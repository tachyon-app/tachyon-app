import Foundation
import GRDB

public class StorageManager {
    public static let shared = StorageManager()
    
    public var dbQueue: DatabaseQueue?
    
    private init() {
        try? setupDatabase()
    }
    
    public func setupInMemoryDatabase() throws {
        // Create in-memory database queue
        var config = Configuration()
        config.prepareDatabase { db in
            db.trace { print("SQL: \($0)") }
        }
        dbQueue = try DatabaseQueue(configuration: config) // In-memory
        try migrator.migrate(dbQueue!)
    }
    
    private func setupDatabase() throws {
        let fileManager = FileManager.default
        let homeUrl = fileManager.homeDirectoryForCurrentUser
        let appSupportUrl = homeUrl.appendingPathComponent(".tachyon")
        
        // Create directory if not exists
        try fileManager.createDirectory(at: appSupportUrl, withIntermediateDirectories: true)
        
        let dbUrl = appSupportUrl.appendingPathComponent("tachyon.db")
        
        var config = Configuration()
        config.prepareDatabase { db in
            db.trace { print("SQL: \($0)") }
        }
        
        dbQueue = try DatabaseQueue(path: dbUrl.path, configuration: config)
        
        try migrator.migrate(dbQueue!)
    }
    
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("v1") { [weak self] db in
            try db.create(table: "search_engines") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("keyword", .text).notNull()
                t.column("urlTemplate", .text).notNull()
                t.column("icon", .blob)
            }
            
            // Seed default data
            try self?.seedDefaults(db)
        }
        
        migrator.registerMigration("v2") { db in
            try db.create(table: "custom_links") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("urlTemplate", .text).notNull()
                t.column("icon", .blob)
                t.column("defaults", .jsonText).notNull().defaults(to: "{}")
            }
        }
        
        migrator.registerMigration("v3") { db in
            // Create window snapping shortcuts table
            try WindowSnappingShortcut.createTable(in: db)
            
            // Auto-seed defaults if table is empty
            let count = try WindowSnappingShortcut.fetchCount(db)
            if count == 0 {
                let defaults = WindowSnappingShortcut.defaults
                for var shortcut in defaults {
                    try shortcut.insert(db)
                }
            }
        }
        
        migrator.registerMigration("v4") { db in
            // Create script commands table
            try db.create(table: "script_commands") { t in
                t.column("id", .text).primaryKey()
                t.column("fileName", .text).notNull().unique()
                t.column("title", .text).notNull()
                t.column("packageName", .text)
                t.column("mode", .text).notNull().defaults(to: "fullOutput")
                t.column("icon", .blob)
                t.column("hotkey", .text)
                t.column("refreshTime", .text)
                t.column("isEnabled", .boolean).notNull().defaults(to: true)
                t.column("lastExecuted", .datetime)
                t.column("createdAt", .datetime).notNull()
            }
        }
        
        migrator.registerMigration("v5") { db in
            // Reset window snapping shortcuts to new cycle-through actions
            // Delete all old shortcuts and insert new defaults
            try db.execute(sql: "DELETE FROM window_snapping_shortcuts")
            
            let defaults = WindowSnappingShortcut.defaults
            for var shortcut in defaults {
                try shortcut.insert(db)
            }
        }
        
        migrator.registerMigration("v6") { db in
            // Create clipboard history table
            try ClipboardItem.createTable(in: db)
        }
        
        migrator.registerMigration("v7") { db in
            // Add columns for URL metadata
            try db.alter(table: "clipboard_items") { t in
                t.add(column: "urlTitle", .text)
            }
        }
        
        migrator.registerMigration("v8") { db in
            // Fix multi-monitor shortcuts: modifiers were 6656 (Ctrl+Opt+Shift) 
            // but should be 6400 (Ctrl+Opt+Cmd)
            try db.execute(
                sql: """
                    UPDATE window_snapping_shortcuts 
                    SET modifiers = 6400 
                    WHERE action IN ('nextDisplay', 'previousDisplay') 
                    AND modifiers = 6656
                    """
            )
        }
        
        return migrator
    }
    
    private func seedDefaults(_ db: Database) throws {
        // Define defaults
        let defaults = [
            ("Google", "g", "https://google.com/search?q={{query}}", "google.png"),
            ("GitHub", "gh", "https://github.com/search?q={{query}}", "github.png"),
            ("YouTube", "yt", "https://youtube.com/results?search_query={{query}}", "youtube.png")
        ]
        
        for (name, keyword, template, iconName) in defaults {
            var iconData: Data? = nil
            
            // Try to load icon from bundle resources
            if let path = Bundle.main.path(forResource: iconName, ofType: nil, inDirectory: "Icons") {
                iconData = try? Data(contentsOf: URL(fileURLWithPath: path))
            }
            
            let record = SearchEngineRecord(
                id: UUID(),
                name: name,
                keyword: keyword,
                urlTemplate: template,
                icon: iconData
            )
            
            try record.insert(db)
        }
    }
    
    // MARK: - Public API
    
    public func getAllSearchEngines() throws -> [SearchEngineRecord] {
        return try dbQueue?.read { db in
             try SearchEngineRecord.fetchAll(db)
        } ?? []
    }
    
    public func saveSearchEngine(_ engine: SearchEngineRecord) throws {
        try dbQueue?.write { db in
            try engine.save(db)
        }
    }
    
    public func deleteSearchEngine(id: UUID) throws {
        _ = try dbQueue?.write { db in
            try SearchEngineRecord.deleteOne(db, key: id)
        }
    }
    
    // MARK: - Custom Links
    
    public func getAllCustomLinks() throws -> [CustomLinkRecord] {
        return try dbQueue?.read { db in
             try CustomLinkRecord.fetchAll(db)
        } ?? []
    }
    
    public func saveCustomLink(_ link: CustomLinkRecord) throws {
        try dbQueue?.write { db in
            try link.save(db)
        }
    }
    
    public func deleteCustomLink(id: UUID) throws {
        _ = try dbQueue?.write { db in
            try CustomLinkRecord.deleteOne(db, key: id)
        }
    }
    
    // MARK: - Script Commands
    
    public func getAllScripts() throws -> [ScriptRecord] {
        return try dbQueue?.read { db in
            try ScriptRecord.fetchAll(db)
        } ?? []
    }
    
    public func saveScript(_ script: ScriptRecord) throws {
        try dbQueue?.write { db in
            try script.save(db)
        }
    }
    
    public func deleteScript(id: UUID) throws {
        _ = try dbQueue?.write { db in
            try ScriptRecord.deleteOne(db, key: id)
        }
    }
}
