import Foundation
import AppKit

/// Service that orchestrates window snapping operations
public final class WindowSnapperService {
    
    private let accessibility: WindowAccessibilityServiceProtocol
    
    /// Whether to enable screen traversal when repeatedly applying edge actions
    public var traversalEnabled: Bool = true
    
    /// Cached dock offsets per screen (keyed by screen frame description)
    private var cachedDockOffsets: [String: CGFloat] = [:]
    
    public init(accessibility: WindowAccessibilityServiceProtocol = WindowAccessibilityService()) {
        self.accessibility = accessibility
    }
    
    /// Execute a window action on the frontmost window
    /// - Parameter action: The window action to perform
    /// - Throws: WindowAccessibilityError if operation fails
    public func execute(_ action: WindowAction) throws {
        // Handle multi-display actions separately
        if action == .nextDisplay || action == .previousDisplay {
            try executeDisplayMove(action)
            return
        }
        
        // Get frontmost window
        guard let windowElement = try accessibility.getFrontmostWindowElement() else {
            throw WindowAccessibilityError.noFrontmostWindow
        }
        
        // Get current frame
        let currentFrame = try accessibility.getWindowFrame(windowElement)
        
        // Determine owning screen
        let owningScreen = ScreenResolver.owningScreen(for: currentFrame)
        var visibleFrame = owningScreen.visibleFrame
        
        print("🔍 Screen Debug:")
        print("  screen.frame: \(owningScreen.frame)")
        print("  screen.visibleFrame: \(owningScreen.visibleFrame)")
        print("  currentFrame: \(currentFrame)")
        
        // IMPORTANT: visibleFrame may not reflect actual usable area due to dock
        // We detect dock offset when window is near the bottom of the screen,
        // then cache it for future use on this screen.
        var adjustedVisibleFrame = visibleFrame
        let screenKey = "\(owningScreen.frame)"
        
        let isFullWidth = abs(currentFrame.width - visibleFrame.width) < 10.0
        let yOffsetFromBottom = currentFrame.origin.y - visibleFrame.origin.y
        let isNearBottom = yOffsetFromBottom > 0 && yOffsetFromBottom < 100
        
        // Try to detect and cache dock offset when window is near bottom
        if isFullWidth && isNearBottom {
            cachedDockOffsets[screenKey] = yOffsetFromBottom
            print("🔍 Dock offset detected and cached: \(yOffsetFromBottom)px")
        }
        
        // Apply cached dock offset if we have one for this screen
        if let dockOffset = cachedDockOffsets[screenKey], dockOffset > 0 {
            // The dock takes up space at the bottom, but the USABLE height stays the same
            // We just need to shift the y origin up by the dock offset
            // Height stays the same as visibleFrame.height
            adjustedVisibleFrame = CGRect(
                x: visibleFrame.origin.x,
                y: visibleFrame.origin.y + dockOffset,  // Start above dock
                width: visibleFrame.width,
                height: visibleFrame.height  // Height stays the same!
            )
            print("🔍 Using cached dock offset: \(dockOffset)px")
            print("🔍 Adjusted visibleFrame: \(adjustedVisibleFrame)")
        }
        
        // Check if we're at an edge and should traverse
        var targetFrame: CGRect
        
        if traversalEnabled {
            targetFrame = try calculateFrameWithTraversal(
                action: action,
                currentFrame: currentFrame,
                owningScreen: owningScreen,
                adjustedVisibleFrame: adjustedVisibleFrame
            )
        } else {
            targetFrame = WindowGeometry.targetFrame(
                for: action,
                currentFrame: currentFrame,
                visibleFrame: adjustedVisibleFrame
            )
        }
        
        // Apply the new frame
        try accessibility.setWindowFrame(windowElement, frame: targetFrame)
    }
    
    /// Calculate target frame with traversal logic
    private func calculateFrameWithTraversal(
        action: WindowAction,
        currentFrame: CGRect,
        owningScreen: NSScreen,
        adjustedVisibleFrame: CGRect
    ) throws -> CGRect {
        // Check if window is currently at a snap position
        let currentPosition = WindowGeometry.currentSnapPosition(
            frame: currentFrame,
            visibleFrame: adjustedVisibleFrame
        )
        
        // Determine if we should traverse to another screen
        let shouldTraverse = shouldTraverseScreen(
            currentPosition: currentPosition,
            requestedAction: action
        )
        
        if shouldTraverse, let nextScreen = getNextScreenForTraversal(
            from: owningScreen,
            action: action
        ) {
            // Move to the opposite edge of the next screen
            let oppositeAction = getOppositeAction(for: action)
            return WindowGeometry.targetFrame(
                for: oppositeAction,
                currentFrame: currentFrame,
                visibleFrame: nextScreen.visibleFrame
            )
        }
        
        // No traversal, just apply the action normally
        return WindowGeometry.targetFrame(
            for: action,
            currentFrame: currentFrame,
            visibleFrame: adjustedVisibleFrame
        )
    }
    
