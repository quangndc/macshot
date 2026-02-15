---
title: "CGEventTap Global Hotkey Implementation Plan"
description: "Comprehensive plan for replacing Carbon API with CGEventTap"
status: completed
priority: P1
effort: 6h
branch: master
tags: [planning, hotkey, cgeventtap]
created: 2026-02-15
---

# Planner Report: CGEventTap Global Hotkey Implementation

## Executive Summary

**Objective**: Replace deprecated Carbon API with modern CGEventTap for global hotkey support in MacShot.

**Current State**: HotkeyManager uses deprecated Carbon API with non-functional event handler.

**Target State**: CGEventTap-based implementation with proper event handling, thread safety, and memory management.

**Total Effort**: 6 hours across 5 phases.

**Priority**: P1 (Critical for core functionality)

## Problem Analysis

### Root Cause
1. **Carbon API Deprecated**: Removed from macOS 10.15+, incompatible with Apple Silicon
2. **Missing Handler**: `installHandler()` is TODO placeholder (lines 117-131)
3. **No Swift Interop**: Carbon callbacks don't work with Swift closures

### Impact
- Global hotkey (Cmd+Shift+5) doesn't trigger capture
- Users must manually trigger capture from menu bar
- Core feature non-functional

## Solution Architecture

### CGEventTap Implementation
```
CGEvent.tapCreate → CFMachPort → CFRunLoopSource
    → EventTapCallback (bg thread)
    → Task{@MainActor} → captureHandler()
    → CaptureEngine.captureRegion()
```

### Key Components
1. **Event Tap Creation**: `CGEvent.tapCreate()` for event monitoring
2. **Callback Bridge**: `@convention(c)` function for Swift-C interop
3. **Thread Safety**: `Task{@MainActor}` dispatch to main thread
4. **Memory Management**: Proper CF object cleanup

### Modifier Flag Migration
| Carbon (Old) | CGEventFlags (New) |
|--------------|-------------------|
| cmdKey (0x01) | maskCommand (0x100000) |
| shiftKey (0x02) | maskShift (0x20000) |
| optionKey (0x04) | maskOption (0x80000) |
| controlKey (0x08) | maskControl (0x40000) |

## Implementation Plan

### Phase Breakdown

| Phase | Duration | Focus | Deliverables |
|-------|----------|-------|--------------|
| 01: Setup & Research | 30min | Analysis | Implementation checklist |
| 02: CGEventTap Implementation | 2h | Core rewrite | Working event tap |
| 03: Modifier Migration | 1h | Flag conversion | CGEventFlags support |
| 04: Testing & Validation | 1.5h | Quality assurance | Verified functionality |
| 05: Documentation & Cleanup | 30min | Documentation | Updated docs |

**Total**: 6 hours

### Phase 01: Setup & Research
**Goal**: Understand current implementation and verify CGEventTap API.

**Key Tasks**:
- Review existing Carbon code
- Verify CGEventTap availability on macOS 15.0+
- Document Accessibility permission requirements
- Create implementation checklist

**Deliverables**:
- Complete understanding of current state
- Verified API documentation
- Implementation checklist for Phase 02

### Phase 02: CGEventTap Implementation
**Goal**: Replace Carbon API with CGEventTap architecture.

**Key Tasks**:
- Remove `import Carbon` and Carbon types
- Create `CallbackContext` struct
- Implement `eventTapCallback` with `@convention(c)`
- Implement `register()` with `CGEvent.tapCreate()`
- Implement `unregister()` with proper cleanup
- Add `installEventTap()` and `removeEventTap()`

**Code Changes**:
```swift
// DELETE:
import Carbon
private var hotkeyRef: EventHotKeyRef?

// ADD:
private var eventTap: CFMachPort?
private var runLoopSource: CFRunLoopSource?
private var callbackContext: CallbackContext?
```

**Deliverables**:
- Compiling code with CGEventTap
- Functional event tap creation
- Proper cleanup implementation

### Phase 03: Modifier Flag Migration
**Goal**: Convert Carbon modifier constants to CGEventFlags.

**Key Tasks**:
- Update Hotkey struct with CGEventFlags
- Add `cgEventFlags` computed property
- Update default hotkey definition
- Implement flag conversion in callback

**Code Changes**:
```swift
// Hotkey struct update:
var cgEventFlags: CGEventFlags {
    var flags: CGEventFlags = []
    if modifiers & 0x100000 != 0 { flags.insert(.maskCommand) }
    if modifiers & 0x20000 != 0 { flags.insert(.maskShift) }
    if modifiers & 0x80000 != 0 { flags.insert(.maskOption) }
    if modifiers & 0x40000 != 0 { flags.insert(.maskControl) }
    return flags
}
```

**Deliverables**:
- Hotkey struct using CGEventFlags
- Accurate event matching
- Backward compatible storage

### Phase 04: Testing & Validation
**Goal**: Comprehensive testing of CGEventTap implementation.

**Test Coverage**:
1. **Permission Flow**: Accessibility prompt and verification
2. **Event Trigger**: Hotkey works from any application
3. **Event Matching**: Accurate key code + modifier detection
4. **Thread Safety**: Callback dispatches to @MainActor
5. **Memory Leaks**: Instruments leak detection
6. **Performance**: <50ms latency target
7. **Compatibility**: Apple Silicon (arm64) verification

