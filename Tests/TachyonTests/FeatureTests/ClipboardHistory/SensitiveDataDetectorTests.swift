import XCTest
@testable import TachyonCore

/// Tests for SensitiveDataDetector (TDD approach)
final class SensitiveDataDetectorTests: XCTestCase {
    
    // MARK: - Credit Card Pattern Tests
    
    func testDetectsVisaCard() {
        // Visa starts with 4, 13 or 16 digits
        XCTAssertTrue(SensitiveDataDetector.containsSensitiveData("4111111111111111"))
        XCTAssertTrue(SensitiveDataDetector.containsSensitiveData("4222222222222"))
    }
    
    func testDetectsMastercardCard() {
        // Mastercard starts with 51-55, 16 digits
        XCTAssertTrue(SensitiveDataDetector.containsSensitiveData("5111111111111118"))
        XCTAssertTrue(SensitiveDataDetector.containsSensitiveData("5500000000000004"))
    }
    
    func testDetectsAmexCard() {
        // Amex starts with 34 or 37, 15 digits
        XCTAssertTrue(SensitiveDataDetector.containsSensitiveData("340000000000009"))
        XCTAssertTrue(SensitiveDataDetector.containsSensitiveData("370000000000002"))
    }
    
    func testDetectsDiscoverCard() {
        // Discover starts with 6011 or 65, 16 digits
        XCTAssertTrue(SensitiveDataDetector.containsSensitiveData("6011111111111117"))
        XCTAssertTrue(SensitiveDataDetector.containsSensitiveData("6500000000000002"))
    }
    
    func testDetectsCardWithSpaces() {
        // Credit cards are often formatted with spaces
        XCTAssertTrue(SensitiveDataDetector.containsSensitiveData("4111 1111 1111 1111"))
        XCTAssertTrue(SensitiveDataDetector.containsSensitiveData("5111 1111 1111 1118"))
    }
    
    func testDetectsCardWithDashes() {
        // Credit cards are sometimes formatted with dashes
        XCTAssertTrue(SensitiveDataDetector.containsSensitiveData("4111-1111-1111-1111"))
        XCTAssertTrue(SensitiveDataDetector.containsSensitiveData("5111-1111-1111-1118"))
    }
    
    func testDetectsCardInText() {
        // Card number embedded in text
        XCTAssertTrue(SensitiveDataDetector.containsSensitiveData("My credit card is 4111111111111111 please charge it"))
        XCTAssertTrue(SensitiveDataDetector.containsSensitiveData("Payment: 5111 1111 1111 1118"))
    }
    
    // MARK: - False Positive Prevention Tests
    
    func testDoesNotDetectShortNumbers() {
        // Short numbers should not be detected as credit cards
        XCTAssertFalse(SensitiveDataDetector.containsSensitiveData("1234567890"))
        XCTAssertFalse(SensitiveDataDetector.containsSensitiveData("411111111111")) // 12 digits
    }
    
    func testDoesNotDetectRandomText() {
        // Normal text should not trigger detection
        XCTAssertFalse(SensitiveDataDetector.containsSensitiveData("Hello world"))
        XCTAssertFalse(SensitiveDataDetector.containsSensitiveData("This is a normal sentence"))
        XCTAssertFalse(SensitiveDataDetector.containsSensitiveData("function calculateTotal() {}"))
    }
    
    func testDoesNotDetectPhoneNumbers() {
        // Phone numbers should not be detected
        XCTAssertFalse(SensitiveDataDetector.containsSensitiveData("+1 555 123 4567"))
        XCTAssertFalse(SensitiveDataDetector.containsSensitiveData("(555) 123-4567"))
    }
    
    func testDoesNotDetectDates() {
        // Dates should not be detected
        XCTAssertFalse(SensitiveDataDetector.containsSensitiveData("2024-01-15"))
        XCTAssertFalse(SensitiveDataDetector.containsSensitiveData("15/01/2024"))
    }
    
    func testDoesNotDetectIpAddresses() {
        // IP addresses should not be detected
        XCTAssertFalse(SensitiveDataDetector.containsSensitiveData("192.168.1.1"))
        XCTAssertFalse(SensitiveDataDetector.containsSensitiveData("10.0.0.1"))
    }
    
    // MARK: - Empty Input Tests
    
    func testEmptyInput() {
        XCTAssertFalse(SensitiveDataDetector.containsSensitiveData(""))
    }
    
    func testWhitespaceOnlyInput() {
        XCTAssertFalse(SensitiveDataDetector.containsSensitiveData("   "))
    }
    
    // MARK: - Multiline Text Tests
    
    func testDetectsCardInMultilineText() {
        let text = """
        Order Details:
        Name: John Doe
        Card: 4111111111111111
        Amount: $99.99
        """
        XCTAssertTrue(SensitiveDataDetector.containsSensitiveData(text))
    }
    
    func testNormalMultilineText() {
        let text = """
        This is a normal document
        with multiple lines
        and no sensitive data
        """
        XCTAssertFalse(SensitiveDataDetector.containsSensitiveData(text))
    }
}
