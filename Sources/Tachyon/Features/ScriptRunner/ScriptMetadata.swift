import Foundation

/// Output presentation modes for script execution
public enum ScriptMode: String, Codable, CaseIterable {
    case fullOutput  // Terminal-like output view
    case compact     // Last line in status bar
    case inline      // First line inline with result
    case silent      // Status updates only
}

/// Script argument definition from metadata
public struct ScriptArgument: Codable, Equatable {
    public enum ArgumentType: String, Codable {
        case text
        case password
    }
    
    public let position: Int         // 1-8
    public let type: ArgumentType
    public let placeholder: String
    public let optional: Bool
    
    public init(position: Int, type: ArgumentType, placeholder: String, optional: Bool) {
        self.position = position
        self.type = type
        self.placeholder = placeholder
        self.optional = optional
    }
}

/// Parsed metadata from Raycast-compatible magic comments
public struct ScriptMetadata {
    // Required fields
    public let schemaVersion: Int    // Must be 1
    public let title: String
    
    // Optional fields with defaults
    public let mode: ScriptMode
    public let packageName: String?
    public let icon: String?         // Emoji or URL
    public let description: String?
    public let refreshTime: String?  // "1h", "10m", "30s"
    public let currentDirectoryPath: String?
    public let needsConfirmation: Bool
    
    // Arguments (sorted by position)
    public let arguments: [ScriptArgument]
    
    public init(
        schemaVersion: Int,
        title: String,
        mode: ScriptMode = .fullOutput,
        packageName: String? = nil,
        icon: String? = nil,
        description: String? = nil,
        refreshTime: String? = nil,
        currentDirectoryPath: String? = nil,
        needsConfirmation: Bool = false,
        arguments: [ScriptArgument] = []
    ) {
        self.schemaVersion = schemaVersion
        self.title = title
        self.mode = mode
        self.packageName = packageName
        self.icon = icon
        self.description = description
        self.refreshTime = refreshTime
        self.currentDirectoryPath = currentDirectoryPath
        self.needsConfirmation = needsConfirmation
        self.arguments = arguments.sorted { $0.position < $1.position }
    }
}
