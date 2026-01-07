import SwiftUI

/// Individual row component for clipboard items in the list
/// Follows Raycast design principles from AGENTS.md
struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    let onCopy: () -> Void
    let onPaste: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Content type icon
            Image(systemName: item.typeIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            // Content preview
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    // Pin indicator
                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#FF9500"))
                    }
                    
                    // Code language badge
                    if let language = item.codeLanguage {
                        Text(language.uppercased())
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.6))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(3)
                    }
                    
                    Spacer()
                    
                    // Timestamp
                    Text(item.relativeTimestamp)
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.4))
                }
                
                // Preview text
                Text(item.previewText)
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.9))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            Spacer()
            
            // Quick actions (visible on hover)
            if isHovered || isSelected {
                HStack(spacing: 4) {
                    QuickActionButton(icon: "doc.on.doc", tooltip: "Copy") {
                        onCopy()
                    }
                    
                    QuickActionButton(icon: item.isPinned ? "pin.slash" : "pin", tooltip: item.isPinned ? "Unpin" : "Pin") {
                        onPin()
                    }
                    
                    QuickActionButton(icon: "trash", tooltip: "Delete", isDestructive: true) {
                        onDelete()
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        if isSelected {
            return Color(hex: "#3274D6").opacity(0.3)
        } else if isHovered {
            return Color.white.opacity(0.05)
        }
        return Color.clear
    }
    
    private var iconColor: Color {
        switch item.type {
        case .text:
            return Color(hex: "#8E8E93")
        case .code:
            return Color(hex: "#34C759")
        case .link:
             return Color(hex: "#0A84FF")
        case .image:
            return Color(hex: "#FF9500")
        case .file:
            return Color(hex: "#007AFF")
        }
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let icon: String
    let tooltip: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
                .background(isHovered ? Color.white.opacity(0.1) : Color.clear)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(tooltip)
    }
    
    private var iconColor: Color {
        if isDestructive {
            return isHovered ? Color(hex: "#FF3B30") : Color.white.opacity(0.5)
        }
        return isHovered ? Color.white.opacity(0.9) : Color.white.opacity(0.5)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        ClipboardItemRow(
            item: ClipboardItem(
                type: .text,
                contentHash: "abc123",
                textContent: "This is a sample text that was copied to the clipboard"
            ),
            isSelected: false,
            onCopy: {},
            onPaste: {},
            onPin: {},
            onDelete: {}
        )
        
        ClipboardItemRow(
            item: ClipboardItem(
                type: .code,
                contentHash: "def456",
                textContent: "func hello() { print(\"Hello\") }",
                codeLanguage: "swift"
            ),
            isSelected: true,
            onCopy: {},
            onPaste: {},
            onPin: {},
            onDelete: {}
        )
        
        ClipboardItemRow(
            item: ClipboardItem(
                type: .image,
                contentHash: "img789",
                imagePath: "/path/to/image.png",
                isPinned: true
            ),
            isSelected: false,
            onCopy: {},
            onPaste: {},
            onPin: {},
            onDelete: {}
        )
    }
    .padding()
    .background(Color(hex: "#1C1C1E"))
}
