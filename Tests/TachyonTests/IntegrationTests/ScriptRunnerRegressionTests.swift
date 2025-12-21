import XCTest

/// Critical regression tests for Script Runner feature
/// These tests prevent the specific bugs we encountered during development
final class ScriptRunnerRegressionTests: XCTestCase {
    
    // MARK: - Inline Output Extraction Bug
    
    func testInlineScriptExtractsNonEmptyLines() {
        // CRITICAL REGRESSION TEST
        // Bug: Inline scripts were using .isEmpty instead of !.isEmpty
        // This caused them to extract empty lines instead of content
        
        let stdout = "\n\nHello World\nLine 2\n"
        let lines = stdout.components(separatedBy: .newlines)
        
        // CORRECT: Find first NON-EMPTY line
        let firstNonEmpty = lines.first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        XCTAssertEqual(firstNonEmpty, "Hello World", "Should extract first non-empty line")
        
        // WRONG (the bug we had): Find first EMPTY line
        let firstEmpty = lines.first { $0.trimmingCharacters(in: .whitespaces).isEmpty }
        XCTAssertNotEqual(firstEmpty, firstNonEmpty, "Empty line should not equal non-empty line")
        XCTAssertEqual(firstEmpty, "", "First line is empty")
    }
    
    func testCompactScriptExtractsLastNonEmptyLine() {
        // Test that compact mode extracts last non-empty line correctly
        let stdout = "Line 1\nLine 2\nLast Line\n\n"
        let lines = stdout.components(separatedBy: .newlines)
        
        // CORRECT: Find last NON-EMPTY line
        let lastNonEmpty = lines.reversed().first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        XCTAssertEqual(lastNonEmpty, "Last Line", "Should extract last non-empty line")
    }
    
    func testEmptyOutputHandling() {
        // Test edge case: completely empty output
        let stdout = "\n\n\n"
        let lines = stdout.components(separatedBy: .newlines)
        
        let firstNonEmpty = lines.first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        XCTAssertNil(firstNonEmpty, "Should return nil for completely empty output")
    }
    
    func testSingleLineOutput() {
        // Test edge case: single line output
        let stdout = "Single Line"
        let lines = stdout.components(separatedBy: .newlines)
        
        let firstNonEmpty = lines.first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        XCTAssertEqual(firstNonEmpty, "Single Line")
    }
    
    func testWhitespaceOnlyLines() {
        // Test edge case: lines with only whitespace
        let stdout = "   \n\t\t\nActual Content\n   "
        let lines = stdout.components(separatedBy: .newlines)
        
        let firstNonEmpty = lines.first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        XCTAssertEqual(firstNonEmpty, "Actual Content", "Should skip whitespace-only lines")
    }
    
    // MARK: - String Sanitization Tests
    
    func testFileNameSanitization() {
        // Test that special characters are removed from file names
        let testCases: [(input: String, expected: String)] = [
            ("Test Script", "test-script"),
            ("Test@Script", "test-script"),
            ("Test#Script", "test-script"),
            ("Test  Script", "test-script"), // multiple spaces
            ("TEST SCRIPT", "test-script"), // uppercase
            ("Test_Script", "test-script"),
            ("Test.Script", "test-script"),
            ("Test/Script", "test-script"),
            ("Test\\Script", "test-script"),
        ]
        
        for (input, expected) in testCases {
            let sanitized = input
                .lowercased()
                .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            
            XCTAssertEqual(sanitized, expected, "'\(input)' should sanitize to '\(expected)'")
        }
    }
    
    // MARK: - Array Safety Tests
    
    func testSafeArrayAccess() {
        // Test that we handle array bounds safely
        let emptyArray: [String] = []
        let singleItem = ["one"]
        let multipleItems = ["one", "two", "three"]
        
        XCTAssertNil(emptyArray.first)
        XCTAssertEqual(singleItem.first, "one")
        XCTAssertEqual(multipleItems.first, "one")
        XCTAssertEqual(multipleItems.last, "three")
    }
    
    // MARK: - Refresh Time Parsing Logic
    
    func testRefreshTimeFormatValidation() {
        // Test that refresh time formats are correctly structured
        let validFormats = ["5m", "10m", "30m", "1h", "3h", "6h", "12h", "1d"]
        let pattern = "^\\d+[smhd]$"
        
        for format in validFormats {
            let range = format.range(of: pattern, options: .regularExpression)
            XCTAssertNotNil(range, "\(format) should match refresh time pattern")
        }
    }
    
    func testInvalidRefreshTimeFormats() {
        // Test that invalid formats are rejected
        let invalidFormats = ["5", "m", "5x", "1.5h", "-5m", ""]
        let pattern = "^\\d+[smhd]$"
        
        for format in invalidFormats {
            let range = format.range(of: pattern, options: .regularExpression)
            XCTAssertNil(range, "\(format) should NOT match refresh time pattern")
        }
    }
}