    /// Determine if we should traverse to another screen
    private func shouldTraverseScreen(
        currentPosition: WindowAction?,
        requestedAction: WindowAction
    ) -> Bool {
        guard let current = currentPosition else { return false }
        
        // Only traverse if we're already at the edge and requesting the same edge again
        switch (current, requestedAction) {
        case (.leftHalf, .leftHalf),
             (.rightHalf, .rightHalf):
            return NSScreen.screens.count > 1
        default:
            return false
        }
    }
    
    /// Get the next screen for traversal
    private func getNextScreenForTraversal(
        from screen: NSScreen,
        action: WindowAction
    ) -> NSScreen? {
        let direction: ScreenResolver.TraversalDirection
        
        switch action {
        case .leftHalf:
            direction = .left
        case .rightHalf:
            direction = .right
        default:
            return nil
        }
        
        return ScreenResolver.nextScreen(from: screen, direction: direction)
    }
    
    /// Get the opposite action for traversal (left → right, right → left)
    private func getOppositeAction(for action: WindowAction) -> WindowAction {
        switch action {
        case .leftHalf: return .rightHalf
        case .rightHalf: return .leftHalf
        default: return action
        }
    }
    
    /// Execute display move actions
    private func executeDisplayMove(_ action: WindowAction) throws {
        guard let windowElement = try accessibility.getFrontmostWindowElement() else {
            throw WindowAccessibilityError.noFrontmostWindow
        }
        
        let currentFrame = try accessibility.getWindowFrame(windowElement)
        let currentScreen = ScreenResolver.owningScreen(for: currentFrame)
        
        // Detect arrangement orientation and choose appropriate direction
        let orientation = ScreenResolver.arrangementOrientation()
        let direction: ScreenResolver.TraversalDirection
        
        switch (action, orientation) {
        case (.nextDisplay, .horizontal):
            direction = .right
        case (.nextDisplay, .vertical):
            direction = .down
        case (.previousDisplay, .horizontal):
            direction = .left
        case (.previousDisplay, .vertical):
            direction = .up
        default:
            direction = .right
        }
        
        print("🔍 Display move: orientation=\(orientation), direction=\(direction)")
        
        guard let nextScreen = ScreenResolver.nextScreen(from: currentScreen, direction: direction) else {
            // Only one screen, do nothing
            return
        }
        
        // Move window to same relative position on next screen
        let relativeX = (currentFrame.origin.x - currentScreen.visibleFrame.origin.x) / currentScreen.visibleFrame.width
        let relativeY = (currentFrame.origin.y - currentScreen.visibleFrame.origin.y) / currentScreen.visibleFrame.height
        let relativeWidth = currentFrame.width / currentScreen.visibleFrame.width
        let relativeHeight = currentFrame.height / currentScreen.visibleFrame.height
        
        print("🔍 Display Move Debug:")
        print("  Current screen: \(currentScreen.visibleFrame)")
        print("  Current frame: \(currentFrame)")
        print("  Relative position: x=\(relativeX), y=\(relativeY)")
        print("  Relative size: w=\(relativeWidth), h=\(relativeHeight)")
        print("  Next screen: \(nextScreen.visibleFrame)")
        
        let newFrame = CGRect(
            x: nextScreen.visibleFrame.origin.x + (nextScreen.visibleFrame.width * relativeX),
            y: nextScreen.visibleFrame.origin.y + (nextScreen.visibleFrame.height * relativeY),
            width: nextScreen.visibleFrame.width * relativeWidth,
            height: nextScreen.visibleFrame.height * relativeHeight
        )
        
        print("  New frame: \(newFrame)")
        print("  Expected width: \(nextScreen.visibleFrame.width) * \(relativeWidth) = \(nextScreen.visibleFrame.width * relativeWidth)")
        
        try accessibility.setWindowFrame(windowElement, frame: newFrame)
    }
}
