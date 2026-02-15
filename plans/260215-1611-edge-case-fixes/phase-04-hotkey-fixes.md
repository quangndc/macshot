# Phase 04: Hotkey System Improvements

**Priority:** HIGH
**Status:** Pending
**Estimated Complexity:** High

---

## Overview

Fix hotkey system edge cases related to conflict detection, event tap reliability, and user feedback. These fixes ensure global hotkeys work consistently and safely.

---

## Issues to Fix

### 1. Hotkey Conflict Detection

**Problem:** No detection for conflicts with system shortcuts
**Location:** `System/HotkeyManager.swift`, `Features/Settings/HotkeysSettings.swift`

**Impact:**
- Users can override system shortcuts
- Unpredictable behavior
- Security/privacy concerns

**Solution:**
```swift
// Add system hotkey blacklist
extension Hotkey {
    static var systemReserved: [Hotkey] {
        [
            // Command key combinations
            Hotkey(keyCode: .q, modifiers: .command),         // Quit
            Hotkey(keyCode: .w, modifiers: .command),         // Close
            Hotkey(keyCode: .c, modifiers: .command),         // Copy
            Hotkey(keyCode: .v, modifiers: .command),         // Paste
            Hotkey(keyCode: .x, modifiers: .command),         // Cut
            Hotkey(keyCode: .z, modifiers: .command),         // Undo
            Hotkey(keyCode: .a, modifiers: .command),         // Select All
            Hotkey(keyCode: .s, modifiers: .command),         // Save
            Hotkey(keyCode: .p, modifiers: .command),         // Print
            Hotkey(keyCode: .f, modifiers: .command),         // Find
            Hotkey(keyCode: .space, modifiers: .command),     // Spotlight
            Hotkey(keyCode: .tab, modifiers: .command),       // App switcher
            Hotkey(keyCode: .m, modifiers: .command),        // Minimize
            Hotkey(keyCode: .h, modifiers: .command),        // Hide
            Hotkey(keyCode: .q, modifiers: [.command, .option, .escape]), // Force Quit
            Hotkey(keyCode: .escape, modifiers: .command),     // Force quit apps
            Hotkey(keyCode: .period, modifiers: [.command, .option]), // Preferences
            Hotkey(keyCode: .comma, modifiers: [.command, .option]),  // Preferences
            Hotkey(keyCode: .one, modifiers: .command),       // Switch to desktop 1
            Hotkey(keyCode: .two, modifiers: .command),       // Switch to desktop 2
            Hotkey(keyCode: .three, modifiers: .command),      // Switch to desktop 3
            Hotkey(keyCode: .four, modifiers: .command),      // Switch to desktop 4
            Hotkey(keyCode: .upArrow, modifiers: [.command, .option, .control]), // Display
            Hotkey(keyCode: .downArrow, modifiers: [.command, .option, .control]), // Display
        ]
    }

    func isSystemReserved() -> Bool {
        Self.systemReserved.contains(self)
    }
}

// Add validation to AppSettings
@Observable
final class AppSettings: Equatable {
    func validateHotkeys() throws {
        let hotkeys = [
            ("fullscreen", captureFullscreenHotkey),
            ("region", captureRegionHotkey),
            ("window", captureWindowHotkey)
        ]

        // Check for system conflicts
        for (name, hotkey) in hotkeys {
            if hotkey.isSystemReserved() {
                throw SettingsError.systemHotkeyConflict(
                    action: name,
                    hotkey: hotkey
                )
            }
        }

        // Check for duplicates (from Phase 03)
        var seen: [Hotkey: String] = [:]
        for (name, hotkey) in hotkeys {
            if let existing = seen[hotkey] {
                throw SettingsError.duplicateHotkey(
                    hotkey: hotkey,
                    actions: [existing, name]
                )
            }
            seen[hotkey] = name
        }
    }
}

enum SettingsError: Error, LocalizedError {
    case systemHotkeyConflict(action: String, hotkey: Hotkey)

    var errorDescription: String? {
        if case let .systemHotkeyConflict(action, hotkey) = self {
            "Hotkey '\(hotkey.description)' conflicts with system shortcut for '\(action)'"
        }
        return nil
    }
}
```

