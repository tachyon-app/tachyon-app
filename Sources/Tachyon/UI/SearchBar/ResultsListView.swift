import SwiftUI

/// List of search results with premium dark design
struct ResultsListView: View {
    let results: [QueryResult]
    let selectedIndex: Int
    let onSelect: (Int) -> Void
    let onExecute: (QueryResult) -> Void
    
    @State private var isUsingKeyboard = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                        ResultRowView(
                            result: result,
                            isSelected: index == selectedIndex,
                            allowHover: !isUsingKeyboard
                        )
                        .id(index) // Important for ScrollViewReader
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isUsingKeyboard = false // Mouse click
                            onExecute(result)
                        }
                        .onHover { hovering in
                            if hovering && !isUsingKeyboard {
                                onSelect(index)
                            }
                        }
                    }
                }
            }
            .frame(height: min(CGFloat(results.count) * 56, 448)) // 8 rows max
            .scrollIndicators(.hidden)
            .onChange(of: selectedIndex) { newIndex in
                // Mark that keyboard is being used
                isUsingKeyboard = true
                
                // Scroll to selected item WITHOUT animation (prevents flicker)
                proxy.scrollTo(newIndex, anchor: .center)
                
                // Reset keyboard flag after a delay (allow mouse again)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isUsingKeyboard = false
                }
            }
        }
    }
}

/// Individual result row with purple branding
struct ResultRowView: View {
    let result: QueryResult
    let isSelected: Bool
    let allowHover: Bool
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            if let iconData = result.iconData, let image = NSImage(data: iconData) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            } else if let iconPath = result.iconPath {
                if iconPath.hasSuffix(".app") {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: iconPath))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                } else if let image = NSImage(contentsOfFile: iconPath) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.white.opacity(0.6))
                        .frame(width: 32, height: 32)
                }
            } else if let icon = result.icon {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(width: 32, height: 32)
            }
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                if let subtitle = result.subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.6))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Spacer()
            
            // Shortcut hint (only for selected)
            if isSelected {
                Text("⌘ ↵")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                // Hover state (only if allowed)
                if isHovered && !isSelected && allowHover {
                    Color.white.opacity(0.05)
                }
                
                // Selected state with purple
                if isSelected {
                    HStack(spacing: 0) {
                        // Blue left border
                        Rectangle()
                            .fill(Color(hex: "#3B86F7"))
                            .frame(width: 3)
                        
                        // Blue background
                        Color(hex: "#3B86F7")
                            .opacity(0.15)
                    }
                }
            }
        )
        .onHover { hovering in
            if allowHover {
                withAnimation(.easeOut(duration: 0.1)) {
                    isHovered = hovering
                }
            }
        }
        .animation(.easeOut(duration: 0.08), value: isSelected)
    }
}
