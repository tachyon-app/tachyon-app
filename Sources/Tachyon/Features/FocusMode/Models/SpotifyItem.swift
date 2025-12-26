import Foundation

/// Represents a Spotify item (track, album, or playlist) for focus music
public struct SpotifyItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public let url: String
    public let title: String
    public let imageURL: String?
    public let type: SpotifyItemType
    
    public init(
        id: UUID = UUID(),
        url: String,
        title: String,
        imageURL: String?,
        type: SpotifyItemType
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.imageURL = imageURL
        self.type = type
    }
}

/// Type of Spotify content
public enum SpotifyItemType: String, Codable {
    case track
    case album
    case playlist
    case show
    case episode
}
