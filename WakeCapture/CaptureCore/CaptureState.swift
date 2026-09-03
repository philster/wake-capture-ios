import Foundation

enum CaptureState: String, Sendable, Codable {
    case disarmed
    case armed
    case starting
    case recording
    case stopping
    case saved
    case failed
    case interrupted

    var isActive: Bool {
        switch self {
        case .starting, .recording, .stopping:
            return true
        default:
            return false
        }
    }

    var canStartCapture: Bool {
        self == .armed
    }

    var canStop: Bool {
        self == .recording
    }
}
