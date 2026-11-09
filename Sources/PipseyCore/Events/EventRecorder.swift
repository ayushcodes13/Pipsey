import Foundation
import AppKit

@MainActor
final class SystemMouseMonitor {
    static let shared = SystemMouseMonitor()
    private var globalMonitor: Any?
    private var localMonitor: Any?

    private init() {}

    func start(handler: @escaping @Sendable (NSEvent.EventType, CGPoint) -> Void) {
        stop()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseUp, .rightMouseDown, .mouseMoved]
        ) { event in
            handler(event.type, NSEvent.mouseLocation)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseUp, .rightMouseDown, .mouseMoved]
        ) { event in
            handler(event.type, NSEvent.mouseLocation)
            return event
        }
    }

    func stop() {
        if let g = globalMonitor {
            NSEvent.removeMonitor(g)
            globalMonitor = nil
        }
        if let l = localMonitor {
            NSEvent.removeMonitor(l)
            localMonitor = nil
        }
    }
}

public actor EventRecorder {
    public private(set) var events: [EventMetadata] = []
    private var isRecording: Bool = false
    private var startedAtMonotonicMs: Int64 = 0
    private var displayDimensions: Dimensions
    private var screenOrigin: CGPoint
    private var lastMouseMoveRecordedMs: Int64 = 0
    private var onBurst: (@Sendable () -> Void)?

    public init(displayDimensions: Dimensions = Dimensions(width: 1440, height: 900), screenOrigin: CGPoint = .zero) {
        self.displayDimensions = displayDimensions
        self.screenOrigin = screenOrigin
    }

    public func setBurstHandler(_ handler: (@Sendable () -> Void)?) {
        self.onBurst = handler
    }

    public func start(startedAtMonotonicMs: Int64) {
        self.startedAtMonotonicMs = startedAtMonotonicMs
        self.isRecording = true
        self.events = []
        self.lastMouseMoveRecordedMs = 0

        // Install system mouse monitoring on MainActor / AppKit runloop
        Task { @MainActor in
            SystemMouseMonitor.shared.start { [weak self] eventType, screenPoint in
                guard let self = self else { return }
                Task {
                    await self.handleSystemMouseEvent(type: eventType, screenPoint: screenPoint)
                }
            }
        }
    }

    private func handleSystemMouseEvent(type: NSEvent.EventType, screenPoint: CGPoint) {
        guard isRecording else { return }
        let nowMs = Int64(DispatchTime.now().uptimeNanoseconds / 1_000_000)
        let relativeTimeMs = max(0, nowMs - startedAtMonotonicMs)

        switch type {
        case .leftMouseDown:
            recordClick(type: .mouseDown, x: screenPoint.x, y: screenPoint.y, relativeTimeMs: relativeTimeMs)
            onBurst?()
        case .leftMouseUp:
            recordClick(type: .mouseUp, x: screenPoint.x, y: screenPoint.y, relativeTimeMs: relativeTimeMs)
        case .rightMouseDown:
            recordClick(type: .mouseDown, x: screenPoint.x, y: screenPoint.y, relativeTimeMs: relativeTimeMs)
            onBurst?()
        case .mouseMoved:
            // Rate limit mouse moves to max 15 Hz (~66ms interval) to bound memory
            if relativeTimeMs - lastMouseMoveRecordedMs >= 66 {
                lastMouseMoveRecordedMs = relativeTimeMs
                recordCursor(x: screenPoint.x, y: screenPoint.y, relativeTimeMs: relativeTimeMs)
            }
        default:
            break
        }
    }

    public func recordCursor(x: Double, y: Double, relativeTimeMs: Int64) {
        guard isRecording else { return }
        let relX = x - Double(screenOrigin.x)
        let relY = y - Double(screenOrigin.y)
        let normX = max(0.0, min(1.0, relX / Double(displayDimensions.width)))
        // Convert Cocoa bottom-left origin to normalized 0-1 (top-left)
        let rawNormY = relY / Double(displayDimensions.height)
        let normY = max(0.0, min(1.0, 1.0 - rawNormY))

        events.append(EventMetadata(
            type: .cursorMove,
            relativeTimeMs: relativeTimeMs,
            normalizedPosition: NormalizedPosition(x: normX, y: normY)
        ))
    }

    public func recordClick(type: EventType, x: Double, y: Double, relativeTimeMs: Int64) {
        guard isRecording else { return }
        let relX = x - Double(screenOrigin.x)
        let relY = y - Double(screenOrigin.y)
        let normX = max(0.0, min(1.0, relX / Double(displayDimensions.width)))
        let rawNormY = relY / Double(displayDimensions.height)
        let normY = max(0.0, min(1.0, 1.0 - rawNormY))

        events.append(EventMetadata(
            type: type,
            relativeTimeMs: relativeTimeMs,
            normalizedPosition: NormalizedPosition(x: normX, y: normY)
        ))
    }

    public func stop() -> [EventMetadata] {
        self.isRecording = false
        Task { @MainActor in
            SystemMouseMonitor.shared.stop()
        }
        return events
    }
}
