import Foundation

/// Result from a plugin search
public struct QueryResult: Identifiable {
    public let id: UUID
    public let title: String
    public let subtitle: String?
    public let icon: String? // SF Symbol name or emoji
    public let iconPath: String? // Path to file for icon
    public let action: () -> Void
    public var score: Double = 0.0
    
    public init(
        id: UUID = UUID(),
        title: String,
        subtitle: String?,
        icon: String?,
        iconPath: String? = nil,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconPath = iconPath
        self.action = action
    }
}

extension QueryResult: Equatable {
    public static func == (lhs: QueryResult, rhs: QueryResult) -> Bool {
        lhs.id == rhs.id
    }
}

extension QueryResult: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(iconPath)
    }
}
