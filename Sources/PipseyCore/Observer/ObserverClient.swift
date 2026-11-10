import Foundation

public enum ObserverError: Error, LocalizedError, CustomStringConvertible, Sendable {
    case invalidEndpoint(String)
    case unauthorized
    case timeout
    case cancelled
    case serverError(Int, String)
    case schemaValidationFailed([String])
    case frameLimitExceeded(Int)
    case unconfigured(String)

    public var errorDescription: String? {
        description
    }

    public var description: String {
        switch self {
        case .invalidEndpoint(let url): return "Invalid VLM endpoint: \(url)"
        case .unauthorized: return "Unauthorized: VLM API key invalid or missing. Please configure your API key in Settings (⌘,)."
        case .timeout: return "VLM request timed out"
        case .cancelled: return "VLM request cancelled by user"
        case .serverError(let code, let msg): return "VLM server error (\(code)): \(msg)"
        case .schemaValidationFailed(let errors): return "VLM Schema validation failed: \(errors.joined(separator: ", "))"
        case .frameLimitExceeded(let count): return "Payload frame count \(count) exceeds safety limit"
        case .unconfigured(let msg): return "VLM unconfigured: \(msg)"
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

    public var isAzure: Bool {
        return baseURL.absoluteString.contains("openai.azure.com")
    }

    public var chatCompletionsEndpoint: URL {
        if isAzure {
            var urlString = baseURL.absoluteString
            if !urlString.hasSuffix("/") {
                urlString += "/"
            }
            if urlString.contains("/deployments/") {
                return URL(string: "\(urlString)chat/completions?api-version=2024-02-15-preview") ?? baseURL
            }
            let host = baseURL.host ?? ""
            return URL(string: "https://\(host)/openai/deployments/\(model)/chat/completions?api-version=2024-02-15-preview")!
        } else {
            return baseURL.appendingPathComponent("chat/completions")
        }
    }

    public init(
        baseURL: URL = URL(string: "https://api.openai.com/v1")!,
        apiKey: String = "",
        model: String = "gpt-4o-mini",
        timeoutSeconds: TimeInterval = 25.0,
        maxFrames: Int = 30
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
        self.timeoutSeconds = timeoutSeconds
        self.maxFrames = maxFrames
    }

    public static func loadDefault() -> VLMConfiguration {
        let defaults = UserDefaults.standard
        let env = ProcessInfo.processInfo.environment

        EnvManager.shared.loadEnvFile()

        let savedBase = defaults.string(forKey: "pipsey_vlm_base_url")
        let savedModel = defaults.string(forKey: "pipsey_vlm_model")

        let poolKey = EnvManager.shared.currentVLMKey()
        let envKey = env["PIPSEY_VLM_API_KEY"]
            ?? env["GROQ_API_KEY"]
            ?? env["ONEPAGER_AZURE_OPENAI_API_KEY"]
            ?? env["AZURE_OPENAI_API_KEY"]
            ?? env["OPENAI_API_KEY"]
        let key = envKey
            ?? KeychainManager.shared.readSecret(account: "pipsey-vlm-api-key")
            ?? (!poolKey.isEmpty ? poolKey : nil)
            ?? ""
        let base = savedBase
            ?? env["PIPSEY_VLM_BASE_URL"]
            ?? env["ONEPAGER_AZURE_OPENAI_BASE_URL"]
            ?? "https://api.groq.com/openai/v1"
        let defaultModel = base.contains("groq.com") ? "qwen/qwen3.8-27b" : (base.contains("openai.azure.com") ? "gpt-5-mini" : "gpt-4o-mini")
        let model = savedModel ?? env["PIPSEY_VLM_MODEL"] ?? defaultModel

        return VLMConfiguration(
            baseURL: URL(string: base) ?? URL(string: "https://api.groq.com/openai/v1")!,
            apiKey: key,
            model: model
        )
    }
}

public actor HostedVLMClient: ObserverClientProtocol {
    private var config: VLMConfiguration
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

        guard !config.apiKey.isEmpty else {
            throw ObserverError.unconfigured("VLM API Key not set. Please open Settings (⌘,) to configure your credentials.")
        }

        let endpoint = config.chatCompletionsEndpoint
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Pipsey/1.0 (Macintosh; Apple Silicon)", forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        if config.isAzure {
            request.setValue(config.apiKey, forHTTPHeaderField: "api-key")
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

        // Format spoken user question if available
        let userQuestion = manifest.transcripts.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let questionPrompt = userQuestion.isEmpty ? "The user demonstrated a UI interaction without asking a specific verbal question." : "The user asked: \"\(userQuestion)\""

        // Format summary of input events across the demonstration
        let eventsSummary: String
        if manifest.events.isEmpty {
            eventsSummary = "Input events: None recorded."
        } else {
            let topEvents = manifest.events.prefix(20).map { evt -> String in
                if let pos = evt.normalizedPosition {
                    return "- [+\(evt.relativeTimeMs)ms] \(evt.type.rawValue) at (x: \(String(format: "%.2f", pos.x)), y: \(String(format: "%.2f", pos.y)))"
                } else {
                    return "- [+\(evt.relativeTimeMs)ms] \(evt.type.rawValue)"
                }
            }.joined(separator: "\n")
            eventsSummary = "User input events during capture:\n\(topEvents)"
        }

        var contentArray: [[String: Any]] = [
            [
                "type": "text",
                "text": """
                \(questionPrompt)

                \(eventsSummary)

                Below are the \(frames.count) chronological screen frames captured during this demonstration.
                Each frame includes its Frame ID, relative timestamp (+Xms), and temporally correlated user inputs.
                Examine visual changes across frames and produce observations citing exact evidence_frame_ids.
                """
            ]
        ]

        for (idx, frame) in frames.enumerated() {
            let meta = frame.metadata
            // Find nearby events within +/- 250ms of this frame timestamp
            let nearbyEvents = manifest.events.filter { abs($0.relativeTimeMs - meta.relativeTimeMs) <= 250 }
            var frameHeader = "Frame #\(idx + 1) [ID: \(meta.frameId), Timestamp: +\(meta.relativeTimeMs)ms]"
            if !nearbyEvents.isEmpty {
                let eventSummary = nearbyEvents.compactMap { evt -> String? in
                    if let pos = evt.normalizedPosition {
                        return "\(evt.type.rawValue)@(x:\(String(format: "%.2f", pos.x)), y:\(String(format: "%.2f", pos.y)))"
                    }
                    return evt.type.rawValue
                }.joined(separator: ", ")
                frameHeader += " (Nearby inputs: \(eventSummary))"
            }

            contentArray.append([
                "type": "text",
                "text": frameHeader
            ])

            if let data = frame.rawImageData {
                let base64 = data.base64EncodedString()
                contentArray.append([
                    "type": "image_url",
                    "image_url": ["url": "data:image/jpeg;base64,\(base64)"]
                ])
            }
        }

        var body: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": contentArray]
            ],
            "response_format": ["type": "json_object"]
        ]

        // On reasoning models, use low reasoning effort for fast interactive observation
        if config.model.contains("gpt-5") || config.model.contains("o1") || config.model.contains("o3") {
            body["reasoning_effort"] = "low"
        } else {
            body["temperature"] = 0.1
            body["max_tokens"] = 1500
        }

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
            if httpResponse.statusCode == 429 {
                let msg = String(data: data, encoding: .utf8) ?? "HTTP 429 Rate Limit"
                print("⚠️ [VLM] HTTP 429 Rate Limit encountered. Checking key rotation pool...")
                if EnvManager.shared.totalKeysCount > 1 {
                    let nextKey = EnvManager.shared.rotateVLMKey()
                    self.config.apiKey = nextKey
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    return try await self.observe(manifest: manifest, frames: frames)
                }
                throw ObserverError.serverError(429, msg)
            }
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                let msg = String(data: data, encoding: .utf8) ?? "Empty body"
                print("⚠️ VLM HTTP \(httpResponse.statusCode) error body: \(msg)")
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
            let bodyStr = String(data: data, encoding: .utf8) ?? "Unreadable"
            throw ObserverError.schemaValidationFailed(["Malformed response from model: \(bodyStr.prefix(200))"])
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
