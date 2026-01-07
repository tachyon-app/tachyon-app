import XCTest
@testable import TachyonCore

/// Tests for ContentTypeDetector (TDD approach)
final class ContentTypeDetectorTests: XCTestCase {
    
    // MARK: - Code Language Detection Tests
    
    func testDetectsSwiftCode() {
        let swiftCode = """
        import Foundation
        
        func greet(name: String) {
            print("Hello, \\(name)!")
        }
        """
        XCTAssertEqual(ContentTypeDetector.detectCodeLanguage(swiftCode), "swift")
    }
    
    func testDetectsSwiftByGuardStatement() {
        let code = "guard let value = optional else { return }"
        XCTAssertEqual(ContentTypeDetector.detectCodeLanguage(code), "swift")
    }
    
    func testDetectsPythonCode() {
        let pythonCode = """
        def greet(name):
            print(f"Hello, {name}!")
        
        if __name__ == "__main__":
            greet("World")
        """
        XCTAssertEqual(ContentTypeDetector.detectCodeLanguage(pythonCode), "python")
    }
    
    func testDetectsPythonByImport() {
        let code = "import numpy as np"
        XCTAssertEqual(ContentTypeDetector.detectCodeLanguage(code), "python")
    }
    
    func testDetectsJavaScriptCode() {
        let jsCode = """
        const greet = (name) => {
            console.log(`Hello, ${name}!`);
        };
        """
        XCTAssertEqual(ContentTypeDetector.detectCodeLanguage(jsCode), "javascript")
    }
    
    func testDetectsJavaScriptByRequire() {
        let code = "const fs = require('fs')"
        XCTAssertEqual(ContentTypeDetector.detectCodeLanguage(code), "javascript")
    }
    
    func testDetectsTypeScriptCode() {
        let tsCode = """
        interface User {
            name: string;
            age: number;
        }
        """
        XCTAssertEqual(ContentTypeDetector.detectCodeLanguage(tsCode), "typescript")
    }
    
    func testDetectsSQLCode() {
        let sqlCode = "SELECT * FROM users WHERE age > 18"
        XCTAssertEqual(ContentTypeDetector.detectCodeLanguage(sqlCode), "sql")
    }
    
    func testDetectsSQLInsert() {
        let code = "INSERT INTO users (name, email) VALUES ('John', 'john@example.com')"
        XCTAssertEqual(ContentTypeDetector.detectCodeLanguage(code), "sql")
    }
    
    func testDoesNotDetectPlainText() {
        let text = "This is just a regular sentence with no code."
        XCTAssertNil(ContentTypeDetector.detectCodeLanguage(text))
    }
    
    func testDoesNotDetectEmptyString() {
        XCTAssertNil(ContentTypeDetector.detectCodeLanguage(""))
    }
    
    // MARK: - URL Detection Tests
    
    func testDetectsHttpUrl() {
        XCTAssertTrue(ContentTypeDetector.isURL("http://example.com"))
        XCTAssertTrue(ContentTypeDetector.isURL("http://example.com/path/to/page"))
    }
    
    func testDetectsHttpsUrl() {
        XCTAssertTrue(ContentTypeDetector.isURL("https://example.com"))
        XCTAssertTrue(ContentTypeDetector.isURL("https://sub.example.com/page?query=value"))
    }
    
    func testDetectsUrlWithPort() {
        XCTAssertTrue(ContentTypeDetector.isURL("http://localhost:3000"))
        XCTAssertTrue(ContentTypeDetector.isURL("https://example.com:8080/api"))
    }
    
    func testDoesNotDetectPlainTextAsUrl() {
        XCTAssertFalse(ContentTypeDetector.isURL("This is not a URL"))
        XCTAssertFalse(ContentTypeDetector.isURL("example.com")) // Missing protocol
    }
    
    func testDoesNotDetectEmptyAsUrl() {
        XCTAssertFalse(ContentTypeDetector.isURL(""))
    }
    
    // MARK: - Markdown Detection Tests
    
    func testDetectsMarkdownHeaders() {
        XCTAssertTrue(ContentTypeDetector.isMarkdown("# Heading 1"))
        XCTAssertTrue(ContentTypeDetector.isMarkdown("## Heading 2"))
        XCTAssertTrue(ContentTypeDetector.isMarkdown("### Heading 3"))
    }
    
    func testDetectsMarkdownBold() {
        XCTAssertTrue(ContentTypeDetector.isMarkdown("This is **bold** text"))
    }
    
    func testDetectsMarkdownItalic() {
        XCTAssertTrue(ContentTypeDetector.isMarkdown("This is *italic* text"))
    }
    
    func testDetectsMarkdownLinks() {
        XCTAssertTrue(ContentTypeDetector.isMarkdown("[Link text](https://example.com)"))
    }
    
    func testDetectsMarkdownCodeBlocks() {
        let markdown = """
        ```swift
        let x = 1
        ```
        """
        XCTAssertTrue(ContentTypeDetector.isMarkdown(markdown))
    }
    
    func testDetectsMarkdownLists() {
        XCTAssertTrue(ContentTypeDetector.isMarkdown("- Item 1"))
        XCTAssertTrue(ContentTypeDetector.isMarkdown("* Item 1"))
        XCTAssertTrue(ContentTypeDetector.isMarkdown("1. Item 1"))
    }
    
    func testDoesNotDetectPlainTextAsMarkdown() {
        XCTAssertFalse(ContentTypeDetector.isMarkdown("This is plain text"))
        XCTAssertFalse(ContentTypeDetector.isMarkdown("No markdown here."))
    }
    
    func testDoesNotDetectEmptyAsMarkdown() {
        XCTAssertFalse(ContentTypeDetector.isMarkdown(""))
    }
    
    // MARK: - Content Type Inference Tests
    
    func testInfersTextType() {
        let result = ContentTypeDetector.inferType(for: "Just a normal sentence")
        XCTAssertEqual(result.type, .text)
        XCTAssertNil(result.codeLanguage)
    }
    
    func testInfersCodeType() {
        let result = ContentTypeDetector.inferType(for: "const x = () => console.log('test')")
        XCTAssertEqual(result.type, .code)
        XCTAssertEqual(result.codeLanguage, "javascript")
    }
    
    func testPrioritizesCodeOverMarkdown() {
        // Code with markdown-like syntax should be detected as code
        let code = """
        # This is a comment
        def main():
            print("Hello")
        """
        let result = ContentTypeDetector.inferType(for: code)
        XCTAssertEqual(result.type, .code)
    }
}
