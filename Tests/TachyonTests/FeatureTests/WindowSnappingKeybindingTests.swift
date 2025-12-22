import XCTest
@testable import TachyonCore

/// TDD Tests for Window Snapping Default Keybindings
final class WindowSnappingKeybindingTests: XCTestCase {
    
    // MARK: - Keybinding Default Tests
    
    func testMaximizeDefaultKeyIsCtrlOptEnter() {
        // Ctrl+Opt = 6144, Enter = 36
        let maximize = WindowSnappingShortcut.defaults.first { $0.action == "maximize" }
        XCTAssertNotNil(maximize)
        XCTAssertEqual(maximize?.keyCode, 36)  // Enter
        XCTAssertEqual(maximize?.modifiers, 6144)  // Ctrl+Opt
    }
    
    func testCenterDefaultKeyIsCtrlOptC() {
        // Ctrl+Opt = 6144, C = 8
        let center = WindowSnappingShortcut.defaults.first { $0.action == "center" }
        XCTAssertNotNil(center)
        XCTAssertEqual(center?.keyCode, 8)  // C
        XCTAssertEqual(center?.modifiers, 6144)  // Ctrl+Opt
    }
    
    func testCycleThirdsDefaultKeyIsCtrlOpt3() {
        // Ctrl+Opt = 6144, 3 = 20
        let cycleThirds = WindowSnappingShortcut.defaults.first { $0.action == "cycleThirds" }
        XCTAssertNotNil(cycleThirds)
        XCTAssertEqual(cycleThirds?.keyCode, 20)  // 3
        XCTAssertEqual(cycleThirds?.modifiers, 6144)  // Ctrl+Opt
    }
    
    func testCycleTwoThirdsDefaultKeyIsCtrlOptT() {
        // Ctrl+Opt = 6144, T = 17
        let cycleTwoThirds = WindowSnappingShortcut.defaults.first { $0.action == "cycleTwoThirds" }
        XCTAssertNotNil(cycleTwoThirds)
        XCTAssertEqual(cycleTwoThirds?.keyCode, 17)  // T
        XCTAssertEqual(cycleTwoThirds?.modifiers, 6144)  // Ctrl+Opt
    }
    
    func testCycleQuartersDefaultKeyIsCtrlOpt4() {
        // Ctrl+Opt = 6144, 4 = 21
        let cycleQuarters = WindowSnappingShortcut.defaults.first { $0.action == "cycleQuarters" }
        XCTAssertNotNil(cycleQuarters)
        XCTAssertEqual(cycleQuarters?.keyCode, 21)  // 4
        XCTAssertEqual(cycleQuarters?.modifiers, 6144)  // Ctrl+Opt
    }
    
    func testCycleThreeQuartersDefaultKeyIsCtrlOptQ() {
        // Ctrl+Opt = 6144, Q = 12
        let cycleThreeQuarters = WindowSnappingShortcut.defaults.first { $0.action == "cycleThreeQuarters" }
        XCTAssertNotNil(cycleThreeQuarters)
        XCTAssertEqual(cycleThreeQuarters?.keyCode, 12)  // Q
        XCTAssertEqual(cycleThreeQuarters?.modifiers, 6144)  // Ctrl+Opt
    }
    
    // MARK: - Old Keybindings Removed Tests
    
    func testOldThirdKeybindingsRemoved() {
        // These should no longer exist
        XCTAssertNil(WindowSnappingShortcut.defaults.first { $0.action == "firstThird" })
        XCTAssertNil(WindowSnappingShortcut.defaults.first { $0.action == "centerThird" })
        XCTAssertNil(WindowSnappingShortcut.defaults.first { $0.action == "lastThird" })
    }
    
    func testOldTwoThirdsKeybindingsRemoved() {
        XCTAssertNil(WindowSnappingShortcut.defaults.first { $0.action == "firstTwoThirds" })
        XCTAssertNil(WindowSnappingShortcut.defaults.first { $0.action == "lastTwoThirds" })
    }
    
    func testOldQuarterKeybindingsRemoved() {
        XCTAssertNil(WindowSnappingShortcut.defaults.first { $0.action == "topLeftQuarter" })
        XCTAssertNil(WindowSnappingShortcut.defaults.first { $0.action == "topRightQuarter" })
        XCTAssertNil(WindowSnappingShortcut.defaults.first { $0.action == "bottomLeftQuarter" })
        XCTAssertNil(WindowSnappingShortcut.defaults.first { $0.action == "bottomRightQuarter" })
    }
    
    func testOldThreeQuartersKeybindingsRemoved() {
        XCTAssertNil(WindowSnappingShortcut.defaults.first { $0.action == "firstThreeQuarters" })
        XCTAssertNil(WindowSnappingShortcut.defaults.first { $0.action == "lastThreeQuarters" })
    }
}
