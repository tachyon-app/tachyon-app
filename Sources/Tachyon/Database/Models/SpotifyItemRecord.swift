import Foundation
import GRDB

public struct SpotifyItemRecord: Codable, FetchableRecord, PersistableRecord, Identifiable {
    public var id: UUID
    public var profileId: UUID
    public var url: String
    public var type: String // track, playlist, album
    public var title: String
    public var createdAt: Date
    
    public static let databaseTableName = "focus_spotify_items"
    
    public init(
        id: UUID = UUID(),
        profileId: UUID,
        url: String,
        type: String,
        title: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.profileId = profileId
        self.url = url
        self.type = type
        self.title = title
        self.createdAt = createdAt
    }
    
    // Convert to domain model
    public func toSpotifyItem() -> SpotifyItem {
        return SpotifyItem(
            id: id,
            url: url,
            title: title,
            imageURL: nil, // We don't persist image URL in DB yet, or need to add column
            type: SpotifyItemType(rawValue: type) ?? .track
        )
    }
}

extension SpotifyItemRecord {
    public static func createTable(in db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("profileId", .text).notNull()
                .references("focus_profiles", onDelete: .cascade)
            t.column("url", .text).notNull()
            t.column("type", .text).notNull()
            t.column("title", .text).notNull()
            t.column("createdAt", .datetime).notNull()
        }
        
        try db.create(index: "idx_spotify_items_profile", on: databaseTableName, columns: ["profileId"], ifNotExists: true)
    }
}
