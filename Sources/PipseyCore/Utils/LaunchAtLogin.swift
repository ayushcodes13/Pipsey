import Foundation
import ServiceManagement

/// Safe wrapper for macOS 13+ ServiceManagement `SMAppService` launch-at-login integration.
public final class LaunchAtLogin: Sendable {
    public static var isAvailable: Bool {
        if #available(macOS 13.0, *) {
            return Bundle.main.bundleIdentifier != nil
        }
        return false
    }

    public static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            guard Bundle.main.bundleIdentifier != nil else { return false }
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    @discardableResult
    public static func setEnabled(_ enabled: Bool) -> Bool {
        if #available(macOS 13.0, *) {
            guard Bundle.main.bundleIdentifier != nil else { return false }
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
                return true
            } catch {
                // If unregistered or not running from an installed application bundle, fail gracefully
                return false
            }
        }
        return false
    }
}
