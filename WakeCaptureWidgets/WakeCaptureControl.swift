import AppIntents
import SwiftUI
import WidgetKit

struct WakeCaptureControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.wakecapture.capture-control") {
            ControlWidgetButton(action: StartWakeCaptureIntent()) {
                Label("Capture", systemImage: "mic.circle.fill")
            }
        }
        .displayName("Wake Capture")
        .description("Start a voice capture.")
    }
}
