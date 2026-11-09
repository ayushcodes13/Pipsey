import Foundation

public enum ObserverError: Error, CustomStringConvertible, Sendable {
    case invalidEndpoint(String)
    case unauthorized
    case timeout
    case cancelled
    case serverError(Int, String)
    case schemaValidationFailed([String])
    case frameLimitExceeded(Int)

    public var description: String {
        switch self {
        case .invalidEndpoint(let url): return "Invalid VLM endpoint: \(url)"
        case .unauthorized: return "Unauthorized: VLM API key invalid or missing"
        case .timeout: return "VLM request timed out"
        case .cancelled: return "VLM request cancelled by user"
        case .serverError(let code, let msg): return "VLM server error (\(code)): \(msg)"
        case .schemaValidationFailed(let errors): return "Schema validation failed: \(errors.joined(separator: ", "))"
        case .frameLimitExceeded(let count): return "Payload frame count \(count) exceeds safety limit"
        }
    }
}

public protocol ObserverClientProtocol: Sendable {
    func observe(
        manifest: EvidenceManifest,
        frames: [SampledFrame]
    ) async throws -> ObserverResponse
}

public struct VLMConfiguration: Sendable {
    public var baseURL: URL
    public var apiKey: String
    public var model: String
    public var timeoutSeconds: TimeInterval
    public var maxFrames: Int

    public init(
        baseURL: URL = URL(string: "https://api.openai.com/v1")!,
        apiKey: String = "",
        model: String = "gpt-4o-mini",
        timeoutSeconds: TimeInterval = 15.0,
        maxFrames: Int = 30
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
        self.timeoutSeconds = timeoutSeconds
        self.maxFrames = maxFrames
    }

    public static func loadDefault() -> VLMConfiguration {
        let env = ProcessInfo.processInfo.environment
        let key = KeychainManager.shared.readSecret(account: "pipsey-vlm-api-key")
            ?? env["PIPSEY_VLM_API_KEY"]
            ?? env["OPENAI_API_KEY"]
            ?? env["AZURE_OPENAI_API_KEY"]
            ?? env["ONEPAGER_AZURE_OPENAI_API_KEY"]
            ?? ""
        let base = env["PIPSEY_VLM_BASE_URL"]
            ?? env["ONEPAGER_AZURE_OPENAI_BASE_URL"]
            ?? "https://api.openai.com/v1"
        let model = env["PIPSEY_VLM_MODEL"] ?? "gpt-4o-mini"
        return VLMConfiguration(
            baseURL: URL(string: base) ?? URL(string: "https://api.openai.com/v1")!,
            apiKey: key,
            model: model
        )
    }
}

public actor HostedVLMClient: ObserverClientProtocol {
    private let config: VLMConfiguration
    private let validator = ObservationValidator()
    private let urlSession: URLSession

    public init(config: VLMConfiguration = .loadDefault(), urlSession: URLSession = .shared) {
        self.config = config
        self.urlSession = urlSession
    }

    public func observe(
        manifest: EvidenceManifest,
        frames: [SampledFrame]
    ) async throws -> ObserverResponse {
        try Task.checkCancellation()

        guard frames.count <= config.maxFrames else {
            throw ObserverError.frameLimitExceeded(frames.count)
        }

        // Construct request payload
        let endpoint = config.baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !config.apiKey.isEmpty {
            request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = config.timeoutSeconds

        // Build messages with system instructions and image content
        let systemPrompt = """
        You are Pipsey Visual Observer. Inspect the sequence of captured frames and mouse events.
        Return ONLY valid JSON matching this schema:
        {
          "schema_version": "0.1",
          "session_id": "\(manifest.sessionId.uuidString)",
          "request_id": "\(UUID().uuidString)",
          "observations": [
            {
              "id": "obs-001",
              "start_ms": 100,
              "end_ms": 500,
              "kind": "visible_change",
              "before": "state description before",
              "after": "state description after",
              "evidence_frame_ids": ["frame-001"],
              "trigger_hypothesis": "cursor hover",
              "confidence_label": "high",
              "uncertainties": []
            }
          ],
          "coverage": { "start_ms": 0, "end_ms": \(manifest.capture.durationMs) },
          "unknowns": []
        }
        Do not guess code frameworks or invent changes not visible in frames.
        """

        var contentArray: [[String: Any]] = [
            ["type": "text", "text": "Analyze the UI changes demonstrated in these frames:"]
        ]

        for frame in frames {
            if let data = frame.rawImageData {
                let base64 = data.base64EncodedString()
                contentArray.append([
                    "type": "image_url",
                    "image_url": ["url": "data:image/jpeg;base64,\(base64)"]
                ])
            }
        }

        let body: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": contentArray]
            ],
            "response_format": ["type": "json_object"],
            "max_tokens": 1024,
            "temperature": 0.1
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch is CancellationError {
            throw ObserverError.cancelled
        } catch let err as URLError where err.code == .timedOut {
            throw ObserverError.timeout
        } catch {
            throw ObserverError.serverError(-1, error.localizedDescription)
        }

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw ObserverError.unauthorized
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                let msg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
                throw ObserverError.serverError(httpResponse.statusCode, msg)
            }
        }

        // Parse OpenAI format
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let contentString = message["content"] as? String,
              let contentData = contentString.data(using: .utf8) else {
            throw ObserverError.schemaValidationFailed(["Malformed response from model"])
        }

        let observerResponse = try JSONDecoder().decode(ObserverResponse.self, from: contentData)

        // Strict schema and frame validation
        let availableIds = Set(manifest.frames.map { $0.frameId })
        let valResult = validator.validate(
            response: observerResponse,
            expectedSessionId: manifest.sessionId,
            availableFrameIds: availableIds,
            sessionDurationMs: manifest.capture.durationMs
        )

        if !valResult.isValid {
            throw ObserverError.schemaValidationFailed(valResult.errors)
        }

        return observerResponse
    }
}
