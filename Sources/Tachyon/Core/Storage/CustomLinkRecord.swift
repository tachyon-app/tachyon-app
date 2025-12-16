import Foundation
import GRDB

public struct CustomLinkRecord: Codable, FetchableRecord, PersistableRecord, Identifiable {
    public var id: UUID
    public var name: String
    public var urlTemplate: String
    public var icon: Data?
    public var defaults: [String: String] // JSON stored as Dictionary
    
    public static var databaseTableName = "custom_links"
    
    enum CodingKeys: String, CodingKey {
        case id, name, urlTemplate, icon, defaults
    }
    
    public init(id: UUID = UUID(), name: String, urlTemplate: String, icon: Data? = nil, defaults: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.urlTemplate = urlTemplate
        self.icon = icon
        self.defaults = defaults
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        urlTemplate = try container.decode(String.self, forKey: .urlTemplate)
        icon = try container.decodeIfPresent(Data.self, forKey: .icon)
        
        // Decode defaults from JSON string
        if let defaultsString = try? container.decode(String.self, forKey: .defaults),
           let defaultsData = defaultsString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: String].self, from: defaultsData) {
            defaults = decoded
        } else {
            defaults = [:]
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(urlTemplate, forKey: .urlTemplate)
        try container.encodeIfPresent(icon, forKey: .icon)
        
        // Encode defaults as JSON string
        let defaultsData = try JSONEncoder().encode(defaults)
        let defaultsString = String(data: defaultsData, encoding: .utf8) ?? "{}"
        try container.encode(defaultsString, forKey: .defaults)
    }
    
    /// Extract placeholder names from the template (e.g. {{user}} -> "user")
    public var parameters: [String] {
        let regex = try! NSRegularExpression(pattern: "\\{\\{([^}]+)\\}\\}", options: [])
        let nsString = urlTemplate as NSString
        let results = regex.matches(in: urlTemplate, options: [], range: NSRange(location: 0, length: nsString.length))
        
        // Use Set to remove duplicates, then sort for stability
        let params = results.map { nsString.substring(with: $0.range(at: 1)).trimmingCharacters(in: .whitespaces) }
        return Array(Set(params)).sorted()
    }
    
    public func constructURL(values: [String: String]) -> URL? {
        var finalString = urlTemplate
        
        // Merge defaults with provided values
        var effectiveValues = defaults
        values.forEach { effectiveValues[$0.key] = $0.value }
        
        for key in parameters {
            let placeholder = "{{\(key)}}"
            let value = effectiveValues[key] ?? ""
            
            // URL encode the value
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            finalString = finalString.replacingOccurrences(of: placeholder, with: encodedValue)
        }
        
        return URL(string: finalString)
    }
}

