import AppKit
import AudioToolbox

/// Native macOS tactile sound effects for session lifecycle feedback (inspired by Clicky).
public enum PipseySoundEffects: Sendable {
    @MainActor
    public static func play(name: String) {
        let soundEnabled = UserDefaults.standard.object(forKey: "pipsey_sound_effects_enabled") as? Bool ?? true
        guard soundEnabled else { return }

        let systemPath = "/System/Library/Sounds/\(name).aiff"
        let url = URL(fileURLWithPath: systemPath)

        // 1. Fresh NSSound instance from file URL: prevents singleton state collision on rapid playback
        if FileManager.default.fileExists(atPath: systemPath),
           let sound = NSSound(contentsOf: url, byReference: true) {
            sound.volume = 1.0
            if sound.play() {
                return
            }
        }

        // 2. Fallback to named system sound with position reset
        if let namedSound = NSSound(named: NSSound.Name(name)) {
            namedSound.stop()
            namedSound.currentTime = 0
            if namedSound.play() {
                return
            }
        }

        // 3. AudioServices system sound fallback for low-latency playback
        var soundID: SystemSoundID = 0
        if AudioServicesCreateSystemSoundID(url as CFURL, &soundID) == noErr {
            AudioServicesPlaySystemSound(soundID)
        }
    }

    @MainActor
    public static func playCaptureStarted() {
        play(name: "Tink")
    }

    @MainActor
    public static func playCaptureStopped() {
        play(name: "Pop")
    }

    @MainActor
    public static func playResponseReady() {
        play(name: "Glass")
    }

    @MainActor
    public static func playCopyFeedback() {
        play(name: "Bottle")
    }

    @MainActor
    public static func playTelescopeFocus() {
        play(name: "Ping")
    }

    @MainActor
    public static func playIdlePeekingSound() {
        play(name: "Pop")
    }
}
