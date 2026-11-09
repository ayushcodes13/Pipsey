import Foundation

/// Evidence Manifest version 0.1 matching API_CONTRACTS.md
public struct EvidenceManifest: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = "0.1"

    public var schemaVersion: String
    public var sessionId: UUID
    public var generation: Int
    public var capture: CaptureInfo
    public var frames: [FrameMetadata]
    public var events: [EventMetadata]
    public var transcripts: [TranscriptItem]
    public var recordingStatus: RecordingStatus
    public var evidenceStatus: EvidenceStatus

    public init(
        schemaVersion: String = EvidenceManifest.currentSchemaVersion,
        sessionId: UUID = UUID(),
        generation: Int = 1,
        capture: CaptureInfo,
        frames: [FrameMetadata] = [],
        events: [EventMetadata] = [],
        transcripts: [TranscriptItem] = [],
        recordingStatus: RecordingStatus = .confirmedStarted,
        evidenceStatus: EvidenceStatus = .pending
    ) {
        self.schemaVersion = schemaVersion
        self.sessionId = sessionId
        self.generation = generation
        self.capture = capture
        self.frames = frames
        self.events = events
        self.transcripts = transcripts
        self.recordingStatus = recordingStatus
        self.evidenceStatus = evidenceStatus
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case sessionId = "session_id"
        case generation
        case capture
        case frames
        case events
        case transcripts
        case recordingStatus = "recording_status"
        case evidenceStatus = "evidence_status"
    }
}

public struct CaptureInfo: Codable, Equatable, Sendable {
    public var targetType: TargetType
    public var targetId: String
    public var dimensions: Dimensions
    public var startedAtMonotonicMs: Int64
    public var durationMs: Int64
    public var permissionState: String

    public init(
        targetType: TargetType,
        targetId: String,
        dimensions: Dimensions,
        startedAtMonotonicMs: Int64,
        durationMs: Int64,
        permissionState: String
    ) {
        self.targetType = targetType
        self.targetId = targetId
        self.dimensions = dimensions
        self.startedAtMonotonicMs = startedAtMonotonicMs
        self.durationMs = durationMs
        self.permissionState = permissionState
    }

    enum CodingKeys: String, CodingKey {
        case targetType = "target_type"
        case targetId = "target_id"
        case dimensions
        case startedAtMonotonicMs = "started_at_monotonic_ms"
        case durationMs = "duration_ms"
        case permissionState = "permission_state"
    }
}

public enum TargetType: String, Codable, Sendable {
    case window
    case display
}

public struct Dimensions: Codable, Equatable, Sendable {
    public var width: Int
    public var height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

public struct FrameMetadata: Codable, Equatable, Sendable {
    public var frameId: String
    public var relativeTimeMs: Int64
    public var width: Int
    public var height: Int
    public var sha256: String
    public var localRef: String

    public init(
        frameId: String,
        relativeTimeMs: Int64,
        width: Int,
        height: Int,
        sha256: String,
        localRef: String
    ) {
        self.frameId = frameId
        self.relativeTimeMs = relativeTimeMs
        self.width = width
        self.height = height
        self.sha256 = sha256
        self.localRef = localRef
    }

    enum CodingKeys: String, CodingKey {
        case frameId = "frame_id"
        case relativeTimeMs = "relative_time_ms"
        case width
        case height
        case sha256
        case localRef = "local_ref"
    }
}

public struct EventMetadata: Codable, Equatable, Sendable {
    public var type: EventType
    public var relativeTimeMs: Int64
    public var normalizedPosition: NormalizedPosition?

    public init(
        type: EventType,
        relativeTimeMs: Int64,
        normalizedPosition: NormalizedPosition? = nil
    ) {
        self.type = type
        self.relativeTimeMs = relativeTimeMs
        self.normalizedPosition = normalizedPosition
    }

    enum CodingKeys: String, CodingKey {
        case type
        case relativeTimeMs = "relative_time_ms"
        case normalizedPosition = "normalized_position"
    }
}

public enum EventType: String, Codable, Sendable {
    case cursorMove = "cursor_move"
    case mouseDown = "mouse_down"
    case mouseUp = "mouse_up"
    case scroll = "scroll"
}

public struct NormalizedPosition: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct TranscriptItem: Codable, Equatable, Sendable {
    public var startMs: Int64
    public var endMs: Int64
    public var text: String
    public var isFinal: Bool

