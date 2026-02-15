---
title: "Phase 01: Setup & Research"
description: "Review existing code and verify CGEventTap implementation approach"
status: pending
priority: P1
effort: 30min
branch: master
tags: [setup, research, planning]
created: 2026-02-15
---

# Phase 01: Setup & Research

## Context Links
- [Main Plan](./plan.md)
- [Brainstorm Report](../../reports/brainstorm-260215-1425-carbon-api-bridging.md)
- [Current HotkeyManager](../../MacShot/System/HotkeyManager.swift)

## Overview
**Priority**: P1 (Critical prerequisite)
**Status**: Pending
**Effort**: 30 minutes

Review existing Carbon implementation and verify CGEventTap API availability for modern macOS.

## Key Insights

### Current State Analysis
1. **Carbon API Status**: Deprecated, 32-bit only, removed from macOS 10.15+
2. **Handler Gap**: `installHandler()` is TODO placeholder (lines 117-131)
3. **Registration Works**: `RegisterEventHotKey()` succeeds, but events never fire
4. **Apple Silicon**: Carbon incompatible with arm64 architecture

### CGEventTap Advantages
1. **Native Support**: Fully supported on macOS 15.0+
2. **Apple Silicon**: Compatible with arm64
3. **Swift Interop**: Works with Swift closures via @convention(c)
4. **No Dependencies**: Part of CoreGraphics framework

## Requirements

### Functional Requirements
- [ ] Verify CGEventTap API availability on macOS 15.0+
- [ ] Confirm Accessibility permission requirements
- [ ] Validate CFRunLoop integration pattern
- [ ] Review thread safety requirements

### Non-Functional Requirements
- [ ] Zero external dependencies
- [ ] Memory-safe implementation
- [ ] Proper cleanup and deinitialization

## Architecture

### System Design
```
Current (Carbon):
RegisterEventHotKey → [NO HANDLER] → ❌ No events

Target (CGEventTap):
CGEvent.tapCreate → CFRunLoopSource → EventTapCallback → @MainActor → ✅ Capture
```

### Component Interaction
```
CGEventTapProxy → Callback → UnsafePointer → Task{@MainActor} → CaptureEngine
```

## Related Code Files

### Files to Read
- `MacShot/System/HotkeyManager.swift` (current implementation)
- `MacShot/MacShotApp.swift` (integration pattern)
- `MacShot/System/Settings/SettingsStore.swift` (hotkey storage)

### Files to Modify
- `MacShot/System/HotkeyManager.swift` (complete rewrite)

### Files to Delete
- None (keep for reference during implementation)

## Implementation Steps

1. **Review Current Implementation** (10min)
   - Read existing HotkeyManager.swift
   - Identify Carbon-specific code paths
   - Note working vs non-working sections
   - Document integration points

2. **Verify CGEventTap API** (10min)
   - Check macOS 15.0+ availability
   - Confirm parameter requirements
   - Validate callback signature
   - Test CFRunLoop integration

3. **Create Implementation Checklist** (10min)
   - List all code changes needed
   - Identify potential issues
   - Document testing requirements
   - Prepare migration plan

## Todo List

- [ ] Read and analyze HotkeyManager.swift
- [ ] Document Carbon API dependencies
- [ ] Verify CGEventTap API documentation
- [ ] Test Accessibility permission flow
- [ ] Create phase 02 implementation checklist
- [ ] Identify potential memory leak points
- [ ] Document thread safety requirements

## Success Criteria

### Definition of Done
1. Complete understanding of existing implementation
2. Verified CGEventTap API availability
3. Documented implementation approach
4. Created checklist for phase 02

### Validation Methods
- Code review complete
- API documentation verified
- Test plan documented
- No open questions about approach

## Risk Assessment

### Potential Issues
- **Accessibility Permission**: User must grant manually
- **CF Object Management**: Manual memory management required
- **Callback Threading**: Runs on event tap thread, not main

### Mitigation Strategies
- Clear setup instructions for permissions
- Proper cleanup in deinit/unregister
- Task{@MainActor} dispatch for handler

## Security Considerations

### Privacy & Access
- **Accessibility Permission**: Required for global event monitoring
- **No Data Collection**: Events processed locally only
- **User Control**: Hotkey configurable in settings

### Best Practices
- Prompt for permission if denied
- Clear error messages
- Graceful degradation if unavailable

## Next Steps

### Dependencies
- None (can proceed immediately)

### Follow-up Tasks
- **Phase 02**: Implement CGEventTap architecture
- **Phase 03**: Migrate modifier flags
- **Phase 04**: Test and validate

### Blockers
- None identified

## Unresolved Questions
- None (research phase will answer all)

---

**Last Updated**: 2026-02-15
**Phase Status**: Pending
**Next Review**: After completion
