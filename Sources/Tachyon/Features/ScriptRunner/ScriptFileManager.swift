import Foundation

/// Manages script files in ~/.tachyon/scripts/
public class ScriptFileManager {
    public static let shared = ScriptFileManager()
    
    public enum FileError: Error {
        case directoryCreationFailed(Error)
        case copyFailed(Error)
        case deleteFailed(Error)
        case fileNotFound
    }
    
    /// Directory where scripts are stored
    public let scriptsDirectory: URL
    
    private init() {
        let homeUrl = FileManager.default.homeDirectoryForCurrentUser
        self.scriptsDirectory = homeUrl.appendingPathComponent(".tachyon/scripts")
        
        // Create directory if it doesn't exist
        try? createScriptsDirectory()
    }
    
    /// Create the scripts directory if it doesn't exist
    private func createScriptsDirectory() throws {
        do {
            try FileManager.default.createDirectory(
                at: scriptsDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            throw FileError.directoryCreationFailed(error)
        }
    }
    
    /// Import a script file (copies to scripts directory)
    /// - Parameter sourceURL: Path to the original script file
    /// - Returns: URL of the copied file in scripts directory
    public func importScript(from sourceURL: URL) throws -> URL {
        let fileName = sourceURL.lastPathComponent
        let destinationURL = scriptsDirectory.appendingPathComponent(fileName)
        
        do {
            // If file already exists, remove it first
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Copy the file
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            
            // Make it executable
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: destinationURL.path
            )
            
            return destinationURL
        } catch {
            throw FileError.copyFailed(error)
        }
    }
    
    /// Get the full path for a script filename
    /// - Parameter fileName: Name of the script file
    /// - Returns: Full URL to the script
    public func scriptURL(for fileName: String) -> URL {
        return scriptsDirectory.appendingPathComponent(fileName)
    }
    
    /// Delete a script file
    /// - Parameter fileName: Name of the script file to delete
    public func deleteScript(fileName: String) throws {
        let fileURL = scriptURL(for: fileName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw FileError.fileNotFound
        }
        
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            throw FileError.deleteFailed(error)
        }
    }
    
    /// Check if a script file exists
    /// - Parameter fileName: Name of the script file
    /// - Returns: True if the file exists
    public func scriptExists(fileName: String) -> Bool {
        let fileURL = scriptURL(for: fileName)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
}
