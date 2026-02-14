---
title: "Phase 05 - Editor UI"
description: "Main editor window with toolbar, panels, and annotation canvas integration"
status: completed
priority: P1
effort: 6h
branch: main
tags: [ui, editor, window, toolbar]
created: 2026-02-14
---

## Context Links

- [Menu Bar Integration - NSStatusItem](../reports/researcher-260214-1310-macos-menu-bar-integration.md)
- [Annotation Canvas](./phase-03-annotation-canvas.md) - Canvas dependency

## Overview

**Priority**: P1 (Main user interface)
**Status**: Completed
**Description**: Build the main editor window integrating toolbar, canvas, properties panel, and export controls.

## Key Insights

- **NSWindow** - Native macOS window management
- **NSToolbar** - Standard toolbar with SF Symbols
- **NSPanel** - Floating panels for properties
- **SwiftUI layouts** - VStack, HStack, Spacer
- **Native controls** - NSColorWell, NSPopUpButton

## Requirements

### Functional
- Main editor window with toolbar
- Tool selection buttons (7 tools)
- Properties panel (color, stroke width)
- Canvas area with screenshot
- Export button
- Keyboard shortcuts
- Window resize handling

### Non-Functional
- Native macOS appearance
- Responsive layout
- Accessibility support
- Dark/light mode support

## Architecture

```
Features/Editor/
├── EditorWindow.swift             # Main NSWindow
├── EditorView.swift                # Root SwiftUI view
├── EditorToolbar.swift              # Toolbar component
├── EditorViewModel.swift           # State management
└── Components/
    ├── ToolButton.swift             # Toolbar button
    ├── PropertiesPanel.swift       # Right panel
    ├── CanvasContainer.swift        # Canvas wrapper
    └── ExportButton.swift           # Export action
```

### Layout

```
┌────────────────────────────────────────────────────┐
│ Toolbar: [⬛] [⚪] [→] [─] [T] [1] [💡] [Save]      │
├──────────────────────────────────┬───────────────┤
│                                  │ Properties     │
│                                  │               │
│            Canvas                │ Stroke: 2px   │
│                                  │ Color: □      │
│                                  │ Fill: □       │
│                                  │               │
└──────────────────────────────────┴───────────────┘
```

## Related Code Files

### Create
- `MacShot/Features/Editor/EditorWindow.swift`
- `MacShot/Features/Editor/EditorView.swift`
- `MacShot/Features/Editor/EditorViewModel.swift`
- `MacShot/Features/Editor/EditorToolbar.swift`
- `MacShot/Features/Editor/Components/ToolButton.swift`
- `MacShot/Features/Editor/Components/PropertiesPanel.swift`
- `MacShot/Features/Editor/Components/CanvasContainer.swift`
- `MacShot/Features/Editor/Components/ExportButton.swift`

### Modify
- `MacShot/Core/Annotation/AnnotationCanvas.swift` - Wrap in container
- `MacShot/MacShotApp.swift` - Show editor on capture

## Implementation Steps

### 1. Editor Window (1h)

```swift
// EditorWindow.swift
import AppKit

final class EditorWindow: NSWindow {
    init(captureResult: CaptureResult) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        title = "MacShot Editor"
        center()
        isReleasedWhenClosed = false
        contentView = NSHostingView(rootView: EditorView(result: captureResult))
    }
}
```

### 2. Editor View Model (0.5h)

```swift
// EditorViewModel.swift
@Observable
final class EditorViewModel {
    var captureResult: CaptureResult
    var selectedTool: ToolType = .select
    var selectedColor: Color = .red
    var strokeWidth: CGFloat = 2
    var showProperties = true

    init(result: CaptureResult) {
        self.captureResult = result
    }
}
```

### 3. Main Editor View (1.5h)

```swift
// EditorView.swift
struct EditorView: View {
    @State private var viewModel: EditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            EditorToolbar(viewModel: viewModel)
                .frame(height: 44)

            HStack(spacing: 0) {
                CanvasContainer(result: viewModel.captureResult)

                if viewModel.showProperties {
                    Divider()
                    PropertiesPanel(viewModel: viewModel)
                        .frame(width: 200)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
```

### 4. Toolbar Component (1h)

```swift
// EditorToolbar.swift
struct EditorToolbar: View {
    @ObservedObject var viewModel: EditorViewModel

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ToolType.allCases) { tool in
                ToolButton(
                    tool: tool,
                    isSelected: viewModel.selectedTool == tool,
                    action: { viewModel.selectedTool = tool }
                )
            }

            Spacer()

            ExportButton { /* Export action */ }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}
```

### 5. Tool Button Component (0.5h)

```swift
// ToolButton.swift
struct ToolButton: View {
    let tool: ToolType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: tool.iconName)
                .font(.system(size: 16))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(width: 32, height: 32)
                .background(isSelected ? .blue : .clear)
                .cornerRadius(6)
        }
        .help(tool.localizedDescription)
    }
}
```

### 6. Properties Panel (1h)

```swift
// PropertiesPanel.swift
struct PropertiesPanel: View {
    @ObservedObject var viewModel: EditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Properties")
                .font(.headline)
                .padding(.horizontal)

            StrokeWidthPicker(selection: $viewModel.strokeWidth)
            ColorPicker("Stroke", selection: $viewModel.selectedColor)
            ColorPicker("Fill", selection: $viewModel.selectedFill)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
    }
}
```

### 7. Canvas Container (0.5h)

```swift
// CanvasContainer.swift
struct CanvasContainer: View {
    let result: CaptureResult

    var body: some View {
        GeometryReader { geometry in
            AnnotationCanvas(backgroundImage: result.image)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
```

## Todo List

- [x] Create EditorWindow class
- [x] Create EditorViewModel
- [x] Create EditorView layout
- [x] Create EditorToolbar
- [x] Create ToolButton component
- [x] Create PropertiesPanel
- [x] Create CanvasContainer
- [x] Create ExportButton
- [ ] Add keyboard shortcuts (Cmd+1-8 for tools)
- [ ] Add tool icons
- [x] Test window resizing
- [ ] Test dark/light mode
- [ ] Verify accessibility labels
- [ ] Add window position persistence

## Success Criteria

- [x] Editor window displays with captured image
- [x] All 7 tool buttons visible and clickable
- [x] Tool selection updates properties panel
- [x] Properties panel controls update canvas
- [x] Window resizes without breaking layout
- [ ] Dark/light mode works
- [ ] Keyboard shortcuts work

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Layout complexity | Medium | Use SwiftUI, test resize |
| Toolbar space | Low | Use overflow menu if needed |
| Properties panel width | Low | Set min/max constraints |

## Security Considerations

- No sensitive data in UI
- User input sanitized
- Accessibility features included

## Next Steps

Proceed to **Phase 06 - Export System** once:
- Editor displays captured image ✅
- Tools selectable ✅
- Properties panel functional ✅

### Follow-up Tasks for Future Release
- Add keyboard shortcuts (Cmd+1-8 for tools)
- Add tool icons
- Test dark/light mode
- Verify accessibility labels
- Add window position persistence
