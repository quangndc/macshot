---
title: "Phase 04: Testing & Validation"
description: "Test CGEventTap implementation and verify functionality"
status: pending
priority: P1
effort: 1.5h
branch: master
tags: [testing, validation, accessibility]
created: 2026-02-15
---

# Phase 04: Testing & Validation

## Context Links
- [Main Plan](./plan.md)
- [Phase 02](./phase-02-cgeventtap-implementation.md)
- [Phase 03](./phase-03-modifier-migration.md)

## Overview
**Priority**: P1 (Critical validation)
**Status**: Pending
**Effort**: 1.5 hours

Comprehensive testing of CGEventTap implementation including permissions, functionality, memory leaks, and architecture compatibility.

## Key Insights

### Testing Priorities
1. **Permission Flow**: Accessibility must be granted
2. **Event Matching**: Key code + modifiers must match exactly
3. **Thread Safety**: Callback dispatches to @MainActor
4. **Memory Management**: CF objects properly cleaned up
5. **Global Scope**: Works from any application

### Test Environment
- macOS 15.0+ required
- Accessibility permission needed
- Test from different applications
- Use Instruments for leak detection

## Requirements

### Functional Requirements
- [ ] Verify Accessibility permission prompt
- [ ] Test hotkey trigger from multiple apps
- [ ] Validate event matching accuracy
- [ ] Test hotkey registration/unregistration
- [ ] Verify memory leak prevention

### Non-Functional Requirements
- [ ] <50ms latency from keypress to handler
- [ ] Zero memory leaks after 100 triggers
- [ ] Compatible with Apple Silicon (arm64)
- [ ] Stable under rapid keypresses

## Architecture

### Test Flow
```
1. Grant Accessibility Permission
2. Launch MacShot
3. Register Hotkey (Cmd+Shift+5)
4. Switch to another app
5. Press Cmd+Shift+5
6. Verify capture triggered
7. Check memory usage
8. Unregister hotkey
9. Verify cleanup
```

### Testing Tools
- **Instruments**: Leak detection
- **Console.app**: Debug logging
- **Activity Monitor**: Memory usage
- **System Settings**: Permission verification

## Related Code Files

### Files to Test
- **Primary**: `MacShot/System/HotkeyManager.swift`
- **Integration**: `MacShot/MacShotApp.swift`
- **Storage**: `MacShot/System/Settings/SettingsStore.swift`

### Test Coverage
- Permission handling
- Event registration
- Event matching
- Thread dispatch
- Memory cleanup
- Apple Silicon compatibility

## Implementation Steps

### Step 1: Accessibility Permission Test (15min)
```swift
// Test permission check
func testAccessibilityPermission() {
    // 1. Check current permission status
    let trusted = AXIsProcessTrusted()
    print("Accessibility trusted: \(trusted)")

    // 2. If not trusted, prompt user
    if !trusted {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    // 3. Verify user granted permission
    // 4. Test registration with permission
}
```

### Step 2: Basic Event Trigger Test (20min)
```swift
// Manual test procedure:
// 1. Launch MacShot
// 2. Verify "Hotkey registered" in console
// 3. Switch to Finder/Safari/Notes
// 4. Press Cmd+Shift+5
// 5. Verify capture triggered
// 6. Check console for callback execution
```

### Step 3: Event Matching Accuracy (15min)
```swift
// Test cases:
// ✓ Cmd+Shift+5 (default) - should trigger
// ✗ Cmd+5 (missing Shift) - should NOT trigger
// ✗ Shift+5 (missing Cmd) - should NOT trigger
// ✗ Cmd+Shift+6 (wrong key) - should NOT trigger
// ✓ Test with custom hotkeys
```

### Step 4: Thread Safety Test (15min)
```swift
// Verify callback dispatch:
// 1. Add log in callback thread
// 2. Add log in @MainActor handler
// 3. Verify different thread IDs
// 4. Confirm handler runs on main thread
```

### Step 5: Memory Leak Detection (20min)
```
// Instruments procedure:
1. Open Instruments → Leaks template
2. Launch MacShot
3. Register hotkey
4. Trigger 100 hotkey presses
5. Unregister hotkey
6. Check for leaks
7. Verify CF object cleanup
```

### Step 6: Performance Test (10min)
```swift
// Measure latency:
// 1. Add timestamp at keypress
// 2. Add timestamp in handler
// 3. Calculate difference
// Target: <50ms
```

### Step 7: Registration/Unregistration Test (10min)
```swift
// Test lifecycle:
// 1. Register hotkey → verify active
// 2. Unregister → verify inactive
// 3. Register again → verify active
// 4. Multiple cycles → no errors
```

### Step 8: Apple Silicon Compatibility (5min)
```
// Verify on arm64:
1. Check architecture in Xcode
2. Test on Apple Silicon Mac
3. Verify no warnings/errors
4. Confirm event tap works
```

## Todo List

- [ ] Grant Accessibility permission in System Settings
- [ ] Build and launch MacShot
- [ ] Verify "Hotkey registered" console message
- [ ] Test hotkey from Finder
- [ ] Test hotkey from Safari
- [ ] Test hotkey from Notes
- [ ] Test incorrect key combinations (should not trigger)
- [ ] Run Instruments leak detection
- [ ] Measure keypress-to-handler latency
- [ ] Test registration/unregistration cycles
- [ ] Verify on Apple Silicon hardware
- [ ] Check console for errors/warnings

## Success Criteria

### Definition of Done
1. Hotkey triggers capture from any application
2. No memory leaks detected by Instruments
3. Works on Apple Silicon (arm64)
4. Compatible with macOS 15.0+
5. Proper cleanup on unregister
6. Accessibility permission flow works

### Validation Methods
- Manual testing from multiple apps
- Instruments leak detector
- Console log analysis
- Performance timing measurements
- Architecture verification

## Risk Assessment

### High Risk Areas
- **Permission Denied**: User hasn't granted Accessibility
- **Memory Leaks**: CF objects not released properly
- **Thread Issues**: Callback not dispatching correctly
- **Event Conflicts**: System apps blocking events

### Mitigation Strategies
- Clear permission prompts and instructions
- Proper cleanup in unregister()
- Task{@MainActor} dispatch
- Test with multiple applications

## Security Considerations

### Privacy
- No event logging
- Local processing only
- User control over hotkey

### Access Control
- Verify permission before registration
- Handle denial gracefully
- Clear error messages

## Next Steps

### Dependencies
- Phases 02-03 must be complete

### Follow-up Tasks
- **Phase 05**: Documentation and cleanup

### Blockers
- Accessibility permission must be granted

## Unresolved Questions
- Q: What if user denies Accessibility permission?
- A: Show helpful message with link to System Settings
- Q: How to handle permission changes during runtime?
- A: Listen for accessibility notifications and re-register

---

**Last Updated**: 2026-02-15
**Phase Status**: Pending
**Next Review**: During testing
