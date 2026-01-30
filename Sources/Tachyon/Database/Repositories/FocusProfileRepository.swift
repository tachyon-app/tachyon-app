import Foundation
import GRDB

public class FocusProfileRepository {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    // MARK: - Profiles
    
    public func fetch(id: UUID) throws -> FocusProfileRecord? {
        try dbQueue.read { db in
            try FocusProfileRecord.fetchOne(db, key: id)
        }
    }

    public func fetchActiveProfile() throws -> FocusProfileRecord? {
        // This is now primarily a fallback/default finder
        try dbQueue.read { db in
            try FocusProfileRecord
                .filter(Column("isDefault") == true)
                .fetchOne(db)
        }
    }
    
    public func count() throws -> Int {
        try dbQueue.read { db in
            try FocusProfileRecord.fetchCount(db)
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
