import Foundation
import GRDB

/// Database record for persisted script commands
public struct ScriptRecord: Codable, Identifiable {
    public var id: UUID
    public var fileName: String           // Filename in ~/.tachyon/scripts/
    public var title: String              // From metadata or user override
    public var packageName: String?
    public var mode: String               // ScriptMode raw value
    public var icon: Data?                // Icon image data
    public var hotkey: String?            // Serialized hotkey binding
    public var refreshTime: String?       // "1h", "10m", etc.
    public var isEnabled: Bool
    public var lastExecuted: Date?
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        fileName: String,
        title: String,
        packageName: String? = nil,
        mode: ScriptMode = .fullOutput,
        icon: Data? = nil,
        hotkey: String? = nil,
        refreshTime: String? = nil,
        isEnabled: Bool = true,
        lastExecuted: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.fileName = fileName
        self.title = title
        self.packageName = packageName
        self.mode = mode.rawValue
        self.icon = icon
        self.hotkey = hotkey
        self.refreshTime = refreshTime
        self.isEnabled = isEnabled
        self.lastExecuted = lastExecuted
        self.createdAt = createdAt
    }
    
    /// Computed property for ScriptMode enum
    public var scriptMode: ScriptMode {
        get { ScriptMode(rawValue: mode) ?? .fullOutput }
        set { mode = newValue.rawValue }
    }
}

// MARK: - GRDB Conformance

extension ScriptRecord: FetchableRecord, PersistableRecord {
    public static var databaseTableName = "script_commands"
}
