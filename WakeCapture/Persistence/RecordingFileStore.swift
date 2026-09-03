import Foundation
import OSLog

struct RecordingFileStore: Sendable {
    private static let logger = Logger(subsystem: "com.wakecapture", category: "FileStore")
    private static let capturesDirectory = "Captures"

    static var baseURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent(capturesDirectory, isDirectory: true)
    }

    static func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    static func fileURL(for id: UUID, extension ext: String = "m4a") -> URL {
        baseURL.appendingPathComponent("\(id.uuidString).\(ext)")
    }

    static func relativePath(for id: UUID, extension ext: String = "m4a") -> String {
        "\(capturesDirectory)/\(id.uuidString).\(ext)"
    }

    static func fileExists(for id: UUID, extension ext: String = "m4a") -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: id, extension: ext).path)
    }

    static func deleteFile(for id: UUID, extension ext: String = "m4a") throws {
        let url = fileURL(for: id, extension: ext)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
            logger.info("Deleted recording file: \(id.uuidString)")
        }
    }

    static func availableStorage() -> Int64? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values?.volumeAvailableCapacityForImportantUsage
    }

    static func hasMinimumStorage(bytes: Int64 = 50_000_000) -> Bool {
        guard let available = availableStorage() else { return true }
        return available >= bytes
    }
}
