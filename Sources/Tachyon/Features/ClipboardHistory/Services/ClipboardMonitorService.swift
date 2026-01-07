import Foundation
import AppKit
import GRDB

/// Service responsible for monitoring the system clipboard for changes
/// Uses polling since macOS does not provide native clipboard change notifications
@MainActor
public class ClipboardMonitorService: ObservableObject {
    
    // MARK: - Published State
    
    @Published public private(set) var isMonitoring: Bool = false
    @Published public private(set) var lastCaptureTime: Date?
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let repository: ClipboardItemRepository
    private var maxItems: Int
    private var isUnlimited: Bool
    
    // Callback for when new item is captured - for UI refresh
    public var onItemCaptured: ((ClipboardItem) -> Void)?
    
    // MARK: - Initialization
    
    public init(repository: ClipboardItemRepository, maxItems: Int = ClipboardMonitorConfig.defaultMaxItems, isUnlimited: Bool = false) {
        self.repository = repository
        self.maxItems = maxItems
        self.isUnlimited = isUnlimited
    }
    
    // MARK: - Public API
    
    /// Start monitoring the clipboard for changes
    public func start() {
        guard !isMonitoring else { return }
        
        lastChangeCount = NSPasteboard.general.changeCount
        
        // Create timer on main run loop
        timer = Timer.scheduledTimer(withTimeInterval: ClipboardMonitorConfig.pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkClipboard()
            }
        }
        
