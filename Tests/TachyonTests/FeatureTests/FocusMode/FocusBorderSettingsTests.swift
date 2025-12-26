import XCTest
@testable import TachyonCore

/// Tests for FocusBorderSettings data model (TDD)
final class FocusBorderSettingsTests: XCTestCase {
    
    // MARK: - Default Values Tests
    
    func testDefaultValues() {
        let settings = FocusBorderSettings()
        
        XCTAssertFalse(settings.isEnabled)
        XCTAssertEqual(settings.thickness, .medium)
    }
    
    func testCustomValues() {
        let settings = FocusBorderSettings(
            isEnabled: true,
            colorHex: "#FF5733",
            thickness: .thick
        )
        
        XCTAssertTrue(settings.isEnabled)
        XCTAssertEqual(settings.colorHex, "#FF5733")
        XCTAssertEqual(settings.thickness, .thick)
    }
    
    // MARK: - Thickness Tests
    
    func testThicknessValues() {
        XCTAssertEqual(BorderThickness.thin.pixelWidth, 4)
        XCTAssertEqual(BorderThickness.medium.pixelWidth, 8)
        XCTAssertEqual(BorderThickness.thick.pixelWidth, 12)
    }
    
    func testAllThicknessCases() {
        let cases = BorderThickness.allCases
        
        XCTAssertEqual(cases.count, 3)
        XCTAssertTrue(cases.contains(.thin))
        XCTAssertTrue(cases.contains(.medium))
        XCTAssertTrue(cases.contains(.thick))
    }
    
    // MARK: - Codable Tests
    
    func testEncodeDecode() throws {
        let settings = FocusBorderSettings(
            isEnabled: true,
            colorHex: "#00FF00",
            thickness: .thin
        )
        
        let encoded = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(FocusBorderSettings.self, from: encoded)
        
        XCTAssertEqual(decoded.isEnabled, settings.isEnabled)
        XCTAssertEqual(decoded.colorHex, settings.colorHex)
        XCTAssertEqual(decoded.thickness, settings.thickness)
    }
}
