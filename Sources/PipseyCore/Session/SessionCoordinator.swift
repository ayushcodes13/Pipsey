import Foundation

public enum SessionState: Equatable, Sendable {
    case idle
    case starting
    case listeningAndCapturing
    case stopping
    case processingVisual
    case generatingResponse
    case speaking
    case readyForFollowup
    case cancelling
    case error(String)

    public var isCapturing: Bool {
        self == .listeningAndCapturing
    }

    public var canCancel: Bool {
        switch self {
        case .idle:
            return false
        default:
            return true
        }
    }
}

public actor SessionCoordinator {
    public private(set) var currentState: SessionState = .idle
    public private(set) var currentSessionId: UUID?
    public private(set) var currentGeneration: Int = 0
    public private(set) var currentManifest: EvidenceManifest?
    public private(set) var currentExplanation: ConversationalExplanation?

    private var stateChangeHandlers: [(SessionState) -> Void] = []

    public init() {}

    public func addStateChangeHandler(_ handler: @escaping @Sendable (SessionState) -> Void) {
        stateChangeHandlers.append(handler)
    }

    private func transition(to newState: SessionState) {
        currentState = newState
        for handler in stateChangeHandlers {
            handler(newState)
        }
    }

    public func startSession(targetType: TargetType = .display, targetId: String = "main", dimensions: Dimensions = Dimensions(width: 1440, height: 900)) -> (UUID, Int) {
        guard currentState == .idle || currentState == .readyForFollowup else {
            return (currentSessionId ?? UUID(), currentGeneration)
        }

        currentGeneration += 1
        let newSessionId = UUID()
        currentSessionId = newSessionId
        currentExplanation = nil

        let capture = CaptureInfo(
            targetType: targetType,
            targetId: targetId,
            dimensions: dimensions,
            startedAtMonotonicMs: Int64(DispatchTime.now().uptimeNanoseconds / 1_000_000),
            durationMs: 0,
            permissionState: "active"
        )

        currentManifest = EvidenceManifest(
            sessionId: newSessionId,
            generation: currentGeneration,
            capture: capture,
            recordingStatus: .confirmedStarted,
            evidenceStatus: .pending
        )

        transition(to: .starting)
        return (newSessionId, currentGeneration)
    }

    public func confirmCaptureStarted(generation: Int) {
        guard generation == currentGeneration, currentState == .starting else { return }
        transition(to: .listeningAndCapturing)
    }

    public func appendTranscript(text: String, isFinal: Bool, generation: Int) {
        guard generation == currentGeneration, currentState == .listeningAndCapturing else { return }
        let nowMs = Int64(DispatchTime.now().uptimeNanoseconds / 1_000_000)
        let startMs = currentManifest?.capture.startedAtMonotonicMs ?? nowMs
        let item = TranscriptItem(startMs: 0, endMs: max(0, nowMs - startMs), text: text, isFinal: isFinal)
        currentManifest?.transcripts.append(item)
    }

    public func appendFrame(metadata: FrameMetadata, generation: Int) {
        guard generation == currentGeneration, currentState == .listeningAndCapturing else { return }
        currentManifest?.frames.append(metadata)
    }

    public func appendEvent(metadata: EventMetadata, generation: Int) {
        guard generation == currentGeneration, currentState == .listeningAndCapturing else { return }
        currentManifest?.events.append(metadata)
    }

    public func stopCapture(generation: Int) {
        guard generation == currentGeneration, currentState == .listeningAndCapturing else { return }
        transition(to: .stopping)

        let nowMs = Int64(DispatchTime.now().uptimeNanoseconds / 1_000_000)
        if let startMs = currentManifest?.capture.startedAtMonotonicMs {
            currentManifest?.capture.durationMs = max(0, nowMs - startMs)
        }
        currentManifest?.recordingStatus = .stopped
    }

    public func beginVisualProcessing(generation: Int) {
        guard generation == currentGeneration, currentState == .stopping else { return }
        transition(to: .processingVisual)
    }

    public func visualProcessingCompleted(generation: Int, validated: Bool) {
        guard generation == currentGeneration, currentState == .processingVisual else { return }
        currentManifest?.evidenceStatus = validated ? .validated : .partial
        transition(to: .generatingResponse)
    }

    public func conversationalResponseReady(explanation: ConversationalExplanation, generation: Int, speaks: Bool = false) {
        guard generation == currentGeneration, currentState == .generatingResponse else { return }
        currentExplanation = explanation
        if speaks {
            transition(to: .speaking)
        } else {
            transition(to: .readyForFollowup)
        }
    }

    public func finishSpeaking(generation: Int) {
        guard generation == currentGeneration, currentState == .speaking else { return }
        transition(to: .readyForFollowup)
    }

    public func cancel(generation: Int? = nil) {
        if let gen = generation, gen != currentGeneration {
            return
        }
        guard currentState != .idle else { return }
        transition(to: .cancelling)
        currentManifest?.recordingStatus = .cancelled
        currentManifest?.evidenceStatus = .failed
        transition(to: .idle)
    }

    public func fail(error: String, generation: Int? = nil) {
        if let gen = generation, gen != currentGeneration {
            return
        }
        currentManifest?.recordingStatus = .error
        currentManifest?.evidenceStatus = .failed
        transition(to: .error(error))
    }

    public func resetToIdle() {
        transition(to: .idle)
        currentManifest = nil
        currentExplanation = nil
    }
}
