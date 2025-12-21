import XCTest
@testable import TachyonCore

/// Tests for ScriptExecutor - script execution and output handling
final class ScriptExecutorTests: XCTestCase {
    var executor: ScriptExecutor!
    var tempDir: URL!
    
    override func setUp() {
        super.setUp()
        executor = ScriptExecutor()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("executor_tests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }
    
    // MARK: - Basic Execution Tests
    
    func testExecuteSimpleBashScript() async throws {
        let scriptContent = """
        #!/bin/bash
        echo "Hello World"
        """
        
        let scriptURL = tempDir.appendingPathComponent("test.sh")
        try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        
        let metadata = ScriptMetadata(
            schemaVersion: 1,
            title: "Test",
            mode: .fullOutput
        )
        
        let result = try await executor.execute(fileURL: scriptURL, metadata: metadata, arguments: [:])
        
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.stdout.contains("Hello World"))
        XCTAssertTrue(result.stderr.isEmpty)
    }
    
    // MARK: - Error Handling Tests
    
    func testExecuteScriptWithNonZeroExitCode() async throws {
        let scriptContent = """
        #!/bin/bash
        echo "Error message" >&2
        exit 1
        """
        
        let scriptURL = tempDir.appendingPathComponent("test.sh")
        try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        
        let metadata = ScriptMetadata(
            schemaVersion: 1,
            title: "Test",
            mode: .fullOutput
        )
        
        let result = try await executor.execute(fileURL: scriptURL, metadata: metadata, arguments: [:])
        
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.stderr.contains("Error message"))
    }
    
    // MARK: - Output Capture Tests
    
    func testCaptureStdoutAndStderr() async throws {
        let scriptContent = """
        #!/bin/bash
        echo "stdout message"
        echo "stderr message" >&2
        """
        
        let scriptURL = tempDir.appendingPathComponent("test.sh")
        try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        
        let metadata = ScriptMetadata(
            schemaVersion: 1,
            title: "Test",
            mode: .fullOutput
        )
        
        let result = try await executor.execute(fileURL: scriptURL, metadata: metadata, arguments: [:])
        
        XCTAssertTrue(result.stdout.contains("stdout message"))
        XCTAssertTrue(result.stderr.contains("stderr message"))
    }
    
    // MARK: - Duration Tests
    
    func testExecutionDuration() async throws {
        let scriptContent = """
        #!/bin/bash
        sleep 0.2
        echo "done"
        """
        
        let scriptURL = tempDir.appendingPathComponent("test.sh")
        try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        
        let metadata = ScriptMetadata(
            schemaVersion: 1,
            title: "Test",
            mode: .fullOutput
        )
        
        let result = try await executor.execute(fileURL: scriptURL, metadata: metadata, arguments: [:])
        
        XCTAssertGreaterThan(result.duration, 0.2, "Duration should be at least 0.2 seconds")
        XCTAssertLessThan(result.duration, 1.0, "Duration should be less than 1 second")
    }
    
    // MARK: - Shebang Detection Tests
    
    func testDetectBashShebang() async throws {
        let scriptContent = """
        #!/bin/bash
        echo "bash"
        """
        
        let scriptURL = tempDir.appendingPathComponent("test.sh")
        try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        
        let metadata = ScriptMetadata(
            schemaVersion: 1,
            title: "Test",
            mode: .fullOutput
        )
        
        let result = try await executor.execute(fileURL: scriptURL, metadata: metadata, arguments: [:])
        XCTAssertTrue(result.isSuccess)
    }
    
}
