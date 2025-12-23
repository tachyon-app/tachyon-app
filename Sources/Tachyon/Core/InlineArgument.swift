import Foundation

/// Represents an argument that needs to be collected inline in the search bar
/// Used by both Script Commands and Custom Links
public struct InlineArgument: Identifiable, Equatable {
    public let id: Int  // Position (1-based)
    public let placeholder: String
    public let isRequired: Bool
    public let isPassword: Bool
    
    public init(position: Int, placeholder: String, isRequired: Bool = true, isPassword: Bool = false) {
        self.id = position
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.isPassword = isPassword
    }
    
    /// Create from a ScriptArgument
    public init(from scriptArg: ScriptArgument) {
        self.id = scriptArg.position
        self.placeholder = scriptArg.placeholder
        self.isRequired = !scriptArg.optional
        self.isPassword = scriptArg.type == .password
    }
}

/// Context for the item being executed with inline arguments
public enum InlineArgumentContext {
    case script(ScriptRecord, ScriptMetadata)
    case customLink(CustomLinkRecord)
    
    var title: String {
        switch self {
        case .script(let record, _):
            return record.title
        case .customLink(let record):
            return record.name
        }
    }
    
    var icon: String? {
        switch self {
        case .script(_, let metadata):
            return metadata.icon ?? "terminal.fill"
        case .customLink:
            return "link"
        }
    }
    
    var iconData: Data? {
        switch self {
        case .script(let record, _):
            return record.icon
        case .customLink(let record):
            return record.icon
        }
    }
}
