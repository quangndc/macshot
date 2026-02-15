---
title: "Phase 02: CGEventTap Implementation"
description: "Replace Carbon API with CGEventTap architecture"
status: pending
priority: P1
effort: 2h
branch: master
tags: [implementation, cgeventtap, core-graphics]
created: 2026-02-15
---

# Phase 02: CGEventTap Implementation

## Context Links
- [Main Plan](./plan.md)
- [Phase 01](./phase-01-setup-research.md)
- [Current HotkeyManager](../../MacShot/System/HotkeyManager.swift)

## Overview
**Priority**: P1 (Critical implementation)
**Status**: Pending
**Effort**: 2 hours

Replace deprecated Carbon API with modern CGEventTap architecture for global hotkey event handling.

## Key Insights

### Core Architecture Changes
1. **Remove Carbon**: Delete `import Carbon` and all Carbon types
2. **CGEventTap**: Use `CGEvent.tapCreate()` for event monitoring
3. **CFRunLoop**: Integrate with `CFMachPort` and `CFRunLoopSource`
4. **Callback Bridge**: Use `@convention(c)` for Swift-C interop

### Critical Implementation Points
- Event tap callback runs on background thread
- Must dispatch to @MainActor for UI updates
- Proper CF object cleanup to prevent leaks
- Accessibility permission required

## Requirements

### Functional Requirements
- [ ] Remove all Carbon API imports and types
- [ ] Implement CGEventTap with keydown event filtering
- [ ] Create thread-safe callback bridge
- [ ] Integrate with CFRunLoop for event processing
- [ ] Implement proper cleanup and deinitialization

### Non-Functional Requirements
- [ ] Zero memory leaks
- [ ] Thread-safe operation
- [ ] Compatible with macOS 15.0+
- [ ] Apple Silicon compatible (arm64)

## Architecture

### New Data Flow
```
User Presses Keys → CGEventTap → Callback (bg thread)
    → Task{@MainActor} → captureHandler() → CaptureEngine
```

### Class Structure
```swift
@MainActor
final class HotkeyManager: ObservableObject {
    // Properties
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let captureHandler: @MainActor () -> Void
    private var callbackContext: CallbackContext?

    // Methods
    init(captureHandler: @escaping @MainActor () -> Void)
    func register(hotkey: Hotkey) -> Bool
    func unregister()
    private func installEventTap()
    private func removeEventTap()
}
```

### Callback Signature
```swift
private let eventTapCallback: CGEventTapCallBack = {
    (proxy: CGEventTapProxy,
     type: CGEventType,
     event: CGEvent,
     refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? in
    // Implementation
}
```

## Related Code Files

### Files to Modify
- **Primary**: `MacShot/System/HotkeyManager.swift`
  - Remove: `import Carbon`, EventHotKeyRef, EventTypeSpec
  - Add: CGEventTap callback, CFRunLoop integration
  - Update: register(), unregister(), installHandler()

### Files to Verify Compatibility
- `MacShot/MacShotApp.swift` - Integration pattern unchanged
- `MacShot/System/Settings/SettingsStore.swift` - Hotkey storage compatible

### Files to Create
- None (rewrite existing file)

## Implementation Steps

### Step 1: Remove Carbon Dependencies (15min)
```swift
// DELETE:
import Carbon
private var hotkeyRef: EventHotKeyRef?
var eventType = EventTypeSpec(...)
var hotkeyID = EventHotKeyID(...)
RegisterEventHotKey(...)
UnregisterEventHotKey(...)

// KEEP:
import ApplicationServices
struct Hotkey (no changes needed)
```

### Step 2: Create Callback Context (15min)
```swift
private struct CallbackContext {
    var handler: @MainActor () -> Void
    var keyCode: UInt32
    var modifiers: UInt32
}
```

### Step 3: Implement Event Tap Callback (30min)
```swift
private let eventTapCallback: CGEventTapCallBack = {
    (proxy: CGEventTapProxy,
     type: CGEventType,
     event: CGEvent,
     refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? in

    // Only handle keydown events
    guard type == .keyDown else {
        return Unmanaged.passUnretained(event)
    }

    // Extract context
    guard let refcon = refcon else {
        return Unmanaged.passUnretained(event)
    }
    let context = refcon.assumingMemoryBound(to: CallbackContext.self).pointee

    // Get event data
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = event.flags

    // Check for hotkey match (with modifier conversion)
    if isHotkeyMatch(keyCode: keyCode, flags: flags, context: context) {
        // Trigger capture on main thread
        Task { @MainActor in
            context.handler()
        }
        return nil  // Consume event
    }

    return Unmanaged.passUnretained(event)
}
```

