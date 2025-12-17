import XCTest
@testable import TachyonCore

class WindowGeometryTests: XCTestCase {
    
    // Standard screen setup for testing
    let screenFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let visibleFrame = CGRect(x: 0, y: 0, width: 1920, height: 1055) // 25px menu bar
    
    // MARK: - Halves Tests
    
    func testLeftHalf() {
        let result = WindowGeometry.targetFrame(
            for: .leftHalf,
            currentFrame: CGRect(x: 500, y: 500, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.origin.y, 0)
        XCTAssertEqual(result.width, 960) // Half of 1920
        XCTAssertEqual(result.height, 1055)
    }
    
    func testRightHalf() {
        let result = WindowGeometry.targetFrame(
            for: .rightHalf,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 960)
        XCTAssertEqual(result.origin.y, 0)
        XCTAssertEqual(result.width, 960)
        XCTAssertEqual(result.height, 1055)
    }
    
    func testTopHalf() {
        // NOTE: "topHalf" action moves window to BOTTOM of screen visually
        // (lower Y in macOS coordinate system where y=0 is at bottom)
        let result = WindowGeometry.targetFrame(
            for: .topHalf,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.origin.y, 0) // Bottom of screen (lower Y)
        XCTAssertEqual(result.width, 1920)
        XCTAssertEqual(result.height, 527.5) // Half height
    }
    
    func testBottomHalf() {
        // NOTE: "bottomHalf" action moves window to TOP of screen visually
        // (higher Y in macOS coordinate system)
        let result = WindowGeometry.targetFrame(
            for: .bottomHalf,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.origin.y, 527.5) // Top of screen (higher Y = half of 1055)
        XCTAssertEqual(result.width, 1920)
        XCTAssertEqual(result.height, 527.5)
    }
    
    // MARK: - Quarters Tests
    
    func testTopLeftQuarter() {
        // NOTE: "topLeftQuarter" moves to BOTTOM-LEFT visually (lower Y, left X)
        let result = WindowGeometry.targetFrame(
            for: .topLeftQuarter,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.origin.y, 0) // Bottom (lower Y)
        XCTAssertEqual(result.width, 960)
        XCTAssertEqual(result.height, 527.5)
    }
    
    func testTopRightQuarter() {
        // NOTE: "topRightQuarter" moves to BOTTOM-RIGHT visually (lower Y, right X)
        let result = WindowGeometry.targetFrame(
            for: .topRightQuarter,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 960)
        XCTAssertEqual(result.origin.y, 0) // Bottom (lower Y)
        XCTAssertEqual(result.width, 960)
        XCTAssertEqual(result.height, 527.5)
    }
    
    func testBottomLeftQuarter() {
        // NOTE: "bottomLeftQuarter" moves to TOP-LEFT visually (higher Y, left X)
        let result = WindowGeometry.targetFrame(
            for: .bottomLeftQuarter,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.origin.y, 527.5) // Top (higher Y)
        XCTAssertEqual(result.width, 960)
        XCTAssertEqual(result.height, 527.5)
    }
    
    func testBottomRightQuarter() {
        // NOTE: "bottomRightQuarter" moves to TOP-RIGHT visually (higher Y, right X)
        let result = WindowGeometry.targetFrame(
            for: .bottomRightQuarter,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 960)
        XCTAssertEqual(result.origin.y, 527.5) // Top (higher Y)
        XCTAssertEqual(result.width, 960)
        XCTAssertEqual(result.height, 527.5)
    }
    
    func testFirstThreeQuarters() {
        let result = WindowGeometry.targetFrame(
            for: .firstThreeQuarters,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.origin.y, 0)
        XCTAssertEqual(result.width, 1440) // 3/4 of 1920
        XCTAssertEqual(result.height, 1055)
    }
    
    func testLastThreeQuarters() {
        let result = WindowGeometry.targetFrame(
            for: .lastThreeQuarters,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 480) // 1/4 of 1920
        XCTAssertEqual(result.origin.y, 0)
        XCTAssertEqual(result.width, 1440)
        XCTAssertEqual(result.height, 1055)
    }
    
    // MARK: - Thirds Tests
    
    func testFirstThird() {
        let result = WindowGeometry.targetFrame(
            for: .firstThird,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.origin.y, 0)
        XCTAssertEqual(result.width, 640) // 1/3 of 1920
        XCTAssertEqual(result.height, 1055)
    }
    
    func testCenterThird() {
        let result = WindowGeometry.targetFrame(
            for: .centerThird,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 640)
        XCTAssertEqual(result.origin.y, 0)
        XCTAssertEqual(result.width, 640)
        XCTAssertEqual(result.height, 1055)
    }
    
    func testLastThird() {
        let result = WindowGeometry.targetFrame(
            for: .lastThird,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 1280) // 2/3 of 1920
        XCTAssertEqual(result.origin.y, 0)
        XCTAssertEqual(result.width, 640)
        XCTAssertEqual(result.height, 1055)
    }
    
    func testFirstTwoThirds() {
        let result = WindowGeometry.targetFrame(
            for: .firstTwoThirds,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.origin.y, 0)
        XCTAssertEqual(result.width, 1280) // 2/3 of 1920
        XCTAssertEqual(result.height, 1055)
    }
    
    func testLastTwoThirds() {
        let result = WindowGeometry.targetFrame(
            for: .lastTwoThirds,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 640) // 1/3 of 1920
        XCTAssertEqual(result.origin.y, 0)
        XCTAssertEqual(result.width, 1280)
        XCTAssertEqual(result.height, 1055)
    }
    
    // MARK: - Maximize & Center Tests
    
    func testMaximize() {
        let result = WindowGeometry.targetFrame(
            for: .maximize,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        // Should fill entire visible frame
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.origin.y, 0)
        XCTAssertEqual(result.width, 1920)
        XCTAssertEqual(result.height, 1055)
    }
    
    func testCenter() {
        let currentFrame = CGRect(x: 100, y: 100, width: 800, height: 600)
        let result = WindowGeometry.targetFrame(
            for: .center,
            currentFrame: currentFrame,
            visibleFrame: visibleFrame
        )
        
        // Should preserve size, just center it
        XCTAssertEqual(result.width, 800)
        XCTAssertEqual(result.height, 600)
        
        // Check centering
        let expectedX = (CGFloat(1920) - CGFloat(800)) / 2
        let expectedY = (CGFloat(1055) - CGFloat(600)) / 2
        XCTAssertEqual(result.origin.x, expectedX)
        XCTAssertEqual(result.origin.y, expectedY)
    }


    
    // MARK: - Portrait Screen Tests
    
    func testPortraitScreenFirstThird() {
        // Portrait screen (taller than wide)
        let portraitVisible = CGRect(x: 0, y: 0, width: 1080, height: 1920)
        
        let result = WindowGeometry.targetFrame(
            for: .firstThird,
            currentFrame: CGRect(x: 100, y: 100, width: 500, height: 500),
            visibleFrame: portraitVisible
        )
        
        // In portrait, thirds should be vertical
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.origin.y, 1280) // Top third (2/3 from bottom)
        XCTAssertEqual(result.width, 1080)
        XCTAssertEqual(result.height, 640) // 1/3 of 1920
    }
    
