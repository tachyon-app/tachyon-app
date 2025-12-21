import Foundation

/// Script templates for creating new scripts
public enum ScriptTemplate: String, CaseIterable, Identifiable {
    case bash = "Bash"
    case appleScript = "AppleScript"
    case swift = "Swift"
    case python = "Python"
    case ruby = "Ruby"
    case nodeJS = "Node.js"
    
    public var id: String { rawValue }
    
    public var shebang: String {
        switch self {
        case .bash: return "#!/bin/bash"
        case .appleScript: return "#!/usr/bin/osascript"
        case .swift: return "#!/usr/bin/swift"
        case .python: return "#!/usr/bin/env python3"
        case .ruby: return "#!/usr/bin/env ruby"
        case .nodeJS: return "#!/usr/bin/env node"
        }
    }
    
    public var fileExtension: String {
        switch self {
        case .bash: return "sh"
        case .appleScript: return "applescript"
        case .swift: return "swift"
        case .python: return "py"
        case .ruby: return "rb"
        case .nodeJS: return "js"
        }
    }
    
    public var commentPrefix: String {
        switch self {
        case .bash, .python, .ruby: return "#"
        case .appleScript, .swift, .nodeJS: return "//"
        }
    }
    
    public var boilerplate: String {
        switch self {
        case .bash:
            return """
            
            # Add your bash code here
            echo "Hello from Bash!"
            """
        case .appleScript:
            return """
            
            -- Add your AppleScript code here
            display notification "Hello from AppleScript!"
            """
        case .swift:
            return """
            
            import Foundation
            
            // Add your Swift code here
            print("Hello from Swift!")
            """
        case .python:
            return """
            
            # Add your Python code here
            print("Hello from Python!")
            """
        case .ruby:
            return """
            
            # Add your Ruby code here
            puts "Hello from Ruby!"
            """
        case .nodeJS:
            return """
            
            // Add your Node.js code here
            console.log("Hello from Node.js!");
            """
        }
    }
    
    /// Generate complete script content with metadata
    public func generateScript(
        title: String,
        mode: ScriptMode,
        description: String?,
        packageName: String?,
        refreshTime: String?
    ) -> String {
        var lines = [shebang, ""]
        
        // Required metadata
        lines.append("\(commentPrefix) @raycast.schemaVersion 1")
        lines.append("\(commentPrefix) @raycast.title \(title)")
        lines.append("\(commentPrefix) @raycast.mode \(mode.rawValue)")
        
        // Optional metadata
        if let description = description, !description.isEmpty {
            lines.append("\(commentPrefix) @raycast.description \(description)")
        }
        
        if let packageName = packageName, !packageName.isEmpty {
            lines.append("\(commentPrefix) @raycast.packageName \(packageName)")
        }
        
        if let refreshTime = refreshTime, !refreshTime.isEmpty {
            lines.append("\(commentPrefix) @raycast.refreshTime \(refreshTime)")
        }
        
        lines.append("\(commentPrefix) @raycast.icon 🚀")
        
        // Add boilerplate code
        lines.append(boilerplate)
        
        return lines.joined(separator: "\n")
    }
    
    /// Generate filename from title
    public static func generateFileName(from title: String, template: ScriptTemplate) -> String {
        let sanitized = title
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
        return "\(sanitized).\(template.fileExtension)"
    }
}
