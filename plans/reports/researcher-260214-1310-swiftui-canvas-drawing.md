# SwiftUI Canvas Drawing Research Report

## 1. Core Graphics vs SwiftUI Canvas

**Core Graphics (Quartz)**
- Pros: High performance, pixel-perfect control, extensive API
- Cons: More complex state management, imperative API
- Best for: Complex vector operations, custom rendering

**SwiftUI Canvas**
- Pros: Declarative API, easy state management, automatic redrawing
- Cons: Limited built-in shapes, performance overhead for complex scenes
- Best for: Simple to moderate drawing needs, rapid development

Apple docs: [Canvas View](https://developer.apple.com/documentation/swiftui/canvas)

## 2. Shape Drawing

### Built-in Shapes
```swift
struct ContentView: View {
    var body: some View {
        Canvas { context, size in
            // Rectangle
            context.fill(Rectangle().path(in: CGRect(x: 50, y: 50, width: 100, height: 100)),
                       with: .blue)

            // Circle/Ellipse
            context.fill(Ellipse().path(in: CGRect(x: 200, y: 50, width: 100, height: 100)),
                       with: .red)

            // Line
            context.stroke(Path { path in
                path.move(to: CGPoint(x: 50, y: 200))
                path.addLine(to: CGPoint(x: 250, y: 200))
            }, with: .black, lineWidth: 2)
        }
    }
}
```

### Custom Arrow Shape
```swift
struct Arrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let headLength: CGFloat = 20
        let headWidth: CGFloat = 15

        path.move(to: rect.origin)
        path.addLine(to: CGPoint(x: rect.maxX - headLength, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - headLength, y: rect.midY - headWidth/2))
        path.addLine(to: rect.maxX, y: rect.midY)
        path.addLine(to: CGPoint(x: rect.maxX - headLength, y: rect.midY + headWidth/2))
        path.addLine(to: CGPoint(x: rect.maxX - headLength, y: rect.midY))
        path.closeSubpath()

        return path
    }
}
```

## 3. Text Annotation

**SwiftUI Text (simpler)**
```swift
Canvas { context, size in
    let text = NSAttributedString(string: "Annotation",
                                attributes: [.font: NSFont(name: "Helvetica", size: 16)!])
    context.draw(text, at: CGPoint(x: 50, y: 50))
}
```

**Core Text (more control)**
```swift
Canvas { context, size in
    let text = NSAttributedString(string: "Styled Text",
                                attributes: [
                                    .font: NSFont(name: "Avenir", size: 20)!,
                                    .foregroundColor: NSColor.white,
                                    .backgroundColor: NSColor.black.withAlphaComponent(0.7)
                                ])
    context.draw(text, at: CGPoint(x: 100, y: 100))
}
```

Apple docs: [Text Drawing](https://developer.apple.com/documentation/uikit/uikit_text_rendering)

## 4. Spotlight/Blur Effects

```swift
Canvas { context, size in
    // Background blur
    context.fill(Rectangle().path(in: CGRect(origin: .zero, size: size)),
               with: .color(.gray.opacity(0.3)))

    // Spotlight effect using radial gradient
    let spotlight = RadialGradient(
        gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
        center: CGPoint(x: size.width/2, y: size.height/2),
        startRadius: 50,
        endRadius: 200
    )

    context.fill(Rectangle().path(in: CGRect(origin: .zero, size: size)),
               with: .foreground(LinearGradient(colors: [.clear], startPoint: .center, endPoint: .top)))
}
```

## 5. Transform Operations

```swift
Canvas { context, size in
    context.withCGContext { cgContext in
        // Move
        cgContext.translateBy(x: 100, y: 100)

        // Rotate
        cgContext.rotate(by: .pi / 4)

        // Scale
        cgContext.scaleBy(x: 1.5, y: 1.5)

        // Draw transformed shape
        context.fill(Rectangle().path(in: CGRect(x: -50, y: -50, width: 100, height: 100)),
                   with: .blue)
    }
}
```

## 6. Undo/Redo with UndoManager

```swift
class DrawingViewModel: ObservableObject {
    @Published var shapes: [ShapeModel] = []
    private let undoManager = UndoManager()

    func addShape(_ shape: ShapeModel) {
        undoManager.registerUndo(withTarget: self) { target in
            target.shapes.removeLast()
        }
        shapes.append(shape)
    }

    func undo() {
        undoManager.undo()
    }

    func redo() {
        undoManager.redo()
    }
}
```

## 7. Image Cropping and Aspect Ratio

```swift
struct CropView: View {
    @State private var cropRect: CGRect = CGRect(x: 50, y: 50, width: 200, height: 200)
    let imageSize = CGSize(width: 300, height: 300)

    var body: some View {
        Canvas { context, size in
            if let image = NSImage(named: "test") {
                let scaledSize = imageSize.aspectFitting(size)
                let offset = CGPoint(x: (size.width - scaledSize.width) / 2,
                                  y: (size.height - scaledSize.height) / 2)

                context.draw(Image(image), in: CGRect(origin: offset, size: scaledSize))
            }
        }
        .overlay(Rectangle().stroke(Color.blue, lineWidth: 2))
    }
}
```

## 8. PNG/JPEG Export

```swift
func exportAsPNG(image: NSImage, url: URL) throws {
    guard let tiffData = image.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "ExportError", code: 1)
    }

    try pngData.write(to: url)
}

func exportAsJPEG(image: NSImage, url: URL, quality: CGFloat) throws {
    guard let tiffData = image.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData),
          let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality]) else {
        throw NSError(domain: "ExportError", code: 1)
    }

    try jpegData.write(to: url)
}
```

Apple docs: [Image Export](https://developer.apple.com/documentation/appkit/nsimage/1520003-representation)

## Summary

SwiftUI Canvas provides excellent declarative drawing capabilities for macOS 15+. For complex applications, consider using Canvas for UI layer and Core Graphics for performance-critical drawing operations. The combination of UndoManager and proper state management creates a robust drawing experience.

## Unresolved Questions

- Performance benchmarks for complex scenes
- Metal integration for GPU acceleration
- Advanced text layout with Core Text