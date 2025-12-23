import XCTest
@testable import TachyonCore

/// Tests for SystemCommandsPlugin (TDD approach)
final class SystemCommandsPluginTests: XCTestCase {
    
    var plugin: SystemCommandsPlugin!
    
    override func setUp() {
        super.setUp()
        plugin = SystemCommandsPlugin()
    }
    
    // MARK: - Plugin Metadata Tests
    
    func testPluginID() {
        XCTAssertEqual(plugin.id, "system-commands")
    }
    
    func testPluginName() {
        XCTAssertEqual(plugin.name, "System Commands")
    }
    
    // MARK: - Command Search Tests
    
    func testSearchByCommandName() async {
        let results = await plugin.search(query: "lock")
        
        XCTAssertFalse(results.isEmpty, "Should find lock screen command")
        XCTAssertTrue(results.first?.title.lowercased().contains("lock") ?? false)
    }
    
    func testSearchByKeyword() async {
        let results = await plugin.search(query: "sleep")
        
        XCTAssertFalse(results.isEmpty, "Should find sleep command")
    }
    
    func testSearchCaseInsensitive() async {
        let results1 = await plugin.search(query: "LOCK")
        let results2 = await plugin.search(query: "lock")
        
        XCTAssertEqual(results1.count, results2.count)
    }
    
    // MARK: - Command Categories Tests
    
    func testPowerCommands() async {
        let queries = ["sleep", "restart", "shutdown", "lock"]
        
        for query in queries {
            let results = await plugin.search(query: query)
            XCTAssertFalse(results.isEmpty, "Should find command for: \(query)")
        }
    }
    
    func testSystemSettingsCommands() async {
        let queries = ["dark mode", "appearance"]
        
        for query in queries {
            let results = await plugin.search(query: query)
            XCTAssertFalse(results.isEmpty, "Should find command for: \(query)")
        }
    }
    
    // MARK: - Result Format Tests
    
    func testResultHasTitle() async {
        let results = await plugin.search(query: "lock")
        
        XCTAssertFalse(results.isEmpty)
        if let first = results.first {
            XCTAssertFalse(first.title.isEmpty)
        }
    }
    
    func testResultHasIcon() async {
        let results = await plugin.search(query: "lock")
        
        XCTAssertFalse(results.isEmpty)
        if let first = results.first {
            XCTAssertNotNil(first.icon)
            XCTAssertFalse(first.icon?.isEmpty ?? true)
        }
    }
    
    func testResultHasAction() async {
        let results = await plugin.search(query: "lock")
        
        XCTAssertFalse(results.isEmpty)
        if let first = results.first {
            XCTAssertNotNil(first.action)
        }
    }
    
    // MARK: - Invalid Query Tests
    
    func testInvalidQueryReturnsEmpty() async {
        let results = await plugin.search(query: "xyzinvalidcommand123")
        
        XCTAssertTrue(results.isEmpty)
    }
    
    func testEmptyQueryReturnsEmpty() async {
        let results = await plugin.search(query: "")
        
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - Fuzzy Matching Tests
    
    func testPartialMatch() async {
        let results = await plugin.search(query: "loc")
        
        // Should find "lock screen" with partial match
        XCTAssertFalse(results.isEmpty)
    }
    
    // MARK: - Command Count Tests
    
    func testHasMultipleCommands() async {
        // Search for a broad term that should match multiple commands
        let results = await plugin.search(query: "screen")
        
        // Should have commands like "lock screen", "screen saver", etc.
        XCTAssertGreaterThanOrEqual(results.count, 1)
    }
}
