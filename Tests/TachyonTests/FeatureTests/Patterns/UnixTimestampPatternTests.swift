import XCTest
@testable import TachyonCore

/// Tests for Unix Timestamp Pattern (TDD approach)
final class UnixTimestampPatternTests: XCTestCase {
    
    var pattern: UnixTimestampPattern!
    
    override func setUp() {
        super.setUp()
        pattern = UnixTimestampPattern()
    }
    
    // MARK: - 10-Digit Timestamp Tests (Seconds)
    
    func testTenDigitTimestamp() throws {
        let result = try XCTUnwrap(pattern.parse("1703347200"))
        XCTAssertEqual(result.type, .unixTimestamp)
        XCTAssertEqual(result.formats.unixSeconds, 1703347200)
    }
    
    func testTenDigitTimestampWithText() throws {
        let result = try XCTUnwrap(pattern.parse("timestamp: 1703347200"))
        XCTAssertEqual(result.formats.unixSeconds, 1703347200)
    }
    
    // MARK: - 13-Digit Timestamp Tests (Milliseconds)
    
    func testThirteenDigitTimestamp() throws {
        let result = try XCTUnwrap(pattern.parse("1703347200000"))
        XCTAssertEqual(result.type, .unixTimestamp)
        XCTAssertEqual(result.formats.unixMilliseconds, 1703347200000)
    }
    
    func testThirteenDigitTimestampConversion() throws {
        let result = try XCTUnwrap(pattern.parse("1703347200000"))
        // Should convert milliseconds to seconds correctly
        XCTAssertEqual(result.formats.unixSeconds, 1703347200)
    }
    
    // MARK: - 16-Digit Timestamp Tests (Microseconds)
    
    func testSixteenDigitTimestamp() throws {
        let result = try XCTUnwrap(pattern.parse("1703347200000000"))
        XCTAssertEqual(result.type, .unixTimestamp)
    }
    
    // MARK: - Keyword Tests
    
    func testNowInUnixKeyword() throws {
        let result = try XCTUnwrap(pattern.parse("now in unix"))
        XCTAssertEqual(result.type, .unixTimestamp)
        XCTAssertNotNil(result.formats.unixSeconds)
        // Should be close to current time (within 5 seconds)
        let timestamp = result.formats.unixSeconds
        let now = Int64(Date().timeIntervalSince1970)
        XCTAssertLessThan(abs(timestamp - now), 5)
    }
    
    func testCurrentEpochKeyword() throws {
        let result = try XCTUnwrap(pattern.parse("current epoch"))
        XCTAssertEqual(result.type, .unixTimestamp)
        XCTAssertNotNil(result.formats.unixSeconds)
    }
    
    func testUnixTimestampKeyword() throws {
        let result = try XCTUnwrap(pattern.parse("unix timestamp"))
        XCTAssertEqual(result.type, .unixTimestamp)
    }
    
    // MARK: - Invalid Input Tests
    
    func testTooShortTimestamp() {
        let result = pattern.parse("123456789") // 9 digits
        XCTAssertNil(result, "9-digit number should not be recognized as timestamp")
    }
    
    func testTooLongTimestamp() {
        let result = pattern.parse("12345678901234567") // 17 digits
        XCTAssertNil(result, "17-digit number should not be recognized as timestamp")
    }
    
    func testNonNumericInput() {
        let result = pattern.parse("abcdefghij")
        XCTAssertNil(result, "Non-numeric input should return nil")
    }
    
    func testEmptyString() {
        let result = pattern.parse("")
        XCTAssertNil(result, "Empty string should return nil")
    }
    
    func testWhitespaceOnly() {
        let result = pattern.parse("   ")
        XCTAssertNil(result, "Whitespace-only input should return nil")
    }
    
    // MARK: - Format Output Tests
    
    func testISO8601Format() throws {
        let result = try XCTUnwrap(pattern.parse("1703347200"))
        XCTAssertFalse(result.formats.iso8601.isEmpty)
        XCTAssertTrue(result.formats.iso8601.contains("2023") || result.formats.iso8601.contains("2024"))
    }
    
    func testRFC2822Format() throws {
        let result = try XCTUnwrap(pattern.parse("1703347200"))
        XCTAssertFalse(result.formats.rfc2822.isEmpty)
    }
    
    func testHumanReadableFormat() throws {
        let result = try XCTUnwrap(pattern.parse("1703347200"))
        XCTAssertFalse(result.formats.humanReadable.isEmpty)
    }
    
    // MARK: - Edge Cases
    
    func testZeroTimestamp() {
        // Unix epoch start: Jan 1, 1970
        let result = pattern.parse("0")
        // Should not match (too short)
        XCTAssertNil(result)
    }
    
    func testNegativeTimestamp() {
        let result = pattern.parse("-1703347200")
        // The regex extracts the number part, ignoring the minus sign
        XCTAssertNotNil(result)
        if let result = result {
            XCTAssertEqual(result.formats.unixSeconds, 1703347200)
        }
    }
}
