// ExportOptions.swift - Export configuration options
// Part of Phase 06 - Export System

import Foundation

/// Export format options
enum ExportFormat: String, CaseIterable, Codable {
    case png
    case jpeg

    /// Display name for UI
    var displayName: String {
        rawValue.uppercased()
    }

    /// File extension
    var fileExtension: String {
        rawValue
    }
}

/// Export configuration containing all export settings
struct ExportOptions: Sendable {
    /// Output format (PNG or JPEG)
    var format: ExportFormat = .png

    /// JPEG quality factor (0.0 - 1.0), ignored for PNG
    var jpegQuality: Double = 0.9

    /// Aspect ratio constraint (nil = freeform)
    var aspectRatio: AspectRatio?

    /// Output file path (nil = prompt user)
    var outputPath: URL?

    /// Copy to clipboard after export
    var copyToClipboard: Bool = true

    /// Default initializer
    init() {}

    /// Initializer with format
    init(format: ExportFormat) {
        self.format = format
    }

    /// Initializer with format and output path
    init(format: ExportFormat, outputPath: URL?) {
        self.format = format
        self.outputPath = outputPath
    }

    /// Initializer with format, output path, and clipboard option
    init(format: ExportFormat, outputPath: URL?, copyToClipboard: Bool) {
        self.format = format
        self.outputPath = outputPath
        self.copyToClipboard = copyToClipboard
    }

    /// Initializer with format and JPEG quality
    init(format: ExportFormat, jpegQuality: Double) {
        self.format = format
        self.jpegQuality = max(0.1, min(1.0, jpegQuality))
    }

    /// Initializer with format, JPEG quality, and output path
    init(format: ExportFormat, jpegQuality: Double, outputPath: URL?) {
        self.format = format
        self.jpegQuality = max(0.1, min(1.0, jpegQuality))
        self.outputPath = outputPath
    }

    /// Validate quality range
    mutating func setQuality(_ quality: Double) {
        jpegQuality = max(0.1, min(1.0, quality))
    }
}
