import Foundation

/// All possible window snapping actions
public enum WindowAction: String, CaseIterable, Codable {
    // Halves
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    
    // Quarters (cycle through all 4)
    case cycleQuarters
    
    // Three-Quarters (cycle between first and last)
    case cycleThreeQuarters
    
    // Thirds (cycle through all 3)
    case cycleThirds
    
    // Two-Thirds (cycle between first and last)
    case cycleTwoThirds
    
    // Maximize & Center
    case maximize
    case fullscreen
    case center
    
    // Multi-monitor
    case nextDisplay
    case previousDisplay
    
    /// Human-readable name for the action
    public var displayName: String {
        switch self {
        case .leftHalf: return "Window Management Left Half"
        case .rightHalf: return "Window Management Right Half"
        case .topHalf: return "Window Management Top Half"
        case .bottomHalf: return "Window Management Bottom Half"
        case .cycleQuarters: return "Window Management Cycle Quarters"
        case .cycleThreeQuarters: return "Window Management Cycle Three Quarters"
        case .cycleThirds: return "Window Management Cycle Thirds"
        case .cycleTwoThirds: return "Window Management Cycle Two Thirds"
        case .maximize: return "Window Management Maximize"
        case .fullscreen: return "Window Management Fullscreen"
        case .center: return "Window Management Center"
        case .nextDisplay: return "Window Management Next Display"
        case .previousDisplay: return "Window Management Previous Display"
        }
    }
}
