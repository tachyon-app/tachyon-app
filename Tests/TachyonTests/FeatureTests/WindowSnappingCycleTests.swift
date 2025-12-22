import XCTest
@testable import TachyonCore
import AppKit

/// TDD Tests for Window Snapping Cycle-Through Behavior
final class WindowSnappingCycleTests: XCTestCase {
    
    var service: WindowSnapperService!
    var mockAccessibility: MockCycleAccessibilityService!
    var screen: NSScreen!
    
    override func setUp() {
        super.setUp()
        mockAccessibility = MockCycleAccessibilityService()
        service = WindowSnapperService(accessibility: mockAccessibility)
        screen = NSScreen.main!
    }
    
    // MARK: - Thirds Cycle Tests
    
    func testCycleThirds_fromNonThirdPosition_snapsToFirstThird() throws {
        // Given: Window in center, not at any third position
        mockAccessibility.currentFrame = CGRect(x: 500, y: 400, width: 800, height: 600)
        
        // When: Cycle thirds
        try service.execute(.cycleThirds)
        
        // Then: Should snap to first third (left third)
        let vf = screen.visibleFrame
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.x, vf.origin.x, accuracy: 5)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.width, vf.width / 3, accuracy: 5)
    }
    
    func testCycleThirds_fromFirstThird_movesToCenterThird() throws {
        // Given: Window at first third
        let vf = screen.visibleFrame
        mockAccessibility.currentFrame = CGRect(
            x: vf.origin.x,
            y: vf.origin.y,
            width: vf.width / 3,
            height: vf.height
        )
        
        // When: Cycle thirds
        try service.execute(.cycleThirds)
        
        // Then: Should move to center third
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.x, vf.origin.x + vf.width / 3, accuracy: 5)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.width, vf.width / 3, accuracy: 5)
    }
    
    func testCycleThirds_fromCenterThird_movesToLastThird() throws {
        // Given: Window at center third
        let vf = screen.visibleFrame
        mockAccessibility.currentFrame = CGRect(
            x: vf.origin.x + vf.width / 3,
            y: vf.origin.y,
            width: vf.width / 3,
            height: vf.height
        )
        
        // When: Cycle thirds
        try service.execute(.cycleThirds)
        
        // Then: Should move to last third
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.x, vf.origin.x + vf.width * 2 / 3, accuracy: 5)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.width, vf.width / 3, accuracy: 5)
    }
    
    func testCycleThirds_fromLastThird_movesToFirstThird() throws {
        // Given: Window at last third
        let vf = screen.visibleFrame
        mockAccessibility.currentFrame = CGRect(
            x: vf.origin.x + vf.width * 2 / 3,
            y: vf.origin.y,
            width: vf.width / 3,
            height: vf.height
        )
        
        // When: Cycle thirds
        try service.execute(.cycleThirds)
        
        // Then: Should wrap to first third
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.x, vf.origin.x, accuracy: 5)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.width, vf.width / 3, accuracy: 5)
    }
    
    // MARK: - Quarters Cycle Tests (clockwise: TL → TR → BR → BL)
    
    func testCycleQuarters_fromNonQuarterPosition_snapsToFirstQuarter() throws {
        // Given: Window in center
        mockAccessibility.currentFrame = CGRect(x: 500, y: 400, width: 800, height: 600)
        
        // When: Cycle quarters
        try service.execute(.cycleQuarters)
        
        // Then: Should snap to first quarter (1/4 width, full height)
        let vf = screen.visibleFrame
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.x, vf.origin.x, accuracy: 5)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.y, vf.origin.y, accuracy: 5)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.width, vf.width / 4, accuracy: 5)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.height, vf.height, accuracy: 5)
    }
    
    func testCycleQuarters_fromFirst_movesToSecond() throws {
        // Given: Window at first quarter
        let vf = screen.visibleFrame
        mockAccessibility.currentFrame = CGRect(
            x: vf.origin.x,
            y: vf.origin.y,
            width: vf.width / 4,
            height: vf.height
        )
        
        // When: Cycle quarters
        try service.execute(.cycleQuarters)
        
        // Then: Should move to second quarter
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.x, vf.origin.x + vf.width / 4, accuracy: 5)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.y, vf.origin.y, accuracy: 5)
    }
    
    func testCycleQuarters_fromSecond_movesToThird() throws {
        // Given: Window at second quarter
        let vf = screen.visibleFrame
        mockAccessibility.currentFrame = CGRect(
            x: vf.origin.x + vf.width / 4,
            y: vf.origin.y,
            width: vf.width / 4,
            height: vf.height
        )
        
        // When: Cycle quarters
        try service.execute(.cycleQuarters)
        
        // Then: Should move to third quarter
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.x, vf.origin.x + vf.width / 2, accuracy: 5)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.y, vf.origin.y, accuracy: 5)
    }
    
    func testCycleQuarters_fromThird_movesToFourth() throws {
        // Given: Window at third quarter
        let vf = screen.visibleFrame
        mockAccessibility.currentFrame = CGRect(
            x: vf.origin.x + vf.width / 2,
            y: vf.origin.y,
            width: vf.width / 4,
            height: vf.height
        )
        
        // When: Cycle quarters
        try service.execute(.cycleQuarters)
        
        // Then: Should move to fourth quarter
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.x, vf.origin.x + vf.width * 3 / 4, accuracy: 5)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.y, vf.origin.y, accuracy: 5)
    }
    
    func testCycleQuarters_fromFourth_movesToFirst() throws {
        // Given: Window at fourth quarter
        let vf = screen.visibleFrame
        mockAccessibility.currentFrame = CGRect(
            x: vf.origin.x + vf.width * 3 / 4,
            y: vf.origin.y,
            width: vf.width / 4,
            height: vf.height
        )
        
        // When: Cycle quarters
        try service.execute(.cycleQuarters)
        
        // Then: Should wrap to first quarter
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.x, vf.origin.x, accuracy: 5)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.y, vf.origin.y, accuracy: 5)
    }
    
    // MARK: - Two-Thirds Cycle Tests
    
    func testCycleTwoThirds_fromNonPosition_snapsToFirstTwoThirds() throws {
        // Given: Window in center
        mockAccessibility.currentFrame = CGRect(x: 500, y: 400, width: 800, height: 600)
        
        // When: Cycle two-thirds
        try service.execute(.cycleTwoThirds)
        
        // Then: Should snap to first two-thirds
        let vf = screen.visibleFrame
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.x, vf.origin.x, accuracy: 5)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.width, vf.width * 2 / 3, accuracy: 5)
    }
    
    func testCycleTwoThirds_fromFirstTwoThirds_movesToLastTwoThirds() throws {
        // Given: Window at first two-thirds
        let vf = screen.visibleFrame
        mockAccessibility.currentFrame = CGRect(
            x: vf.origin.x,
            y: vf.origin.y,
            width: vf.width * 2 / 3,
            height: vf.height
        )
        
        // When: Cycle two-thirds
        try service.execute(.cycleTwoThirds)
        
        // Then: Should move to last two-thirds
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.x, vf.origin.x + vf.width / 3, accuracy: 5)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.width, vf.width * 2 / 3, accuracy: 5)
    }
    
    func testCycleTwoThirds_fromLastTwoThirds_movesToFirstTwoThirds() throws {
        // Given: Window at last two-thirds
        let vf = screen.visibleFrame
        mockAccessibility.currentFrame = CGRect(
            x: vf.origin.x + vf.width / 3,
            y: vf.origin.y,
            width: vf.width * 2 / 3,
            height: vf.height
        )
        
        // When: Cycle two-thirds
        try service.execute(.cycleTwoThirds)
        
        // Then: Should wrap to first two-thirds
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.x, vf.origin.x, accuracy: 5)
    }
    
    // MARK: - Three-Quarters Cycle Tests
    
    func testCycleThreeQuarters_fromNonPosition_snapsToFirstThreeQuarters() throws {
        // Given: Window in center
        mockAccessibility.currentFrame = CGRect(x: 500, y: 400, width: 800, height: 600)
        
        // When: Cycle three-quarters
        try service.execute(.cycleThreeQuarters)
        
        // Then: Should snap to first three-quarters
        let vf = screen.visibleFrame
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.x, vf.origin.x, accuracy: 5)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.width, vf.width * 3 / 4, accuracy: 5)
    }
    
    func testCycleThreeQuarters_fromFirstThreeQuarters_movesToLastThreeQuarters() throws {
        // Given: Window at first three-quarters
        let vf = screen.visibleFrame
        mockAccessibility.currentFrame = CGRect(
            x: vf.origin.x,
            y: vf.origin.y,
            width: vf.width * 3 / 4,
            height: vf.height
        )
        
        // When: Cycle three-quarters
        try service.execute(.cycleThreeQuarters)
        
        // Then: Should move to last three-quarters
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.x, vf.origin.x + vf.width / 4, accuracy: 5)
        XCTAssertEqual(mockAccessibility.lastSetFrame!.width, vf.width * 3 / 4, accuracy: 5)
    }
    
    func testCycleThreeQuarters_fromLastThreeQuarters_movesToFirstThreeQuarters() throws {
        // Given: Window at last three-quarters
        let vf = screen.visibleFrame
        mockAccessibility.currentFrame = CGRect(
            x: vf.origin.x + vf.width / 4,
            y: vf.origin.y,
            width: vf.width * 3 / 4,
            height: vf.height
        )
        
        // When: Cycle three-quarters
        try service.execute(.cycleThreeQuarters)
        
        // Then: Should wrap to first three-quarters
        XCTAssertEqual(mockAccessibility.lastSetFrame!.origin.x, vf.origin.x, accuracy: 5)
    }
}

// MARK: - Mock Accessibility Service for Cycle Tests

class MockCycleAccessibilityService: WindowAccessibilityServiceProtocol {
    var currentFrame: CGRect = .zero
    var lastSetFrame: CGRect?
    
    func getFrontmostWindowElement() throws -> AXUIElement? {
        return AXUIElementCreateApplication(ProcessInfo.processInfo.processIdentifier)
    }
    
    func getWindowFrame(_ element: AXUIElement) throws -> CGRect {
        return currentFrame
    }
    
    func setWindowFrame(_ element: AXUIElement, frame: CGRect) throws {
        lastSetFrame = frame
    }
}
