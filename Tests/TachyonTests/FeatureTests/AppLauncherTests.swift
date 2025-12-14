import XCTest
@testable import TachyonCore

/// Tests for the App Launcher plugin
final class AppLauncherTests: XCTestCase {
    
    var plugin: AppLauncherPlugin!
    
    override func setUp() {
        super.setUp()
        plugin = AppLauncherPlugin()
    }
    
    func testPluginIdentity() {
        XCTAssertEqual(plugin.id, "app-launcher")
        XCTAssertEqual(plugin.name, "App Launcher")
    }
    
    func testSearchReturnsResults() {
        // This test assumes some apps are installed
        // We'll search for common macOS apps
        let results = plugin.search(query: "safari")
        
        // Should find Safari if it's installed
        XCTAssertFalse(results.isEmpty, "Should find at least one result for 'safari'")
    }
    
    func testSearchIsCaseInsensitive() {
        let results1 = plugin.search(query: "safari")
        let results2 = plugin.search(query: "SAFARI")
        
        // Should return same results regardless of case
        XCTAssertEqual(results1.count, results2.count)
    }
    
    func testEmptyQueryReturnsAll() {
        let results = plugin.search(query: "")
        
        // Empty query should return all indexed apps
        XCTAssertGreaterThan(results.count, 0, "Should have indexed some apps")
    }
}
