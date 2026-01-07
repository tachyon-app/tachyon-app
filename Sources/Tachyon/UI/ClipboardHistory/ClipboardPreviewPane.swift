import SwiftUI

/// Preview pane for displaying detailed content of selected clipboard item
/// Shows different previews based on content type
struct ClipboardPreviewPane: View {
    let item: ClipboardItem?
    
    var body: some View {
        Group {
            if let item = item {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    previewHeader(for: item)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Content
                    ScrollView {
                        previewContent(for: item)
                            .padding(16)
                    }
                }
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#1C1C1E"))
    }
    
    // MARK: - Preview Header
    
    @ViewBuilder
    private func previewHeader(for item: ClipboardItem) -> some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: item.typeIcon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(typeColor(for: item))
            
            VStack(alignment: .leading, spacing: 2) {
                // Type label
                HStack(spacing: 8) {
                    Text(typeLabel(for: item))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.white)
                    
                    if item.isPinned {
                        Label("Pinned", systemImage: "pin.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "#FF9500"))
                    }
                }
                
                // Timestamp
                Text(item.relativeTimestamp)
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.5))
            }
            
            Spacer()
            
            // Source app (if available)
            if let sourceApp = item.sourceApp {
                Text(appName(from: sourceApp))
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.4))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(4)
            }
        }
        .padding(16)
    }
    
    // MARK: - Preview Content
    
    @ViewBuilder
    private func previewContent(for item: ClipboardItem) -> some View {
        switch item.type {
        case .text:
            textPreview(item.textContent ?? "")
            
        case .code:
            codePreview(item.textContent ?? "", language: item.codeLanguage)
            
        case .image:
            imagePreview(for: item)
            
        case .file:
            filePreview(item.filePaths ?? [])
            
        case .link:
            linkPreview(for: item)
        }
    }
    
    // MARK: - Text Preview
    
    @ViewBuilder
    private func textPreview(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(Color.white.opacity(0.9))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    
    // MARK: - Link Preview
    
    @ViewBuilder
    private func linkPreview(for item: ClipboardItem) -> some View {
        VStack(spacing: 16) {
            // Thumbnail
            if let path = item.imagePath,
               let image = NSImage(contentsOfFile: path) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            } else {
                // Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.05))
                        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 150)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "safari")
                            .font(.system(size: 40))
                            .foregroundColor(Color.white.opacity(0.2))
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Title
                if let title = item.urlTitle, !title.isEmpty {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // URL
                if let url = item.textContent {
                    HStack(spacing: 6) {
                         Image(systemName: "link")
                             .font(.system(size: 11))
                         Text(url)
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .foregroundColor(Color(hex: "#0A84FF"))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color(hex: "#0A84FF").opacity(0.1))
                    .cornerRadius(6)
                    .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
    }

    // MARK: - Code Preview
    
    @ViewBuilder
    private func codePreview(_ code: String, language: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Language badge
            if let lang = language {
                Text(lang.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "#34C759"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#34C759").opacity(0.15))
                    .cornerRadius(4)
            }
            
            // Code block
            Text(code)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.9))
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
        }
    }
    
    // MARK: - Image Preview
    
    @ViewBuilder
    private func imagePreview(for item: ClipboardItem) -> some View {
        VStack(spacing: 20) {
            if let path = item.imagePath,
               let image = NSImage(contentsOfFile: path) {
                VStack(spacing: 12) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .cornerRadius(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    // Image info
                    HStack {
                        Text("\(Int(image.size.width)) × \(Int(image.size.height))")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.5))
                        
                        Spacer()
                        
                        if let fileSize = fileSizeString(for: path) {
                            Text(fileSize)
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundColor(Color.white.opacity(0.3))
                    
                    Text("Image not available")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity, minHeight: 150)
            }
            
            // Recognized Text (OCR)
            if let ocrText = item.imageOCRText, !ocrText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "text.viewfinder")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#FF9500"))
                        
                        Text("RECOGNIZED TEXT")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.6))
                        
                        Spacer()
                    }
                    
                    Text(ocrText)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.8))
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                }
            }
        }
    }
    
    // MARK: - File Preview
    
    @ViewBuilder
    private func filePreview(_ paths: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(paths.prefix(10), id: \.self) { path in
                HStack(spacing: 10) {
                    Image(systemName: fileIcon(for: path))
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#007AFF"))
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(URL(fileURLWithPath: path).lastPathComponent)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.9))
                            .lineLimit(1)
                        
                        Text(URL(fileURLWithPath: path).deletingLastPathComponent().path)
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.4))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if let size = fileSizeString(for: path) {
                        Text(size)
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }
                .padding(10)
                .background(Color.white.opacity(0.03))
                .cornerRadius(6)
            }
            
            if paths.count > 10 {
                Text("+ \(paths.count - 10) more files")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.5))
                    .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(Color.white.opacity(0.2))
            
            Text("Select an item to preview")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    
    private func typeLabel(for item: ClipboardItem) -> String {
        switch item.type {
        case .text: return "Text"
        case .code: return "Code"
        case .link: return "Link"
        case .image: return "Image"
        case .file: return item.filePaths?.count == 1 ? "File" : "Files"
        }
    }
    
    private func typeColor(for item: ClipboardItem) -> Color {
        switch item.type {
        case .text: return Color(hex: "#8E8E93")
        case .code: return Color(hex: "#34C759")
        case .link: return Color(hex: "#0A84FF")
        case .image: return Color(hex: "#FF9500")
        case .file: return Color(hex: "#007AFF")
        }
    }
    
    private func appName(from bundleId: String) -> String {
        // Extract app name from bundle ID
        let components = bundleId.split(separator: ".")
        return components.last.map(String.init) ?? bundleId
    }
    
    private func fileSizeString(for path: String) -> String? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attrs[.size] as? Int64 else {
            return nil
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    private func fileIcon(for path: String) -> String {
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.fill"
        case "doc", "docx": return "doc.text.fill"
        case "xls", "xlsx": return "tablecells.fill"
        case "ppt", "pptx": return "rectangle.fill.on.rectangle.fill"
        case "zip", "rar", "7z": return "archivebox.fill"
        case "jpg", "jpeg", "png", "gif", "webp": return "photo.fill"
        case "mp4", "mov", "avi": return "play.rectangle.fill"
        case "mp3", "wav", "aac": return "music.note"
        default: return "doc.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 0) {
        Color.gray.frame(width: 300)
        
        ClipboardPreviewPane(
            item: ClipboardItem(
                type: .code,
                contentHash: "preview123",
                textContent: """
                func greet(name: String) {
                    print("Hello, \\(name)!")
                }
                
                greet(name: "World")
                """,
                sourceApp: "com.apple.Xcode",
                codeLanguage: "swift"
            )
        )
    }
    .frame(width: 700, height: 400)
}
