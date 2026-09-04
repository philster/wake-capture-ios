import ActivityKit
import AVFoundation
import Foundation
import OSLog
import SwiftData
import UIKit

@Observable
@MainActor
final class CaptureCoordinator {
    private let logger = Logger(subsystem: "com.wakecapture", category: "Coordinator")
    private let audioSession: any AudioSessionProviding
    private let recorderFactory: AudioRecorderFactory
    let storageCheck: @Sendable () -> Bool

    private(set) var state: CaptureState = .disarmed
    private(set) var elapsedSeconds: Int = 0
    private(set) var lastError: CaptureError?

    var isArmed: Bool { state == .armed }

    var maxRecordingSeconds: Int = 300
    var silenceTimeoutSeconds: Int = 30

    private var recorder: (any AudioRecording)?
    private var currentSession: CaptureSession?
    private var timer: Timer?
    private var activity: Activity<CaptureActivityAttributes>?
    private var interruptionObserver: NSObjectProtocol?
    private var routeObserver: NSObjectProtocol?
    private var resetObserver: NSObjectProtocol?
    private(set) var store: (any CaptureStoring)?

    init(
        audioSession: any AudioSessionProviding = AudioSessionController(),
        recorderFactory: @escaping AudioRecorderFactory = { try AudioRecorder(captureId: $0) },
        storageCheck: @escaping @Sendable () -> Bool = { RecordingFileStore.hasMinimumStorage() }
    ) {
        self.audioSession = audioSession
        self.recorderFactory = recorderFactory
        self.storageCheck = storageCheck
    }

    func setStore(_ store: any CaptureStoring) {
        self.store = store
    }

    func setModelContainer(_ container: ModelContainer) {
        self.store = CaptureRepository(modelContainer: container)
    }

    // MARK: - Arm / Disarm

    func toggleArmed() {
        if isArmed {
            disarm()
        } else {
            arm()
        }
    }

    func arm() {
        guard state == .disarmed || state == .saved || state == .failed else { return }
        state = .armed
        lastError = nil
        logger.info("Wake Capture armed")
    }

    func disarm() {
        guard !state.isActive else { return }
        state = .disarmed
        logger.info("Wake Capture disarmed")
    }

    // MARK: - Start Capture

    func startCapture() async {
        guard state.canStartCapture else {
            lastError = .invalidStateTransition(from: state, attempted: "startCapture")
            return
        }

        state = .starting

        let permission = audioSession.checkPermission()
        switch permission {
        case .denied:
            fail(.microphonePermissionDenied)
            return
        case .restricted:
            fail(.microphonePermissionRestricted)
            return
        case .undetermined:
            let granted = await audioSession.requestPermission()
            if !granted {
                fail(.microphonePermissionDenied)
                return
            }
        case .granted:
            break
        }

        guard storageCheck() else {
            fail(.storageInsufficient)
            return
        }

        do {
            try audioSession.configureForRecording()
            try audioSession.activate()
        } catch let error as CaptureError {
            fail(error)
            return
        } catch {
            fail(.audioSessionSetupFailed(underlying: error))
            return
        }

        let captureId = UUID()
        do {
            let newRecorder = try recorderFactory(captureId)
            try newRecorder.start()
            self.recorder = newRecorder
        } catch let error as CaptureError {
            audioSession.deactivate()
            fail(error)
            return
        } catch {
            audioSession.deactivate()
            fail(.recorderStartFailed(underlying: error))
            return
        }

        let session = CaptureSession(id: captureId, startedAt: Date())
        currentSession = session

        startLiveActivity(captureId: captureId)
        startTimer()
        observeInterruptions()

        state = .recording
        elapsedSeconds = 0
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        logger.info("Recording started: \(captureId.uuidString)")
    }

    // MARK: - Stop Capture

