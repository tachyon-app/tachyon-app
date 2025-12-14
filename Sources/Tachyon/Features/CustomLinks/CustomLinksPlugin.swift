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
        // Filter templates that match the query
        let filteredTemplates = templates.filter { template in
            if query.isEmpty { return true }
            return template.name.localizedCaseInsensitiveContains(query) || 
                   template.urlTemplate.localizedCaseInsensitiveContains(query)
        }
        
        return filteredTemplates.map { template in
            QueryResult(
                title: template.name,
                subtitle: template.urlTemplate,
                icon: template.icon ?? "link",
                action: {
                    // TODO: Show input form for placeholders
                    // For MVP, if there are no placeholders, just open it
                    if template.placeholders.isEmpty {
                        if let url = URL(string: template.urlTemplate) {
                            NSWorkspace.shared.open(url)
                        }
                    } else {
                        print("Opening template with placeholders not yet implemented: \(template.name)")
                    }
                }
            )
        }
    }
    
    private func loadTemplates() {
        // TODO: Load from persistence
        // Add some defaults for testing
        templates = [
            LinkTemplate(name: "GitHub Pull Requests", urlTemplate: "https://github.com/pulls", icon: "arrow.triangle.pull"),
            LinkTemplate(name: "Google Search", urlTemplate: "https://google.com/search?q={{query}}", icon: "magnifyingglass")
        ]
    }
    
    private func saveTemplates() {
        // TODO: Save to persistence
    }
}
