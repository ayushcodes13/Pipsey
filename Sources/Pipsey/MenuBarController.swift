import AppKit
import PipseyCore

@MainActor
public final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private let onActivate: () -> Void
    private let onCheckPermissions: () -> Void
    private let onOpenSettings: () -> Void

    public init(
        onActivate: @escaping () -> Void,
        onCheckPermissions: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void = {}
    ) {
        self.onActivate = onActivate
        self.onCheckPermissions = onCheckPermissions
        self.onOpenSettings = onOpenSettings
        super.init()
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            // Load template icon if available, fallback to 🤖
            if let templateURL = Bundle.main.url(forResource: "pipsey-menubar-template@2x", withExtension: "png") ??
                Bundle.main.url(forResource: "pipsey-menubar-template@1x", withExtension: "png") ??
                (FileManager.default.fileExists(atPath: "Assets/pipsey-menubar-template@2x.png") ? URL(fileURLWithPath: "Assets/pipsey-menubar-template@2x.png") : nil),
               let img = NSImage(contentsOf: templateURL) {
                img.isTemplate = true
                img.size = NSSize(width: 18, height: 18)
                button.image = img
                button.title = ""
            } else {
                button.title = "🤖"
            }
            button.toolTip = "Pipsey Companion (⌥⌘P)"
        }

        let menu = NSMenu()
        let activateItem = NSMenuItem(title: "Activate Pipsey (⌥⌘P)", action: #selector(handleActivate), keyEquivalent: "p")
        activateItem.keyEquivalentModifierMask = [.option, .command]
        activateItem.target = self
        menu.addItem(activateItem)

        let settingsItem = NSMenuItem(title: "Settings & AI Keys...", action: #selector(handleSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

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

    @objc private func handleSettings() {
        onOpenSettings()
    }

    @objc private func handlePermissions() {
        onCheckPermissions()
    }

    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
}
