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
    private var onAudioPowerChange: (@Sendable (Float) -> Void)?

    public init() {}

    public func setAudioPowerHandler(_ handler: (@Sendable (Float) -> Void)?) {
        self.onAudioPowerChange = handler
    }

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

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            request.append(buffer)

            // Compute RMS audio power level for real-time waveform visualization
            if let channelData = buffer.floatChannelData?[0] {
                let frameLength = Int(buffer.frameLength)
                var sum: Float = 0
                for i in 0..<frameLength {
                    let sample = channelData[i]
                    sum += sample * sample
                }
                let rms = sqrt(sum / Float(max(frameLength, 1)))
                let normalized = min(max(rms * 10.0, 0.0), 1.0)
                Task { [weak self] in
                    await self?.publishAudioPower(normalized)
                }
            }
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

    private func publishAudioPower(_ power: Float) {
        onAudioPowerChange?(power)
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

    public func stop() async -> [TranscriptItem] {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        recognitionRequest?.endAudio()

        // Allow in-flight speech recognition to finalize buffers (up to 400ms)
        if let task = recognitionTask, task.state == .running {
            for _ in 0..<8 {
                if task.state == .completed || task.state == .canceling || (transcripts.last?.isFinal == true) {
                    break
                }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }

        recognitionRequest = nil
        recognitionTask?.finish()
        recognitionTask = nil

        onAudioPowerChange?(0.0)
        return transcripts
    }

    public func cancel() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        transcripts = []
        onAudioPowerChange?(0.0)
    }
}
