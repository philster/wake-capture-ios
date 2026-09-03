import Foundation

struct CaptureSession: Sendable {
    let id: UUID
    let startedAt: Date
    var fileURL: URL?
    var durationSeconds: Double = 0
    var codec: String = "aac"
    var mimeType: String = "audio/mp4"
    var sampleRate: Double = 44100
    var channelCount: Int = 1
}
