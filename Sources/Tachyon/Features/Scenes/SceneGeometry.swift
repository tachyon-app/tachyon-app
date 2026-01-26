import Foundation
import AppKit

/// Pure geometry calculations for scene window proportional coordinates
public struct SceneGeometry {
    
    // MARK: - Proportional Coordinate Conversion
    
    /// Convert absolute frame to proportional coordinates relative to visibleFrame
    /// - Parameters:
    ///   - frame: The absolute window frame in screen coordinates
    ///   - visibleFrame: The screen's visible frame (excluding menu bar and dock)
    /// - Returns: Tuple of (xPercent, yPercent, widthPercent, heightPercent) in range 0.0-1.0
    public static func toProportional(
        frame: CGRect,
        visibleFrame: CGRect
    ) -> (xPct: CGFloat, yPct: CGFloat, wPct: CGFloat, hPct: CGFloat) {
        guard visibleFrame.width > 0 && visibleFrame.height > 0 else {
            return (0, 0, 1, 1)
        }
        
        // Calculate relative position within the visible frame
        let xPct = (frame.origin.x - visibleFrame.origin.x) / visibleFrame.width
        let yPct = (frame.origin.y - visibleFrame.origin.y) / visibleFrame.height
        let wPct = frame.width / visibleFrame.width
        let hPct = frame.height / visibleFrame.height
        
        return (
            xPct: clamp(xPct, min: 0, max: 1),
            yPct: clamp(yPct, min: 0, max: 1),
            wPct: clamp(wPct, min: 0, max: 1),
            hPct: clamp(hPct, min: 0, max: 1)
        )
    }
    
    /// Convert proportional coordinates back to absolute frame
    /// - Parameters:
    ///   - xPct: X position as percentage of visibleFrame (0.0-1.0)
    ///   - yPct: Y position as percentage of visibleFrame (0.0-1.0)
    ///   - wPct: Width as percentage of visibleFrame (0.0-1.0)
    ///   - hPct: Height as percentage of visibleFrame (0.0-1.0)
    ///   - visibleFrame: The target screen's visible frame
    /// - Returns: Absolute CGRect in screen coordinates
    public static func toAbsolute(
        xPct: CGFloat,
        yPct: CGFloat,
        wPct: CGFloat,
        hPct: CGFloat,
        visibleFrame: CGRect
    ) -> CGRect {
        let x = visibleFrame.origin.x + (xPct * visibleFrame.width)
        let y = visibleFrame.origin.y + (yPct * visibleFrame.height)
        let width = wPct * visibleFrame.width
        let height = hPct * visibleFrame.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    /// Convert SceneWindow proportional coordinates to absolute frame
    public static func toAbsoluteFrame(
        window: SceneWindow,
        visibleFrame: CGRect
    ) -> CGRect {
        return toAbsolute(
            xPct: CGFloat(window.xPercent),
            yPct: CGFloat(window.yPercent),
            wPct: CGFloat(window.widthPercent),
            hPct: CGFloat(window.heightPercent),
            visibleFrame: visibleFrame
        )
    }
    
    // MARK: - Display Helpers
    
    /// Get the screen that contains the majority of the given frame
    public static func screenContaining(frame: CGRect) -> NSScreen? {
        var maxOverlap: CGFloat = 0
        var bestScreen: NSScreen?
        
        for screen in NSScreen.screens {
            let intersection = frame.intersection(screen.frame)
            if !intersection.isNull {
                let overlapArea = intersection.width * intersection.height
                if overlapArea > maxOverlap {
                    maxOverlap = overlapArea
                    bestScreen = screen
                }
            }
        }
        
        return bestScreen
    }
    
    /// Get the display index for a given screen
    public static func displayIndex(for screen: NSScreen) -> Int {
        return NSScreen.screens.firstIndex(of: screen) ?? 0
    }
    
    /// Get the screen for a given display index
    public static func screen(forIndex index: Int) -> NSScreen? {
        guard index >= 0 && index < NSScreen.screens.count else {
            return nil
        }
        return NSScreen.screens[index]
    }
    
    /// Get display info for all connected screens
    public static func getAllDisplays() -> [(index: Int, name: String, visibleFrame: CGRect)] {
        return NSScreen.screens.enumerated().map { index, screen in
            let name = screen.localizedName
            return (index: index, name: name, visibleFrame: screen.visibleFrame)
        }
    }
    
    // MARK: - Helpers
    
    private static func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        return Swift.min(Swift.max(value, min), max)
    }
}
