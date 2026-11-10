import Foundation

/// Robust .env loader and Multi-Key Pool for independent VLM and Text LLM rate-limit rotation
public final class EnvManager: @unchecked Sendable {
    public static let shared = EnvManager()

    private let lock = NSLock()
    private var loadedKeys: [String] = []
    private var vlmKeyIndex: Int = 0
    private var textKeyIndex: Int = 0

    private init() {
        loadEnvFile()
    }

    /// Automatically find and load .env file from project root or user home
    public func loadEnvFile() {
        lock.lock()
        defer { lock.unlock() }

        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath

        let candidatePaths = [
            (currentDir as NSString).appendingPathComponent(".env"),
            "/Users/devayushrout/Desktop/Pipsey/.env",
            (NSHomeDirectory() as NSString).appendingPathComponent(".pipsey/.env"),
            (NSHomeDirectory() as NSString).appendingPathComponent(".env")
        ]

        var envContent: String? = nil
        var loadedPath: String? = nil

        for path in candidatePaths {
            if fileManager.fileExists(atPath: path),
               let content = try? String(contentsOfFile: path, encoding: .utf8) {
                envContent = content
                loadedPath = path
                break
            }
        }

        guard let content = envContent else {
            return
        }

        var parsedKeys: [String] = []

        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            let parts = trimmed.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }

            let key = parts[0].trimmingCharacters(in: .whitespaces)
            var val = parts[1].trimmingCharacters(in: .whitespaces)

            // Strip surrounding quotes
            if (val.hasPrefix("\"") && val.hasSuffix("\"")) || (val.hasPrefix("'") && val.hasSuffix("'")) {
                val = String(val.dropFirst().dropLast())
            }

            guard !val.isEmpty else { continue }

            // Set in process environment
            setenv(key, val, 1)

            // Collect keys for rotation pool
            if key == "GROQ_API_KEYS" {
                let subkeys = val.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                parsedKeys.append(contentsOf: subkeys)
            } else if key.hasPrefix("GROQ_API_KEY") || key == "PIPSEY_VLM_API_KEY" || key == "PIPSEY_TEXT_API_KEY" {
                parsedKeys.append(val)
            }
        }

        // Deduplicate keys preserving order
        var seen = Set<String>()
        var uniqueKeys: [String] = []
        for k in parsedKeys {
            if !seen.contains(k) {
                seen.insert(k)
                uniqueKeys.append(k)
            }
        }

        self.loadedKeys = uniqueKeys
        if let p = loadedPath {
            print("✅ [EnvManager] Loaded \(uniqueKeys.count) API keys from \(p)")
        }
    }

    // MARK: - Key Pool Rotation

    public var totalKeysCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return loadedKeys.count
    }

    public func currentVLMKey() -> String {
        lock.lock()
        defer { lock.unlock() }
        guard !loadedKeys.isEmpty else {
            return ProcessInfo.processInfo.environment["PIPSEY_VLM_API_KEY"] ?? ""
        }
        return loadedKeys[vlmKeyIndex % loadedKeys.count]
    }

    public func rotateVLMKey() -> String {
        lock.lock()
        defer { lock.unlock() }
        guard !loadedKeys.isEmpty else { return "" }
        vlmKeyIndex = (vlmKeyIndex + 1) % loadedKeys.count
        let nextKey = loadedKeys[vlmKeyIndex]
        let masked = nextKey.count > 8 ? "\(nextKey.prefix(4))...\(nextKey.suffix(4))" : "***"
        print("🔄 [VLM RateLimit Rotator] Rotated to Key #\(vlmKeyIndex + 1)/\(loadedKeys.count) [\(masked)]")
        return nextKey
    }

    public func currentTextKey() -> String {
        lock.lock()
        defer { lock.unlock() }
        guard !loadedKeys.isEmpty else {
            return ProcessInfo.processInfo.environment["PIPSEY_TEXT_API_KEY"] ?? ""
        }
        return loadedKeys[textKeyIndex % loadedKeys.count]
    }

    public func rotateTextKey() -> String {
        lock.lock()
        defer { lock.unlock() }
        guard !loadedKeys.isEmpty else { return "" }
        textKeyIndex = (textKeyIndex + 1) % loadedKeys.count
        let nextKey = loadedKeys[textKeyIndex]
        let masked = nextKey.count > 8 ? "\(nextKey.prefix(4))...\(nextKey.suffix(4))" : "***"
        print("🔄 [Text RateLimit Rotator] Rotated to Key #\(textKeyIndex + 1)/\(loadedKeys.count) [\(masked)]")
        return nextKey
    }
}
