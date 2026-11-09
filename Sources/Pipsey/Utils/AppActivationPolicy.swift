import AppKit

/// Reference-counted activation policy manager following macos-patterns.
/// Ensures that opening auxiliary windows (Settings, History, Onboarding) presents
/// the app properly, and closing the last window respects the user's Dock preference.
@MainActor
public enum AppActivationPolicy {
    private static var openWindowCount = 0

    public static func enter() {
        openWindowCount += 1
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    public static func leave() {
        openWindowCount = max(0, openWindowCount - 1)
        guard openWindowCount == 0 else { return }
        let hideDock = UserDefaults.standard.bool(forKey: "pipsey_hide_dock_icon")
        if hideDock {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
