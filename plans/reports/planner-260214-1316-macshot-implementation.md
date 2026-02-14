---
title: "MacShot Implementation Plan - Planner Report"
description: "Comprehensive implementation plan for native macOS screenshot tool"
status: completed
priority: P1
effort: 40h
branch: main
tags: [swiftui, screenshot, macos, implementation-plan]
created: 2026-02-14
---

## Executive Summary

Created comprehensive 8-phase implementation plan for MacShot - a native macOS screenshot tool achieving full feature parity with WinShot.

**Plan Location**: `/Users/huy.nguyenquang/Claude-Projects/macshot/plans/260214-1316-macshot-implementation/`

**Total Estimated Effort**: 40 hours

## Phase Breakdown

| Phase | Effort | Priority | Dependencies |
|-------|--------|----------|--------------|
| 01 - Project Setup | 2h | P1 | None |
| 02 - Capture Engine | 8h | P1 | Phase 01 |
| 03 - Annotation Canvas | 10h | P1 | Phase 01 |
| 04 - Editor UI | 6h | P1 | Phases 02, 03 |
| 05 - Export System | 5h | P1 | Phases 02, 03 |
| 06 - System Integration | 4h | P1 | Phases 02, 04 |
| 07 - Settings Persistence | 3h | P2 | All previous |
| 08 - Testing & Polish | 6h | P2 | All previous |

## Tech Stack

- **Framework**: Swift/SwiftUI
- **Target**: macOS 15.0+ (Sequoia)
- **Language**: Swift 6.0
- **Architecture**: MVVM with Combine
- **Dependencies**: Minimal (Apple frameworks only)

## Key Features

1. **Capture Modes**
   - Fullscreen (all displays)
   - Region (drag selection)
   - Window (auto-detect)

2. **Annotation Tools**
   - Rectangle, Ellipse, Arrow, Line
   - Text with font/color
   - Number badges
   - Spotlight/blur effect

3. **Editor Features**
   - Non-destructive cropping
   - Aspect ratio presets (16:9, 4:3, 1:1)
   - Transform operations (move, resize, rotate)
   - Undo/redo support

4. **Export**
   - PNG (lossless)
   - JPEG (quality slider)
   - Copy to clipboard
   - Quick save folder

5. **System Integration**
   - Menu bar icon (SF Symbols)
   - Global hotkeys (Cmd+Shift+5/6/7)
   - Launch at login
   - Export notifications

6. **Settings**
   - Hotkey customization
   - Export preferences
   - Editor state persistence
   - UserDefaults backed

## Architecture Overview

```
MacShot/
├── App/
│   ├── MacShotApp.swift
│   └── AppDelegate.swift
├── Core/
│   ├── CaptureEngine/
│   ├── Annotation/
│   └── Export/
├── Features/
│   ├── Capture/
│   ├── Annotation/
│   └── Editor/
├── UI/
│   ├── Views/
│   └── Components/
├── System/
│   ├── MenuBarManager.swift
│   ├── HotkeyManager.swift
│   ├── NotificationManager.swift
│   └── Settings/
└── Resources/
    └── Assets.xcassets
```

## Research Integration

Plan incorporates findings from 4 research reports:

1. **Screenshot APIs** - CGWindowList, CGDisplayStream, multi-display, Retina
2. **Global Hotkey** - Carbon API, modifier keys, permissions
3. **Menu Bar Integration** - NSStatusItem, SF Symbols, SMAppService
4. **Canvas Drawing** - SwiftUI Canvas, Core Graphics, UndoManager

## Implementation Order

**Sequential** (Phases 1-6):
1. Setup → 2. Capture → 3. Canvas → 4. Editor → 5. Export → 6. Integration

**Polish** (Phases 7-8):
7. Settings → 8. Testing

## Success Criteria

- [ ] All capture modes working
- [ ] All annotation tools functional
- [ ] Export to PNG/JPEG
- [ ] Menu bar + hotkeys
- [ ] Settings persistence
- [ ] Unit test coverage > 60%
- [ ] UI/UX matches native macOS

## Critical Path

```
Setup → Capture ┬→ Editor → Integration → Complete
                └→ Canvas ↗
                      └→ Export ────────────────┘
```

**Parallel Opportunities**:
- Phase 04 (Editor UI) can start once Phase 02 completes
- Phase 05 (Export) can start once Phase 03 completes
- Phase 06 (Integration) can run parallel to 04-05

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|--------------|------------|
| Carbon API deprecation | High | Medium | Research CGEventTap alternative |
| Permission denial | High | Low | Graceful fallback, clear UX |
| Multi-display coords | Medium | Medium | Thorough testing |
| Performance on Retina | Medium | Low | Async processing |
| App Store rejection | High | Low | Follow HIG, test on hardware |

## Security Requirements

- Screen Recording permission
- Accessibility permission (hotkeys)
- Automation permission (login items)
- App Sandbox enabled
- Minimal entitlements

## Next Steps

1. **Begin Phase 01** - Project Setup
2. **Create GitHub repository**
3. **Setup CI/CD** (optional)
4. **Start Implementation**

## Plan Files Created

- `plan.md` - Overview access point
- `phase-01-project-setup.md` - Xcode setup, entitlements
- `phase-02-capture-engine.md` - CGWindowList capture
- `phase-03-annotation-canvas.md` - SwiftUI Canvas drawing
- `phase-04-editor-ui.md` - Main editor window
- `phase-05-export-system.md` - PNG/JPEG export, cropping
- `phase-06-system-integration.md` - Menu bar, hotkeys, login
- `phase-07-settings-persistence.md` - UserDefaults, preferences UI
- `phase-08-testing-polish.md` - Tests, bugs, documentation

## Unresolved Questions

1. Should we explore CGEventTap as Carbon alternative for hotkeys?
2. Cloud sync for settings across devices?
3. Video capture for future versions?
4. OCR for text in screenshots?

---

**Status**: Plan complete. Ready for implementation.