### Step 4: Implement Registration (30min)
```swift
func register(hotkey: Hotkey) -> Bool {
    unregister()

    // Check Accessibility permission
    guard AXIsProcessTrusted() else {
        print("Accessibility permission not granted")
        return false
    }

    // Create event tap
    let eventMask = (1 << CGEventType.keyDown.rawValue)
    guard let tap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: CGEventMask(eventMask),
        callback: eventTapCallback,
        userInfo: nil
    ) else {
        print("Failed to create event tap")
        return false
    }

    eventTap = tap

    // Create and add run loop source
    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    self.runLoopSource = runLoopSource

    // Store context for callback
    callbackContext = CallbackContext(
        handler: captureHandler,
        keyCode: hotkey.keyCode,
        modifiers: hotkey.modifiers
    )

    // Enable the tap
    CGEvent.tapEnable(tap: tap, enable: true)

    return true
}
```

### Step 5: Implement Unregistration (15min)
```swift
func unregister() {
    if let tap = eventTap {
        CGEvent.tapEnable(tap: tap, enable: false)

        if let source = runLoopSource {
            CFRunLoopRemoveSource(
                CFRunLoopGetCurrent(),
                source,
                .commonModes
            )
        }
    }

    eventTap = nil
    runLoopSource = nil
    callbackContext = nil
}
```

### Step 6: Update registerFromSettings (10min)
```swift
func registerFromSettings() -> Bool {
    let storedHotkey = Hotkey(
        id: 1,
        keyCode: SettingsStore.captureFullscreenHotkey.keyCode,
        modifiers: SettingsStore.captureFullscreenHotkey.modifiers,
        description: SettingsStore.captureFullscreenHotkey.description
    )
    return register(hotkey: storedHotkey)
}
```

### Step 7: Add Modifier Conversion Helper (15min)
```swift
private func isHotkeyMatch(
    keyCode: Int64,
    flags: CGEventFlags,
    context: CallbackContext
) -> Bool {
    // Check key code
    guard keyCode == Int64(context.keyCode) else {
        return false
    }

    // Convert Carbon modifiers to CGEventFlags
    var targetFlags: CGEventFlags = []
    if context.modifiers & 0x01 != 0 { targetFlags.insert(.maskCommand) }
    if context.modifiers & 0x02 != 0 { targetFlags.insert(.maskShift) }
    if context.modifiers & 0x04 != 0 { targetFlags.insert(.maskOption) }
    if context.modifiers & 0x08 != 0 { targetFlags.insert(.maskControl) }

    return flags == targetFlags
}
```

## Todo List

- [ ] Remove `import Carbon` from HotkeyManager.swift
- [ ] Delete Carbon-specific types (EventHotKeyRef, EventTypeSpec, etc.)
- [ ] Create CallbackContext struct
- [ ] Implement eventTapCallback with @convention(c)
- [ ] Implement register() with CGEvent.tapCreate
- [ ] Implement unregister() with proper cleanup
- [ ] Add modifier conversion helper function
- [ ] Update registerFromSettings() method
- [ ] Add Accessibility permission check
- [ ] Test compilation (no errors)

## Success Criteria

### Definition of Done
1. Code compiles without errors
2. No Carbon imports remaining
3. CGEventTap properly configured
4. CFRunLoop integration complete
5. Proper cleanup implemented

### Validation Methods
- Build project successfully
- No compiler warnings
- Code review for memory safety
- Verify thread safety

## Risk Assessment

### High Risk Areas
- **Memory Leaks**: CF objects must be properly released
- **Thread Safety**: Callback runs on background thread
- **Permission Denial**: Accessibility required for operation

### Mitigation Strategies
- Proper cleanup in unregister()
- Task{@MainActor} dispatch for handler
- Clear permission prompt and instructions

## Security Considerations

### Privacy
- Events processed locally only
- No data logging or transmission
- User-configurable hotkey

### Access Control
- Accessibility permission required
- System permission dialog shown
- Graceful handling if denied

## Next Steps

### Dependencies
- Phase 01 must be complete

### Follow-up Tasks
- **Phase 03**: Migrate modifier constants in Hotkey struct
- **Phase 04**: Test with Accessibility permission
- **Phase 05**: Documentation and cleanup

### Blockers
- None (can proceed after Phase 01)

## Unresolved Questions
- Q: Should we prompt for Accessibility permission automatically?
- A: Yes, add prompt in register() if not granted
- Q: How to handle permission denied state?
- A: Return false from register() and log message

---

**Last Updated**: 2026-02-15
**Phase Status**: Pending
**Next Review**: During implementation
