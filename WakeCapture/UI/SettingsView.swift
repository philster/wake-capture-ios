import SwiftUI

struct SettingsView: View {
    @Environment(CaptureCoordinator.self) private var coordinator

    private static let maxRecordingOptions = [1, 2, 5, 10, 15, 30]
    private static let silenceTimeoutOptions = [10, 15, 30, 45, 60, 90, 120]

    var body: some View {
        @Bindable var coord = coordinator

        Form {
            Section("Recording") {
                Picker("Max recording", selection: Binding(
                    get: { coordinator.maxRecordingSeconds / 60 },
                    set: { coordinator.maxRecordingSeconds = $0 * 60 }
                )) {
                    ForEach(Self.maxRecordingOptions, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }

                Picker("Silence auto-stop", selection: Binding(
                    get: { coordinator.silenceTimeoutSeconds },
                    set: { coordinator.silenceTimeoutSeconds = $0 }
                )) {
                    ForEach(Self.silenceTimeoutOptions, id: \.self) { seconds in
                        Text("\(seconds)s").tag(seconds)
                    }
                }
            }

            Section {
                Picker("Auto-disarm after", selection: Binding(
                    get: { coordinator.autoDisarmPreset },
                    set: { coordinator.autoDisarmPreset = $0 }
                )) {
                    ForEach(AutoDisarmDuration.allCases, id: \.self) { preset in
                        Text(preset.label).tag(preset)
                    }
                }
            } header: {
                Text("Auto-Disarm")
            } footer: {
                Text("When armed, Wake Capture automatically disarms after this duration. Takes effect on next arm.")
            }

            Section("About") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            }
        }
        .navigationTitle("Settings")
    }
}
