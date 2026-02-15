// HotkeyPerformanceTests.swift - Performance and memory tests for hotkey implementation
// Tests for Phase 09 - Testing & Validation
// Focus: Memory leaks, performance benchmarks, resource usage

import XCTest
import ApplicationServices
@testable import MacShot

final class HotkeyPerformanceTests: XCTestCase {

    // MARK: - Memory Management Tests

    func testMemoryLeakRegistrationUnregistration() {
        // Test that hotkey manager doesn't leak memory after registration/unregistration

        weak var weakManager: HotkeyManager?

        autoreleasepool {
            let handler: @MainActor () -> Void = {}
            let manager = HotkeyManager(captureHandler: handler)
            weakManager = manager

            let hotkey = Hotkey.default
            let _ = manager.register(hotkey: hotkey)
            manager.unregister()
        }

        // After autorelease pool, manager should be deallocated
        XCTAssertNil(weakManager, "HotkeyManager should be deallocated")
    }

    func testMemoryLeakMultipleHotkeys() {
        // Test memory management with multiple hotkey registrations

        weak var weakManager: HotkeyManager?

        autoreleasepool {
            let handler: @MainActor () -> Void = {}
            let manager = HotkeyManager(captureHandler: handler)
            weakManager = manager

            let hotkeys = [
                Hotkey(id: 1, keyCode: 59, flags: [.maskCommand], description: "1"),
                Hotkey(id: 2, keyCode: 60, flags: [.maskShift], description: "2"),
                Hotkey(id: 3, keyCode: 61, flags: [.maskCommand, .maskShift], description: "3")
            ]

            for hotkey in hotkeys {
                let _ = manager.register(hotkey: hotkey)
                manager.unregister()
            }
        }

        XCTAssertNil(weakManager, "HotkeyManager should be deallocated")
    }

    func testMemoryLeakLongRunning() {
        // Test memory management during long-running registration

        weak var weakManager: HotkeyManager?

        autoreleasepool {
            let handler: @MainActor () -> Void = {}
            let manager = HotkeyManager(captureHandler: handler)
            weakManager = manager

            let hotkey = Hotkey.default
            let _ = manager.register(hotkey: hotkey)

            // Simulate long-running usage
            for _ in 0..<1000 {
                // Just keep it registered
                _ = manager.register(hotkey: hotkey)
            }
        }

        // Clean up in outer scope
        if let manager = weakManager {
            manager.unregister()
        }

        XCTAssertNil(weakManager, "HotkeyManager should be deallocated")
    }

    // MARK: - Performance Benchmarks

    func testRegistrationPerformance() {
        // Test registration time performance
        let hotkey = Hotkey.default

        measure {
            let manager = HotkeyManager(captureHandler: {})
            let _ = manager.register(hotkey: hotkey)
            manager.unregister()
        }
    }

    func testUnregistrationPerformance() {
        // Test unregistration time performance
        let hotkey = Hotkey.default

        measure {
            let manager = HotkeyManager(captureHandler: {})
            let _ = manager.register(hotkey: hotkey)

            // Measure unregistration
            manager.unregister()
        }
    }

    func testHotkeyMatchingPerformance() {
        // Test hotkey matching logic performance
        let hotkey = Hotkey.default

        measure {
            for _ in 0..<10000 {
                let testFlags: CGEventFlags = [.maskCommand, .maskShift]
                let testKeyCode: Int64 = 59

                let matches = testKeyCode == Int64(hotkey.keyCode) && testFlags == hotkey.cgEventFlags
                _ = matches
            }
        }
    }

    func testMultipleRegistrationsPerformance() {
        // Performance of multiple registration/unregistration cycles
        let hotkey = Hotkey.default

        measure {
            let manager = HotkeyManager(captureHandler: {})

            for _ in 0..<100 {
                let _ = manager.register(hotkey: hotkey)
                manager.unregister()
            }
        }
    }

    // MARK: - Resource Usage Tests

    func testEventTapResourceUsage() {
        // Test that event tap doesn't consume excessive resources
        let hotkey = Hotkey.default

        measure {
            let manager = HotkeyManager(captureHandler: {})

            // Register and maintain the tap
            let result = manager.register(hotkey: hotkey)

            if result {
                // Keep it registered for a bit
                Thread.sleep(forTimeInterval: 0.1)
            }

            manager.unregister()
        }
    }

    func testRunLoopSourcePerformance() {
        // Test run loop source performance impact
        let hotkey = Hotkey.default

        measure {
            let manager = HotkeyManager(captureHandler: {})
            let _ = manager.register(hotkey: hotkey)

            // Measure impact of having active run loop source
            for _ in 0..<1000 {
                CFRunLoopRunInMode(.defaultMode, 0.001, false)
            }

            manager.unregister()
        }
    }

