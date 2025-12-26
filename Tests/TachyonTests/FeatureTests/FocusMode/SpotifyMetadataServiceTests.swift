import XCTest
@testable import TachyonCore

/// Tests for SpotifyMetadataService (TDD)
final class SpotifyMetadataServiceTests: XCTestCase {
    
    var service: SpotifyMetadataService!
    
    override func setUp() {
        super.setUp()
        service = SpotifyMetadataService()
    }
    
    // MARK: - URL Validation Tests
    
    func testValidTrackURL() {
        let url = "https://open.spotify.com/track/4iV5W9uYEdYUVa79Axb7Rh"
        
        XCTAssertTrue(service.isValidSpotifyURL(url))
        XCTAssertEqual(service.getItemType(from: url), .track)
    }
    
    func testValidPlaylistURL() {
        let url = "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M"
        
        XCTAssertTrue(service.isValidSpotifyURL(url))
        XCTAssertEqual(service.getItemType(from: url), .playlist)
    }
    
    func testValidAlbumURL() {
        let url = "https://open.spotify.com/album/4aawyAB9vmqN3uQ7FjRGTy"
        
        XCTAssertTrue(service.isValidSpotifyURL(url))
        XCTAssertEqual(service.getItemType(from: url), .album)
    }
    
    func testInvalidURL() {
        let url = "https://youtube.com/watch?v=123"
        
        XCTAssertFalse(service.isValidSpotifyURL(url))
    }
    
    func testEmptyURL() {
        XCTAssertFalse(service.isValidSpotifyURL(""))
    }
    
    func testMalformedURL() {
        let url = "not a url at all"
        
        XCTAssertFalse(service.isValidSpotifyURL(url))
    }
    
    // MARK: - URL Format Variations
    
    func testSpotifyURLWithQueryParams() {
        let url = "https://open.spotify.com/track/4iV5W9uYEdYUVa79Axb7Rh?si=abc123"
        
        XCTAssertTrue(service.isValidSpotifyURL(url))
    }
    
    func testSpotifyURLWithoutHTTPS() {
        let url = "open.spotify.com/track/4iV5W9uYEdYUVa79Axb7Rh"
        
        // Should still be recognized or normalized
        XCTAssertTrue(service.isValidSpotifyURL(url) || 
                     service.isValidSpotifyURL("https://" + url))
    }
}
