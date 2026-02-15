# MacShot Deployment Guide

## Overview

This guide provides comprehensive instructions for building, testing, and deploying MacShot. The document covers development builds, App Store submission, and maintenance procedures.

## Prerequisites

### Development Requirements
- **macOS**: 15.0 or later
- **Xcode**: 15.0 or later
- **Swift**: 6.0 toolchain
- **Hardware**: Intel or Apple Silicon Mac
- **Storage**: 2GB+ free space for builds

### Apple Developer Account
- **Apple ID**: Free Apple ID for development
- **Developer Account**: Paid Apple Developer account ($99/year) for distribution
- **App Store Connect**: Access required for App Store submission

### Certificates and Profiles
- **Developer Certificate**: Code signing certificate
- **App Store Certificate**: Distribution certificate
- **Provisioning Profiles**: Development and distribution profiles

## Build Configuration

### Build Settings Overview
```swift
// Package.swift configuration
let package = Package(
    name: "MacShot",
    platforms: [.macOS(.v15)],
    products: [.executable(name: "MacShot", targets: ["MacShot"])],
    targets: [
        .executableTarget(
            name: "MacShot",
            dependencies: [],
            path: "MacShot",
            sources: ["Core/**", "Features/**", "System/**", "UI/**", "*.swift"],
            resources: []
        )
    ]
)
```

### Xcode Build Configuration
1. **Open Project**: `open MacShot.xcodeproj`
2. **Select Scheme**: MacShot
3. **Configuration**: Debug (development), Release (distribution)

### Build Types

#### Debug Build
- **Purpose**: Development and testing
- **Optimization**: None
- **Debug Information**: Full
- **Code Signing**: Development certificate
- **Symbols**: Included for debugging

```bash
# Debug build command
xcodebuild -project MacShot.xcodeproj \
          -scheme MacShot \
          -configuration Debug \
          -arch x86_64 \
          -sdk macosx \
          build
```

#### Release Build
- **Purpose**: Distribution and App Store
- **Optimization**: Full
- **Debug Information**: Stripped
- **Code Signing**: Distribution certificate
- **Symbols**: None (for privacy)

```bash
# Release build command
xcodebuild -project MacShot.xcodeproj \
          -scheme MacShot \
          -configuration Release \
          -arch x86_64 \
          -arch arm64 \
          -sdk macosx \
          -destination generic/platform=macOS \
          build
```

## Build Process

### Command Line Building

#### Single Architecture Build
```bash
# Intel build
xcodebuild -project MacShot.xcodeproj \
          -scheme MacShot \
          -configuration Release \
          -arch x86_64 \
          -sdk macosx \
          -archivePath MacShot.xcarchive \
          archive

# Apple Silicon build
xcodebuild -project MacShot.xcodeproj \
          -scheme MacShot \
          -configuration Release \
          -arch arm64 \
          -sdk macosx \
          -archivePath MacShot-ARM.xcarchive \
          archive
```

#### Universal Binary Build
```bash
# Create universal binary
xcodebuild -project MacShot.xcodeproj \
          -scheme MacShot \
          -configuration Release \
          -archivePath MacShot-Universal.xcarchive \
          archive
```

### Xcode Build Process

#### Manual Build Steps
1. Open Xcode project
2. Select build target
3. Choose configuration (Debug/Release)
4. Select destination
5. Click Build button (⌘B) or Product → Build

#### Automated Build
1. Enable Automator or create shell script
2. Use xcodebuild commands
3. Include error handling
4. Archive for distribution

## Testing Procedures

### Unit Testing

#### Running Tests
```bash
# Run all tests
xcodebuild test -project MacShot.xcodeproj -scheme MacShot -destination 'platform=macOS'

# Run specific test target
xcodebuild test -project MacShot.xcodeproj -scheme MacShot -only-testing:MacShotTests
```

#### Test Coverage
```bash
# Generate coverage report
xcodebuild test -project MacShot.xcodeproj -scheme MacShot \
              -enableCodeCoverage YES \
              -destination 'platform=macOS'

# View coverage report
xcrun xccov view --report --json MacShot.xcresult
```

