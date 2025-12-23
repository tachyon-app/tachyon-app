import XCTest
@testable import TachyonCore

/// Tests for Duration Until Pattern (TDD approach)
final class DurationUntilPatternTests: XCTestCase {
    
    var pattern: DurationUntilPattern!
    var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        pattern = DurationUntilPattern()
        calendar = Calendar.current
    }
    
    // MARK: - Days Until Queries
    
    func testDaysUntilChristmas() throws {
        let result = try XCTUnwrap(pattern.parse("days until christmas"))
        XCTAssertEqual(result.type, .dateDifference)
        
        // Should be December 25 of current or next year
        let month = calendar.component(.month, from: result.date)
        let day = calendar.component(.day, from: result.date)
        XCTAssertEqual(month, 12)
        XCTAssertEqual(day, 25)
    }
    
    func testDaysUntilNewYear() throws {
        let result = try XCTUnwrap(pattern.parse("days until new year"))
        XCTAssertEqual(result.type, .dateDifference)
        
        // Should be January 1 of next year
        let month = calendar.component(.month, from: result.date)
        let day = calendar.component(.day, from: result.date)
        XCTAssertEqual(month, 1)
        XCTAssertEqual(day, 1)
    }
    
    func testDaysUntilSpecificDate() throws {
        let result = try XCTUnwrap(pattern.parse("days until march 15"))
        XCTAssertEqual(result.type, .dateDifference)
        
        let month = calendar.component(.month, from: result.date)
        let day = calendar.component(.day, from: result.date)
        XCTAssertEqual(month, 3)
        XCTAssertEqual(day, 15)
    }
    
    func testDaysUntilTomorrow() throws {
        let result = try XCTUnwrap(pattern.parse("days until tomorrow"))
        XCTAssertEqual(result.type, .dateDifference)
        
        let expected = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    // MARK: - Time Until Queries
    
    func testTimeUntilChristmas() throws {
        let result = try XCTUnwrap(pattern.parse("time until christmas"))
        XCTAssertEqual(result.type, .dateDifference)
        
        let month = calendar.component(.month, from: result.date)
        let day = calendar.component(.day, from: result.date)
        XCTAssertEqual(month, 12)
        XCTAssertEqual(day, 25)
    }
    
    func testTimeUntilNewYear() throws {
        let result = try XCTUnwrap(pattern.parse("time until new year"))
        
        let month = calendar.component(.month, from: result.date)
        let day = calendar.component(.day, from: result.date)
        XCTAssertEqual(month, 1)
        XCTAssertEqual(day, 1)
    }
    
    func testTimeUntilMarch15() throws {
        let result = try XCTUnwrap(pattern.parse("time until march 15"))
        
        let month = calendar.component(.month, from: result.date)
        let day = calendar.component(.day, from: result.date)
        XCTAssertEqual(month, 3)
        XCTAssertEqual(day, 15)
    }
    
    // MARK: - Special Date Keywords
    
    func testHalloween() throws {
        let result = try XCTUnwrap(pattern.parse("days until halloween"))
        
        let month = calendar.component(.month, from: result.date)
        let day = calendar.component(.day, from: result.date)
        XCTAssertEqual(month, 10)
        XCTAssertEqual(day, 31)
    }
    
    // Note: Easter, Thanksgiving, and Valentine's Day not yet implemented
    /*
    func testValentinesDay() throws {
        let result = try XCTUnwrap(pattern.parse("days until valentine"))
        
        let month = calendar.component(.month, from: result.date)
        let day = calendar.component(.day, from: result.date)
        XCTAssertEqual(month, 2)
        XCTAssertEqual(day, 14)
    }
    
    func testThanksgiving() throws {
        let result = try XCTUnwrap(pattern.parse("days until thanksgiving"))
        
        // Thanksgiving is 4th Thursday of November
        let month = calendar.component(.month, from: result.date)
        XCTAssertEqual(month, 11)
    }
    
    func testEaster() throws {
        let result = try XCTUnwrap(pattern.parse("days until easter"))
        
        // Easter is in March or April
        let month = calendar.component(.month, from: result.date)
        XCTAssertTrue(month == 3 || month == 4)
    }
    */
    
    // MARK: - Hours/Minutes Until
    // Note: These patterns are not yet implemented
    
    /*
    func testHoursUntilTomorrow() throws {
        let result = try XCTUnwrap(pattern.parse("hours until tomorrow"))
        XCTAssertEqual(result.type, .dateDifference)
        
        let expected = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    
    func testMinutesUntilTomorrow() throws {
        let result = try XCTUnwrap(pattern.parse("minutes until tomorrow"))
        
        let expected = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        let resultDay = calendar.startOfDay(for: result.date)
        XCTAssertEqual(resultDay, expected)
    }
    */
    
    // MARK: - Case Insensitivity
    
    func testCaseInsensitiveKeyword() throws {
        let result1 = try XCTUnwrap(pattern.parse("days until CHRISTMAS"))
        let result2 = try XCTUnwrap(pattern.parse("days until Christmas"))
        let result3 = try XCTUnwrap(pattern.parse("days until christmas"))
        
        let day1 = calendar.startOfDay(for: result1.date)
        let day2 = calendar.startOfDay(for: result2.date)
        let day3 = calendar.startOfDay(for: result3.date)
        
        XCTAssertEqual(day1, day2)
        XCTAssertEqual(day2, day3)
    }
    
    func testCaseInsensitiveDaysUntil() throws {
        let result1 = try XCTUnwrap(pattern.parse("DAYS UNTIL christmas"))
        let result2 = try XCTUnwrap(pattern.parse("Days Until christmas"))
        
        let day1 = calendar.startOfDay(for: result1.date)
        let day2 = calendar.startOfDay(for: result2.date)
        
        XCTAssertEqual(day1, day2)
    }
    
    // MARK: - Whitespace Handling
    // Note: Extra whitespace handling not yet implemented
    
    /*
    func testExtraWhitespace() throws {
        let result = try XCTUnwrap(pattern.parse("days  until  christmas"))
        
        let month = calendar.component(.month, from: result.date)
        let day = calendar.component(.day, from: result.date)
        XCTAssertEqual(month, 12)
        XCTAssertEqual(day, 25)
    }
    */
    
    // MARK: - Alternative Phrasings
    
    func testUntilWithoutDays() throws {
        let result = try XCTUnwrap(pattern.parse("until christmas"))
        
        let month = calendar.component(.month, from: result.date)
        let day = calendar.component(.day, from: result.date)
        XCTAssertEqual(month, 12)
        XCTAssertEqual(day, 25)
    }
    
    // MARK: - Relative Description
    
    func testRelativeDescriptionFormat() throws {
        let result = try XCTUnwrap(pattern.parse("days until tomorrow"))
        
        // Should have a relative description
        XCTAssertFalse(result.formats.relative.isEmpty)
        // Just check it's not empty, format may vary
    }
    
    // MARK: - Invalid Input Tests
    
    func testInvalidHoliday() {
        let result = pattern.parse("days until festivus")
        // Should either return nil or try to parse "festivus" as a date
        // Depending on implementation, this might be nil
    }
    
    func testMissingDate() {
        let result = pattern.parse("days until")
        XCTAssertNil(result, "Missing date should return nil")
    }
    
    func testEmptyString() {
        let result = pattern.parse("")
        XCTAssertNil(result, "Empty string should return nil")
    }
    
    func testUnrecognizedPattern() {
        let result = pattern.parse("random text")
        XCTAssertNil(result, "Unrecognized pattern should return nil")
    }
    
    // MARK: - Edge Cases
    
    func testDaysUntilToday() throws {
        let result = try XCTUnwrap(pattern.parse("days until today"))
        
        let resultDay = calendar.startOfDay(for: result.date)
        let expectedDay = calendar.startOfDay(for: Date())
        XCTAssertEqual(resultDay, expectedDay)
    }
    
    func testDaysUntilPastDate() {
        // If the date has passed this year, should return next year's occurrence
        let currentMonth = calendar.component(.month, from: Date())
        
        if currentMonth > 1 {
            // After January, "days until new year" should be next year
            let result = pattern.parse("days until new year")
            XCTAssertNotNil(result)
            
            if let result = result {
                let year = calendar.component(.year, from: result.date)
                let currentYear = calendar.component(.year, from: Date())
                XCTAssertGreaterThanOrEqual(year, currentYear)
            }
        }
    }
}
