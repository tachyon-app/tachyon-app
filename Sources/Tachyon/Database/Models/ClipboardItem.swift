import Foundation
import GRDB
import CryptoKit

/// ClipboardItem model for storing clipboard history entries
/// Supports text, code, images, and file references
public struct ClipboardItem: Codable, Equatable, FetchableRecord, PersistableRecord, Identifiable {
    public var id: UUID
    public var timestamp: Int64           // Unix time in milliseconds
    public var type: ContentType
    public var contentHash: String        // SHA-256 hash for deduplication
    public var textContent: String?       // For text/code items
    public var imagePath: String?         // Path to encrypted image file
    public var imageOCRText: String?      // Extracted text from image for search
    public var filePaths: [String]?       // For file items
    public var sourceApp: String?         // Bundle ID of source application
    public var codeLanguage: String?      // For code type: swift, python, javascript, etc.
    public var isPinned: Bool
    public var urlTitle: String?          // For link items: Page title
    // Note: We'll store OG image in a separate cache keyed by contentHash/ID, not directly in DB for now to keep it simple, or reused imagePath?
    // Let's add explicit field.
    
    public enum ContentType: String, Codable {
        case text      // Plain text, rich text, markdown
        case code      // Detected code snippets
        case link      // Detected URLs
        case image     // PNG, JPG, screen captures
        case file      // File references
    }
    
    // GRDB table definition
    public static let databaseTableName = "clipboard_items"
    
    // MARK: - Initializers
    
    public init(
        id: UUID = UUID(),
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        type: ContentType,
        contentHash: String,
        textContent: String? = nil,
        imagePath: String? = nil,
        imageOCRText: String? = nil,
        filePaths: [String]? = nil,
        urlTitle: String? = nil,
        sourceApp: String? = nil,
        codeLanguage: String? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.contentHash = contentHash
        self.textContent = textContent
        self.imagePath = imagePath
        self.imageOCRText = imageOCRText
        self.filePaths = filePaths
        self.urlTitle = urlTitle
        self.sourceApp = sourceApp
        self.codeLanguage = codeLanguage
        self.isPinned = isPinned
    }
    
    // MARK: - Computed Properties
    
    /// Returns a human-readable relative timestamp (e.g., "2m ago", "3h ago")
    public var relativeTimestamp: String {
        let now = Date()
        let itemDate = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
        let interval = now.timeIntervalSince(itemDate)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
    
    /// Returns a truncated preview text for display in the list
    public var previewText: String {
        switch type {
        case .text, .code, .link:
            // For link, prefer title if available, otherwise URL
            if type == .link, let title = urlTitle, !title.isEmpty {
                return title
            }
            
            guard let text = textContent, !text.isEmpty else { return "Empty" }
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: " ")
            if cleaned.count > 100 {
                return String(cleaned.prefix(97)) + "…"
            }
            return cleaned
            
        case .image:
            if let ocrText = imageOCRText, !ocrText.isEmpty {
                return ocrText.count > 100 ? String(ocrText.prefix(97)) + "…" : ocrText
            }
            return "Image"
            
        case .file:
            guard let paths = filePaths, !paths.isEmpty else { return "No files" }
            if paths.count == 1 {
                return URL(fileURLWithPath: paths[0]).lastPathComponent
            }
            return "\(paths.count) files"
        }
    }
    
    /// Icon name for the content type
    public var typeIcon: String {
        switch type {
        case .text:
            return "doc.text"
        case .code:
            return "chevron.left.forwardslash.chevron.right"
        case .link:
            return "link"
        case .image:
            return "photo"
        case .file:
            return "folder"
        }
    }
    
    // MARK: - Hash Generation
    
    /// Generate SHA-256 hash for text content
    public static func generateHash(for text: String) -> String {
        let data = Data(text.utf8)
        return generateHash(for: data)
    }
    
    /// Generate SHA-256 hash for binary data (images, files)
    public static func generateHash(for data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Table Creation

extension ClipboardItem {
    public static func createTable(in db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("timestamp", .integer).notNull()
            t.column("type", .text).notNull()
            t.column("contentHash", .text).notNull().unique()
            t.column("textContent", .text)
            t.column("imagePath", .text)
            t.column("imageOCRText", .text)
            t.column("filePaths", .text)  // JSON encoded array
            t.column("urlTitle", .text)
            t.column("sourceApp", .text)
            t.column("codeLanguage", .text)
            t.column("isPinned", .boolean).notNull().defaults(to: false)
        }
        
        // Indexes for performance
        try db.create(index: "idx_clipboard_timestamp", on: databaseTableName, columns: ["timestamp"], ifNotExists: true)
        try db.create(index: "idx_clipboard_pinned", on: databaseTableName, columns: ["isPinned"], ifNotExists: true)
        try db.create(index: "idx_clipboard_type", on: databaseTableName, columns: ["type"], ifNotExists: true)
    }
}

// MARK: - GRDB Encoding/Decoding for Arrays

extension ClipboardItem {
    enum CodingKeys: String, CodingKey {
        case id, timestamp, type, contentHash, textContent, imagePath
        case imageOCRText, filePaths, urlTitle, sourceApp, codeLanguage, isPinned
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Int64.self, forKey: .timestamp)
        type = try container.decode(ContentType.self, forKey: .type)
        contentHash = try container.decode(String.self, forKey: .contentHash)
        textContent = try container.decodeIfPresent(String.self, forKey: .textContent)
        imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
        imageOCRText = try container.decodeIfPresent(String.self, forKey: .imageOCRText)
        sourceApp = try container.decodeIfPresent(String.self, forKey: .sourceApp)
        codeLanguage = try container.decodeIfPresent(String.self, forKey: .codeLanguage)
        urlTitle = try container.decodeIfPresent(String.self, forKey: .urlTitle)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        
        // Decode filePaths from JSON string
        if let filePathsJSON = try container.decodeIfPresent(String.self, forKey: .filePaths),
           let data = filePathsJSON.data(using: .utf8) {
            filePaths = try? JSONDecoder().decode([String].self, from: data)
        } else {
            filePaths = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)
        try container.encode(contentHash, forKey: .contentHash)
        try container.encodeIfPresent(textContent, forKey: .textContent)
        try container.encodeIfPresent(imagePath, forKey: .imagePath)
        try container.encodeIfPresent(imageOCRText, forKey: .imageOCRText)
        try container.encodeIfPresent(urlTitle, forKey: .urlTitle)
        try container.encodeIfPresent(sourceApp, forKey: .sourceApp)
        try container.encodeIfPresent(codeLanguage, forKey: .codeLanguage)
        try container.encode(isPinned, forKey: .isPinned)
        
        // Encode filePaths as JSON string
        if let filePaths = filePaths {
            let data = try JSONEncoder().encode(filePaths)
            let jsonString = String(data: data, encoding: .utf8)
            try container.encodeIfPresent(jsonString, forKey: .filePaths)
        }
    }
}
