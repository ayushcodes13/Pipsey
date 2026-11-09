import AppKit
import SwiftUI

public enum CompanionStyle: String, CaseIterable, Sendable {
    case floatingCircle = "floatingCircle"
    case notchIsland = "notchIsland"
}

public enum CompanionCorner: String, CaseIterable, Sendable {
    case topRight = "topRight"
    case topLeft = "topLeft"
    case bottomRight = "bottomRight"
    case bottomLeft = "bottomLeft"
}

@MainActor
public final class FloatingIslandPanel: NSPanel {
    public private(set) var currentWidth: CGFloat = 340
    public private(set) var currentHeight: CGFloat = 64
    public var allowsKeyWindow: Bool = false
    public var customOrigin: NSPoint? = nil
    public var companionStyle: CompanionStyle = .floatingCircle
    public var anchorCorner: CompanionCorner = .topRight
    private var isProgrammaticReposition: Bool = false

    public init(contentRect: NSRect, level: NSWindow.Level = .floating) {
        self.currentWidth = contentRect.width > 0 ? contentRect.width : 340
        self.currentHeight = contentRect.height > 0 ? contentRect.height : 64
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
        self.acceptsMouseMovedEvents = true
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        // Exclude companion island UI from macOS ScreenCaptureKit and window recordings
        self.sharingType = .none
        // SwiftUI NotchShape renders the tailored organic shadow; disable rectangular window shadow
        self.hasShadow = false

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMoveNotification(_:)),
            name: NSWindow.didMoveNotification,
            object: self
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func screenParametersDidChange(_ notification: Notification) {
        reposition(width: currentWidth, height: currentHeight)
    }

    @objc private func windowDidMoveNotification(_ notification: Notification) {
        if !isProgrammaticReposition {
            self.customOrigin = self.frame.origin
        }
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
        let targetOrigin = NSPoint(x: clampedX, y: clampedY)

        // Check if tossed/dragged near any screen corner
        if let corner = detectNearestCorner(for: targetOrigin, on: screen) {
            self.snapToCorner(corner, on: screen)
            PipseySoundEffects.playTelescopeFocus()
        } else {
            self.customOrigin = targetOrigin
            self.setFrameOrigin(targetOrigin)
        }
    }

    public func detectNearestCorner(for origin: NSPoint, on screen: NSScreen) -> CompanionCorner? {
        let vis = screen.visibleFrame
        let threshold: CGFloat = 110

        let distTopRight = hypot(vis.maxX - (origin.x + currentWidth), vis.maxY - (origin.y + currentHeight))
        let distTopLeft = hypot(origin.x - vis.minX, vis.maxY - (origin.y + currentHeight))
        let distBottomRight = hypot(vis.maxX - (origin.x + currentWidth), origin.y - vis.minY)
        let distBottomLeft = hypot(origin.x - vis.minX, origin.y - vis.minY)

        let minDistance = min(distTopRight, distTopLeft, distBottomRight, distBottomLeft)
        guard minDistance < threshold else { return nil }

        if minDistance == distTopRight { return .topRight }
        if minDistance == distTopLeft { return .topLeft }
        if minDistance == distBottomRight { return .bottomRight }
        return .bottomLeft
    }

    public func snapToCorner(_ corner: CompanionCorner, on targetScreen: NSScreen? = nil) {
        self.anchorCorner = corner
        let screen = targetScreen ?? self.screen ?? FloatingIslandPanel.targetScreenForCursor()
        let vis = screen.visibleFrame
        let inset: CGFloat = 18

        let x: CGFloat
        let y: CGFloat

        switch corner {
        case .topRight:
            x = vis.maxX - currentWidth - inset
            y = vis.maxY - currentHeight - inset
        case .topLeft:
            x = vis.minX + inset
            y = vis.maxY - currentHeight - inset
        case .bottomRight:
            x = vis.maxX - currentWidth - inset
            y = vis.minY + inset
        case .bottomLeft:
            x = vis.minX + inset
            y = vis.minY + inset
        }

        let origin = NSPoint(x: x, y: y)
        self.customOrigin = origin
        self.setFrame(NSRect(origin: origin, size: NSSize(width: currentWidth, height: currentHeight)), display: true, animate: false)
    }

    public func resetToDefaultPosition() {
        self.customOrigin = nil
        reposition(width: currentWidth, height: currentHeight)
    }

    public func reposition(on targetScreen: NSScreen? = nil, width: CGFloat = 340, height: CGFloat = 64) {
        self.isProgrammaticReposition = true
        defer { self.isProgrammaticReposition = false }

        self.currentWidth = width
        self.currentHeight = height

        let screen = targetScreen ?? FloatingIslandPanel.targetScreenForCursor()

        if companionStyle == .floatingCircle && customOrigin == nil {
            let vis = screen.visibleFrame
            let inset: CGFloat = 18
            let x: CGFloat
            let y: CGFloat
            switch anchorCorner {
            case .topRight:
                x = vis.maxX - width - inset
                y = vis.maxY - height - inset
            case .topLeft:
                x = vis.minX + inset
                y = vis.maxY - height - inset
            case .bottomRight:
                x = vis.maxX - width - inset
                y = vis.minY + inset
            case .bottomLeft:
                x = vis.minX + inset
                y = vis.minY + inset
            }
            self.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true, animate: false)
            return
        }

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
        self.isProgrammaticReposition = true
        defer { self.isProgrammaticReposition = false }

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

@MainActor
public final class DraggableIslandHostingView<Content: View>: NSHostingView<Content> {
    override public var mouseDownCanMoveWindow: Bool {
        return true
    }
}
