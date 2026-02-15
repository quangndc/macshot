// HotkeyManager.swift
// This file manages global hotkeys (keyboard shortcuts that work anywhere)
// Uses CGEventTap for modern macOS event monitoring

import ApplicationServices

// Global storage for current hotkey info (accessible from callback)
// Store only keyCode and modifiers (no main actor closure)
private nonisolated(unsafe) var currentHotkeyTuple: (keyCode: UInt32, modifiers: UInt32)?

// Global reference to HotkeyManager for callback access
private nonisolated(unsafe) var sharedHotkeyManager: HotkeyManager?

// HOTKEY ERROR - Errors that can occur during hotkey registration
enum HotkeyError: Error, LocalizedError {
    case permissionDenied
    case registrationFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Accessibility permission not granted"
        case .registrationFailed:
            return "Failed to register hotkey"
        }
    }
}

// @MainActor means this runs on the main thread for safety
@MainActor
final class HotkeyManager: ObservableObject {

    // eventTap is our "listening device" for keyboard events
    private var eventTap: CFMachPort?

    // runLoopSource integrates the tap with macOS's event processing
    private var runLoopSource: CFRunLoopSource?

    // Reconnection monitoring
    private var reconnectTimer: Timer?

    // Rate limiting
    private var lastTriggerTime: Date?
    private let minimumInterval: TimeInterval = 0.5

    // Current hotkey info for reconnection
    private var currentHotkeyInfo: Hotkey?

    // captureHandler is what happens when hotkey is pressed
    private let captureHandler: @MainActor () -> Void

    // INITIALIZER - Sets up the hotkey manager
    init(captureHandler: @escaping @MainActor () -> Void) {
        self.captureHandler = captureHandler
        sharedHotkeyManager = self
    }

    // REGISTER FROM SETTINGS - Load from SettingsStore and register
    func registerFromSettings() -> Bool {
        let storedHotkey = Hotkey(
            id: 1,
            keyCode: SettingsStore.captureFullscreenHotkey.keyCode,
            flags: SettingsStore.captureFullscreenHotkey.cgEventFlags,
            description: SettingsStore.captureFullscreenHotkey.description
        )
        return register(hotkey: storedHotkey)
    }

    // REGISTER - Tells macOS "hey, I want this keyboard shortcut"
    func register(hotkey: Hotkey) -> Bool {
        unregister()
        currentHotkeyInfo = hotkey

        guard AXIsProcessTrusted() else {
            print("Accessibility permission not granted. Please enable in System Settings > Privacy & Security > Accessibility")
            let options: [String: Bool] = ["AXTrustedCheckOptionPrompt": true]
            _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
            return false
        }

        do {
            try registerWithRetry(hotkey, attempts: 3)
            print("Hotkey registered: \(hotkey.description)")
            return true
        } catch {
            print("Failed to register hotkey after retries: \(error)")
            return false
        }
    }

    // REGISTER WITH RETRY - Attempt registration multiple times
    private func registerWithRetry(_ hotkey: Hotkey, attempts: Int) throws {
        for attempt in 0..<attempts {
            do {
                try registerEventTap(hotkey)
                return
            } catch {
                if attempt == attempts - 1 {
                    throw error
                }
                Thread.sleep(forTimeInterval: 0.1 * Double(attempt + 1))
            }
        }
    }

    // REGISTER EVENT TAP - Create and configure event tap
    private func registerEventTap(_ hotkey: Hotkey) throws {
        // Store hotkey info in global variable for callback access
        currentHotkeyTuple = (
            keyCode: hotkey.keyCode,
            modifiers: hotkey.modifiers
        )

        let eventMask = (1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventTapCallback,
            userInfo: nil
        ) else {
            throw HotkeyError.registrationFailed
        }

        eventTap = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        self.runLoopSource = runLoopSource
        CGEvent.tapEnable(tap: tap, enable: true)
        startHealthMonitoring()
    }

    // START HEALTH MONITORING
    private func startHealthMonitoring() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.isTapHealthy() {
                print("Event tap unhealthy, attempting reconnect")
                self.reconnect()
            }
        }
    }

    // IS TAP HEALTHY
    private func isTapHealthy() -> Bool {
        guard let tap = eventTap else { return false }
        return CGEvent.tapIsEnabled(tap: tap)
    }

    // RECONNECT
    @MainActor
    private func reconnect() {
        guard let hotkey = currentHotkeyInfo else { return }
        unregister(keepHotkeyInfo: true)

        Task { @MainActor in
            do {
                try registerWithRetry(hotkey, attempts: 3)
                print("Event tap reconnected successfully")
            } catch {
                print("Event tap reconnection failed: \(error.localizedDescription)")
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(10))
                    self.reconnect()
                }
            }
        }
    }

    // HANDLE HOTKEY TRIGGER
    func handleHotkeyTrigger() {
        let now = Date()
        if let last = lastTriggerTime,
           now.timeIntervalSince(last) < minimumInterval {
            return
        }
        lastTriggerTime = now
        Task { @MainActor [weak self] in
            self?.captureHandler()
        }
    }

    // UNREGISTER
    func unregister(keepHotkeyInfo: Bool = false) {
        reconnectTimer?.invalidate()
        reconnectTimer = nil

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
        }

        eventTap = nil
        runLoopSource = nil
        currentHotkeyTuple = nil

        if !keepHotkeyInfo {
            currentHotkeyInfo = nil
        }
    }

    // DEINIT
    nonisolated deinit {
        currentHotkeyTuple = nil
        // Timer cleanup happens in unregister
    }
}

