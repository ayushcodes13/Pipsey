import Foundation
import ScreenCaptureKit
import CoreMedia
import CoreGraphics

public enum CaptureError: Error, CustomStringConvertible, Sendable {
    case permissionDenied(String)
    case noDisplayAvailable
    case streamInitializationFailed(String)
    case timeoutExceeded

    public var description: String {
        switch self {
        case .permissionDenied(let msg): return "Screen Capture Permission Denied: \(msg)"
        case .noDisplayAvailable: return "No active display available for capture"
        case .streamInitializationFailed(let msg): return "Stream Initialization Failed: \(msg)"
        case .timeoutExceeded: return "Capture reached maximum 30-second ceiling"
        }
    }
}

public actor CaptureService {
    public private(set) var isCapturing: Bool = false
    public private(set) var startMonotonicMs: Int64 = 0
    public private(set) var sessionDir: URL?
    public private(set) var sampler: FrameSampler?
    public private(set) var eventRecorder: EventRecorder?

    private var timeoutTask: Task<Void, Never>?
    private var stream: SCStream?
    private let maxDurationSeconds: Int = 30

    public init() {}

    public func startCapture(
        sessionId: UUID,
        onTimeout: @escaping @Sendable () -> Void
    ) async throws -> (Dimensions, FrameSampler, EventRecorder) {
        guard !isCapturing else {
            throw CaptureError.streamInitializationFailed("Capture already running")
        }

        // Preflight ScreenCaptureKit access
        guard CGPreflightScreenCaptureAccess() else {
            throw CaptureError.permissionDenied("Screen recording permission declined in System Settings (Error -3801)")
        }

        let shareable: SCShareableContent
        do {
            shareable = try await SCShareableContent.current
        } catch {
            throw CaptureError.permissionDenied("Failed to access SCShareableContent: \(error.localizedDescription)")
        }

        guard let display = shareable.displays.first else {
            throw CaptureError.noDisplayAvailable
        }

        let dimensions = Dimensions(width: display.width, height: display.height)
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("pipsey-session-\(sessionId.uuidString)")
        let sampler = FrameSampler(targetFps: 2.0, maxFrames: 60, sessionDirectory: dir)
        let eventRecorder = EventRecorder(displayDimensions: dimensions)

        self.sessionDir = dir
        self.sampler = sampler
        self.eventRecorder = eventRecorder
        self.startMonotonicMs = Int64(DispatchTime.now().uptimeNanoseconds / 1_000_000)
        self.isCapturing = true

        await eventRecorder.start(startedAtMonotonicMs: self.startMonotonicMs)

        // Setup 30-second hard ceiling
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(30_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.handleTimeout()
            onTimeout()
        }

        return (dimensions, sampler, eventRecorder)
    }

    private func handleTimeout() {
        self.isCapturing = false
    }

    public func stop() async -> (durationMs: Int64, frames: [FrameMetadata], events: [EventMetadata]) {
        timeoutTask?.cancel()
        timeoutTask = nil
        isCapturing = false

        if let stream = self.stream {
            try? await stream.stopCapture()
            self.stream = nil
        }

        let nowMs = Int64(DispatchTime.now().uptimeNanoseconds / 1_000_000)
        let durationMs = max(0, nowMs - startMonotonicMs)

        let frames = await sampler?.sampledFrames ?? []
        let events = await eventRecorder?.stop() ?? []

        return (durationMs, frames, events)
    }

    public func cancel() async {
        timeoutTask?.cancel()
        timeoutTask = nil
        isCapturing = false

        if let stream = self.stream {
            try? await stream.stopCapture()
            self.stream = nil
        }

        await sampler?.cleanup()
        _ = await eventRecorder?.stop()
        self.sampler = nil
        self.eventRecorder = nil
    }
}
