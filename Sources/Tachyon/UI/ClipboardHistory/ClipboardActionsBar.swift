import SwiftUI

/// Actions bar displayed at the bottom of the clipboard history view
/// Shows available actions for the currently selected item
struct ClipboardActionsBar: View {
    let selectedItem: ClipboardItem?
    let onCopy: () -> Void
    let onPaste: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: action hints
            HStack(spacing: 20) {
                ActionHint(keys: ["⏎"], label: "Copy")
                ActionHint(keys: ["⌘", "⏎"], label: "Paste")
                ActionHint(keys: ["⌘", "P"], label: selectedItem?.isPinned == true ? "Unpin" : "Pin")
                ActionHint(keys: ["⌘", "⌫"], label: "Delete")
            }
            
            Spacer()
            
            // Right: action buttons
            if selectedItem != nil {
                HStack(spacing: 8) {
                    ActionButton(title: "Copy", icon: "doc.on.doc", shortcut: "⏎") {
                        onCopy()
                    }
                    
                    ActionButton(title: "Paste", icon: "doc.on.clipboard", shortcut: "⌘⏎", isPrimary: true) {
                        onPaste()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "#1C1C1E"))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.white.opacity(0.1)),
            alignment: .top
        )
    }
}

// MARK: - Action Hint

private struct ActionHint: View {
    let keys: [String]
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.7))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.5))
        }
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let title: String
    let icon: String
    let shortcut: String
    var isPrimary: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                
                Text(shortcut)
                    .font(.system(size: 10))
                    .foregroundColor(isPrimary ? Color.white.opacity(0.7) : Color.white.opacity(0.4))
            }
            .foregroundColor(isPrimary ? Color.white : Color.white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var backgroundColor: Color {
        if isPrimary {
            return isHovered ? Color(hex: "#0A84FF") : Color(hex: "#007AFF")
        }
        return isHovered ? Color.white.opacity(0.15) : Color.white.opacity(0.1)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        
        ClipboardActionsBar(
            selectedItem: ClipboardItem(
                type: .text,
                contentHash: "abc",
                textContent: "Sample"
            ),
            onCopy: {},
            onPaste: {},
            onPin: {},
            onDelete: {}
        )
    }
    .frame(width: 700, height: 200)
    .background(Color(hex: "#2C2C2E"))
}
