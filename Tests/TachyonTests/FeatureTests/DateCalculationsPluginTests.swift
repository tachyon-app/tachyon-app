import XCTest
@testable import TachyonCore

/// Tests for DateCalculationsPlugin (TDD approach)
final class DateCalculationsPluginTests: XCTestCase {
    
    var plugin: DateCalculationsPlugin!
    
    override func setUp() {
        super.setUp()
        plugin = DateCalculationsPlugin()
    }
    
    // MARK: - Plugin Metadata Tests
    
    func testPluginID() {
        XCTAssertEqual(plugin.id, "date-calculations")
    }
    
    func testPluginName() {
        XCTAssertEqual(plugin.name, "Date & Time")
    }
    
    // MARK: - Query Handling Tests
    
    func testHandlesUnixTimestamp() async {
        let results = await plugin.search(query: "1703347200")
        
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results.first?.icon, "calendar")
    }
    
    func testHandlesRelativeDate() async {
        let results = await plugin.search(query: "tomorrow")
        
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results.first?.icon, "calendar")
    }
    
    func testHandlesDateArithmetic() async {
        let results = await plugin.search(query: "today + 3 days")
        
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results.first?.icon, "calendar")
    }
    
    func testHandlesDurationUntil() async {
        let results = await plugin.search(query: "days until christmas")
        
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results.first?.icon, "calendar")
    }
    
    func testHandlesTimezoneQuery() async {
        let results = await plugin.search(query: "time in tokyo")
        
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results.first?.icon, "calendar")
    }
    
    // MARK: - AlwaysShow Flag Tests
    
    func testResultsHaveAlwaysShowFlag() async {
        let results = await plugin.search(query: "today")
        
        XCTAssertFalse(results.isEmpty)
        if let first = results.first {
            XCTAssertTrue(first.alwaysShow, "Date results should bypass fuzzy matching")
        }
    }
    
    // MARK: - Result Format Tests
    
    func testResultHasTitle() async {
        let results = await plugin.search(query: "tomorrow")
        
        XCTAssertFalse(results.isEmpty)
        if let first = results.first {
            XCTAssertFalse(first.title.isEmpty)
        }
    }
    
    func testResultHasSubtitle() async {
        let results = await plugin.search(query: "now in unix")
        
        XCTAssertFalse(results.isEmpty)
        if let first = results.first, let subtitle = first.subtitle {
            XCTAssertFalse(subtitle.isEmpty)
        }
    }
    
    func testResultHasIcon() async {
        let results = await plugin.search(query: "today")
        
        XCTAssertFalse(results.isEmpty)
        if let first = results.first {
            XCTAssertEqual(first.icon, "calendar")
        }
    }
    
    // MARK: - Date Difference Title/Subtitle Tests
    
    func testDateDifferenceShowsDurationInTitle() async {
        let results = await plugin.search(query: "days until tomorrow")
        
        XCTAssertFalse(results.isEmpty)
        if let first = results.first {
            // For date difference, duration should be prominent in title
            XCTAssertTrue(first.title.contains("in") || first.title.contains("day"))
        }
    }
    
    // MARK: - Copy Action Tests
    
    func testResultHasCopyAction() async {
        let results = await plugin.search(query: "today")
        
        XCTAssertFalse(results.isEmpty)
        if let first = results.first {
            XCTAssertNotNil(first.action)
        }
    }
    
    // MARK: - Invalid Query Tests
    
    func testInvalidQueryReturnsEmpty() async {
        let results = await plugin.search(query: "random gibberish xyz")
        
        XCTAssertTrue(results.isEmpty)
    }
    
    func testEmptyQueryReturnsEmpty() async {
        let results = await plugin.search(query: "")
        
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - Multiple Results Tests
    
    func testSingleResultPerQuery() async {
        let results = await plugin.search(query: "tomorrow")
        
        // Each query should return at most one result
        XCTAssertLessThanOrEqual(results.count, 1)
    }
    
    // MARK: - Edge Cases
    
    func testWhitespaceQuery() async {
        let results = await plugin.search(query: "   ")
        
        XCTAssertTrue(results.isEmpty)
    }
    
    func testCaseInsensitiveQuery() async {
        let results1 = await plugin.search(query: "TODAY")
        let results2 = await plugin.search(query: "today")
        
        XCTAssertEqual(results1.count, results2.count)
    }
}
