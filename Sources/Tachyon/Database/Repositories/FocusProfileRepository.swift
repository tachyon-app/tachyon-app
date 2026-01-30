import Foundation
import GRDB

public class FocusProfileRepository {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    // MARK: - Profiles
    
    public func fetchActiveProfile() throws -> FocusProfileRecord? {
        // For now, simpler: fetch default or first one. 
        // In future we might have "isActive" flag or setting storing active profile ID.
        // Let's assume we fetch the one marked isDefault = true, or just first one.
        try dbQueue.read { db in
            try FocusProfileRecord
                .filter(Column("isDefault") == true)
                .fetchOne(db)
        }
    }
    
    public func fetchAll() throws -> [FocusProfileRecord] {
        try dbQueue.read { db in
            try FocusProfileRecord.fetchAll(db)
        }
    }
    
    public func save(_ profile: FocusProfileRecord) throws {
        try dbQueue.write { db in
            try profile.save(db)
        }
    }
    
    public func delete(_ profileId: UUID) throws {
        try dbQueue.write { db in
            try FocusProfileRecord.deleteOne(db, key: profileId)
        }
    }
    
    // MARK: - Spotify Items
    
    public func fetchSpotifyItems(for profileId: UUID) throws -> [SpotifyItemRecord] {
        try dbQueue.read { db in
            try SpotifyItemRecord
                .filter(Column("profileId") == profileId)
                .fetchAll(db)
        }
    }
    
    public func addSpotifyItem(_ item: SpotifyItemRecord) throws {
        try dbQueue.write { db in
            try item.save(db)
        }
    }
    
    public func removeSpotifyItem(_ itemId: UUID) throws {
        try dbQueue.write { db in
            try SpotifyItemRecord.deleteOne(db, key: itemId)
        }
    }
    
    public func clearSpotifyItems(for profileId: UUID) throws {
        try dbQueue.write { db in
            try SpotifyItemRecord
                .filter(Column("profileId") == profileId)
                .deleteAll(db)
        }
    }
}
