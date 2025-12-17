import Foundation
import GRDB

public struct WindowSnappingShortcut: Codable, Equatable, FetchableRecord, PersistableRecord {
    public var id: Int64?
    public var action: String  // WindowAction raw value
    public var keyCode: UInt32
    public var modifiers: UInt32  // cmdKey, optionKey, controlKey, shiftKey
    public var isEnabled: Bool
    
    // GRDB table definition
    public static let databaseTableName = "window_snapping_shortcuts"
    
    // Computed properties
    public var windowAction: WindowAction? {
        WindowAction(rawValue: action)
    }
    
    public var displayName: String {
        windowAction?.displayName ?? action
    }
    
    public var shortcutString: String {
        KeyCodeMapper.format(keyCode: keyCode, modifiers: modifiers)
    }
    
    // Initializer
    public init(
        id: Int64? = nil,
        action: String,
        keyCode: UInt32,
        modifiers: UInt32,
        isEnabled: Bool
    ) {
        self.id = id
        self.action = action
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isEnabled = isEnabled
    }
}

// MARK: - Table Creation

extension WindowSnappingShortcut {
    public static func createTable(in db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("action", .text).notNull().unique()
            t.column("keyCode", .integer).notNull()
            t.column("modifiers", .integer).notNull()
            t.column("isEnabled", .boolean).notNull().defaults(to: true)
        }
    }
}
