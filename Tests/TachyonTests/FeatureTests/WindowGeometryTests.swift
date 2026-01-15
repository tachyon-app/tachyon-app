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
        let result = WindowGeometry.targetFrame(
            for: .topHalf,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.origin.y, 0)
        XCTAssertEqual(result.width, 1920)
        XCTAssertEqual(result.height, 527.5)
    }
    
    func testBottomHalf() {
        let result = WindowGeometry.targetFrame(
            for: .bottomHalf,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.origin.y, 527.5)
        XCTAssertEqual(result.width, 1920)
        XCTAssertEqual(result.height, 527.5)
    }
    
    // MARK: - Third Position Helper Tests
    
    func testThirdFramePosition1() {
        let result = WindowGeometry.thirdFrame(position: 1, visibleFrame: visibleFrame)
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.width, 640) // 1/3 of 1920
    }
    
    func testThirdFramePosition2() {
        let result = WindowGeometry.thirdFrame(position: 2, visibleFrame: visibleFrame)
        XCTAssertEqual(result.origin.x, 640) // 1/3 of 1920
        XCTAssertEqual(result.width, 640)
    }
    
    func testThirdFramePosition3() {
        let result = WindowGeometry.thirdFrame(position: 3, visibleFrame: visibleFrame)
        XCTAssertEqual(result.origin.x, 1280) // 2/3 of 1920
        XCTAssertEqual(result.width, 640)
    }
    
    func testCurrentThirdPositionFirst() {
        let frame = CGRect(x: 0, y: 0, width: 640, height: 1055)
        let pos = WindowGeometry.currentThirdPosition(frame: frame, visibleFrame: visibleFrame)
        XCTAssertEqual(pos, 1)
    }
    
    func testCurrentThirdPositionCenter() {
        let frame = CGRect(x: 640, y: 0, width: 640, height: 1055)
        let pos = WindowGeometry.currentThirdPosition(frame: frame, visibleFrame: visibleFrame)
        XCTAssertEqual(pos, 2)
    }
    
    func testCurrentThirdPositionLast() {
        let frame = CGRect(x: 1280, y: 0, width: 640, height: 1055)
        let pos = WindowGeometry.currentThirdPosition(frame: frame, visibleFrame: visibleFrame)
        XCTAssertEqual(pos, 3)
    }
    
    func testCurrentThirdPositionNone() {
        let frame = CGRect(x: 100, y: 100, width: 800, height: 600)
        let pos = WindowGeometry.currentThirdPosition(frame: frame, visibleFrame: visibleFrame)
        XCTAssertNil(pos)
    }
    
    // MARK: - Quarter Position Helper Tests
    
    func testQuarterFramePosition1_First() {
        let result = WindowGeometry.quarterFrame(position: 1, visibleFrame: visibleFrame)
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.origin.y, 0)
        XCTAssertEqual(result.width, 480)  // 1/4 of 1920
        XCTAssertEqual(result.height, 1055)
    }
    
    func testQuarterFramePosition2_Second() {
        let result = WindowGeometry.quarterFrame(position: 2, visibleFrame: visibleFrame)
        XCTAssertEqual(result.origin.x, 480)  // 1/4 of 1920
        XCTAssertEqual(result.origin.y, 0)
    }
    
    func testQuarterFramePosition3_Third() {
        let result = WindowGeometry.quarterFrame(position: 3, visibleFrame: visibleFrame)
        XCTAssertEqual(result.origin.x, 960)  // 1/2 of 1920
        XCTAssertEqual(result.origin.y, 0)
    }
    
    func testQuarterFramePosition4_Fourth() {
        let result = WindowGeometry.quarterFrame(position: 4, visibleFrame: visibleFrame)
        XCTAssertEqual(result.origin.x, 1440)  // 3/4 of 1920
        XCTAssertEqual(result.origin.y, 0)
    }
    
    func testCurrentQuarterPositionFirst() {
        let frame = CGRect(x: 0, y: 0, width: 480, height: 1055)
        let pos = WindowGeometry.currentQuarterPosition(frame: frame, visibleFrame: visibleFrame)
        XCTAssertEqual(pos, 1)
    }
    
    func testCurrentQuarterPositionSecond() {
        let frame = CGRect(x: 480, y: 0, width: 480, height: 1055)
        let pos = WindowGeometry.currentQuarterPosition(frame: frame, visibleFrame: visibleFrame)
        XCTAssertEqual(pos, 2)
    }
    
    func testCurrentQuarterPositionThird() {
        let frame = CGRect(x: 960, y: 0, width: 480, height: 1055)
        let pos = WindowGeometry.currentQuarterPosition(frame: frame, visibleFrame: visibleFrame)
        XCTAssertEqual(pos, 3)
    }
    
    func testCurrentQuarterPositionFourth() {
        let frame = CGRect(x: 1440, y: 0, width: 480, height: 1055)
        let pos = WindowGeometry.currentQuarterPosition(frame: frame, visibleFrame: visibleFrame)
        XCTAssertEqual(pos, 4)
    }
    
    // MARK: - Two-Thirds Position Helper Tests
    
    func testTwoThirdsFramePosition1() {
        let result = WindowGeometry.twoThirdsFrame(position: 1, visibleFrame: visibleFrame)
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.width, 1280) // 2/3 of 1920
    }
    
    func testTwoThirdsFramePosition2() {
        let result = WindowGeometry.twoThirdsFrame(position: 2, visibleFrame: visibleFrame)
        XCTAssertEqual(result.origin.x, 640) // 1/3 of 1920
        XCTAssertEqual(result.width, 1280)
    }
    
    // MARK: - Three-Quarters Position Helper Tests
    
    func testThreeQuartersFramePosition1() {
        let result = WindowGeometry.threeQuartersFrame(position: 1, visibleFrame: visibleFrame)
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.width, 1440) // 3/4 of 1920
    }
    
    func testThreeQuartersFramePosition2() {
        let result = WindowGeometry.threeQuartersFrame(position: 2, visibleFrame: visibleFrame)
        XCTAssertEqual(result.origin.x, 480) // 1/4 of 1920
        XCTAssertEqual(result.width, 1440)
    }
    
    // MARK: - Maximize & Center Tests
    
    func testMaximize() {
        let result = WindowGeometry.targetFrame(
            for: .maximize,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
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
        
        XCTAssertEqual(result.width, 800)
        XCTAssertEqual(result.height, 600)
        
        let expectedX = (CGFloat(1920) - CGFloat(800)) / 2
        let expectedY = (CGFloat(1055) - CGFloat(600)) / 2
        XCTAssertEqual(result.origin.x, expectedX)
        XCTAssertEqual(result.origin.y, expectedY)
    }
    
    // MARK: - Snap Position Detection Tests
    
    func testCurrentSnapPositionLeftHalf() {
        let leftHalfFrame = CGRect(x: 0, y: 0, width: 960, height: 1055)
        let position = WindowGeometry.currentSnapPosition(frame: leftHalfFrame, visibleFrame: visibleFrame)
        XCTAssertEqual(position, .leftHalf)
    }
    
    func testCurrentSnapPositionRightHalf() {
        let rightHalfFrame = CGRect(x: 960, y: 0, width: 960, height: 1055)
        let position = WindowGeometry.currentSnapPosition(frame: rightHalfFrame, visibleFrame: visibleFrame)
        XCTAssertEqual(position, .rightHalf)
    }
    
    func testCurrentSnapPositionMaximized() {
        let maxFrame = CGRect(x: 0, y: 0, width: 1920, height: 1055)
        let position = WindowGeometry.currentSnapPosition(frame: maxFrame, visibleFrame: visibleFrame)
        XCTAssertEqual(position, .maximize)
    }
    
    func testCurrentSnapPositionNone() {
        let randomFrame = CGRect(x: 100, y: 100, width: 800, height: 600)
        let position = WindowGeometry.currentSnapPosition(frame: randomFrame, visibleFrame: visibleFrame)
        XCTAssertNil(position)
    }
    
    // MARK: - Corner Quarter Tests (screen divided into 4 quadrants)
    
    func testTopLeftQuarter() {
        let result = WindowGeometry.targetFrame(
            for: .topLeftQuarter,
            currentFrame: CGRect(x: 500, y: 500, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.origin.y, 0)
        XCTAssertEqual(result.width, 960)   // Half of 1920
        XCTAssertEqual(result.height, 527.5) // Half of 1055
    }
    
    func testTopRightQuarter() {
        let result = WindowGeometry.targetFrame(
            for: .topRightQuarter,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 960)  // Half of 1920
        XCTAssertEqual(result.origin.y, 0)
        XCTAssertEqual(result.width, 960)
        XCTAssertEqual(result.height, 527.5)
    }
    
    func testBottomLeftQuarter() {
        let result = WindowGeometry.targetFrame(
            for: .bottomLeftQuarter,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 0)
        XCTAssertEqual(result.origin.y, 527.5)  // Half of 1055
        XCTAssertEqual(result.width, 960)
        XCTAssertEqual(result.height, 527.5)
    }
    
    func testBottomRightQuarter() {
        let result = WindowGeometry.targetFrame(
            for: .bottomRightQuarter,
            currentFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            visibleFrame: visibleFrame
        )
        
        XCTAssertEqual(result.origin.x, 960)
        XCTAssertEqual(result.origin.y, 527.5)
        XCTAssertEqual(result.width, 960)
        XCTAssertEqual(result.height, 527.5)
    }
    
    // MARK: - Corner Quarter Snap Position Detection Tests
    
    func testCurrentSnapPositionTopLeftQuarter() {
        let frame = CGRect(x: 0, y: 0, width: 960, height: 527.5)
        let position = WindowGeometry.currentSnapPosition(frame: frame, visibleFrame: visibleFrame)
        XCTAssertEqual(position, .topLeftQuarter)
    }
    
    func testCurrentSnapPositionTopRightQuarter() {
        let frame = CGRect(x: 960, y: 0, width: 960, height: 527.5)
        let position = WindowGeometry.currentSnapPosition(frame: frame, visibleFrame: visibleFrame)
        XCTAssertEqual(position, .topRightQuarter)
    }
    
    func testCurrentSnapPositionBottomLeftQuarter() {
        let frame = CGRect(x: 0, y: 527.5, width: 960, height: 527.5)
        let position = WindowGeometry.currentSnapPosition(frame: frame, visibleFrame: visibleFrame)
        XCTAssertEqual(position, .bottomLeftQuarter)
    }
    
    func testCurrentSnapPositionBottomRightQuarter() {
        let frame = CGRect(x: 960, y: 527.5, width: 960, height: 527.5)
        let position = WindowGeometry.currentSnapPosition(frame: frame, visibleFrame: visibleFrame)
        XCTAssertEqual(position, .bottomRightQuarter)
    }
}
