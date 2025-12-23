import Foundation

/// Represents a system command that can be executed
public struct SystemCommand {
    let id: String
    let name: String
    let description: String
    let icon: String
    let keywords: [String]
    let category: CommandCategory
    let requiresConfirmation: Bool
    let action: () async -> CommandResult
    
    public init(
        id: String,
        name: String,
        description: String,
        icon: String,
        keywords: [String] = [],
        category: CommandCategory,
        requiresConfirmation: Bool = false,
        action: @escaping () async -> CommandResult
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.keywords = keywords
        self.category = category
        self.requiresConfirmation = requiresConfirmation
        self.action = action
    }
}

/// Categories for organizing system commands
public enum CommandCategory: String {
    case power = "Power & Session"
    case settings = "Settings & Appearance"
    case audio = "Audio & Volume"
    case fileManagement = "File & Disk Management"
    case appManagement = "Application Management"
}

/// Result of executing a system command
public struct CommandResult {
    let success: Bool
    let message: String?
    let error: Error?
    
    public static func success(_ message: String? = nil) -> CommandResult {
        CommandResult(success: true, message: message, error: nil)
    }
    
    public static func failure(_ error: Error) -> CommandResult {
        CommandResult(success: false, message: nil, error: error)
    }
    
    public static func failure(_ message: String) -> CommandResult {
        CommandResult(success: false, message: message, error: nil)
    }
}
