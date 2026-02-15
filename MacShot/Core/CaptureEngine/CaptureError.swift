// CaptureError.swift - Capture operation errors
// Part of Phase 02 - Capture Engine

import Foundation

/// Errors that can occur during screenshot capture
enum CaptureError: Error, LocalizedError {
    case permissionDenied
    case captureInProgress
    case displayNotFound
    case windowNotFound
    case windowOffScreen
    case invalidRegion(CGRect)
    case regionTooSmall(minSize: CGSize)
    case captureFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Screen recording permission denied. Please enable in System Settings > Privacy & Security > Screen Recording"
        case .captureInProgress:
            return "A capture operation is already in progress"
        case .displayNotFound:
            return "No display found for capture"
        case .windowNotFound:
            return "Window not found or has been closed"
        case .windowOffScreen:
            return "Window is not visible on any screen"
        case .invalidRegion(let rect):
            return "Invalid capture region: \(rect)"
        case .regionTooSmall(let size):
            return "Region too small. Minimum size: \(Int(size.width)) x \(Int(size.height))"
        case .captureFailed(let message):
            return "Capture failed: \(message)"
        }
    }
}
