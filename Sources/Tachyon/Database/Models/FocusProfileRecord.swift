import Foundation
import GRDB

public struct FocusProfileRecord: Codable, FetchableRecord, PersistableRecord, Identifiable {
    public var id: UUID
    public var name: String
    public var isMusicEnabled: Bool
    public var lastDuration: TimeInterval
    public var prefersStatusBar: Bool
    public var borderSettings: FocusBorderSettings // Stored as JSON
    public var createdAt: Date
    public var updatedAt: Date
    public var isDefault: Bool
    
    public static let databaseTableName = "focus_profiles"
    
    public init(
        id: UUID = UUID(),
        name: String,
        isMusicEnabled: Bool = true,
        lastDuration: TimeInterval = 1500,
        prefersStatusBar: Bool = false,
        borderSettings: FocusBorderSettings = FocusBorderSettings(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.isMusicEnabled = isMusicEnabled
        self.lastDuration = lastDuration
        self.prefersStatusBar = prefersStatusBar
        self.borderSettings = borderSettings
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDefault = isDefault
    }
}

extension FocusProfileRecord {
    public static func createTable(in db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("name", .text).notNull()
            t.column("isMusicEnabled", .boolean).notNull().defaults(to: true)
            t.column("lastDuration", .double).notNull().defaults(to: 1500)
            t.column("prefersStatusBar", .boolean).notNull().defaults(to: false)
            t.column("borderSettings", .jsonText).notNull() // Stores JSON serialization of FocusBorderSettings
            t.column("createdAt", .datetime).notNull()
            t.column("updatedAt", .datetime).notNull()
            t.column("isDefault", .boolean).notNull().defaults(to: false)
        }
    }
}
