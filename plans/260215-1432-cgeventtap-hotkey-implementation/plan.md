---
title: "CGEventTap Global Hotkey Implementation"
description: "Replace deprecated Carbon API with CGEventTap for global hotkey support"
status: completed
priority: P1
effort: 6h
branch: master
tags: [hotkey, cgeventtap, carbon-api, system-integration]
created: 2026-02-15
---

# CGEventTap Global Hotkey Implementation

## Overview
Complete replacement of deprecated Carbon API with modern CGEventTap architecture for global hotkey support in MacShot.

## Status
- **Current**: CGEventTap implementation complete and fully functional
- **Target**: All phases completed successfully
- **Priority**: P1 (Critical for core functionality) - COMPLETED

## Phases

### Phase 01: Setup & Research (30min)
[Status: ✅ Complete](./phase-01-setup-research.md)
- Review existing Carbon implementation
- Verify CGEventTap API availability
- Create implementation checklist

### Phase 02: CGEventTap Implementation (2h)
[Status: ✅ Complete](./phase-02-cgeventtap-implementation.md)
- Replace Carbon API with CGEventTap
- Implement event tap callback
- Set up CFRunLoop integration
- Thread safety with @MainActor

### Phase 03: Modifier Flag Migration (1h)
[Status: ✅ Complete](./phase-03-modifier-migration.md)
- Convert Carbon modifier constants
- Update Hotkey struct
- Ensure bit flag compatibility

### Phase 04: Testing & Validation (1.5h)
[Status: ✅ Complete](./phase-04-testing-validation.md)
- Accessibility permission testing
- Global hotkey trigger testing
- Memory leak detection
- Apple Silicon compatibility

### Phase 05: Documentation & Cleanup (30min)
[Status: ✅ Complete](./phase-05-documentation-cleanup.md)
- Update code comments
- Update system architecture docs
- Remove Carbon imports
- Final cleanup

## Dependencies
- None (standalone implementation)

## Success Criteria ✅ ALL MET
1. ✅ Hotkey (Cmd+Shift+5) triggers screen capture from any application
2. ✅ No memory leaks (Instruments leak detector)
3. ✅ Works on Apple Silicon (arm64)
4. ✅ Compatible with macOS 15.0+
5. ✅ Proper cleanup when hotkey unregistered
6. ✅ Accessibility permission prompt shown if not granted

## Key Risks
- **Accessibility Permission**: User must grant manually (mitigation: clear instructions)
- **Memory Leaks**: CF objects need proper cleanup (mitigation: deinit handling)
- **Thread Safety**: Callback runs on event tap thread (mitigation: MainActor dispatch)

## Related Files
- **Primary**: `MacShot/System/HotkeyManager.swift`
- **Secondary**: `MacShot/MacShotApp.swift` (integration)
- **Docs**: `docs/system-architecture.md`

## References
- [Brainstorm Report](../reports/brainstorm-260215-1425-carbon-api-bridging.md)
- [CGEventTap Documentation](https://developer.apple.com/documentation/coregraphics/cgeventtap)
- [Accessibility Permissions](https://developer.apple.com/documentation/security/accessibility)
