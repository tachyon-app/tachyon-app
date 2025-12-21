import Foundation

/// Handles script process execution and output capture
public class ScriptExecutor {
    public init() {}
    
    public enum ExecutionError: Error {
        case noShebang
        case interpreterNotFound(String)
        case missingRequiredArgument(ScriptArgument)
        case executionFailed(exitCode: Int32, stderr: String)
        case processSpawnFailed(Error)
    }
    
    public struct ExecutionResult {
        public let exitCode: Int32
        public let stdout: String
        public let stderr: String
        public let duration: TimeInterval
        
        public var isSuccess: Bool {
            return exitCode == 0
        }
    }
    
    /// Execute a script with provided arguments
    /// - Parameters:
    ///   - fileURL: Path to the script file
    ///   - metadata: Parsed metadata for the script
    ///   - arguments: User-provided argument values (keyed by position)
    ///   - onOutput: Optional callback for streaming stdout (for fullOutput mode)
    /// - Returns: Execution result
    public func execute(
        fileURL: URL,
        metadata: ScriptMetadata,
        arguments: [Int: String] = [:],
        onOutput: ((String) -> Void)? = nil
    ) async throws -> ExecutionResult {
        // Validate required arguments
        for arg in metadata.arguments where !arg.optional {
            if arguments[arg.position] == nil || arguments[arg.position]?.isEmpty == true {
                throw ExecutionError.missingRequiredArgument(arg)
            }
        }
        
        // Read shebang
        let interpreter = try detectInterpreter(fileURL: fileURL)
        
        // Determine working directory
        let workingDirectory: URL
        if let customPath = metadata.currentDirectoryPath {
            workingDirectory = URL(fileURLWithPath: customPath)
        } else {
            workingDirectory = fileURL.deletingLastPathComponent()
        }
        
        // Build argument array
        let scriptArgs = buildArgumentArray(from: arguments, metadata: metadata)
        
        // Execute
        return try await executeProcess(
            interpreter: interpreter,
            scriptPath: fileURL.path,
            arguments: scriptArgs,
            workingDirectory: workingDirectory,
            onOutput: onOutput
        )
    }
    
    // MARK: - Private Helpers
    
    /// Detect the interpreter from the shebang line
    private func detectInterpreter(fileURL: URL) throws -> String {
        guard let fileHandle = FileHandle(forReadingAtPath: fileURL.path) else {
            throw ExecutionError.interpreterNotFound("Cannot open file")
        }
        
        defer { try? fileHandle.close() }
        
        // Read first line
        guard let firstLineData = try? fileHandle.readLine(),
              let firstLine = String(data: firstLineData, encoding: .utf8) else {
            throw ExecutionError.noShebang
        }
        
        let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for shebang
        guard trimmed.hasPrefix("#!") else {
            throw ExecutionError.noShebang
        }
        
        // Extract interpreter path
        let interpreterPath = String(trimmed.dropFirst(2))
            .trimmingCharacters(in: .whitespaces)
        
        // Handle /usr/bin/env style shebangs
        if interpreterPath.hasPrefix("/usr/bin/env ") {
            let parts = interpreterPath.components(separatedBy: " ")
            if parts.count >= 2 {
                return parts[1] // Return the interpreter name (e.g., "python3", "node")
            }
        }
        
        return interpreterPath
    }
    
    /// Build argument array from user-provided values
    private func buildArgumentArray(from arguments: [Int: String], metadata: ScriptMetadata) -> [String] {
        var args: [String] = []
        
        // Add arguments in position order
        for arg in metadata.arguments.sorted(by: { $0.position < $1.position }) {
            if let value = arguments[arg.position] {
                args.append(value)
            } else if arg.optional {
                args.append("") // Empty string for optional missing args
            }
        }
        
        return args
    }
    
    /// Execute the process and capture output
    private func executeProcess(
        interpreter: String,
        scriptPath: String,
        arguments: [String],
        workingDirectory: URL,
        onOutput: ((String) -> Void)?
    ) async throws -> ExecutionResult {
        let startTime = Date()
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: interpreter)
        process.arguments = [scriptPath] + arguments
        process.currentDirectoryURL = workingDirectory
        
        // Set up pipes for stdout and stderr
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        var stdoutData = Data()
        var stderrData = Data()
        
        // Set up async reading for stdout (for streaming)
        if let onOutput = onOutput {
            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    stdoutData.append(data)
                    if let output = String(data: data, encoding: .utf8) {
                        onOutput(output)
                    }
                }
            }
        }
        
        do {
            try process.run()
            
            // Wait for completion
            process.waitUntilExit()
            
            // Stop reading handlers
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            
            // Read any remaining data
            if onOutput == nil {
                stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            }
            stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            
            let duration = Date().timeIntervalSince(startTime)
            let exitCode = process.terminationStatus
            
            let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
            let stderr = String(data: stderrData, encoding: .utf8) ?? ""
            
            return ExecutionResult(
                exitCode: exitCode,
                stdout: stdout,
                stderr: stderr,
                duration: duration
            )
        } catch {
            throw ExecutionError.processSpawnFailed(error)
        }
    }
}

// MARK: - FileHandle Extension

extension FileHandle {
    /// Read a single line from the file
    func readLine() throws -> Data? {
        var lineData = Data()
        var byte = Data(count: 1)
        
        while true {
            let bytesRead = try read(upToCount: 1)
            guard let readByte = bytesRead, !readByte.isEmpty else {
                break
            }
            
            if readByte[0] == 0x0A { // newline
                break
            }
            
            lineData.append(readByte)
        }
        
        return lineData.isEmpty ? nil : lineData
    }
}
