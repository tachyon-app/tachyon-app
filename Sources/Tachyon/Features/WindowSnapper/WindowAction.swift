import Foundation

/// All possible window snapping actions
public enum WindowAction: String, CaseIterable, Codable {
    // Halves
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    
    // Quarters
    case topLeftQuarter
    case topRightQuarter
    case bottomLeftQuarter
    case bottomRightQuarter
    case firstThreeQuarters
    case lastThreeQuarters
    
    // Thirds
    case firstThird
    case centerThird
    case lastThird
    case firstTwoThirds
    case lastTwoThirds
    
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
        case .topLeftQuarter: return "Top Left Quarter"
        case .topRightQuarter: return "Top Right Quarter"
        case .bottomLeftQuarter: return "Bottom Left Quarter"
        case .bottomRightQuarter: return "Bottom Right Quarter"
        case .firstThreeQuarters: return "First Three Quarters"
        case .lastThreeQuarters: return "Last Three Quarters"
        case .firstThird: return "First Third"
        case .centerThird: return "Center Third"
        case .lastThird: return "Last Third"
        case .firstTwoThirds: return "First Two Thirds"
        case .lastTwoThirds: return "Last Two Thirds"
        case .maximize: return "Maximize"
        case .fullscreen: return "Fullscreen"
        case .center: return "Center"
        case .nextDisplay: return "Next Display"
        case .previousDisplay: return "Previous Display"
        }
    }
}
