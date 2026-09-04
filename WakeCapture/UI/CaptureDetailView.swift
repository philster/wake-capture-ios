import AVFoundation
import SwiftUI

struct CaptureDetailView: View {
    let capture: CaptureRecord
    @State private var isPlaying = false
    @State private var player: AVAudioPlayer?
    @State private var playerDelegate = PlayerDelegate()

    var body: some View {
        List {
            Section("Recording") {
                LabeledContent("Date", value: capture.createdAt.formatted(date: .long, time: .shortened))
                LabeledContent("Duration", value: formattedDuration)
                LabeledContent("Status", value: capture.state.capitalized)
                LabeledContent("Format", value: "\(capture.codec.uppercased()) • \(Int(capture.sampleRate))Hz • \(capture.channelCount == 1 ? "Mono" : "Stereo")")
            }

            Section {
                Button {
                    togglePlayback()
                } label: {
                    Label(isPlaying ? "Stop Playback" : "Play Recording",
                          systemImage: isPlaying ? "stop.fill" : "play.fill")
                }
                .disabled(!fileExists)
            }

            if let title = capture.title {
                Section("Title") {
                    Text(title)
                }
            }
        }
        .navigationTitle("Capture Details")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            player?.stop()
        }
    }

    private var formattedDuration: String {
        let m = Int(capture.durationSeconds) / 60
        let s = Int(capture.durationSeconds) % 60
        return String(format: "%d:%02d", m, s)
    }

    private var fileExists: Bool {
        RecordingFileStore.fileExists(for: capture.id)
    }

    private func togglePlayback() {
        if isPlaying {
            player?.stop()
            isPlaying = false
            return
        }

        let url = RecordingFileStore.fileURL(for: capture.id)
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            playerDelegate.onFinish = { isPlaying = false }
            player?.delegate = playerDelegate
            player?.play()
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }
}

private class PlayerDelegate: NSObject, AVAudioPlayerDelegate {
    var onFinish: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }
}
