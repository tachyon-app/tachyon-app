import XCTest
@testable import TachyonCore

/// Tests for Relative Date Pattern (TDD approach)
final class RelativeDatePatternTests: XCTestCase {
    
    var pattern: RelativeDatePattern!
    var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        pattern = RelativeDatePattern()
        calendar = Calendar.current
    }
    
    // MARK: - Simple Relative Dates
    
    func testToday() throws {
        let result = try XCTUnwrap(pattern.parse("today"))
        XCTAssertEqual(result.type, .naturalLanguage)
        
        let resultDay = calendar.startOfDay(for: result.date)
        let expectedDay = calendar.startOfDay(for: Date())
        XCTAssertEqual(resultDay, expectedDay)
    }
    
    func testTomorrow() throws {
        let result = try XCTUnwrap(pattern.parse("tomorrow"))
        XCTAssertEqual(result.type, .naturalLanguage)
        
        let expected = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    func testYesterday() throws {
        let result = try XCTUnwrap(pattern.parse("yesterday"))
        XCTAssertEqual(result.type, .naturalLanguage)
        
        let expected = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    func testNow() throws {
        let result = try XCTUnwrap(pattern.parse("now"))
        XCTAssertEqual(result.type, .naturalLanguage)
        
        // Should be within 5 seconds of current time
        let diff = abs(result.date.timeIntervalSinceNow)
        XCTAssertLessThan(diff, 5.0)
    }
    
    // MARK: - Named Weekdays (Next Occurrence)
    
    func testMondayNextOccurrence() throws {
        let result = try XCTUnwrap(pattern.parse("monday"))
        XCTAssertEqual(result.type, .naturalLanguage)
        
        let weekday = calendar.component(.weekday, from: result.date)
        XCTAssertEqual(weekday, 2) // Monday is 2 in Gregorian calendar
        
        // Should be in the future
        XCTAssertGreaterThan(result.date, Date())
    }
    
    func testFridayNextOccurrence() throws {
        let result = try XCTUnwrap(pattern.parse("friday"))
        let weekday = calendar.component(.weekday, from: result.date)
        XCTAssertEqual(weekday, 6) // Friday is 6
    }
    
    func testSundayNextOccurrence() throws {
        let result = try XCTUnwrap(pattern.parse("sunday"))
        let weekday = calendar.component(.weekday, from: result.date)
        XCTAssertEqual(weekday, 1) // Sunday is 1
    }
    
    // MARK: - Next Weekday
    
    func testNextMonday() throws {
        let result = try XCTUnwrap(pattern.parse("next monday"))
        XCTAssertEqual(result.type, .naturalLanguage)
        
        let weekday = calendar.component(.weekday, from: result.date)
        XCTAssertEqual(weekday, 2)
        
        // Should be at least 1 day in the future
        XCTAssertGreaterThan(result.date, Date())
    }
    
    func testNextFriday() throws {
        let result = try XCTUnwrap(pattern.parse("next friday"))
        let weekday = calendar.component(.weekday, from: result.date)
        XCTAssertEqual(weekday, 6)
    }
    
    // MARK: - Last Weekday
    
    func testLastMonday() throws {
        let result = try XCTUnwrap(pattern.parse("last monday"))
        XCTAssertEqual(result.type, .naturalLanguage)
        
        let weekday = calendar.component(.weekday, from: result.date)
        XCTAssertEqual(weekday, 2)
        
        // Should be in the past
        XCTAssertLessThan(result.date, Date())
    }
    
    func testLastFriday() throws {
        let result = try XCTUnwrap(pattern.parse("last friday"))
        let weekday = calendar.component(.weekday, from: result.date)
        XCTAssertEqual(weekday, 6)
        XCTAssertLessThan(result.date, Date())
    }
    
    // MARK: - Relative Offsets (Future)
    
    func testInTwoDays() throws {
        let result = try XCTUnwrap(pattern.parse("in 2 days"))
        XCTAssertEqual(result.type, .naturalLanguage)
        
        let expected = calendar.date(byAdding: .day, value: 2, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    func testInThreeWeeks() throws {
        let result = try XCTUnwrap(pattern.parse("in 3 weeks"))
        
        let expected = calendar.date(byAdding: .weekOfYear, value: 3, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    func testInFiveMonths() throws {
        let result = try XCTUnwrap(pattern.parse("in 5 months"))
        
        let expected = calendar.date(byAdding: .month, value: 5, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    func testInOneYear() throws {
        let result = try XCTUnwrap(pattern.parse("in 1 year"))
        
        let expected = calendar.date(byAdding: .year, value: 1, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    // MARK: - Relative Offsets (Past)
    
    func testThreeDaysAgo() throws {
        let result = try XCTUnwrap(pattern.parse("3 days ago"))
        XCTAssertEqual(result.type, .naturalLanguage)
        
        let expected = calendar.date(byAdding: .day, value: -3, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    func testTwoWeeksAgo() throws {
        let result = try XCTUnwrap(pattern.parse("2 weeks ago"))
        
        let expected = calendar.date(byAdding: .weekOfYear, value: -2, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    func testOneMonthAgo() throws {
        let result = try XCTUnwrap(pattern.parse("1 month ago"))
        
        let expected = calendar.date(byAdding: .month, value: -1, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    // MARK: - Complex Patterns
    
    func testMondayInThreeWeeks() throws {
        let result = try XCTUnwrap(pattern.parse("monday in 3 weeks"))
        XCTAssertEqual(result.type, .naturalLanguage)
        
        let weekday = calendar.component(.weekday, from: result.date)
        XCTAssertEqual(weekday, 2) // Should be a Monday
        
        // Should be roughly 3 weeks in the future (21 days +/- a few days)
        let daysDiff = calendar.dateComponents([.day], from: Date(), to: result.date).day ?? 0
        XCTAssertGreaterThan(daysDiff, 14)
        XCTAssertLessThan(daysDiff, 28)
    }
    
    func testFridayInTwoMonths() throws {
        let result = try XCTUnwrap(pattern.parse("friday in 2 months"))
        
        let weekday = calendar.component(.weekday, from: result.date)
        XCTAssertEqual(weekday, 6) // Should be a Friday
        
        // Should be roughly 2 months in the future
        XCTAssertGreaterThan(result.date, Date())
    }
    
    // MARK: - Edge Cases
    
    func testZeroOffset() throws {
        let result = try XCTUnwrap(pattern.parse("in 0 days"))
        
        let resultDay = calendar.startOfDay(for: result.date)
        let expectedDay = calendar.startOfDay(for: Date())
        XCTAssertEqual(resultDay, expectedDay)
    }
    
    func testSingularUnit() throws {
        let result = try XCTUnwrap(pattern.parse("in 1 day"))
        
        let expected = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    func testCaseInsensitivity() throws {
        let result1 = try XCTUnwrap(pattern.parse("TODAY"))
        let result2 = try XCTUnwrap(pattern.parse("Today"))
        let result3 = try XCTUnwrap(pattern.parse("today"))
        
        let day1 = calendar.startOfDay(for: result1.date)
        let day2 = calendar.startOfDay(for: result2.date)
        let day3 = calendar.startOfDay(for: result3.date)
        
        XCTAssertEqual(day1, day2)
        XCTAssertEqual(day2, day3)
    }
    
    // MARK: - Invalid Input Tests
    
    func testInvalidWeekday() {
        let result = pattern.parse("funday")
        XCTAssertNil(result, "Invalid weekday should return nil")
    }
    
    func testInvalidOffset() {
        let result = pattern.parse("in xyz days")
        XCTAssertNil(result, "Non-numeric offset should return nil")
    }
    
    func testEmptyString() {
        let result = pattern.parse("")
        XCTAssertNil(result, "Empty string should return nil")
    }
    
    func testUnrecognizedPattern() {
        let result = pattern.parse("random text")
        XCTAssertNil(result, "Unrecognized pattern should return nil")
    }
}
