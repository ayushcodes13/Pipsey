import AppKit
import SwiftUI
import PipseyCore

@MainActor
public final class HistoryWindowController: NSWindowController {
    public static let shared = HistoryWindowController()

    public init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.isReleasedWhenClosed = false
        window.title = "Pipsey Interaction Library"
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
        window.minSize = NSSize(width: 680, height: 440)

        super.init(window: window)
        window.contentView = NSHostingView(rootView: HistoryView())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func showHistory() {
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

public struct HistoryView: View {
    @State private var records: [SavedSessionRecord] = []
    @State private var selectedRecordId: UUID? = nil
    @State private var searchQuery: String = ""
    @State private var hasCopied: Bool = false

    private var filteredRecords: [SavedSessionRecord] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            return records
        }
        return records.filter {
            $0.question.lowercased().contains(q) ||
            $0.appName.lowercased().contains(q) ||
            $0.likelyMechanism.lowercased().contains(q) ||
            $0.suggestedFramework.lowercased().contains(q)
        }
    }

    private var selectedRecord: SavedSessionRecord? {
        records.first { $0.id == selectedRecordId } ?? records.first
    }

    public var body: some View {
        ZStack {
            Color(hex: "0D0E12").ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Search & Filter Bar
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.4))
                        TextField("Search interactions, apps, code...", text: $searchQuery)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                        if !searchQuery.isEmpty {
                            Button(action: { searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(8)

                    Spacer()

                    Text("\(records.count) Interactions Saved")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.4))

                Divider().background(Color.white.opacity(0.1))

                // Main Split View
                if records.isEmpty {
                    emptyStateView
                } else {
                    HSplitView {
                        // Left List Sidebar
                        VStack(spacing: 0) {
                            List(filteredRecords, selection: $selectedRecordId) { record in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(record.appName)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(Color(hex: "00F0FF"))
                                        Spacer()
                                        Text(record.formattedDate)
                                            .font(.system(size: 9.5))
                                            .foregroundColor(.white.opacity(0.4))
                                    }

                                    Text(record.question)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(2)

                                    Text(record.spokenSummary)
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.6))
                                        .lineLimit(1)
                                }
                                .padding(.vertical, 4)
                                .tag(record.id)
                            }
                            .listStyle(.sidebar)
                        }
                        .frame(minWidth: 240, maxWidth: 320)

                        // Right Detail View
                        if let record = selectedRecord {
                            detailView(for: record)
                        } else {
                            VStack {
                                Spacer()
                                Text("Select an interaction to view details")
                                    .foregroundColor(.white.opacity(0.5))
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        .task {
            await reloadRecords()
        }
    }

    private func detailView(for record: SavedSessionRecord) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Header & Badges
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            badge(text: record.appName, color: Color(hex: "00F0FF"))
                            badge(text: record.appCategory, color: Color.purple)
                            badge(text: record.suggestedFramework, color: Color.green)
                        }

                        Text(record.question)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button(action: {
                        Task {
                            await SessionHistoryManager.shared.delete(id: record.id)
                            await reloadRecords()
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help("Delete interaction")
                }

                Divider().background(Color.white.opacity(0.1))

                // Summary
                VStack(alignment: .leading, spacing: 4) {
                    Text("Observed Interaction")
                        .font(.caption).bold()
                        .foregroundColor(.white.opacity(0.5))
                    Text(record.spokenSummary)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.95))
                }

                // Mechanism
                VStack(alignment: .leading, spacing: 4) {
                    Text("Likely Mechanism")
                        .font(.caption).bold()
                        .foregroundColor(.purple.opacity(0.8))
                    Text(record.likelyMechanism)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.92))
                }

                // Implementation Approach
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended Implementation")
                        .font(.caption).bold()
                        .foregroundColor(.green.opacity(0.8))
                    Text(record.implementationApproach)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.92))
                }

                // Code Snippets / Markdown
                if !record.detailedMarkdown.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Full Code & Analysis")
                                .font(.caption).bold()
                                .foregroundColor(.white.opacity(0.5))
                            Spacer()
                            Button(action: {
                                let pb = NSPasteboard.general
                                pb.clearContents()
                                pb.setString(record.detailedMarkdown, forType: .string)
                                hasCopied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    hasCopied = false
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: hasCopied ? "checkmark" : "doc.on.doc")
                                    Text(hasCopied ? "Copied!" : "Copy Code")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(hasCopied ? .green : .accentColor)
                        }

                        Text(record.detailedMarkdown)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(20)
        }
    }

    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .cornerRadius(4)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            PipseyMascotView(size: 48)
            Text("No Interactions Saved Yet")
                .font(.headline)
                .foregroundColor(.white)
            Text("Whenever you ask Pipsey to explain software interactions, the explanations and generated code will be saved here automatically.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func reloadRecords() async {
        records = await SessionHistoryManager.shared.getAllRecords()
        if selectedRecordId == nil {
            selectedRecordId = records.first?.id
        }
    }
}
