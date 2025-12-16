import XCTest
@testable import TachyonCore
import GRDB

class SearchEnginesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Use in-memory database for testing to avoid side effects and filesystem access
        try! StorageManager.shared.setupInMemoryDatabase()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testDefaultSeeding() throws {
        let engines = try StorageManager.shared.getAllSearchEngines()
        XCTAssertEqual(engines.count, 3, "Should have 3 default engines seeded")
        
        let names = engines.map { $0.name }
        XCTAssertTrue(names.contains("Google"))
        XCTAssertTrue(names.contains("GitHub"))
        XCTAssertTrue(names.contains("YouTube"))
    }
    
    func testAddAndRemoveEngine() throws {
        // Create a new engine
        let newEngine = SearchEngineRecord(
            id: UUID(),
            name: "DuckDuckGo",
            keyword: "d",
            urlTemplate: "https://duckduckgo.com/?q={{query}}",
            icon: nil
        )
        
        // Add it
        try StorageManager.shared.saveSearchEngine(newEngine)
        
        // Verify it was saved
        var engines = try StorageManager.shared.getAllSearchEngines()
        XCTAssertEqual(engines.count, 4)
        XCTAssertTrue(engines.contains(where: { $0.name == "DuckDuckGo" }))
        
        // Remove it
        try StorageManager.shared.deleteSearchEngine(id: newEngine.id)
        
        // Verify removal
        engines = try StorageManager.shared.getAllSearchEngines()
        XCTAssertEqual(engines.count, 3)
        XCTAssertFalse(engines.contains(where: { $0.name == "DuckDuckGo" }))
    }
    
    func testModifyingEngine() throws {
        // Get an existing engine (e.g. Google)
        var engines = try StorageManager.shared.getAllSearchEngines()
        guard var google = engines.first(where: { $0.name == "Google" }) else {
            XCTFail("Google engine not found")
            return
        }
        
        // Modify it
        let oldKeyword = google.keyword
        google.keyword = "goo"
        
        try StorageManager.shared.saveSearchEngine(google)
        
        // Verify update
        engines = try StorageManager.shared.getAllSearchEngines()
        guard let updatedGoogle = engines.first(where: { $0.id == google.id }) else {
            XCTFail("Google engine not found after update")
            return
        }
        
        XCTAssertEqual(updatedGoogle.keyword, "goo")
        XCTAssertNotEqual(updatedGoogle.keyword, oldKeyword)
    }
    
    func testPluginSearch() throws {
        // Initialize plugin (this will start observation on the current in-memory DB)
        let plugin = SearchEnginePlugin()
        
        // Wait for async observation to likely complete (hacky but sufficient for basic test)
        let expectation = XCTestExpectation(description: "Wait for DB observation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Perform a search
        let results = plugin.search(query: "swiftui")
        
        // Should have results for each engine
        let engines = try StorageManager.shared.getAllSearchEngines()
        XCTAssertEqual(results.count, engines.count)
        
        // Check result content
        if let googleResult = results.first(where: { $0.title == "Search in Google" }) {
            XCTAssertEqual(googleResult.subtitle, "Search for 'swiftui'")
        } else {
            XCTFail("Google result not found")
        }
    }
    
    func testPluginRespectsDefaults() throws {
        // Test that plugin results always have 'alwaysShow = true' based on our implementation
        let plugin = SearchEnginePlugin()
        
        // Wait for DB sync
        let expectation = XCTestExpectation(description: "Wait for DB observation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let results = plugin.search(query: "anything")
        
        for result in results {
            XCTAssertTrue(result.alwaysShow, "Search engine results should always be shown as fallback")
        }
    }
}
