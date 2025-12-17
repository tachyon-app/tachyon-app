import XCTest
@testable import TachyonCore
import AppKit

class WindowSnapperServiceTests: XCTestCase {
    
    var service: WindowSnapperService!
    var mockAccessibility: MockAccessibilityService!
    
    override func setUp() {
        super.setUp()
        mockAccessibility = MockAccessibilityService()
        service = WindowSnapperService(accessibility: mockAccessibility)
    }
    
    // MARK: - Basic Snapping Tests
    
    func testExecuteLeftHalf() throws {
        // Setup: window in center of screen
        mockAccessibility.currentFrame = CGRect(x: 500, y: 400, width: 800, height: 600)
        
        try service.execute(.leftHalf)
        
        // Should snap to left half
        guard let screen = NSScreen.main else {
            XCTFail("No main screen")
            return
        }
        
        XCTAssertEqual(mockAccessibility.setFrameCalled, true)
        XCTAssertEqual(mockAccessibility.lastSetFrame?.origin.x, screen.visibleFrame.origin.x)
        XCTAssertEqual(mockAccessibility.lastSetFrame?.width, screen.visibleFrame.width / 2)
    }
    
    func testExecuteRightHalf() throws {
        mockAccessibility.currentFrame = CGRect(x: 500, y: 400, width: 800, height: 600)
        
        try service.execute(.rightHalf)
        
        guard let screen = NSScreen.main else {
            XCTFail("No main screen")
            return
        }
        
        XCTAssertEqual(mockAccessibility.setFrameCalled, true)
        XCTAssertEqual(mockAccessibility.lastSetFrame?.origin.x, screen.visibleFrame.origin.x + screen.visibleFrame.width / 2)
        XCTAssertEqual(mockAccessibility.lastSetFrame?.width, screen.visibleFrame.width / 2)
    }
    
    func testExecuteMaximize() throws {
        mockAccessibility.currentFrame = CGRect(x: 500, y: 400, width: 800, height: 600)
        
        try service.execute(.maximize)
        
        guard let screen = NSScreen.main else {
            XCTFail("No main screen")
            return
        }
        
        XCTAssertEqual(mockAccessibility.setFrameCalled, true)
        XCTAssertEqual(mockAccessibility.lastSetFrame?.origin.x, screen.visibleFrame.origin.x)
        XCTAssertEqual(mockAccessibility.lastSetFrame?.origin.y, screen.visibleFrame.origin.y)
        XCTAssertEqual(mockAccessibility.lastSetFrame?.width, screen.visibleFrame.width)
        XCTAssertEqual(mockAccessibility.lastSetFrame?.height, screen.visibleFrame.height)
    }
    
    func testExecuteCenter() throws {
        mockAccessibility.currentFrame = CGRect(x: 100, y: 100, width: 800, height: 600)
        
        try service.execute(.center)
        
        guard let screen = NSScreen.main else {
            XCTFail("No main screen")
            return
        }
        
        XCTAssertEqual(mockAccessibility.setFrameCalled, true)
        
        // Should preserve size
        XCTAssertEqual(mockAccessibility.lastSetFrame?.width, 800)
        XCTAssertEqual(mockAccessibility.lastSetFrame?.height, 600)
        
        // Should be centered
        let expectedX = screen.visibleFrame.origin.x + (screen.visibleFrame.width - 800) / 2
        let expectedY = screen.visibleFrame.origin.y + (screen.visibleFrame.height - 600) / 2
        XCTAssertEqual(mockAccessibility.lastSetFrame?.origin.x, expectedX)
        XCTAssertEqual(mockAccessibility.lastSetFrame?.origin.y, expectedY)
    }
    
    // MARK: - Traversal Tests
    
    func testTraversalDisabled() throws {
        service.traversalEnabled = false
        
        guard let screen = NSScreen.main else {
            XCTFail("No main screen")
            return
        }
        
        // Window already at left half
        let leftHalfFrame = CGRect(
            x: screen.visibleFrame.origin.x,
            y: screen.visibleFrame.origin.y,
            width: screen.visibleFrame.width / 2,
            height: screen.visibleFrame.height
        )
        mockAccessibility.currentFrame = leftHalfFrame
        
        try service.execute(.leftHalf)
        
        // Should stay at left half (no traversal)
        XCTAssertEqual(mockAccessibility.lastSetFrame?.origin.x, screen.visibleFrame.origin.x)
        XCTAssertEqual(mockAccessibility.lastSetFrame?.width, screen.visibleFrame.width / 2)
    }
    
