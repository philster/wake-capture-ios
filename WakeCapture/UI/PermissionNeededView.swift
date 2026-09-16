import SwiftUI

struct PermissionNeededView: View {
    @Environment(CaptureCoordinator.self) private var coordinator
    @Environment(\.scenePhase) private var scenePhase
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                coordinator.recheckPermission()
            }
        }
    }

    private var statusSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.slash.circle.fill")
                .font(.system(size: iconSize))
                .foregroundStyle(.red)
                .accessibilityHidden(true)

            Text("Microphone Access Needed")
                .font(.title2)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)

            Text("Microphone permission was disabled. Enable it in Settings to continue recording.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .accessibilityElement(children: .combine)
    }

    private var buttonsSection: some View {
        VStack(spacing: 16) {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Settings", systemImage: "gear")
                    .font(.title3)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint("Opens Wake Capture settings to enable microphone access")

            Button {
                coordinator.disarm()
            } label: {
                Text("Cancel")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.bordered)
            .accessibilityHint("Disarms wake capture and returns to home")
        }
    }

    private var regularLayout: some View {
        VStack(spacing: 32) {
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
}
