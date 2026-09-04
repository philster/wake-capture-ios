import AVFoundation
import OSLog

protocol AudioRecording: Sendable {
    var captureId: UUID { get }
    var fileURL: URL { get }
    var isRecording: Bool { get }
    func start() throws
    func stop() async -> RecordingResult
    func stopSync() -> RecordingResult
}

typealias AudioRecorderFactory = @Sendable (UUID) throws -> any AudioRecording

final class AudioRecorder: NSObject, AudioRecording, AVAudioRecorderDelegate {
    private let logger = Logger(subsystem: "com.wakecapture", category: "AudioRecorder")

    private let recorder: AVAudioRecorder
    let fileURL: URL
    let captureId: UUID

    private let _isRecording = OSAllocatedUnfairLock(initialState: false)
    private let _onFinish = OSAllocatedUnfairLock<(@Sendable (Bool) -> Void)?>(initialState: nil)

    var isRecording: Bool { _isRecording.withLock { $0 } }

    var currentTime: TimeInterval { recorder.currentTime }

    init(captureId: UUID) throws {
        self.captureId = captureId
        try RecordingFileStore.ensureDirectory()
        self.fileURL = RecordingFileStore.fileURL(for: captureId)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            self.recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        } catch {
            throw CaptureError.recorderStartFailed(underlying: error)
        }

        super.init()
        recorder.delegate = self
    }

    func start() throws {
        guard !isRecording else { throw CaptureError.alreadyRecording }
        recorder.prepareToRecord()
        guard recorder.record() else {
            throw CaptureError.recorderStartFailed(
                underlying: NSError(domain: "AudioRecorder", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "record() returned false"])
            )
        }
        _isRecording.withLock { $0 = true }
        logger.info("Recording started: \(self.captureId.uuidString)")
    }

    func stop() async -> RecordingResult {
        guard isRecording else {
            return RecordingResult(
                captureId: captureId, fileURL: fileURL, durationSeconds: 0, succeeded: false
            )
        }
        let duration = recorder.currentTime
        return await withCheckedContinuation { continuation in
            _onFinish.withLock { $0 = { succeeded in
                continuation.resume(returning: RecordingResult(
                    captureId: self.captureId,
                    fileURL: self.fileURL,
                    durationSeconds: duration,
                    succeeded: succeeded
                ))
            }}
            recorder.stop()
            _isRecording.withLock { $0 = false }
            logger.info("Recording stopped: \(self.captureId.uuidString), duration: \(duration)s")
        }
    }

    func stopSync() -> RecordingResult {
        let duration = recorder.currentTime
        recorder.stop()
        _isRecording.withLock { $0 = false }
        let exists = FileManager.default.fileExists(atPath: fileURL.path)
        return RecordingResult(
            captureId: captureId, fileURL: fileURL, durationSeconds: duration, succeeded: exists
        )
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        logger.info("Recorder finished, success: \(flag)")
        _onFinish.withLock { callback in
            callback?(flag)
            callback = nil
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        logger.error("Recorder encode error: \(error?.localizedDescription ?? "unknown")")
        _onFinish.withLock { callback in
            callback?(false)
            callback = nil
        }
    }
}

struct RecordingResult: Sendable {
    let captureId: UUID
    let fileURL: URL
    let durationSeconds: Double
    let succeeded: Bool
}
