# MacShot Concurrency and Resource Management Edge Cases Analysis

## Scope
- Files: CaptureEngineCoordinator.swift, AnnotationEngine.swift, HotkeyManager.swift, EditorViewModel.swift, ExportManager.swift
- Focus: Concurrency and resource management edge cases
- Analysis Date: 2026-02-15

## Edge Case Analysis Results

### 1. Capture interrupted by another capture

**Status:** ⚠️ Partial

**Analysis:**
- ✅ **Handled:** CaptureEngineCoordinator uses `isCapturing` flag and `@MainActor` to prevent concurrent captures
- ⚠️ **Partial:** No explicit cancellation handling for in-progress captures
- ❌ **Missing:** No mechanism to abort ongoing capture when new capture starts

**Current Code:**
```swift
@MainActor
func capture(mode: CaptureMode) async throws -> CaptureResult {
    isCapturing = true
    defer { isCapturing = false }
    // ... capture logic
}
```

**Recommendation:** Add cancellation token to abort ongoing captures.

### 2. Settings modification during capture

**Status:** ❌ Unhandled

**Analysis:**
- ❌ **Missing:** No protection against settings changes during capture
- ❌ **Risk:** SettingsStore values could change mid-capture affecting capture behavior
- ❌ **Impact:** Cursor inclusion, quality settings could be inconsistent

**Current Code:**
```swift
// Settings accessed directly during capture
includeCursor = SettingsStore.includeCursor
// No locking mechanism
```

**Recommendation:** Capture settings at start of capture operation.

### 3. UI update from background thread

**Status:** ✅ Handled

**Analysis:**
- ✅ **Handled:** All UI-related classes are marked with `@MainActor`
- ✅ **Good:** `Task { @MainActor in }` used in hotkey callback
- ✅ **Safe:** Published properties automatically marshal to main thread

**Current Code:**
```swift
@MainActor
final class CaptureEngine: ObservableObject { /* ... */ }

Task { @MainActor in
    hotkey.handler()
}
```

### 4. Actor isolation violations

**Status:** ✅ Handled

**Analysis:**
- ✅ **Good:** All actor-isolated classes properly marked with `@MainActor`
- ✅ **Safe:** No unsafe cross-actor access detected
- ✅ **Compliant:** Proper use of `@MainActor` for UI classes

**Current Code:**
```swift
@MainActor
final class AnnotationEngine: ObservableObject { /* ... */ }

@MainActor
final class ExportManager: ObservableObject { /* ... */ }
```

### 5. Async operation cancelled mid-execution

**Status:** ⚠️ Partial

**Analysis:**
- ✅ **Partial:** Some async operations use `try/await` with error handling
- ⚠️ **Partial:** No explicit Task cancellation support
- ❌ **Missing:** No cleanup on cancellation for ScreenCaptureKit operations

**Current Code:**
```swift
func captureFullscreen() async throws -> CaptureResult {
    try await capture(mode: .fullscreen) // No cancellation handling
}
```

**Recommendation:** Add Task with cancellation support for long-running operations.

### 6. Image exceeds available memory

**Status:** ❌ Unhandled

**Analysis:**
- ❌ **Missing:** No memory limit checks for captured images
- ❌ **Risk:** Large screenshots could cause memory pressure
- ❌ **Missing:** No graceful degradation for large images

**Current Code:**
```swift
// No memory validation before capture
result = try await FullscreenCapture.capture()
```

**Recommendation:** Add memory validation and fallback strategies.

### 7. Annotations array exceeds memory limit

**Status:** ❌ Unhandled

**Analysis:**
- ❌ **Missing:** No size limits on shapes array in AnnotationEngine
- ❌ **Risk:** Thousands of annotations could exhaust memory
- ❌ **Missing:** No pagination or virtualization for large annotation sets

**Current Code:**
```swift
private(set) var shapes: [any Shape] = [] // No size limit
```

**Recommendation:** Implement shape array size limits and cleanup strategies.

### 8. Event tap resource leak (deinit verification)

**Status:** ⚠️ Partial

**Analysis:**
- ✅ **Good:** HotkeyManager has proper `unregister()` call
- ⚠️ **Partial:** `deinit` calls `unregister()` but no verification
- ❌ **Missing:** No confirmation resources were actually released

**Current Code:**
```swift
deinit {
    currentHotkey = nil // Only clears global var, doesn't verify tap cleanup
}
```

**Recommendation:** Add resource verification in deinit or logging.

### 9. File handle leak on export failure

**Status:** ❌ Unhandled

**Analysis:**
- ❌ **Missing:** No explicit file handle management in ExportManager
- ❌ **Risk:** Failed exports could leave file handles open
- ❌ **Missing:** No try/finally pattern for file operations

**Current Code:**
```swift
private func saveFile(_ image: NSImage, to url: URL, options: ExportOptions) async throws {
    // No explicit file handle management
    switch options.format {
    case .png: try exportPNG(image: image, to: url)
    }
}
```

**Recommendation:** Use proper file handle management and error recovery.

### 10. Undo/redo memory exhaustion

**Status:** ⚠️ Partial

**Analysis:**
- ✅ **Partial:** Has `maxUndoLevels = 50` limit
- ⚠️ **Partial:** UndoManager built-in memory management
- ❌ **Missing:** No monitoring of actual memory usage
- ❌ **Missing:** No cleanup for very large undo stacks

**Current Code:**
```swift
private let maxUndoLevels = 50
private var undoManager = UndoManager()
```

**Recommendation:** Add memory monitoring and adaptive undo limits.

## Critical Issues Summary

1. **Memory Management:** No memory limits for images or annotations
2. **Cancellation:** No support for cancelling long-running operations
3. **Resource Cleanup:** Insufficient verification of resource release
4. **Settings Consistency:** No protection against mid-operation settings changes

## Recommendations

1. **Add memory validation** before capture operations
2. **Implement Task cancellation** for async operations
3. **Add resource verification** in deinitializers
4. **Capture settings snapshot** at operation start
5. **Implement shape array limits** with cleanup strategies
6. **Add file handle management** for export operations
7. **Monitor memory usage** for undo/redo operations

## Unresolved Questions

1. Should implement memory pressure monitoring and automatic cleanup?
2. Should add Task cancellation support for all async operations?
3. Should implement resource verification logging for debugging?

## Files Reviewed

- `/Users/huy.nguyenquang/Claude-Projects/macshot/MacShot/Core/CaptureEngine/CaptureEngineCoordinator.swift`
- `/Users/huy.nguyenquang/Claude-Projects/macshot/MacShot/Core/Annotation/AnnotationEngine.swift`
- `/Users/huy.nguyenquang/Claude-Projects/macshot/MacShot/System/HotkeyManager.swift`
- `/Users/huy.nguyenquang/Claude-Projects/macshot/MacShot/Features/Editor/EditorViewModel.swift`
- `/Users/huy.nguyenquang/Claude-Projects/macshot/MacShot/Core/Export/ExportManager.swift`