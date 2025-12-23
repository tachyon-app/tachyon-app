import XCTest
@testable import TachyonCore

/// Tests for the Calculator Engine (TDD approach)
final class CalculatorEngineTests: XCTestCase {
    
    var calculator: CalculatorEngine!
    
    override func setUp() {
        super.setUp()
        calculator = CalculatorEngine()
    }
    
    // MARK: - Basic Arithmetic Tests
    
    func testAddition() throws {
        let result = try XCTUnwrap(calculator.evaluate("2+2"))
        XCTAssertEqual(result.result, 4.0, accuracy: 0.001)
        XCTAssertEqual(result.expression, "2+2")
    }
    
    func testSubtraction() throws {
        let result = try XCTUnwrap(calculator.evaluate("10-3"))
        XCTAssertEqual(result.result, 7.0, accuracy: 0.001)
    }
    
    func testMultiplication() throws {
        let result = try XCTUnwrap(calculator.evaluate("5*6"))
        XCTAssertEqual(result.result, 30.0, accuracy: 0.001)
    }
    
    func testDivision() throws {
        let result = try XCTUnwrap(calculator.evaluate("20/4"))
        XCTAssertEqual(result.result, 5.0, accuracy: 0.001)
    }
    
    func testDivisionByZero() {
        let result = calculator.evaluate("10/0")
        XCTAssertNil(result, "Division by zero should return nil")
    }
    
    // MARK: - Operator Precedence Tests
    
    func testOperatorPrecedence() throws {
        let result = try XCTUnwrap(calculator.evaluate("2+3*4"))
        XCTAssertEqual(result.result, 14.0, accuracy: 0.001, "Should be 2+(3*4)=14, not (2+3)*4=20")
    }
    
    func testParentheses() throws {
        let result = try XCTUnwrap(calculator.evaluate("(2+3)*4"))
        XCTAssertEqual(result.result, 20.0, accuracy: 0.001)
    }
    
    func testNestedParentheses() throws {
        let result = try XCTUnwrap(calculator.evaluate("((2+3)*4)+1"))
        XCTAssertEqual(result.result, 21.0, accuracy: 0.001)
    }
    
    // MARK: - Percentage Tests
    
    func testPercentageMultiplication() throws {
        let result = try XCTUnwrap(calculator.evaluate("100*30%"))
        XCTAssertEqual(result.result, 30.0, accuracy: 0.001, "100*30% should be 30")
        XCTAssertEqual(result.type, .percentage)
        XCTAssertEqual(result.inputLabel, "Percentage")
    }
    
    func testPercentageAddition() throws {
        let result = try XCTUnwrap(calculator.evaluate("50+10%"))
        XCTAssertEqual(result.result, 55.0, accuracy: 0.001, "50+10% should be 55 (50 + 5)")
    }
    
    func testPercentageSubtraction() throws {
        let result = try XCTUnwrap(calculator.evaluate("100-20%"))
        XCTAssertEqual(result.result, 80.0, accuracy: 0.001, "100-20% should be 80")
    }
    
    // MARK: - Math Functions Tests
    
    func testSquareRoot() throws {
        let result = try XCTUnwrap(calculator.evaluate("sqrt(16)"))
        XCTAssertEqual(result.result, 4.0, accuracy: 0.001)
    }
    
    func testSine() throws {
        let result = try XCTUnwrap(calculator.evaluate("sin(0)"))
        XCTAssertEqual(result.result, 0.0, accuracy: 0.001)
    }
    
    func testCosine() throws {
        let result = try XCTUnwrap(calculator.evaluate("cos(0)"))
        XCTAssertEqual(result.result, 1.0, accuracy: 0.001)
    }
    
    func testLogarithm() throws {
        let result = try XCTUnwrap(calculator.evaluate("log(100)"))
        XCTAssertEqual(result.result, 2.0, accuracy: 0.001, "log base 10 of 100 is 2")
    }
    
    func testNaturalLog() throws {
        let result = try XCTUnwrap(calculator.evaluate("ln(2.718281828)"))
        XCTAssertEqual(result.result, 1.0, accuracy: 0.001)
    }
    
    func testAbsoluteValue() throws {
        let result = try XCTUnwrap(calculator.evaluate("abs(-5)"))
        XCTAssertEqual(result.result, 5.0, accuracy: 0.001)
    }
    
    // MARK: - Constants Tests
    
    func testPiConstant() throws {
        let result = try XCTUnwrap(calculator.evaluate("pi"))
        XCTAssertEqual(result.result, Double.pi, accuracy: 0.001)
    }
    
    func testEulerConstant() throws {
        let result = try XCTUnwrap(calculator.evaluate("e"))
        XCTAssertEqual(result.result, M_E, accuracy: 0.001)
    }
    
    func testPiInExpression() throws {
        let result = try XCTUnwrap(calculator.evaluate("2*pi"))
        XCTAssertEqual(result.result, 2 * Double.pi, accuracy: 0.001)
    }
    
    // MARK: - Scientific Notation Tests
    
    func testScientificNotationPositive() throws {
        let result = try XCTUnwrap(calculator.evaluate("2e3"))
        XCTAssertEqual(result.result, 2000.0, accuracy: 0.001)
    }
    
    func testScientificNotationNegative() throws {
        let result = try XCTUnwrap(calculator.evaluate("3.14e-2"))
        XCTAssertEqual(result.result, 0.0314, accuracy: 0.0001)
    }
    
    // MARK: - Decimal Tests
    
    func testDecimalNumbers() throws {
        let result = try XCTUnwrap(calculator.evaluate("3.14+2.86"))
        XCTAssertEqual(result.result, 6.0, accuracy: 0.001)
    }
    
    func testNegativeNumbers() throws {
        let result = try XCTUnwrap(calculator.evaluate("-5+3"))
        XCTAssertEqual(result.result, -2.0, accuracy: 0.001)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyExpression() {
        let result = calculator.evaluate("")
        XCTAssertNil(result, "Empty expression should return nil")
    }
    
    func testInvalidExpression() {
        let result = calculator.evaluate("2++3")
        XCTAssertNil(result, "Invalid expression should return nil")
    }
    
    func testUnmatchedParentheses() {
        let result = calculator.evaluate("(2+3")
        XCTAssertNil(result, "Unmatched parentheses should return nil")
    }
    
    func testWhitespace() throws {
        let result = try XCTUnwrap(calculator.evaluate("  2  +  3  "))
        XCTAssertEqual(result.result, 5.0, accuracy: 0.001)
    }
    
    // MARK: - Formatting Tests
    
    func testFormattedResult() throws {
        let result = try XCTUnwrap(calculator.evaluate("1000+500"))
        XCTAssertEqual(result.formattedResult, "1,500", "Large numbers should have thousand separators")
    }
    
    func testFormattedResultDecimal() throws {
        let result = try XCTUnwrap(calculator.evaluate("10/3"))
        // Should round to reasonable decimal places
        XCTAssertTrue(result.formattedResult.hasPrefix("3.33"))
    }
    
    // MARK: - Output Label Tests (Number to Words)
    
    func testOutputLabelSmallNumber() throws {
        let result = try XCTUnwrap(calculator.evaluate("30"))
        XCTAssertEqual(result.outputLabel, "Thirty")
    }
    
    func testOutputLabelLargeNumber() throws {
        let result = try XCTUnwrap(calculator.evaluate("1000"))
        XCTAssertEqual(result.outputLabel, "One Thousand")
    }
}
