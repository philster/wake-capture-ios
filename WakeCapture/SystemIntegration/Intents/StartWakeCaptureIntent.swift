import AppIntents
import Foundation

struct StartWakeCaptureIntent: AudioRecordingIntent {
    static let title: LocalizedStringResource = "Start Capture"
    static let description: IntentDescription = "Start a Wake Capture audio recording."
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let coordinator = SharedCaptureCoordinator.shared
        coordinator.enforceExpiry()

        guard coordinator.isArmed else {
            throw NotArmedError()
        }

        await coordinator.startCapture()
        return .result()
    }
}

private struct NotArmedError: LocalizedError {
    var errorDescription: String? {
        "Wake Capture is not armed. Open the app and arm it first."
    }
}
