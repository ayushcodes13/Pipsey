import AppKit

/// Native macOS tactile sound effects for session lifecycle feedback (inspired by Clicky).
public enum PipseySoundEffects: Sendable {
    @MainActor
    public static func playCaptureStarted() {
        NSSound(named: "Tink")?.play()
    }

    @MainActor
    public static func playCaptureStopped() {
        NSSound(named: "Pop")?.play()
    }

    @MainActor
    public static func playResponseReady() {
        NSSound(named: "Glass")?.play()
    }

    @MainActor
    public static func playCopyFeedback() {
        NSSound(named: "Bottle")?.play()
    }

    @MainActor
    public static func playTelescopeFocus() {
        NSSound(named: "Ping")?.play()
    }

    @MainActor
    public static func playIdlePeekingSound() {
        NSSound(named: "Pop")?.play()
    }
}