**Files:**
- MODIFY: `MacShot/System/Settings/AppSettings.swift`
- MODIFY: `MacShot/Features/Settings/HotkeysSettings.swift`
- MODIFY: `MacShot/System/HotkeyManager.swift`

**Testing:**
- Try setting system shortcuts
- Verify conflict detection
- Test error messages

---

### 2. Event Tap Reconnection

**Problem:** No automatic reconnection for disconnected event taps
**Location:** `System/HotkeyManager.swift`

**Impact:**
- Hotkeys stop working after sleep/wake
- Requires app restart to recover
- Poor user experience

**Solution:**
```swift
// Add to HotkeyManager.swift
class HotkeyManager {
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var reconnectTimer: Timer?

    // NEW: Reconnection handling
    private var currentHotkey: Hotkey?
    private var currentHandler: (() -> Void)?

    func register(_ hotkey: Hotkey, handler: @escaping () -> Void) throws {
        // Check permissions first
        guard checkAccessibilityPermission() else {
            throw HotkeyError.permissionDenied
        }

        // Store for potential reconnection
        currentHotkey = hotkey
        currentHandler = handler

        // Attempt registration with retry
        try registerWithRetry(hotkey, handler: handler, attempts: 3)
    }

    private func registerWithRetry(_ hotkey: Hotkey, handler: @escaping () -> Void, attempts: Int) throws {
        for attempt in 0..<attempts {
            do {
                try registerEventTap(hotkey, handler: handler)
                return // Success
            } catch {
                if attempt == attempts - 1 {
                    throw error // Final attempt failed
                }

                // Wait before retry
                try await Task.sleep(for: .milliseconds(100 * (attempt + 1)))
            }
        }
    }

    private func registerEventTap(_ hotkey: Hotkey, handler: @escaping () -> Void) throws {
        // Create event tap
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        guard let newTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event in
                HotkeyCallback(proxy, type: type, event: event, hotkey: hotkey, handler: handler)
            },
            userInfo: nil
        ) else {
            throw HotkeyError.registrationFailed
        }

        tap = newTap
        runLoopSource = CFMachPortCreateRunLoopSource(newTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: newTap, enable: true)

        // Start health monitoring
        startHealthMonitoring()
    }

    private func startHealthMonitoring() {
        // Cancel any existing timer
        reconnectTimer?.invalidate()

        // Check tap health every 5 seconds
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if !self.isTapHealthy() {
                os_log(.warning, log: OSLog.default, "Event tap unhealthy, attempting reconnect")
                self.reconnect()
            }
        }
    }

    private func isTapHealthy() -> Bool {
        guard let tap = tap else { return false }

        // Check if tap is still enabled
        return CGEvent.tapIsEnabled(tap: tap)
    }

    private func reconnect() {
        guard let hotkey = currentHotkey,
              let handler = currentHandler else {
            return
        }

        // Unregister old tap
        unregister()

        // Attempt reconnection
        Task {
            do {
                try await self.registerWithRetry(hotkey, handler: handler)
                os_log(.info, log: OSLog.default, "Event tap reconnected successfully")
            } catch {
                os_log(.error, log: OSLog.default, "Event tap reconnection failed: %{public}@", error.localizedDescription)

                // Schedule another attempt
                try await Task.sleep(for: .seconds(10))
                self.reconnect()
            }
        }
    }

    func unregister() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            runLoopSource = nil
        }

        if let tap = tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            tap = nil
        }
    }
}
```

**Files:**
- MODIFY: `MacShot/System/HotkeyManager.swift`

**Testing:**
- Sleep/wake cycle
- Display connection changes
- Manual reconnect scenarios

---

### 3. Multiple Rapid Hotkey Presses

