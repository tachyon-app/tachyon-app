import Foundation

/// Configuration constants for clipboard monitoring
/// These are centralized here for easy adjustment
public enum ClipboardMonitorConfig {
    /// Polling interval in seconds. Balances responsiveness vs CPU usage.
    /// Raycast uses approximately 500ms. Can be adjusted if needed.
    public static let pollingInterval: TimeInterval = 0.5
    
    /// Maximum text content length (characters)
    /// Content exceeding this limit will not be stored
    public static let maxTextLength: Int = 100_000
    
    /// Maximum image size in bytes (10 MB)
    /// Images exceeding this limit will not be stored
    public static let maxImageSize: Int = 10 * 1024 * 1024
    
    /// Maximum number of file paths per entry
    /// File entries exceeding this limit will not be stored
    public static let maxFilePaths: Int = 100
    
    /// Default maximum number of history items
    public static let defaultMaxItems: Int = 200
    
    /// Directory name for storing clipboard images
    public static let imageStorageDirectory: String = "clipboard_images"
}
