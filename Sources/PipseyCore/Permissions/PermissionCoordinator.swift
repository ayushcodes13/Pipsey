import Foundation
import AppKit
import AVFoundation
import Speech
import CoreGraphics
import ScreenCaptureKit

public enum ScreenRecordingStatus: String, Sendable {
    case granted
    case denied
    case unknown
}

public enum AudioPermissionStatus: String, Sendable {
    case authorized
    case denied
    case restricted
    case notDetermined
}

public enum SpeechPermissionStatus: String, Sendable {
    case authorized
    case denied
    case restricted
    case notDetermined
}

public struct PermissionSnapshot: Sendable, Equatable {
    public var screenRecording: ScreenRecordingStatus
    public var microphone: AudioPermissionStatus
    public var speechRecognition: SpeechPermissionStatus

    public init(
        screenRecording: ScreenRecordingStatus,
        microphone: AudioPermissionStatus,
        speechRecognition: SpeechPermissionStatus
    ) {
        self.screenRecording = screenRecording
        self.microphone = microphone
        self.speechRecognition = speechRecognition
    }

    public var allGranted: Bool {
        screenRecording == .granted && microphone == .authorized && speechRecognition == .authorized
    }
}

public final class PermissionCoordinator: @unchecked Sendable {
    public static let shared = PermissionCoordinator()
    private let lock = os_unfair_lock_t.allocate(capacity: 1)
    private var _cachedScreenGranted: Bool = false

    public init() {
        lock.initialize(to: os_unfair_lock())
    }

    deinit {
        lock.deallocate()
    }

    public func markScreenRecordingGranted() {
        os_unfair_lock_lock(lock)
        _cachedScreenGranted = true
        os_unfair_lock_unlock(lock)
        UserDefaults.standard.set(true, forKey: "pipsey_screen_recording_granted")
    }

    public func resetScreenRecordingCache() {
        os_unfair_lock_lock(lock)
        _cachedScreenGranted = false
        os_unfair_lock_unlock(lock)
        UserDefaults.standard.removeObject(forKey: "pipsey_screen_recording_granted")
    }

    public func checkScreenRecordingStatus() -> ScreenRecordingStatus {
        os_unfair_lock_lock(lock)
        let isCached = _cachedScreenGranted
        os_unfair_lock_unlock(lock)
        if isCached { return .granted }

        if UserDefaults.standard.bool(forKey: "pipsey_screen_recording_granted") {
            markScreenRecordingGranted()
            return .granted
        }

        if #available(macOS 12.0, *) {
            if CGPreflightScreenCaptureAccess() {
                markScreenRecordingGranted()
                return .granted
            } else {
                return .denied
            }
        }
        return .unknown
    }

    public func verifyScreenRecordingAccess() async -> Bool {
        if checkScreenRecordingStatus() == .granted { return true }
        do {
            _ = try await SCShareableContent.current
            markScreenRecordingGranted()
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    public func requestScreenRecordingAccess() -> Bool {
        if #available(macOS 12.0, *) {
            let granted = CGRequestScreenCaptureAccess()
            if granted {
                markScreenRecordingGranted()
            }
            return granted
        }
        return false
    }

    public func checkMicrophoneStatus() -> AudioPermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    public func requestMicrophoneAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    public func checkSpeechStatus() -> SpeechPermissionStatus {
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    public func requestSpeechAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    public func currentSnapshot() -> PermissionSnapshot {
        PermissionSnapshot(
            screenRecording: checkScreenRecordingStatus(),
            microphone: checkMicrophoneStatus(),
            speechRecognition: checkSpeechStatus()
        )
    }

    public func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    public func openMicrophoneSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    public func openSpeechRecognitionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition") {
            NSWorkspace.shared.open(url)
        }
    }
}