**Problem:** No rate limiting for successive hotkey triggers
**Location:** `System/HotkeyManager.swift`

**Impact:**
- Can queue multiple captures
- Resource exhaustion
- Unresponsive UI

**Solution:**
```swift
// Add rate limiting to HotkeyManager.swift
class HotkeyManager {
    private var lastTriggerTime: Date?
    private let minimumInterval: TimeInterval = 0.5 // 500ms between captures

    func handleHotkeyTrigger() {
        let now = Date()

        // Rate limiting check
        if let last = lastTriggerTime,
           now.timeIntervalSince(last) < minimumInterval {
            os_log(.debug, log: OSLog.default, "Hotkey ignored due to rate limiting")
            return
        }

        lastTriggerTime = now

        // Dispatch to main actor
        Task { @MainActor [weak self] in
            self?.triggerCapture()
        }
    }
}

// Update C callback
func HotkeyCallback(
    proxy: CGEventTapProxy,
    eventType: CGEventType,
    event: CGEvent,
    hotkey: Hotkey,
    handler: @escaping () -> Void
) -> Unmanaged<CGEvent>? {
    // Check if this is our hotkey
    guard let keyCode = CGEvent.getIntegerValueField(event, field: .keyboardEventKeycode),
          let rawModifiers = CGEvent.getFlagsValue(event),
          keyCode == UInt64(hotkey.keyCode.rawValue),
          matchModifiers(rawModifiers, hotkey.modifiers) else {
        return Unmanaged.passRetained(event)
    }

    // Consume the event
    CGEvent.setIntegerValueField(event, field: .keyboardEventKeycode, value: 0)

    // Handle with rate limiting
    HotkeyManager.shared?.handleHotkeyTrigger()

    return Unmanaged.passRetained(event)
}
```

**Files:**
- MODIFY: `MacShot/System/HotkeyManager.swift`

**Testing:**
- Rapid successive presses
- Verify rate limiting works
- No missed legitimate presses

---

### 4. Hotkey Recording Timeout

**Problem:** No timeout for hotkey recording
**Location:** `Features/Settings/HotkeyRecorder.swift`

**Impact:**
- Can get stuck waiting for input
- User confusion
- UI state inconsistency

**Solution:**
```swift
// Add timeout to HotkeyRecorder.swift
struct HotkeyRecorder: View {
    @Binding var hotkey: Hotkey
    @State private var isRecording = false
    @State private var timeoutTimer: Timer?
    @FocusState private var isFocused

    var body: some View {
        Button(action: startRecording) {
            HStack {
                Text(isRecording ? "Press keys..." : hotkey.description)
                Spacer()
                if isRecording {
                    Button("Cancel") {
                        stopRecording(cancel: true)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .focused($isFocused)
        .onChange(of: isFocused) { _, newValue in
            if !newValue && isRecording {
                // Lost focus while recording
                stopRecording(cancel: true)
            }
        }
    }

    private func startRecording() {
        isRecording = true

        // Set timeout (10 seconds)
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            self?.stopRecording(cancel: true)
        }
    }

    private func stopRecording(cancel: Bool) {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        isRecording = false
        // Handle cancel/save...
    }
}
```

**Files:**
- MODIFY: `MacShot/Features/Settings/HotkeyRecorder.swift`

**Testing:**
- Record without input (timeout)
- Cancel recording
- Record successfully

---

## Success Criteria

- [ ] System shortcut conflicts detected
- [ ] Event tap auto-reconnects after disconnect
- [ ] Rate limiting prevents rapid triggers
- [ ] Hotkey recording has timeout
- [ ] All hotkey edge cases tested

---

## Next Steps

After completing this phase:
1. Move to [Phase 05: Annotation System Validation](./phase-05-annotation-fixes.md)
2. Update hotkey tests
3. Test reconnect scenarios

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| False positive conflicts | Medium | Test common shortcuts |
| Reconnection loop | Low | Max retry attempts |
| Rate limiting too strict | Low | User-adjustable interval |
