import Foundation
import ScreenCaptureKit
import CoreMedia
import CoreImage
import ImageIO
import AppKit
import os

public enum CaptureError: Error, LocalizedError, CustomStringConvertible, Sendable {
    case permissionDenied(String)
    case noDisplayAvailable
    case streamInitializationFailed(String)
    case timeoutExceeded
    case cancelled

    public var errorDescription: String? {
        description
    }

    public var description: String {
        switch self {
        case .permissionDenied(let msg): return msg
        case .noDisplayAvailable: return "No display available for capture"
        case .streamInitializationFailed(let msg): return "Stream Initialization Failed: \(msg)"
        case .timeoutExceeded: return "Capture exceeded maximum allowed duration (30s)"
        case .cancelled: return "Capture cancelled by user"
        }
    }
}

actor TaskTracker {
    private var inFlightTasks = Set<Task<Void, Never>>()

    func track(_ task: Task<Void, Never>) {
        inFlightTasks.insert(task)
    }

    func untrack(_ task: Task<Void, Never>) {
        inFlightTasks.remove(task)
    }

    func drain() async {
        let tasks = Array(inFlightTasks)
        inFlightTasks.removeAll()
        for t in tasks {
            _ = await t.value
        }
    }
}

final class CaptureStreamOutputHandler: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    private let sampler: FrameSampler
    private let startMonotonicMs: Int64
    private let displayWidth: Int
    private let displayHeight: Int
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private let taskTracker = TaskTracker()
    private let runningLock = os_unfair_lock_t.allocate(capacity: 1)
    private var _isRunning: Bool = true

    init(sampler: FrameSampler, startMonotonicMs: Int64, displayWidth: Int, displayHeight: Int) {
        self.sampler = sampler
        self.startMonotonicMs = startMonotonicMs
        self.displayWidth = displayWidth
        self.displayHeight = displayHeight
        self.runningLock.initialize(to: os_unfair_lock())
        super.init()
    }

    deinit {
        runningLock.deallocate()
    }

    var isRunning: Bool {
        get {
            os_unfair_lock_lock(runningLock)
            defer { os_unfair_lock_unlock(runningLock) }
            return _isRunning
        }
        set {
            os_unfair_lock_lock(runningLock)
            _isRunning = newValue
            os_unfair_lock_unlock(runningLock)
        }
    }

    func stop() {
        isRunning = false
    }

    func drain() async {
        stop()
        await taskTracker.drain()
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard isRunning, type == .screen else { return }
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }

        let nowMs = Int64(DispatchTime.now().uptimeNanoseconds / 1_000_000)
        let relativeTimeMs = max(0, nowMs - startMonotonicMs)

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let jpegData = ciContext.jpegRepresentation(
            of: ciImage,
            colorSpace: colorSpace,
            options: [CIImageRepresentationOption(rawValue: "kCGImageDestinationLossyFactor"): 0.75]
        ) else {
            return
        }

        let task = Task { [weak self] in
            guard let self = self, self.isRunning else { return }
            _ = await self.sampler.sampleFrame(
                relativeTimeMs: relativeTimeMs,
                width: self.displayWidth,
                height: self.displayHeight,
                jpegData: jpegData
            )
        }

        Task { [weak self, task] in
            guard let self = self else { return }
            await self.taskTracker.track(task)
            _ = await task.value
            await self.taskTracker.untrack(task)
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("⚠️ ScreenCaptureKit stream stopped with error: \(error.localizedDescription)")
    }
}

