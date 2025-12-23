import XCTest
@testable import TachyonCore

/// Tests for TimezonePattern (TDD approach)
final class TimezonePatternTests: XCTestCase {
    
    var pattern: TimezonePattern!
    var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        pattern = TimezonePattern()
        calendar = Calendar.current
    }
    
    // MARK: - Basic Timezone Query Tests
    
    func testTimeInCity() {
        let result = pattern.parse("time in tokyo")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .timezone)
        XCTAssertEqual(result?.timeZone.identifier, "Asia/Tokyo")
    }
    
    func testTimeInNewYork() {
        let result = pattern.parse("time in new york")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.timeZone.identifier, "America/New_York")
    }
    
    func testTimeInLondon() {
        let result = pattern.parse("time in london")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.timeZone.identifier, "Europe/London")
    }
    
    // MARK: - City Name Variations
    
    func testCityAbbreviation() {
        let result = pattern.parse("time in nyc")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.timeZone.identifier, "America/New_York")
    }
    
    func testCityAlias() {
        let result = pattern.parse("time in sf")
        
        XCTAssertNotNil(result)
        // SF should map to San Francisco
        XCTAssertTrue(result?.timeZone.identifier.contains("Los_Angeles") ?? false)
    }
    
    // MARK: - Timezone Conversion Tests
    
    func testTimezoneConversion() {
        let result = pattern.parse("5pm london in tokyo")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .timezone)
        XCTAssertEqual(result?.timeZone.identifier, "Asia/Tokyo")
    }
    
    func testTimezoneConversionWithAM() {
        let result = pattern.parse("9am nyc in london")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.timeZone.identifier, "Europe/London")
    }
    
    // MARK: - Case Insensitivity Tests
    
    func testCaseInsensitive() {
        let result1 = pattern.parse("time in TOKYO")
        let result2 = pattern.parse("time in Tokyo")
        let result3 = pattern.parse("time in tokyo")
        
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertNotNil(result3)
        
        XCTAssertEqual(result1?.timeZone, result2?.timeZone)
        XCTAssertEqual(result2?.timeZone, result3?.timeZone)
    }
    
    // MARK: - Invalid Input Tests
    
    func testInvalidCity() {
        let result = pattern.parse("time in invalidcity123")
        
        XCTAssertNil(result)
    }
    
    func testEmptyInput() {
        let result = pattern.parse("")
        
        XCTAssertNil(result)
    }
    
    func testMissingCity() {
        let result = pattern.parse("time in")
        
        XCTAssertNil(result)
    }
    
    // MARK: - Common Cities Coverage
    
    func testCommonCities() {
        let cities = [
            ("tokyo", "Asia/Tokyo"),
            ("london", "Europe/London"),
            ("paris", "Europe/Paris"),
            ("sydney", "Australia/Sydney"),
            ("dubai", "Asia/Dubai")
        ]
        
        for (city, expectedTz) in cities {
            let result = pattern.parse("time in \(city)")
            XCTAssertNotNil(result, "Failed to parse: \(city)")
            XCTAssertEqual(result?.timeZone.identifier, expectedTz, "Wrong timezone for: \(city)")
        }
    }
}
