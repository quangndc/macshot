---
title: "MacShot - Native macOS Screenshot Tool Implementation Plan"
description: "Complete implementation plan for WinShot parity on macOS 15+"
status: in-progress
priority: P1
effort: 44h
branch: main
tags: [swiftui, screenshot, macos, annotation]
created: 2026-02-14
---

## Overview

Native macOS screenshot tool achieving full feature parity with WinShot (Windows). Built with Swift/SwiftUI targeting macOS 15+ (Sequoia).

## Phase Status

| Phase | Status | Progress |
|-------|--------|----------|
| [01 - Project Setup](./phase-01-project-setup.md) | completed | 100% |
| [02 - Capture Engine](./phase-02-capture-engine.md) | pending | 0% |
| [03 - Design & Wireframes](./phase-03-design-wireframes.md) | pending | 0% |
| [04 - Annotation Canvas](./phase-04-annotation-canvas.md) | pending | 0% |
| [05 - Editor UI](./phase-05-editor-ui.md) | pending | 0% |
| [06 - Export System](./phase-06-export-system.md) | pending | 0% |
| [07 - System Integration](./phase-07-system-integration.md) | pending | 0% |
| [08 - Settings Persistence](./phase-08-settings-persistence.md) | pending | 0% |
| [09 - Testing & Polish](./phase-09-testing-polish.md) | pending | 0% |

## Tech Stack

- **Framework**: Swift/SwiftUI
- **Target**: macOS 15+ (Sequoia)
- **UI/UX**: Native macOS Design (SF Symbols, translucency, native controls)
- **Design System**: 8pt grid, SF Pro typography, adaptive colors
- **Architecture**: MVVM with Combine
- **Dependencies**: Minimal (Swift standard library + Apple frameworks)

## Key Features

1. **Capture Modes**: Fullscreen, Region (drag selection), Window (auto-detect)
2. **Annotation Tools**: Rectangle, Ellipse, Arrow, Line, Text, Number, Spotlight
3. **Editor Features**: Non-destructive cropping, aspect ratio presets, gradient backgrounds
4. **Export**: PNG/JPEG with quality control, output ratios, quick save folder
5. **System Integration**: Menu bar icon, global hotkeys (Cmd+Shift+5), auto-start
6. **Settings**: Hotkey customization, export preferences, editor persistence

## Research Dependencies

- [Screenshot APIs](../../researcher-260214-1310-screenshot-apis.md)
- [Global Hotkey Research](../reports/researcher-260214-1310-macos-global-hotkey-research.md)
- [Menu Bar Integration](../reports/researcher-260214-1310-macos-menu-bar-integration.md)
- [Canvas Drawing](../reports/researcher-260214-1310-swiftui-canvas-drawing.md)

## Architecture Overview

```
MacShot.app
├── App/
│   ├── MacShotApp.swift           # App entry point
│   └── AppDelegate.swift           # Lifecycle management
├── Core/
│   ├── CaptureEngine.swift         # CGWindowList capture
│   ├── AnnotationCanvas.swift     # SwiftUI Canvas drawing
│   ├── ExportManager.swift        # PNG/JPEG export
│   └── HotkeyManager.swift        # Global hotkey registration
├── Features/
│   ├── Capture/
│   │   ├── FullscreenCapture.swift
│   │   ├── RegionCapture.swift
│   │   └── WindowCapture.swift
│   ├── Annotation/
│   │   ├── Shapes/
│   │   └── Tools/
│   └── Editor/
│       ├── EditorWindow.swift
│       └── CropOverlay.swift
├── UI/
│   ├── Views/
│   ├── Components/
│   └── Themes/
├── System/
│   ├── MenuBarManager.swift
│   ├── SettingsStore.swift
│   └── NotificationManager.swift
└── Resources/
    ├── Assets.xcassets
    └── Entitlements.plist
```

## Implementation Order

1. **Project Setup** → Foundation for all development
2. **Capture Engine** → Core screenshot functionality
3. **Design & Wireframes** → Design system definition and UI mockups
4. **Annotation Canvas** → Drawing capability (depends on capture, design)
5. **Editor UI** → User interface (depends on canvas, design)
6. **Export System** → Save functionality (depends on editor)
7. **System Integration** → Menu bar, hotkeys (parallel with 4-5)
8. **Settings Persistence** → User preferences
9. **Testing & Polish** → QA and refinement

## Success Criteria

- [ ] All capture modes working (fullscreen, region, window)
- [ ] All annotation tools functional
- [ ] Export to PNG/JPEG with quality settings
- [ ] Menu bar integration with global hotkeys
- [ ] Settings persistence across sessions
- [ ] Unit test coverage > 60%
- [ ] UI/UX matches native macOS patterns

## Unresolved Questions

1. Should we support Screen Recording Kit for video capture (future)?
2. What OCR capabilities for text recognition in screenshots?
3. Cloud sync for settings across devices?
