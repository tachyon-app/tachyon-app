import Foundation
import GRDB

/// Repository for Scene CRUD operations
public class SceneRepository {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    // MARK: - Queries
    
    /// Fetch all scenes ordered by creation date (newest first)
    public func fetchAll() throws -> [WindowScene] {
        try dbQueue.read { db in
            try WindowScene.order(Column("createdAt").desc).fetchAll(db)
        }
    }
    
    /// Fetch a scene by ID
    public func fetch(byId id: UUID) throws -> WindowScene? {
        try dbQueue.read { db in
            try WindowScene.fetchOne(db, key: id)
        }
    }
    
    /// Fetch all enabled scenes
    public func fetchEnabled() throws -> [WindowScene] {
        try dbQueue.read { db in
            try WindowScene
                .filter(Column("isEnabled") == true)
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }
    
    /// Fetch scenes with shortcuts assigned
    public func fetchWithShortcuts() throws -> [WindowScene] {
        try dbQueue.read { db in
            try WindowScene
                .filter(Column("shortcutKeyCode") != nil)
                .filter(Column("isEnabled") == true)
                .fetchAll(db)
        }
    }
    
    /// Fetch a scene with its windows
    public func fetchWithWindows(byId id: UUID) throws -> (scene: WindowScene, windows: [SceneWindow])? {
        try dbQueue.read { db in
            guard let scene = try WindowScene.fetchOne(db, key: id) else {
                return nil
            }
            let windows = try scene.windows.fetchAll(db)
            return (scene, windows)
        }
    }
    
    /// Fetch windows for a scene
    public func fetchWindows(forSceneId sceneId: UUID) throws -> [SceneWindow] {
        try dbQueue.read { db in
            try SceneWindow
                .filter(Column("sceneId") == sceneId)
                .fetchAll(db)
        }
    }
    
    // MARK: - Mutations
    
    /// Insert a new scene with its windows
    public func insert(_ scene: WindowScene, windows: [SceneWindow]) throws {
        try dbQueue.write { db in
            var mutableScene = scene
            try mutableScene.insert(db)
            
            for var window in windows {
                try window.insert(db)
            }
        }
    }
    
    /// Insert a scene without windows
    public func insert(_ scene: WindowScene) throws {
        try dbQueue.write { db in
            var mutableScene = scene
            try mutableScene.insert(db)
        }
    }
    
    /// Update a scene
    public func update(_ scene: WindowScene) throws {
        try dbQueue.write { db in
            try scene.update(db)
        }
    }
    
    /// Update a scene and replace all its windows
    public func update(_ scene: WindowScene, windows: [SceneWindow]) throws {
        try dbQueue.write { db in
            try scene.update(db)
            
            // Delete existing windows for this scene
            try SceneWindow.filter(Column("sceneId") == scene.id).deleteAll(db)
            
            // Insert new windows
            for var window in windows {
                try window.insert(db)
            }
        }
    }
    
    /// Update scene shortcut
    public func updateShortcut(sceneId: UUID, keyCode: UInt32?, modifiers: UInt32?) throws {
        try dbQueue.write { db in
            guard var scene = try WindowScene.fetchOne(db, key: sceneId) else { return }
            scene.shortcutKeyCode = keyCode
            scene.shortcutModifiers = modifiers
            try scene.update(db)
        }
    }
    
    /// Delete a scene (windows are deleted via cascade)
    public func delete(id: UUID) throws {
        try dbQueue.write { db in
            _ = try WindowScene.deleteOne(db, key: id)
        }
    }
    
    /// Delete all scenes
    public func deleteAll() throws {
        try dbQueue.write { db in
            try WindowScene.deleteAll(db)
        }
    }
    
    // MARK: - Validation
    
    /// Check if a shortcut is already used by another scene
    public func validateShortcut(keyCode: UInt32, modifiers: UInt32, excludingSceneId: UUID?) throws -> WindowScene? {
        try dbQueue.read { db in
            var query = WindowScene
                .filter(Column("shortcutKeyCode") == keyCode)
                .filter(Column("shortcutModifiers") == modifiers)
            
            if let excludedId = excludingSceneId {
                query = query.filter(Column("id") != excludedId)
            }
            
            return try query.fetchOne(db)
        }
    }
}
