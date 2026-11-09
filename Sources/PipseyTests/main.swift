import Foundation
import AppKit
import PipseyCore

final class AtomicBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: T

    init(_ value: T) {
        self.value = value
    }

    func set(_ value: T) {
        lock.lock()
        defer { lock.unlock() }
        self.value = value
    }

    func get() -> T {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func mutate(_ transform: (inout T) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        transform(&value)
    }
}

@MainActor
func runAllTests() async -> (passed: Int, failed: Int) {
    var passed = 0
    var failed = 0

    func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
        if actual != expected {
            print("❌ FAIL: Expected \(expected), got \(actual). \(message) at \(file):\(line)")
            failed += 1
        } else {
            passed += 1
        }
    }

    func assertTrue(_ condition: Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
        if !condition {
            print("❌ FAIL: Condition is false. \(message) at \(file):\(line)")
            failed += 1
        } else {
            passed += 1
        }
    }

    print("=========================================")
    print("RUNNING PIPSEY VERIFICATION TEST SUITE")
    print("=========================================")

    // TEST 1: SessionCoordinator Lifecycle
    print("\n--- Test 1: SessionCoordinator Lifecycle ---")
    let coordinator = SessionCoordinator()
    let stateTransitions = AtomicBox<[SessionState]>([])
    await coordinator.addStateChangeHandler { state in
        stateTransitions.mutate { $0.append(state) }
    }

    let (_, gen) = await coordinator.startSession(targetType: .display, targetId: "test_disp")
    assertEqual(await coordinator.currentState, .starting, "State should be starting")
    assertEqual(await coordinator.currentGeneration, gen, "Generation must match")

    await coordinator.confirmCaptureStarted(generation: gen)
    assertEqual(await coordinator.currentState, .listeningAndCapturing, "State should be listeningAndCapturing")

    // Append metadata
    await coordinator.appendTranscript(text: "How does this button hover work?", isFinal: true, generation: gen)
    await coordinator.appendFrame(metadata: FrameMetadata(frameId: "f01", relativeTimeMs: 100, width: 1440, height: 900, sha256: "dummyhash", localRef: "ref01"), generation: gen)
    await coordinator.appendFrame(metadata: FrameMetadata(frameId: "f02", relativeTimeMs: 400, width: 1440, height: 900, sha256: "dummyhash2", localRef: "ref02"), generation: gen)

    await coordinator.stopCapture(generation: gen)
    assertEqual(await coordinator.currentState, .stopping, "State should be stopping")

    await coordinator.beginVisualProcessing(generation: gen)
    assertEqual(await coordinator.currentState, .processingVisual, "State should be processingVisual")

    await coordinator.visualProcessingCompleted(generation: gen, validated: true)
    assertEqual(await coordinator.currentState, .generatingResponse, "State should be generatingResponse")

    let explanation = ConversationalExplanation(
        observedBehavior: "Menu appeared on hover",
        likelyMechanism: "CSS :hover or mouseEnter event listener",
        implementationApproach: "Use conditional rendering in React",
        spokenSummary: "The menu expanded when hovered.",
        detailedMarkdown: "Full details..."
    )
    await coordinator.conversationalResponseReady(explanation: explanation, generation: gen, speaks: true)
    assertEqual(await coordinator.currentState, .speaking, "State should be speaking")

    await coordinator.finishSpeaking(generation: gen)
    assertEqual(await coordinator.currentState, .readyForFollowup, "State should be readyForFollowup")

    // TEST 2: Cancellation & Generation Isolation
    print("\n--- Test 2: Cancellation & Generation Isolation ---")
    let (_, gen2) = await coordinator.startSession()
    assertTrue(gen2 > gen, "New generation should increment")
    await coordinator.confirmCaptureStarted(generation: gen2)
    assertEqual(await coordinator.currentState, .listeningAndCapturing, "State is capturing")

    // Attempt mutation with stale generation (gen)
    await coordinator.stopCapture(generation: gen)
    assertEqual(await coordinator.currentState, .listeningAndCapturing, "Stale generation cannot mutate state")

    // Cancel active generation
    await coordinator.cancel(generation: gen2)
    assertEqual(await coordinator.currentState, .idle, "Cancelled session should return to idle")

    // TEST 3: EvidenceManifest Encoding & API Schema Match
    print("\n--- Test 3: Evidence Manifest JSON Serialization ---")
    let manifest = EvidenceManifest(
        sessionId: UUID(),
        generation: 1,
        capture: CaptureInfo(
            targetType: .display,
            targetId: "disp-1",
            dimensions: Dimensions(width: 1440, height: 900),
            startedAtMonotonicMs: 1000,
            durationMs: 5000,
            permissionState: "active"
        ),
        frames: [
            FrameMetadata(frameId: "frame-01", relativeTimeMs: 100, width: 1440, height: 900, sha256: "abc", localRef: "/tmp/f1.jpg")
        ],
        events: [
            EventMetadata(type: .cursorMove, relativeTimeMs: 150, normalizedPosition: NormalizedPosition(x: 0.5, y: 0.5))
        ],
        transcripts: [
            TranscriptItem(startMs: 0, endMs: 2000, text: "Explain this animation", isFinal: true)
        ]
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
    do {
        let data = try encoder.encode(manifest)
        let jsonString = String(data: data, encoding: .utf8)!
        assertTrue(jsonString.contains("\"schema_version\" : \"0.1\""), "Schema version present")
        assertTrue(jsonString.contains("\"target_type\" : \"display\""), "Target type present")
        assertTrue(jsonString.contains("\"frame_id\" : \"frame-01\""), "Frame ID present")
        assertTrue(jsonString.contains("\"normalized_position\""), "Position present")

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(EvidenceManifest.self, from: data)
        assertEqual(decoded.sessionId, manifest.sessionId, "Decoded session ID matches")
        assertEqual(decoded.frames.count, 1, "Decoded frames count matches")
    } catch {
        print("❌ FAIL: Manifest encoding/decoding failed: \(error)")
        failed += 1
    }

    // TEST 4: ObservationValidator Acceptance & Rejection
    print("\n--- Test 4: ObservationValidator ---")
    let validator = ObservationValidator()
    let validSessionId = UUID()
    let validResponse = ObserverResponse(
        schemaVersion: "0.1",
        sessionId: validSessionId.uuidString,
        requestId: "req-1",
        observations: [
            Observation(
                id: "obs-1",
                startMs: 200,
                endMs: 800,
                kind: "visible_change",
                before: "button normal",
                after: "button highlighted",
                evidenceFrameIds: ["f-01", "f-02"],
                triggerHypothesis: "hover",
                confidenceLabel: .high
            )
        ],
        coverage: TimeCoverage(startMs: 0, endMs: 1000)
    )

    let validResult = validator.validate(
        response: validResponse,
        expectedSessionId: validSessionId,
        availableFrameIds: ["f-01", "f-02", "f-03"],
        sessionDurationMs: 1000
    )
    assertTrue(validResult.isValid, "Valid response must pass validation")
    assertEqual(validResult.errors.count, 0, "No errors expected")

    // Test rejection on invalid frame reference
    let invalidFrameResponse = ObserverResponse(
        schemaVersion: "0.1",
        sessionId: validSessionId.uuidString,
        requestId: "req-2",
        observations: [
            Observation(
                id: "obs-2",
                startMs: 200,
                endMs: 800,
                before: "a",
                after: "b",
                evidenceFrameIds: ["ghost-frame-999"]
            )
        ],
        coverage: TimeCoverage(startMs: 0, endMs: 1000)
    )
    let invalidResult = validator.validate(
        response: invalidFrameResponse,
        expectedSessionId: validSessionId,
        availableFrameIds: ["f-01", "f-02"],
        sessionDurationMs: 1000
    )
    assertTrue(!invalidResult.isValid, "Nonexistent frame ID must fail validation")
    assertTrue(invalidResult.errors.contains { $0.contains("ghost-frame-999") }, "Error references missing frame")

    // TEST 5: Floating Island Non-Activating Panel Properties
    print("\n--- Test 5: Floating Island Panel Properties ---")
    let panel = FloatingIslandPanel(contentRect: NSRect(x: 0, y: 0, width: 340, height: 64))
    assertTrue(panel.styleMask.contains(NSWindow.StyleMask.nonactivatingPanel), "Panel has nonactivatingPanel mask")
    assertTrue(panel.styleMask.contains(NSWindow.StyleMask.borderless), "Panel is borderless")
    assertEqual(panel.canBecomeKey, false, "Panel cannot become key (steals no keyboard focus)")
    assertEqual(panel.canBecomeMain, false, "Panel cannot become main (steals no window focus)")
    assertEqual(panel.level.rawValue, NSWindow.Level.floating.rawValue, "Panel level is floating")

    // TEST 6: HotKey Controller Registration
    print("\n--- Test 6: HotKey Controller Registration ---")
    let hotKey = HotKeyController()
    let triggered = AtomicBox<Bool>(false)
    let registered = hotKey.register {
        triggered.set(true)
    }
    assertTrue(registered, "Carbon HotKey (⌥⌘P) registers successfully")
    hotKey.unregister()

    return (passed, failed)
}

// Entrypoint
let (passed, failed) = await runAllTests()
print("\n=========================================")
print("TOTAL TESTS: \(passed + failed) | PASSED: \(passed) | FAILED: \(failed)")
if failed == 0 {
    print("VERDICT: PASS")
    exit(0)
} else {
    print("VERDICT: FAIL")
    exit(1)
}
