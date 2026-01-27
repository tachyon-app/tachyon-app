import Foundation
import AppKit

/// Service that orchestrates window snapping operations
public final class WindowSnapperService {
    
    private let accessibility: WindowAccessibilityServiceProtocol
    
    /// Whether to enable screen traversal when repeatedly applying edge actions
    public var traversalEnabled: Bool = true
    
    /// Cached dock offsets per screen (keyed by screen frame description)
    private var cachedDockOffsets: [String: CGFloat] = [:]
    
    // MARK: - Coordinate Conversion Helpers
    
    /// Convert Cocoa frame (bottom-left origin) to Accessibility frame (top-left origin)
    private func toAXFrame(from cocoaFrame: CGRect) -> CGRect {
        // Accessibility APIs use a flipped coordinate system where (0,0) is top-left of the PRIMARY screen
        // Cocoa uses (0,0) as bottom-left of the PRIMARY screen
        // Formula: AX_Y = PrimaryScreenHeight - (Cocoa_Y + Height)
        
        // Find primary screen (the one at 0,0 in Cocoa coords)
        let primaryHeight = NSScreen.screens.first { $0.frame.origin == .zero }?.frame.height 
            ?? NSScreen.main?.frame.height 
            ?? 0
            
        var axFrame = cocoaFrame
        axFrame.origin.y = primaryHeight - (cocoaFrame.origin.y + cocoaFrame.height)
        
        // DEBUG LOGGING (Can be removed later)
        // print("🔍 DEBUG: toAXFrame: Cocoa \(cocoaFrame) -> AX \(axFrame) (Primary Height: \(primaryHeight))")
        
        return axFrame
    }
    
    /// Convert Accessibility frame (top-left origin) to Cocoa frame (bottom-left origin)
    private func toCocoaFrame(from axFrame: CGRect) -> CGRect {
        // The conversion is symmetric
        return toAXFrame(from: axFrame)
    }
    
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
        
        // Get current frame (AX coordinates)
        let currentFrame = try accessibility.getWindowFrame(windowElement)
        
        // Convert to Cocoa coordinates for accurate screen detection
        let currentCocoaFrame = toCocoaFrame(from: currentFrame)
        
        // Determine owning screen
        let owningScreen = ScreenResolver.owningScreen(for: currentCocoaFrame)
        let visibleFrame = owningScreen.visibleFrame // Cocoa coordinates
        
        // Convert visible frame to AX coordinates for geometry calculations
        // WindowGeometry assumes Y-down / top-left origin logic (matching AX)
        var visibleFrameAX = toAXFrame(from: visibleFrame)
        
        // IMPORTANT: visibleFrame may not reflect actual usable area due to dock
        // We detect dock offset when window is near the bottom of the screen,
        // then cache it for future use on this screen.
        var adjustedVisibleFrameAX = visibleFrameAX
        let screenKey = "\(owningScreen.frame)"
        
        // Use AX frames for relative check
        let isFullWidth = abs(currentFrame.width - visibleFrameAX.width) < 10.0
        // In AX (Y-down), bottom is Y + Height. Dock is at bottom.
        // If window is near bottom of screen...
        let screenBottomAX = visibleFrameAX.origin.y + visibleFrameAX.height
        let windowBottomAX = currentFrame.origin.y + currentFrame.height
        let yOffsetFromBottom = screenBottomAX - windowBottomAX
        let isNearBottom = yOffsetFromBottom > 0 && yOffsetFromBottom < 100
        
        // Try to detect and cache dock offset when window is near bottom
        if isFullWidth && isNearBottom {
            cachedDockOffsets[screenKey] = yOffsetFromBottom
        }
        
        // Apply cached dock offset if we have one for this screen
        if let dockOffset = cachedDockOffsets[screenKey], dockOffset > 0 {
            // In AX coordinates (Y-down), reducing the height effectively lifts the bottom
            // because origin is at top. We want to exclude the dock area at the bottom.
            adjustedVisibleFrameAX = CGRect(
                x: visibleFrameAX.origin.x,
                y: visibleFrameAX.origin.y,
                width: visibleFrameAX.width,
                height: visibleFrameAX.height - dockOffset // Reduce height to avoid dock
            )
        }
        
