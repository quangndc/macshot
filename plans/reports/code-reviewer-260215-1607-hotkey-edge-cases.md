# MacShot Hotkey System Edge Case Analysis

**Date:** 2026-02-15
**Work Context:** /Users/huy.nguyenquang/Claude-Projects/macshot
**Reports:** /Users/huy.nguyenquang/Claude-Projects/macshot/plans/reports/

## Edge Cases Analysis

### 1. Accessibility Permission Denied

**✅ Handled:**
- `HotkeyManager.swift` (lines 54-60): Checks `AXIsProcessTrusted()` before registering
- Prompts user with `AXTrustedCheckOptionPrompt` to grant permission
- Returns `false` if permission denied, preventing event tap creation
- User-friendly error message printed to console

**❌ Unhandled:**
- No persistent permission state tracking (keeps prompting every time)
- No fallback behavior when permission is permanently denied
- No visual feedback in UI showing permission status

**⚠️ Partial:**
- No retry mechanism for permission denial scenarios
- Missing permission status display in settings UI

### 2. Event Tap Registration Failure

**✅ Handled:**
- `HotkeyManager.swift` (lines 76-87): Checks `CGEvent.tapCreate` success
- Returns `false` if tap creation fails
- Cleans up global state on failure
- Provides console error message

**❌ Unhandled:**
- No retry mechanism for temporary failures (e.g., system busy)
- No specific error handling for different failure types
- No fallback to alternative hotkey methods if CGEventTap fails
- No logging of failure reasons for debugging

**⚠️ Partial:**
- Error message is generic ("Failed to create event tap") without specific cause
- No attempt to re-register after failure

### 3. Multiple Simultaneous Hotkey Presses

**✅ Handled:**
- Event tap callback is designed to handle rapid key presses
- Only processes `keyDown` events, filtering out others
- Events are consumed (return nil) when hotkey matches
- Global state management prevents race conditions with `@MainActor`

**❌ Unhandled:**
- No protection against rapid successive triggers (could cause multiple captures)
- No cooldown period between hotkey activations
- No handling of "held down" key scenarios (auto-repeat)

**⚠️ Partial:**
- Could benefit from a debouncing mechanism for rapid key presses
- No rate limiting to prevent accidental repeated captures

### 4. Hotkey Conflicts with System Shortcuts

**✅ Handled:**
- Event tap uses `.headInsertEventTap` position to intercept before system handlers
- Consumes events (return nil) when hotkey matches
- Only processes exact key+modifier combinations

**❌ Unhandled:**
- No mechanism to detect if hotkey conflicts with system shortcuts
- No conflict detection between multiple app hotkeys
- No warning to user about potential conflicts
- No fallback to alternative key combinations

**⚠️ Partial:**
- User has no way to check if their chosen hotkey conflicts
- Settings UI doesn't validate hotkey against common system shortcuts
- No validation against other MacShot hotkeys (different types)

### 5. Hotkey Recording Cancellation Mid-Recording

**✅ Handled:**
- `HotkeyRecorder.swift` (lines 32-39): Shows "Press keys..." state
- `onDisappear` callback calls `stopRecording()` (line 36)
- Event monitor cleanup in `stopRecording()` (lines 73-76)
- No hotkey update if recording cancelled mid-process

**❌ Unhandled:**
- No explicit cancellation mechanism (like pressing Escape)
- No timeout for recording (user could be left recording indefinitely)
- No visual indicator of recording timeout
- No cleanup if view disappears while recording

**⚠️ Partial:**
- No timeout for recording session
- No keyboard shortcut to cancel recording
- Could benefit from a recording timeout mechanism

### 6. Event Tap Disconnection Mid-Operation

**✅ Handled:**
- `HotkeyManager.swift` (lines 107-126): Proper cleanup in `unregister()`
- Event tap is disabled before removal from run loop
- Global state cleared when tap is disconnected
- Uses `@MainActor` for thread safety

**❌ Unhandled:**
- No automatic reconnection if tap is disconnected
- No detection of tap disconnection during operation
- No retry mechanism for temporary disconnections
- No logging of disconnection events

**⚠️ Partial:**
- No periodic health check to verify tap is still active
- No automatic re-registration on app focus/switching
- Missing event tap status monitoring

## Additional Issues Found

### Duplicate File Issue
- **File:** `HotkeyManager.swift.swift` exists alongside `HotkeyManager.swift`
- Both files contain identical functionality but different implementations
- **Note:** The duplicate uses a `ContextBox` class for global state, while original uses global variable

### Hotkey Management Issues
- **Missing:** No `registerFromSettings()` usage found in actual code
- **Gap:** Settings store defines three hotkeys but only one (fullscreen) is actually registered
- **Impact:** Region and Window hotkeys exist but don't function

### Error Handling Gaps
- **Missing:** No comprehensive error handling in `handleHotkeyPress()`
- **Issue:** `try?` in `handleHotkeyPress()` silently fails (line 125)
- **Impact:** User gets no feedback if capture fails due to hotkey error

### UI Integration Issues
- **Missing:** Permission status not shown in settings
- **Missing:** Hotkey conflict warnings
- **Missing:** Recording status feedback beyond "Press keys..."

## Recommendations

1. **Implement hotkey conflict detection**
2. **Add permission status tracking and display**
3. **Implement automatic reconnection for event taps**
4. **Add recording timeout and cancellation**
5. **Fix duplicate hotkey functionality**
6. **Add comprehensive error handling and user feedback**
7. **Implement rate limiting for hotkey activation**
8. **Add hotkey validation in settings UI**

## Priority Assessment

**Critical:** None
**High:** Hotkey conflict detection, proper error handling in `handleHotkeyPress()`
**Medium:** Permission status tracking, automatic reconnection, rate limiting
**Low:** Recording timeout, duplicate file cleanup

## Unresolved Questions

1. How should the app handle simultaneous hotkey presses for different capture types?
2. What should be the behavior if multiple hotkeys match the same key combination?
3. Should the app provide a way to test hotkeys before finalizing them?
4. How should the system handle keyboard layout variations (different keyboard locales)?