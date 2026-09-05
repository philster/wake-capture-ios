import XCTest
@testable import WakeCapture

@MainActor
final class CaptureCoordinatorTests: XCTestCase {
    private var mockSession: MockAudioSession!
    private var mockStore: MockCaptureStore!
    private var lastCreatedRecorder: MockRecorder?
    private var testDefaults: UserDefaults!
    private var sut: CaptureCoordinator!

    override func setUp() {
        super.setUp()
        mockSession = MockAudioSession()
        mockStore = MockCaptureStore()
        testDefaults = UserDefaults(suiteName: "CaptureCoordinatorTests")!
        testDefaults.removePersistentDomain(forName: "CaptureCoordinatorTests")
        sut = CaptureCoordinator(
            audioSession: mockSession,
            recorderFactory: { [weak self] captureId in
                let recorder = MockRecorder(captureId: captureId)
                self?.lastCreatedRecorder = recorder
                return recorder
            },
            storageCheck: { true },
            autoDisarmManager: AutoDisarmManager(defaults: testDefaults)
        )
        sut.setStore(mockStore)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "CaptureCoordinatorTests")
        super.tearDown()
    }

    // MARK: - Arm / Disarm

    func test_arm_disarm() {
        XCTAssertEqual(sut.state, .disarmed)
        XCTAssertFalse(sut.isArmed)

        sut.arm()
        XCTAssertEqual(sut.state, .armed)
        XCTAssertTrue(sut.isArmed)

        sut.disarm()
        XCTAssertEqual(sut.state, .disarmed)
        XCTAssertFalse(sut.isArmed)
    }

    func test_toggleArmed_togglesBothDirections() {
        sut.toggleArmed()
        XCTAssertEqual(sut.state, .armed)
        sut.toggleArmed()
        XCTAssertEqual(sut.state, .disarmed)
    }

    // MARK: - Start Capture guards

    func test_startCapture_whenNotArmed_doesNotRecord() async {
        await sut.startCapture()
        XCTAssertNotEqual(sut.state, .recording)
        XCTAssertNotNil(sut.lastError)
    }

    func test_startCapture_permissionDenied_failsWithCorrectError() async {
        sut.arm()
        mockSession.permissionStatus = .denied

        await sut.startCapture()

        XCTAssertNotEqual(sut.state, .recording)
        XCTAssertEqual(sut.lastError?.userMessage, CaptureError.microphonePermissionDenied.userMessage)
    }

    func test_startCapture_permissionUndetermined_requestsAndProceeds() async {
        sut.arm()
        mockSession.permissionStatus = .undetermined
        mockSession.permissionRequestResult = true

        await sut.startCapture()

        XCTAssertEqual(sut.state, .recording)
    }

    func test_startCapture_permissionUndetermined_deniedOnRequest_fails() async {
        sut.arm()
        mockSession.permissionStatus = .undetermined
        mockSession.permissionRequestResult = false

        await sut.startCapture()

        XCTAssertNotEqual(sut.state, .recording)
        XCTAssertEqual(sut.lastError?.userMessage, CaptureError.microphonePermissionDenied.userMessage)
    }

    func test_startCapture_insufficientStorage_fails() async {
        sut = CaptureCoordinator(
            audioSession: mockSession,
            recorderFactory: { MockRecorder(captureId: $0) },
            storageCheck: { false },
            autoDisarmManager: AutoDisarmManager(defaults: testDefaults)
        )
        sut.arm()

        await sut.startCapture()

        XCTAssertNotEqual(sut.state, .recording)
        XCTAssertEqual(sut.lastError?.userMessage, CaptureError.storageInsufficient.userMessage)
    }

    // MARK: - Audio session errors

    func test_startCapture_audioSetupThrows_fails() async {
        sut.arm()
        mockSession.configureError = CaptureError.audioSessionSetupFailed(
            underlying: NSError(domain: "test", code: -50)
        )

        await sut.startCapture()

        XCTAssertNotEqual(sut.state, .recording)
        XCTAssertTrue(sut.lastError?.userMessage.contains("audio") == true)
    }

    func test_startCapture_activateThrows_fails() async {
        sut.arm()
        mockSession.activateError = CaptureError.audioSessionActivationFailed(
            underlying: NSError(domain: "test", code: -50)
        )

        await sut.startCapture()

        XCTAssertNotEqual(sut.state, .recording)
        XCTAssertTrue(sut.lastError?.userMessage.contains("audio") == true)
    }

    // MARK: - Recorder errors

    func test_startCapture_recorderThrows_deactivatesAndFails() async {
        sut = CaptureCoordinator(
            audioSession: mockSession,
            recorderFactory: { _ in
                throw CaptureError.recorderStartFailed(
                    underlying: NSError(domain: "test", code: -1)
                )
            },
            storageCheck: { true },
            autoDisarmManager: AutoDisarmManager(defaults: testDefaults)
        )
        sut.arm()

        await sut.startCapture()

        XCTAssertNotEqual(sut.state, .recording)
        XCTAssertTrue(mockSession.deactivateCalled)
    }

    // MARK: - Happy path

    func test_startCapture_success_transitionsToRecording() async {
        sut.arm()

        await sut.startCapture()

        XCTAssertEqual(sut.state, .recording)
        XCTAssertEqual(sut.elapsedSeconds, 0)
        XCTAssertNil(sut.lastError)
        XCTAssertTrue(mockSession.configureCalled)
        XCTAssertTrue(mockSession.activateCalled)
    }

    // MARK: - Stop Capture

    func test_stopCapture_savesWhenSuccessful() async {
        sut.arm()
        await sut.startCapture()
        XCTAssertEqual(sut.state, .recording)

        await sut.stopCapture()

        XCTAssertEqual(sut.state, .armed)
        XCTAssertEqual(mockStore.savedRecords.count, 1)
        XCTAssertTrue(mockSession.deactivateCalled)
    }

    func test_stopCapture_failsWhenZeroDuration() async {
        sut.arm()
        await sut.startCapture()

        lastCreatedRecorder?.stopResult = RecordingResult(
            captureId: lastCreatedRecorder!.captureId,
            fileURL: lastCreatedRecorder!.fileURL,
            durationSeconds: 0,
            succeeded: true
        )

        await sut.stopCapture()

        XCTAssertNotEqual(sut.state, .armed)
        XCTAssertTrue(mockStore.savedRecords.isEmpty)
    }

    func test_stopCapture_failsWhenNotSucceeded() async {
        sut.arm()
        await sut.startCapture()

        lastCreatedRecorder?.stopResult = RecordingResult(
            captureId: lastCreatedRecorder!.captureId,
            fileURL: lastCreatedRecorder!.fileURL,
            durationSeconds: 5.0,
            succeeded: false
        )

        await sut.stopCapture()

        XCTAssertEqual(sut.state, .failed)
    }

    // MARK: - Stop then re-capture

    func test_stopCapture_transitionsToArmed_allowingImmediateRestart() async {
        sut.arm()
        await sut.startCapture()
        XCTAssertEqual(sut.state, .recording)

        await sut.stopCapture()
        XCTAssertEqual(sut.state, .armed)
        XCTAssertTrue(sut.state.canStartCapture)

        await sut.startCapture()
        XCTAssertEqual(sut.state, .recording)
    }

    // MARK: - Auto-Disarm

    func test_arm_persistsTimestamp() {
        sut.arm()
        XCTAssertNotNil(sut.autoDisarmManager.armTimestamp())
    }

    func test_disarm_clearsTimestamp() {
        sut.arm()
        sut.disarm()
        XCTAssertNil(sut.autoDisarmManager.armTimestamp())
    }

    func test_enforceExpiry_whenExpired_disarms() {
        sut.arm()
        let pastTimestamp = Date().addingTimeInterval(-28801).timeIntervalSince1970
        testDefaults.set(pastTimestamp, forKey: "autoDisarm_armTimestamp")
        testDefaults.set(AutoDisarmDuration.eightHours.rawValue, forKey: "autoDisarm_duration")

        sut.enforceExpiry()

        XCTAssertEqual(sut.state, .disarmed)
    }

    func test_enforceExpiry_whenNotExpired_staysArmed() {
        sut.arm()
        sut.enforceExpiry()
        XCTAssertEqual(sut.state, .armed)
    }

    func test_enforceExpiry_untilManual_staysArmed() {
        sut.autoDisarmPreset = .untilManual
        sut.arm()
        sut.enforceExpiry()
        XCTAssertEqual(sut.state, .armed)
    }

    func test_startCapture_whenExpired_doesNotRecord() async {
        sut.arm()
        let pastTimestamp = Date().addingTimeInterval(-28801).timeIntervalSince1970
        testDefaults.set(pastTimestamp, forKey: "autoDisarm_armTimestamp")
        testDefaults.set(AutoDisarmDuration.eightHours.rawValue, forKey: "autoDisarm_duration")

        await sut.startCapture()

        XCTAssertEqual(sut.state, .disarmed)
    }

    func test_restorePersistedState_armedNotExpired() {
        sut.autoDisarmPreset = .eightHours
        sut.arm()

        let fresh = CaptureCoordinator(
            audioSession: mockSession,
            recorderFactory: { MockRecorder(captureId: $0) },
            storageCheck: { true },
            autoDisarmManager: AutoDisarmManager(defaults: testDefaults)
        )
        XCTAssertEqual(fresh.state, .disarmed)

        fresh.restorePersistedState()
        XCTAssertEqual(fresh.state, .armed)
    }

    func test_restorePersistedState_armedButExpired() {
        let pastTimestamp = Date().addingTimeInterval(-28801).timeIntervalSince1970
        testDefaults.set(pastTimestamp, forKey: "autoDisarm_armTimestamp")
        testDefaults.set(AutoDisarmDuration.eightHours.rawValue, forKey: "autoDisarm_duration")

        let fresh = CaptureCoordinator(
            audioSession: mockSession,
            recorderFactory: { MockRecorder(captureId: $0) },
            storageCheck: { true },
            autoDisarmManager: AutoDisarmManager(defaults: testDefaults)
        )
        fresh.restorePersistedState()

        XCTAssertEqual(fresh.state, .disarmed)
        XCTAssertNil(fresh.autoDisarmManager.armTimestamp())
    }

    func test_stopCapture_doesNotResetAutoDisarmTimer() async {
        sut.arm()
        let originalTimestamp = sut.autoDisarmManager.armTimestamp()

        await sut.startCapture()
        await sut.stopCapture()

        XCTAssertEqual(sut.state, .armed)
        XCTAssertEqual(
            sut.autoDisarmManager.armTimestamp()!.timeIntervalSince1970,
            originalTimestamp!.timeIntervalSince1970,
            accuracy: 1
        )
    }
}
