import Foundation
import AppKit
import GRDB

public class SearchEnginePlugin: Plugin {
    public var id: String { "search-engines" }
    public var name: String { "Search Engines" }
    
    private var engines: [SearchEngineRecord] = []
    private var observationTask: TransactionObserver? // Just holding reference if needed, but GRDB observation is usually Cancellable
    private var cancellable: AnyDatabaseCancellable?
    
    public init() {
        startObservation()
    }
    
    private func startObservation() {
        let request = SearchEngineRecord.all()
        let observation = ValueObservation.tracking { db in
            try request.fetchAll(db)
        }
        
        // StorageManager might not be ready if init throws?
        // But setupDatabase uses try? so it might fail silently.
        // If dbQueue is nil, we can't observe.
        guard let dbQueue = StorageManager.shared.dbQueue else {
            print("❌ StorageManager DB not available")
            return
        }
        
        cancellable = observation.start(
            in: dbQueue,
            onError: { error in
                print("❌ SearchEnginePlugin observation error: \(error)")
            },
            onChange: { [weak self] engines in
                self?.engines = engines
                print("✅ SearchEnginePlugin updated with \(engines.count) engines")
            }
        )
    }
    
    public func search(query: String) -> [QueryResult] {
        guard !query.isEmpty else { return [] }
        
        return engines.map { engine in
            let urlString = engine.urlTemplate.replacingOccurrences(
                of: "{{query}}", 
                with: query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            )
            
            return QueryResult(
                id: UUID(), // Or stable ID based on engine.id? 
                title: "Search in \(engine.name)",
                subtitle: "Search for '\(query)'",
                icon: nil, 
                iconPath: nil,
                iconData: engine.icon, // Use Blob data
                alwaysShow: true, 
                action: {
                    if let url = URL(string: urlString) {
                        NSWorkspace.shared.open(url)
                    }
                }
            )
        }
    }
}
