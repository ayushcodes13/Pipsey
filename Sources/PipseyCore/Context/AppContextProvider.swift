import Foundation
import AppKit

public struct AppContext: Codable, Equatable, Sendable {
    public var appName: String
    public var bundleIdentifier: String?
    public var windowTitle: String?
    public var category: String
    public var suggestedFramework: String

    public init(
        appName: String,
        bundleIdentifier: String? = nil,
        windowTitle: String? = nil,
        category: String = "General UI",
        suggestedFramework: String = "Modern UI / Declarative Framework"
    ) {
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.windowTitle = windowTitle
        self.category = category
        self.suggestedFramework = suggestedFramework
    }
}

public final class AppContextProvider: @unchecked Sendable {
    public static let shared = AppContextProvider()

    public init() {}

    @MainActor
    public func detectActiveContext() -> AppContext {
        let workspace = NSWorkspace.shared
        var frontApp = workspace.frontmostApplication

        // If Pipsey itself is frontmost, find the most recently active non-Pipsey application
        if frontApp?.bundleIdentifier == "com.pipsey.companion" || frontApp?.localizedName == "Pipsey" {
            let runningApps = workspace.runningApplications
            frontApp = runningApps.first { app in
                app.isActive && app.bundleIdentifier != "com.pipsey.companion" && app.localizedName != "Pipsey"
            } ?? runningApps.first { app in
                app.activationPolicy == .regular && app.bundleIdentifier != "com.pipsey.companion" && app.localizedName != "Pipsey"
            }
        }

        let appName = frontApp?.localizedName ?? "Active Application"
        let bundleId = frontApp?.bundleIdentifier

        let (category, framework) = categorizeApplication(bundleId: bundleId, appName: appName)

        return AppContext(
            appName: appName,
            bundleIdentifier: bundleId,
            windowTitle: nil,
            category: category,
            suggestedFramework: framework
        )
    }

    private func categorizeApplication(bundleId: String?, appName: String) -> (String, String) {
        guard let id = bundleId?.lowercased() else {
            return ("General Application", "Modern Declarative UI (React / SwiftUI)")
        }

        if id.contains("figma") {
            return ("Design Tool", "Figma Auto-Layout & Design Tokens / CSS Canvas")
        } else if id.contains("xcode") {
            return ("macOS / iOS Development", "Swift / SwiftUI / AppKit")
        } else if id.contains("vscode") || id.contains("vscodium") || id.contains("cursor") {
            return ("Code Editor", "React / TypeScript / Tailwind CSS")
        } else if id.contains("chrome") || id.contains("safari") || id.contains("firefox") || id.contains("brave") || id.contains("arc") {
            return ("Web Browser", "HTML / CSS / JavaScript & React Components")
        } else if id.contains("linear") {
            return ("Productivity", "Modern Keyboard-Centric Web / React UI")
        } else if id.contains("slack") || id.contains("discord") || id.contains("notion") {
            return ("Collaboration & Docs", "React / Electron Component Architecture")
        } else if id.contains("apple.") {
            return ("Apple Native App", "Native Apple Human Interface Guidelines / SwiftUI")
        }

        return ("macOS Application", "Declarative UI Framework (SwiftUI / React)")
    }
}
