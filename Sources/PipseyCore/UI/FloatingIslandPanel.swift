import AppKit
import SwiftUI

@MainActor
public final class FloatingIslandPanel: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.hasShadow = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func screenParametersDidChange(_ notification: Notification) {
        reposition()
    }

    override public var canBecomeKey: Bool {
        return false
    }

    override public var canBecomeMain: Bool {
        return false
    }

    public static func targetScreenForCursor() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        for screen in NSScreen.screens {
            if NSMouseInRect(mouseLocation, screen.frame, false) {
                return screen
            }
        }
        return NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    }

    public func reposition(on targetScreen: NSScreen? = nil) {
        let screen = targetScreen ?? FloatingIslandPanel.targetScreenForCursor()
        let screenRect = screen.frame
        let visibleRect = screen.visibleFrame

        let panelWidth: CGFloat = 340
        let panelHeight: CGFloat = 64

        let topInset: CGFloat
        if #available(macOS 12.0, *) {
            topInset = screen.safeAreaInsets.top
        } else {
            topInset = 0
        }

        let x = screenRect.origin.x + (screenRect.width - panelWidth) / 2.0
        let y: CGFloat
        if topInset > 0 {
            // Screen with camera notch: position directly hugging the notch bottom
            y = screenRect.origin.y + screenRect.height - panelHeight - (topInset / 2.0)
        } else {
            // Non-notch Mac (e.g. M1 Air / 13" M1 MBP): position 6pt below the menu bar
            y = visibleRect.origin.y + visibleRect.height - panelHeight - 6
        }

        self.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
    }

    public func repositionTopCenter() {
        reposition()
    }
}
