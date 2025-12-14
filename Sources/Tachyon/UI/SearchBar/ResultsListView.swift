import SwiftUI

/// List of search results
struct ResultsListView: View {
    let results: [QueryResult]
    let selectedIndex: Int
    let onSelect: (Int) -> Void
    let onExecute: (QueryResult) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) { // Removed spacing for cleaner look
                ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                    ResultRowView(
                        result: result,
                        isSelected: index == selectedIndex
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onExecute(result)
                    }
                    .onHover { hovering in
                        if hovering {
                            onSelect(index)
                        }
                    }
                }
            }
            .padding(6)
        }
        // Calculate height: ~62 per row + padding
        // Limit to max ~6.5 items (400px)
        .frame(height: min(CGFloat(results.count) * 62 + 12, 400))
        .scrollIndicators(.hidden)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

/// Individual result row
struct ResultRowView: View {
    let result: QueryResult
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
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
                     // Fallback for broken paths
                     Image(systemName: "doc.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                 }
            } else if let icon = result.icon {
                // Fixed: Use Image(systemName:) instead of Text(icon)
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(width: 32, height: 32)
            }
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                
                if let subtitle = result.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        // Ensure high contrast for selection
        .padding(.horizontal, 4)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}