        isMonitoring = true

    }
    
    /// Stop monitoring the clipboard
    public func stop() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false

    }
    
    /// Update max items setting
    public func updateSettings(maxItems: Int, isUnlimited: Bool) {
        self.maxItems = maxItems
        self.isUnlimited = isUnlimited
    }
    
    // MARK: - Private Methods
    
    private func checkClipboard() {
        let currentCount = NSPasteboard.general.changeCount
        
        // Only process if clipboard has changed
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount
        
        // Process the new clipboard content
        processClipboardContent()
    }
    
    private func processClipboardContent() {
        let pasteboard = NSPasteboard.general
        
        // Determine content type and extract data
        // Priority: File > Image > Text
        if let item = extractFileContent(from: pasteboard) {
            saveItem(item)
        } else if let item = extractImageContent(from: pasteboard) {
            saveItem(item)
        } else if let item = extractTextContent(from: pasteboard) {
            saveItem(item)
        }
    }
    
    // MARK: - Content Extraction
    
    private func extractTextContent(from pasteboard: NSPasteboard) -> ClipboardItem? {
        guard let text = pasteboard.string(forType: .string) else { return nil }
        
        // Check size limit
        guard text.count <= ClipboardMonitorConfig.maxTextLength else {

            return nil
        }
        
        // Check for sensitive data
        if SensitiveDataDetector.containsSensitiveData(text) {

            return nil
        }
        
        // Generate content hash for deduplication
        let hash = ClipboardItem.generateHash(for: text)
        
        // Check for duplicates
        if let existing = try? repository.findByHash(hash) {

            // Update timestamp of existing item instead
            updateTimestamp(for: existing)
            return nil
        }
        
        // Detect content type (code vs plain text)
        let (type, codeLanguage) = ContentTypeDetector.inferType(for: text)
        
        // Get source app bundle ID
        let sourceApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        
        return ClipboardItem(
            type: type,
            contentHash: hash,
            textContent: text,
            sourceApp: sourceApp,
            codeLanguage: codeLanguage
        )
    }
    
    private func extractImageContent(from pasteboard: NSPasteboard) -> ClipboardItem? {
        // Try to get image data
        guard let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) else {
            return nil
        }
        
        // Check size limit
        guard imageData.count <= ClipboardMonitorConfig.maxImageSize else {

            return nil
        }
        
        // Generate content hash for deduplication
        let hash = ClipboardItem.generateHash(for: imageData)
        
        // Check for duplicates
        if let existing = try? repository.findByHash(hash) {

            updateTimestamp(for: existing)
            return nil
        }
        
        // Get source app bundle ID
        let sourceApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        
        // For now, store the image path as a placeholder
        // TODO: Implement encrypted image storage
        let imagePath = storeImage(data: imageData, hash: hash)
        
        // TODO: Run OCR asynchronously
        // let ocrText = await OCRService.extractText(from: image)
        
        return ClipboardItem(
            type: .image,
            contentHash: hash,
            imagePath: imagePath,
            imageOCRText: nil, // TODO: Add OCR
            sourceApp: sourceApp
        )
    }
    
    private func extractFileContent(from pasteboard: NSPasteboard) -> ClipboardItem? {
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return nil
        }
        
        // Filter to file URLs only
        let filePaths = urls.filter { $0.isFileURL }.map { $0.path }
        
        guard !filePaths.isEmpty else { return nil }
        
        // Check file count limit
        guard filePaths.count <= ClipboardMonitorConfig.maxFilePaths else {

            return nil
        }
        
        // Generate content hash from sorted file paths
        let pathsString = filePaths.sorted().joined(separator: "|")
        let hash = ClipboardItem.generateHash(for: pathsString)
        
        // Check for duplicates
        if let existing = try? repository.findByHash(hash) {

            updateTimestamp(for: existing)
            return nil
        }
        
        // Get source app bundle ID
        let sourceApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        
        return ClipboardItem(
            type: .file,
            contentHash: hash,
            filePaths: filePaths,
            sourceApp: sourceApp
        )
    }
    
    // MARK: - Storage Helpers
    
    private func saveItem(_ item: ClipboardItem) {
        do {
            try repository.insert(item)
            lastCaptureTime = Date()

            
            // Trigger OCR if it's an image
            if item.type == .image, let imagePath = item.imagePath {
                Task {
                    await performOCR(for: item, imagePath: imagePath)
                }
            }
            
            // Trigger Metadata Fetch if it's a link
            if item.type == .link, let urlString = item.textContent, let url = URL(string: urlString) {
                Task {
                    await fetchLinkMetadata(for: item, url: url)
                }
            }
            
            // Enforce history limit (FIFO eviction)
            if !isUnlimited {
                try enforceLimit()
            }
            
            // Notify listeners
            onItemCaptured?(item)
        } catch {
            print("📋 Failed to save clipboard item: \(error)")
        }
    }
    
    private func performOCR(for item: ClipboardItem, imagePath: String) async {
        guard let image = NSImage(contentsOfFile: imagePath) else { return }
        
        print("🔍 Starting OCR for item \(item.id)")
        if let text = await OCRService.extractText(from: image) {
            print("✅ OCR successful: found \(text.count) chars")
            // Update item with OCR text
            var updatedItem = item
            updatedItem.imageOCRText = text
            
            do {
                try repository.update(updatedItem)
                
                // Notify listeners of update (MainActor)
                await MainActor.run {
                    onItemCaptured?(updatedItem)
                }
            } catch {
                print("❌ Failed to update item with OCR text: \(error)")
            }
        } else {
            print("⚠️ OCR found no text")
        }
    }
    
    private func fetchLinkMetadata(for item: ClipboardItem, url: URL) async {
        do {
            let (title, image) = try await LinkMetadataService.shared.fetchMetadata(for: url)
            
            var updatedItem = item
            updatedItem.urlTitle = title
            
            if let image = image, let tiffData = image.tiffRepresentation {
                // Generate a unique hash for the thumbnail image
                // We combine item hash with "thumbnail" to differentiate
                let thumbHash = ClipboardItem.generateHash(for: (item.contentHash + "_thumbnail").data(using: .utf8)!)
                updatedItem.imagePath = storeImage(data: tiffData, hash: thumbHash)
            }
            
            try repository.update(updatedItem)
            
            await MainActor.run {
                onItemCaptured?(updatedItem)
            }
        } catch {
            // Metadata fetch failure is expected for some URLs, silent fail or log
            print("⚠️ Failed to fetch metadata for URL: \(error.localizedDescription)")
        }
    }
    
    private func updateTimestamp(for item: ClipboardItem) {
        var updated = item
        updated.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        try? repository.update(updated)
    }
    
    private func enforceLimit() throws {
        let currentCount = try repository.countUnpinned()
        guard currentCount > maxItems else { return }
        
        let toRemove = currentCount - maxItems
        let oldest = try repository.fetchOldestUnpinned(limit: toRemove)
        
        for item in oldest {
            // Delete associated image file if exists
            if let imagePath = item.imagePath {
                try? FileManager.default.removeItem(atPath: imagePath)
            }
            try repository.delete(id: item.id)
        }
    }
    
    private func storeImage(data: Data, hash: String) -> String? {
        let fileManager = FileManager.default
        let homeUrl = fileManager.homeDirectoryForCurrentUser
        let storageUrl = homeUrl
            .appendingPathComponent(".tachyon")
            .appendingPathComponent(ClipboardMonitorConfig.imageStorageDirectory)
        
        // Create directory if needed
        try? fileManager.createDirectory(at: storageUrl, withIntermediateDirectories: true)
        
        // Use hash as filename
        let fileUrl = storageUrl.appendingPathComponent("\(hash.prefix(16)).png")
        
        // Convert to PNG if needed and save
        if let image = NSImage(data: data),
           let pngData = image.pngRepresentation {
            do {
                try pngData.write(to: fileUrl)
                return fileUrl.path
            } catch {
                print("📋 Failed to save image: \(error)")
                return nil
            }
        }
        
        return nil
    }
}

// MARK: - NSImage Extension

extension NSImage {
    var pngRepresentation: Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }
}
