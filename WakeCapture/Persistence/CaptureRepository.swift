import Foundation
import SwiftData
import OSLog

@ModelActor
actor CaptureRepository {
    private let logger = Logger(subsystem: "com.wakecapture", category: "Repository")

    func save(_ record: CaptureRecord) throws {
        modelContext.insert(record)
        try modelContext.save()
        logger.info("Saved capture: \(record.id.uuidString)")
    }

    func update(_ id: UUID, duration: Double, state: String) throws {
        let predicate = #Predicate<CaptureRecord> { $0.id == id }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        guard let record = try modelContext.fetch(descriptor).first else { return }
        record.durationSeconds = duration
        record.state = state
        try modelContext.save()
    }

    func fetchAll() throws -> [CaptureRecord] {
        let descriptor = FetchDescriptor<CaptureRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetch(id: UUID) throws -> CaptureRecord? {
        let predicate = #Predicate<CaptureRecord> { $0.id == id }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func delete(id: UUID) throws {
        let predicate = #Predicate<CaptureRecord> { $0.id == id }
        try modelContext.delete(model: CaptureRecord.self, where: predicate)
        try modelContext.save()
        try? RecordingFileStore.deleteFile(for: id)
        logger.info("Deleted capture: \(id.uuidString)")
    }
}