    func testTraversalEnabledSingleScreen() throws {
        service.traversalEnabled = true
        
        guard let screen = NSScreen.main else {
            XCTFail("No main screen")
            return
        }
        
        // With single screen, traversal shouldn't happen
        let leftHalfFrame = CGRect(
            x: screen.visibleFrame.origin.x,
            y: screen.visibleFrame.origin.y,
            width: screen.visibleFrame.width / 2,
            height: screen.visibleFrame.height
        )
        mockAccessibility.currentFrame = leftHalfFrame
        
        try service.execute(.leftHalf)
        
        // Should stay at left half (only one screen)
        XCTAssertEqual(mockAccessibility.lastSetFrame?.origin.x, screen.visibleFrame.origin.x)
    }
    
    // MARK: - Error Handling Tests
    
    func testNoFrontmostWindow() {
        mockAccessibility.shouldThrowNoWindow = true
        
        XCTAssertThrowsError(try service.execute(.leftHalf)) { error in
            XCTAssertEqual(error as? WindowAccessibilityError, .noFrontmostWindow)
        }
    }
    
    func testCannotGetFrame() {
        mockAccessibility.shouldThrowCannotGetFrame = true
        
        XCTAssertThrowsError(try service.execute(.leftHalf)) { error in
            XCTAssertEqual(error as? WindowAccessibilityError, .cannotGetFrame)
        }
    }
    
    func testCannotSetFrame() {
        mockAccessibility.shouldThrowCannotSetFrame = true
        mockAccessibility.currentFrame = CGRect(x: 500, y: 400, width: 800, height: 600)
        
        XCTAssertThrowsError(try service.execute(.leftHalf)) { error in
            XCTAssertEqual(error as? WindowAccessibilityError, .cannotSetFrame)
        }
    }
    
    // MARK: - Dock Offset Detection Tests
    
