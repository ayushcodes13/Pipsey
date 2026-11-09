import Foundation

public struct SavedSessionRecord: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var timestamp: Date
    public var appName: String
    public var appCategory: String
    public var suggestedFramework: String
    public var question: String
    public var spokenSummary: String
    public var likelyMechanism: String
    public var implementationApproach: String
    public var detailedMarkdown: String
    public var frameCount: Int
    public var durationMs: Int64

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        appName: String = "Active App",
        appCategory: String = "General UI",
        suggestedFramework: String = "React / SwiftUI",
        question: String,
        spokenSummary: String,
        likelyMechanism: String,
        implementationApproach: String,
        detailedMarkdown: String,
        frameCount: Int = 0,
        durationMs: Int64 = 0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.appName = appName
        self.appCategory = appCategory
        self.suggestedFramework = suggestedFramework
        self.question = question
        self.spokenSummary = spokenSummary
        self.likelyMechanism = likelyMechanism
        self.implementationApproach = implementationApproach
        self.detailedMarkdown = detailedMarkdown
        self.frameCount = frameCount
        self.durationMs = durationMs
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

public actor SessionHistoryManager {
    public static let shared = SessionHistoryManager()
    private let storageURL: URL
    private var records: [SavedSessionRecord] = []
    private var isLoaded: Bool = false

    public init(customStorageURL: URL? = nil) {
        if let custom = customStorageURL {
            self.storageURL = custom
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let pipseyDir = appSupport.appendingPathComponent("Pipsey", isDirectory: true)
            try? FileManager.default.createDirectory(at: pipseyDir, withIntermediateDirectories: true)
            self.storageURL = pipseyDir.appendingPathComponent("session_history.json")
        }
    }

    public func save(record: SavedSessionRecord) {
        ensureLoaded()
        records.insert(record, at: 0)
        persist()
    }

    public func getAllRecords() -> [SavedSessionRecord] {
        ensureLoaded()
        return records
    }

    public func delete(id: UUID) {
        ensureLoaded()
        records.removeAll { $0.id == id }
        persist()
    }

    public func clearAll() {
        records.removeAll()
        persist()
    }

    public func search(query: String) -> [SavedSessionRecord] {
        ensureLoaded()
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return records }

        return records.filter {
            $0.question.lowercased().contains(clean) ||
            $0.appName.lowercased().contains(clean) ||
            $0.likelyMechanism.lowercased().contains(clean) ||
            $0.implementationApproach.lowercased().contains(clean) ||
            $0.suggestedFramework.lowercased().contains(clean)
        }
    }

    private func ensureLoaded() {
        guard !isLoaded else { return }
        isLoaded = true
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }

        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            records = try decoder.decode([SavedSessionRecord].self, from: data)
        } catch {
            print("Notice: Starting new session history store: \(error.localizedDescription)")
            records = []
        }
    }

    private func persist() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(records)
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            print("Failed to persist session history: \(error)")
        }
    }
}