    func stopCapture() async {
        guard state.canStop, let recorder else {
            return
        }

        state = .stopping
        stopTimer()
        removeObservers()

        let result = await recorder.stop()
        audioSession.deactivate()
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        if result.succeeded, result.durationSeconds > 0 {
            await persistCapture(result: result)
            stopLiveActivity(recording: false)
            state = .armed
            logger.info("Capture saved: \(result.captureId.uuidString)")
        } else {
            stopLiveActivity(recording: false)
            fail(.fileWriteFailed(
                underlying: NSError(domain: "CaptureCoordinator", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Recording produced no data"])
            ))
        }

        self.recorder = nil
        self.currentSession = nil
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard state == .recording else { return }
        elapsedSeconds += 1
        updateLiveActivity()

        if elapsedSeconds >= maxRecordingSeconds {
            Task { await stopCapture() }
        }
    }

    // MARK: - Live Activity

    private func startLiveActivity(captureId: UUID) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = CaptureActivityAttributes(
            captureId: captureId.uuidString,
            startedAt: Date()
        )
        let initialState = CaptureActivityAttributes.ContentState(
            elapsedSeconds: 0,
            isRecording: true
        )
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            logger.info("Live Activity started")
        } catch {
            logger.warning("Could not start Live Activity: \(error.localizedDescription)")
        }
    }

    private func updateLiveActivity() {
        guard let activity else { return }
        let updatedState = CaptureActivityAttributes.ContentState(
            elapsedSeconds: elapsedSeconds,
            isRecording: true
        )
        Task {
            await activity.update(.init(state: updatedState, staleDate: nil))
        }
    }

    private func stopLiveActivity(recording: Bool) {
        guard let activity else { return }
        let finalState = CaptureActivityAttributes.ContentState(
            elapsedSeconds: elapsedSeconds,
            isRecording: false
        )
        Task {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        self.activity = nil
    }

    // MARK: - Interruption handling

    private func observeInterruptions() {
        interruptionObserver = audioSession.observeInterruptions { [weak self] type, options in
            Task { @MainActor [weak self] in
                guard let self, self.state == .recording else { return }
                switch type {
                case .began:
                    self.logger.warning("Audio interrupted")
                    await self.handleInterruption()
                case .ended:
                    break
                @unknown default:
                    break
                }
            }
        }

        routeObserver = audioSession.observeRouteChanges { [weak self] reason in
            Task { @MainActor [weak self] in
                guard let self, self.state == .recording else { return }
                if reason == .oldDeviceUnavailable {
                    self.logger.warning("Audio route lost")
                    await self.handleInterruption()
                }
            }
        }

        resetObserver = audioSession.observeMediaServicesReset { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.state == .recording else { return }
                await self.handleInterruption()
            }
        }
    }

    private func handleInterruption() async {
        guard state == .recording, let recorder else { return }

        state = .stopping
        stopTimer()
        removeObservers()

        let result = recorder.stopSync()
        audioSession.deactivate()
        stopLiveActivity(recording: false)

        if result.succeeded, result.durationSeconds > 0 {
            await persistCapture(result: result, state: .interrupted)
        }

        state = .interrupted
        lastError = .interruptedBySystem(reason: "Recording was interrupted by the system")
        self.recorder = nil
        self.currentSession = nil
    }

    private func removeObservers() {
        if let o = interruptionObserver { NotificationCenter.default.removeObserver(o) }
        if let o = routeObserver { NotificationCenter.default.removeObserver(o) }
        if let o = resetObserver { NotificationCenter.default.removeObserver(o) }
        interruptionObserver = nil
        routeObserver = nil
        resetObserver = nil
    }

    // MARK: - Persistence

    private func persistCapture(result: RecordingResult, state: CaptureState = .saved) async {
        guard let store else {
            logger.error("No store configured for persistence")
            return
        }
        let data = CaptureRecordData(
            id: result.captureId,
            createdAt: currentSession?.startedAt ?? Date(),
            durationSeconds: result.durationSeconds,
            relativePath: RecordingFileStore.relativePath(for: result.captureId),
            state: state.rawValue
        )
        do {
            try await store.save(data)
        } catch {
            logger.error("Failed to persist capture: \(error.localizedDescription)")
            lastError = .metadataPersistFailed(underlying: error)
        }
    }

    // MARK: - Failure

    private func fail(_ error: CaptureError) {
        state = .failed
        lastError = error
        logger.error("Capture failed: \(error.userMessage)")
    }

    // MARK: - Formatted time

    var formattedElapsed: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
