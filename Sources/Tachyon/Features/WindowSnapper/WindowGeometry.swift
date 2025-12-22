import Foundation
import AppKit

/// Pure geometry calculations for window snapping
public struct WindowGeometry {
    
    // MARK: - Third Position Helpers
    
    /// Determine which third position the window is in (1=first, 2=center, 3=last) or nil
    public static func currentThirdPosition(frame: CGRect, visibleFrame: CGRect) -> Int? {
        let tolerance: CGFloat = 5.0
        let width = visibleFrame.width
        let x = visibleFrame.origin.x
        
        // Check if it's full height
        guard abs(frame.height - visibleFrame.height) < tolerance else { return nil }
        guard abs(frame.width - width / 3) < tolerance else { return nil }
        
        if abs(frame.origin.x - x) < tolerance { return 1 }  // First third
        if abs(frame.origin.x - (x + width / 3)) < tolerance { return 2 }  // Center third
        if abs(frame.origin.x - (x + width * 2 / 3)) < tolerance { return 3 }  // Last third
        
        return nil
    }
    
    /// Get target frame for nth third (1=first, 2=center, 3=last)
    public static func thirdFrame(position: Int, visibleFrame: CGRect) -> CGRect {
        let width = visibleFrame.width
        let x = visibleFrame.origin.x
        let y = visibleFrame.origin.y
        let height = visibleFrame.height
        
        switch position {
        case 1: return CGRect(x: x, y: y, width: width / 3, height: height)
        case 2: return CGRect(x: x + width / 3, y: y, width: width / 3, height: height)
        case 3: return CGRect(x: x + width * 2 / 3, y: y, width: width / 3, height: height)
        default: return CGRect(x: x, y: y, width: width / 3, height: height)
        }
    }
    
    // MARK: - Two-Thirds Position Helpers
    
    /// Determine which two-thirds position the window is in (1=first, 2=last) or nil
    public static func currentTwoThirdsPosition(frame: CGRect, visibleFrame: CGRect) -> Int? {
        let tolerance: CGFloat = 5.0
        let width = visibleFrame.width
        let x = visibleFrame.origin.x
        
        guard abs(frame.height - visibleFrame.height) < tolerance else { return nil }
        guard abs(frame.width - width * 2 / 3) < tolerance else { return nil }
        
        if abs(frame.origin.x - x) < tolerance { return 1 }  // First two thirds
        if abs(frame.origin.x - (x + width / 3)) < tolerance { return 2 }  // Last two thirds
        
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
    
    // MARK: - Quarter Position Helpers (clockwise: TL=1, TR=2, BR=3, BL=4)
    
    /// Determine which quarter position the window is in (1-4, vertical quarters) or nil
    public static func currentQuarterPosition(frame: CGRect, visibleFrame: CGRect) -> Int? {
        let tolerance: CGFloat = 25.0  // Increased tolerance for window manager adjustments
        let width = visibleFrame.width
        let x = visibleFrame.origin.x
        
        // Check if it's full height and 1/4 width
        guard abs(frame.height - visibleFrame.height) < tolerance else { return nil }
        guard abs(frame.width - width / 4) < tolerance else { return nil }
        
        if abs(frame.origin.x - x) < tolerance { return 1 }  // First quarter
        if abs(frame.origin.x - (x + width / 4)) < tolerance { return 2 }  // Second quarter
        if abs(frame.origin.x - (x + width / 2)) < tolerance { return 3 }  // Third quarter
        if abs(frame.origin.x - (x + width * 3 / 4)) < tolerance { return 4 }  // Fourth quarter
        
        return nil
    }
    
    /// Get target frame for nth quarter (1-4, vertical quarters)
    public static func quarterFrame(position: Int, visibleFrame: CGRect) -> CGRect {
        let width = visibleFrame.width
        let height = visibleFrame.height
        let x = visibleFrame.origin.x
        let y = visibleFrame.origin.y
        
        switch position {
        case 1: return CGRect(x: x, y: y, width: width / 4, height: height)  // First quarter
        case 2: return CGRect(x: x + width / 4, y: y, width: width / 4, height: height)  // Second quarter
        case 3: return CGRect(x: x + width / 2, y: y, width: width / 4, height: height)  // Third quarter
        case 4: return CGRect(x: x + width * 3 / 4, y: y, width: width / 4, height: height)  // Fourth quarter
        default: return CGRect(x: x, y: y, width: width / 4, height: height)
        }
    }
    
    // MARK: - Three-Quarters Position Helpers
    
    /// Determine which three-quarters position the window is in (1=first, 2=last) or nil
    public static func currentThreeQuartersPosition(frame: CGRect, visibleFrame: CGRect) -> Int? {
        let tolerance: CGFloat = 5.0
        let width = visibleFrame.width
        let x = visibleFrame.origin.x
        
        guard abs(frame.height - visibleFrame.height) < tolerance else { return nil }
        guard abs(frame.width - width * 3 / 4) < tolerance else { return nil }
        
        if abs(frame.origin.x - x) < tolerance { return 1 }  // First three quarters
        if abs(frame.origin.x - (x + width / 4)) < tolerance { return 2 }  // Last three quarters
        
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
    public static func currentSnapPosition(
        frame: CGRect,
        visibleFrame: CGRect
    ) -> WindowAction? {
        let tolerance: CGFloat = 5.0
        
        func isClose(_ a: CGFloat, _ b: CGFloat) -> Bool {
            abs(a - b) < tolerance
        }
        
        func framesMatch(_ a: CGRect, _ b: CGRect) -> Bool {
            isClose(a.origin.x, b.origin.x) &&
            isClose(a.origin.y, b.origin.y) &&
            isClose(a.width, b.width) &&
            isClose(a.height, b.height)
        }
        
        // Check basic positions
        let positions: [WindowAction] = [
            .maximize,
            .leftHalf, .rightHalf, .topHalf, .bottomHalf
        ]
        
        for position in positions {
            let targetFrame = self.targetFrame(
                for: position,
                currentFrame: frame,
                visibleFrame: visibleFrame
            )
            
            if framesMatch(frame, targetFrame) {
                return position
            }
        }
        
        return nil
    }
}
