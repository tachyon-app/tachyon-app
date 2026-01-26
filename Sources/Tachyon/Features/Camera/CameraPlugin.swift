import Foundation

/// Plugin that provides the "Open Camera" command in Tachyon search
public class CameraPlugin: Plugin {
    
    public var id: String { "camera" }
    public var name: String { "Camera" }
    
    /// Keywords that trigger the camera command
    private let keywords: Set<String> = [
        "camera", "webcam", "selfie", "photo", "take photo",
        "open camera", "check camera", "mirror", "video",
        "facetime", "meeting", "appearance"
    ]
    
    public init() {}
    
    public func search(query: String) -> [QueryResult] {
        guard !query.isEmpty else { return [] }
        
        let lowercaseQuery = query.lowercased()
        
        // Check if query matches any keyword
        let matches = keywords.contains { keyword in
            keyword.contains(lowercaseQuery) || lowercaseQuery.contains(keyword)
        }
        
        // Also check for partial matches
        let partialMatch = keywords.contains { keyword in
            keyword.hasPrefix(lowercaseQuery) || 
            keyword.split(separator: " ").contains { $0.hasPrefix(lowercaseQuery) }
        }
        
        guard matches || partialMatch else { return [] }
        
        return [
            QueryResult(
                title: "Open Camera",
                subtitle: "Preview your camera, take photos, switch cameras",
                icon: "camera.fill",
                alwaysShow: false,
                hideWindowAfterExecution: false,  // Keep window open to show camera
                action: {
                    // Action will be handled by SearchBarViewModel to show camera view
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenCameraView"),
                        object: nil
                    )
                }
            )
        ]
    }
}
