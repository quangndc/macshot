---
title: "Phase 01 - Project Setup"
description: "Xcode project initialization, entitlements, and dependencies"
status: completed
priority: P1
effort: 2h
branch: main
tags: [setup, xcode, entitlements]
created: 2026-02-14
---

## Context Links

- [Screenshot APIs - Performance Considerations](../../researcher-260214-1310-screenshot-apis.md)
- [Global Hotkey - Entitlements](../reports/researcher-260214-1310-macos-global-hotkey-research.md)
- [Menu Bar Integration - Permissions](../reports/researcher-260214-1310-macos-menu-bar-integration.md)

## Overview

**Priority**: P1 (Blocks all development)
**Status**: Completed
**Description**: Initialize Xcode project with proper entitlements, folder structure, and build configuration for macOS 15+ screenshot tool.

## Key Insights

From research reports:
- Requires Screen Recording, Accessibility, and Automation permissions
- Needs ServiceManagement for login item (auto-start)
- CGWindowList APIs require proper entitlements
- App Sandbox configuration critical for App Store distribution

## Requirements

### Functional
- Xcode project targeting macOS 15.0+
- Swift 6.0 language version
- SwiftUI lifecycle
- Proper bundle identifier and signing

### Non-Functional
- Code organization follows Swift style guide
- Build configuration for Debug/Release
- Git integration with .gitignore
- Unit test target configured

## Architecture

```
MacShot/
├── MacShot.xcodeproj/
├── MacShot/
│   ├── MacShotApp.swift
│   ├── Info.plist
│   └── Entitlements.plist
├── MacShotTests/
├── .gitignore
└── README.md
```

## Related Code Files

### Create
- `MacShot/MacShotApp.swift` - App entry point
- `MacShot/Info.plist` - App configuration
- `MacShot/Entitlements.plist` - Permissions
- `.gitignore` - Git ignore rules
- `README.md` - Project documentation

## Implementation Steps

1. **Create Xcode Project**
   - New macOS App project
   - SwiftUI interface
   - macOS 15.0 deployment target
   - Bundle ID: `com.macshot.app`

2. **Configure Entitlements**
   ```xml
   <!-- Entitlements.plist -->
   <key>com.apple.security.app-sandbox</key>
   <true/>
   <key>com.apple.security.files.user-selected.read-write</key>
   <true/>
   <key>com.apple.security.automation.apple-events</key>
   <true/>
   <key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
   <array>
       <string>com.apple.screencapture</string>
   </array>
   ```

3. **Setup Folder Structure**
   - Create `Core/`, `Features/`, `UI/`, `System/`, `Resources/` groups
   - Configure build phases for asset compilation

4. **Configure Build Settings**
   - Swift Language Version: 6.0
   - Swift Concurrency: Strict
   - Warning Mode: Enhanced
   - Enable Testability: Yes

5. **Git Initialization**
   - Initialize git repo
   - Add .gitignore for Xcode/Swift
   - Initial commit

6. **Create Placeholder Files**
   - App delegate stub
   - Core module stubs
   - Test stubs

## Todo List

- [x] Create Xcode project from template
- [x] Set deployment target to macOS 15.0
- [x] Create Entitlements.plist with required permissions
- [x] Configure bundle identifier and signing
- [x] Create folder structure in Xcode
- [x] Setup git repository
- [x] Create README.md with project overview
- [x] Verify build configuration (Debug + Release)
- [ ] Add SwiftLint to build phase (optional)

## Success Criteria

- [x] Project builds without errors for macOS 15.0+
- [x] App launches and shows blank window
- [x] All required entitlements configured
- [x] Git repo initialized with proper .gitignore
- [x] Unit test target configured and runs empty tests

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Incorrect entitlements | High (app won't function) | Test capture APIs early |
| macOS version mismatch | Medium | Set explicit deployment target |
| Signing issues | Medium | Use developer team for testing |

## Security Considerations

- App Sandbox enabled (App Store requirement)
- Minimal entitlements (only what's necessary)
- File access limited to user-selected files
- No network access required initially

## Next Steps

Proceed to **Phase 02 - Capture Engine** once:
- Project builds successfully
- Entitlements verified
- Basic app window displays
