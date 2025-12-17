import Foundation
import GRDB

public class WindowSnappingShortcutRepository {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    // MARK: - Queries
    
    public func fetchAll() throws -> [WindowSnappingShortcut] {
        try dbQueue.read { db in
            try WindowSnappingShortcut.fetchAll(db)
        }
    }
    
    public func fetchEnabled() throws -> [WindowSnappingShortcut] {
        try dbQueue.read { db in
            try WindowSnappingShortcut
                .filter(Column("isEnabled") == true)
                .fetchAll(db)
        }
    }
    
    public func fetch(byAction action: WindowAction) throws -> WindowSnappingShortcut? {
        try dbQueue.read { db in
            try WindowSnappingShortcut
                .filter(Column("action") == action.rawValue)
                .fetchOne(db)
        }
    }
    
    // MARK: - Mutations
    
    public func insert(_ shortcut: WindowSnappingShortcut) throws {
        try dbQueue.write { db in
            var mutableShortcut = shortcut
            try mutableShortcut.insert(db)
        }
    }
    
    public func insertDefaults() throws {
        let defaults = WindowSnappingShortcut.defaults
        try dbQueue.write { db in
            for var shortcut in defaults {
                try shortcut.insert(db)
            }
        }
    }
    
    public func update(_ shortcut: WindowSnappingShortcut) throws {
        try dbQueue.write { db in
            try shortcut.update(db)
        }
    }
    
    public func deleteAll() throws {
        try dbQueue.write { db in
            try WindowSnappingShortcut.deleteAll(db)
        }
    }
    
    public func resetToDefaults() throws {
        try deleteAll()
        try insertDefaults()
    }
    
    // MARK: - Validation
    
    public func validateShortcut(_ shortcut: WindowSnappingShortcut) throws -> ShortcutValidationResult {
        let allShortcuts = try fetchAll()
        
        // Check for duplicates (excluding self)
        let duplicates = allShortcuts.filter {
            $0.keyCode == shortcut.keyCode &&
            $0.modifiers == shortcut.modifiers &&
            $0.action != shortcut.action
        }
        
        if let duplicate = duplicates.first {
            return .conflict(with: duplicate.action)
        }
        
        // Validate key code is valid
        guard KeyCodeMapper.isValid(shortcut.keyCode) else {
            return .invalid(reason: "Invalid key code")
        }
        
        return .valid
    }
}

public enum ShortcutValidationResult: Equatable {
    case valid
    case conflict(with: String)  // Action name
    case invalid(reason: String)
}
