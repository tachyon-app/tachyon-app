import Foundation

/// Main search engine that coordinates queries across all plugins
public final class QueryEngine {
    
    private var plugins: [Plugin] = []
    private let fuzzyMatcher = FuzzyMatcher()
    private var debounceTask: Task<Void, Never>?
    
    /// Callback when search completes (for debounced searches)
    public var onSearchComplete: (([QueryResult]) -> Void)?
    
    public init() {}
    
    // MARK: - Plugin Management
    
    /// Register a plugin with the query engine
    public func register(plugin: Plugin) {
        plugins.append(plugin)
    }
    
    /// Unregister a plugin
    public func unregister(pluginId: String) {
        plugins.removeAll { $0.id == pluginId }
    }
    
    // MARK: - Search
    
    /// Perform a synchronous search across all plugins
    /// - Parameter query: Search query string
    /// - Returns: Ranked results sorted by score (descending)
    public func search(query: String) -> [QueryResult] {
        // Empty query returns no results
        guard !query.isEmpty else { return [] }
        
        // Collect results from all plugins
        var allResults: [QueryResult] = []
        
        for plugin in plugins {
            let pluginResults = plugin.search(query: query)
            allResults.append(contentsOf: pluginResults)
        }
        
        // Score each result using fuzzy matching
        var scoredResults = allResults.map { result in
            var scored = result
            scored.score = fuzzyMatcher.score(query: query, target: result.title)
            return scored
        }
        
        // Filter out results with score 0
        scoredResults = scoredResults.filter { $0.score > 0 }
        
        // Sort by score (descending)
        scoredResults.sort { $0.score > $1.score }
        
        return scoredResults
    }
    
    /// Perform a debounced search (useful for live typing)
    /// Results are delivered via the onSearchComplete callback
    /// - Parameter query: Search query string
    /// - Parameter delay: Debounce delay in nanoseconds (default: 50ms)
    public func searchDebounced(query: String, delay: UInt64 = 50_000_000) {
        // Cancel any existing debounce task
        debounceTask?.cancel()
        
        // Create new debounce task
        debounceTask = Task {
            // Wait for debounce delay
            try? await Task.sleep(nanoseconds: delay)
            
            // If not cancelled, perform search
            guard !Task.isCancelled else { return }
            
            let results = search(query: query)
            
            // Deliver results on main thread
            await MainActor.run {
                onSearchComplete?(results)
            }
        }
    }
}
