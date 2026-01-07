import Foundation
import GRDB

/// Repository for ClipboardItem CRUD operations
/// Follows the repository pattern used by WindowSnappingShortcutRepository
public class ClipboardItemRepository {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    // MARK: - Queries
    
    /// Fetch all items, pinned first, then by timestamp descending
    public func fetchAll() throws -> [ClipboardItem] {
        try dbQueue.read { db in
            try ClipboardItem
                .order(Column("isPinned").desc, Column("timestamp").desc)
                .fetchAll(db)
        }
    }
    
    /// Fetch items with pagination
    public func fetchRecent(limit: Int, offset: Int = 0) throws -> [ClipboardItem] {
        try dbQueue.read { db in
            try ClipboardItem
                .order(Column("isPinned").desc, Column("timestamp").desc)
                .limit(limit, offset: offset)
                .fetchAll(db)
        }
    }
    
    /// Fetch items by type
    public func fetchByType(_ type: ClipboardItem.ContentType) throws -> [ClipboardItem] {
        try dbQueue.read { db in
            try ClipboardItem
                .filter(Column("type") == type.rawValue)
                .order(Column("isPinned").desc, Column("timestamp").desc)
                .fetchAll(db)
        }
    }
    
    /// Fetch a single item by ID
    public func fetch(byId id: UUID) throws -> ClipboardItem? {
        try dbQueue.read { db in
            try ClipboardItem.fetchOne(db, key: id)
        }
    }
    
    /// Find item by content hash (for deduplication)
    public func findByHash(_ hash: String) throws -> ClipboardItem? {
        try dbQueue.read { db in
            try ClipboardItem
                .filter(Column("contentHash") == hash)
                .fetchOne(db)
        }
    }
    
    /// Search items by text content or OCR text
    public func search(query: String) throws -> [ClipboardItem] {
        let pattern = "%\(query.lowercased())%"
        
        return try dbQueue.read { db in
            try ClipboardItem
                .filter(
                    Column("textContent").like(pattern).collating(.nocase) ||
                    Column("imageOCRText").like(pattern).collating(.nocase)
                )
                .order(Column("isPinned").desc, Column("timestamp").desc)
                .fetchAll(db)
        }
    }
    
    /// Fetch oldest unpinned items for FIFO eviction
    public func fetchOldestUnpinned(limit: Int) throws -> [ClipboardItem] {
        try dbQueue.read { db in
            try ClipboardItem
                .filter(Column("isPinned") == false)
                .order(Column("timestamp").asc)
                .limit(limit)
                .fetchAll(db)
        }
    }
    
    // MARK: - Counts
    
    /// Total item count
    public func count() throws -> Int {
        try dbQueue.read { db in
            try ClipboardItem.fetchCount(db)
        }
    }
    
    /// Count of unpinned items only
    public func countUnpinned() throws -> Int {
        try dbQueue.read { db in
            try ClipboardItem
                .filter(Column("isPinned") == false)
                .fetchCount(db)
        }
    }
    
    // MARK: - Mutations
    
    /// Insert a new item
    public func insert(_ item: ClipboardItem) throws {
        try dbQueue.write { db in
            var mutableItem = item
            try mutableItem.insert(db)
        }
    }
    
    /// Update an existing item
    public func update(_ item: ClipboardItem) throws {
        try dbQueue.write { db in
            try item.update(db)
        }
    }
    
    /// Toggle pin status for an item
    public func togglePin(id: UUID) throws {
        try dbQueue.write { db in
            guard var item = try ClipboardItem.fetchOne(db, key: id) else {
                return
            }
            item.isPinned.toggle()
            try item.update(db)
        }
    }
    
    /// Delete an item by ID
    public func delete(id: UUID) throws {
        _ = try dbQueue.write { db in
            try ClipboardItem.deleteOne(db, key: id)
        }
    }
    
    /// Delete all items, optionally keeping pinned items
    public func deleteAll(exceptPinned: Bool) throws {
        try dbQueue.write { db in
            if exceptPinned {
                try ClipboardItem
                    .filter(Column("isPinned") == false)
                    .deleteAll(db)
            } else {
                try ClipboardItem.deleteAll(db)
            }
        }
    }
    
    /// Delete multiple items by IDs
    public func delete(ids: [UUID]) throws {
        try dbQueue.write { db in
            try ClipboardItem
                .filter(ids.contains(Column("id")))
                .deleteAll(db)
        }
    }
}
