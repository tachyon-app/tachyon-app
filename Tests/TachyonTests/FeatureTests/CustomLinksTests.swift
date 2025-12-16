import XCTest
@testable import TachyonCore
import GRDB

class CustomLinksTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Use in-memory database for testing
        try! StorageManager.shared.setupInMemoryDatabase()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - CustomLinkRecord Tests
    
    func testParameterExtraction() {
        let link = CustomLinkRecord(
            name: "Test",
            urlTemplate: "https://example.com/{{user}}/{{repo}}/issues/{{number}}",
            defaults: [:]
        )
        
        let params = link.parameters
        XCTAssertEqual(params.count, 3)
        XCTAssertTrue(params.contains("user"))
        XCTAssertTrue(params.contains("repo"))
        XCTAssertTrue(params.contains("number"))
    }
    
    func testParameterDeduplication() {
        let link = CustomLinkRecord(
            name: "Test",
            urlTemplate: "https://example.com/{{user}}/{{user}}/{{repo}}",
            defaults: [:]
        )
        
        let params = link.parameters
        XCTAssertEqual(params.count, 2) // user should only appear once
        XCTAssertTrue(params.contains("user"))
        XCTAssertTrue(params.contains("repo"))
    }
    
    func testURLConstruction() {
        let link = CustomLinkRecord(
            name: "GitHub Issue",
            urlTemplate: "https://github.com/{{org}}/{{repo}}/issues/{{number}}",
            defaults: ["org": "mycompany"]
        )
        
        let url = link.constructURL(values: ["repo": "myrepo", "number": "123"])
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://github.com/mycompany/myrepo/issues/123")
    }
    
    func testURLConstructionWithDefaults() {
        let link = CustomLinkRecord(
            name: "Jira",
            urlTemplate: "https://jira.company.com/browse/{{ticket}}",
            defaults: ["ticket": "PROJ-"]
        )
        
        // User provides full value, should override default
        let url1 = link.constructURL(values: ["ticket": "PROJ-123"])
        XCTAssertEqual(url1?.absoluteString, "https://jira.company.com/browse/PROJ-123")
        
        // User provides empty, should use default
        let url2 = link.constructURL(values: [:])
        XCTAssertEqual(url2?.absoluteString, "https://jira.company.com/browse/PROJ-")
    }
    
    func testURLEncoding() {
        let link = CustomLinkRecord(
            name: "Search",
            urlTemplate: "https://example.com/search?q={{query}}",
            defaults: [:]
        )
        
        let url = link.constructURL(values: ["query": "hello world"])
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("hello%20world"))
    }
    
    // MARK: - Storage Tests
    
    func testAddAndRetrieveLink() throws {
        let link = CustomLinkRecord(
            id: UUID(),
            name: "Test Link",
            urlTemplate: "https://example.com/{{param}}",
            icon: nil,
            defaults: ["param": "default"]
        )
        
        try StorageManager.shared.saveCustomLink(link)
        
        let links = try StorageManager.shared.getAllCustomLinks()
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[0].name, "Test Link")
        XCTAssertEqual(links[0].urlTemplate, "https://example.com/{{param}}")
        XCTAssertEqual(links[0].defaults["param"], "default")
    }
    
    func testUpdateLink() throws {
        var link = CustomLinkRecord(
            id: UUID(),
            name: "Original",
            urlTemplate: "https://example.com/{{a}}",
            defaults: [:]
        )
        
        try StorageManager.shared.saveCustomLink(link)
        
        // Update the link
        link.name = "Updated"
        link.urlTemplate = "https://example.com/{{b}}"
        link.defaults = ["b": "value"]
        
        try StorageManager.shared.saveCustomLink(link)
        
        let links = try StorageManager.shared.getAllCustomLinks()
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[0].name, "Updated")
        XCTAssertEqual(links[0].urlTemplate, "https://example.com/{{b}}")
        XCTAssertEqual(links[0].defaults["b"], "value")
    }
    
    func testDeleteLink() throws {
        let link = CustomLinkRecord(
            id: UUID(),
            name: "To Delete",
            urlTemplate: "https://example.com",
            defaults: [:]
        )
        
        try StorageManager.shared.saveCustomLink(link)
        var links = try StorageManager.shared.getAllCustomLinks()
        XCTAssertEqual(links.count, 1)
        
        try StorageManager.shared.deleteCustomLink(id: link.id)
        links = try StorageManager.shared.getAllCustomLinks()
        XCTAssertEqual(links.count, 0)
    }
    
    func testDefaultsPersistence() throws {
        let link = CustomLinkRecord(
            id: UUID(),
            name: "With Defaults",
            urlTemplate: "https://example.com/{{a}}/{{b}}/{{c}}",
            defaults: [
                "a": "value1",
                "b": "value2",
                "c": "value3"
            ]
        )
        
        try StorageManager.shared.saveCustomLink(link)
        
        let links = try StorageManager.shared.getAllCustomLinks()
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[0].defaults.count, 3)
        XCTAssertEqual(links[0].defaults["a"], "value1")
        XCTAssertEqual(links[0].defaults["b"], "value2")
        XCTAssertEqual(links[0].defaults["c"], "value3")
    }
    
    // MARK: - Plugin Tests
    
    func testPluginSearch() throws {
        let link1 = CustomLinkRecord(
            name: "GitHub",
            urlTemplate: "https://github.com/{{repo}}",
            defaults: [:]
        )
        
        let link2 = CustomLinkRecord(
            name: "GitLab",
            urlTemplate: "https://gitlab.com/{{repo}}",
            defaults: [:]
        )
        
        try StorageManager.shared.saveCustomLink(link1)
        try StorageManager.shared.saveCustomLink(link2)
        
        let plugin = CustomLinksPlugin()
        
        // Wait for observation to sync
        let expectation = XCTestExpectation(description: "Wait for DB observation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let results = plugin.search(query: "git")
        XCTAssertEqual(results.count, 2)
        
        let hubResults = plugin.search(query: "github")
        XCTAssertEqual(hubResults.count, 1)
        XCTAssertEqual(hubResults[0].title, "GitHub")
    }
    
    func testPluginHideWindowBehavior() throws {
        // Link without parameters should hide window
        let simpleLink = CustomLinkRecord(
            name: "Simple",
            urlTemplate: "https://example.com",
            defaults: [:]
        )
        
        // Link with parameters should NOT hide window
        let paramLink = CustomLinkRecord(
            name: "Parameterized",
            urlTemplate: "https://example.com/{{param}}",
            defaults: [:]
        )
        
        try StorageManager.shared.saveCustomLink(simpleLink)
        try StorageManager.shared.saveCustomLink(paramLink)
        
        let plugin = CustomLinksPlugin()
        
        // Wait for observation
        let expectation = XCTestExpectation(description: "Wait for DB observation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let results = plugin.search(query: "e") // Search for "e" to match both
        
        // Find the results
        let simpleResult = results.first { $0.title == "Simple" }
        let paramResult = results.first { $0.title == "Parameterized" }
        
        XCTAssertNotNil(simpleResult, "Simple result should be found")
        XCTAssertNotNil(paramResult, "Parameterized result should be found")
        
        guard let simple = simpleResult, let param = paramResult else {
            XCTFail("Results not found")
            return
        }
        
        // Simple link should hide window after execution
        XCTAssertTrue(simple.hideWindowAfterExecution)
        
        // Parameterized link should NOT hide window (needs input form)
        XCTAssertFalse(param.hideWindowAfterExecution)
    }
}
