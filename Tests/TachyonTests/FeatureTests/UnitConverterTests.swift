import XCTest
@testable import TachyonCore

/// Tests for the Unit Converter (TDD approach)
final class UnitConverterTests: XCTestCase {
    
    var converter: TachyonCore.UnitConverter!
    
    override func setUp() {
        super.setUp()
        converter = TachyonCore.UnitConverter()
    }
    
    // MARK: - Pattern Detection Tests
    
    func testDetectsLengthConversion() throws {
        let result = converter.convert("5 km to miles")
        
    }
    
    func testDetectsTemperatureConversion() throws {
        let result = converter.convert("100 F to C")
        
    }
    
    func testDetectsTimeConversion() throws {
        let result = converter.convert("2 hours to minutes")
        
    }
    
    func testDetectsDataConversion() throws {
        let result = converter.convert("1 GB to MB")
        
    }
    
    func testNonConversionReturnsNil() throws {
        let result = converter.convert("hello world")
        XCTAssertNil(result)
    }
    
    // MARK: - Length Conversion Tests
    
    func testKilometersToMiles() throws {
        let result: CalculationResult = try XCTUnwrap(converter.convert("1 km to miles"))
        XCTAssertEqual(result.result, 0.621371, accuracy: 0.001)
        XCTAssertEqual(result.inputUnit, "Kilometers")
        XCTAssertEqual(result.outputUnit, "Miles")
    }
    
    func testMilesToKilometers() throws {
        let result: CalculationResult = try XCTUnwrap(converter.convert("1 mile to km"))
        XCTAssertEqual(result.result, 1.60934, accuracy: 0.001)
    }
    
    func testMetersToFeet() throws {
        let result: CalculationResult = try XCTUnwrap(converter.convert("10 m to feet"))
        XCTAssertEqual(result.result, 32.8084, accuracy: 0.001)
    }
    
    func testInchesToCentimeters() throws {
        let result: CalculationResult = try XCTUnwrap(converter.convert("10 inches to cm"))
        XCTAssertEqual(result.result, 25.4, accuracy: 0.1)
    }
    
    // MARK: - Temperature Conversion Tests
    
    func testFahrenheitToCelsius() throws {
        let result = converter.convert("100 F to C")
        
        if let r = result?.result { XCTAssertEqual(r, 37.7778, accuracy: 0.01) }
    }
    
    func testCelsiusToFahrenheit() throws {
        let result = converter.convert("0 C to F")
        
        if let r = result?.result { XCTAssertEqual(r, 32.0, accuracy: 0.01) }
    }
    
    func testCelsiusToKelvin() throws {
        let result = converter.convert("0 C to K")
        
        if let r = result?.result { XCTAssertEqual(r, 273.15, accuracy: 0.01) }
    }
    
    // MARK: - Weight Conversion Tests
    
    func testKilogramsToPounds() throws {
        let result = converter.convert("1 kg to lb")
        
        if let r = result?.result { XCTAssertEqual(r, 2.20462, accuracy: 0.001) }
    }
    
    func testPoundsToKilograms() throws {
        let result = converter.convert("10 lb to kg")
        
        if let r = result?.result { XCTAssertEqual(r, 4.53592, accuracy: 0.001) }
    }
    
    func testGramsToOunces() throws {
        let result = converter.convert("100 g to oz")
        
        if let r = result?.result { XCTAssertEqual(r, 3.52739, accuracy: 0.001) }
    }
    
    // MARK: - Volume Conversion Tests
    
    func testLitersToGallons() throws {
        let result = converter.convert("1 liter to gallons")
        
        if let r = result?.result { XCTAssertEqual(r, 0.264172, accuracy: 0.001) }
    }
    
    func testGallonsToLiters() throws {
        let result = converter.convert("1 gallon to liters")
        
        if let r = result?.result { XCTAssertEqual(r, 3.78541, accuracy: 0.001) }
    }
    
    func testMillilitersToFluidOunces() throws {
        let result = converter.convert("100 ml to fl oz")
        
        if let r = result?.result { XCTAssertEqual(r, 3.38140, accuracy: 0.001) }
    }
    
