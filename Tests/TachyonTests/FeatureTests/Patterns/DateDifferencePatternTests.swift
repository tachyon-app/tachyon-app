import XCTest
@testable import TachyonCore

/// Tests for DateDifferencePattern (TDD approach)
final class DateDifferencePatternTests: XCTestCase {
    
    var pattern: DateDifferencePattern!
    var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        pattern = DateDifferencePattern()
        calendar = Calendar.current
    }
    
    // MARK: - Basic Date Difference Tests
    
    func testSimpleDateDifference() {
        let result = pattern.parse("tomorrow - today")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .dateDifference)
    }
    
    func testDateMinusDate() {
        let result = pattern.parse("dec 25 - today")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .dateDifference)
    }
    
    // MARK: - Whitespace Handling
    
    func testWhitespaceVariations() {
        let result1 = pattern.parse("tomorrow-today")
        let result2 = pattern.parse("tomorrow - today")
        let result3 = pattern.parse("tomorrow  -  today")
        
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertNotNil(result3)
    }
    
    // MARK: - Invalid Input Tests
    
    func testInvalidPattern() {
        let result = pattern.parse("random text")
        
        XCTAssertNil(result)
    }
    
    func testMissingOperator() {
        let result = pattern.parse("tomorrow today")
        
        XCTAssertNil(result)
    }
    
    func testEmptyInput() {
        let result = pattern.parse("")
        
        XCTAssertNil(result)
    }
}
