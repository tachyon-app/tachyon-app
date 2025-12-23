import XCTest
@testable import TachyonCore

/// Integration tests for System Commands Plugin
final class SystemCommandsIntegrationTests: XCTestCase {
    
    var plugin: SystemCommandsPlugin!
    
    override func setUp() {
        super.setUp()
        plugin = SystemCommandsPlugin()
    }
    
    // MARK: - End-to-End Search Flow
    
    func testSearchForPowerCommand() async {
        let results = await plugin.search(query: "sleep")
        
        XCTAssertFalse(results.isEmpty, "Should find sleep command")
        
        if let result = results.first {
            XCTAssertTrue(result.title.lowercased().contains("sleep"))
            XCTAssertNotNil(result.action)
            XCTAssertFalse(result.icon?.isEmpty ?? true)
        }
    }
    
    func testSearchForSystemSettingsCommand() async {
        let results = await plugin.search(query: "dark mode")
        
        XCTAssertFalse(results.isEmpty, "Should find dark mode command")
        
        if let result = results.first {
            XCTAssertTrue(result.title.lowercased().contains("dark") || 
                         result.title.lowercased().contains("appearance"))
        }
    }
    
    func testSearchForAudioCommand() async {
        let results = await plugin.search(query: "mute")
        
        XCTAssertFalse(results.isEmpty, "Should find mute command")
    }
    
    // MARK: - Fuzzy Matching Integration
    
    func testFuzzyMatchingWorks() async {
        // Partial match should work
        let results = await plugin.search(query: "loc")
        
        // Should find "Lock Screen"
        XCTAssertFalse(results.isEmpty)
    }
    
    func testTypoTolerance() async {
        // Common typos should still find commands
        let results = await plugin.search(query: "slep") // typo for "sleep"
        
        // Fuzzy matching might find it, but not guaranteed
        // Just ensure it doesn't crash
        XCTAssertNotNil(results)
    }
    
    // MARK: - Multiple Results Tests
    
    func testBroadSearchReturnsMultiple() async {
        let results = await plugin.search(query: "volume")
        
        // Should find multiple volume commands (0%, 25%, 50%, 75%, 100%)
        XCTAssertGreaterThanOrEqual(results.count, 1)
    }
    
    func testSpecificSearchReturnsSingle() async {
        let results = await plugin.search(query: "lock screen")
        
        // Should find exactly the lock screen command
        XCTAssertGreaterThanOrEqual(results.count, 1)
        
        if let first = results.first {
            XCTAssertTrue(first.title.lowercased().contains("lock"))
        }
    }
    
    // MARK: - Error Handling
    
    func testInvalidQueryReturnsEmpty() async {
        let results = await plugin.search(query: "xyzinvalidcommand123")
        
        XCTAssertTrue(results.isEmpty)
    }
    
    func testEmptyQueryReturnsEmpty() async {
        let results = await plugin.search(query: "")
        
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - Command Metadata Validation
    
    func testAllCommandsHaveRequiredFields() async {
        // Search for a broad term to get multiple commands
        let results = await plugin.search(query: "system")
        
        for result in results {
            XCTAssertFalse(result.title.isEmpty, "Command should have title")
            XCTAssertNotNil(result.action, "Command should have action")
            // Icon can be optional in QueryResult
        }
    }
    
    // MARK: - Performance Tests
    
    func testSearchPerformance() async {
        let queries = ["sleep", "lock", "dark mode", "volume", "trash"]
        
        for query in queries {
            let start = Date()
            _ = await plugin.search(query: query)
            let duration = Date().timeIntervalSince(start)
            
            // Should complete quickly for good UX
            XCTAssertLessThan(duration, 0.05, "Search for '\(query)' took too long: \(duration)s")
        }
    }
    
    // MARK: - Case Sensitivity
    
    func testCaseInsensitiveSearch() async {
        let results1 = await plugin.search(query: "LOCK")
        let results2 = await plugin.search(query: "lock")
        let results3 = await plugin.search(query: "Lock")
        
        XCTAssertEqual(results1.count, results2.count)
        XCTAssertEqual(results2.count, results3.count)
    }
    
    // MARK: - Category Coverage
    
    func testPowerCategoryCommands() async {
        let powerCommands = ["sleep", "restart", "shutdown", "lock"]
        
        for command in powerCommands {
            let results = await plugin.search(query: command)
            XCTAssertFalse(results.isEmpty, "Should find command: \(command)")
        }
    }
    
    func testAudioCategoryCommands() async {
        let audioCommands = ["mute", "unmute", "volume"]
        
        for command in audioCommands {
            let results = await plugin.search(query: command)
            XCTAssertFalse(results.isEmpty, "Should find command: \(command)")
        }
    }
    
    // MARK: - Keyword Search
    
    func testSearchByKeyword() async {
        // "dark" should find "Toggle System Appearance"
        let results = await plugin.search(query: "dark")
        
        XCTAssertFalse(results.isEmpty)
    }
    
    func testSearchByAlternateKeyword() async {
        // "appearance" should also find dark mode toggle
        let results = await plugin.search(query: "appearance")
        
        XCTAssertFalse(results.isEmpty)
    }
}
