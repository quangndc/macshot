# MacShot

A lightweight macOS screenshot tool with global hotkey support.

## Overview

MacShot is a native macOS application (macOS 15.0+) built with SwiftUI that provides fast screenshot capture with configurable global hotkeys and automatic file management.

## Features

- **Global Hotkey**: Capture screenshots from anywhere in macOS
- **Menu Bar App**: Runs unobtrusively in the menu bar
- **Smart Naming**: Automatic timestamp-based file naming
- **Configurable Output**: Custom save locations
- **Native Performance**: Built with Swift 6.0 for optimal performance

## Requirements

- macOS 15.0 or later
- Xcode 15.0 or later
- Swift 6.0

## Permissions

MacShot requires the following macOS permissions:

- **Screen Recording**: Required to capture screen content
- **Accessibility**: Required for global hotkey registration
- **Automation**: Required for system-level integration

## Project Status

> **Phase**: Implementation in progress
> **Current Phase**: 01 - Project Setup
> **Bundle ID**: `com.macshot.app`

## Development

### Build

```bash
# Open in Xcode
open MacShot.xcodeproj

# Or build from command line
xcodebuild -project MacShot.xcodeproj -scheme MacShot -configuration Debug
```

### Structure

```
MacShot/
├── Core/           # Core functionality
├── Features/       # Feature modules
├── UI/             # SwiftUI views
├── System/         # System integration
└── Resources/      # Assets and resources
```

## License

MIT License - See LICENSE file for details