        // Handle cycle actions
        var targetFrame: CGRect
        
        switch action {
        case .cycleThirds:
            let currentPos = WindowGeometry.currentThirdPosition(frame: currentFrame, visibleFrame: adjustedVisibleFrameAX)
            let nextPos = currentPos.map { ($0 % 3) + 1 } ?? 1  // Cycle or start at first
            targetFrame = WindowGeometry.thirdFrame(position: nextPos, visibleFrame: adjustedVisibleFrameAX)
            
        case .cycleTwoThirds:
            let currentPos = WindowGeometry.currentTwoThirdsPosition(frame: currentFrame, visibleFrame: adjustedVisibleFrameAX)
            let nextPos = currentPos.map { ($0 % 2) + 1 } ?? 1  // Cycle or start at first
            targetFrame = WindowGeometry.twoThirdsFrame(position: nextPos, visibleFrame: adjustedVisibleFrameAX)
            
        case .cycleQuarters:
            let currentPos = WindowGeometry.currentQuarterPosition(frame: currentFrame, visibleFrame: adjustedVisibleFrameAX)
            let nextPos = currentPos.map { ($0 % 4) + 1 } ?? 1  // Cycle or start at first
            targetFrame = WindowGeometry.quarterFrame(position: nextPos, visibleFrame: adjustedVisibleFrameAX)
            
        case .cycleThreeQuarters:
            let currentPos = WindowGeometry.currentThreeQuartersPosition(frame: currentFrame, visibleFrame: adjustedVisibleFrameAX)
            let nextPos = currentPos.map { ($0 % 2) + 1 } ?? 1  // Cycle or start at first
            targetFrame = WindowGeometry.threeQuartersFrame(position: nextPos, visibleFrame: adjustedVisibleFrameAX)
            
        default:
            // Check if we're at an edge and should traverse
            if traversalEnabled {
                targetFrame = try calculateFrameWithTraversal(
                    action: action,
                    currentFrame: currentFrame,
                    owningScreen: owningScreen,
                    adjustedVisibleFrame: adjustedVisibleFrameAX
                )
            } else {
                targetFrame = WindowGeometry.targetFrame(
                    for: action,
                    currentFrame: currentFrame,
                    visibleFrame: adjustedVisibleFrameAX
                )
            }
        }
        
        print("🔍 DEBUG: Execution Target Frame: \(targetFrame)")
        print("🔍 DEBUG: Current Adjusted Visible Frame from Owning Screen: \(adjustedVisibleFrameAX)")
        
        // Apply the new frame (first pass - macOS may enforce minimum size constraints)
        try accessibility.setWindowFrame(windowElement, frame: targetFrame)
        
        // Second pass: check if window overflows screen bounds due to minimum size constraints
        // (apps like Finder have minimum widths that may cause overflow)
        let actualFrame = try accessibility.getWindowFrame(windowElement)
        
        // IMPORTANT: We must re-calculate which screen the window is INTEEDED to be on (Target).
        // If we relying on actualFrame, animation lag might report the OLD screen, causing
        // false positive overflow detection against the wrong screen bounds.
        let targetCocoaFrame = toCocoaFrame(from: targetFrame)
        let intendedOwningScreen = ScreenResolver.owningScreen(for: targetCocoaFrame)
        let intendedVisibleFrame = intendedOwningScreen.visibleFrame
        let intendedVisibleFrameAX = toAXFrame(from: intendedVisibleFrame)
        
        // Use the INTENDED screen's bounds for the overflow check
        let screenRight = intendedVisibleFrameAX.origin.x + intendedVisibleFrameAX.width
        let actualRight = actualFrame.origin.x + actualFrame.width
        
        // DEBUG: Print details
        // print("🔍 DEBUG: Overflow Check against screen: \(currentVisibleFrameAX)")
        
        if actualRight > screenRight + 5 {  // 5px tolerance
            // Window extends past right edge, shift it left
            let overflow = actualRight - screenRight
            var correctedFrame = actualFrame
            correctedFrame.origin.x -= overflow
            
            // Ensure we don't go past left edge of the INTENDED screen
            if correctedFrame.origin.x < intendedVisibleFrameAX.origin.x {
                correctedFrame.origin.x = intendedVisibleFrameAX.origin.x
            }
            
            try accessibility.setWindowFrame(windowElement, frame: correctedFrame)
        }

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
            