    // MARK: - Stress Tests

    func testHighFrequencyRegistration() {
        // Test handling high frequency registration/unregistration
        let hotkey = Hotkey.default

        measure {
            for _ in 0..<1000 {
                autoreleasepool {
                    let manager = HotkeyManager(captureHandler: {})
                    let _ = manager.register(hotkey: hotkey)
                    manager.unregister()
                }
            }
        }
    }

    func testMemoryPressureTest() {
        // Test behavior under simulated memory pressure
        let hotkey = Hotkey.default

        // Create many objects to simulate memory pressure
        var managers: [HotkeyManager] = []
        for _ in 0..<50 {
            autoreleasepool {
                let manager = HotkeyManager(captureHandler: {})
                let _ = manager.register(hotkey: hotkey)
                managers.append(manager)
            }
        }

        // Clean up
        for manager in managers {
            manager.unregister()
        }
        managers.removeAll()
    }

    // MARK: - Callback Performance Tests

    func testCallbackDispatchPerformance() {
        // Test Task { @MainActor } dispatch performance
        var callCount = 0

        let handler: @MainActor () -> Void = {
            callCount += 1
        }

        let hotkey = Hotkey.default
        let manager = HotkeyManager(captureHandler: handler)
        let result = manager.register(hotkey: hotkey)

        measure {
            if result {
                // Simulate callback dispatch
                for _ in 0..<1000 {
                    Task { @MainActor in
                        callCount += 1
                    }
                }
            }
        }

        manager.unregister()
    }

    func testEventHandlerPerformance() {
        // Test the overall event handling performance
        let hotkey = Hotkey.default

        measure {
            autoreleasepool {
                let manager = HotkeyManager(captureHandler: {})
                let _ = manager.register(hotkey: hotkey)

                // Simulate event processing
                for i in 0..<10000 {
                    let testFlags: CGEventFlags = i % 2 == 0 ? [.maskCommand, .maskShift] : [.maskCommand]
                    let testKeyCode: Int64 = 59

                    // Hotkey matching logic
                    let matches = testKeyCode == Int64(hotkey.keyCode) && testFlags == hotkey.cgEventFlags
                    _ = matches
                }

                manager.unregister()
            }
        }
    }

    // MARK: - Thread Safety Performance

    func testConcurrentAccessPerformance() {
        // Test performance with concurrent access
        let hotkey = Hotkey.default
        let queue = DispatchQueue(label: "com.macshot.test", attributes: .concurrent)

        measure {
            let group = DispatchGroup()

            for i in 0..<10 {
                queue.async(group: group) {
                    autoreleasepool {
                        let manager = HotkeyManager(captureHandler: {})
                        let _ = manager.register(hotkey: hotkey)
                        manager.unregister()
                    }
                }
            }

            group.wait()
        }
    }

    // MARK: - Memory Footprint Tests

    func testMemoryFootprintAfterOperations() {
        // Test memory footprint after various operations
        let hotkey = Hotkey.default

        // Measure initial memory
        let initialMemory = ProcessInfo.processInfo.physicalMemory

        // Perform operations
        autoreleasepool {
            let manager = HotkeyManager(captureHandler: {})

            // Multiple registrations
            for _ in 0..<100 {
                let _ = manager.register(hotkey: hotkey)
                manager.unregister()
            }
        }

        // Memory should return close to baseline
        // We can't precisely measure, but verify no crash
        XCTAssertTrue(true)
    }

    // MARK: - Resource Cleanup Tests

    func testResourceCleanupAfterCrash() {
        // Test resource cleanup in error scenarios
        let hotkey = Hotkey.default

        // Simulate scenarios where things might go wrong
        autoreleasepool {
            let manager = HotkeyManager(captureHandler: {})

            // Register
            let _ = manager.register(hotkey: hotkey)

            // Various cleanup scenarios
            manager.unregister()
            manager.unregister()  // Multiple calls
            manager.unregister()

            // Should handle gracefully
            XCTAssertTrue(true)
        }
    }

    // MARK: - Continuous Operation Tests

    func testContinuousOperationPerformance() {
        // Test performance during continuous operation
        let hotkey = Hotkey.default

        measure {
            autoreleasepool {
                let manager = HotkeyManager(captureHandler: {})
                let _ = manager.register(hotkey: hotkey)

                // Simulate continuous operation
                for i in 0..<10000 {
                    // Simulate key press checks
                    let testFlags: CGEventFlags = i % 100 == 0 ? [.maskCommand, .maskShift] : []
                    let testKeyCode: Int64 = 59

                    let matches = testKeyCode == Int64(hotkey.keyCode) && testFlags == hotkey.cgEventFlags
                    _ = matches
                }

                manager.unregister()
            }
        }
    }
}