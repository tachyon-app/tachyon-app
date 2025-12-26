import XCTest
@testable import TachyonCore

/// Tests for FocusSession data model (TDD)
final class FocusSessionTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        let session = FocusSession(duration: 1500) // 25 minutes
        
        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.duration, 1500)
        XCTAssertNil(session.goal)
        XCTAssertNil(session.startTime)
        XCTAssertEqual(session.state, .pending)
    }
    
    func testInitializationWithGoal() {
        let session = FocusSession(duration: 1500, goal: "Write documentation")
        
        XCTAssertEqual(session.goal, "Write documentation")
    }
    
    // MARK: - State Transition Tests
    
    func testStartSession() {
        var session = FocusSession(duration: 1500)
        
        session.start()
        
        XCTAssertEqual(session.state, .active)
        XCTAssertNotNil(session.startTime)
    }
    
    func testPauseSession() {
        var session = FocusSession(duration: 1500)
        session.start()
        
        session.pause()
        
        XCTAssertEqual(session.state, .paused)
        XCTAssertNotNil(session.pausedAt)
    }
    
    func testResumeSession() {
        var session = FocusSession(duration: 1500)
        session.start()
        session.pause()
        
        session.resume()
        
        XCTAssertEqual(session.state, .active)
        XCTAssertNil(session.pausedAt)
    }
    
    func testStopSession() {
        var session = FocusSession(duration: 1500)
        session.start()
        
        session.stop()
        
        XCTAssertEqual(session.state, .cancelled)
    }
    
    func testCompleteSession() {
        var session = FocusSession(duration: 1500)
        session.start()
        
        session.complete()
        
        XCTAssertEqual(session.state, .completed)
    }
    
    // MARK: - Remaining Time Tests
    
    func testRemainingTimeBeforeStart() {
        let session = FocusSession(duration: 1500)
        
        XCTAssertEqual(session.remainingTime, 1500)
    }
    
    func testRemainingTimeAfterStart() {
        var session = FocusSession(duration: 1500)
        session.start()
        
        // Remaining time should be close to duration (within 1 second)
        XCTAssertLessThanOrEqual(abs(session.remainingTime - 1500), 1)
    }
    
    // MARK: - Invalid State Transitions
    
    func testCannotPauseBeforeStart() {
        var session = FocusSession(duration: 1500)
        
        session.pause()
        
        XCTAssertEqual(session.state, .pending) // Should remain pending
    }
    
    func testCannotResumeIfNotPaused() {
        var session = FocusSession(duration: 1500)
        session.start()
        
        session.resume() // Already active
        
        XCTAssertEqual(session.state, .active)
    }
}
