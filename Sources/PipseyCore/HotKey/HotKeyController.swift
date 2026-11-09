import Foundation
import AppKit
import Carbon

public final class HotKeyController: @unchecked Sendable {
    public typealias ActionHandler = @Sendable () -> Void

    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private var actionHandler: ActionHandler?
    private var flagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var isHoldingOptionCommand: Bool = false
    private var holdStartTime: Date?
    private var onHoldStart: ActionHandler?
    private var onHoldEnd: ActionHandler?

    public init() {}

    deinit {
        unregister()
    }

    public func registerOptionCommandHold(
        onHoldStart: @escaping ActionHandler,
        onHoldEnd: @escaping ActionHandler
    ) {
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
        if let local = localFlagsMonitor {
            NSEvent.removeMonitor(local)
            localFlagsMonitor = nil
        }

        self.onHoldStart = onHoldStart
        self.onHoldEnd = onHoldEnd

        let handleFlags: (NSEvent) -> Void = { [weak self] event in
            guard let self = self else { return }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let isOptCmd = flags.contains([.option, .command])

            if isOptCmd {
                if !self.isHoldingOptionCommand {
                    self.isHoldingOptionCommand = true
                    self.holdStartTime = Date()
                    self.onHoldStart?()
                }
            } else {
                if self.isHoldingOptionCommand {
                    self.isHoldingOptionCommand = false
                    let duration = Date().timeIntervalSince(self.holdStartTime ?? Date())
                    // If held for >= 0.30s, release finishes capture automatically
                    if duration >= 0.30 {
                        self.onHoldEnd?()
                    }
                }
            }
        }

        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
            handleFlags(event)
        }

        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            handleFlags(event)
            return event
        }
    }

    public func register(
        keyCode: UInt32 = 35, // 35 is Key code 'P' on QWERTY
        modifiers: UInt32 = UInt32(cmdKey | optionKey),
        onTrigger: @escaping ActionHandler
    ) -> Bool {
        unregister()
        self.actionHandler = onTrigger

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                let controller = Unmanaged<HotKeyController>.fromOpaque(userData).takeUnretainedValue()
                controller.actionHandler?()
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandler
        )

        guard status == noErr else {
            return false
        }

        let hotKeyID = EventHotKeyID(signature: OSType(0x50495053), id: 1) // 'PIPS'
        var hotKey: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )

        if registerStatus == noErr {
            self.hotKeyRef = hotKey
            return true
        } else {
            if let handler = eventHandler {
                RemoveEventHandler(handler)
                eventHandler = nil
            }
            return false
        }
    }

    public func unregister() {
        if let hotKey = hotKeyRef {
            UnregisterEventHotKey(hotKey)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
        if let local = localFlagsMonitor {
            NSEvent.removeMonitor(local)
            localFlagsMonitor = nil
        }
        actionHandler = nil
        onHoldStart = nil
        onHoldEnd = nil
    }
}
