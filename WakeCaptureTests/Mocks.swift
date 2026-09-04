import AVFoundation
import Foundation
@testable import WakeCapture

final class MockAudioSession: AudioSessionProviding, @unchecked Sendable {
    var permissionStatus: AudioPermissionStatus = .granted
    var permissionRequestResult: Bool = true
    var configureError: Error?
    var activateError: Error?
    var configureCalled = false
    var activateCalled = false
    var deactivateCalled = false

    func checkPermission() -> AudioPermissionStatus {
        permissionStatus
    }

    func requestPermission() async -> Bool {
        permissionRequestResult
    }

    func configureForRecording() throws {
        configureCalled = true
        if let error = configureError { throw error }
    }

    func activate() throws {
        activateCalled = true
        if let error = activateError { throw error }
    }

    func deactivate() {
        deactivateCalled = true
    }

    func observeInterruptions(_ handler: @escaping @Sendable (AVAudioSession.InterruptionType, AVAudioSession.InterruptionOptions) -> Void) -> NSObjectProtocol {
        NSObject()
    }

    func observeRouteChanges(_ handler: @escaping @Sendable (AVAudioSession.RouteChangeReason) -> Void) -> NSObjectProtocol {
        NSObject()
    }

    func observeMediaServicesReset(_ handler: @escaping @Sendable () -> Void) -> NSObjectProtocol {
        NSObject()
    }
}

final class MockRecorder: AudioRecording, @unchecked Sendable {
    let captureId: UUID
    let fileURL: URL
    var isRecording: Bool = false
    var startError: Error?
    var stopResult: RecordingResult

    init(captureId: UUID) {
        self.captureId = captureId
        self.fileURL = URL(fileURLWithPath: "/tmp/\(captureId.uuidString).m4a")
        self.stopResult = RecordingResult(
            captureId: captureId,
            fileURL: fileURL,
            durationSeconds: 5.0,
            succeeded: true
        )
    }

    func start() throws {
        if let error = startError { throw error }
        isRecording = true
    }

    func stop() async -> RecordingResult {
        isRecording = false
        return stopResult
    }

    func stopSync() -> RecordingResult {
        isRecording = false
        return stopResult
    }
}

final class MockCaptureStore: CaptureStoring, @unchecked Sendable {
    var savedRecords: [CaptureRecordData] = []
    var saveError: Error?

    func save(_ data: CaptureRecordData) async throws {
        if let error = saveError { throw error }
        savedRecords.append(data)
    }
}
