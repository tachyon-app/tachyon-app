import Foundation
import AppKit

/// Service for fetching favicons from URLs
class FaviconService {
    static let shared = FaviconService()
    
    private init() {}
    
    /// Fetches favicon for a given URL
    /// - Parameter urlString: The URL to fetch favicon for
    /// - Returns: PNG data of the favicon, or nil if fetch fails
    func fetchFavicon(for urlString: String) async -> Data? {
        guard let domain = extractDomain(from: urlString) else {
            return nil
        }
        
        // Try multiple favicon sources
        let faviconURLs = [
            "https://www.google.com/s2/favicons?domain=\(domain)&sz=64",
            "https://\(domain)/favicon.ico",
            "https://\(domain)/apple-touch-icon.png"
        ]
        
        for faviconURLString in faviconURLs {
            if let favicon = await downloadFavicon(from: faviconURLString) {
                return favicon
            }
        }
        
        return nil
    }
    
    /// Extracts domain from a URL string
    private func extractDomain(from urlString: String) -> String? {
        // Handle template URLs by extracting the base domain
        var cleanURL = urlString
            .replacingOccurrences(of: "{argument}", with: "test")
            .replacingOccurrences(of: "{{query}}", with: "test")
        
        guard let url = URL(string: cleanURL),
              let host = url.host else {
            return nil
        }
        
        return host
    }
    
    /// Downloads favicon from URL and converts to PNG data
    private func downloadFavicon(from urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            // Convert to NSImage and resize if needed
            guard let image = NSImage(data: data) else {
                return nil
            }
            
            // Resize to 32x32 for consistency
            let resizedImage = resizeImage(image, to: NSSize(width: 32, height: 32))
            
            // Convert to PNG data
            guard let tiffData = resizedImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else {
                return nil
            }
            
            return pngData
        } catch {
            print("❌ Failed to download favicon from \(urlString): \(error)")
            return nil
        }
    }
    
    /// Resizes an image to the specified size
    private func resizeImage(_ image: NSImage, to size: NSSize) -> NSImage {
        let resizedImage = NSImage(size: size)
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        resizedImage.unlockFocus()
        return resizedImage
    }
}
