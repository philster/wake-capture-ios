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
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 80))
                .foregroundStyle(.indigo)
                .accessibilityHidden(true)
            Text("Wake Capture")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
            Text("Capture thoughts the moment you wake — before they fade.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Next") { page = 1 }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityHint("Go to microphone access page")
            Spacer().frame(height: 60)
        }
    }

    private var microphonePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "mic.badge.plus")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            Text("Microphone Access")
                .font(.title.bold())
                .accessibilityAddTraits(.isHeader)
            Text("Wake Capture needs microphone access to record your voice. The mic is only active while you're recording — never in the background.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .foregroundStyle(.secondary)
            Spacer()
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
            Spacer().frame(height: 60)
        }
    }

    private var controlPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "lock.shield")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
                .accessibilityHidden(true)
            Text("Lock Screen Control")
                .font(.title.bold())
                .accessibilityAddTraits(.isHeader)
            Text("Add the Wake Capture control to your Lock Screen or Control Center for instant access.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Get Started") {
                hasCompleted = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityHint("Completes setup and opens the app")
            Spacer().frame(height: 60)
        }
    }
}
