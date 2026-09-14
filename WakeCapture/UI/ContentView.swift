import SwiftUI

struct ContentView: View {
    @Environment(CaptureCoordinator.self) private var coordinator

    var body: some View {
        switch coordinator.state {
        case .recording, .starting, .stopping:
            RecordingView()
        default:
            NavigationStack {
                HomeView()
            }
        }
    }
}

struct HomeView: View {
    @Environment(CaptureCoordinator.self) private var coordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 80

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: coordinator.isArmed ? "mic.circle.fill" : "mic.circle")
                    .font(.system(size: iconSize))
                    .foregroundStyle(coordinator.isArmed ? .green : .secondary)
                    .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
                    .accessibilityHidden(true)

                Text(coordinator.isArmed ? "Armed" : "Disarmed")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(coordinator.isArmed ? .primary : .secondary)
                    .accessibilityAddTraits(.isHeader)

                if coordinator.isArmed {
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        let _ = coordinator.enforceExpiry()
                        if let remaining = coordinator.autoDisarmRemainingSeconds {
                            Text("Auto-disarm in \(formatDuration(remaining))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        } else {
                            Text("Armed until you disarm")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .accessibilityElement(children: .combine)

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
            .accessibilityHint(coordinator.isArmed ? "Disarms wake capture" : "Arms wake capture for recording")

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
                .accessibilityHint("Begins audio recording immediately")
            }

            if let error = coordinator.lastError {
                Text(error.userMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .accessibilityLabel("Error: \(error.userMessage)")
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

    private func formatDuration(_ totalSeconds: Int) -> String {
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        if h > 0 {
            return String(format: "%dh %02dm", h, m)
        }
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