public actor CaptureService {
    public private(set) var isCapturing: Bool = false
    public private(set) var sessionDir: URL?
    public private(set) var sampler: FrameSampler?
    public private(set) var eventRecorder: EventRecorder?

    private var stream: SCStream?
    private var outputHandler: CaptureStreamOutputHandler?
    private var timeoutTask: Task<Void, Never>?
    private var startMonotonicMs: Int64 = 0
    private let captureQueue = DispatchQueue(label: "com.pipsey.screencapture.video", qos: .userInitiated)
    private let maxDurationSeconds: Int = 30

    public init() {}

    public func startCapture(
        sessionId: UUID,
        onTimeout: @escaping @Sendable () -> Void
    ) async throws -> (Dimensions, FrameSampler, EventRecorder) {
        guard !isCapturing else {
            throw CaptureError.streamInitializationFailed("Capture already running")
        }

        // Verify ScreenCaptureKit access:
        // Check CGPreflightScreenCaptureAccess and attempt SCShareableContent.current
        let preflight = CGPreflightScreenCaptureAccess()
        let shareable: SCShareableContent
        do {
            shareable = try await SCShareableContent.current
            PermissionCoordinator.shared.markScreenRecordingGranted()
        } catch {
            _ = CGRequestScreenCaptureAccess()
            if !preflight {
                throw CaptureError.permissionDenied("Screen Recording permission required. Please enable Pipsey in System Settings > Privacy & Security > Screen & System Audio Recording, then press ⌥⌘ again.")
            }
            throw CaptureError.permissionDenied("Screen Recording permission denied: \(error.localizedDescription)")
        }

        // Multi-monitor aware: select display containing user's cursor
        let (screenNumber, screenOrigin) = await MainActor.run { () -> (CGDirectDisplayID?, CGPoint) in
            let mouseLocation = NSEvent.mouseLocation
            let activeScreen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main ?? NSScreen.screens.first
            let num = activeScreen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            let origin = activeScreen?.frame.origin ?? .zero
            return (num, origin)
        }

        var targetDisplay = shareable.displays.first
        if let num = screenNumber, let matched = shareable.displays.first(where: { $0.displayID == num }) {
            targetDisplay = matched
        }

        guard let display = targetDisplay else {
            throw CaptureError.noDisplayAvailable
        }

        let dimensions = Dimensions(width: display.width, height: display.height)
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("pipsey-session-\(sessionId.uuidString)")
        let sampler = FrameSampler(targetFps: 2.0, maxFrames: 60, sessionDirectory: dir)
        let eventRecorder = EventRecorder(displayDimensions: dimensions, screenOrigin: screenOrigin)

        self.sessionDir = dir
        self.sampler = sampler
        self.eventRecorder = eventRecorder
        self.startMonotonicMs = Int64(DispatchTime.now().uptimeNanoseconds / 1_000_000)

        // Setup ContentFilter to capture active screen (excluding Pipsey overlay if detected)
        let excludedWindows = shareable.windows.filter { window in
            guard let title = window.owningApplication?.applicationName else { return false }
            return title.localizedCaseInsensitiveContains("Pipsey")
        }
        let filter = SCContentFilter(display: display, excludingWindows: excludedWindows)

        // Configure stream settings: 15 fps capture, show cursor, 32BGRA
        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = display.height
        config.minimumFrameInterval = CMTime(value: 1, timescale: 15)
        config.queueDepth = 5
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = true

        let handler = CaptureStreamOutputHandler(
            sampler: sampler,
            startMonotonicMs: self.startMonotonicMs,
            displayWidth: display.width,
            displayHeight: display.height
        )
        self.outputHandler = handler

        let scStream = SCStream(filter: filter, configuration: config, delegate: handler)
        do {
            try scStream.addStreamOutput(handler, type: .screen, sampleHandlerQueue: captureQueue)
            try await scStream.startCapture()
        } catch {
            handler.stop()
            self.outputHandler = nil
            throw CaptureError.streamInitializationFailed("Failed to start operational ScreenCaptureKit stream: \(error.localizedDescription)")
        }

        self.stream = scStream
        self.isCapturing = true

        // Start event recording
        await eventRecorder.start(startedAtMonotonicMs: self.startMonotonicMs)

        // Connect click event bursts to sampler
        await eventRecorder.setBurstHandler { [weak sampler] in
            Task {
                await sampler?.requestBurstNext()
            }
        }

        // 30s recording ceiling guard
        self.timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(self?.maxDurationSeconds ?? 30) * 1_000_000_000)
            guard !Task.isCancelled else { return }
            print("⏱️ Screen recording reached ceiling of 30s. Automatically concluding.")
            onTimeout()
        }

        return (dimensions, sampler, eventRecorder)
    }

    public func stop() async -> (Int64, [FrameMetadata], [EventMetadata]) {
        timeoutTask?.cancel()
        timeoutTask = nil
        isCapturing = false

        if let handler = self.outputHandler {
            await handler.drain()
            self.outputHandler = nil
        }

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

        if let handler = self.outputHandler {
            await handler.drain()
            self.outputHandler = nil
        }

        if let stream = self.stream {
            try? await stream.stopCapture()
            self.stream = nil
        }

        await cleanup()
        _ = await eventRecorder?.stop()
        self.eventRecorder = nil
    }

    public func cleanup() async {
        if let dir = self.sessionDir {
            try? FileManager.default.removeItem(at: dir)
            self.sessionDir = nil
        }
        await sampler?.cleanup()
        self.sampler = nil
    }
}
