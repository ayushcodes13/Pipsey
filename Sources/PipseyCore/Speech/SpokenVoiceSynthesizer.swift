import Foundation
import AVFoundation

@MainActor
public final class SpokenVoiceSynthesizer: NSObject, AVSpeechSynthesizerDelegate {
    public static let shared = SpokenVoiceSynthesizer()

    private let synthesizer = AVSpeechSynthesizer()
    private var completionHandler: (() -> Void)?
    public var isMuted: Bool = false

    override public init() {
        super.init()
        synthesizer.delegate = self
    }

    public var isSpeaking: Bool {
        synthesizer.isSpeaking
    }

    public func speak(_ text: String, completion: (() -> Void)? = nil) {
        guard !isMuted, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion?()
            return
        }

        stop()
        self.completionHandler = completion

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.05
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.9

        synthesizer.speak(utterance)
    }

    public func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        completionHandler = nil
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            let handler = self.completionHandler
            self.completionHandler = nil
            handler?()
        }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.completionHandler = nil
        }
    }
}
