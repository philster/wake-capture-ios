import AppIntents
import Foundation

struct StopWakeCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = "Stop Capture"
    static let description: IntentDescription = "Stop the current Wake Capture recording."
    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        await SharedCaptureCoordinator.shared.stopCapture()
        return .result()
    }
}
