import AppKit
import SwiftUI

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
    }

    override public var canBecomeKey: Bool {
        return false
    }

    override public var canBecomeMain: Bool {
        return false
    }

    public func repositionTopCenter() {
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame
        let visibleRect = screen.visibleFrame

        let panelWidth: CGFloat = 340
        let panelHeight: CGFloat = 64

        // Check if there is a notch
        let topInset: CGFloat
        if #available(macOS 12.0, *) {
            topInset = screen.safeAreaInsets.top
        } else {
            topInset = 0
        }

        let x = screenRect.origin.x + (screenRect.width - panelWidth) / 2.0
        let y: CGFloat
        if topInset > 0 {
            // Under the notch
            y = screenRect.origin.y + screenRect.height - panelHeight - (topInset / 2.0)
        } else {
            // Non-notch Mac: position just below the menu bar
            y = visibleRect.origin.y + visibleRect.height - panelHeight - 6
        }

        self.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
    }
}
