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
        case .leftHalf: return "Left Half"
        case .rightHalf: return "Right Half"
        case .topHalf: return "Top Half"
        case .bottomHalf: return "Bottom Half"
        case .cycleQuarters: return "Cycle Quarters"
        case .cycleThreeQuarters: return "Cycle Three Quarters"
        case .cycleThirds: return "Cycle Thirds"
        case .cycleTwoThirds: return "Cycle Two Thirds"
        case .maximize: return "Maximize"
        case .fullscreen: return "Fullscreen"
        case .center: return "Center"
        case .nextDisplay: return "Next Display"
        case .previousDisplay: return "Previous Display"
        }
    }
}
