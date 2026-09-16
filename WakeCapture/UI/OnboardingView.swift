import SwiftUI

struct OnboardingView: View {
    @Environment(CaptureCoordinator.self) private var coordinator
    @AppStorage("hasCompletedOnboarding") private var hasCompleted = false
    @State private var page = 0

    var body: some View {
        TabView(selection: $page) {
            welcomePage.tag(0)
            microphonePage.tag(1)
            controlPage.tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .accessibilityLabel("Onboarding, page \(page + 1) of 3")
    }

    private var welcomePage: some View {
        OnboardingPage(
            icon: "moon.zzz.fill",
            iconColor: .indigo,
            title: "Wake Capture",
            titleFont: .largeTitle.bold(),
            subtitle: "Capture thoughts the moment you wake — before they fade."
        ) {
            Button("Next") { page = 1 }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityHint("Go to microphone access page")
        }
    }

    private var microphonePage: some View {
        OnboardingPage(
            icon: "mic.badge.plus",
            iconColor: .green,
            title: "Microphone Access",
            subtitle: "Wake Capture needs microphone access to record your voice. The mic is only active while you're recording — never in the background."
        ) {
            Button("Grant Access") {
                Task {
                    _ = await AudioSessionController().requestPermission()
                    page = 2
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityHint("Requests microphone permission")
            Button("Skip for now") { page = 2 }
                .font(.callout)
                .accessibilityHint("Continue without granting microphone access")
        }
    }

    private var controlPage: some View {
        OnboardingPage(
            icon: "lock.shield",
            iconColor: .blue,
            title: "Lock Screen Control",
            subtitle: "Add the Wake Capture control to your Lock Screen or Control Center for instant access."
        ) {
            Button("Get Started") {
                hasCompleted = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityHint("Completes setup and opens the app")
        }
    }
}

private struct OnboardingPage<Actions: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    var titleFont: Font = .title.bold()
    let subtitle: String
    @ViewBuilder let actions: () -> Actions

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        if verticalSizeClass == .compact {
            compactLayout
        } else {
            regularLayout
        }
    }

    private var illustration: some View {
        Image(systemName: icon)
            .font(.system(size: 80))
            .foregroundStyle(iconColor)
            .accessibilityHidden(true)
    }

    private var textAndActions: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(titleFont)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            actions()
        }
    }

    private var regularLayout: some View {
        VStack(spacing: 24) {
            Spacer()
            illustration
            textAndActions
                .padding(.horizontal, 40)
            Spacer()
            Spacer().frame(height: 40)
        }
    }

    private var compactLayout: some View {
        HStack(spacing: 32) {
            illustration
                .frame(maxWidth: .infinity)
            textAndActions
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
        .frame(maxHeight: .infinity)
    }
}
