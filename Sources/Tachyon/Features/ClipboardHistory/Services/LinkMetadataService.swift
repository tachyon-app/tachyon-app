import Foundation
import LinkPresentation
import AppKit

/// Service to fetch OpenGraph metadata (title, image) from URLs
/// using Apple's LinkPresentation framework.
@available(macOS 10.15, *)
public actor LinkMetadataService {
    public static let shared = LinkMetadataService()
    
    // In-memory cache to avoid excessive requests
    // Key: URL absolute string
    private var fetchCache: Set<String> = []
    
    private init() {}
    
    /// Fetch metadata for a given URL
    /// Returns title and image (if available)
    public func fetchMetadata(for url: URL) async throws -> (title: String?, image: NSImage?) {
        // Instantiate a new provider for each request
        let metadataProvider = LPMetadataProvider()
        metadataProvider.timeout = 5.0
        
        // Ensure we handle thread affinity issues if any (LPMetadataProvider is mainly main thread?)
        // Docs say startFetchingMetadata is async. Should be fine.
        
        let metadata = try await metadataProvider.startFetchingMetadata(for: url)
        
        // Extract content
        var image: NSImage? = nil
        
        if let imageProvider = metadata.imageProvider {
            image = try? await loadItem(provider: imageProvider)
        }
        
        return (metadata.title, image)
    }
    
    private func loadItem(provider: NSItemProvider) async throws -> NSImage? {
        return try await withCheckedThrowingContinuation { continuation in
            provider.loadObject(ofClass: NSImage.self) { item, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: item as? NSImage)
                }
            }
        }
    }
}
