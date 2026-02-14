// ExportSettings.swift - File export preferences
// Think of it like choosing how your photos get saved - quality, format, location

import SwiftUI

// EXPORT SETTINGS VIEW - Configure default export behavior
struct ExportSettings: View {
    // @Binding connects to settings data from parent
    // Changes flow both directions between view and settings
    @Binding var settings: AppSettings

    // Track whether file picker is showing
    @State private var showingFolderPicker = false

    // BODY - What this settings tab looks like
    var body: some View {
        // FORM arranges controls neatly
        Form {
            // FORMAT PICKER - Choose PNG or JPEG
            // PNG = no quality loss (bigger files)
            // JPEG = smaller files (some quality loss)
            Picker("Default Format", selection: $settings.defaultFormat) {
                // Each option has a display text and a value tag
                Text("PNG").tag(ExportFormat.png)
                Text("JPEG").tag(ExportFormat.jpeg)
            }

            // QUALITY SLIDER - Only show for JPEG format
            // When user picks JPEG, show quality control
            if settings.defaultFormat == .jpeg {
                // VSTACK arranges things vertically
                VStack(alignment: .leading) {
                    // Show current quality as percentage
                    Text("Quality: \(Int(settings.defaultQuality * 100))%")

                    // Slider lets user pick quality value
                    // in: 0.1...1.0 means minimum 10%, maximum 100%
                    Slider(value: $settings.defaultQuality, in: 0.1...1.0)
                }
            }

            // OUTPUT FOLDER - Where to save screenshots by default
            HStack {
                Text("Output Folder")
                Spacer()  // Pushes label left, button right

                // Button shows current folder or "None" (ask each time)
                Button {
                    showingFolderPicker = true
                } label: {
                    if let folder = settings.defaultOutputFolder {
                        // Show folder name - use lastPathComponent
                        Text(folder.lastPathComponent)
                            .foregroundStyle(.primary)
                    } else {
                        // No default set - will ask each time
                        Text("None (ask each time)")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.link)  // Link style looks like text
            }

            // Helpful tip about what happens with no folder set
            if settings.defaultOutputFolder == nil {
                Text("When no folder is set, you'll be asked where to save each screenshot.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        // FILE PICKER - Shown when user clicks folder button
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            // Handle the folder user picked
            if case .success(let urls) = result {
                // User picked a folder - save it (first item from array)
                if let url = urls.first {
                    settings.defaultOutputFolder = url
                }
            }
            // If user cancelled, result is .cancel - do nothing
        }
    }
}

// PREVIEW - Shows what this view looks like in Xcode
#if DEBUG
struct ExportSettings_Previews: PreviewProvider {
    static var previews: some View {
        ExportSettings(settings: .constant(AppSettings.defaults))
    }
}
#endif
