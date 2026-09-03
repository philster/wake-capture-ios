import Foundation

enum CaptureError: Error, Sendable {
    case microphonePermissionDenied
    case microphonePermissionRestricted
    case audioSessionSetupFailed(underlying: Error)
    case audioSessionActivationFailed(underlying: Error)
    case recorderStartFailed(underlying: Error)
    case recorderNotRunning
    case fileWriteFailed(underlying: Error)
    case storageInsufficient
    case interruptedBySystem(reason: String)
    case invalidStateTransition(from: CaptureState, attempted: String)
    case fileNotFound(url: URL)
    case metadataPersistFailed(underlying: Error)
    case alreadyRecording

    var userMessage: String {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is denied. Open Settings → Wake Capture → Microphone to enable it."
        case .microphonePermissionRestricted:
            return "Microphone access is restricted on this device."
        case .audioSessionSetupFailed:
            return "Could not set up audio. Please try again."
        case .audioSessionActivationFailed:
            return "Could not activate audio session."
        case .recorderStartFailed:
            return "Could not start recording."
        case .recorderNotRunning:
            return "Recorder is not running."
        case .fileWriteFailed:
            return "Could not save recording."
        case .storageInsufficient:
            return "Not enough storage space."
        case .interruptedBySystem(let reason):
            return "Recording interrupted: \(reason)"
        case .invalidStateTransition:
            return "Cannot perform this action right now."
        case .fileNotFound:
            return "Recording file not found."
        case .metadataPersistFailed:
            return "Could not save recording metadata."
        case .alreadyRecording:
            return "A recording is already in progress."
        }
    }
}
