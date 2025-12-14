import Foundation

/// Represents a URL template with placeholders
public struct LinkTemplate: Codable, Identifiable {
    public var id: UUID = UUID()
    public let name: String
    public let keyword: String? // Short trigger e.g. "gh", "g"
    public let urlTemplate: String
    public let icon: String?
    
    public init(id: UUID = UUID(), name: String, keyword: String? = nil, urlTemplate: String, icon: String? = nil) {
        self.id = id
        self.name = name
        self.keyword = keyword
        self.urlTemplate = urlTemplate
        self.icon = icon
    }
    
    /// Extract placeholder names from the template (e.g. {{user}} -> "user")
    public var placeholders: [String] {
        let regex = try! NSRegularExpression(pattern: "\\{\\{([^}]+)\\}\\}", options: [])
        let nsString = urlTemplate as NSString
        let results = regex.matches(in: urlTemplate, options: [], range: NSRange(location: 0, length: nsString.length))
        
        return results.map { nsString.substring(with: $0.range(at: 1)).trimmingCharacters(in: .whitespaces) }
    }
    
    /// Construct the final URL by replacing placeholders with values
    public func constructURL(values: [String: String]) -> URL? {
        var finalString = urlTemplate
        
        for (key, value) in values {
            let placeholder = "{{\(key)}}"
            // URL encode the value
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            finalString = finalString.replacingOccurrences(of: placeholder, with: encodedValue)
        }
        
        return URL(string: finalString)
    }
}
