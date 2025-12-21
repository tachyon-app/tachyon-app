import Foundation

/// Parses Raycast-compatible magic comments from script files
public class MetadataParser {
    public enum ParseError: Error {
        case missingSchemaVersion
        case invalidSchemaVersion(Int)
        case missingTitle
        case invalidArgumentJSON(position: Int, error: String)
        case fileReadError(Error)
    }
    
    private let commentPrefixes = ["#", "//"]
    private let raycastPrefix = "@raycast."
    
    /// Parse metadata from a script file
    /// - Parameter fileURL: Path to the script file
    /// - Returns: Parsed metadata
    /// - Throws: ParseError if validation fails
    public func parse(fileURL: URL) throws -> ScriptMetadata {
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            return try parse(content: content)
        } catch let error as ParseError {
            throw error
        } catch {
            throw ParseError.fileReadError(error)
        }
    }
    
    /// Parse metadata from script content string (for testing)
    /// - Parameter content: Script file content
    /// - Returns: Parsed metadata
    /// - Throws: ParseError if validation fails
    public func parse(content: String) throws -> ScriptMetadata {
        var schemaVersion: Int?
        var title: String?
        var mode: ScriptMode = .fullOutput
        var packageName: String?
        var icon: String?
        var description: String?
        var refreshTime: String?
        var currentDirectoryPath: String?
        var needsConfirmation: Bool = false
        var arguments: [ScriptArgument] = []
        
        let lines = content.components(separatedBy: .newlines)
        var lineCount = 0
        
        // Parse up to 100 lines or until we hit a non-comment line
        for line in lines {
            lineCount += 1
            if lineCount > 100 { break }
            
            guard let (key, value) = extractKeyValue(from: line) else {
                // If we hit a non-comment, non-empty line, stop parsing
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty && !isComment(trimmed) {
                    break
                }
                continue
            }
            
            // Parse the key-value pair
            switch key {
            case "schemaVersion":
                schemaVersion = Int(value)
                
            case "title":
                title = value
                
            case "mode":
                if let parsedMode = ScriptMode(rawValue: value) {
                    mode = parsedMode
                }
                
            case "packageName":
                packageName = value
                
            case "icon":
                icon = value
                
            case "description":
                description = value
                
            case "refreshTime":
                refreshTime = value
                
            case "currentDirectoryPath":
                currentDirectoryPath = value
                
            case "needsConfirmation":
                needsConfirmation = value.lowercased() == "true"
                
            default:
                // Check if it's an argument definition
                if key.hasPrefix("argument") {
                    if let arg = try parseArgument(key: key, value: value) {
                        arguments.append(arg)
                    }
                }
            }
        }
        
        // Validate required fields
        guard let version = schemaVersion else {
            throw ParseError.missingSchemaVersion
        }
        
        guard version == 1 else {
            throw ParseError.invalidSchemaVersion(version)
        }
        
        guard let scriptTitle = title else {
            throw ParseError.missingTitle
        }
        
        return ScriptMetadata(
            schemaVersion: version,
            title: scriptTitle,
            mode: mode,
            packageName: packageName,
            icon: icon,
            description: description,
            refreshTime: refreshTime,
            currentDirectoryPath: currentDirectoryPath,
            needsConfirmation: needsConfirmation,
            arguments: arguments
        )
    }
    
    // MARK: - Private Helpers
    
    /// Check if a line is a comment
    private func isComment(_ line: String) -> Bool {
        for prefix in commentPrefixes {
            if line.hasPrefix(prefix) {
                return true
            }
        }
        return false
    }
    
    /// Extract key-value pair from a comment line
    /// - Parameter line: Line to parse
    /// - Returns: Tuple of (key, value) or nil if not a Raycast comment
    private func extractKeyValue(from line: String) -> (String, String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Check for comment prefix
        var content: String?
        for prefix in commentPrefixes {
            if trimmed.hasPrefix(prefix) {
                content = String(trimmed.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        guard let commentContent = content else { return nil }
        
        // Check for @raycast. prefix
        guard commentContent.hasPrefix(raycastPrefix) else { return nil }
        
        let afterPrefix = String(commentContent.dropFirst(raycastPrefix.count))
        
        // Split on first space to get key and value
        let components = afterPrefix.split(separator: " ", maxSplits: 1)
        guard components.count == 2 else { return nil }
        
        let key = String(components[0]).trimmingCharacters(in: .whitespaces)
        let value = String(components[1]).trimmingCharacters(in: .whitespaces)
        
        return (key, value)
    }
    
    /// Parse an argument definition
    /// - Parameters:
    ///   - key: The key (e.g., "argument1", "argument2")
    ///   - value: JSON string value
    /// - Returns: Parsed ScriptArgument or nil if invalid
    private func parseArgument(key: String, value: String) throws -> ScriptArgument? {
        // Extract position number from key (e.g., "argument1" -> 1)
        let numberString = key.replacingOccurrences(of: "argument", with: "")
        guard let position = Int(numberString), position >= 1, position <= 8 else {
            return nil
        }
        
        // Parse JSON
        guard let jsonData = value.data(using: .utf8) else {
            throw ParseError.invalidArgumentJSON(position: position, error: "Invalid UTF-8")
        }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                throw ParseError.invalidArgumentJSON(position: position, error: "Not a JSON object")
            }
            
            // Extract fields
            let typeString = json["type"] as? String ?? "text"
            let type = ScriptArgument.ArgumentType(rawValue: typeString) ?? .text
            let placeholder = json["placeholder"] as? String ?? ""
            let optional = json["optional"] as? Bool ?? false
            
            return ScriptArgument(
                position: position,
                type: type,
                placeholder: placeholder,
                optional: optional
            )
        } catch {
            throw ParseError.invalidArgumentJSON(position: position, error: error.localizedDescription)
        }
    }
}
