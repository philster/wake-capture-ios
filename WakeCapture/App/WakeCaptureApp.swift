import SwiftData
import SwiftUI

@main
struct WakeCaptureApp: App {
    @State private var coordinator = SharedCaptureCoordinator.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .task { coordinator.restorePersistedState() }
            .environment(coordinator)
            .modelContainer(for: CaptureRecord.self) { result in
                switch result {
                case .success(let container):
                    coordinator.setModelContainer(container)
                case .failure(let error):
                    fatalError("Failed to create model container: \(error)")
                }
            }
        }
    }
}
