import Foundation

public struct CanonicalScenario: Sendable {
    public var id: String
    public var name: String
    public var question: String
    public var expectedBefore: String
    public var expectedAfter: String
    public var expectedTrigger: String
    public var forbiddenFalseClaim: String

    public init(
        id: String,
        name: String,
        question: String,
        expectedBefore: String,
        expectedAfter: String,
        expectedTrigger: String,
        forbiddenFalseClaim: String
    ) {
        self.id = id
        self.name = name
        self.question = question
        self.expectedBefore = expectedBefore
        self.expectedAfter = expectedAfter
        self.expectedTrigger = expectedTrigger
        self.forbiddenFalseClaim = forbiddenFalseClaim
    }
}

public struct CanonicalEvaluationFixture: Sendable {
    public static let scenarios: [CanonicalScenario] = [
        CanonicalScenario(
            id: "E01",
            name: "Hover dropdown",
            question: "How does this menu appear?",
            expectedBefore: "menu hidden",
            expectedAfter: "menu visible",
            expectedTrigger: "hover",
            forbiddenFalseClaim: "clicked the menu item"
        ),
        CanonicalScenario(
            id: "E02",
            name: "Tooltip",
            question: "Where did this tooltip come from?",
            expectedBefore: "tooltip absent",
            expectedAfter: "tooltip label displayed",
            expectedTrigger: "cursor pause over button",
            forbiddenFalseClaim: "invented text not in frame"
        ),
        CanonicalScenario(
            id: "E03",
            name: "Modal",
            question: "How did the screen darken?",
            expectedBefore: "page normal",
            expectedAfter: "dialog and backdrop open",
            expectedTrigger: "click",
            forbiddenFalseClaim: "page navigation"
        ),
        CanonicalScenario(
            id: "E04",
            name: "Drag and drop",
            question: "How did this item move?",
            expectedBefore: "item in source list",
            expectedAfter: "item placed in target column",
            expectedTrigger: "mouse drag gesture",
            forbiddenFalseClaim: "instant copy paste"
        ),
        CanonicalScenario(
            id: "E05",
            name: "Loading spinner",
            question: "What happened while waiting?",
            expectedBefore: "spinner active",
            expectedAfter: "result list loaded",
            expectedTrigger: "async task resolution",
            forbiddenFalseClaim: "completed immediately"
        ),
        CanonicalScenario(
            id: "E06",
            name: "Tab switch",
            question: "How did this view switch?",
            expectedBefore: "Tab A active with Tab A content",
            expectedAfter: "Tab B selected with Tab B content",
            expectedTrigger: "click on Tab B",
            forbiddenFalseClaim: "full page reload"
        ),
        CanonicalScenario(
            id: "E07",
            name: "Sidebar expand",
            question: "How did the sidebar expand?",
            expectedBefore: "narrow collapsed sidebar with icons only",
            expectedAfter: "expanded sidebar showing text labels",
            expectedTrigger: "sidebar toggle click",
            forbiddenFalseClaim: "guessing exact private animation easing"
        ),
        CanonicalScenario(
            id: "E08",
            name: "Carousel slide",
            question: "How did the slide change?",
            expectedBefore: "Slide 1 active",
            expectedAfter: "Slide 2 visible",
            expectedTrigger: "next arrow click",
            forbiddenFalseClaim: "claims unseen future slide details"
        ),
        CanonicalScenario(
            id: "E09",
            name: "Toast notification",
            question: "What notification just showed up?",
            expectedBefore: "notification area clear",
            expectedAfter: "temporary toast banner displayed",
            expectedTrigger: "action completed",
            forbiddenFalseClaim: "permanent dialog window"
        ),
        CanonicalScenario(
            id: "E10",
            name: "Async list update",
            question: "How did the new item appear?",
            expectedBefore: "list showing 3 items",
            expectedAfter: "list showing 4 items",
            expectedTrigger: "server polling or websocket event",
            forbiddenFalseClaim: "claims knowledge of private database schema"
        )
    ]

    public static func generateMockResponse(for scenario: CanonicalScenario, sessionId: UUID) -> ObserverResponse {
        ObserverResponse(
            schemaVersion: "0.1",
            sessionId: sessionId.uuidString,
            requestId: "req-\(scenario.id)",
            observations: [
                Observation(
                    id: "obs-\(scenario.id)",
                    startMs: 200,
                    endMs: 800,
                    kind: "visible_change",
                    before: scenario.expectedBefore,
                    after: scenario.expectedAfter,
                    evidenceFrameIds: ["frame-001", "frame-002"],
                    triggerHypothesis: scenario.expectedTrigger,
                    confidenceLabel: .high,
                    uncertainties: ["underlying framework private"]
                )
            ],
            coverage: TimeCoverage(startMs: 0, endMs: 2000),
            unknowns: []
        )
    }
}