### Integration Testing

#### UI Testing
```bash
# Run UI tests
xcodebuild test -project MacShot.xcodeproj \
               -scheme MacShot \
               -only-testing:MacShotUITests \
               -destination 'platform=macOS'
```

#### Performance Testing
```bash
# Performance testing
xcodebuild test -project MacShot.xcodeproj \
               -scheme MacShot \
               -only-testing:MacShotPerformanceTests \
               -destination 'platform=macOS'
```

### Manual Testing Checklist

#### Functionality Testing
- [ ] Menu bar icon appears
- [ ] Global hotkey triggers capture
- [ ] Fullscreen capture works
- [ ] Region selection works
- [ ] Window capture works
- [ ] Files save correctly
- [ ] Settings open properly

#### Edge Case Testing
- [ ] Multiple display setup
- [ ] Retina display scaling
- [ ] Low memory conditions
- [ ] Network file systems
- [ ] Permission denied scenarios
- [ ] Large file handling

#### UI Testing
- [ ] Menu bar interactions
- [ ] Keyboard shortcuts
- [ ] Mouse interactions
- [ ] Screen reader support
- [ ] High contrast mode
- [ ] Different screen sizes

## Code Signing

### Development Signing

#### Creating Development Certificate
1. Open Keychain Access
2. Keychain Access → Certificate Assistant → Create Certificate
3. Type: Code Signing
4. Identity: Mac Development
5. Validity: 365 days
6. Store in Keychain

#### Signing Development Build
```bash
# Sign with development certificate
codesign --force --sign "Developer ID Application: Your Name" \
        --deep --options runtime \
        MacShot.app
```

### App Store Signing

#### Distribution Certificate
1. Create certificate in Apple Developer portal
2. Download and install in Keychain
3. Use in Xcode for distribution builds

#### Notarization Process
```bash
# Package app
ditto -c -k --sequesterRsrc --keepParent MacShot.app MacShot.zip

# Upload for notarization
xcrun altool --notarize-app \
            --primary-bundle-id "com.macshot.app" \
            --username "apple-id@apple.com" \
            --password "app-specific-password" \
            --file MacShot.zip
```

## App Store Submission

### App Store Connect Preparation

#### App Information
- **Name**: MacShot
- **Bundle ID**: com.macshot.app
- **Version**: 0.9.1 (current), 1.0.0 (target)
- **Category**: Utilities
- **Age Rating**: 4+

#### App Store Connect Setup
1. Create new app in App Store Connect
2. Fill in app information
3. Add screenshots (minimum 2, maximum 5)
4. Add app preview video (optional)
5. Write app description
6. Set pricing (Free)

### Metadata Requirements

#### Screenshots
- **Size**: 1280x720 or 1280x800 pixels
- **Format**: PNG or JPG
- **Min**: 2 screenshots
- **Max**: 5 screenshots
- **Content**: Show app in action

#### App Description
- **Short Description**: Under 170 characters
- **Full Description**: Detailed features and benefits
- **Keywords**: Relevant search terms
- **Support Website**: Help and documentation URL

### App Review Submission

#### Checklist Before Submission
- [ ] App builds successfully
- [ ] All tests pass
- [ ] Privacy manifest included
- [ ] App review checklist completed
- [ ] Metadata filled correctly
- [ ] Screenshots approved

#### Submission Process
1. Archive app in Xcode
2. Upload to App Store Connect
3. Complete metadata
4. Submit for review
5. Respond to review comments

### App Review Guidelines

#### Common Rejections
- **Guideline 2.1 - Performance**: App too slow or crashes
- **Guideline 2.2.1 - Minimum Functionality**: Not enough features
- **Guideline 4.2 - Minimum API Usage**: Deprecated APIs used
- **Guideline 5.1.1 - Security**: Privacy issues or data collection

### Review Response Template
```markdown
## Bug ID: [Review Number]
### Issue: [Description of rejection]

### Resolution:
1. [Action taken to fix issue]
2. [Additional testing performed]
3. [Evidence of fix]

### Testing:
- [Describe tests performed]
- [Include screenshots if applicable]
- [Provide user feedback if available]
```

