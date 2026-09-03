import Foundation

@MainActor
enum SharedCaptureCoordinator {
    static let shared = CaptureCoordinator()
}
