import XCTest
@testable import TachyonCore

/// Tests for CameraPlugin (TDD approach)
final class CameraPluginTests: XCTestCase {
    
    var plugin: CameraPlugin!
    
    override func setUp() {
        super.setUp()
        plugin = CameraPlugin()
    }
    
    // MARK: - Plugin Metadata Tests
    
    func testPluginID() {
        XCTAssertEqual(plugin.id, "camera")
    }
    
    func testPluginName() {
        XCTAssertEqual(plugin.name, "Camera")
    }
    
    // MARK: - Command Search Tests
    
    func testSearchByCamera() {
        let results = plugin.search(query: "camera")
        
        XCTAssertFalse(results.isEmpty, "Should find camera command")
        XCTAssertEqual(results.first?.title, "Open Camera")
    }
    
    func testSearchByWebcam() {
        let results = plugin.search(query: "webcam")
        
        XCTAssertFalse(results.isEmpty, "Should find camera command for 'webcam'")
        XCTAssertEqual(results.first?.title, "Open Camera")
    }
    
    func testSearchByPhoto() {
        let results = plugin.search(query: "photo")
        
        XCTAssertFalse(results.isEmpty, "Should find camera command for 'photo'")
    }
    
    func testSearchBySelfie() {
        let results = plugin.search(query: "selfie")
        
        XCTAssertFalse(results.isEmpty, "Should find camera command for 'selfie'")
    }
    
    func testSearchByMeeting() {
        let results = plugin.search(query: "meeting")
        
        XCTAssertFalse(results.isEmpty, "Should find camera command for 'meeting'")
    }
    
    func testSearchByMirror() {
        let results = plugin.search(query: "mirror")
        
        XCTAssertFalse(results.isEmpty, "Should find camera command for 'mirror'")
    }
    
    func testSearchCaseInsensitive() {
        let results1 = plugin.search(query: "CAMERA")
        let results2 = plugin.search(query: "camera")
        
        XCTAssertEqual(results1.count, results2.count)
    }
    
    // MARK: - Result Format Tests
    
    func testResultHasTitle() {
        let results = plugin.search(query: "camera")
        
        XCTAssertFalse(results.isEmpty)
        if let first = results.first {
            XCTAssertEqual(first.title, "Open Camera")
        }
    }
    
    func testResultHasSubtitle() {
        let results = plugin.search(query: "camera")
        
        XCTAssertFalse(results.isEmpty)
        if let first = results.first {
            XCTAssertNotNil(first.subtitle)
            XCTAssertFalse(first.subtitle?.isEmpty ?? true)
        }
    }
    
    func testResultHasIcon() {
        let results = plugin.search(query: "camera")
        
        XCTAssertFalse(results.isEmpty)
        if let first = results.first {
            XCTAssertNotNil(first.icon)
            XCTAssertEqual(first.icon, "camera.fill")
        }
    }
    
    func testResultKeepsWindowOpen() {
        let results = plugin.search(query: "camera")
        
        XCTAssertFalse(results.isEmpty)
        if let first = results.first {
            // Camera should NOT hide window after execution
            XCTAssertFalse(first.hideWindowAfterExecution)
        }
    }
    
    // MARK: - Invalid Query Tests
    
    func testInvalidQueryReturnsEmpty() {
        let results = plugin.search(query: "xyzinvalidquery123")
        
        XCTAssertTrue(results.isEmpty)
    }
    
    func testEmptyQueryReturnsEmpty() {
        let results = plugin.search(query: "")
        
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - Partial Match Tests
    
    func testPartialMatchCamera() {
        let results = plugin.search(query: "cam")
        
        // Should find "camera" with partial match
        XCTAssertFalse(results.isEmpty)
    }
    
    func testPartialMatchOpen() {
        let results = plugin.search(query: "open")
        
        // Should find "open camera" 
        XCTAssertFalse(results.isEmpty)
    }
}
