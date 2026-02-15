// RegionSelectionOverlay.swift - UI for selecting screen region
// Part of Phase 02 - Capture Engine

@preconcurrency import AppKit

/// Overlay window for selecting a screen region
final class RegionSelectionOverlay: NSWindow {
    private var selectionStart: CGPoint = .zero
    private var selectionEnd: CGPoint = .zero
    private var selectionRect: CGRect = .zero
    private var onSelectionComplete: ((CGRect) -> Void)?
    private var displayConfigurationObserver: NSObjectProtocol?
    private var currentDisplayConfiguration: String = UUID().uuidString
    private var isValidConfiguration = true

    /// Create overlay covering all screens
    convenience init(onSelectionComplete: @escaping (CGRect) -> Void) {
        // Calculate frame covering all screens
        let allScreens = NSScreen.screens
        var minX: CGFloat = .infinity
        var minY: CGFloat = .infinity
        var maxX: CGFloat = -.infinity
        var maxY: CGFloat = -.infinity

        for screen in allScreens {
            let frame = screen.frame
            minX = min(minX, frame.minX)
            minY = min(minY, frame.minY)
            maxX = max(maxX, frame.maxX)
            maxY = max(maxY, frame.maxY)
        }

        let overlayFrame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

        self.init(
            contentRect: overlayFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.onSelectionComplete = onSelectionComplete
        self.setupWindow()
    }

    private func setupWindow() {
        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        ignoresMouseEvents = false

        // Create custom draw view for overlay
        let drawView = SelectionDrawView(frame: frame)
        contentView = drawView

        // Register for display changes
        displayConfigurationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Invalidate current selection
            self?.currentDisplayConfiguration = UUID().uuidString
            self?.isValidConfiguration = false
            self?.showDisplayChangedWarning()
        }
    }

    private func showDisplayChangedWarning() {
        // Close the overlay as display configuration changed
        close()
        // TODO: Show user notification about display configuration change
    }

    /// Clean up observer
    deinit {
        if let observer = displayConfigurationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func mouseDown(with event: NSEvent) {
        selectionStart = convertFromScreenLocation(event.locationInWindow)
        selectionEnd = selectionStart
        selectionRect = .null
        updateSelectionView()
    }

    override func mouseDragged(with event: NSEvent) {
        selectionEnd = convertFromScreenLocation(event.locationInWindow)
        selectionRect = CGRect(points: (selectionStart, selectionEnd))
        updateSelectionView()
    }

    override func mouseUp(with event: NSEvent) {
        let finalRect = CGRect(points: (selectionStart, selectionEnd))

        // Only complete if rect has meaningful size
        if finalRect.width > 10 && finalRect.height > 10 {
            onSelectionComplete?(finalRect)
        }

        close()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC key
            close()
        }
    }

    private func convertFromScreenLocation(_ point: CGPoint) -> CGPoint {
        guard let screen = NSScreen.main else { return point }
        let screenFrame = screen.frame
        return CGPoint(x: point.x, y: screenFrame.height - point.y)
    }

    private func updateSelectionView() {
        guard let drawView = contentView as? SelectionDrawView else { return }
        drawView.selectionRect = selectionRect
        drawView.needsDisplay = true
    }
}

/// Custom NSView for drawing selection rectangle
class SelectionDrawView: NSView {
    var selectionRect: CGRect = .null

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw semi-transparent dark overlay
        NSColor.black.withAlphaComponent(0.3).setFill()
        bounds.fill()

        // Draw selection rectangle
        if !selectionRect.isNull {
            // Clear selection area
            NSColor.clear.setFill()
            selectionRect.fill()

            // Draw border
            NSColor.white.setStroke()
            let borderPath = NSBezierPath(rect: selectionRect)
            borderPath.lineWidth = 2
            borderPath.stroke()

            // Draw dimensions text
            let dimensions = "\(Int(selectionRect.width)) × \(Int(selectionRect.height))"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.white
            ]
            let textSize = dimensions.size(withAttributes: attrs)
            let textRect = CGRect(
                x: selectionRect.midX - textSize.width / 2,
                y: selectionRect.minY - 20,
                width: textSize.width + 8,
                height: textSize.height + 4
            )

            NSColor.black.withAlphaComponent(0.7).setFill()
            NSBezierPath(roundedRect: textRect, xRadius: 4, yRadius: 4).fill()

            dimensions.draw(
                in: textRect.insetBy(dx: 4, dy: 2),
                withAttributes: attrs
            )
        }
    }
}

extension CGRect {
    /// Create rect from two points
    init(points: (CGPoint, CGPoint)) {
        let (p1, p2) = points
        self.init(
            x: min(p1.x, p2.x),
            y: min(p1.y, p2.y),
            width: abs(p2.x - p1.x),
            height: abs(p2.y - p1.y)
        )
    }
}
