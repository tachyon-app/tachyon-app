import Foundation
import AppKit

/// Pure geometry calculations for window snapping
public struct WindowGeometry {
    
    /// Proportional tolerance for position detection (5% of screen dimension)
    private static let proportionalTolerance: CGFloat = 0.05
    
    // MARK: - Third Position Helpers
    
    /// Determine which third position the window is in (1=first, 2=center, 3=last) or nil
    /// Uses proportional detection to work across different screen sizes
    /// Also handles apps with minimum width constraints that can't shrink to target size
    public static func currentThirdPosition(frame: CGRect, visibleFrame: CGRect) -> Int? {
        let tolerance = proportionalTolerance
        
        // Check proportional height (~100%) - this must still match
        let heightRatio = frame.height / visibleFrame.height
        guard abs(heightRatio - 1.0) < tolerance else { return nil }
        
        // Check proportional width (~33%)
        let widthRatio = frame.width / visibleFrame.width
        let widthMatches = abs(widthRatio - 1.0/3.0) < tolerance
        
        // Also accept if width is LARGER than expected (app has minimum width constraint)
        // but still less than or equal to the target + extra tolerance
        let widthConstrainedButClose = widthRatio >= 1.0/3.0 && widthRatio <= 0.5
        
        guard widthMatches || widthConstrainedButClose else { return nil }
        
        // Check proportional X position
        let xRatio = (frame.origin.x - visibleFrame.origin.x) / visibleFrame.width
        if abs(xRatio - 0.0) < tolerance { return 1 }       // First third
        if abs(xRatio - 1.0/3.0) < tolerance { return 2 }   // Center third
        if abs(xRatio - 2.0/3.0) < tolerance { return 3 }   // Last third
        
        return nil
    }
    
    /// Get target frame for nth third (1=first, 2=center, 3=last)
    /// For the last position, we align by right edge so windows with min width constraints don't overflow
    public static func thirdFrame(position: Int, visibleFrame: CGRect) -> CGRect {
        let width = visibleFrame.width
        let x = visibleFrame.origin.x
        let y = visibleFrame.origin.y
        let height = visibleFrame.height
        let targetWidth = width / 3
        
        switch position {
        case 1: return CGRect(x: x, y: y, width: targetWidth, height: height)
        case 2: return CGRect(x: x + width / 3, y: y, width: targetWidth, height: height)
        case 3: 
            // Align by right edge: x = screenRight - targetWidth
            let rightEdge = x + width
            return CGRect(x: rightEdge - targetWidth, y: y, width: targetWidth, height: height)
        default: return CGRect(x: x, y: y, width: targetWidth, height: height)
        }
    }
    
    // MARK: - Two-Thirds Position Helpers
    
    /// Determine which two-thirds position the window is in (1=first, 2=last) or nil
    /// Uses proportional detection to work across different screen sizes
    public static func currentTwoThirdsPosition(frame: CGRect, visibleFrame: CGRect) -> Int? {
        let tolerance = proportionalTolerance
        
        // Check proportional width (~66%)
        let widthRatio = frame.width / visibleFrame.width
        guard abs(widthRatio - 2.0/3.0) < tolerance else { return nil }
        
        // Check proportional height (~100%)
        let heightRatio = frame.height / visibleFrame.height
        guard abs(heightRatio - 1.0) < tolerance else { return nil }
        
        // Check proportional X position
        let xRatio = (frame.origin.x - visibleFrame.origin.x) / visibleFrame.width
        if abs(xRatio - 0.0) < tolerance { return 1 }       // First two thirds
        if abs(xRatio - 1.0/3.0) < tolerance { return 2 }   // Last two thirds
        
        return nil
    }
    
    /// Get target frame for nth two-thirds (1=first, 2=last)
    public static func twoThirdsFrame(position: Int, visibleFrame: CGRect) -> CGRect {
        let width = visibleFrame.width
        let x = visibleFrame.origin.x
        let y = visibleFrame.origin.y
        let height = visibleFrame.height
        
        switch position {
        case 1: return CGRect(x: x, y: y, width: width * 2 / 3, height: height)
        case 2: return CGRect(x: x + width / 3, y: y, width: width * 2 / 3, height: height)
        default: return CGRect(x: x, y: y, width: width * 2 / 3, height: height)
        }
    }
    
    // MARK: - Quarter Position Helpers (vertical quarters: 1, 2, 3, 4 from left to right)
    