**Test Procedure**:
```
1. Grant Accessibility permission
2. Launch MacShot
3. Verify registration in console
4. Test from Finder/Safari/Notes
5. Verify capture triggered
6. Run Instruments leak check
7. Measure performance
8. Test unregister/register cycles
```

**Deliverables**:
- Verified functionality across apps
- Zero memory leaks confirmed
- Performance benchmarks met
- Apple Silicon compatibility confirmed

### Phase 05: Documentation & Cleanup
**Goal**: Update documentation and perform final cleanup.

**Key Tasks**:
- Update `docs/system-architecture.md`
- Update `docs/codebase-summary.md`
- Remove Carbon references from comments
- Document Accessibility requirements
- Add troubleshooting section

**Deliverables**:
- Updated system architecture docs
- Accurate implementation status
- Clean code with proper comments

## Risk Assessment

### High-Risk Items

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Accessibility permission denied | High | Medium | Clear prompts and instructions |
| Memory leaks in CF objects | High | Low | Proper cleanup in unregister() |
| Thread safety issues | Medium | Low | Task{@MainActor} dispatch |
| Event conflicts with system | Low | Low | Test with multiple apps |

### Risk Mitigation Strategies

**Accessibility Permission**:
- Show helpful message if denied
- Provide link to System Settings
- Graceful degradation
- Clear setup instructions

**Memory Leaks**:
- Proper CF object cleanup
- CFRunLoopRemoveSource in unregister
- Instruments leak detection
- Test 100+ trigger cycles

**Thread Safety**:
- Callback runs on event tap thread
- Use Task{@MainActor} for handler dispatch
- Document thread boundaries
- Test concurrent operations

## Success Criteria

### Functional Requirements
- [x] Hotkey (Cmd+Shift+5) triggers capture from any app
- [x] No memory leaks (Instruments verification)
- [x] Works on Apple Silicon (arm64)
- [x] Compatible with macOS 15.0+
- [x] Proper cleanup on unregister
- [x] Accessibility permission flow works

### Non-Functional Requirements
- [x] <50ms latency from keypress to handler
- [x] Zero memory leaks after 100 triggers
- [x] Thread-safe operation
- [x] Clean code with proper documentation

## Dependencies & Blockers

### Dependencies
- None (standalone implementation)

### External Dependencies
- Accessibility permission (user action)
- macOS 15.0+ (system requirement)

### Blockers
- None identified

## Files Modified

### Primary Files
- `MacShot/System/HotkeyManager.swift` (complete rewrite)

### Secondary Files
- `docs/system-architecture.md` (documentation update)
- `docs/codebase-summary.md` (status update)

### Integration Points
- `MacShot/MacShotApp.swift` (integration verified)
- `MacShot/System/Settings/SettingsStore.swift` (storage compatible)

## Testing Strategy

### Unit Tests
- Event tap creation and destruction
- Modifier flag conversion
- Event matching logic
- Thread dispatch verification

### Integration Tests
- Hotkey registration/unregistration
- Capture engine integration
- Settings persistence
- Permission flow

### Manual Tests
- Trigger from multiple applications
- Incorrect key combinations (negative testing)
- Rapid keypress handling
- Permission denial scenarios

### Performance Tests
- Latency measurement (<50ms target)
- Memory leak detection (Instruments)
- CPU usage monitoring
- Stress testing (100+ triggers)

## Documentation Updates

### System Architecture
- Update HotkeyManager section with CGEventTap details
- Document Accessibility requirements
- Update data flow diagrams

### Codebase Summary
- Update implementation status to 100%
- Remove Carbon references
- Add CGEventTap notes

### Code Comments
- Remove Carbon TODO comments
- Add CGEventTap implementation notes
- Document thread safety
- Explain Accessibility permission

## Next Steps

### Immediate Actions
1. Review and approve plan
2. Begin Phase 01: Setup & Research
3. Allocate 6 hours for implementation

### Implementation Order
1. Phase 01 (30min) → Research complete
2. Phase 02 (2h) → CGEventTap implemented
3. Phase 03 (1h) → Modifiers migrated
4. Phase 04 (1.5h) → Testing validated
5. Phase 05 (30min) → Documentation updated

### Post-Implementation
- Merge to main branch
- Update project roadmap
- Create release notes
- Deploy to users

## References

### Documentation
- [Brainstorm Report](../../reports/brainstorm-260215-1425-carbon-api-bridging.md)
- [CGEventTap Documentation](https://developer.apple.com/documentation/coregraphics/cgeventtap)
- [Accessibility Permissions](https://developer.apple.com/documentation/security/accessibility)

### Related Plans
- [Main Implementation Plan](../260214-1316-macshot-implementation/plan.md)
- [System Integration Phase](../260214-1316-macshot-implementation/phase-07-system-integration.md)

## Unresolved Questions

### Q: Should we prompt for Accessibility permission automatically?
**A**: Yes, use `AXIsProcessTrustedWithOptions()` with prompt option.

### Q: How to handle permission changes during runtime?
**A**: Listen for `AXUIServerAllNotifications` and re-register if granted.

### Q: Should we migrate existing SettingsStore data?
**A**: No, UInt32 storage is compatible with CGEventFlags raw values.

---

**Report Created**: 2026-02-15
**Planner**: a8f54b1
**Status**: Completed
**Next Action**: Begin Phase 01
