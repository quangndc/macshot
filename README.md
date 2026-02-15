# MacShot

A lightweight macOS screenshot tool (15.0+) with global hotkey support, built with SwiftUI for native performance.

## 🚀 Quick Start

**Requirements:**
- macOS 15.0+
- Xcode 15.0+
- Swift 6.0

**Build & Run:**
```bash
# Open in Xcode
open MacShot.xcodeproj

# Build from command line
xcodebuild -project MacShot.xcodeproj -scheme MacShot -configuration Debug
```

**Required Permissions:**
- Screen Recording (for capture)
- Accessibility (for global hotkeys)
- Automation (for system integration)

## ✨ Features

- 📸 **Global Hotkey**: Capture from any app
- 🖥️ **Menu Bar Interface**: Unobtrusive operation
- 📝 **Smart Naming**: Automatic timestamps
- 💾 **Flexible Storage**: Custom save locations
- ⚡ **Native Performance**: Swift 6.0 optimization

## 📚 Documentation

Complete documentation is available in the `docs/` directory:

- [**Project Overview & PDR**](docs/project-overview-pdr.md) - Product requirements and vision
- [**Codebase Summary**](docs/codebase-summary.md) - Architecture and implementation details
- [**Code Standards**](docs/code-standards.md) - Swift coding guidelines
- [**System Architecture**](docs/system-architecture.md) - Technical architecture and data flow
- [**Project Roadmap**](docs/project-roadmap.md) - Development phases and timeline
- [**Deployment Guide**](docs/deployment-guide.md) - Build, test, and deploy instructions

## 🏗️ Project Structure

```
MacShot/
├── Core/                    # Capture engine and file management
├── Features/                # Feature modules
├── UI/                      # SwiftUI interfaces
├── System/                  # Hotkeys and system integration
└── Resources/               # Assets
```

## 🎯 Current Status

**Phase 9/10 Complete** - Testing & QA Complete
- ✅ Project setup complete
- ✅ Capture engine implementation
- ✅ File management system
- ✅ Editor UI with annotation tools
- ✅ Settings persistence system
- ✅ System integration components
- ✅ Comprehensive test suite
- 🔄 Documentation update (Phase 10 in progress)
- 🗓️ Current version: 0.9.1

## 📄 License

MIT License - See LICENSE file for details

---

For comprehensive information about development, architecture, and deployment, see the [documentation](docs/).
