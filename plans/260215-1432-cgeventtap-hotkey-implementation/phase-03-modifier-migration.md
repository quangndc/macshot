---
title: "Phase 03: Modifier Flag Migration"
description: "Convert Carbon modifier constants to CGEventFlags"
status: pending
priority: P1
effort: 1h
branch: master
tags: [implementation, modifiers, migration]
created: 2026-02-15
---

# Phase 03: Modifier Flag Migration

## Context Links
- [Main Plan](./plan.md)
- [Phase 02](./phase-02-cgeventtap-implementation.md)
- [Current Hotkey Struct](../../MacShot/System/HotkeyManager.swift)

## Overview
**Priority**: P1 (Required for event matching)
**Status**: Pending
**Effort**: 1 hour

Convert Carbon modifier constants to CGEventFlags for proper hotkey event matching.

## Key Insights

### Modifier Constants Mapping
| Carbon | CGEventFlags | Value |
|--------|--------------|-------|
| cmdKey | maskCommand | 0x100000 |
| shiftKey | maskShift | 0x20000 |
| optionKey | maskOption | 0x80000 |
| controlKey | maskControl | 0x40000 |

### Critical Points
1. **Bit Positions**: Carbon uses lower bits, CGEventFlags uses higher bits
2. **Type Safety**: CGEventFlags is an OptionSet, not raw UInt32
3. **Default Hotkey**: Cmd+Shift+5 needs both flags set
4. **Storage**: UInt32 storage still works, just different bit positions

## Requirements

### Functional Requirements
- [ ] Update Hotkey struct to use CGEventFlags internally
- [ ] Maintain backward compatibility with SettingsStore
- [ ] Convert Carbon modifiers to CGEventFlags
- [ ] Update default hotkey definition
- [ ] Ensure proper bit flag comparisons

### Non-Functional Requirements
- [ ] No breaking changes to public API
- [ ] Type-safe modifier handling
- [ ] Clear documentation of changes

## Architecture

### Type Conversion Flow
```
SettingsStore (UInt32) → Hotkey (UInt32 storage)
    → CGEventFlags (internal comparison)
```

### Hotkey Struct Update
```swift
// BEFORE:
struct Hotkey: Codable, Equatable, Sendable {
    var id: Int
    var keyCode: UInt32
    var modifiers: UInt32  // Carbon constants
    var description: String
}

// AFTER:
struct Hotkey: Codable, Equatable, Sendable {
    var id: Int
    var keyCode: UInt32
    var modifiers: UInt32  // CGEventFlags raw values
    var description: String

    // Helper for conversion
    var cgEventFlags: CGEventFlags {
        var flags: CGEventFlags = []
        if modifiers & 0x100000 != 0 { flags.insert(.maskCommand) }
        if modifiers & 0x20000 != 0 { flags.insert(.maskShift) }
        if modifiers & 0x80000 != 0 { flags.insert(.maskOption) }
        if modifiers & 0x40000 != 0 { flags.insert(.maskControl) }
        return flags
    }
}
```

## Related Code Files

### Files to Modify
- **Primary**: `MacShot/System/HotkeyManager.swift`
  - Update Hotkey struct
  - Add CGEventFlags helper
  - Update default hotkey

### Files to Check Compatibility
- `MacShot/System/Settings/SettingsStore.swift` - Storage format unchanged
- `MacShot/Features/Settings/HotkeysSettings.swift` - UI compatibility

## Implementation Steps

### Step 1: Update Hotkey Struct (20min)
```swift
struct Hotkey: Codable, Equatable, Sendable {
    var id: Int
    var keyCode: UInt32
    var modifiers: UInt32  // Raw CGEventFlags values
    var description: String

    // Convert to CGEventFlags for comparison
    var cgEventFlags: CGEventFlags {
        var flags: CGEventFlags = []
        if modifiers & UInt32(CGEventFlags.maskCommand.rawValue) != 0 {
            flags.insert(.maskCommand)
        }
        if modifiers & UInt32(CGEventFlags.maskShift.rawValue) != 0 {
            flags.insert(.maskShift)
        }
        if modifiers & UInt32(CGEventFlags.maskOption.rawValue) != 0 {
            flags.insert(.maskOption)
        }
        if modifiers & UInt32(CGEventFlags.maskControl.rawValue) != 0 {
            flags.insert(.maskControl)
        }
        return flags
    }
}
```

### Step 2: Update Default Hotkey (10min)
```swift
extension Hotkey {
    static let `default` = Hotkey(
        id: 1,
        keyCode: 59,  // F5 key
        modifiers: UInt32(CGEventFlags.maskCommand.rawValue |
                         CGEventFlags.maskShift.rawValue),
        description: "⌘⇧5"
    )
}
```

### Step 3: Update Event Matching (20min)
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

    // Compare CGEventFlags directly
    let targetFlags = CGEventFlags(rawValue: context.modifiers)
    return flags == targetFlags
}
```

### Step 4: Add Conversion Helper (10min)
```swift
extension Hotkey {
    // Create from CGEventFlags for UI recording
    init(id: Int, keyCode: UInt32, flags: CGEventFlags, description: String) {
        self.id = id
        self.keyCode = keyCode
        self.modifiers = flags.rawValue
        self.description = description
    }
}
```

## Todo List

- [ ] Add cgEventFlags computed property to Hotkey
- [ ] Update default hotkey with CGEventFlags
- [ ] Update event matching logic in callback
- [ ] Add convenience initializer for CGEventFlags
- [ ] Test with Cmd+Shift+5 combination
- [ ] Test with single modifier (Cmd only)
- [ ] Test with three modifiers (Cmd+Shift+Option)
- [ ] Verify SettingsStore compatibility

## Success Criteria

### Definition of Done
1. Hotkey struct uses CGEventFlags internally
2. Default hotkey works with CGEventFlags
3. Event matching accurate for all combinations
4. SettingsStore compatibility maintained
5. No breaking changes to public API

### Validation Methods
- Test all modifier combinations
- Verify backward compatibility
- Check SettingsStore persistence
- UI hotkey recording still works

## Risk Assessment

### Potential Issues
- **Breaking Changes**: SettingsStore stores UInt32
- **Type Safety**: Raw values vs OptionSet
- **UI Integration**: HotkeyRecorder may need updates

### Mitigation Strategies
- Keep UInt32 storage for backward compatibility
- Add conversion helpers
- Test thoroughly with UI

## Security Considerations

### Input Validation
- Validate modifier flags on creation
- Prevent invalid flag combinations
- Sanitize user input from UI

### Best Practices
- Use type-safe CGEventFlags internally
- Clear documentation of conversion
- Consistent flag handling

## Next Steps

### Dependencies
- Phase 02 must be complete

### Follow-up Tasks
- **Phase 04**: Test and validate implementation
- **Phase 05**: Documentation updates

### Blockers
- None (can proceed after Phase 02)

## Unresolved Questions
- Q: Should we migrate existing SettingsStore data?
- A: No, UInt32 storage is compatible with CGEventFlags raw values

---

**Last Updated**: 2026-02-15
**Phase Status**: Pending
**Next Review**: During implementation
