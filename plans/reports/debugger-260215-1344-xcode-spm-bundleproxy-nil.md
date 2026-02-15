# Debug Report: Xcode NSException bundleProxyForCurrentProcess is nil

## Executive Summary
- Issue: Running MacShot by opening Package.swift in Xcode throws NSException: "bundleProxyForCurrentProcess is nil: mainBundle.bundleURL file:///Users/huy.nguyenquang/Library/Developer/Xcode/DerivedData/macshot-gbaemapxtxgsvgavnsbpzuxnydrf/Build/Products/Debug/".
- Impact: App cannot launch when built as SwiftPM executable; SwiftUI/AppKit expects an app bundle.
- Likely root cause: Package.swift defines only an executable target with Info.plist and Entitlements excluded, so Xcode builds a command-line executable (no .app bundle). SwiftUI @main/NSApplication expects Bundle.main to be a bundle; fails when there is none.
- Priority: High for developer workflow; runtime not reachable in this configuration.

## Technical Analysis
- Package.swift defines:
  - product: executable "MacShot"
  - target: executableTarget path "MacShot", exclude Info.plist and Entitlements.plist, resources: []
- When opening Package.swift, Xcode treats this as a SwiftPM executable, not an app bundle. Build output in DerivedData/Build/Products/Debug/ is an executable path, not an .app.
- SwiftUI App lifecycle in MacShot/MacShotApp.swift uses @main with NSApplicationDelegateAdaptor. This requires a proper app bundle to initialize bundle proxy and load resources.
- Error string mentions bundleProxyForCurrentProcess is nil and shows a directory URL in Build/Products/Debug/, consistent with running a raw executable without a bundle.

## Supporting Evidence
- /Users/huy.nguyenquang/Claude-Projects/macshot/Package.swift:
  - executable product/target only
  - Info.plist and Entitlements.plist excluded
  - resources: []
- /Users/huy.nguyenquang/Claude-Projects/macshot/MacShot/MacShotApp.swift:
  - SwiftUI @main App, requires AppKit lifecycle and bundle

## Actionable Recommendations
### Immediate Fix (most likely)
- Open the Xcode project instead of Package.swift:
  - /Users/huy.nguyenquang/Claude-Projects/macshot/MacShot.xcodeproj
  - Build and run scheme "MacShot" as an App product.

### Alternate Fixes / Diagnostics
- If you must use Package.swift in Xcode:
  - Ensure the target is an app bundle (SwiftPM does not build macOS app bundles directly). Use Xcode project for app packaging.
  - Confirm whether the Xcode scheme created from Package.swift runs as “Executable” not “App” in Product type.
- Verify whether Build Products contains MacShot.app. If not, you are in the SPM executable path.
- Sanity check at runtime: add temporary log (or breakpoint) to inspect Bundle.main.bundleURL; expect .app bundle when fixed.

## Most Likely Root Cause
- Running a SwiftUI macOS app as a SwiftPM executable (no bundle) by opening Package.swift, causing Bundle.main to be nil and triggering the NSException.

## Unresolved Questions
- Are you opening MacShot.xcodeproj or only Package.swift?
- Does the Build Products directory contain MacShot.app when using the Xcode project scheme?
