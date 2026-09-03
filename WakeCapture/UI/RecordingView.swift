import SwiftUI

struct RecordingView: View {
    @Environment(CaptureCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 48) {
            Spacer()

            Text("RECORDING")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(.red)
                .opacity(coordinator.state == .recording ? 1 : 0.4)

            Text(coordinator.formattedElapsed)
                .font(.system(size: 72, weight: .light, design: .monospaced))
                .monospacedDigit()
                .contentTransition(.numericText())

            Circle()
                .fill(.red)
                .frame(width: 12, height: 12)
                .opacity(coordinator.state == .recording ? 1 : 0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: coordinator.state)

            Spacer()

            Button {
                Task { await coordinator.stopCapture() }
            } label: {
                Text("STOP")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 140, height: 140)
                    .background(.red, in: Circle())
            }
            .disabled(coordinator.state != .recording)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .preferredColorScheme(.dark)
    }
}
