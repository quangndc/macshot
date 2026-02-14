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
            sources: [
                "MacShotApp.swift",
                "Core/CaptureEngine.swift",
                "Core/FileManager.swift",
                "System/HotkeyManager.swift",
                "UI/MenuBarView.swift"
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
