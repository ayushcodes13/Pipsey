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
        // Run as accessory app so it doesn't show in the Dock or steal active app focus
        NSApp.setActivationPolicy(.accessory)

        // Setup Floating Notch Panel (anchored flush to screen top bezel)
        let metrics = NotchMetrics.current()
        let panel = FloatingIslandPanel(contentRect: NSRect(x: 0, y: 0, width: metrics.closedWidth, height: metrics.closedHeight))
        let hostingView = NSHostingView(rootView: CompanionIslandView(viewModel: viewModel))
        panel.contentView = hostingView
        panel.reposition(width: metrics.closedWidth, height: metrics.closedHeight)
        panel.orderFrontRegardless()
        self.islandPanel = panel

        // Dynamic geometry update when notch springs open or closes
        viewModel.onGeometryChange = { [weak panel] width, height in
            panel?.updateGeometry(width: width, height: height)
        }

        // Setup Menu Bar Item
        self.menuBarController = MenuBarController(
            onActivate: { [weak self] in
                Task { @MainActor in
                    self?.islandPanel?.repositionTopCenter()
                    await self?.viewModel.triggerSession()
                }
            },
            onCheckPermissions: {
                let snapshot = PermissionCoordinator.shared.currentSnapshot()
                print("Permission Status:")
                print("  Screen Recording: \(snapshot.screenRecording.rawValue)")
                print("  Microphone: \(snapshot.microphone.rawValue)")
                print("  Speech Recognition: \(snapshot.speechRecognition.rawValue)")
            }
        )

        // Setup Global Hotkey (⌥⌘P)
        let hotKeyRegistered = hotKeyController.register { [weak self] in
            Task { @MainActor in
                self?.islandPanel?.repositionTopCenter()
                await self?.viewModel.triggerSession()
            }
        }

        print("Pipsey started successfully!")
        print("  HotKey (⌥⌘P) registered: \(hotKeyRegistered)")
        print("  Top-Center Notch presented: \(panel.isVisible)")
        print("  Notch footprint: \(metrics.closedWidth)x\(metrics.closedHeight) (Physical notch: \(metrics.hasPhysicalNotch))")
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyController.unregister()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
