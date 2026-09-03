import AppIntents
import Foundation

struct StartWakeCaptureIntent: AudioRecordingIntent {
    static let title: LocalizedStringResource = "Start Capture"
    static let description: IntentDescription = "Start a Wake Capture audio recording."
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let coordinator = SharedCaptureCoordinator.shared
        if !coordinator.isArmed {
            coordinator.arm()
        }
        await coordinator.startCapture()
        return .result()
    }
}
