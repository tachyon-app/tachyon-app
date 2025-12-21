import XCTest
@testable import TachyonCore

/// Tests for ScriptTemplates - template generation and file naming
final class ScriptTemplatesTests: XCTestCase {
    
    // MARK: - Template Availability Tests
    
    func testAllTemplatesAvailable() {
        let templates = ScriptTemplate.allCases
        XCTAssertEqual(templates.count, 6, "Should have 6 script templates")
        
        XCTAssertTrue(templates.contains(.bash))
        XCTAssertTrue(templates.contains(.appleScript))
        XCTAssertTrue(templates.contains(.swift))
        XCTAssertTrue(templates.contains(.python))
        XCTAssertTrue(templates.contains(.ruby))
        XCTAssertTrue(templates.contains(.nodeJS))
    }
    
    // MARK: - Shebang Tests
    
    func testBashShebang() {
        XCTAssertEqual(ScriptTemplate.bash.shebang, "#!/bin/bash")
    }
    
    func testAppleScriptShebang() {
        XCTAssertEqual(ScriptTemplate.appleScript.shebang, "#!/usr/bin/osascript")
    }
    
    func testSwiftShebang() {
        XCTAssertEqual(ScriptTemplate.swift.shebang, "#!/usr/bin/swift")
    }
    
    func testPythonShebang() {
        XCTAssertEqual(ScriptTemplate.python.shebang, "#!/usr/bin/env python3")
    }
    
    func testRubyShebang() {
        XCTAssertEqual(ScriptTemplate.ruby.shebang, "#!/usr/bin/env ruby")
    }
    
    func testNodeJSShebang() {
        XCTAssertEqual(ScriptTemplate.nodeJS.shebang, "#!/usr/bin/env node")
    }
    
    // MARK: - File Extension Tests
    
    func testBashFileExtension() {
        XCTAssertEqual(ScriptTemplate.bash.fileExtension, "sh")
    }
    
    func testAppleScriptFileExtension() {
        XCTAssertEqual(ScriptTemplate.appleScript.fileExtension, "applescript")
    }
    
    func testSwiftFileExtension() {
        XCTAssertEqual(ScriptTemplate.swift.fileExtension, "swift")
    }
    
    func testPythonFileExtension() {
        XCTAssertEqual(ScriptTemplate.python.fileExtension, "py")
    }
    
    func testRubyFileExtension() {
        XCTAssertEqual(ScriptTemplate.ruby.fileExtension, "rb")
    }
    
    func testNodeJSFileExtension() {
        XCTAssertEqual(ScriptTemplate.nodeJS.fileExtension, "js")
    }
    
    // MARK: - Comment Prefix Tests
    
    func testBashCommentPrefix() {
        XCTAssertEqual(ScriptTemplate.bash.commentPrefix, "#")
    }
    
    func testAppleScriptCommentPrefix() {
        XCTAssertEqual(ScriptTemplate.appleScript.commentPrefix, "//")
    }
    
    func testSwiftCommentPrefix() {
        XCTAssertEqual(ScriptTemplate.swift.commentPrefix, "//")
    }
    
    func testNodeJSCommentPrefix() {
        XCTAssertEqual(ScriptTemplate.nodeJS.commentPrefix, "//")
    }
    
    // MARK: - Script Generation Tests
    
    func testGenerateBasicScript() {
        let script = ScriptTemplate.bash.generateScript(
            title: "Test Script",
            mode: .fullOutput,
            description: nil,
            packageName: nil,
            refreshTime: nil
        )
        
        XCTAssertTrue(script.contains("#!/bin/bash"))
        XCTAssertTrue(script.contains("# @raycast.title Test Script"))
        XCTAssertTrue(script.contains("# @raycast.mode fullOutput"))
    }
    
    func testGenerateScriptWithAllFields() {
        let script = ScriptTemplate.bash.generateScript(
            title: "Test Script",
            mode: .inline,
            description: "A test script",
            packageName: "Developer Tools",
            refreshTime: "5m"
        )
        
        XCTAssertTrue(script.contains("#!/bin/bash"))
        XCTAssertTrue(script.contains("# @raycast.title Test Script"))
        XCTAssertTrue(script.contains("# @raycast.mode inline"))
        XCTAssertTrue(script.contains("# @raycast.description A test script"))
        XCTAssertTrue(script.contains("# @raycast.packageName Developer Tools"))
        XCTAssertTrue(script.contains("# @raycast.refreshTime 5m"))
    }
    
