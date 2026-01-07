import Cocoa

/// Helper to access module resources explicitly
public enum TachyonAssets {
    /// The main application logo
    public static var logoURL: URL? {
        Bundle.module.url(forResource: "Logo", withExtension: "png")
    }
    
    /// The application icon
    public static var iconURL: URL? {
        Bundle.module.url(forResource: "icon", withExtension: "png")
    }
    
    /// Helper to get the logo as NSImage
    public static var logo: NSImage? {
        guard let url = logoURL else { return nil }
        return NSImage(contentsOf: url)
    }
    
    /// Helper to get the icon as NSImage
    public static var icon: NSImage? {
        guard let url = iconURL else { return nil }
        return NSImage(contentsOf: url)
    }
}
