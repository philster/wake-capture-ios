import SwiftUI

struct SettingsView: View {
    @Environment(CaptureCoordinator.self) private var coordinator
    @State private var maxMinutes: Double = 5
    @State private var silenceTimeout: Double = 30

    var body: some View {
        @Bindable var coord = coordinator

        Form {
            Section("Recording") {
                VStack(alignment: .leading) {
                    Text("Max recording: \(Int(maxMinutes)) min")
                    Slider(value: $maxMinutes, in: 1...30, step: 1)
                }
                .onChange(of: maxMinutes) { _, newValue in
                    coordinator.maxRecordingSeconds = Int(newValue) * 60
                }

                VStack(alignment: .leading) {
                    Text("Silence auto-stop: \(Int(silenceTimeout))s")
                    Slider(value: $silenceTimeout, in: 10...120, step: 5)
                }
                .onChange(of: silenceTimeout) { _, newValue in
                    coordinator.silenceTimeoutSeconds = Int(newValue)
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
        .onAppear {
            maxMinutes = Double(coordinator.maxRecordingSeconds / 60)
            silenceTimeout = Double(coordinator.silenceTimeoutSeconds)
        }
    }
}
