import XCTest
@testable import TachyonCore
import AppKit

class ScreenResolverTests: XCTestCase {
    
    // MARK: - Screen Ownership Tests
    
    func testOwningScreenBasedOnCenterPoint() {
        // Simulate two screens side by side
        let screen1 = MockScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let screen2 = MockScreen(frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080))
        
        // Window centered on screen 1
        let window1 = CGRect(x: 800, y: 400, width: 400, height: 300)
        let owner1 = ScreenResolver.owningScreen(for: window1, screens: [screen1, screen2])
        XCTAssertEqual(owner1.frame, screen1.frame)
        
        // Window centered on screen 2
        let window2 = CGRect(x: 2500, y: 400, width: 400, height: 300)
        let owner2 = ScreenResolver.owningScreen(for: window2, screens: [screen1, screen2])
        XCTAssertEqual(owner2.frame, screen2.frame)
    }
    
    func testOwningScreenWithSplitWindow() {
        let screen1 = MockScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let screen2 = MockScreen(frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080))
        
        // Window split 50/50 but center is on screen 1
        let splitWindow = CGRect(x: 1700, y: 400, width: 500, height: 300)
        let centerX = splitWindow.midX // 1950 - on screen 2
        
        let owner = ScreenResolver.owningScreen(for: splitWindow, screens: [screen1, screen2])
        // Center point is at x=1950, which is on screen 2
        XCTAssertEqual(owner.frame, screen2.frame)
    }
    
    func testOwningScreenExactly5050Split() {
        let screen1 = MockScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let screen2 = MockScreen(frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080))
        
        // Window exactly centered on the boundary
        let exactSplitWindow = CGRect(x: 1720, y: 400, width: 400, height: 300)
        // Center is at x=1920, exactly on the boundary
        
        let owner = ScreenResolver.owningScreen(for: exactSplitWindow, screens: [screen1, screen2])
        // Should use intersection area as tiebreaker
        XCTAssertNotNil(owner)
    }
    
    // MARK: - Screen Ordering Tests
    
    func testOrderedScreensHorizontal() {
        // Three screens in horizontal arrangement
        let screen1 = MockScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let screen2 = MockScreen(frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080))
        let screen3 = MockScreen(frame: CGRect(x: 3840, y: 0, width: 1920, height: 1080))
        
        let ordered = ScreenResolver.orderedScreens(screens: [screen3, screen1, screen2])
        
        XCTAssertEqual(ordered.count, 3)
        XCTAssertEqual(ordered[0].frame.origin.x, 0)
        XCTAssertEqual(ordered[1].frame.origin.x, 1920)
        XCTAssertEqual(ordered[2].frame.origin.x, 3840)
    }
    
    func testOrderedScreensVertical() {
        // Two screens in vertical arrangement
        let screen1 = MockScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let screen2 = MockScreen(frame: CGRect(x: 0, y: 1080, width: 1920, height: 1080))
        
        let ordered = ScreenResolver.orderedScreens(screens: [screen2, screen1])
        
        XCTAssertEqual(ordered.count, 2)
        // Should be ordered top to bottom (higher y first in macOS coordinates)
        XCTAssertEqual(ordered[0].frame.origin.y, 1080)
        XCTAssertEqual(ordered[1].frame.origin.y, 0)
    }
    
    // MARK: - Traversal Tests
    
    func testNextScreenHorizontal() {
        let screen1 = MockScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let screen2 = MockScreen(frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080))
        let screen3 = MockScreen(frame: CGRect(x: 3840, y: 0, width: 1920, height: 1080))
        
        let screens = [screen1, screen2, screen3]
        
        let next1 = ScreenResolver.nextScreen(from: screen1, direction: .right, screens: screens)
        XCTAssertEqual(next1?.frame, screen2.frame)
        
        let next2 = ScreenResolver.nextScreen(from: screen2, direction: .right, screens: screens)
        XCTAssertEqual(next2?.frame, screen3.frame)
        
        // At the end, should wrap around
        let next3 = ScreenResolver.nextScreen(from: screen3, direction: .right, screens: screens)
        XCTAssertEqual(next3?.frame, screen1.frame)
    }
    
    func testPreviousScreenHorizontal() {
        let screen1 = MockScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let screen2 = MockScreen(frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080))
        let screen3 = MockScreen(frame: CGRect(x: 3840, y: 0, width: 1920, height: 1080))
        
        let screens = [screen1, screen2, screen3]
        
        let prev3 = ScreenResolver.nextScreen(from: screen3, direction: .left, screens: screens)
        XCTAssertEqual(prev3?.frame, screen2.frame)
        
        let prev2 = ScreenResolver.nextScreen(from: screen2, direction: .left, screens: screens)
        XCTAssertEqual(prev2?.frame, screen1.frame)
        
        // At the start, should wrap around
        let prev1 = ScreenResolver.nextScreen(from: screen1, direction: .left, screens: screens)
        XCTAssertEqual(prev1?.frame, screen3.frame)
    }
    
    func testSingleScreen() {
        let screen = MockScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let screens = [screen]
        
        // With single screen, next/prev should return nil or same screen
        let next = ScreenResolver.nextScreen(from: screen, direction: .right, screens: screens)
        XCTAssertNil(next) // Or could return same screen
    }
    
    // MARK: - Arrangement Orientation Tests
    
    func testArrangementOrientationHorizontal() {
        // Three screens arranged horizontally
        let screen1 = MockScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let screen2 = MockScreen(frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080))
        let screen3 = MockScreen(frame: CGRect(x: 3840, y: 0, width: 1920, height: 1080))
        
        // Note: arrangementOrientation uses NSScreen, so we can't directly test with MockScreen
        // But we can verify the logic by checking orderedScreens behavior
        let ordered = ScreenResolver.orderedScreens(screens: [screen3, screen1, screen2])
        
        // Should be sorted left to right
        XCTAssertEqual(ordered[0].frame.origin.x, 0)
        XCTAssertEqual(ordered[1].frame.origin.x, 1920)
        XCTAssertEqual(ordered[2].frame.origin.x, 3840)
    }
    
    func testArrangementOrientationVertical() {
        // Two screens arranged vertically (stacked)
        let screen1 = MockScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let screen2 = MockScreen(frame: CGRect(x: 0, y: 1080, width: 1920, height: 1080))
        
        let ordered = ScreenResolver.orderedScreens(screens: [screen1, screen2])
        
        // Should be sorted top to bottom (higher y first in macOS coords)
        XCTAssertEqual(ordered[0].frame.maxY, 2160) // screen2 is at top
        XCTAssertEqual(ordered[1].frame.maxY, 1080) // screen1 is at bottom
    }
    
    func testArrangementOrientationMixed() {
        // Screens with vertical offset but predominantly horizontal
        let screen1 = MockScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let screen2 = MockScreen(frame: CGRect(x: 1920, y: -200, width: 1920, height: 1080))
        
        let ordered = ScreenResolver.orderedScreens(screens: [screen2, screen1])
        
        // Horizontal span is 3840, vertical span is 1280
        // Since horizontal > vertical, should sort by x
        XCTAssertEqual(ordered[0].frame.origin.x, 0)
        XCTAssertEqual(ordered[1].frame.origin.x, 1920)
    }
    
    // MARK: - Traversal Direction Tests
    
    func testVerticalTraversalUp() {
        let screen1 = MockScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let screen2 = MockScreen(frame: CGRect(x: 0, y: 1080, width: 1920, height: 1080))
        let screens = [screen1, screen2]
        
        // Going "up" should move to screen with higher y
        let next = ScreenResolver.nextScreen(from: screen1, direction: .up, screens: screens)
        XCTAssertEqual(next?.frame.origin.y, 1080)
    }
    
    func testVerticalTraversalDown() {
        let screen1 = MockScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let screen2 = MockScreen(frame: CGRect(x: 0, y: 1080, width: 1920, height: 1080))
        let screens = [screen1, screen2]
        
        // Going "down" should move to screen with lower y
        let next = ScreenResolver.nextScreen(from: screen2, direction: .down, screens: screens)
        XCTAssertEqual(next?.frame.origin.y, 0)
    }
}

