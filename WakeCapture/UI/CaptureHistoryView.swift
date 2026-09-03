import SwiftData
import SwiftUI

struct CaptureHistoryView: View {
    @Query(sort: \CaptureRecord.createdAt, order: .reverse) private var captures: [CaptureRecord]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            if captures.isEmpty {
                ContentUnavailableView(
                    "No Captures",
                    systemImage: "waveform",
                    description: Text("Your recordings will appear here.")
                )
            } else {
                ForEach(captures) { capture in
                    NavigationLink {
                        CaptureDetailView(capture: capture)
                    } label: {
                        CaptureRow(capture: capture)
                    }
                }
                .onDelete(perform: deleteCapturesAt)
            }
        }
        .navigationTitle("Captures")
    }

    private func deleteCapturesAt(_ offsets: IndexSet) {
        for index in offsets {
            let capture = captures[index]
            try? RecordingFileStore.deleteFile(for: capture.id)
            modelContext.delete(capture)
        }
        try? modelContext.save()
    }
}

struct CaptureRow: View {
    let capture: CaptureRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(capture.title ?? formattedDate)
                .font(.body)
                .fontWeight(.medium)

            HStack(spacing: 12) {
                Label(formattedDuration, systemImage: "clock")
                Label(capture.state, systemImage: stateIcon)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var formattedDate: String {
        capture.createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    private var formattedDuration: String {
        let m = Int(capture.durationSeconds) / 60
        let s = Int(capture.durationSeconds) % 60
        return String(format: "%d:%02d", m, s)
    }

    private var stateIcon: String {
        switch capture.state {
        case "saved": return "checkmark.circle"
        case "interrupted": return "exclamationmark.triangle"
        case "failed": return "xmark.circle"
        default: return "questionmark.circle"
        }
    }
}
