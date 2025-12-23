import XCTest
@testable import TachyonCore

/// Tests for DateExpressionParser (TDD approach)
final class DateExpressionParserTests: XCTestCase {
    
    var parser: DateExpressionParser!
    
    override func setUp() {
        super.setUp()
        parser = DateExpressionParser()
    }
    
    // MARK: - Pattern Priority Tests
    
    func testUnixTimestampPatternFirst() {
        let result = parser.parse("1703347200")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .unixTimestamp)
    }
    
    func testRelativeDatePattern() {
        let result = parser.parse("tomorrow")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .naturalLanguage)
    }
    
    func testDateArithmeticPattern() {
        let result = parser.parse("today + 3 days")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .dateArithmetic)
    }
    
    func testDurationUntilPattern() {
        let result = parser.parse("days until christmas")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .dateDifference)
    }
    
    func testTimezonePattern() {
        let result = parser.parse("time in tokyo")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .timezone)
    }
    
    func testWeekDayNumberPattern() {
        let result = parser.parse("week number")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .weekDayInfo)
    }
    
    // MARK: - First Match Behavior Tests
    
    func testReturnsFirstSuccessfulMatch() {
        // "now" could match multiple patterns, but should return first successful one
        let result = parser.parse("now")
        
        XCTAssertNotNil(result)
        // Should be handled by RelativeDatePattern
        XCTAssertEqual(result?.type, .naturalLanguage)
    }
    
    // MARK: - Invalid Input Tests
    
    func testInvalidInputReturnsNil() {
        let result = parser.parse("completely invalid input xyz")
        
        XCTAssertNil(result)
    }
    
    func testEmptyStringReturnsNil() {
        let result = parser.parse("")
        
        XCTAssertNil(result)
    }
    
    func testWhitespaceOnlyReturnsNil() {
        let result = parser.parse("   ")
        
        XCTAssertNil(result)
    }
    
    // MARK: - Pattern Coverage Tests
    
    func testAllPatternsRegistered() {
        // Test that all major patterns are working
        let testCases: [(String, DateResultType)] = [
            ("1703347200", .unixTimestamp),
            ("today", .naturalLanguage),
            ("today + 1 day", .dateArithmetic),
            ("days until tomorrow", .dateDifference),
            ("time in nyc", .timezone),
            ("week number", .weekDayInfo)
        ]
        
        for (input, expectedType) in testCases {
            let result = parser.parse(input)
            XCTAssertNotNil(result, "Failed to parse: \(input)")
            XCTAssertEqual(result?.type, expectedType, "Wrong type for: \(input)")
        }
    }
    
    // MARK: - Expression Preservation Tests
    
    func testPreservesOriginalExpression() {
        let input = "tomorrow"
        let result = parser.parse(input)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.expression, input)
    }
    
    func testPreservesExpressionWithSpaces() {
        let input = "today + 3 days"
        let result = parser.parse(input)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.expression, input)
    }
    
    // MARK: - Case Sensitivity Tests
    
    func testCaseInsensitiveParsing() {
        let result1 = parser.parse("TODAY")
        let result2 = parser.parse("today")
        let result3 = parser.parse("Today")
        
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertNotNil(result3)
        
        XCTAssertEqual(result1?.type, result2?.type)
        XCTAssertEqual(result2?.type, result3?.type)
    }
    
    // MARK: - Whitespace Handling Tests
    
    func testTrimsWhitespace() {
        let result1 = parser.parse("  tomorrow  ")
        let result2 = parser.parse("tomorrow")
        
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertEqual(result1?.type, result2?.type)
    }
    
    // MARK: - Complex Query Tests
    
    func testComplexDateArithmetic() {
        let result = parser.parse("tomorrow + 2 weeks")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .dateArithmetic)
    }
    
    func testComplexDurationQuery() {
        let result = parser.parse("days until new year")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .dateDifference)
    }
    
    // MARK: - Edge Cases
    
    func testNumericStringNotTimestamp() {
        // 5-digit number should not be parsed as timestamp
        let result = parser.parse("12345")
        
        // Should either be nil or not a unix timestamp
        if let result = result {
            XCTAssertNotEqual(result.type, .unixTimestamp)
        }
    }
    
    func testAmbiguousInput() {
        // Some inputs might match multiple patterns
        // Parser should return the first successful match
        let result = parser.parse("in 2 days")
        
        XCTAssertNotNil(result)
        // Should be handled by RelativeDatePattern
        XCTAssertEqual(result?.type, .naturalLanguage)
    }
}