    func testDockOffsetDetectionWhenWindowIsNearBottomAndFullWidth() throws {
        // Simulate a window at the bottom of the screen with dock offset
        // visibleFrame starts at y=0, but window is at y=38 (dock offset)
        guard let screen = NSScreen.main else {
            XCTFail("No main screen")
            return
        }
        
        // Simulate maximized window with dock offset
        mockAccessibility.currentFrame = CGRect(
            x: screen.visibleFrame.origin.x,
            y: screen.visibleFrame.origin.y + 38,  // Dock offset
            width: screen.visibleFrame.width,
            height: screen.visibleFrame.height
        )
        
        try service.execute(.topHalf)
        
        // After detecting dock offset, the frame should account for it
        XCTAssertEqual(mockAccessibility.setFrameCalled, true)
        
        // Top half should start at y + dockOffset, not y=0
        let expectedY = screen.visibleFrame.origin.y + 38  // Dock offset applied
        XCTAssertNotNil(mockAccessibility.lastSetFrame)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.y, expectedY, accuracy: 1.0)
    }
    
    func testDockOffsetCachingAcrossMultipleActions() throws {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen")
            return
        }
        
        // First action: maximized window with dock offset - should detect and cache
        mockAccessibility.currentFrame = CGRect(
            x: screen.visibleFrame.origin.x,
            y: screen.visibleFrame.origin.y + 38,
            width: screen.visibleFrame.width,
            height: screen.visibleFrame.height
        )
        
        try service.execute(.topHalf)
        let firstFrameY = mockAccessibility.lastSetFrame?.origin.y ?? 0
        
        // Second action: window at top half (y=510, not near bottom)
        // Should still use cached dock offset
        mockAccessibility.currentFrame = mockAccessibility.lastSetFrame ?? .zero
        
        try service.execute(.bottomHalf)
        
        // Bottom half should also account for dock offset from cache
        XCTAssertEqual(mockAccessibility.setFrameCalled, true)
    }
    
    func testMaximizeUsesFullHeightWithDockOffset() throws {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen")
            return
        }
        
        // Start with window at bottom (triggers dock offset detection)
        mockAccessibility.currentFrame = CGRect(
            x: screen.visibleFrame.origin.x,
            y: screen.visibleFrame.origin.y + 38,
            width: screen.visibleFrame.width,
            height: screen.visibleFrame.height
        )
        
        try service.execute(.maximize)
        
        // Maximize should use full visibleFrame height (944), not reduced height
        XCTAssertNotNil(mockAccessibility.lastSetFrame)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.height, screen.visibleFrame.height, accuracy: 1.0)
    }
    
    func testTopHalfHeightWithDockOffset() throws {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen")
            return
        }
        
        // Start with maximized window (triggers dock detection)
        mockAccessibility.currentFrame = CGRect(
            x: screen.visibleFrame.origin.x,
            y: screen.visibleFrame.origin.y + 38,
            width: screen.visibleFrame.width,
            height: screen.visibleFrame.height
        )
        
        try service.execute(.topHalf)
        
        // Top half height should be half of visibleFrame height
        let expectedHeight = screen.visibleFrame.height / 2
        XCTAssertNotNil(mockAccessibility.lastSetFrame)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.height, expectedHeight, accuracy: 1.0)
    }
    
    func testBottomHalfPositionWithDockOffset() throws {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen")
            return
        }
        
        // Start with maximized window (triggers dock detection)
        mockAccessibility.currentFrame = CGRect(
            x: screen.visibleFrame.origin.x,
            y: screen.visibleFrame.origin.y + 38,
            width: screen.visibleFrame.width,
            height: screen.visibleFrame.height
        )
        
        try service.execute(.bottomHalf)
        
        // Bottom half should be at upper portion (y = dock offset + height/2)
        let expectedY = screen.visibleFrame.origin.y + 38 + screen.visibleFrame.height / 2
        XCTAssertNotNil(mockAccessibility.lastSetFrame)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.y, expectedY, accuracy: 1.0)
    }
    
    func testNoDockOffsetWhenWindowNotNearBottom() throws {
        // When window is not near bottom and no cached offset, no adjustment should happen
        guard let screen = NSScreen.main else {
            XCTFail("No main screen")
            return
        }
        
        // Window in center of screen (not near bottom)
        mockAccessibility.currentFrame = CGRect(x: 500, y: 400, width: 800, height: 600)
        
        // Create a fresh service (no cached dock offset)
        let freshService = WindowSnapperService(accessibility: mockAccessibility)
        
        try freshService.execute(.leftHalf)
        
        // Should use visibleFrame as-is
        XCTAssertEqual(mockAccessibility.lastSetFrame?.origin.y, screen.visibleFrame.origin.y)
    }
    
    func testQuarterPositionsWithDockOffset() throws {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen")
            return
        }
        
        // Start with maximized window (triggers dock detection)
        let dockOffset: CGFloat = 38
        mockAccessibility.currentFrame = CGRect(
            x: screen.visibleFrame.origin.x,
            y: screen.visibleFrame.origin.y + dockOffset,
            width: screen.visibleFrame.width,
            height: screen.visibleFrame.height
        )
        
        // Test bottom-left quarter
        try service.execute(.bottomLeftQuarter)
        
        // Bottom-left quarter should be at (x=0, y = dockOffset + height/2)
        let expectedY = screen.visibleFrame.origin.y + dockOffset + screen.visibleFrame.height / 2
        XCTAssertNotNil(mockAccessibility.lastSetFrame)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.y, expectedY, accuracy: 1.0)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.width, screen.visibleFrame.width / 2, accuracy: 1.0)
    }
}

// MARK: - Mock Accessibility Service

class MockAccessibilityService: WindowAccessibilityServiceProtocol {
    var currentFrame: CGRect = .zero
    var lastSetFrame: CGRect?
    var setFrameCalled = false
    
    var shouldThrowNoWindow = false
    var shouldThrowCannotGetFrame = false
    var shouldThrowCannotSetFrame = false
    
    func getFrontmostWindowElement() throws -> AXUIElement? {
        if shouldThrowNoWindow {
            throw WindowAccessibilityError.noFrontmostWindow
        }
        // Return a dummy element (we don't actually use it in tests)
        return AXUIElementCreateApplication(ProcessInfo.processInfo.processIdentifier)
    }
    
    func getWindowFrame(_ element: AXUIElement) throws -> CGRect {
        if shouldThrowCannotGetFrame {
            throw WindowAccessibilityError.cannotGetFrame
        }
        return currentFrame
    }
    
    func setWindowFrame(_ element: AXUIElement, frame: CGRect) throws {
        if shouldThrowCannotSetFrame {
            throw WindowAccessibilityError.cannotSetFrame
        }
        lastSetFrame = frame
        setFrameCalled = true
    }
}
