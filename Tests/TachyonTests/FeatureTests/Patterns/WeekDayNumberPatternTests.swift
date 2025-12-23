import XCTest
@testable import TachyonCore

/// Tests for WeekDayNumberPattern (TDD approach)
final class WeekDayNumberPatternTests: XCTestCase {
    
    var pattern: WeekDayNumberPattern!
    var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        pattern = WeekDayNumberPattern()
        calendar = Calendar.current
    }
    
    // MARK: - Week Number Tests
    
    func testWeekNumber() {
        let result = pattern.parse("week number")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .weekDayInfo)
    }
    
    func testWeekNumberVariation() {
        let result = pattern.parse("what week is it")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .weekDayInfo)
    }
    
    // MARK: - Day Number Tests
    
    func testDayNumber() {
        let result = pattern.parse("day number")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .weekDayInfo)
    }
    
    func testDayOfYear() {
        let result = pattern.parse("day of year")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .weekDayInfo)
    }
    
    // MARK: - Case Insensitivity Tests
    
    func testCaseInsensitive() {
        let result1 = pattern.parse("WEEK NUMBER")
        let result2 = pattern.parse("Week Number")
        let result3 = pattern.parse("week number")
        
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertNotNil(result3)
    }
    
    // MARK: - Invalid Input Tests
    
    func testInvalidInput() {
        let result = pattern.parse("random text")
        
        XCTAssertNil(result)
    }
    
    func testEmptyInput() {
        let result = pattern.parse("")
        
        XCTAssertNil(result)
    }
}
