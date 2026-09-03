import ActivityKit
import SwiftUI
import WidgetKit

struct CaptureActivityView: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CaptureActivityAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "mic.fill")
                        .foregroundStyle(.red)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(formatTime(context.state.elapsedSeconds))
                        .font(.system(size: 28, weight: .medium, design: .monospaced))
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Button(intent: StopWakeCaptureIntent()) {
                        Image(systemName: "stop.fill")
                            .foregroundStyle(.white)
                    }
                    .tint(.red)
                }
            } compactLeading: {
                Image(systemName: "mic.fill")
                    .foregroundStyle(.red)
            } compactTrailing: {
                Text(formatTime(context.state.elapsedSeconds))
                    .font(.caption.monospacedDigit())
            } minimal: {
                Image(systemName: "mic.fill")
                    .foregroundStyle(.red)
            }
        }
    }

    private func lockScreenView(context: ActivityViewContext<CaptureActivityAttributes>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text("Capturing")
                        .font(.subheadline.weight(.semibold))
                }
                Text(formatTime(context.state.elapsedSeconds))
                    .font(.system(size: 32, weight: .medium, design: .monospaced))
                    .monospacedDigit()
            }
            Spacer()
            Button(intent: StopWakeCaptureIntent()) {
                Text("STOP")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.red, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