            // CRITICAL: Convert next screen's visible frame to AX coordinates
            // WindowGeometry expects Y-down / top-left origin logic
            let nextScreenVisibleAX = toAXFrame(from: nextScreen.visibleFrame)
            
            return WindowGeometry.targetFrame(
                for: oppositeAction,
                currentFrame: currentFrame,
                visibleFrame: nextScreenVisibleAX
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
        
        // Get current frame (AX coords)
        let currentFrame = try accessibility.getWindowFrame(windowElement)
        // Convert to Cocoa for screen detection
        let currentCocoaFrame = toCocoaFrame(from: currentFrame)
        let currentScreen = ScreenResolver.owningScreen(for: currentCocoaFrame)
        
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
        
        guard let nextScreen = ScreenResolver.nextScreen(from: currentScreen, direction: direction) else {
            // Only one screen, do nothing
            return
        }
        
        // Check if window is at a snap position - if so, re-apply that snap on destination
        // Use AX visible frames for position checking
        let currentVisibleAX = toAXFrame(from: currentScreen.visibleFrame)
        let nextVisibleAX = toAXFrame(from: nextScreen.visibleFrame)
        
        if let snapPosition = WindowGeometry.currentSnapPosition(frame: currentFrame, visibleFrame: currentVisibleAX) {
            // Re-apply the same snap action on the destination screen
            let newFrame = WindowGeometry.targetFrame(
                for: snapPosition,
                currentFrame: currentFrame,
                visibleFrame: nextVisibleAX
            )
            try accessibility.setWindowFrame(windowElement, frame: newFrame)
            return
        }
        
        // Check for thirds position
        if let thirdPos = WindowGeometry.currentThirdPosition(frame: currentFrame, visibleFrame: currentVisibleAX) {
            let newFrame = WindowGeometry.thirdFrame(position: thirdPos, visibleFrame: nextVisibleAX)
            try accessibility.setWindowFrame(windowElement, frame: newFrame)
            return
        }
        
        // Check for two-thirds position
        if let twoThirdsPos = WindowGeometry.currentTwoThirdsPosition(frame: currentFrame, visibleFrame: currentVisibleAX) {
            let newFrame = WindowGeometry.twoThirdsFrame(position: twoThirdsPos, visibleFrame: nextVisibleAX)
            try accessibility.setWindowFrame(windowElement, frame: newFrame)
            return
        }
        
        // Check for quarters position
        if let quarterPos = WindowGeometry.currentQuarterPosition(frame: currentFrame, visibleFrame: currentVisibleAX) {
            let newFrame = WindowGeometry.quarterFrame(position: quarterPos, visibleFrame: nextVisibleAX)
            try accessibility.setWindowFrame(windowElement, frame: newFrame)
            return
        }
        
        // Check for three-quarters position
        if let threeQuartersPos = WindowGeometry.currentThreeQuartersPosition(frame: currentFrame, visibleFrame: currentVisibleAX) {
            let newFrame = WindowGeometry.threeQuartersFrame(position: threeQuartersPos, visibleFrame: nextVisibleAX)
            try accessibility.setWindowFrame(windowElement, frame: newFrame)
            return
        }
        
        // Not at a snap position - use relative proportions as fallback
        // Use AX coords for relative calculation
        let relativeX = (currentFrame.origin.x - currentVisibleAX.origin.x) / currentVisibleAX.width
        let relativeY = (currentFrame.origin.y - currentVisibleAX.origin.y) / currentVisibleAX.height
        let relativeWidth = currentFrame.width / currentVisibleAX.width
        let relativeHeight = currentFrame.height / currentVisibleAX.height
        
        let newFrame = CGRect(
            x: nextVisibleAX.origin.x + (nextVisibleAX.width * relativeX),
            y: nextVisibleAX.origin.y + (nextVisibleAX.height * relativeY),
            width: nextVisibleAX.width * relativeWidth,
            height: nextVisibleAX.height * relativeHeight
        )
        
        try accessibility.setWindowFrame(windowElement, frame: newFrame)
    }
}