    /// Determine which quarter position the window is in (1-4, vertical quarters) or nil
    /// Uses proportional detection to work across different screen sizes
    /// Also handles apps with minimum width constraints that can't shrink to target size
    public static func currentQuarterPosition(frame: CGRect, visibleFrame: CGRect) -> Int? {
        let tolerance = proportionalTolerance
        
        // Check proportional height (~100%) - this must still match
        let heightRatio = frame.height / visibleFrame.height
        guard abs(heightRatio - 1.0) < tolerance else { return nil }
        
        // Check proportional width (~25%)
        let widthRatio = frame.width / visibleFrame.width
        let widthMatches = abs(widthRatio - 0.25) < tolerance
        
        // Also accept if width is LARGER than expected (app has minimum width constraint)
        // but still less than or equal to half the screen (otherwise it's clearly not a quarter)
        let widthConstrainedButClose = widthRatio >= 0.25 && widthRatio <= 0.5
        
        guard widthMatches || widthConstrainedButClose else { return nil }
        
        // Check proportional X position
        let xRatio = (frame.origin.x - visibleFrame.origin.x) / visibleFrame.width
        if abs(xRatio - 0.0) < tolerance { return 1 }    // First quarter
        if abs(xRatio - 0.25) < tolerance { return 2 }   // Second quarter
        if abs(xRatio - 0.5) < tolerance { return 3 }    // Third quarter
        if abs(xRatio - 0.75) < tolerance { return 4 }   // Fourth quarter
        
        return nil
    }
    
    /// Get target frame for nth quarter (1-4, vertical quarters)
    /// For the last position, we align by right edge so windows with min width constraints don't overflow
    public static func quarterFrame(position: Int, visibleFrame: CGRect) -> CGRect {
        let width = visibleFrame.width
        let height = visibleFrame.height
        let x = visibleFrame.origin.x
        let y = visibleFrame.origin.y
        let targetWidth = width / 4
        
        switch position {
        case 1: return CGRect(x: x, y: y, width: targetWidth, height: height)  // First quarter
        case 2: return CGRect(x: x + width / 4, y: y, width: targetWidth, height: height)  // Second quarter
        case 3: return CGRect(x: x + width / 2, y: y, width: targetWidth, height: height)  // Third quarter
        case 4: 
            // Align by right edge: x = screenRight - targetWidth
            let rightEdge = x + width
            return CGRect(x: rightEdge - targetWidth, y: y, width: targetWidth, height: height)  // Fourth quarter
        default: return CGRect(x: x, y: y, width: targetWidth, height: height)
        }
    }
    
    // MARK: - Three-Quarters Position Helpers
    
    /// Determine which three-quarters position the window is in (1=first, 2=last) or nil
    /// Uses proportional detection to work across different screen sizes
    public static func currentThreeQuartersPosition(frame: CGRect, visibleFrame: CGRect) -> Int? {
        let tolerance = proportionalTolerance
        
        // Check proportional width (~75%)
        let widthRatio = frame.width / visibleFrame.width
        guard abs(widthRatio - 0.75) < tolerance else { return nil }
        
        // Check proportional height (~100%)
        let heightRatio = frame.height / visibleFrame.height
        guard abs(heightRatio - 1.0) < tolerance else { return nil }
        
        // Check proportional X position
        let xRatio = (frame.origin.x - visibleFrame.origin.x) / visibleFrame.width
        if abs(xRatio - 0.0) < tolerance { return 1 }    // First three quarters
        if abs(xRatio - 0.25) < tolerance { return 2 }   // Last three quarters
        
        return nil
    }
    
    /// Get target frame for nth three-quarters (1=first, 2=last)
    public static func threeQuartersFrame(position: Int, visibleFrame: CGRect) -> CGRect {
        let width = visibleFrame.width
        let x = visibleFrame.origin.x
        let y = visibleFrame.origin.y
        let height = visibleFrame.height
        
        switch position {
        case 1: return CGRect(x: x, y: y, width: width * 3 / 4, height: height)
        case 2: return CGRect(x: x + width / 4, y: y, width: width * 3 / 4, height: height)
        default: return CGRect(x: x, y: y, width: width * 3 / 4, height: height)
        }
    }
    
    // MARK: - Main Target Frame Calculation
    
