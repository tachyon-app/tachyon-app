import Foundation
import AppKit

/// Utility for executing AppleScript commands
public class AppleScriptExecutor {
    
    public static let shared = AppleScriptExecutor()
    
    private init() {}
    
    /// Execute an AppleScript string
    public func execute(_ script: String) -> (success: Bool, output: String?, error: String?) {
        var errorDict: NSDictionary?
        
        guard let appleScript = NSAppleScript(source: script) else {
            return (false, nil, "Failed to create AppleScript")
        }
        
        let output = appleScript.executeAndReturnError(&errorDict)
        
        if let error = errorDict {
            let errorMessage = error["NSAppleScriptErrorMessage"] as? String ?? error.description
            return (false, nil, errorMessage)
        }
        
        return (true, output.stringValue, nil)
    }
    
    /// Execute an AppleScript asynchronously
    public func executeAsync(_ script: String) async -> (success: Bool, output: String?, error: String?) {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.execute(script)
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Execute a shell command via AppleScript
    public func executeShellCommand(_ command: String) -> (success: Bool, output: String?, error: String?) {
        let script = "do shell script \"\(command)\""
        return execute(script)
    }
    
    /// Execute a shell command asynchronously
    public func executeShellCommandAsync(_ command: String) async -> (success: Bool, output: String?, error: String?) {
        let script = "do shell script \"\(command)\""
        return await executeAsync(script)
    }
}
