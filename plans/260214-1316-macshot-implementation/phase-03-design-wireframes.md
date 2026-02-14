---
title: "Phase 03 - Design & Wireframes"
description: "Design system definition, wireframe HTML previews, and logo asset creation"
status: completed
completion_date: 2026-02-14
priority: P1
effort: 4h
branch: main
tags: [design, wireframes, ui-ux]
created: 2026-02-14
---

## Context Links

- [Screenshot APIs Research](../reports/researcher-260214-1310-macos-global-hotkey-research.md)
- [Menu Bar Integration Research](../reports/researcher-260214-1310-macos-menu-bar-integration.md)
- [Canvas Drawing Research](../reports/researcher-260214-1310-swiftui-canvas-drawing.md)
- [Project Overview](../plan.md)

## Overview

**Date**: 2026-02-14
**Priority**: P1 (High)
**Status**: Completed
**Estimated Time**: 4 hours

Define the design system for MacShot, create wireframe HTML previews for all major screens, and generate logo assets. Ensures visual consistency with macOS native patterns and Apple Human Interface Guidelines compliance.

## Key Insights

### macOS Design Patterns
- **Translucency**: Use `.ultraThinMaterial` and `.thickMaterial` for sidebar/overlay panels
- **SF Symbols**: Use system symbols for toolbar icons (camera.crop, pencil.and.outline, arrow.uturn.backward, etc.)
- **Native Controls**: `NSToolbar`, `NSPanel`, `NSPopUpButton` for platform consistency
- **Color Semantics**: System colors (`controlAccentColor`, `separatorColor`) for automatic dark mode support

### Apple HIG Compliance
- **Spacing**: Use 8pt grid system (8, 16, 24, 32, 40)
- **Typography**: SF Pro (system font), `.title`, `.body`, `.caption` styles
- **Touch Targets**: Minimum 44x44pt for interactive elements
- **Visual Hierarchy**: Weight, size, and color to guide attention

### Design System Structure
```
Design System
├── Colors (accent, semantic, adaptive)
├── Typography (hierarchy, weights)
├── Spacing (8pt grid)
├── Components (buttons, cards, dividers)
└── Icons (SF Symbols + custom)
```

## Requirements

### Functional Requirements
1. **Design Guidelines Document**: Complete design system specification in `/docs/design-guidelines.md`
2. **Wireframe HTML Previews**: Interactive HTML files for all major screens
   - Capture mode selector
   - Annotation canvas editor
   - Settings/preferences window
3. **Logo Asset**: App icon in multiple sizes (16x16, 32x32, 128x128, 256x256, 512x512, 1024x1024)

### Non-Functional Requirements
1. **Apple HIG Compliance**: Adhere to macOS 15 design patterns
2. **Accessibility**: WCAG 2.1 AA contrast ratios, VoiceOver support
3. **Dark Mode**: Automatic appearance switching
4. **Responsiveness**: Support window resizing from 800x600 minimum

## Architecture

### Design System Structure
```
macshot/Design/
├── Colors.swift          # Color palette definitions
├── Typography.swift      # Font styles hierarchy
├── Spacing.swift         # 8pt grid constants
└── Components/
    ├── ToolButton.swift  # Reusable toolbar button
    ├── CardView.swift    # Content card container
    └── Divider.swift     # Visual separators
```

### Design Token Mapping
```swift
// Colors
static let accentColor = Color.accentColor
static let surfacePrimary = Color(.windowBackgroundColor)
static let surfaceSecondary = Color(.controlBackgroundColor)

// Spacing (8pt grid)
static let spacing-xs: CGFloat = 8
static let spacing-sm: CGFloat = 16
static let spacing-md: CGFloat = 24
static let spacing-lg: CGFloat = 32

// Typography
extension Font {
    static let largeTitle = Font.largeTitle
    static let title = Font.title
    static let body = Font.body
    static let caption = Font.caption
}
```

## Related Code Files

### Files to Create
- `/docs/design-guidelines.md` - Complete design system documentation
- `/docs/wireframes/capture-mode.html` - Capture selector preview
- `/docs/wireframes/annotation-editor.html` - Canvas editor preview
- `/docs/wireframes/settings-window.html` - Preferences window preview
- `/docs/wireframes/*.png` - Screenshots of wireframes for reference
- `/macshot/Design/Colors.swift` - Color definitions
- `/macshot/Design/Typography.swift` - Font hierarchy
- `/macshot/Design/Spacing.swift` - Layout constants
- `/macshot/Design/Components/ToolButton.swift` - Reusable button

### Files to Delete
- None

### Files to Modify
- None (new design phase)

## Implementation Steps

1. **Research macOS Design Trends**
   - Study Apple HIG for macOS 15
   - Review native screenshot tools (Screenshot.app, Preview)
   - Identify SF Symbols for all UI icons
   - Document native interaction patterns

2. **Define Design System**
   - Color palette: Primary accent, semantic colors, adaptive surfaces
   - Typography hierarchy: Display, heading, body, caption
   - Spacing scale: 8pt grid system (8, 16, 24, 32, 40, 48)
   - Component specifications: Buttons, cards, dividers, badges

3. **Create Wireframe HTML Previews**
   - **Capture Mode**: Floating panel with mode buttons (Fullscreen, Region, Window)
   - **Annotation Editor**: Canvas with toolbar (left), preview (center), options (right)
   - **Settings Window**: Tabbed preferences (General, Hotkeys, Export, Advanced)

4. **Generate Logo Asset**
   - Use AI image generation for logo concept
   - Style: Minimal camera/screenshot icon with macOS aesthetic
   - Variations: Light/dark mode versions
   - Export: Multi-resolution iconset

5. **Capture Wireframe Screenshots**
   - Take screenshots of all HTML previews
   - Save as PNG in `/docs/wireframes/`
   - Annotate key UI decisions

6. **Create Design Guidelines Document**
   - Document color system with hex/RGB values
   - Typography scale with use cases
   - Spacing/spacing tokens
   - Component library with usage examples
   - Accessibility guidelines

## Todo List

- [x] Research macOS design trends and native patterns
- [x] Define color palette (accent, semantic, adaptive)
- [x] Define typography hierarchy (display, heading, body, caption)
- [x] Define spacing scale (8pt grid system)
- [x] Create wireframe HTML for capture mode selector
- [x] Create wireframe HTML for annotation editor
- [x] Create wireframe HTML for settings window
- [x] Generate logo asset with AI image generation
- [x] Capture screenshots of all wireframes
- [x] Write design guidelines document
- [x] Review and validate against Apple HIG

## Success Criteria

- [x] Design guidelines document created in `/docs/design-guidelines.md`
- [x] All wireframe HTML files created and interactive
- [x] Logo asset generated in all required sizes
- [x] Screenshots captured and documented
- [x] Design system validated against Apple HIG
- [x] Accessibility requirements met (WCAG 2.1 AA)

## Risk Assessment

### Potential Issues
- **Design Iterations**: May require multiple rounds to achieve native feel
- **Asset Generation**: AI logo generation may need refinement
- **Browser Rendering**: HTML wireframes may not perfectly match SwiftUI

### Mitigation Strategies
- Use native macOS apps as reference for patterns
- Have backup logo concepts ready
- Document SwiftUI-specific adjustments in guidelines

## Security Considerations

N/A - Design phase has no security implications

## Next Steps

Proceed to **Phase 04 - Annotation Canvas** - Next development phase (pending start).
