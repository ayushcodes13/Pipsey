import Foundation

public struct ValidationResult: Equatable, Sendable {
    public var isValid: Bool
    public var errors: [String]
    public var warnings: [String]

    public init(isValid: Bool, errors: [String] = [], warnings: [String] = []) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
    }
}

public struct ObservationValidator: Sendable {
    public init() {}

    public func validate(
        response: ObserverResponse,
        expectedSessionId: UUID,
        availableFrameIds: Set<String>,
        sessionDurationMs: Int64
    ) -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []

        // Check schema version
        if response.schemaVersion != "0.1" {
            errors.append("Unsupported schema version: \(response.schemaVersion)")
        }

        // Check session ID
        if response.sessionId != expectedSessionId.uuidString {
            errors.append("Session ID mismatch: expected \(expectedSessionId.uuidString), got \(response.sessionId)")
        }

        // Check coverage bounds
        if response.coverage.startMs < 0 || response.coverage.endMs < response.coverage.startMs {
            errors.append("Invalid coverage interval: [\(response.coverage.startMs), \(response.coverage.endMs)]")
        }

        // Validate each observation
        for obs in response.observations {
            if obs.startMs < 0 {
                errors.append("Negative start time in observation \(obs.id): \(obs.startMs)")
            }
            if obs.endMs < obs.startMs {
                errors.append("End time before start time in observation \(obs.id): [\(obs.startMs), \(obs.endMs)]")
            }
            if sessionDurationMs > 0 && obs.endMs > sessionDurationMs + 1000 {
                warnings.append("Observation \(obs.id) extends beyond session duration (\(obs.endMs)ms > \(sessionDurationMs)ms)")
            }

            // Check frame references
            for frameId in obs.evidenceFrameIds {
                if !availableFrameIds.contains(frameId) {
                    errors.append("Observation \(obs.id) references nonexistent frame ID '\(frameId)'")
                }
            }

            if obs.evidenceFrameIds.isEmpty {
                warnings.append("Observation \(obs.id) has no supporting evidence frame IDs")
            }

            // Ensure before and after are populated
            if obs.before.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append("Observation \(obs.id) missing 'before' state")
            }
            if obs.after.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append("Observation \(obs.id) missing 'after' state")
            }
        }

        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
}
