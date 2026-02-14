// EditorViewModel.swift - State management for editor UI
// Part of Phase 05 - Editor UI

import SwiftUI
import Observation

/// View model managing editor state and tool interactions
@Observable
final class EditorViewModel {
    // MARK: - Capture Data

    /// The captured screenshot being edited
    let captureResult: CaptureResult

    // MARK: - Tool Selection

    /// Currently selected drawing tool
    var selectedTool: ToolType = .select {
        didSet {
            toolManager.selectTool(selectedTool)
        }
    }

    // MARK: - Style Properties

    /// Current stroke color
    var selectedColor: Color = .red {
        didSet {
            toolManager.setStrokeColor(selectedColor)
        }
    }

    /// Current fill color (nil = transparent)
    var selectedFill: Color? = nil {
        didSet {
            toolManager.setFillColor(selectedFill)
        }
    }

    /// Current stroke width in points
    var strokeWidth: CGFloat = 2 {
        didSet {
            toolManager.setStrokeWidth(Double(strokeWidth))
        }
    }

    /// Current opacity (0.0 - 1.0)
    var opacity: Double = 1.0 {
        didSet {
            toolManager.setOpacity(opacity)
        }
    }

    // MARK: - UI State

    /// Show/hide properties panel
    var showProperties = true

    /// Show/hide toolbar
    var showToolbar = true

    // MARK: - Tool Manager

    /// Internal tool manager for canvas interaction
    private let toolManager: ToolManager

    // MARK: - Initialization

    /// Initialize with capture result
    /// - Parameter result: The screenshot capture result to edit
    init(result: CaptureResult) {
        self.captureResult = result
        self.toolManager = ToolManager()

        // Sync initial state with tool manager
        self.selectedColor = toolManager.strokeColor
        self.strokeWidth = CGFloat(toolManager.strokeWidth)
        self.opacity = toolManager.opacity
    }

    // MARK: - Accessors

    /// Get the tool manager for canvas binding
    var toolManagerAccessor: ToolManager {
        toolManager
    }

    // MARK: - Actions

    /// Select a specific tool
    /// - Parameter tool: The tool to select
    func selectTool(_ tool: ToolType) {
        selectedTool = tool
    }

    /// Apply a color preset
    /// - Parameter preset: The preset to apply
    func applyPreset(_ preset: ColorPreset) {
        switch preset {
        case .red:
            toolManager.applyRedPreset()
            selectedColor = .red
            selectedFill = nil
        case .blue:
            toolManager.applyBluePreset()
            selectedColor = .blue
            selectedFill = nil
        case .green:
            toolManager.applyGreenPreset()
            selectedColor = .green
            selectedFill = nil
        case .yellow:
            toolManager.applyHighlightPreset()
            selectedColor = .yellow
            selectedFill = .yellow.opacity(0.3)
        }

        // Sync state
        selectedColor = toolManager.strokeColor
        selectedFill = toolManager.fillColor
        strokeWidth = CGFloat(toolManager.strokeWidth)
        opacity = toolManager.opacity
    }

    /// Toggle properties panel visibility
    func toggleProperties() {
        showProperties.toggle()
    }

    /// Toggle toolbar visibility
    func toggleToolbar() {
        showToolbar.toggle()
    }

    // MARK: - Export

    /// Show export panel
    var showExportPanel = false

    /// Export manager - shared instance
    /// Use Task.run to initialize properly on main actor
    private var exportManager: ExportManager?

    /// Get or create export manager on main actor
    @MainActor
    func getExportManager() -> ExportManager {
        if let manager = exportManager {
            return manager
        }
        let manager = ExportManager()
        exportManager = manager
        return manager
    }

    /// Image cropper (lazy initialized) - made internal for ExportPanel access
    var imageCropper: ImageCropper {
        get { _imageCropper }
        set {
            _imageCropper = newValue
            // Set image bounds for cropper
            let imageSize = CGSize(
                width: captureResult.image.size.width,
                height: captureResult.image.size.height
            )
            _imageCropper.setImageBounds(
                CGRect(origin: .zero, size: imageSize)
            )
        }
    }

    /// Private storage for image cropper
    @ObservationIgnored private var _imageCropper = ImageCropper()

    /// Quick copy to clipboard
    @MainActor
    func copyToClipboard() {
        getExportManager().quickCopyToClipboard(captureResult.image)
    }

    /// Quick save to desktop
    @MainActor
    func saveToDesktop() async -> URL? {
        return await getExportManager().quickSaveToDesktop(captureResult.image)
    }
}

// MARK: - Color Presets

/// Quick color presets for common annotation styles
enum ColorPreset: String, CaseIterable, Identifiable {
    case red
    case blue
    case green
    case yellow

    // MARK: - Identifiable

    var id: String { rawValue }

    /// Display name
    var displayName: String {
        rawValue.capitalized
    }

    /// Representative color
    var color: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .yellow: return .yellow
        }
    }
}
