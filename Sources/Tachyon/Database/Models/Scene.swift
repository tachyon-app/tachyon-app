import Foundation
import GRDB

/// Represents a recorded window layout scene
public struct WindowScene: Codable, Equatable, Identifiable, FetchableRecord, PersistableRecord {
    public var id: UUID
    public var name: String
    public var displayCount: Int           // Number of displays when recorded
    public var targetDisplayIndex: Int?    // nil = Full Workspace, 0+ = specific display
    public var shortcutKeyCode: UInt32?
    public var shortcutModifiers: UInt32?
    public var isEnabled: Bool
    public var createdAt: Date
    
    // GRDB table definition
    public static let databaseTableName = "scenes"
    
    // GRDB relation to SceneWindow with explicit foreign key
    public static let windows = hasMany(SceneWindow.self, using: ForeignKey(["sceneId"]))
    public var windows: QueryInterfaceRequest<SceneWindow> {
        request(for: WindowScene.windows)
    }
    
    // Computed properties
    public var displayName: String {
        name.isEmpty ? "Untitled Scene" : name
    }
    
    public var isFullWorkspace: Bool {
        targetDisplayIndex == nil
    }
    
    public var shortcutString: String? {
        guard let keyCode = shortcutKeyCode, let modifiers = shortcutModifiers else {
            return nil
        }
        return KeyCodeMapper.format(keyCode: keyCode, modifiers: modifiers)
    }
    
    // Initializer
    public init(
        id: UUID = UUID(),
        name: String,
        displayCount: Int,
        targetDisplayIndex: Int? = nil,
        shortcutKeyCode: UInt32? = nil,
        shortcutModifiers: UInt32? = nil,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.displayCount = displayCount
        self.targetDisplayIndex = targetDisplayIndex
        self.shortcutKeyCode = shortcutKeyCode
        self.shortcutModifiers = shortcutModifiers
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
}

// MARK: - Table Creation

extension WindowScene {
    public static func createTable(in db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("name", .text).notNull()
            t.column("displayCount", .integer).notNull()
            t.column("targetDisplayIndex", .integer)
            t.column("shortcutKeyCode", .integer)
            t.column("shortcutModifiers", .integer)
            t.column("isEnabled", .boolean).notNull().defaults(to: true)
            t.column("createdAt", .datetime).notNull()
        }
    }
}
