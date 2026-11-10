import AppKit
import SwiftUI
import PipseyCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var islandPanel: FloatingIslandPanel?
    private var menuBarController: MenuBarController?
    private let hotKeyController = HotKeyController()
    private let sessionCoordinator = SessionCoordinator()
    private lazy var viewModel = IslandViewModel(coordinator: sessionCoordinator)

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as regular macOS app showing in Dock by default (or accessory if configured in Settings)
        let hideDock = UserDefaults.standard.bool(forKey: "pipsey_hide_dock_icon")
        NSApp.setActivationPolicy(hideDock ? .accessory : .regular)

        // Set native application icon to the squircle mascot dock icon with transparent corners
        if let iconUrl = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let appIcon = NSImage(contentsOf: iconUrl) {
            NSApp.applicationIconImage = appIcon
        } else if let iconPng = Bundle.main.url(forResource: "pipsey-app-icon-1024", withExtension: "png"),
                  let appIcon = NSImage(contentsOf: iconPng) {
            NSApp.applicationIconImage = appIcon
        }

        // Setup Standard macOS Main Application Menu (Edit, Window, Help, Preferences)
        setupMainMenu()

        // Setup Floating Island Panel
        let islandLevel = NSWindow.Level(Int(CGWindowLevelForKey(.floatingWindow)) + 10)
        let panel = FloatingIslandPanel(
            contentRect: NSRect(x: 0, y: 0, width: viewModel.currentWidth, height: viewModel.currentHeight),
            level: islandLevel
        )
        panel.companionStyle = viewModel.companionStyle
        panel.anchorCorner = viewModel.anchorCorner
        let hostingView = DraggableIslandHostingView(rootView: CompanionIslandView(viewModel: viewModel))
        panel.contentView = hostingView
        panel.reposition(width: viewModel.currentWidth, height: viewModel.currentHeight)
        panel.orderFrontRegardless()
        self.islandPanel = panel

        // Dynamic geometry update when companion morphs, peeks, or expands
        viewModel.onGeometryChange = { [weak panel] width, height in
            panel?.updateGeometry(width: width, height: height)
        }

        // Visibility control (e.g. Menu Bar Only when idle)
        viewModel.onVisibilityChange = { [weak panel] isVisible in
            if isVisible {
                panel?.alphaValue = 1.0
                panel?.orderFrontRegardless()
            } else {
                panel?.alphaValue = 0.0
            }
        }

        // Draggable floating companion support (like Wispr Flow)
        var dragStartOrigin: NSPoint? = nil
        viewModel.onDragStart = { [weak panel] in
            guard let panel = panel else { return }
            dragStartOrigin = panel.frame.origin
        }

        viewModel.onDragChanged = { [weak panel] translation in
            guard let panel = panel, let start = dragStartOrigin else { return }
            // In SwiftUI translation: +width is right, +height is down.
            // In AppKit screen coordinates: +x is right, +y is UP.
            let newOrigin = NSPoint(x: start.x + translation.width, y: start.y - translation.height)
            panel.setCustomOrigin(newOrigin)
        }

        viewModel.onDragEnded = {
            dragStartOrigin = nil
        }

        // Allow keyboard focus when sheets (settings, follow-up, permissions) are active
        viewModel.onKeyWindowPermissionChange = { [weak panel] allows in
            panel?.allowsKeyWindow = allows
            if allows {
                panel?.makeKey()
            }
        }

        // Setup Menu Bar Item
        self.menuBarController = MenuBarController(
            onActivate: { [weak self] in
                Task { @MainActor in
                    await self?.viewModel.triggerSession()
                }
            },
            onCheckPermissions: { [weak self] in
                Task { @MainActor in
                    self?.viewModel.showPermissionsSheet = true
                }
            },
            onOpenSettings: {
                Task { @MainActor in
                    SettingsWindowController.show()
                }
            },
            onResetPosition: { [weak self] in
                Task { @MainActor in
                    self?.islandPanel?.resetToDefaultPosition()
                }
            },
            onTelescopeInspection: { [weak self] in
                Task { @MainActor in
                    await self?.viewModel.triggerTelescopeInspection()
                }
            },
            onPeekingGlance: { [weak self] in
                Task { @MainActor in
                    self?.viewModel.triggerIdlePeekingGlance()
                }
            }
        )

        // Setup Global Hotkey (⌥⌘P)
        let hotKeyRegistered = hotKeyController.register { [weak self] in
            Task { @MainActor in
                if self?.islandPanel?.customOrigin == nil {
                    self?.islandPanel?.repositionTopCenter()
                }
                await self?.viewModel.triggerSession()
            }
        }

        // Setup Telescope Inspection Trigger (Control + Option + Command ⌃⌥⌘)
        hotKeyController.onTelescopeInspectionTrigger = { [weak self] isHolding in
            Task { @MainActor in
                guard let self = self else { return }
                if isHolding {
                    if self.viewModel.state == .idle {
                        await self.viewModel.triggerTelescopeInspection()
                    }
                } else {
                    if self.viewModel.state.isCapturing && self.viewModel.isTelescopeInspectionMode {
                        await self.viewModel.stopCapture()
                    }
                }
            }
        }

        // Setup Option + Command Hold to Record & Release to Stop (Wispr Flow style)
        hotKeyController.registerOptionCommandHold(
            onHoldStart: { [weak self] in
                Task { @MainActor in
                    guard let self = self else { return }
                    if self.viewModel.state == .idle {
                        if self.islandPanel?.customOrigin == nil {
                            self.islandPanel?.repositionTopCenter()
                        }
                        await self.viewModel.triggerSession()
                    }
                }
            },
            onHoldEnd: { [weak self] in
                Task { @MainActor in
                    guard let self = self else { return }
                    if self.viewModel.state.isCapturing {
                        await self.viewModel.stopCapture()
                    }
                }
            }
        )

        print("Pipsey started successfully!")
        print("  HotKey (⌥⌘P) registered: \(hotKeyRegistered)")
        print("  Companion Panel presented: \(panel.isVisible)")
        print("  Footprint: \(panel.currentWidth)x\(panel.currentHeight) (Style: \(panel.companionStyle.rawValue))")

        // Observe Demo Simulation requests from Settings or Onboarding
        NotificationCenter.default.addObserver(forName: NSNotification.Name("PipseyTriggerDemoSimulation"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                await self?.viewModel.runDemoSimulation()
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When clicking Pipsey in the macOS Dock or Launchpad:
        islandPanel?.orderFrontRegardless()
        withAnimation {
            viewModel.isHovering = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            withAnimation {
                self?.viewModel.isHovering = false
            }
        }
        return true
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        let activateItem = NSMenuItem(title: "Activate Pipsey (⌥⌘P)", action: #selector(handleActivate), keyEquivalent: "")
        activateItem.target = self
        menu.addItem(activateItem)

        let historyItem = NSMenuItem(title: "Interaction Library...", action: #selector(handleHistory), keyEquivalent: "")
        historyItem.target = self
        menu.addItem(historyItem)

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(handleSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let snapItem = NSMenuItem(title: "Snap to Top Center", action: #selector(handleResetPosition), keyEquivalent: "")
        snapItem.target = self
        menu.addItem(snapItem)

        menu.addItem(NSMenuItem.separator())
        let demoItem = NSMenuItem(title: "Try Demo Simulation", action: #selector(handleDemoSimulation), keyEquivalent: "")
        demoItem.target = self
        menu.addItem(demoItem)
        return menu
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // 1. Pipsey Application Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "Pipsey")
        let aboutItem = NSMenuItem(title: "About Pipsey", action: #selector(handleAbout), keyEquivalent: "")
        aboutItem.target = self
        appMenu.addItem(aboutItem)
        appMenu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(handleSettings), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(settingsItem)

        let historyItem = NSMenuItem(title: "Interaction Library...", action: #selector(handleHistory), keyEquivalent: "h")
        historyItem.target = self
        appMenu.addItem(historyItem)

        let guideItem = NSMenuItem(title: "Welcome & Quickstart Guide...", action: #selector(handleGuide), keyEquivalent: "")
        guideItem.target = self
        appMenu.addItem(guideItem)

        let demoItem = NSMenuItem(title: "Try Demo Simulation...", action: #selector(handleDemoSimulation), keyEquivalent: "d")
        demoItem.keyEquivalentModifierMask = [.option, .command]
        demoItem.target = self
        appMenu.addItem(demoItem)

        appMenu.addItem(NSMenuItem.separator())
        let hideItem = NSMenuItem(title: "Hide Pipsey", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(hideItem)
        let hideOthersItem = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.option, .command]
        appMenu.addItem(hideOthersItem)
        let showAllItem = NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(showAllItem)
        appMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Pipsey", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitItem)
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // 2. Edit Menu (crucial so ⌘C, ⌘V, ⌘X, ⌘A, ⌘Z work natively in text fields!)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "Z"))
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // 3. View Menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        let snapItem = NSMenuItem(title: "Snap Island to Top Center", action: #selector(handleResetPosition), keyEquivalent: "")
        snapItem.target = self
        viewMenu.addItem(snapItem)
        let libItem = NSMenuItem(title: "Interaction Library", action: #selector(handleHistory), keyEquivalent: "l")
        libItem.target = self
        viewMenu.addItem(libItem)
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // 4. Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(NSMenuItem(title: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"))
        windowMenu.addItem(NSMenuItem(title: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: ""))
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        // 5. Help Menu
        let helpMenuItem = NSMenuItem()
        let helpMenu = NSMenu(title: "Help")
        let helpGuideItem = NSMenuItem(title: "Pipsey Quickstart Guide", action: #selector(handleGuide), keyEquivalent: "?")
        helpGuideItem.target = self
        helpMenu.addItem(helpGuideItem)
        helpMenuItem.submenu = helpMenu
        mainMenu.addItem(helpMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func handleActivate() {
        Task { @MainActor in
            await viewModel.triggerSession()
        }
    }

    @objc private func handleDemoSimulation() {
        Task { @MainActor in
            await viewModel.runDemoSimulation()
        }
    }

    @objc private func handleSettings() {
        SettingsWindowController.show()
    }

    @objc private func handleHistory() {
        HistoryWindowController.shared.showHistory()
    }

    @objc private func handleGuide() {
        OnboardingWindowController.shared.showOnboarding(force: true)
    }

    @objc private func handleResetPosition() {
        islandPanel?.resetToDefaultPosition()
    }

    @objc private func handleAbout() {
        NSApp.orderFrontStandardAboutPanel(
            options: [
                NSApplication.AboutPanelOptionKey.applicationName: "Pipsey",
                NSApplication.AboutPanelOptionKey.version: "0.1.0",
                NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "Pipsey AI Companion"
            ]
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyController.unregister()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
