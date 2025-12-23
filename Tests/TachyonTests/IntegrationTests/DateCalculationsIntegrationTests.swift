import XCTest
@testable import TachyonCore

/// Integration tests for Date Calculations end-to-end flow
final class DateCalculationsIntegrationTests: XCTestCase {
    
    var plugin: DateCalculationsPlugin!
    var parser: DateExpressionParser!
    
    override func setUp() {
        super.setUp()
        plugin = DateCalculationsPlugin()
        parser = DateExpressionParser()
    }
    
    // MARK: - End-to-End Query Flow Tests
    
    func testUnixTimestampQueryFlow() async {
        // User types a unix timestamp
        let query = "1703347200"
        
        // Plugin processes it
        let results = await plugin.search(query: query)
        
        // Should return exactly one result
        XCTAssertEqual(results.count, 1)
        
        // Result should have proper formatting
        if let result = results.first {
            XCTAssertFalse(result.title.isEmpty)
            XCTAssertNotNil(result.subtitle)
            XCTAssertEqual(result.icon, "calendar")
            XCTAssertTrue(result.alwaysShow, "Should bypass fuzzy matching")
            XCTAssertNotNil(result.action, "Should have copy action")
        }
    }
    
    func testNaturalLanguageDateFlow() async {
        // User types natural language
        let query = "tomorrow"
        
        let results = await plugin.search(query: query)
        
        XCTAssertFalse(results.isEmpty)
        if let result = results.first {
            XCTAssertTrue(result.title.contains("2025") || result.title.contains("202"))
            XCTAssertTrue(result.alwaysShow)
        }
    }
    
    func testDateArithmeticFlow() async {
        // User performs date arithmetic
        let query = "today + 7 days"
        
        let results = await plugin.search(query: query)
        
        XCTAssertFalse(results.isEmpty)
        if let result = results.first {
            XCTAssertNotNil(result.subtitle)
            XCTAssertTrue(result.alwaysShow)
        }
    }
    
    func testTimezoneQueryFlow() async {
        // User asks for time in another timezone
        let query = "time in tokyo"
        
        let results = await plugin.search(query: query)
        
        XCTAssertFalse(results.isEmpty)
        if let result = results.first {
            XCTAssertTrue(result.title.contains(":") || result.title.contains("AM") || result.title.contains("PM"))
        }
    }
    
    func testDurationUntilFlow() async {
        // User asks for duration
        let query = "days until new year"
        
        let results = await plugin.search(query: query)
        
        XCTAssertFalse(results.isEmpty)
        if let result = results.first {
            // Should show the duration prominently
            XCTAssertTrue(result.title.contains("day") || result.title.contains("in"))
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidQueryReturnsEmpty() async {
        let invalidQueries = [
            "completely random text xyz",
            "12345", // Too short for timestamp
            "not a date at all",
            "%%%###"
        ]
        
        for query in invalidQueries {
            let results = await plugin.search(query: query)
            XCTAssertTrue(results.isEmpty, "Should return empty for: \(query)")
        }
    }
    
    func testEmptyQueryHandling() async {
        let results = await plugin.search(query: "")
        XCTAssertTrue(results.isEmpty)
    }
    
    func testWhitespaceQueryHandling() async {
        let results = await plugin.search(query: "   ")
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - Pattern Priority Tests
    
    func testPatternPriorityOrder() {
        // Unix timestamps should be detected before relative dates
        let timestamp = "1703347200"
        let result = parser.parse(timestamp)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .unixTimestamp)
    }
    
    func testAmbiguousInputHandling() {
        // "in 2 days" could match multiple patterns
        // Should return the first successful match
        let result = parser.parse("in 2 days")
        
        XCTAssertNotNil(result)
        // Should be handled by RelativeDatePattern
        XCTAssertEqual(result?.type, .naturalLanguage)
    }
    
    // MARK: - Multiple Format Output Tests
    
    func testResultHasAllFormats() async {
        let query = "tomorrow"
        let results = await plugin.search(query: query)
        
        XCTAssertFalse(results.isEmpty)
        
        // Parse the result to get DateResult
        if let dateResult = parser.parse(query) {
            // Should have all format types
            XCTAssertFalse(dateResult.formats.humanReadable.isEmpty)
            XCTAssertFalse(dateResult.formats.iso8601.isEmpty)
            XCTAssertFalse(dateResult.formats.rfc2822.isEmpty)
            XCTAssertGreaterThan(dateResult.formats.unixSeconds, 0)
            XCTAssertGreaterThan(dateResult.formats.unixMilliseconds, 0)
            XCTAssertFalse(dateResult.formats.relative.isEmpty)
        }
    }
    
    // MARK: - Copy Action Tests
    
    func testCopyActionExists() async {
        let query = "today"
        let results = await plugin.search(query: query)
        
        XCTAssertFalse(results.isEmpty)
        if let result = results.first {
            XCTAssertNotNil(result.action, "Should have copy action")
        }
    }
    
    // MARK: - Performance Tests
    
    func testParsingPerformance() {
        let queries = [
            "1703347200",
            "tomorrow",
            "today + 3 days",
            "time in tokyo",
            "days until christmas"
        ]
        
        measure {
            for query in queries {
                _ = parser.parse(query)
            }
        }
    }
    
    func testPluginSearchPerformance() async {
        let queries = [
            "1703347200",
            "tomorrow",
            "today + 3 days"
        ]
        
        for query in queries {
            let start = Date()
            _ = await plugin.search(query: query)
            let duration = Date().timeIntervalSince(start)
            
            // Should complete in less than 100ms for good UX
            XCTAssertLessThan(duration, 0.1, "Query '\(query)' took too long: \(duration)s")
        }
    }
    
    // MARK: - Case Sensitivity Tests
    
    func testCaseInsensitiveQueries() async {
        let queries = [
            ("TODAY", "today"),
            ("TOMORROW", "tomorrow"),
            ("TIME IN TOKYO", "time in tokyo")
        ]
        
        for (upper, lower) in queries {
            let results1 = await plugin.search(query: upper)
            let results2 = await plugin.search(query: lower)
            
            XCTAssertEqual(results1.count, results2.count, "Case sensitivity issue for: \(upper)")
        }
    }
    
    // MARK: - AlwaysShow Flag Tests
    
    func testAllResultsHaveAlwaysShow() async {
        let queries = ["tomorrow", "1703347200", "today + 1 day", "time in nyc"]
        
        for query in queries {
            let results = await plugin.search(query: query)
            
            for result in results {
                XCTAssertTrue(result.alwaysShow, "Result for '\(query)' should have alwaysShow=true")
            }
        }
    }
}
