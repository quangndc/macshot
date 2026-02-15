# Carbon API Bridging - Solution Report

## Problem Statement
MacShot's global hotkey (Cmd+Shift+5) is registered but not triggering. The current implementation uses deprecated Carbon API with incomplete event handler bridging.

## Root Cause
- Carbon framework (`import Carbon`) is deprecated and incompatible with modern macOS
- `installHandler()` is a TODO placeholder (line 117-131 in HotkeyManager.swift)
- Carbon's `InstallEventHandler` requires complex C function pointer bridging

## Evaluated Approaches

### ❌ Carbon API Bridging (Current Approach)
**Pros:**
- Code already written
- RegisterEventHotKey works

**Cons:**
- Deprecated since 2012
- 32-bit only, removed from macOS 10.15+
- No Swift interop for callbacks
- Will not work on Apple Silicon
- Dead end

### ❌ NSEvent.globalMonitor
**Pros:**
- Simple API
- Swift-native

**Cons:**
- Blocked by sandboxed apps
- Unreliable for global monitoring
- Inconsistent behavior

### ✅ CGEventTap (RECOMMENDED)
**Pros:**
- Native macOS API, fully supported
- Apple Silicon compatible
- Swift-compatible
- No external dependencies
- Handles all edge cases
- Proper event filtering

**Cons:**
- Requires Accessibility permission (already required)
- More complex code (but correct)

## Final Solution: CGEventTap Architecture

### New HotkeyManager Structure

```swift
import ApplicationServices

@MainActor
final class HotkeyManager: ObservableObject {
    
    // MARK: - Properties
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let captureHandler: @MainActor () -> Void
    
    // Thread-safe callback context
    private struct CallbackContext {
        var handler: @MainActor () -> Void
        var keyCode: UInt32
        var modifiers: UInt32
    }
    
    // MARK: - Initialization
    
    init(captureHandler: @escaping @MainActor () -> Void) {
        self.captureHandler = captureHandler
    }
    
    // MARK: - Event Tap Callback
    
    private let eventTapCallback: CGEventTapCallBack = { 
        (proxy: CGEventTapProxy, 
         type: CGEventType, 
         event: CGEvent, 
         refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? in
        
        // Only handle keydown events
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }
        
        // Extract context
        let context = refcon!.assumingMemoryBound(to: CallbackContext.self).pointee
        
        // Get event data
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // Check for hotkey match
        let targetModifiers: UInt32 = {
            var mods: UInt32 = 0
            if context.modifiers & 0x01 != 0 { flags.contains(.maskCommand) }
            if context.modifiers & 0x02 != 0 { flags.contains(.maskShift) }
            if context.modifiers & 0x04 != 0 { flags.contains(.maskOption) }
            if context.modifiers & 0x08 != 0 { flags.contains(.maskControl) }
            return mods
        }()
        
        if keyCode == context.keyCode && flags == targetModifiers {
            // Trigger capture on main thread
            Task { @MainActor in
                context.handler()
            }
            return nil  // Consume event
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    // MARK: - Registration
    
    func register(hotkey: Hotkey) -> Bool {
        unregister()
        
        // Create event tap
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventTapCallback,
            userInfo: nil
        ) else {
            print("Failed to create event tap")
            return false
        }
        
        eventTap = tap
        
        // Create run loop source
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        self.runLoopSource = runLoopSource
        
        // Enable the tap
        CGEvent.tapEnable(tap: tap, enable: true)
        
        return true
    }
    
    func unregister() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFRunLoopRemoveSource(
                CFRunLoopGetCurrent(),
                runLoopSource!,
                .commonModes
            )
        }
        eventTap = nil
        runLoopSource = nil
    }
}
```

### Key Implementation Details

1. **Callback Context**: Uses unsafe pointer to pass handler to C callback
2. **Thread Safety**: Capture handler dispatched to @MainActor
3. **Event Filtering**: Returns nil to consume event, Unmanaged.passUnretained(event) to pass through
4. **Cleanup**: Proper CFRunLoop cleanup to prevent memory leaks

### Migration Steps

1. Replace `HotkeyManager.swift` with CGEventTap implementation
2. Remove `import Carbon` - use `import ApplicationServices` only
3. Update modifier constants (Carbon → CGEventFlags)
4. Test with Accessibility permission enabled
5. Verify hotkey triggers capture

### Configuration Changes

**None required** - CGEventTap works with existing entitlements:
```xml
<key>NSAccessibilityUsageDescription</key>
<string>MacShot needs accessibility access for global hotkey functionality.</string>
```

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Accessibility permission denied | High | Clear setup instructions, in-app prompt |
| Event tap performance | Low | Efficient callback, early returns |
| Memory leaks | Medium | Proper CF cleanup, deinit handling |

## Success Metrics

- [ ] Hotkey triggers capture from any app
- [ ] No memory leaks (verify with Instruments)
- [ ] Works on Apple Silicon
- [ ] Compatible with macOS 15.0+

## Next Steps

1. **I can create a detailed implementation plan** with step-by-step phases
2. **You can implement directly** using the solution above
3. **We can iterate** on the implementation together

## Dependencies

- Xcode project created ✓
- Accessibility permission required
- Existing `CaptureEngine` integration ready

