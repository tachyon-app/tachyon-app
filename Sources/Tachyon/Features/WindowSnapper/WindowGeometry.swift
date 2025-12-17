import Foundation
import AppKit

/// Pure geometry calculations for window snapping
public struct WindowGeometry {
    
    /// Calculate target frame for a window action
    /// - Parameters:
    ///   - action: The window action to perform
    ///   - currentFrame: Current window frame
    ///   - visibleFrame: Visible screen frame (accounts for menu bar/dock)
    /// - Returns: Target frame for the window
    public static func targetFrame(
        for action: WindowAction,
        currentFrame: CGRect,
        visibleFrame: CGRect
    ) -> CGRect {
        let width = visibleFrame.width
        let height = visibleFrame.height
        let x = visibleFrame.origin.x
        let y = visibleFrame.origin.y
        
        // Determine if screen is portrait or landscape
        let isPortrait = height > width
        
        switch action {
        // MARK: - Halves
        case .leftHalf:
            return CGRect(x: x, y: y, width: width / 2, height: height)
            
        case .rightHalf:
            return CGRect(x: x + width / 2, y: y, width: width / 2, height: height)
            
        case .topHalf:
            // User confirmed: top button should go to BOTTOM (lower Y)
            return CGRect(x: x, y: y, width: width, height: height / 2)
            
        case .bottomHalf:
            // User confirmed: bottom button should go to TOP (higher Y)
            return CGRect(x: x, y: y + height / 2, width: width, height: height / 2)
            
        // MARK: - Quarters
        case .topLeftQuarter:
            // Top left button goes to bottom left (lower Y, lower X)
            return CGRect(x: x, y: y, width: width / 2, height: height / 2)
            
        case .topRightQuarter:
            // Top right button goes to bottom right (lower Y, higher X)
            return CGRect(x: x + width / 2, y: y, width: width / 2, height: height / 2)
            
        case .bottomLeftQuarter:
            // Bottom left button goes to top left (higher Y, lower X)
            return CGRect(x: x, y: y + height / 2, width: width / 2, height: height / 2)
            
        case .bottomRightQuarter:
            // Bottom right button goes to top right (higher Y, higher X)
            return CGRect(x: x + width / 2, y: y + height / 2, width: width / 2, height: height / 2)
            
        case .firstThreeQuarters:
            return CGRect(x: x, y: y, width: width * 3 / 4, height: height)
            
        case .lastThreeQuarters:
            return CGRect(x: x + width / 4, y: y, width: width * 3 / 4, height: height)
            
        // MARK: - Thirds
        case .firstThird:
            if isPortrait {
                // Portrait: thirds are vertical (top, middle, bottom)
                return CGRect(x: x, y: y + height * 2 / 3, width: width, height: height / 3)
            } else {
                // Landscape: thirds are horizontal (left, center, right)
                return CGRect(x: x, y: y, width: width / 3, height: height)
            }
            
        case .centerThird:
            if isPortrait {
                return CGRect(x: x, y: y + height / 3, width: width, height: height / 3)
            } else {
                return CGRect(x: x + width / 3, y: y, width: width / 3, height: height)
            }
            
        case .lastThird:
            if isPortrait {
                return CGRect(x: x, y: y, width: width, height: height / 3)
            } else {
                return CGRect(x: x + width * 2 / 3, y: y, width: width / 3, height: height)
            }
            
        case .firstTwoThirds:
            if isPortrait {
                return CGRect(x: x, y: y + height / 3, width: width, height: height * 2 / 3)
            } else {
                return CGRect(x: x, y: y, width: width * 2 / 3, height: height)
            }
            
        case .lastTwoThirds:
            if isPortrait {
                return CGRect(x: x, y: y, width: width, height: height * 2 / 3)
            } else {
                return CGRect(x: x + width / 3, y: y, width: width * 2 / 3, height: height)
            }
            
        // MARK: - Maximize & Center
        case .maximize:
            return visibleFrame
            
        case .fullscreen:
            // Fullscreen is handled differently (native macOS API)
            return visibleFrame
            
        case .center:
            // Center without resizing
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
            // These are handled by WindowSnapperService with screen traversal
            return currentFrame
        }
    }
    
    /// Determine if a window is currently at a snap position
    /// - Parameters:
    ///   - frame: Current window frame
    ///   - visibleFrame: Visible screen frame
    /// - Returns: The snap position if detected, nil otherwise
    public static func currentSnapPosition(
        frame: CGRect,
        visibleFrame: CGRect
    ) -> WindowAction? {
        let tolerance: CGFloat = 5.0 // Allow 5px tolerance for floating point
        
        func isClose(_ a: CGFloat, _ b: CGFloat) -> Bool {
            abs(a - b) < tolerance
        }
        
        func framesMatch(_ a: CGRect, _ b: CGRect) -> Bool {
            isClose(a.origin.x, b.origin.x) &&
            isClose(a.origin.y, b.origin.y) &&
            isClose(a.width, b.width) &&
            isClose(a.height, b.height)
        }
        
        // Check all snap positions
        let positions: [WindowAction] = [
            .maximize,
            .leftHalf, .rightHalf, .topHalf, .bottomHalf,
            .topLeftQuarter, .topRightQuarter, .bottomLeftQuarter, .bottomRightQuarter,
            .firstThreeQuarters, .lastThreeQuarters,
            .firstThird, .centerThird, .lastThird,
            .firstTwoThirds, .lastTwoThirds
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
