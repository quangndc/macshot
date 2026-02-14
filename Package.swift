// swift-tools-version: 6.0
// MacShot - Screenshot capture tool for macOS

import PackageDescription

let package = Package(
    name: "MacShot",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "MacShot",
            targets: ["MacShot"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MacShot",
            dependencies: [],
            path: "MacShot",
            exclude: ["Info.plist", "Entitlements.plist"],
            sources: [
                "MacShotApp.swift",
                "Core/CaptureEngine.swift",
                "Core/FileManager.swift",
                "Core/CaptureEngine/CaptureMode.swift",
                "Core/CaptureEngine/CaptureResult.swift",
                "Core/CaptureEngine/CaptureEngineCoordinator.swift",
                "Core/CaptureEngine/FullscreenCapture.swift",
                "Core/CaptureEngine/RegionCapture.swift",
                "Core/CaptureEngine/WindowCapture.swift",
                "Core/CaptureEngine/ScreenCaptureHelper.swift",
                "Core/Export/ExportOptions.swift",
                "Core/Export/AspectRatio.swift",
                "Core/Export/ImageCropper.swift",
                "Core/Export/ExportManager.swift",
                "Core/Export/Formats/PNGExporter.swift",
                "Core/Export/Formats/JPEGExporter.swift",
                "Features/Capture/RegionSelectionOverlay.swift",
                "Features/Editor/EditorWindow.swift",
                "Features/Editor/EditorView.swift",
                "Features/Editor/EditorViewModel.swift",
                "Features/Editor/EditorToolbar.swift",
                "Features/Editor/Components/ToolButton.swift",
                "Features/Editor/Components/PropertiesPanel.swift",
                "Features/Editor/Components/CanvasContainer.swift",
                "Features/Editor/Components/ExportButton.swift",
                "Features/Editor/Components/ExportPanel.swift",
                "Features/Editor/Components/CropOverlay.swift",
                "System/HotkeyManager.swift",
                "UI/MenuBarView.swift",
                "Core/Annotation/AnnotationCanvas.swift",
                "Core/Annotation/AnnotationEngine.swift",
                "Core/Annotation/InteractionHandler.swift",
                "Core/Annotation/Models/ShapeProtocol.swift",
                "Core/Annotation/Models/RectangleShape.swift",
                "Core/Annotation/Models/EllipseShape.swift",
                "Core/Annotation/Models/LineShape.swift",
                "Core/Annotation/Models/ArrowShape.swift",
                "Core/Annotation/Models/TextShape.swift",
                "Core/Annotation/Models/NumberShape.swift",
                "Core/Annotation/Models/SpotlightShape.swift",
                "Core/Annotation/Tools/ShapeFactory.swift",
                "Core/Annotation/Tools/ToolManager.swift",
                "Core/Annotation/Tools/ToolType.swift"
            ],
            resources: []
        ),
        .testTarget(
            name: "MacShotTests",
            dependencies: ["MacShot"],
            path: "MacShotTests"
        )
    ]
)
