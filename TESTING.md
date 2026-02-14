# MacShot Testing Guide

Contributor guide for running, writing, and maintaining tests.

## Table of Contents

- [Quick Start](#quick-start)
- [Running Tests](#running-tests)
- [Test Organization](#test-organization)
- [Writing Tests](#writing-tests)
- [Performance Benchmarks](#performance-benchmarks)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

```bash
# Run all tests
swift test

# Run specific test class
swift test --filter CaptureEngineTests

# Run with verbose output
swift test --verbose

# Run tests with code coverage
swift test --enable-code-coverage
```

---

## Running Tests

### Prerequisites

- macOS 15.0+
- Xcode Command Line Tools
- Swift Package Manager

### Commands

| Command | Description |
|---------|-------------|
| `swift test` | Run all tests |
| `swift test --filter <pattern>` | Run tests matching pattern |
| `swift test --verbose` | Show detailed test output |
| `swift test --enable-code-coverage` | Generate coverage report |
| `swift test --parallel` | Run tests in parallel |

### Test Targets

- **MacShotTests** - Unit tests
- **MacShotUITests** - UI automation tests

---

## Test Organization

### Unit Tests (`MacShotTests/`)

| File | Description |
|------|-------------|
| `CaptureEngineTests.swift` | Screenshot capture tests |
| `AnnotationEngineTests.swift` | Annotation shape tests |
| `ExportManagerTests.swift` | Export/save tests |
| `SettingsStoreTests.swift` | UserDefaults persistence tests |
| `PerformanceTests.swift` | Performance benchmarks |

### UI Tests (`MacShotUITests/`)

| File | Description |
|------|-------------|
| `CaptureFlowUITests.swift` | Capture workflow UI tests |
| `AnnotationFlowUITests.swift` | Annotation tool UI tests |
| `ExportFlowUITests.swift` | Export/save UI tests |

---

## Writing Tests

### Test Structure

```swift
import XCTest
@testable import MacShot

final class MyTests: XCTestCase {
    var systemUnderTest: MySystem!

    override func setUp() {
        super.setUp()
        systemUnderTest = MySystem()
    }

    override func tearDown() {
        systemUnderTest = nil
        super.tearDown()
    }

    func testFeature() {
        // Given
        let input = "test"

        // When
        let result = systemUnderTest.process(input)

        // Then
        XCTAssertEqual(result, "expected")
    }
}
```

### Naming Conventions

- **Test Class**: `<Feature>Tests` (e.g., `CaptureEngineTests`)
- **Test Method**: `test<Feature>` or `test<Feature>_<Condition>`
- **Given-When-Then**: Structure tests logically

### Async Tests

```swift
func testAsyncFeature() async throws {
    if #available(macOS 15.0, *) {
        let result = try await systemUnderTest.asyncMethod()
        XCTAssertNotNil(result)
    }
}
```

### @MainActor Tests

```swift
@MainActor
final class MainActorTests: XCTestCase {
    func testMainActorFeature() {
        // Tests for @MainActor classes
    }
}
```

---

## Performance Benchmarks

### Running Benchmarks

```bash
# Run only performance tests
swift test --filter PerformanceTests

# View detailed metrics
swift test --filter PerformanceTests --verbose
```

### Benchmarks Available

| Test | Target |
|------|--------|
| `testCaptureLatencyBenchmark` | < 100ms |
| `testPNGExportTimeBenchmark` | < 500ms |
| `testJPEGExportTimeBenchmark` | < 500ms |
| `testRenderingPerformanceAt60fps` | < 16.67ms |
| `testMemoryUsageDuringCapture` | No leaks |
| `testMemoryUsageDuringExport` | No leaks |

### Performance Metrics

- **XCTClockMetric** - Execution time
- **XCTMemoryMetric** - Memory usage
- **XCTCPUMetric** - CPU usage

---

## Troubleshooting

### Tests Timing Out

```
// Increase timeout for slow operations
let expectation = XCTestExpectation(description: "Wait for async")
wait(for: 10.0, timeout: 15.0)
```

### UI Test Failures

```
// Ensure app is in expected state
override func setUp() {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["UITesting"] // Add flag
    app.launch()
}
```

### @MainActor Isolation

```
// Use MainActor.assumeIsolated for bridging
await MainActor.assumeIsolated {
    // Access @MainActor code
}
```

### Async/Await Errors

```
// Check availability before using
if #available(macOS 15.0, *) {
    // Use async code
} else {
    XCTail("Requires macOS 15.0+")
}
```

---

## Coverage Goals

**Target**: > 60% code coverage

### Priority Areas

1. **Core Logic**: Capture, Annotation, Export
2. **State Management**: Settings, Undo/Redo
3. **Error Handling**: File I/O, Invalid inputs

### Exclusions

- SwiftUI View code (hard to unit test)
- Platform-specific APIs (CGDisplay, etc.)
- Simple property wrappers

---

## CI/CD Integration

Tests run automatically on:

- Pull requests
- Main branch commits
- Release tags

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Tests
        run: swift test --enable-code-coverage
```

---

## Resources

- [XCTest Framework](https://developer.apple.com/documentation/xctest)
- [UI Testing Guide](https://developer.apple.com/documentation/xctest/ui_testing)
- [Performance Testing](https://developer.apple.com/documentation/xctest/measuring_test_performance)
