import Foundation

/// Protocol that all plugins must conform to
public protocol Plugin {
    /// Unique identifier for the plugin
    var id: String { get }
    
    /// Human-readable name
    var name: String { get }
    
    /// Search for items matching the query
    /// - Parameter query: User's search query
    /// - Returns: Array of results (unscored - QueryEngine will score them)
    func search(query: String) -> [QueryResult]
}
