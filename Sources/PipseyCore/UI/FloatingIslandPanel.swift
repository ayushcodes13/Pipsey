import AppKit
import SwiftUI

@MainActor
public final class FloatingIslandPanel: NSPanel {
    public private(set) var currentWidth: CGFloat = 340
    public private(set) var currentHeight: CGFloat = 64
    public var allowsKeyWindow: Bool = false
    public var customOrigin: NSPoint? = nil

    public init(contentRect: NSRect, level: NSWindow.Level = .floating) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.isFloatingPanel = true
        self.isMovableByWindowBackground = true
        self.level = level
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

    public func setCustomOrigin(_ newOrigin: NSPoint) {
        let screen = self.screen ?? FloatingIslandPanel.targetScreenForCursor()
        let clampedX = max(screen.frame.minX + 4, min(screen.frame.maxX - currentWidth - 4, newOrigin.x))
        let clampedY = max(screen.visibleFrame.minY + 4, min(screen.frame.maxY - currentHeight, newOrigin.y))
        let origin = NSPoint(x: clampedX, y: clampedY)
        self.customOrigin = origin
        self.setFrameOrigin(origin)
    }

    public func resetToDefaultPosition() {
        self.customOrigin = nil
        reposition(width: currentWidth, height: currentHeight)
    }

    public func reposition(on targetScreen: NSScreen? = nil, width: CGFloat = 340, height: CGFloat = 64) {
        self.currentWidth = width
        self.currentHeight = height

        let screen = targetScreen ?? FloatingIslandPanel.targetScreenForCursor()
        let metrics = NotchMetrics.current(for: screen)
        let screenRect = screen.frame

        let x = screenRect.origin.x + (screenRect.width - width) / 2.0
        let y: CGFloat

        if metrics.hasPhysicalNotch {
            // Hardware Notch: anchors flush to the top bezel
            y = screenRect.origin.y + screenRect.height - height
        } else {
            // Non-Notched Screen (e.g. M1 Air): floats cleanly below the system menu bar
            let menuBarBottom = screen.visibleFrame.origin.y + screen.visibleFrame.height
            y = menuBarBottom - height - 8
        }

        self.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true, animate: false)
    }

    public func updateGeometry(width: CGFloat, height: CGFloat, on targetScreen: NSScreen? = nil) {
        let oldWidth = self.currentWidth
        let oldHeight = self.currentHeight
        self.currentWidth = width
        self.currentHeight = height

        if let origin = customOrigin {
            let screen = targetScreen ?? self.screen ?? FloatingIslandPanel.targetScreenForCursor()
            let newX = origin.x - (width - oldWidth) / 2.0
            let isNearBottom = origin.y < screen.visibleFrame.midY
            let newY = isNearBottom ? origin.y : origin.y - (height - oldHeight)

            let clampedX = max(screen.frame.minX + 4, min(screen.frame.maxX - width - 4, newX))
            let clampedY = max(screen.visibleFrame.minY + 4, min(screen.frame.maxY - height, newY))
            self.customOrigin = NSPoint(x: clampedX, y: clampedY)
            self.setFrame(NSRect(x: clampedX, y: clampedY, width: width, height: height), display: true, animate: false)
        } else {
            reposition(on: targetScreen, width: width, height: height)
        }
    }

    public func repositionTopCenter() {
        resetToDefaultPosition()
    }
}