## Distribution Methods

### App Store Distribution
- **Primary method**: App Store
- **Update process**: App Store Connect
- **Version management**: Semantic versioning
- **User feedback**: Reviews and ratings

### Direct Distribution
- **Method**: Website download
- **Format**: DMG or ZIP
- **Signing**: Developer ID certificate
- **Notarization**: Required for Gatekeeper acceptance

### Enterprise Distribution
- **Method**: Apple Business Manager
- **Distribution**: Enterprise App Store
- **Management**: Mobile Device Management
- **Updates**: Internal distribution

## Maintenance and Updates

### Version Management

#### Semantic Versioning
- **Major (X.0.0)**: Breaking changes
- **Minor (X.Y.0)**: New features
- **Patch (X.Y.Z)**: Bug fixes

#### Version Increment Rules
- **Major**: New capture modes, API changes
- **Minor**: New features, UI improvements
- **Patch**: Bug fixes, security updates

### Update Process

#### Beta Testing
1. Create TestFlight build
2. Select beta testers
3. Collect feedback
4. Fix issues
5. Release public version

#### Public Update
1. Prepare release notes
2. Update version number
3. Build and archive
4. Submit to App Store
5. Review and publish

### Monitoring and Analytics

#### Crash Reporting
- **Tools**: Crashlytics or Sentry
- **Alerts**: Crash rate > 1%
- **Resolution**: < 24 hours for critical bugs

#### Performance Monitoring
- **Metrics**: Launch time, capture performance
- **Thresholds**: < 1s launch, < 500ms capture
- **Alerts**: Performance degradation > 20%

## Troubleshooting

### Common Build Issues

#### Signing Errors
```bash
# Check certificate validity
security find-certificate -c "Developer ID Application" -p

# Verify app signature
codesign --verify --deep --verbose=4 MacShot.app
```

#### Archive Issues
```bash
# Validate app before archiving
xcrun xcodebuild -exportArchive \
                -archivePath MacShot.xcarchive \
                -exportPath . \
                -exportOptionsPlist export-options.plist
```

### Common Runtime Issues

#### Permission Issues
```bash
# Check Screen Recording permission
tccutil ScreenRecording com.macshot.app

# Check Accessibility permission
tccutil Accessibility com.macshot.app
```

#### Performance Issues
```bash
 Profile app with Instruments
# Open Xcode → Open Tool → Instruments
# Choose Time Profiler
# Run app with profiling
```

### App Store Issues

#### Rejection Resolution
1. **Review rejection email** carefully
2. **Identify specific guideline violation**
3. **Implement required changes**
4. **Test thoroughly**
5. **Submit with detailed response**

#### Review Delays
- **Standard**: 1-3 business days
- **Extended**: 7+ business days
- **Contact**: App Store Review team for delays > 7 days

## Backup and Recovery

### Development Backup
- **Source Code**: Git repository
- **Builds**: Archive builds regularly
- **Certificates**: Backup developer certificates
- **Profiles**: Save provisioning profiles

### Production Backup
- **App Store Connect**: Version history maintained
- **User Data**: No user data to backup
- **Documentation**: Keep updated documentation

### Recovery Procedures
- **Code Recovery**: Git repository history
- **Certificate Recovery**: Apple Developer portal
- **App Store Recovery**: App Store Connect version history

## Resources

### Documentation
- [Apple Developer Documentation](https://developer.apple.com)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review)
- [Notarization Guide](https://developer.apple.com/documentation/notarization)
- [Code Signing Guide](https://developer.apple.com/documentation/xcode/code-signing-your-app)

### Tools
- **Xcode**: IDE and build tools
- **Altool**: Command-line App Store tools
- **Codesign**: Code signing tool
- **Security**: Keychain management
- **Instruments**: Performance profiling

### Support
- **Apple Developer Forums**: Community support
- **Apple Developer Support**: Paid support
- **Stack Overflow**: Development questions
- **GitHub Issues**: Bug reports and feature requests

---
*Last Updated: 2026-02-15*
*Deployment Guide Version: 1.1.0*
*Current Project Version: 0.9.1*