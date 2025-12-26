import Foundation

/// Service for controlling Spotify playback via AppleScript
public class SpotifyPlayerService {
    
    public init() {}
    
    /// Play a Spotify item (track, album, or playlist)
    /// URL format: https://open.spotify.com/{{type}}/{{ID}}?queryparams
    /// Spotify URI format: spotify:{{type}}:{{ID}}
    public func play(item: SpotifyItem) async throws {
        // Parse the URL to extract type and ID
        guard let spotifyURI = parseSpotifyURL(item.url) else {
            throw SpotifyPlayerError.invalidURL(item.url)
        }
        
        let script = """
        tell application "Spotify"
            play track "\(spotifyURI)"
        end tell
        """
        
        try await executeAppleScript(script)
    }
    
    /// Parse Spotify URL to extract spotify:type:id format
    /// Input: https://open.spotify.com/track/4iV5W9uYEdYUVa79Axb7Rh?si=abc123
    /// Output: spotify:track:4iV5W9uYEdYUVa79Axb7Rh
    private func parseSpotifyURL(_ urlString: String) -> String? {
        // Handle both URL format and already-formatted URI
        if urlString.hasPrefix("spotify:") {
            return urlString
        }
        
        guard let url = URL(string: urlString),
              url.host?.contains("spotify.com") == true else {
            return nil
        }
        
        // Path components: ["", "track", "4iV5W9uYEdYUVa79Axb7Rh"]
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        guard pathComponents.count >= 2 else { return nil }
        
        let type = pathComponents[0] // track, album, or playlist
        let id = pathComponents[1]   // The Spotify ID
        
        // Validate type
        guard ["track", "album", "playlist", "show", "episode"].contains(type) else { return nil }
        
        return "spotify:\(type):\(id)"
    }
    
    /// Play a random item from a list
    public func playRandom(from items: [SpotifyItem]) async throws {
        guard !items.isEmpty else { return }
        let randomItem = items.randomElement()!
        try await play(item: randomItem)
    }
    
    /// Pause Spotify playback
    public func pause() async throws {
        let script = """
        tell application "Spotify"
            pause
        end tell
        """
        try await executeAppleScript(script)
    }
    
    /// Resume Spotify playback
    public func resume() async throws {
        let script = """
        tell application "Spotify"
            play
        end tell
        """
        try await executeAppleScript(script)
    }
    
    /// Check if Spotify is running
    public func isSpotifyRunning() -> Bool {
        let script = """
        tell application "System Events"
            return (name of processes) contains "Spotify"
        end tell
        """
        
        guard let appleScript = NSAppleScript(source: script) else { return false }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        return result.booleanValue
    }
    
    // MARK: - Private
    
    private func executeAppleScript(_ source: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                guard let script = NSAppleScript(source: source) else {
                    continuation.resume(throwing: SpotifyPlayerError.scriptError)
                    return
                }
                
                var error: NSDictionary?
                script.executeAndReturnError(&error)
                
                if let error = error {
                    continuation.resume(throwing: SpotifyPlayerError.executionFailed(
                        error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                    ))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

/// Errors for Spotify player
public enum SpotifyPlayerError: Error, LocalizedError {
    case scriptError
    case executionFailed(String)
    case invalidURL(String)
    
    public var errorDescription: String? {
        switch self {
        case .scriptError: return "Failed to create AppleScript"
        case .executionFailed(let msg): return "Spotify control failed: \(msg)"
        case .invalidURL(let url): return "Invalid Spotify URL: \(url)"
        }
    }
}
