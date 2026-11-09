import Foundation
import AppKit

public actor EventRecorder {
    public private(set) var events: [EventMetadata] = []
    private var isRecording: Bool = false
    private var startedAtMonotonicMs: Int64 = 0
    private var displayDimensions: Dimensions

    public init(displayDimensions: Dimensions = Dimensions(width: 1440, height: 900)) {
        self.displayDimensions = displayDimensions
    }

    public func start(startedAtMonotonicMs: Int64) {
        self.startedAtMonotonicMs = startedAtMonotonicMs
        self.isRecording = true
        self.events = []
    }

    public func recordCursor(x: Double, y: Double, relativeTimeMs: Int64) {
        guard isRecording else { return }
        let normX = max(0.0, min(1.0, x / Double(displayDimensions.width)))
        let normY = max(0.0, min(1.0, y / Double(displayDimensions.height)))
        events.append(EventMetadata(
            type: .cursorMove,
            relativeTimeMs: relativeTimeMs,
            normalizedPosition: NormalizedPosition(x: normX, y: normY)
        ))
    }

    public func recordClick(type: EventType, x: Double, y: Double, relativeTimeMs: Int64) {
        guard isRecording else { return }
        let normX = max(0.0, min(1.0, x / Double(displayDimensions.width)))
        let normY = max(0.0, min(1.0, y / Double(displayDimensions.height)))
        events.append(EventMetadata(
            type: type,
            relativeTimeMs: relativeTimeMs,
            normalizedPosition: NormalizedPosition(x: normX, y: normY)
        ))
    }

    public func stop() -> [EventMetadata] {
        self.isRecording = false
        return events
    }
}