    public init(
        startMs: Int64,
        endMs: Int64,
        text: String,
        isFinal: Bool
    ) {
        self.startMs = startMs
        self.endMs = endMs
        self.text = text
        self.isFinal = isFinal
    }

    enum CodingKeys: String, CodingKey {
        case startMs = "start_ms"
        case endMs = "end_ms"
        case text
        case isFinal = "is_final"
    }
}

public enum RecordingStatus: String, Codable, Sendable {
    case confirmedStarted = "confirmed_started"
    case stopped = "stopped"
    case cancelled = "cancelled"
    case error = "error"
}

public enum EvidenceStatus: String, Codable, Sendable {
    case pending = "pending"
    case validated = "validated"
    case partial = "partial"
    case failed = "failed"
}

public struct ObserverResponse: Codable, Equatable, Sendable {
    public var schemaVersion: String
    public var sessionId: String
    public var requestId: String
    public var observations: [Observation]
    public var coverage: TimeCoverage
    public var unknowns: [String]

    public init(
        schemaVersion: String = "0.1",
        sessionId: String,
        requestId: String,
        observations: [Observation],
        coverage: TimeCoverage,
        unknowns: [String] = []
    ) {
        self.schemaVersion = schemaVersion
        self.sessionId = sessionId
        self.requestId = requestId
        self.observations = observations
        self.coverage = coverage
        self.unknowns = unknowns
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case sessionId = "session_id"
        case requestId = "request_id"
        case observations
        case coverage
        case unknowns
    }
}

public struct Observation: Codable, Equatable, Sendable {
    public var id: String
    public var startMs: Int64
    public var endMs: Int64
    public var kind: String
    public var before: String
    public var after: String
    public var evidenceFrameIds: [String]
    public var triggerHypothesis: String?
    public var confidenceLabel: ConfidenceLabel
    public var uncertainties: [String]

    public init(
        id: String,
        startMs: Int64,
        endMs: Int64,
        kind: String = "visible_change",
        before: String,
        after: String,
        evidenceFrameIds: [String],
        triggerHypothesis: String? = nil,
        confidenceLabel: ConfidenceLabel = .medium,
        uncertainties: [String] = []
    ) {
        self.id = id
        self.startMs = startMs
        self.endMs = endMs
        self.kind = kind
        self.before = before
        self.after = after
        self.evidenceFrameIds = evidenceFrameIds
        self.triggerHypothesis = triggerHypothesis
        self.confidenceLabel = confidenceLabel
        self.uncertainties = uncertainties
    }

    enum CodingKeys: String, CodingKey {
        case id
        case startMs = "start_ms"
        case endMs = "end_ms"
        case kind
        case before
        case after
        case evidenceFrameIds = "evidence_frame_ids"
        case triggerHypothesis = "trigger_hypothesis"
        case confidenceLabel = "confidence_label"
        case uncertainties
    }
}

public enum ConfidenceLabel: String, Codable, Sendable {
    case high
    case medium
    case low
}

public struct TimeCoverage: Codable, Equatable, Sendable {
    public var startMs: Int64
    public var endMs: Int64

    public init(startMs: Int64, endMs: Int64) {
        self.startMs = startMs
        self.endMs = endMs
    }

    enum CodingKeys: String, CodingKey {
        case startMs = "start_ms"
        case endMs = "end_ms"
    }
}

public struct ConversationalExplanation: Codable, Equatable, Sendable {
    public var observedBehavior: String
    public var likelyMechanism: String
    public var implementationApproach: String
    public var uncertainties: [String]
    public var spokenSummary: String
    public var detailedMarkdown: String

    public init(
        observedBehavior: String,
        likelyMechanism: String,
        implementationApproach: String,
        uncertainties: [String] = [],
        spokenSummary: String,
        detailedMarkdown: String
    ) {
        self.observedBehavior = observedBehavior
        self.likelyMechanism = likelyMechanism
        self.implementationApproach = implementationApproach
        self.uncertainties = uncertainties
        self.spokenSummary = spokenSummary
        self.detailedMarkdown = detailedMarkdown
    }

    enum CodingKeys: String, CodingKey {
        case observedBehavior = "observed_behavior"
        case likelyMechanism = "likely_mechanism"
        case implementationApproach = "implementation_approach"
        case uncertainties
        case spokenSummary = "spoken_summary"
        case detailedMarkdown = "detailed_markdown"
    }
}
