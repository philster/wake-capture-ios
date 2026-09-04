import SwiftUI

struct ContentView: View {
    @Environment(CaptureCoordinator.self) private var coordinator
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                switch coordinator.state {
                case .recording, .starting, .stopping:
                    RecordingView()
                default:
                    HomeView()
                }
            }
        }
        .onChange(of: coordinator.state.isActive) { _, isActive in
            if isActive {
                navigationPath = NavigationPath()
            }
        }
    }
}

struct HomeView: View {
    @Environment(CaptureCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: coordinator.isArmed ? "mic.circle.fill" : "mic.circle")
                    .font(.system(size: 80))
                    .foregroundStyle(coordinator.isArmed ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))

                Text(coordinator.isArmed ? "Armed" : "Disarmed")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(coordinator.isArmed ? .primary : .secondary)
            }

            Button {
                coordinator.toggleArmed()
            } label: {
                Text(coordinator.isArmed ? "Disarm" : "Arm Wake Capture")
                    .font(.title3)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(coordinator.isArmed ? .gray : .green)
            .padding(.horizontal, 40)

            if coordinator.isArmed {
                Button {
                    Task { await coordinator.startCapture() }
                } label: {
                    Label("Start Capture", systemImage: "record.circle")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.horizontal, 40)
            }

            if let error = coordinator.lastError {
                Text(error.userMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            NavigationLink {
                CaptureHistoryView()
            } label: {
                Label("Capture History", systemImage: "list.bullet")
            }
            .padding(.bottom, 8)

            NavigationLink {
                SettingsView()
            } label: {
                Label("Settings", systemImage: "gear")
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("Wake Capture")
        .navigationBarTitleDisplayMode(.inline)
    }
}
