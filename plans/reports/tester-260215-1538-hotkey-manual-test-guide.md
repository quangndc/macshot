# Hotkey Implementation Manual Test Guide
**Date**: 2026-02-15 15:39
**Project**: MacShot
**Component**: CGEventTap Hotkey Implementation

## Quick Test Instructions

### Prerequisites
1. MacShot application built and running
2. Xcode or terminal access for testing

### Test 1: Accessibility Permission
1. Run the MacShot application
2. Open System Settings > Privacy & Security > Accessibility
3. Verify that MacShot is listed and permission is requested if not granted
4. **Expected**: Permission dialog should appear when hotkey is first triggered

### Test 2: Hotkey Trigger (Cmd+Shift+5)
1. With MacShot running, open any application (Safari, Finder, TextEdit, etc.)
2. Press Cmd+Shift+5 simultaneously
3. **Expected**: MacShot screenshot editor should open regardless of which app is active

### Test 3: Cross-Application Test
1. Open Safari and browse a webpage
2. Press Cmd+Shift+5
3. **Expected**: Screenshot editor should open capturing Safari
4. Open TextEdit and type some text
5. Press Cmd+Shift+5
6. **Expected**: Screenshot editor should open capturing TextEdit

### Test 4: Incorrect Combinations
1. Press only Cmd+5 (missing Shift)
2. **Expected**: Should not trigger MacShot
3. Press only Shift+5 (missing Cmd)
4. **Expected**: Should not trigger MacShot
5. Press Ctrl+Cmd+Shift+5
6. **Expected**: Should not trigger MacShot (wrong modifiers)

### Test 5: System Hotkey Conflict
1. Press Cmd+Shift+5 (standard macOS screenshot shortcut)
2. **Expected**: Should work exactly like standard screenshot (MacShot should intercept and handle)

### Test 6: Settings Integration
1. Open MacShot settings
2. Navigate to Hotkey settings
3. Verify the hotkey is set to Cmd+Shift+5
4. **Expected**: Settings should show correct hotkey configuration

## Troubleshooting

### If Hotkey Doesn't Work:
1. **Check Accessibility**: Verify MacShot has Accessibility permission
2. **Check Running**: Ensure MacShot is running (look for menu bar icon)
3. **Check Other Apps**: Try different applications to test
4. **Check Conflicts**: Ensure no other apps are using Cmd+Shift+5

### Debug Steps:
1. Open Console.app
2. Filter for "MacShot" messages
3. Trigger hotkey and check for:
   - Permission request logs
   - Event tap creation logs
   - Hotkey match logs
   - Error messages

## Expected Behavior Summary

| Test Case | Action | Expected Result |
|-----------|--------|-----------------|
| Permission First Use | Press Cmd+Shift+5 | Permission dialog appears |
| Cross-App Trigger | Press Cmd+Shift+5 in any app | MacShot editor opens |
| Wrong Combo | Press Cmd+5 | No response |
| System Shortcut | Press Cmd+Shift+5 | Works like normal screenshot |
| Settings Display | Check hotkey settings | Shows Cmd+Shift+5 |

## Performance Notes

- Hotkey response should be instantaneous (< 100ms)
- No performance impact on system when not triggered
- Memory usage should remain constant when active
- CPU usage should be minimal when idle

## Security Notes

- Only processes exact hotkey combinations
- Does not capture or store keystroke data
- Requires explicit user permission via Accessibility
- No keylogging or data collection features