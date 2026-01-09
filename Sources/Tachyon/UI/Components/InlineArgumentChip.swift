import SwiftUI

/// A styled inline argument input chip for the search bar
/// Matches Raycast's design with rounded background and placeholder text
struct InlineArgumentChip: View {
    let argument: InlineArgument
    @Binding var value: String
    let isFocused: Bool
    let onTab: () -> Void
    let onSubmit: () -> Void
    
    @FocusState private var textFieldFocused: Bool
    
    var body: some View {
        Group {
            if argument.isPassword {
                SecureField(argument.placeholder, text: $value)
                    .focused($textFieldFocused)
                    .onSubmit(onSubmit)
            } else {
                TextField(argument.placeholder, text: $value)
                    .focused($textFieldFocused)
                    .onSubmit(onSubmit)
            }
        }
        .textFieldStyle(.plain)
        .font(.system(size: 16, weight: .regular))
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(minWidth: 120)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(
                    isFocused ? Color(hex: "#3B86F7") : Color.white.opacity(0.15),
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
        .onChange(of: isFocused) { newValue in
            // Use async to ensure focus change happens after view update
            if newValue {
                DispatchQueue.main.async {
                    textFieldFocused = true
                }
            } else {
                textFieldFocused = false
            }
        }
        .onAppear {
            if isFocused {
                // Slight delay to ensure view is fully rendered
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    textFieldFocused = true
                }
            }
        }
    }
}

/// Extension for viewing the chip with a locked item prefix
struct LockedItemChip: View {
    let title: String
    let icon: String?
    let iconData: Data?
    
    var body: some View {
        HStack(spacing: 6) {
            // Icon
            if let iconData = iconData, let nsImage = NSImage(data: iconData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
            } else if let icon = icon {
                if icon.count <= 2 && icon.first?.isEmoji == true {
                    Text(icon)
                        .font(.system(size: 14))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#3B86F7"))
                }
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(0.12))
        )
    }
}

// Helper extension
private extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack {
            LockedItemChip(title: "testnode", icon: "🤖", iconData: nil)
            InlineArgumentChip(
                argument: InlineArgument(position: 1, placeholder: "Argument 1"),
                value: .constant(""),
                isFocused: true,
                onTab: {},
                onSubmit: {}
            )
        }
        .padding()
        .background(Color(hex: "#1a1a1a"))
    }
}