// EVENT TAP CALLBACK
private let eventTapCallback: CGEventTapCallBack = {
    (proxy: CGEventTapProxy,
     type: CGEventType,
     event: CGEvent,
     refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? in

    guard type == .keyDown else {
        return Unmanaged.passUnretained(event)
    }

    guard let hotkey = currentHotkeyTuple else {
        return Unmanaged.passUnretained(event)
    }

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = event.flags

    if isHotkeyMatch(keyCode: keyCode, flags: flags, hotkey: hotkey) {
        // Dispatch to main actor to handle the hotkey
        DispatchQueue.main.async {
            sharedHotkeyManager?.handleHotkeyTrigger()
        }
        event.setIntegerValueField(.keyboardEventKeycode, value: 0)
        return Unmanaged.passRetained(event)
    }

    return Unmanaged.passUnretained(event)
}

// IS HOTKEY MATCH
private nonisolated(unsafe) func isHotkeyMatch(
    keyCode: Int64,
    flags: CGEventFlags,
    hotkey: (keyCode: UInt32, modifiers: UInt32)
) -> Bool {
    guard keyCode == Int64(hotkey.keyCode) else {
        return false
    }

    var targetFlags: CGEventFlags = []
    let modifiers = hotkey.modifiers

    if modifiers & UInt32(CGEventFlags.maskCommand.rawValue) != 0 {
        targetFlags.insert(.maskCommand)
    }
    if modifiers & UInt32(CGEventFlags.maskShift.rawValue) != 0 {
        targetFlags.insert(.maskShift)
    }
    if modifiers & UInt32(CGEventFlags.maskAlternate.rawValue) != 0 {
        targetFlags.insert(.maskAlternate)
    }
    if modifiers & UInt32(CGEventFlags.maskSecondaryFn.rawValue) != 0 {
        targetFlags.insert(.maskSecondaryFn)
    }

    return flags == targetFlags
}

// HOTKEY - A simple data structure to describe a hotkey
struct Hotkey: Codable, Equatable, Sendable {
    var id: Int
    var keyCode: UInt32
    var modifiers: UInt32
    var description: String

    var cgEventFlags: CGEventFlags {
        var flags: CGEventFlags = []
        if modifiers & UInt32(CGEventFlags.maskCommand.rawValue) != 0 {
            flags.insert(.maskCommand)
        }
        if modifiers & UInt32(CGEventFlags.maskShift.rawValue) != 0 {
            flags.insert(.maskShift)
        }
        if modifiers & UInt32(CGEventFlags.maskAlternate.rawValue) != 0 {
            flags.insert(.maskAlternate)
        }
        if modifiers & UInt32(CGEventFlags.maskSecondaryFn.rawValue) != 0 {
            flags.insert(.maskSecondaryFn)
        }
        return flags
    }

    init(id: Int, keyCode: UInt32, flags: CGEventFlags, description: String) {
        self.id = id
        self.keyCode = keyCode
        self.modifiers = UInt32(truncatingIfNeeded: flags.rawValue)
        self.description = description
    }
}

// SYSTEM RESERVED HOTKEYS
extension Hotkey {
    static var systemReserved: [Hotkey] {
        [
            Hotkey(id: 100, keyCode: 0x0C, flags: .maskCommand, description: "Q+Cmd"),
            Hotkey(id: 101, keyCode: 0x0D, flags: .maskCommand, description: "W+Cmd"),
            Hotkey(id: 102, keyCode: 0x08, flags: .maskCommand, description: "C+Cmd"),
            Hotkey(id: 103, keyCode: 0x09, flags: .maskCommand, description: "V+Cmd"),
            Hotkey(id: 104, keyCode: 0x07, flags: .maskCommand, description: "X+Cmd"),
            Hotkey(id: 105, keyCode: 0x06, flags: .maskCommand, description: "Z+Cmd"),
            Hotkey(id: 106, keyCode: 0x00, flags: .maskCommand, description: "A+Cmd"),
            Hotkey(id: 107, keyCode: 0x01, flags: .maskCommand, description: "S+Cmd"),
            Hotkey(id: 108, keyCode: 0x23, flags: .maskCommand, description: "P+Cmd"),
            Hotkey(id: 109, keyCode: 0x03, flags: .maskCommand, description: "F+Cmd"),
            Hotkey(id: 110, keyCode: 0x31, flags: .maskCommand, description: "Space+Cmd"),
            Hotkey(id: 111, keyCode: 0x30, flags: .maskCommand, description: "Tab+Cmd"),
            Hotkey(id: 112, keyCode: 0x2E, flags: .maskCommand, description: "M+Cmd"),
            Hotkey(id: 113, keyCode: 0x04, flags: .maskCommand, description: "H+Cmd"),
            Hotkey(id: 114, keyCode: 0x35, flags: .maskCommand, description: "Esc+Cmd"),
        ]
    }

    func isSystemReserved() -> Bool {
        Self.systemReserved.contains(self)
    }
}

// DEFAULT HOTKEY
extension Hotkey {
    static let `default` = Hotkey(
        id: 1,
        keyCode: 59,
        flags: [.maskCommand, .maskShift],
        description: "⌘⇧5"
    )
}
