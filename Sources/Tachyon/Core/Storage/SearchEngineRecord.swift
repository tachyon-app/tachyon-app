import Foundation
import GRDB

public struct SearchEngineRecord: Codable, FetchableRecord, PersistableRecord, Identifiable {
    public var id: UUID
    public var name: String
    public var keyword: String
    public var urlTemplate: String
    public var icon: Data?
    
    public init(id: UUID = UUID(), name: String, keyword: String, urlTemplate: String, icon: Data? = nil) {
        self.id = id
        self.name = name
        self.keyword = keyword
        self.urlTemplate = urlTemplate
        self.icon = icon
    }
    
    // Define database table name
    public static var databaseTableName = "search_engines"
}
