// EditorSettings.swift - Annotation editor defaults
// Think of it like setting up your art supplies - which tool to use first, what color

import SwiftUI

// EDITOR SETTINGS VIEW - Configure annotation editor defaults
struct EditorSettings: View {
    // @Binding connects to settings data from parent
    // Changes sync between view and settings object
    @Binding var settings: AppSettings

    // BODY - What this settings tab looks like
    var body: some View {
        // FORM arranges controls in clean layout
        Form {
            // DEFAULT TOOL - Which tool is selected when editor opens
            Picker("Default Tool", selection: $settings.defaultTool) {
                // Each tool type gets an option
                Text("Select").tag(ToolType.select)
                Text("Arrow").tag(ToolType.arrow)
                Text("Rectangle").tag(ToolType.rectangle)
                Text("Ellipse").tag(ToolType.ellipse)
                Text("Line").tag(ToolType.line)
                Text("Text").tag(ToolType.text)
                Text("Number").tag(ToolType.number)
                Text("Spotlight").tag(ToolType.spotlight)
            }

            // STROKE WIDTH - How thick are the lines drawn
            VStack(alignment: .leading) {
                // Show current value with label
                Text("Stroke Width: \(Int(settings.defaultStrokeWidth))pt")

                // Slider lets user pick thickness
                // Range: 1pt (thin) to 10pt (thick)
                Slider(value: $settings.defaultStrokeWidth, in: 1...10)
            }

            // DEFAULT COLOR - What color for new annotations
            HStack {
                Text("Default Color")
                Spacer()  // Pushes label left, color picker right

                // Color picker lets user choose a color
                ColorPicker("", selection: $settings.defaultColor)
            }
        }
        .padding()
    }
}

// PREVIEW - Shows what this view looks like in Xcode
#if DEBUG
struct EditorSettings_Previews: PreviewProvider {
    static var previews: some View {
        EditorSettings(settings: .constant(AppSettings.defaults))
    }
}
#endif
