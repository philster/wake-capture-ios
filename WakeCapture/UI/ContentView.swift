import SwiftUI

struct ContentView: View {
    @Environment(CaptureCoordinator.self) private var coordinator

    var body: some View {
        switch coordinator.state {
        case .recording, .starting, .stopping:
            RecordingView()
        case .permissionNeeded:
            PermissionNeededView()
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
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 80

    var body: some View {
        Group {
            if verticalSizeClass == .compact {
                compactLayout
            } else {
                regularLayout
            }
        }
        .animation(reduceMotion ? nil : .default, value: coordinator.isArmed)
        .navigationTitle("Wake Capture")
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                NavigationLink {
                    CaptureHistoryView()
                } label: {
                    Label("History", systemImage: "microphone.badge.ellipsis")
                }
                Spacer()
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { coordinator.lastError != nil },
                set: { if !$0 { coordinator.lastError = nil } }
            ),
            presenting: coordinator.lastError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.userMessage)
        }
    }

    private var statusSection: some View {
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
    }

    private var buttonsSection: some View {
        VStack(spacing: 16) {
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
            .accessibilityHint(coordinator.isArmed ? "Disarms wake capture" : "Arms wake capture for recording")
            .sensoryFeedback(.impact(flexibility: .soft), trigger: coordinator.isArmed)

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
                .accessibilityHint("Begins audio recording immediately")
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    private var regularLayout: some View {
        VStack(spacing: 40) {
            Spacer()
            statusSection
            buttonsSection
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var compactLayout: some View {
        HStack(spacing: 32) {
            statusSection
                .frame(maxWidth: .infinity)
            buttonsSection
                .frame(maxWidth: 280)
        }
        .padding(.horizontal, 24)
        .frame(maxHeight: .infinity)
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
