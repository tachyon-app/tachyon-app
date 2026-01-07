import Foundation
import AppKit
import GRDB

/// Main coordinator for clipboard history functionality
/// Exposes all clipboard-related operations to the UI layer
@MainActor
public class ClipboardHistoryManager: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = ClipboardHistoryManager()
    
    // MARK: - Published State
    
    @Published public private(set) var items: [ClipboardItem] = []
    @Published public private(set) var isEnabled: Bool = true
    @Published public var maxItems: Int = ClipboardMonitorConfig.defaultMaxItems
    @Published public var isUnlimited: Bool = false
    @Published public var searchQuery: String = ""
    @Published public var typeFilter: ContentTypeFilter = .all
    
    // MARK: - Private Properties
    
    private var repository: ClipboardItemRepository?
    private var monitorService: ClipboardMonitorService?
    private let fuzzyMatcher = FuzzyMatcher()
    
    // MARK: - Computed Properties
    
    /// Filtered items based on search query and type filter
    public var filteredItems: [ClipboardItem] {
        var result = items
        
        // Apply type filter
        if typeFilter != .all {
            result = result.filter { $0.type == typeFilter.contentType }
        }
        
        // Apply search filter
        if !searchQuery.isEmpty {
            result = result.compactMap { item -> (ClipboardItem, Double)? in
                let searchText = item.textContent ?? item.imageOCRText ?? item.previewText
                let score = fuzzyMatcher.score(query: searchQuery, target: searchText)
                return score > 0 ? (item, score) : nil
            }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
        }
        
        return result
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    /// Initialize the manager with a database connection
    public func initialize(dbQueue: DatabaseQueue) {
        repository = ClipboardItemRepository(dbQueue: dbQueue)
        
        guard let repository = repository else { return }
        
        // Create monitor service
        monitorService = ClipboardMonitorService(
            repository: repository,
            maxItems: maxItems,
            isUnlimited: isUnlimited
        )
        
        // Set up callback for new items or updates
        monitorService?.onItemCaptured = { [weak self] item in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // Check if item already exists (for updates like OCR)
                if let index = self.items.firstIndex(where: { $0.id == item.id }) {
                    self.items[index] = item
                } else {
                    self.items.insert(item, at: 0)
                }
            }
        }
        
        // Load existing items
        refreshItems()
    }
    
    // MARK: - Public API
    
    /// Start clipboard monitoring
    public func startMonitoring() {
        guard isEnabled else { return }
        monitorService?.start()
    }
    
    /// Stop clipboard monitoring
    public func stopMonitoring() {
        monitorService?.stop()
    }
    
    /// Enable or disable clipboard history
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if enabled {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }
    
    /// Refresh items from database
    public func refreshItems() {
        guard let repository = repository else { return }
        
        do {
            items = try repository.fetchAll()
        } catch {
            print("📋 Failed to fetch items: \(error)")
        }
    }
    
    /// Copy an item to the system clipboard
    public func copyItem(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.type {
        case .text, .code, .link:
            if let text = item.textContent {
                pasteboard.setString(text, forType: .string)
            }
            
        case .image:
            if let imagePath = item.imagePath,
               let imageData = try? Data(contentsOf: URL(fileURLWithPath: imagePath)),
               let image = NSImage(data: imageData) {
                pasteboard.writeObjects([image])
            }
            
        case .file:
            if let paths = item.filePaths {
                let urls = paths.map { URL(fileURLWithPath: $0) }
                pasteboard.writeObjects(urls as [NSURL])
            }
        }
        

    }
    
    /// Paste an item (copy to clipboard and simulate Cmd+V)
    public func pasteItem(_ item: ClipboardItem) {
        // First, copy to clipboard
        copyItem(item)
        
        // Then simulate paste keystroke
        simulatePasteKeystroke()
    }
    
    /// Toggle pin status for an item
    public func togglePin(_ item: ClipboardItem) {
        guard let repository = repository else { return }
        
        do {
            try repository.togglePin(id: item.id)
            refreshItems()
        } catch {
            print("📋 Failed to toggle pin: \(error)")
        }
    }
    
    /// Delete a single item
    public func deleteItem(_ item: ClipboardItem) {
        guard let repository = repository else { return }
        
        do {
            // Delete image file if exists
            if let imagePath = item.imagePath {
                try? FileManager.default.removeItem(atPath: imagePath)
            }
            
            try repository.delete(id: item.id)
            refreshItems()
        } catch {
            print("📋 Failed to delete item: \(error)")
        }
    }
    
    /// Clear all history (except pinned items if specified)
    public func clearHistory(exceptPinned: Bool = true) {
        guard let repository = repository else { return }
        
        do {
            // Delete image files for items that will be removed
            let itemsToDelete = exceptPinned ? items.filter { !$0.isPinned } : items
            for item in itemsToDelete {
                if let imagePath = item.imagePath {
                    try? FileManager.default.removeItem(atPath: imagePath)
                }
            }
            
            try repository.deleteAll(exceptPinned: exceptPinned)
            refreshItems()

        } catch {
            print("📋 Failed to clear history: \(error)")
        }
    }
    
    /// Update settings
    public func updateSettings(maxItems: Int, isUnlimited: Bool) {
        self.maxItems = maxItems
        self.isUnlimited = isUnlimited
        monitorService?.updateSettings(maxItems: maxItems, isUnlimited: isUnlimited)
    }
    
    // MARK: - Private Methods
    
    private func simulatePasteKeystroke() {
        // Use CGEvent to simulate Cmd+V
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // Key code 9 is "V"
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        
        // Small delay before key up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
            keyUp?.flags = .maskCommand
            keyUp?.post(tap: .cghidEventTap)
        }
    }
}

// MARK: - Content Type Filter

public enum ContentTypeFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case text = "Text"
    case code = "Code"
    case image = "Images"
    case file = "Files"
    
    public var id: String { rawValue }
    
    var contentType: ClipboardItem.ContentType? {
        switch self {
        case .all: return nil
        case .text: return .text
        case .code: return .code
        case .image: return .image
        case .file: return .file
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "tray.full"
        case .text: return "doc.text"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .image: return "photo"
        case .file: return "folder"
        }
    }
}
