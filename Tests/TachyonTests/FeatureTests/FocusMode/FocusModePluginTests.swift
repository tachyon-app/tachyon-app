import XCTest
@testable import TachyonCore

/// Tests for FocusModePlugin (TDD)
final class FocusModePluginTests: XCTestCase {
    
    var plugin: FocusModePlugin!
    
    override func setUp() {
        super.setUp()
        plugin = FocusModePlugin()
    }
    
    // MARK: - Plugin Metadata Tests
    
    func testPluginID() {
        XCTAssertEqual(plugin.id, "focus-mode")
    }
    
    func testPluginName() {
        XCTAssertEqual(plugin.name, "Focus Mode")
    }
    
    // MARK: - Query Parsing Tests
    
    func testFocusCommandShowsResults() async {
        let results = await plugin.search(query: "focus")
        
        XCTAssertFalse(results.isEmpty)
    }
    
    func testFocusWithDuration() async {
        let results = await plugin.search(query: "focus 25")
        
        XCTAssertFalse(results.isEmpty)
        // Should parse 25 as minutes
    }
    
    func testFocusWithMinutes() async {
        let results = await plugin.search(query: "focus 25 min")
        
        XCTAssertFalse(results.isEmpty)
    }
    
    func testFocusWithHour() async {
        let results = await plugin.search(query: "focus 1 hour")
        
        XCTAssertFalse(results.isEmpty)
    }
    
    func testStopFocusCommand() async {
        // stop focus only shows results when a session is active
        // With no session, it should return empty
        let results = await plugin.search(query: "stop focus")
        
        XCTAssertTrue(results.isEmpty, "Should be empty when no session is active")
    }
    
    func testPauseFocusCommand() async {
        // pause focus only shows results when a session is active
        // With no session, it should return empty
        let results = await plugin.search(query: "pause focus")
        
        XCTAssertTrue(results.isEmpty, "Should be empty when no session is active")
    }
    
    // MARK: - Quick Focus Tests
    
    func testQuickFocusCommand() async {
        // Start a session first to set last config
        _ = await plugin.search(query: "focus 25")
        
        // Now "focus" alone should use last config
        let results = await plugin.search(query: "focus")
        
        XCTAssertFalse(results.isEmpty)
    }
    
    // MARK: - Invalid Query Tests
    
    func testUnrelatedQueryReturnsEmpty() async {
        let results = await plugin.search(query: "random text")
        
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - Result Format Tests
    
    func testResultHasCorrectIcon() async {
        let results = await plugin.search(query: "focus")
        
        XCTAssertFalse(results.isEmpty)
        if let first = results.first {
            XCTAssertEqual(first.icon, "timer")
        }
    }
}
