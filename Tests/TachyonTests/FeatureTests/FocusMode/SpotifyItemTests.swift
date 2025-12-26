import XCTest
@testable import TachyonCore

/// Tests for SpotifyItem data model (TDD)
final class SpotifyItemTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        let item = SpotifyItem(
            url: "https://open.spotify.com/track/123",
            title: "Focus Music",
            imageURL: "https://i.scdn.co/image/abc",
            type: .track
        )
        
        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.url, "https://open.spotify.com/track/123")
        XCTAssertEqual(item.title, "Focus Music")
        XCTAssertEqual(item.imageURL, "https://i.scdn.co/image/abc")
        XCTAssertEqual(item.type, .track)
    }
    
    func testPlaylistType() {
        let item = SpotifyItem(
            url: "https://open.spotify.com/playlist/abc",
            title: "Focus Playlist",
            imageURL: nil,
            type: .playlist
        )
        
        XCTAssertEqual(item.type, .playlist)
    }
    
    func testAlbumType() {
        let item = SpotifyItem(
            url: "https://open.spotify.com/album/xyz",
            title: "Focus Album",
            imageURL: nil,
            type: .album
        )
        
        XCTAssertEqual(item.type, .album)
    }
    
    // MARK: - Codable Tests
    
    func testEncodeDecode() throws {
        let item = SpotifyItem(
            url: "https://open.spotify.com/track/123",
            title: "Test Track",
            imageURL: "https://example.com/image.jpg",
            type: .track
        )
        
        let encoded = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(SpotifyItem.self, from: encoded)
        
        XCTAssertEqual(decoded.url, item.url)
        XCTAssertEqual(decoded.title, item.title)
        XCTAssertEqual(decoded.type, item.type)
    }
}
