import XCTest
@testable import TachyonCore

/// Tests for DateResult model (TDD approach)
final class DateResultTests: XCTestCase {
    
    var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        calendar = Calendar.current
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        let date = Date()
        let result = DateResult(date: date, type: .naturalLanguage, expression: "today")
        
        XCTAssertEqual(result.date, date)
        XCTAssertEqual(result.type, .naturalLanguage)
        XCTAssertEqual(result.expression, "today")
        XCTAssertEqual(result.timeZone, .current)
    }
    
    func testInitializationWithCustomTimezone() {
        let date = Date()
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        let result = DateResult(date: date, type: .timezone, expression: "time in tokyo", timeZone: tokyo)
        
        XCTAssertEqual(result.timeZone, tokyo)
    }
    
    // MARK: - Unix Timestamp Format Tests
    
    func testUnixSecondsFormat() {
        let timestamp: TimeInterval = 1703347200
        let date = Date(timeIntervalSince1970: timestamp)
        let result = DateResult(date: date, type: .unixTimestamp, expression: "1703347200")
        
        XCTAssertEqual(result.formats.unixSeconds, 1703347200)
    }
    
    func testUnixMillisecondsFormat() {
        let timestamp: TimeInterval = 1703347200
        let date = Date(timeIntervalSince1970: timestamp)
        let result = DateResult(date: date, type: .unixTimestamp, expression: "1703347200")
        
        XCTAssertEqual(result.formats.unixMilliseconds, 1703347200000)
    }
    
    // MARK: - ISO 8601 Format Tests
    
    func testISO8601Format() {
        let date = Date()
        let result = DateResult(date: date, type: .naturalLanguage, expression: "now")
        
        XCTAssertFalse(result.formats.iso8601.isEmpty)
        XCTAssertTrue(result.formats.iso8601.contains("T"))
        XCTAssertTrue(result.formats.iso8601.contains("-"))
    }
    
    // MARK: - RFC 2822 Format Tests
    
    func testRFC2822Format() {
        let date = Date()
        let result = DateResult(date: date, type: .naturalLanguage, expression: "now")
        
        XCTAssertFalse(result.formats.rfc2822.isEmpty)
        // RFC 2822 format includes day name
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        XCTAssertTrue(dayNames.contains(where: { result.formats.rfc2822.contains($0) }))
    }
    
    // MARK: - Human Readable Format Tests
    
    func testHumanReadableFormat() {
        let date = Date()
        let result = DateResult(date: date, type: .naturalLanguage, expression: "now")
        
        XCTAssertFalse(result.formats.humanReadable.isEmpty)
        // Should contain day name
        let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        XCTAssertTrue(dayNames.contains(where: { result.formats.humanReadable.contains($0) }))
    }
    
    // MARK: - Relative Format Tests
    
    func testRelativeFormatFuture() {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let result = DateResult(date: tomorrow, type: .naturalLanguage, expression: "tomorrow")
        
        XCTAssertFalse(result.formats.relative.isEmpty)
        // Should indicate future
        XCTAssertTrue(result.formats.relative.contains("in") || result.formats.relative.contains("tomorrow"))
    }
    
    func testRelativeFormatPast() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let result = DateResult(date: yesterday, type: .naturalLanguage, expression: "yesterday")
        
        XCTAssertFalse(result.formats.relative.isEmpty)
        // Should indicate past
        XCTAssertTrue(result.formats.relative.contains("ago") || result.formats.relative.contains("yesterday"))
    }
    
    // MARK: - Primary Subtitle Tests
    
    func testPrimarySubtitleUnixTimestamp() {
        let date = Date()
        let result = DateResult(date: date, type: .unixTimestamp, expression: "now")
        
        let subtitle = result.primarySubtitle
        XCTAssertTrue(subtitle.contains("Unix:"))
        XCTAssertTrue(subtitle.contains("ISO:"))
    }
    
    func testPrimarySubtitleNaturalLanguage() {
        let date = Date()
        let result = DateResult(date: date, type: .naturalLanguage, expression: "today")
        
        let subtitle = result.primarySubtitle
        XCTAssertTrue(subtitle.contains("•"))
    }
    
    func testPrimarySubtitleTimezone() {
        let date = Date()
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        let result = DateResult(date: date, type: .timezone, expression: "time in tokyo", timeZone: tokyo)
        
        let subtitle = result.primarySubtitle
        XCTAssertTrue(subtitle.contains("Asia/Tokyo"))
    }
    
    func testPrimarySubtitleDateDifference() {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let result = DateResult(date: tomorrow, type: .dateDifference, expression: "days until tomorrow")
        
        let subtitle = result.primarySubtitle
        XCTAssertFalse(subtitle.isEmpty)
    }
    
    func testPrimarySubtitleWeekDayInfo() {
        let date = Date()
        let result = DateResult(date: date, type: .weekDayInfo, expression: "week number")
        
        let subtitle = result.primarySubtitle
        XCTAssertTrue(subtitle.contains("Week"))
        XCTAssertTrue(subtitle.contains("Day"))
    }
    
    // MARK: - Date Difference Relative Description Tests
    
    func testDateDifferenceExactDayCount() {
        let futureDate = calendar.date(byAdding: .day, value: 10, to: calendar.startOfDay(for: Date()))!
        let result = DateResult(date: futureDate, type: .dateDifference, expression: "days until")
        
        // Should show exact day count
        XCTAssertTrue(result.formats.relative.contains("10") || result.formats.relative.contains("day"))
    }
    
    func testDateDifferenceNegative() {
        let pastDate = calendar.date(byAdding: .day, value: -5, to: Date())!
        let result = DateResult(date: pastDate, type: .dateDifference, expression: "days since")
        
        // Should indicate past
        XCTAssertTrue(result.formats.relative.contains("ago"))
    }
    
    // MARK: - Type-Specific Behavior Tests
    
    func testAllDateResultTypes() {
        let date = Date()
        let types: [DateResultType] = [
            .unixTimestamp,
            .naturalLanguage,
            .dateArithmetic,
            .timezone,
            .dateDifference,
            .weekDayInfo
        ]
        
        for type in types {
            let result = DateResult(date: date, type: type, expression: "test")
            XCTAssertEqual(result.type, type)
            XCTAssertFalse(result.primarySubtitle.isEmpty, "Subtitle should not be empty for type \(type)")
        }
    }
    
    // MARK: - Edge Cases
    
    func testVeryFarFutureDate() {
        let farFuture = calendar.date(byAdding: .year, value: 100, to: Date())!
        let result = DateResult(date: farFuture, type: .naturalLanguage, expression: "in 100 years")
        
        XCTAssertNotNil(result.formats.iso8601)
        XCTAssertNotNil(result.formats.humanReadable)
    }
    
    func testVeryFarPastDate() {
        let farPast = calendar.date(byAdding: .year, value: -100, to: Date())!
        let result = DateResult(date: farPast, type: .naturalLanguage, expression: "100 years ago")
        
        XCTAssertNotNil(result.formats.iso8601)
        XCTAssertNotNil(result.formats.humanReadable)
    }
}
