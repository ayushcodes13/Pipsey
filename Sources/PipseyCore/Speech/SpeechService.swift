import Foundation
import Speech
import AVFoundation

public actor SpeechService {
    public private(set) var transcripts: [TranscriptItem] = []
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var startMonotonicMs: Int64 = 0

    public init() {}

    public func startListening(startedAtMonotonicMs: Int64) async throws {
        self.startMonotonicMs = startedAtMonotonicMs
        self.transcripts = []

        guard SFSpeechRecognizer.authorizationStatus() == .authorized,
              AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
            // Audio/Speech not granted; operates in silent/typed fallback mode
            return
        }

        let audioEngine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        self.audioEngine = audioEngine
        self.recognitionRequest = request

        self.recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self, let result = result else { return }
            let text = result.bestTranscription.formattedString
            let isFinal = result.isFinal
            Task {
                await self.appendRecognizedText(text: text, isFinal: isFinal)
            }
        }
    }

    public func appendRecognizedText(text: String, isFinal: Bool) {
        let nowMs = Int64(DispatchTime.now().uptimeNanoseconds / 1_000_000)
        let elapsed = max(0, nowMs - startMonotonicMs)
        transcripts.append(TranscriptItem(startMs: 0, endMs: elapsed, text: text, isFinal: isFinal))
    }

    public func addTypedQuestion(_ text: String) {
        let nowMs = Int64(DispatchTime.now().uptimeNanoseconds / 1_000_000)
        let elapsed = max(0, nowMs - startMonotonicMs)
        transcripts.append(TranscriptItem(startMs: 0, endMs: elapsed, text: text, isFinal: true))
    }

    public func stop() -> [TranscriptItem] {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        return transcripts
    }

    public func cancel() {
        _ = stop()
        transcripts = []
    }
}
