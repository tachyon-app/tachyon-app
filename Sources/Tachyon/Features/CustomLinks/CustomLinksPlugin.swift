import Foundation
import AppKit

public class CustomLinksPlugin: Plugin {
    public var id: String { "custom-links" }
    public var name: String { "Custom Links" }
    
    private var templates: [LinkTemplate] = []
    
    public init() {
        // Load saved templates (mock for now)
        loadTemplates()
    }
    
    public func addTemplate(_ template: LinkTemplate) {
        templates.append(template)
        saveTemplates()
    }
    
    public func search(query: String) -> [QueryResult] {
        var results: [QueryResult] = []
        
        for template in templates {
            if let keyword = template.keyword {
                // Check if query starts with keyword
                // Case 1: Exact match "gh" -> show generic
                if query.caseInsensitiveCompare(keyword) == .orderedSame {
                     results.append(createResult(template: template, queryRemainder: ""))
                }
                // Case 2: "gh something" -> show specific
                else if query.lowercased().hasPrefix(keyword.lowercased() + " ") {
                    let remainder = String(query.dropFirst(keyword.count + 1))
                    results.append(createResult(template: template, queryRemainder: remainder))
                }
            } else {
                // Legacy match by name
                if query.isEmpty || 
                   template.name.localizedCaseInsensitiveContains(query) || 
                   template.urlTemplate.localizedCaseInsensitiveContains(query) {
                    results.append(createResult(template: template, queryRemainder: ""))
                }
            }
        }
        
        return results
    }
    
    private func createResult(template: LinkTemplate, queryRemainder: String) -> QueryResult {
        // Simple map for now: {{query}} -> queryRemainder
        let values = ["query": queryRemainder]
        let finalURL = template.constructURL(values: values)
        
        let subtitle = queryRemainder.isEmpty ? template.urlTemplate : (finalURL?.absoluteString ?? template.urlTemplate)
        
        return QueryResult(
            title: template.name + (queryRemainder.isEmpty ? "" : ": \(queryRemainder)"),
            subtitle: subtitle,
            icon: template.icon ?? "link",
            action: {
                if let url = finalURL {
                    NSWorkspace.shared.open(url)
                }
            }
        )
    }

    private func loadTemplates() {
        // TODO: Load from persistence
        // Add some defaults for testing
        templates = [
            LinkTemplate(name: "GitHub Pull Requests", keyword: "gh", urlTemplate: "https://github.com/pulls", icon: "arrow.triangle.pull"),
            LinkTemplate(name: "Google Search", keyword: "g", urlTemplate: "https://google.com/search?q={{query}}", icon: "magnifyingglass")
        ]
    }
    
    private func saveTemplates() {
        // TODO: Save to persistence
    }
}
