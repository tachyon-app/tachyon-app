import XCTest
@testable import TachyonCore

/// Tests for the QueryEngine
/// The QueryEngine coordinates searching across all plugins and returns ranked results
final class QueryEngineTests: XCTestCase {
    
    var engine: QueryEngine!
    
    override func setUp() {
        super.setUp()
        engine = QueryEngine()
    }
    
    // MARK: - Basic Query Tests
    
    func testEmptyQuery() {
        let results = engine.search(query: "")
        XCTAssertTrue(results.isEmpty, "Empty query should return no results")
    }
    
    func testQueryWithNoMatches() {
        // Register a simple test plugin
        let plugin = MockPlugin(items: [
            QueryResult(title: "Safari", subtitle: "Web Browser", icon: nil, action: {})
        ])
        engine.register(plugin: plugin)
        
        let results = engine.search(query: "xyz123")
        XCTAssertTrue(results.isEmpty, "Query with no matches should return empty")
    }
    
    func testQueryWithMatches() {
        let plugin = MockPlugin(items: [
            QueryResult(title: "Safari", subtitle: "Web Browser", icon: nil, action: {}),
            QueryResult(title: "Google Chrome", subtitle: "Web Browser", icon: nil, action: {}),
            QueryResult(title: "Firefox", subtitle: "Web Browser", icon: nil, action: {})
        ])
        engine.register(plugin: plugin)
        
        let results = engine.search(query: "saf")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Safari")
    }
    
    // MARK: - Ranking Tests
    
    func testResultsAreRankedByScore() {
        let plugin = MockPlugin(items: [
            QueryResult(title: "Safari", subtitle: "Browser", icon: nil, action: {}),
            QueryResult(title: "System Preferences", subtitle: "Settings", icon: nil, action: {}),
            QueryResult(title: "Sublime Text", subtitle: "Editor", icon: nil, action: {})
        ])
        engine.register(plugin: plugin)
        
        let results = engine.search(query: "s")
        XCTAssertGreaterThan(results.count, 0)
        
        // Results should be sorted by score (descending)
        for i in 0..<(results.count - 1) {
            XCTAssertGreaterThanOrEqual(results[i].score, results[i + 1].score)
        }
    }
    
    // MARK: - Multiple Plugin Tests
    
    func testMultiplePlugins() {
        let plugin1 = MockPlugin(items: [
            QueryResult(title: "Safari", subtitle: "Browser", icon: nil, action: {})
        ])
        let plugin2 = MockPlugin(items: [
            QueryResult(title: "System Preferences", subtitle: "Settings", icon: nil, action: {})
        ])
        
        engine.register(plugin: plugin1)
        engine.register(plugin: plugin2)
        
        let results = engine.search(query: "s")
        XCTAssertEqual(results.count, 2, "Should get results from both plugins")
    }
    
    // MARK: - Performance Tests
    
    func testSearchPerformance() {
        // Create a plugin with many items
        let items = (0..<200).map { i in
            QueryResult(title: "Application \(i)", subtitle: "App", icon: nil, action: {})
        }
        let plugin = MockPlugin(items: items)
        engine.register(plugin: plugin)
        
        measure {
            _ = engine.search(query: "app")
        }
        
        // Should complete in well under 5ms
    }
    
    // MARK: - Debouncing Tests
    
    func testDebouncing() async {
        let plugin = MockPlugin(items: [
            QueryResult(title: "Safari", subtitle: "Browser", icon: nil, action: {})
        ])
        engine.register(plugin: plugin)
        
        // Simulate rapid typing - only the last query should execute
        var callCount = 0
        engine.onSearchComplete = { _ in callCount += 1 }
        
        engine.searchDebounced(query: "s")
        engine.searchDebounced(query: "sa")
        engine.searchDebounced(query: "saf")
        
        // Wait for debounce delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Should only have called once (for the last query)
        XCTAssertEqual(callCount, 1)
    }
}

// MARK: - Mock Plugin

class MockPlugin: Plugin {
    let items: [QueryResult]
    
    init(items: [QueryResult]) {
        self.items = items
    }
    
    var id: String { "mock" }
    var name: String { "Mock Plugin" }
    
    func search(query: String) -> [QueryResult] {
        return items
    }
}
