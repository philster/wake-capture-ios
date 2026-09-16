import SwiftUI

struct RecordingView: View {
    @Environment(CaptureCoordinator.self) private var coordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ScaledMetric(relativeTo: .largeTitle) private var stopButtonSize: CGFloat = 140

    var body: some View {
        Group {
            if verticalSizeClass == .compact {
                compactLayout
            } else {
                regularLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var statusSection: some View {
        VStack(spacing: 16) {
            Text("RECORDING")
                .font(.headline)
                .textCase(.uppercase)
                .foregroundStyle(.red)
                .opacity(coordinator.state == .recording ? 1 : 0.4)
                .accessibilityAddTraits(.isHeader)

            Text(coordinator.formattedElapsed)
                .font(.system(.largeTitle, design: .monospaced, weight: .light))
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                .monospacedDigit()
                .contentTransition(.numericText())
                .accessibilityLabel("Elapsed time: \(coordinator.formattedElapsed)")

            Circle()
                .fill(.red)
                .frame(width: 12, height: 12)
                .opacity(coordinator.state == .recording ? 1 : 0)
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: coordinator.state
                )
                .accessibilityHidden(true)
        }
    }

    private var stopButton: some View {
        Button {
            Task { await coordinator.stopCapture() }
        } label: {
            Text("STOP")
                .font(.title2.bold())
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .frame(width: stopButtonSize, height: stopButtonSize)
                .background(.red, in: Circle())
        }
        .disabled(coordinator.state != .recording)
        .accessibilityLabel("Stop recording")
        .accessibilityHint("Stops the current capture and saves it")
    }

    private var regularLayout: some View {
        VStack(spacing: 48) {
            Spacer()
            statusSection
            Spacer()
            stopButton
            Spacer()
        }
    }

    private var compactLayout: some View {
        HStack(spacing: 32) {
            statusSection
                .frame(maxWidth: .infinity)
            stopButton
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
    }
}
