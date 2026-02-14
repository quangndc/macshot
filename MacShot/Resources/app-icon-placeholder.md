# MacShot App Icon - Generation Instructions

## Status
**Placeholder Only** - AI generation requires Gemini API paid tier

## Design Concept

```
Minimal camera viewfinder with capture button overlay
- Blue to purple gradient (#007AFF to #5856D6)
- Flat design, SF Symbols style
- Transparent background
- Recognizable at small sizes (16x16)
```

## Required Sizes

| Size | File | Usage |
|------|------|-------|
| 16x16 | 16.png | Menu bar |
| 32x32 | 32.png | Retina menu bar |
| 128x128 | 128.png | Dock |
| 256x256 | 256.png | App switcher |
| 512x512 | 512.png | Settings |
| 1024x1024 | 1024.png | Mac App Store |

## Generation Options

### Option 1: ImageMagick (Free)
```bash
# Create simple camera icon
convert -size 1024x1024 xc:none \
  -fill '#007AFF' -draw 'circle 512,512 400,400' \
  -fill white -draw 'rectangle 350,512 674,570' \
  -fill white -draw 'circle 512,541 30' \
  app-icon.png
```

### Option 2: SF Symbols + SwiftUI
```swift
// Use SF Symbol as base
let cameraIcon = Image(systemName: "camera.fill")
    .symbolRenderingMode(.hierarchical)
    .foregroundStyle(
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
```

### Option 3: Manual Design
- Use Figma/Sketch with SF Symbols library
- Export at all required sizes
- Add to Xcode asset catalog

## Next Steps
1. Choose generation method above
2. Generate icons in all sizes
3. Add PNG files to AppIcon.appiconset/
4. Update Contents.json if needed
