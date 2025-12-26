import Foundation

/// Service for validating and extracting metadata from Spotify URLs
public class SpotifyMetadataService {
    
    public init() {}
    
    // MARK: - URL Validation
    
    /// Check if URL is a valid Spotify URL
    public func isValidSpotifyURL(_ urlString: String) -> Bool {
        // Normalize URL
        let normalized = urlString.hasPrefix("https://") ? urlString : "https://" + urlString
        
        guard let url = URL(string: normalized),
              let host = url.host else {
            return false
        }
        
        // Check host is Spotify
        guard host == "open.spotify.com" || host.hasSuffix(".spotify.com") else {
            return false
        }
        
        // Check path contains valid content type
        let path = url.path
        return path.contains("/track/") || 
               path.contains("/album/") || 
               path.contains("/playlist/") ||
               path.contains("/show/") ||
               path.contains("/episode/")
    }
    
    /// Get the item type from a Spotify URL
    public func getItemType(from urlString: String) -> SpotifyItemType? {
        let normalized = urlString.hasPrefix("https://") ? urlString : "https://" + urlString
        
        if normalized.contains("/track/") {
            return .track
        } else if normalized.contains("/album/") {
            return .album
        } else if normalized.contains("/playlist/") {
            return .playlist
        } else if normalized.contains("/show/") {
            return .show
        } else if normalized.contains("/episode/") {
            return .episode
        }
        return nil
    }
    
    // MARK: - Metadata Extraction
    
    /// Fetch metadata from Spotify URL
    public func fetchMetadata(from urlString: String) async throws -> SpotifyItem {
        guard isValidSpotifyURL(urlString) else {
            throw SpotifyMetadataError.invalidURL
        }
        
        guard let itemType = getItemType(from: urlString) else {
            throw SpotifyMetadataError.unknownType
        }
        
        let normalized = urlString.hasPrefix("https://") ? urlString : "https://" + urlString
        guard let url = URL(string: normalized) else {
            throw SpotifyMetadataError.invalidURL
        }
        
        // Fetch HTML from URL
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw SpotifyMetadataError.fetchFailed
        }
        
        // Extract og:title
        let title = extractMetaContent(from: html, property: "og:title") ?? "Unknown"
        
        // Extract og:image
        let imageURL = extractMetaContent(from: html, property: "og:image")
        
        return SpotifyItem(
            url: normalized,
            title: title,
            imageURL: imageURL,
            type: itemType
        )
    }
    
    // MARK: - HTML Parsing
    
    private func extractMetaContent(from html: String, property: String) -> String? {
        // Simple regex to extract meta content
        // Pattern: <meta property="og:title" content="...">
        let patterns = [
            "<meta[^>]+property=\"\(property)\"[^>]+content=\"([^\"]+)\"",
            "<meta[^>]+content=\"([^\"]+)\"[^>]+property=\"\(property)\""
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                return String(html[range])
            }
        }
        
        return nil
    }
}

/// Errors that can occur when fetching Spotify metadata
public enum SpotifyMetadataError: Error, LocalizedError {
    case invalidURL
    case unknownType
    case fetchFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid Spotify URL"
        case .unknownType: return "Unknown Spotify content type"
        case .fetchFailed: return "Failed to fetch metadata"
        }
    }
}
