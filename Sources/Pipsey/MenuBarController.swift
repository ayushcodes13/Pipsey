import AppKit
import PipseyCore

@MainActor
public final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private let onActivate: () -> Void
    private let onCheckPermissions: () -> Void

    public init(onActivate: @escaping () -> Void, onCheckPermissions: @escaping () -> Void) {
        self.onActivate = onActivate
        self.onCheckPermissions = onCheckPermissions
        super.init()
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.title = "🤖"
            button.toolTip = "Pipsey Companion (⌥⌘P)"
        }

        let menu = NSMenu()
        let activateItem = NSMenuItem(title: "Activate Pipsey (⌥⌘P)", action: #selector(handleActivate), keyEquivalent: "p")
        activateItem.keyEquivalentModifierMask = [.option, .command]
        activateItem.target = self
        menu.addItem(activateItem)

        let permissionsItem = NSMenuItem(title: "Check System Permissions...", action: #selector(handlePermissions), keyEquivalent: "")
        permissionsItem.target = self
        menu.addItem(permissionsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Pipsey", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func handleActivate() {
        onActivate()
    }

    @objc private func handlePermissions() {
        onCheckPermissions()
    }

    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
}
