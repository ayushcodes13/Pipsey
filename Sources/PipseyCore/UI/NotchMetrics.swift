import AppKit

/// Calculates display-specific notch dimensions matching Apple hardware and virtual menu bar insets.
public struct NotchMetrics: Sendable {
    public let hasPhysicalNotch: Bool
    public let closedWidth: CGFloat
    public let closedHeight: CGFloat

    public init(hasPhysicalNotch: Bool, closedWidth: CGFloat, closedHeight: CGFloat) {
        self.hasPhysicalNotch = hasPhysicalNotch
        self.closedWidth = closedWidth
        self.closedHeight = closedHeight
    }

    @MainActor
    public static func current(for screen: NSScreen = FloatingIslandPanel.targetScreenForCursor()) -> NotchMetrics {
        var topInset: CGFloat = 0
        if #available(macOS 12.0, *) {
            topInset = screen.safeAreaInsets.top
        }

        var notchWidth: CGFloat = 185
        var notchHeight: CGFloat = 32

        if topInset > 0 {
            // Hardware Notch (e.g. 14" / 16" MacBook Pro)
            if #available(macOS 12.0, *) {
                if let left = screen.auxiliaryTopLeftArea?.width,
                   let right = screen.auxiliaryTopRightArea?.width {
                    notchWidth = screen.frame.width - left - right + 4
                }
            }
            notchHeight = topInset
            return NotchMetrics(hasPhysicalNotch: true, closedWidth: max(notchWidth, 185), closedHeight: notchHeight)
        } else {
            // Non-notched display (e.g. M1 MacBook Air, 13" MacBook Pro, Studio Display)
            // Compact, elegant floating capsule (draggable anywhere like Wispr Flow)
            let notchWidth: CGFloat = 180
            let notchHeight: CGFloat = 32
            return NotchMetrics(hasPhysicalNotch: false, closedWidth: notchWidth, closedHeight: notchHeight)
        }
    }
}