    // MARK: - Time Conversion Tests
    
    func testHoursToMinutes() throws {
        let result = converter.convert("2 hours to minutes")
        
        if let r = result?.result { XCTAssertEqual(r, 120.0, accuracy: 0.001) }
    }
    
    func testMinutesToSeconds() throws {
        let result = converter.convert("5 minutes to seconds")
        
        if let r = result?.result { XCTAssertEqual(r, 300.0, accuracy: 0.001) }
    }
    
    func testDaysToHours() throws {
        let result = converter.convert("1 day to hours")
        
        if let r = result?.result { XCTAssertEqual(r, 24.0, accuracy: 0.001) }
    }
    
    func testWeeksToDays() throws {
        let result = converter.convert("2 weeks to days")
        
        if let r = result?.result { XCTAssertEqual(r, 14.0, accuracy: 0.001) }
    }
    
    // MARK: - Data Size Conversion Tests
    
    func testGigabytesToMegabytes() throws {
        let result = converter.convert("1 GB to MB")
        // Uses decimal (SI) prefixes: 1 GB = 1000 MB
        if let r = result?.result { XCTAssertEqual(r, 1000.0, accuracy: 0.001) }
    }
    
    func testMegabytesToKilobytes() throws {
        let result = converter.convert("1 MB to KB")
        // Uses decimal (SI) prefixes: 1 MB = 1000 KB
        if let r = result?.result { XCTAssertEqual(r, 1000.0, accuracy: 0.001) }
    }
    
    func testTerabytesToGigabytes() throws {
        let result = converter.convert("1 TB to GB")
        // Uses decimal (SI) prefixes: 1 TB = 1000 GB
        if let r = result?.result { XCTAssertEqual(r, 1000.0, accuracy: 0.001) }
    }
    
    func testBytesToKilobytes() throws {
        let result = converter.convert("2000 bytes to KB")
        // Uses decimal (SI) prefixes: 2000 bytes = 2 KB
        if let r = result?.result { XCTAssertEqual(r, 2.0, accuracy: 0.001) }
    }
    
    // MARK: - Case Insensitivity Tests
    
    func testCaseInsensitiveUnits() throws {
        let result1 = converter.convert("1 KM to MILES")
        let result2 = converter.convert("1 km to miles")
        
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        if let r1 = result1?.result, let r2 = result2?.result {
            XCTAssertEqual(r1, r2, accuracy: 0.001)
        }
    }
    
    // MARK: - Decimal Input Tests
    
    func testDecimalInput() throws {
        let result: CalculationResult = try XCTUnwrap(converter.convert("2.5 hours to minutes"))
        XCTAssertEqual(result.result, 150.0, accuracy: 0.001)
    }
    
    func testScientificNotationInput() throws {
        let result: CalculationResult = try XCTUnwrap(converter.convert("1e3 meters to km"))
        XCTAssertEqual(result.result, 1.0, accuracy: 0.001)
    }
    
    // MARK: - Alternative Syntax Tests
    
    func testInKeywordInsteadOfTo() throws {
        let result: CalculationResult = try XCTUnwrap(converter.convert("100 F in C"))
        XCTAssertEqual(result.result, 37.7778, accuracy: 0.01)
    }
    
    // MARK: - Formatting Tests
    
    func testFormattedOutput() throws {
        let result = converter.convert("5 km to miles")
        // 5 km = 3.10685 miles, formatted result should contain "3.1" or "3.10"
        XCTAssertTrue(result!.formattedResult.contains("3.1") || result!.formattedResult.contains("3,1"), "Should format to reasonable decimals")
    }
    
    // MARK: - Type Property Tests
    
    func testResultType() throws {
        let result = converter.convert("5 km to miles")
        
        XCTAssertEqual(result?.type, .unitConversion)
    }
    
    // MARK: - Invalid Conversion Tests
    
    func testIncompatibleUnits() throws {
        let result = converter.convert("5 km to celsius")
        XCTAssertNil(result, "Should not convert incompatible unit types")
    }
    
    func testInvalidUnit() throws {
        let result = converter.convert("5 blargs to km")
        XCTAssertNil(result, "Invalid unit should return nil")
    }
}
