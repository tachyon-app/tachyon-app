import XCTest
@testable import TachyonCore

final class CustomLinksTests: XCTestCase {
    
    var plugin: CustomLinksPlugin!
    
    override func setUp() {
        super.setUp()
        plugin = CustomLinksPlugin()
    }
    
    func testLinkTemplateParsing() {
        let template = LinkTemplate(
            name: "GitHub Repo",
            urlTemplate: "https://github.com/{{user}}/{{repo}}"
        )
        
        XCTAssertEqual(template.placeholders, ["user", "repo"])
    }
    
    func testLinkConstruction() {
        let template = LinkTemplate(
            name: "GitHub Repo",
            urlTemplate: "https://github.com/{{user}}/{{repo}}"
        )
        
        let url = template.constructURL(values: ["user": "apple", "repo": "swift"])
        XCTAssertEqual(url?.absoluteString, "https://github.com/apple/swift")
    }
    
    func testSearchFindsTemplates() {
        // Add a test template
        plugin.addTemplate(LinkTemplate(
            name: "Jira Ticket",
            urlTemplate: "https://jira.company.com/browse/{{ticket}}"
        ))
        
        let results = plugin.search(query: "jira")
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results.first?.title, "Jira Ticket")
    }
    
    func testUrlEncoding() {
        let template = LinkTemplate(
            name: "Search",
            urlTemplate: "https://google.com/search?q={{query}}"
        )
        
        let url = template.constructURL(values: ["query": "hello world"])
        XCTAssertEqual(url?.absoluteString, "https://google.com/search?q=hello%20world")
    }
    
    func testKeywordParsing() {
        // Use a unique keyword to avoid collision with defaults
        plugin.addTemplate(LinkTemplate(
            name: "GitHub Custom",
            keyword: "gh-custom",
            urlTemplate: "https://github.com/{{query}}"
        ))
        
        // Test Trigger + Argument (Custom)
        let resultsArg = plugin.search(query: "gh-custom swift")
        XCTAssertEqual(resultsArg.count, 1)
        XCTAssertEqual(resultsArg.first?.subtitle, "https://github.com/swift")
        
        // Test Trigger + Argument (Default Google)
        let resultsGoogleArg = plugin.search(query: "g swift")
        XCTAssertFalse(resultsGoogleArg.isEmpty)
        // Check finding the right result (Google might be first or second depending on if "g" matches others)
        // In defaults: "GitHub Pull Requests" (gh) vs "Google Search" (g). "g" matches "Google Search".
        let googleResult = resultsGoogleArg.first { $0.title.contains("Google Search") }
        XCTAssertNotNil(googleResult)
        XCTAssertEqual(googleResult?.subtitle, "https://google.com/search?q=swift")

        // Test Trigger only (Default Google)
        let resultsGoogle = plugin.search(query: "g")
        let googleGeneric = resultsGoogle.first { $0.title == "Google Search" }
        XCTAssertNotNil(googleGeneric)
        XCTAssertEqual(googleGeneric?.subtitle, "https://google.com/search?q={{query}}")

        // Test Non-matching Trigger
        let resultsNone = plugin.search(query: "z")
        XCTAssertTrue(resultsNone.isEmpty)
    }
}
