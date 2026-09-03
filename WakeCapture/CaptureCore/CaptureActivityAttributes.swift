import ActivityKit
import Foundation

struct CaptureActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var elapsedSeconds: Int
        var isRecording: Bool
    }

    let captureId: String
    let startedAt: Date
}
