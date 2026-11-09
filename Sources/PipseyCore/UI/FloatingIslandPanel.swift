import AppKit
import SwiftUI

@MainActor
public final class FloatingIslandPanel: NSPanel {
    public private(set) var currentWidth: CGFloat = 340
    public private(set) var currentHeight: CGFloat = 64
    public var allowsKeyWindow: Bool = false

    public init(contentRect: NSRect, level: NSWindow.Level = .floating) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = level
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        // SwiftUI NotchShape renders the tailored organic shadow; disable rectangular window shadow
        self.hasShadow = false

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
        reposition(width: currentWidth, height: currentHeight)
    }

    override public var canBecomeKey: Bool {
        return allowsKeyWindow
    }

    override public var canBecomeMain: Bool {
        return false
    }

    override public func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        // Return unconstrained frame so the notch anchors flush to the top bezel without being forced down by macOS
        return frameRect
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

    public func reposition(on targetScreen: NSScreen? = nil, width: CGFloat = 340, height: CGFloat = 64) {
        self.currentWidth = width
        self.currentHeight = height

        let screen = targetScreen ?? FloatingIslandPanel.targetScreenForCursor()
        let screenRect = screen.frame

        let x = screenRect.origin.x + (screenRect.width - width) / 2.0
        // Notch window anchors flush to the absolute top edge of the display
        let y = screenRect.origin.y + screenRect.height - height

        self.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true, animate: false)
    }

    public func updateGeometry(width: CGFloat, height: CGFloat, on targetScreen: NSScreen? = nil) {
        reposition(on: targetScreen, width: width, height: height)
    }

    public func repositionTopCenter() {
        reposition(width: currentWidth, height: currentHeight)
    }
}
