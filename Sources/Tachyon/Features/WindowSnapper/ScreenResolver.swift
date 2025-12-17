import Foundation
import AppKit

/// Resolves which screen owns a window and handles multi-monitor traversal
public struct ScreenResolver {
    
    public enum TraversalDirection {
        case left, right, up, down
    }
    
    /// Determine which screen owns a window based on center point
    /// - Parameters:
    ///   - frame: Window frame
    ///   - screens: Available screens (defaults to NSScreen.screens)
    /// - Returns: The owning screen
    public static func owningScreen(
        for frame: CGRect,
        screens: [NSScreen]? = nil
    ) -> NSScreen {
        let availableScreens = screens ?? NSScreen.screens
        guard !availableScreens.isEmpty else {
            return NSScreen.main ?? NSScreen.screens.first!
        }
        
        let centerPoint = CGPoint(x: frame.midX, y: frame.midY)
        
        // Find screen containing center point
        if let screenWithCenter = availableScreens.first(where: { $0.frame.contains(centerPoint) }) {
            return screenWithCenter
        }
        
        // Fallback: use screen with largest intersection area
        var maxIntersection: CGFloat = 0
        var bestScreen = availableScreens[0]
        
        for screen in availableScreens {
            let intersection = frame.intersection(screen.frame)
            let area = intersection.width * intersection.height
            
            if area > maxIntersection {
                maxIntersection = area
                bestScreen = screen
            }
        }
        
        return bestScreen
    }
    
    /// Overload for mock screens (testing)
    public static func owningScreen(
        for frame: CGRect,
        screens: [MockScreen]
    ) -> MockScreen {
        guard !screens.isEmpty else {
            fatalError("No screens available")
        }
        
        let centerPoint = CGPoint(x: frame.midX, y: frame.midY)
        
        // Find screen containing center point
        if let screenWithCenter = screens.first(where: { $0.frame.contains(centerPoint) }) {
            return screenWithCenter
        }
        
        // Fallback: use screen with largest intersection area
        var maxIntersection: CGFloat = 0
        var bestScreen = screens[0]
        
        for screen in screens {
            let intersection = frame.intersection(screen.frame)
            let area = intersection.width * intersection.height
            
            if area > maxIntersection {
                maxIntersection = area
                bestScreen = screen
            }
        }
        
        return bestScreen
    }
    
    /// Get screens sorted by position (left-to-right, then top-to-bottom)
    /// - Parameter screens: Available screens (defaults to NSScreen.screens)
    /// - Returns: Ordered array of screens
    public static func orderedScreens(screens: [NSScreen]? = nil) -> [NSScreen] {
        let availableScreens = screens ?? NSScreen.screens
        
        // Determine if arrangement is primarily horizontal or vertical
        let minX = availableScreens.map { $0.frame.minX }.min() ?? 0
        let maxX = availableScreens.map { $0.frame.maxX }.max() ?? 0
        let minY = availableScreens.map { $0.frame.minY }.min() ?? 0
        let maxY = availableScreens.map { $0.frame.maxY }.max() ?? 0
        
        let horizontalSpan = maxX - minX
        let verticalSpan = maxY - minY
        
        if horizontalSpan >= verticalSpan {
            // Horizontal arrangement - sort left to right
            return availableScreens.sorted { $0.frame.minX < $1.frame.minX }
        } else {
            // Vertical arrangement - sort top to bottom (higher y first in macOS)
            return availableScreens.sorted { $0.frame.maxY > $1.frame.maxY }
        }
    }
    
    /// Overload for mock screens
    public static func orderedScreens(screens: [MockScreen]) -> [MockScreen] {
        let minX = screens.map { $0.frame.minX }.min() ?? 0
        let maxX = screens.map { $0.frame.maxX }.max() ?? 0
        let minY = screens.map { $0.frame.minY }.min() ?? 0
        let maxY = screens.map { $0.frame.maxY }.max() ?? 0
        
        let horizontalSpan = maxX - minX
        let verticalSpan = maxY - minY
        
        if horizontalSpan >= verticalSpan {
            return screens.sorted { $0.frame.minX < $1.frame.minX }
        } else {
            return screens.sorted { $0.frame.maxY > $1.frame.maxY }
        }
    }
    
    /// Calculate next screen for traversal
    /// - Parameters:
    ///   - current: Current screen
    ///   - direction: Direction to traverse
    ///   - screens: Available screens (defaults to NSScreen.screens)
    /// - Returns: Next screen, or nil if single screen
    public static func nextScreen(
        from current: NSScreen,
        direction: TraversalDirection,
        screens: [NSScreen]? = nil
    ) -> NSScreen? {
        let availableScreens = screens ?? NSScreen.screens
        guard availableScreens.count > 1 else { return nil }
        
        let ordered = orderedScreens(screens: availableScreens)
        guard let currentIndex = ordered.firstIndex(where: { $0 == current }) else {
            return nil
        }
        
        switch direction {
        case .right, .down:
            let nextIndex = (currentIndex + 1) % ordered.count
            return ordered[nextIndex]
            
        case .left, .up:
            let prevIndex = (currentIndex - 1 + ordered.count) % ordered.count
            return ordered[prevIndex]
        }
    }
    
    /// Overload for mock screens
    public static func nextScreen(
        from current: MockScreen,
        direction: TraversalDirection,
        screens: [MockScreen]
    ) -> MockScreen? {
        guard screens.count > 1 else { return nil }
        
        let ordered = orderedScreens(screens: screens)
        guard let currentIndex = ordered.firstIndex(where: { $0.frame == current.frame }) else {
            return nil
        }
        
        switch direction {
        case .right, .down:
            let nextIndex = (currentIndex + 1) % ordered.count
            return ordered[nextIndex]
            
        case .left, .up:
            let prevIndex = (currentIndex - 1 + ordered.count) % ordered.count
            return ordered[prevIndex]
        }
    }
    
    /// Arrangement orientation for multi-monitor setups
    public enum ArrangementOrientation {
        case horizontal
        case vertical
    }
    
    /// Detect if monitors are arranged horizontally or vertically
    public static func arrangementOrientation(screens: [NSScreen]? = nil) -> ArrangementOrientation {
        let availableScreens = screens ?? NSScreen.screens
        guard availableScreens.count > 1 else { return .horizontal }
        
        let minX = availableScreens.map { $0.frame.minX }.min() ?? 0
        let maxX = availableScreens.map { $0.frame.maxX }.max() ?? 0
        let minY = availableScreens.map { $0.frame.minY }.min() ?? 0
        let maxY = availableScreens.map { $0.frame.maxY }.max() ?? 0
        
        let horizontalSpan = maxX - minX
        let verticalSpan = maxY - minY
        
        return horizontalSpan >= verticalSpan ? .horizontal : .vertical
    }
}

// Make MockScreen available for testing
public class MockScreen {
    public let frame: CGRect
    public let visibleFrame: CGRect
    
    public init(frame: CGRect, visibleFrame: CGRect? = nil) {
        self.frame = frame
        self.visibleFrame = visibleFrame ?? CGRect(
            x: frame.origin.x,
            y: frame.origin.y,
            width: frame.width,
            height: frame.height - 25
        )
    }
}
