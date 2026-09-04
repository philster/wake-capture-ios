import AVFoundation
import OSLog

enum AudioPermissionStatus: Sendable {
    case granted
    case denied
    case restricted
    case undetermined
}

protocol AudioSessionProviding: Sendable {
    func checkPermission() -> AudioPermissionStatus
    func requestPermission() async -> Bool
    func configureForRecording() throws
    func activate() throws
    func deactivate()
    func observeInterruptions(_ handler: @escaping @Sendable (AVAudioSession.InterruptionType, AVAudioSession.InterruptionOptions) -> Void) -> NSObjectProtocol
    func observeRouteChanges(_ handler: @escaping @Sendable (AVAudioSession.RouteChangeReason) -> Void) -> NSObjectProtocol
    func observeMediaServicesReset(_ handler: @escaping @Sendable () -> Void) -> NSObjectProtocol
}

final class AudioSessionController: AudioSessionProviding {
    private let logger = Logger(subsystem: "com.wakecapture", category: "AudioSession")

    func checkPermission() -> AudioPermissionStatus {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return .granted
        case .denied: return .denied
        case .undetermined: return .undetermined
        @unknown default: return .undetermined
        }
    }

    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func configureForRecording() throws {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default, options: [])
            try session.setPreferredSampleRate(44100)
            logger.info("Audio session configured for recording")
        } catch {
            logger.error("Audio session setup failed: \(error.localizedDescription)")
            throw CaptureError.audioSessionSetupFailed(underlying: error)
        }
    }

    func activate() throws {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(true, options: [])
            try session.setPreferredInputNumberOfChannels(1)
            logger.info("Audio session activated")
        } catch {
            logger.error("Audio session activation failed: \(error.localizedDescription)")
            throw CaptureError.audioSessionActivationFailed(underlying: error)
        }
    }

    func deactivate() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            logger.info("Audio session deactivated")
        } catch {
            logger.warning("Audio session deactivation failed: \(error.localizedDescription)")
        }
    }

    func observeInterruptions(_ handler: @escaping @Sendable (AVAudioSession.InterruptionType, AVAudioSession.InterruptionOptions) -> Void) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: nil
        ) { notification in
            guard let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            let options: AVAudioSession.InterruptionOptions
            if let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt {
                options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            } else {
                options = []
            }
            handler(type, options)
        }
    }

    func observeRouteChanges(_ handler: @escaping @Sendable (AVAudioSession.RouteChangeReason) -> Void) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: nil
        ) { notification in
            guard let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
            handler(reason)
        }
    }

    func observeMediaServicesReset(_ handler: @escaping @Sendable () -> Void) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: nil,
            queue: nil
        ) { _ in
            handler()
        }
    }
}
