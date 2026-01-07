import Foundation
import TachyonCore

/// Plugin that provides Clipboard History as a searchable command
public class ClipboardHistoryPlugin: Plugin {
    public var id: String { "clipboard-history" }
    public var name: String { "Clipboard History" }
    
    public init() {}
    
    public func search(query: String) -> [QueryResult] {
        // Match against common search terms
        let searchTerms = ["clipboard", "clipboard history", "paste history", "copy history", "recent copies", "history"]
        
        let queryLower = query.lowercased()
        
        // Check if query matches any search term
        let matches = searchTerms.contains { term in
            term.hasPrefix(queryLower) || term.contains(queryLower)
        }
        
        guard matches else {
            return []
        }
        
        return [
            QueryResult(
                id: UUID(),
                title: "Clipboard History",
                subtitle: "View and paste from clipboard history ⌘⇧V",
                icon: "doc.on.clipboard",
                action: {
                    // Post notification to open clipboard history
                    NotificationCenter.default.post(
                        name: Notification.Name("OpenClipboardHistory"),
                        object: nil
                    )
                }
            )
        ]
    }
}
