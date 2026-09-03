import AppIntents

struct WakeCaptureShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartWakeCaptureIntent(),
            phrases: [
                "Start a capture with \(.applicationName)",
                "Record this with \(.applicationName)",
                "Start recording in \(.applicationName)",
            ],
            shortTitle: "Start Capture",
            systemImageName: "mic.circle.fill"
        )
        AppShortcut(
            intent: StopWakeCaptureIntent(),
            phrases: [
                "Stop capture in \(.applicationName)",
                "Stop recording in \(.applicationName)",
            ],
            shortTitle: "Stop Capture",
            systemImageName: "stop.circle.fill"
        )
        AppShortcut(
            intent: ArmWakeCaptureIntent(),
            phrases: [
                "Arm \(.applicationName)",
                "Arm \(.applicationName) for capture",
            ],
            shortTitle: "Arm",
            systemImageName: "moon.zzz.fill"
        )
        AppShortcut(
            intent: DisarmWakeCaptureIntent(),
            phrases: [
                "Disarm \(.applicationName)",
                "Turn off \(.applicationName)",
            ],
            shortTitle: "Disarm",
            systemImageName: "moon"
        )
    }
}
