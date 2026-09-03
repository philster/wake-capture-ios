import Foundation
import SwiftData

@Model
final class CaptureRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var durationSeconds: Double
    var relativePath: String
    var mimeType: String
    var codec: String
    var sampleRate: Double
    var channelCount: Int
    var state: String
    var transcriptStatus: String
    var uploadStatus: String
    var title: String?
    var tags: [String]

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        durationSeconds: Double = 0,
        relativePath: String,
        mimeType: String = "audio/mp4",
        codec: String = "aac",
        sampleRate: Double = 44100,
        channelCount: Int = 1,
        state: String = CaptureState.saved.rawValue,
        transcriptStatus: String = "none",
        uploadStatus: String = "none",
        title: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.durationSeconds = durationSeconds
        self.relativePath = relativePath
        self.mimeType = mimeType
        self.codec = codec
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.state = state
        self.transcriptStatus = transcriptStatus
        self.uploadStatus = uploadStatus
        self.title = title
        self.tags = tags
    }
}
