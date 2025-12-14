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
}
