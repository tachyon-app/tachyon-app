import Foundation
import AppKit

public class DateCalculationsPlugin: Plugin {
    public var id: String { "date-calculations" }
    public var name: String { "Date & Time" }
    
    private let parser = DateExpressionParser()
    
    public init() {}
    
    public func search(query: String) -> [QueryResult] {
        guard let result = parser.parse(query) else {
            return []
        }
        
        return [createResult(from: result)]
    }
    
    private func createResult(from result: DateResult) -> QueryResult {
        // For "days until" queries, show the duration as the title
        let title: String
        let subtitle: String
        
        if result.type == .dateDifference {
            // Show duration as title, date as subtitle
            title = result.formats.relative
            subtitle = result.formats.humanReadable
        } else {
            // Normal: date as title, metadata as subtitle
            title = result.formats.humanReadable
            subtitle = result.primarySubtitle
        }
        
        return QueryResult(
            id: UUID(),
            title: title,
            subtitle: subtitle,
            icon: "calendar",
            alwaysShow: true, // Always show because parser already validated the query
            hideWindowAfterExecution: true,
            action: {
                // Default action: Copy human readable format
                self.copyToClipboard(result.formats.humanReadable)
                self.showNotification("Copied date to clipboard")
            }
        )
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func showNotification(_ message: String) {
        NotificationCenter.default.post(
            name: NSNotification.Name("UpdateStatusBar"),
            object: ("📅", message)
        )
    }
}