    func testGenerateScriptWithDifferentModes() {
        let modes: [ScriptMode] = [.fullOutput, .compact, .inline, .silent]
        
        for mode in modes {
            let script = ScriptTemplate.bash.generateScript(
                title: "Test",
                mode: mode,
                description: nil,
                packageName: nil,
                refreshTime: nil
            )
            
            XCTAssertTrue(script.contains("# @raycast.mode \(mode.rawValue)"))
        }
    }
    
    func testGenerateNodeJSScript() {
        let script = ScriptTemplate.nodeJS.generateScript(
            title: "Node Script",
            mode: .fullOutput,
            description: nil,
            packageName: nil,
            refreshTime: nil
        )
        
        XCTAssertTrue(script.contains("#!/usr/bin/env node"))
        XCTAssertTrue(script.contains("// @raycast.title Node Script"))
        XCTAssertTrue(script.contains("console.log"))
    }
    
    func testGenerateSwiftScript() {
        let script = ScriptTemplate.swift.generateScript(
            title: "Swift Script",
            mode: .fullOutput,
            description: nil,
            packageName: nil,
            refreshTime: nil
        )
        
        XCTAssertTrue(script.contains("#!/usr/bin/swift"))
        XCTAssertTrue(script.contains("// @raycast.title Swift Script"))
        XCTAssertTrue(script.contains("print"))
    }
    
    // MARK: - File Name Generation Tests
    
    func testGenerateFileNameBasic() {
        let fileName = ScriptTemplate.generateFileName(from: "Test Script", template: .bash)
        XCTAssertEqual(fileName, "test-script.sh")
    }
    
    func testGenerateFileNameWithSpaces() {
        let fileName = ScriptTemplate.generateFileName(from: "My Test Script", template: .bash)
        XCTAssertEqual(fileName, "my-test-script.sh")
    }
    
    func testGenerateFileNameWithSpecialCharacters() {
        let fileName = ScriptTemplate.generateFileName(from: "Test@Script#123", template: .bash)
        // The regex removes special chars, leaving "testscript123"
        XCTAssertTrue(fileName.hasSuffix(".sh"))
        XCTAssertFalse(fileName.contains("@"))
        XCTAssertFalse(fileName.contains("#"))
    }
    
    func testGenerateFileNameWithDifferentExtensions() {
        let testCases: [(ScriptTemplate, String)] = [
            (.bash, "test.sh"),
            (.python, "test.py"),
            (.ruby, "test.rb"),
            (.nodeJS, "test.js"),
            (.swift, "test.swift"),
            (.appleScript, "test.applescript")
        ]
        
        for (template, expected) in testCases {
            let fileName = ScriptTemplate.generateFileName(from: "Test", template: template)
            XCTAssertEqual(fileName, expected, "File name for \(template.rawValue) should be \(expected)")
        }
    }
    
    func testGenerateFileNameWithUppercase() {
        let fileName = ScriptTemplate.generateFileName(from: "TEST SCRIPT", template: .bash)
        XCTAssertEqual(fileName, "test-script.sh")
    }
    
    // MARK: - Boilerplate Tests
    
    func testBashBoilerplateExists() {
        XCTAssertFalse(ScriptTemplate.bash.boilerplate.isEmpty)
        XCTAssertTrue(ScriptTemplate.bash.boilerplate.contains("echo"))
    }
    
    func testNodeJSBoilerplateExists() {
        XCTAssertFalse(ScriptTemplate.nodeJS.boilerplate.isEmpty)
        XCTAssertTrue(ScriptTemplate.nodeJS.boilerplate.contains("console.log"))
    }
    
    func testPythonBoilerplateExists() {
        XCTAssertFalse(ScriptTemplate.python.boilerplate.isEmpty)
        XCTAssertTrue(ScriptTemplate.python.boilerplate.contains("print"))
    }
    
    func testSwiftBoilerplateExists() {
        XCTAssertFalse(ScriptTemplate.swift.boilerplate.isEmpty)
        XCTAssertTrue(ScriptTemplate.swift.boilerplate.contains("print"))
    }
    
    func testRubyBoilerplateExists() {
        XCTAssertFalse(ScriptTemplate.ruby.boilerplate.isEmpty)
        XCTAssertTrue(ScriptTemplate.ruby.boilerplate.contains("puts"))
    }
}