    /// Calculate target frame for a window action
    public static func targetFrame(
        for action: WindowAction,
        currentFrame: CGRect,
        visibleFrame: CGRect
    ) -> CGRect {
        let width = visibleFrame.width
        let height = visibleFrame.height
        let x = visibleFrame.origin.x
        let y = visibleFrame.origin.y
        
        switch action {
        // MARK: - Halves
        case .leftHalf:
            return CGRect(x: x, y: y, width: width / 2, height: height)
            
        case .rightHalf:
            return CGRect(x: x + width / 2, y: y, width: width / 2, height: height)
            
        case .topHalf:
            return CGRect(x: x, y: y, width: width, height: height / 2)
            
        case .bottomHalf:
            return CGRect(x: x, y: y + height / 2, width: width, height: height / 2)
            
        // MARK: - Corner Quarters
        case .topLeftQuarter:
            return CGRect(x: x, y: y, width: width / 2, height: height / 2)
            
        case .topRightQuarter:
            return CGRect(x: x + width / 2, y: y, width: width / 2, height: height / 2)
            
        case .bottomLeftQuarter:
            return CGRect(x: x, y: y + height / 2, width: width / 2, height: height / 2)
            
        case .bottomRightQuarter:
            return CGRect(x: x + width / 2, y: y + height / 2, width: width / 2, height: height / 2)
            
        // MARK: - Cycle Actions (handled by WindowSnapperService)
        case .cycleQuarters, .cycleThreeQuarters, .cycleThirds, .cycleTwoThirds:
            return currentFrame  // Cycle logic handled elsewhere
            
        // MARK: - Maximize & Center
        case .maximize:
            return visibleFrame
            
        case .fullscreen:
            return visibleFrame
            
        case .center:
            let centeredX = x + (width - currentFrame.width) / 2
            let centeredY = y + (height - currentFrame.height) / 2
            return CGRect(
                x: centeredX,
                y: centeredY,
                width: currentFrame.width,
                height: currentFrame.height
            )
            
        // MARK: - Multi-monitor
        case .nextDisplay, .previousDisplay:
            return currentFrame
        }
    }
    
    /// Determine if a window is currently at a snap position
    /// Uses proportional detection to work across different screen sizes
    public static func currentSnapPosition(
        frame: CGRect,
        visibleFrame: CGRect
    ) -> WindowAction? {
        let tolerance = proportionalTolerance
        
        // Calculate proportional dimensions
        let widthRatio = frame.width / visibleFrame.width
        let heightRatio = frame.height / visibleFrame.height
        let xRatio = (frame.origin.x - visibleFrame.origin.x) / visibleFrame.width
        let yRatio = (frame.origin.y - visibleFrame.origin.y) / visibleFrame.height
        
        // Check maximize (~100% width and height, at origin)
        if abs(widthRatio - 1.0) < tolerance && abs(heightRatio - 1.0) < tolerance &&
           abs(xRatio) < tolerance && abs(yRatio) < tolerance {
            return .maximize
        }
        
        // Check left half (~50% width, ~100% height, at left edge)
        if abs(widthRatio - 0.5) < tolerance && abs(heightRatio - 1.0) < tolerance &&
           abs(xRatio) < tolerance {
            return .leftHalf
        }
        
        // Check right half (~50% width, ~100% height, at right edge)
        if abs(widthRatio - 0.5) < tolerance && abs(heightRatio - 1.0) < tolerance &&
           abs(xRatio - 0.5) < tolerance {
            return .rightHalf
        }
        
        // Check top half (~100% width, ~50% height, at top)
        if abs(widthRatio - 1.0) < tolerance && abs(heightRatio - 0.5) < tolerance &&
           abs(yRatio) < tolerance {
            return .topHalf
        }
        
        // Check bottom half (~100% width, ~50% height, at bottom)
        if abs(widthRatio - 1.0) < tolerance && abs(heightRatio - 0.5) < tolerance &&
           abs(yRatio - 0.5) < tolerance {
            return .bottomHalf
        }
        
        // Check top left quarter (~50% width, ~50% height, at top-left)
        if abs(widthRatio - 0.5) < tolerance && abs(heightRatio - 0.5) < tolerance &&
           abs(xRatio) < tolerance && abs(yRatio) < tolerance {
            return .topLeftQuarter
        }
        
        // Check top right quarter (~50% width, ~50% height, at top-right)
        if abs(widthRatio - 0.5) < tolerance && abs(heightRatio - 0.5) < tolerance &&
           abs(xRatio - 0.5) < tolerance && abs(yRatio) < tolerance {
            return .topRightQuarter
        }
        
        // Check bottom left quarter (~50% width, ~50% height, at bottom-left)
        if abs(widthRatio - 0.5) < tolerance && abs(heightRatio - 0.5) < tolerance &&
           abs(xRatio) < tolerance && abs(yRatio - 0.5) < tolerance {
            return .bottomLeftQuarter
        }
        
        // Check bottom right quarter (~50% width, ~50% height, at bottom-right)
        if abs(widthRatio - 0.5) < tolerance && abs(heightRatio - 0.5) < tolerance &&
           abs(xRatio - 0.5) < tolerance && abs(yRatio - 0.5) < tolerance {
            return .bottomRightQuarter
        }
        
        return nil
    }
}