    func testPortraitScreenCenterThird() {
        let portraitVisible = CGRect(x: 0, y: 0, width: 1080, height: 1920)
        
        let result = WindowGeometry.targetFrame(
            for: .centerThird,
            currentFrame: CGRect(x: 100, y: 100, width: 500, height: 500),
            visibleFrame: portraitVisible
        )
        
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.origin.y, 640)
        XCTAssertEqual(result.width, 1080)
        XCTAssertEqual(result.height, 640)
    }
    
    func testPortraitScreenLastThird() {
        let portraitVisible = CGRect(x: 0, y: 0, width: 1080, height: 1920)
        
        let result = WindowGeometry.targetFrame(
            for: .lastThird,
            currentFrame: CGRect(x: 100, y: 100, width: 500, height: 500),
            visibleFrame: portraitVisible
        )
        
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.origin.y, 0) // Bottom third
        XCTAssertEqual(result.width, 1080)
        XCTAssertEqual(result.height, 640)
    }
    
    // MARK: - Edge Detection Tests
    
    func testCurrentSnapPositionLeftHalf() {
        let leftHalfFrame = CGRect(x: 0, y: 0, width: 960, height: 1055)
        
        let position = WindowGeometry.currentSnapPosition(
            frame: leftHalfFrame,
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(position, .leftHalf)
    }
    
    func testCurrentSnapPositionRightHalf() {
        let rightHalfFrame = CGRect(x: 960, y: 0, width: 960, height: 1055)
        
        let position = WindowGeometry.currentSnapPosition(
            frame: rightHalfFrame,
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(position, .rightHalf)
    }
    
    func testCurrentSnapPositionTopLeftQuarter() {
        // TopLeftQuarter is at bottom-left visually (y=0 in macOS coords)
        let quarterFrame = CGRect(x: 0, y: 0, width: 960, height: 527.5)
        
        let position = WindowGeometry.currentSnapPosition(
            frame: quarterFrame,
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(position, .topLeftQuarter)
    }
    
    func testCurrentSnapPositionMaximized() {
        let maxFrame = CGRect(x: 0, y: 0, width: 1920, height: 1055)
        
        let position = WindowGeometry.currentSnapPosition(
            frame: maxFrame,
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(position, .maximize)
    }
    
    func testCurrentSnapPositionNone() {
        let randomFrame = CGRect(x: 100, y: 100, width: 800, height: 600)
        
        let position = WindowGeometry.currentSnapPosition(
            frame: randomFrame,
            visibleFrame: visibleFrame
        )
        
        XCTAssertNil(position)
    }
}
