import Foundation
import AppKit
import GRDB

public class CustomLinksPlugin: Plugin {
    public var id: String { "custom-links" }
    public var name: String { "Custom Links" }
    
    private var links: [CustomLinkRecord] = []
    private var cancellable: AnyDatabaseCancellable?
    
    public init() {
        startObservation()
    }
    
    private func startObservation() {
        let request = CustomLinkRecord.all()
        let observation = ValueObservation.tracking { db in
            try request.fetchAll(db)
        }
        
        guard let dbQueue = StorageManager.shared.dbQueue else {
            print("❌ StorageManager DB not available for CustomLinks")
            return
        }
        
        cancellable = observation.start(
            in: dbQueue,
            onError: { error in
                print("❌ CustomLinksPlugin observation error: \(error)")
            },
            onChange: { [weak self] links in
                self?.links = links
                print("✅ CustomLinksPlugin updated with \(links.count) links")
            }
        )
    }
    
    public func search(query: String) -> [QueryResult] {
        guard !query.isEmpty else { return [] }
        
        return links.compactMap { link in
            // Fuzzy match on name
            guard link.name.localizedCaseInsensitiveContains(query) else { return nil }
            
            let hasParams = !link.parameters.isEmpty
            
            return QueryResult(
                id: link.id,
                title: link.name,
                subtitle: hasParams ? "Custom Link (requires input)" : link.urlTemplate,
                icon: "link",
                iconPath: nil,
                iconData: link.icon,
                alwaysShow: false,
                hideWindowAfterExecution: !hasParams, // Don't hide if params needed
                action: { [weak self] in
                    self?.handleLinkAction(link)
                }
            )
        }
    }
    
    private func handleLinkAction(_ link: CustomLinkRecord) {
        if link.parameters.isEmpty {
            // No params, open directly
            if let url = link.constructURL(values: [:]) {
                NSWorkspace.shared.open(url)
            }
        } else {
            // Has params, trigger inline argument mode (Raycast-style)
            NotificationCenter.default.post(
                name: NSNotification.Name("EnterInlineLinkArgumentMode"),
                object: link
            )
        }
    }
}
