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

        // Setup Floating Island Panel (anchored to notch on hardware notch, or floating capsule below menu bar on non-notch)
        let metrics = NotchMetrics.current()
        let islandLevel = NSWindow.Level(Int(CGWindowLevelForKey(.floatingWindow)) + 10)
        let panel = FloatingIslandPanel(
            contentRect: NSRect(x: 0, y: 0, width: metrics.closedWidth, height: metrics.closedHeight),
            level: islandLevel
        )
        let hostingView = DraggableIslandHostingView(rootView: CompanionIslandView(viewModel: viewModel))
        panel.contentView = hostingView
        panel.reposition(width: metrics.closedWidth, height: metrics.closedHeight)
        panel.orderFrontRegardless()
        self.islandPanel = panel

        // Dynamic geometry update when notch springs open or closes
        viewModel.onGeometryChange = { [weak panel] width, height in
            panel?.updateGeometry(width: width, height: height)
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
            onOpenSettings: { [weak self] in
                Task { @MainActor in
                    self?.viewModel.showSettingsSheet = true
                }
            },
            onResetPosition: { [weak self] in
                Task { @MainActor in
                    self?.islandPanel?.resetToDefaultPosition()
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
