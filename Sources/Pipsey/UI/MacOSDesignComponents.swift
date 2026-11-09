import SwiftUI
import AppKit

// MARK: - Native Keyboard Shortcut Badge (<kbd> component)

/// Idiomatic macOS keyboard shortcut badge matching Apple Human Interface Guidelines and macos-design skill.
public struct KeyBadge: View {
    let text: String
    var isAccent: Bool = false

    public init(_ text: String, isAccent: Bool = false) {
        self.text = text
        self.isAccent = isAccent
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(isAccent ? Color(hex: "00F0FF") : .white.opacity(0.85))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(isAccent ? Color(hex: "00F0FF").opacity(0.12) : Color.white.opacity(0.08))
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isAccent ? Color(hex: "00F0FF").opacity(0.35) : Color.white.opacity(0.16), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 2, y: 1)
    }
}

// MARK: - Shortcut Combo Helper

public struct ShortcutComboBadge: View {
    let keys: [String]

    public init(_ keys: [String]) {
        self.keys = keys
    }

    public var body: some View {
        HStack(spacing: 3) {
            ForEach(keys, id: \.self) { k in
                KeyBadge(k)
            }
        }
    }
}

// MARK: - Layered macOS Dark Surface

public struct MacOSCardSurface<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.75))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 4, y: 2)
    }
}

// MARK: - Micro Toast Notification HUD

public struct HUDNotificationView: View {
    let title: String
    let systemImage: String

    public init(title: String, systemImage: String = "checkmark.circle.fill") {
        self.title = title
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "00F0FF"))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(hex: "1C1C1E").opacity(0.95))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 8, y: 3)
    }
}
