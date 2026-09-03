import AppIntents
import Foundation

struct ArmWakeCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = "Arm Wake Capture"
    static let description: IntentDescription = "Arm Wake Capture for recording."

    @MainActor
    func perform() async throws -> some IntentResult {
        SharedCaptureCoordinator.shared.arm()
        return .result()
    }
}

struct DisarmWakeCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = "Disarm Wake Capture"
    static let description: IntentDescription = "Disarm Wake Capture."

    @MainActor
    func perform() async throws -> some IntentResult {
        SharedCaptureCoordinator.shared.disarm()
        return .result()
    }
}
