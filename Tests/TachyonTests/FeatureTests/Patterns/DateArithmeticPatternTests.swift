import XCTest
@testable import TachyonCore

/// Tests for Date Arithmetic Pattern (TDD approach)
final class DateArithmeticPatternTests: XCTestCase {
    
    var pattern: DateArithmeticPattern!
    var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        pattern = DateArithmeticPattern()
        calendar = Calendar.current
    }
    
    // MARK: - Addition Operations
    
    func testTodayPlusThreeDays() throws {
        let result = try XCTUnwrap(pattern.parse("today + 3 days"))
        XCTAssertEqual(result.type, .dateArithmetic)
        
        let expected = calendar.date(byAdding: .day, value: 3, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    func testNowPlusTwoHours() throws {
        let result = try XCTUnwrap(pattern.parse("now + 2 hours"))
        XCTAssertEqual(result.type, .dateArithmetic)
        
        let expected = calendar.date(byAdding: .hour, value: 2, to: Date())!
        let diff = abs(result.date.timeIntervalSince(expected))
        XCTAssertLessThan(diff, 5.0) // Within 5 seconds
    }
    
    func testTomorrowPlusOneWeek() throws {
        let result = try XCTUnwrap(pattern.parse("tomorrow + 1 week"))
        
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        let expected = calendar.date(byAdding: .weekOfYear, value: 1, to: tomorrow)!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, calendar.startOfDay(for: expected))
    }
    
    func testTodayPlusFiveMinutes() throws {
        let result = try XCTUnwrap(pattern.parse("today + 5 minutes"))
        
        // 'today' returns current time (not midnight), so adding 5 minutes
        let expected = calendar.date(byAdding: .minute, value: 5, to: Date())!
        let diff = abs(result.date.timeIntervalSince(expected))
        XCTAssertLessThan(diff, 10.0) // Allow 10 seconds tolerance for test execution time
    }
    
    // MARK: - Subtraction Operations
    
    func testTodayMinusThreeDays() throws {
        let result = try XCTUnwrap(pattern.parse("today - 3 days"))
        XCTAssertEqual(result.type, .dateArithmetic)
        
        let expected = calendar.date(byAdding: .day, value: -3, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    func testNowMinusTwoHours() throws {
        let result = try XCTUnwrap(pattern.parse("now - 2 hours"))
        
        let expected = calendar.date(byAdding: .hour, value: -2, to: Date())!
        let diff = abs(result.date.timeIntervalSince(expected))
        XCTAssertLessThan(diff, 5.0)
    }
    
    func testTomorrowMinusOneDay() throws {
        let result = try XCTUnwrap(pattern.parse("tomorrow - 1 day"))
        
        // tomorrow - 1 day = today
        let resultDay = calendar.startOfDay(for: result.date)
        let expectedDay = calendar.startOfDay(for: Date())
        XCTAssertEqual(resultDay, expectedDay)
    }
    
    // MARK: - All Time Units
    
    func testSecondsUnit() throws {
        let result = try XCTUnwrap(pattern.parse("now + 30 seconds"))
        
        let expected = calendar.date(byAdding: .second, value: 30, to: Date())!
        let diff = abs(result.date.timeIntervalSince(expected))
        XCTAssertLessThan(diff, 5.0)
    }
    
    func testMinutesUnit() throws {
        let result = try XCTUnwrap(pattern.parse("now + 15 minutes"))
        
        let expected = calendar.date(byAdding: .minute, value: 15, to: Date())!
        let diff = abs(result.date.timeIntervalSince(expected))
        XCTAssertLessThan(diff, 5.0)
    }
    
    func testHoursUnit() throws {
        let result = try XCTUnwrap(pattern.parse("now + 4 hours"))
        
        let expected = calendar.date(byAdding: .hour, value: 4, to: Date())!
        let diff = abs(result.date.timeIntervalSince(expected))
        XCTAssertLessThan(diff, 5.0)
    }
    
    func testDaysUnit() throws {
        let result = try XCTUnwrap(pattern.parse("today + 7 days"))
        
        let expected = calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    func testWeeksUnit() throws {
        let result = try XCTUnwrap(pattern.parse("today + 2 weeks"))
        
        let expected = calendar.date(byAdding: .weekOfYear, value: 2, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    func testMonthsUnit() throws {
        let result = try XCTUnwrap(pattern.parse("today + 3 months"))
        
        let expected = calendar.date(byAdding: .month, value: 3, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    func testYearsUnit() throws {
        let result = try XCTUnwrap(pattern.parse("today + 1 year"))
        
        let expected = calendar.date(byAdding: .year, value: 1, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    // MARK: - Singular vs Plural Forms
    
    func testSingularDay() throws {
        let result = try XCTUnwrap(pattern.parse("today + 1 day"))
        
        let expected = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    func testPluralDays() throws {
        let result = try XCTUnwrap(pattern.parse("today + 5 days"))
        
        let expected = calendar.date(byAdding: .day, value: 5, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    func testSingularWeek() throws {
        let result = try XCTUnwrap(pattern.parse("today + 1 week"))
        
        let expected = calendar.date(byAdding: .weekOfYear, value: 1, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    // MARK: - Whitespace Handling
    
    func testNoSpacesAroundOperator() throws {
        let result = try XCTUnwrap(pattern.parse("today+3 days"))
        
        let expected = calendar.date(byAdding: .day, value: 3, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    func testExtraSpaces() throws {
        let result = try XCTUnwrap(pattern.parse("today  +  3  days"))
        
        let expected = calendar.date(byAdding: .day, value: 3, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    // MARK: - Specific Dates
    // Note: Parsing specific dates like 'dec 25' is not yet implemented in DateArithmeticPattern
    
    /*
    func testSpecificDateArithmetic() throws {
        let result = try XCTUnwrap(pattern.parse("dec 25 + 7 days"))
        
        // Should parse "dec 25" and add 7 days
        XCTAssertNotNil(result)
        XCTAssertEqual(result.type, .dateArithmetic)
    }
    */
    
    // MARK: - Edge Cases
    
    func testZeroOffset() throws {
        let result = try XCTUnwrap(pattern.parse("today + 0 days"))
        
        let resultDay = calendar.startOfDay(for: result.date)
        let expectedDay = calendar.startOfDay(for: Date())
        XCTAssertEqual(resultDay, expectedDay)
    }
    
    func testLargeOffset() throws {
        let result = try XCTUnwrap(pattern.parse("today + 365 days"))
        
        let expected = calendar.date(byAdding: .day, value: 365, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    // MARK: - Invalid Input Tests
    
    func testInvalidOperator() {
        let result = pattern.parse("today * 3 days")
        XCTAssertNil(result, "Invalid operator should return nil")
    }
    
    func testInvalidUnit() {
        let result = pattern.parse("today + 3 fortnights")
        XCTAssertNil(result, "Invalid unit should return nil")
    }
    
    func testMissingNumber() {
        let result = pattern.parse("today + days")
        XCTAssertNil(result, "Missing number should return nil")
    }
    
    func testMissingUnit() {
        let result = pattern.parse("today + 3")
        XCTAssertNil(result, "Missing unit should return nil")
    }
    
    func testEmptyString() {
        let result = pattern.parse("")
        XCTAssertNil(result, "Empty string should return nil")
    }
    
    func testNoOperator() {
        let result = pattern.parse("today 3 days")
        XCTAssertNil(result, "Missing operator should return nil")
    }
}
