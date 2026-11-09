import AppKit
import SwiftUI
import PipseyCore

@MainActor
public final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    public static var shared: SettingsWindowController?

    public static func show(tab: SettingsTab? = nil) {
        if let tab {
            SettingsNavigation.shared.selectedTab = tab
        }

        if shared == nil {
            shared = SettingsWindowController()
        }

        shared?.showWindow(nil)
    }

    private init() {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: CGSize(width: 720, height: 560)),
            styleMask: [
                .titled,
                .closable,
                .resizable,
                .miniaturizable,
                .fullSizeContentView, // Required for liquid glass rounded corners
            ],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)
        configureWindow()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureWindow() {
        guard let window else { return }

        window.title = "Pipsey Settings"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.toolbarStyle = .automatic
        window.isMovableByWindowBackground = true
        window.setFrameAutosaveName("PipseySettingsWindow")
        window.minSize = NSSize(width: 680, height: 500)
        window.center()
        window.delegate = self

        let hostingController = NSHostingController(rootView: SettingsView())
        window.contentViewController = hostingController
    }

    public override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        AppActivationPolicy.enter()
    }

    public func windowWillClose(_ notification: Notification) {
        AppActivationPolicy.leave()
        Self.shared = nil
    }
}
