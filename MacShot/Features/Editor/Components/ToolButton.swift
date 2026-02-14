// ToolButton.swift - Individual toolbar button for tool selection
// Part of Phase 05 - Editor UI

import SwiftUI

/// Button component for tool selection in toolbar
struct ToolButton: View {
    // MARK: - Properties

    let tool: ToolType
    let isSelected: Bool
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background for selected state
                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.blue)
                }

                // Tool icon
                Image(systemName: tool.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .frame(width: 32, height: 32)
            }
        }
        .buttonStyle(.plain)
        .help("\(tool.displayName) (\(tool.keyboardShortcut ?? ""))")
        .accessibilityLabel(tool.displayName)
        .accessibilityHint(isSelected ? "Currently selected" : "Select this tool")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        HStack(spacing: 8) {
            ToolButton(
                tool: .select,
                isSelected: true,
                action: {}
            )
            ToolButton(
                tool: .rectangle,
                isSelected: false,
                action: {}
            )
            ToolButton(
                tool: .ellipse,
                isSelected: false,
                action: {}
            )
        }

        HStack(spacing: 8) {
            ToolButton(
                tool: .arrow,
                isSelected: false,
                action: {}
            )
            ToolButton(
                tool: .line,
                isSelected: false,
                action: {}
            )
            ToolButton(
                tool: .text,
                isSelected: false,
                action: {}
            )
        }
    }
    .padding()
    .background(.ultraThinMaterial)
}
