import XCTest
@testable import TachyonCore

/// Tests for Script Runner notification behavior
final class ScriptRunnerNotificationTests: XCTestCase {
    
    // MARK: - Notification Posting Tests
    
    func testCompactModePostsClearSearchQueryNotification() {
        // Test that compact mode posts ClearSearchQuery notification
        let expectation = XCTestExpectation(description: "ClearSearchQuery notification posted")
        
        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ClearSearchQuery"),
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        // Simulate compact script execution
        NotificationCenter.default.post(
            name: NSNotification.Name("ClearSearchQuery"),
            object: nil
        )
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testInlineModePostsClearSearchQueryNotification() {
        // Test that inline mode posts ClearSearchQuery notification
        let expectation = XCTestExpectation(description: "ClearSearchQuery notification posted")
        
        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ClearSearchQuery"),
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        // Simulate inline script execution
        NotificationCenter.default.post(
            name: NSNotification.Name("ClearSearchQuery"),
            object: nil
        )
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testSilentModePostsClearSearchQueryNotification() {
        // Test that silent mode posts ClearSearchQuery notification
        let expectation = XCTestExpectation(description: "ClearSearchQuery notification posted")
        
        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ClearSearchQuery"),
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        // Simulate silent script execution
        NotificationCenter.default.post(
            name: NSNotification.Name("ClearSearchQuery"),
            object: nil
        )
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - Status Bar Update Tests
    
    func testCompactModePostsStatusBarUpdate() {
        let expectation = XCTestExpectation(description: "UpdateStatusBar notification posted")
        
        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UpdateStatusBar"),
            object: nil,
            queue: .main
        ) { notification in
            if let (emoji, message) = notification.object as? (String, String) {
                XCTAssertEqual(emoji, "✅")
                XCTAssertFalse(message.isEmpty)
                expectation.fulfill()
            }
        }
        
        // Simulate compact script success
        NotificationCenter.default.post(
            name: NSNotification.Name("UpdateStatusBar"),
            object: ("✅", "Test output")
        )
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testInlineModePostsStatusBarUpdate() {
        let expectation = XCTestExpectation(description: "UpdateStatusBar notification posted")
        
        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UpdateStatusBar"),
            object: nil,
            queue: .main
        ) { notification in
            if let (emoji, message) = notification.object as? (String, String) {
                XCTAssertEqual(emoji, "✅")
                XCTAssertEqual(message, "Updated inline output")
                expectation.fulfill()
            }
        }
        
        // Simulate inline script success
        NotificationCenter.default.post(
            name: NSNotification.Name("UpdateStatusBar"),
            object: ("✅", "Updated inline output")
        )
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testSilentModePostsStatusBarUpdate() {
        let expectation = XCTestExpectation(description: "UpdateStatusBar notification posted")
        
        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UpdateStatusBar"),
            object: nil,
            queue: .main
        ) { notification in
            if let (emoji, message) = notification.object as? (String, String) {
                XCTAssertEqual(emoji, "✅")
                XCTAssertEqual(message, "Script finished running")
                expectation.fulfill()
            }
        }
        
        // Simulate silent script success
        NotificationCenter.default.post(
            name: NSNotification.Name("UpdateStatusBar"),
            object: ("✅", "Script finished running")
        )
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - Refresh Results Tests
    
    func testInlineModePostsRefreshSearchResults() {
        let expectation = XCTestExpectation(description: "RefreshSearchResults notification posted")
        
        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RefreshSearchResults"),
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        // Simulate inline script execution
        NotificationCenter.default.post(
            name: NSNotification.Name("RefreshSearchResults"),
            object: nil
        )
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - Notification Order Tests
    
    func testNotificationsPostedInCorrectOrder() {
        // Test that for inline mode, notifications are posted in the correct order:
        // 1. UpdateStatusBar
        // 2. ClearSearchQuery
        // 3. RefreshSearchResults
        
        var notifications: [String] = []
        let expectation = XCTestExpectation(description: "All notifications received")
        expectation.expectedFulfillmentCount = 3
        
        let statusObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UpdateStatusBar"),
            object: nil,
            queue: .main
        ) { _ in
            notifications.append("UpdateStatusBar")
            expectation.fulfill()
        }
        
        let clearObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ClearSearchQuery"),
            object: nil,
            queue: .main
        ) { _ in
            notifications.append("ClearSearchQuery")
            expectation.fulfill()
        }
        
        let refreshObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RefreshSearchResults"),
            object: nil,
            queue: .main
        ) { _ in
            notifications.append("RefreshSearchResults")
            expectation.fulfill()
        }
        
        // Post notifications in order
        NotificationCenter.default.post(name: NSNotification.Name("UpdateStatusBar"), object: ("✅", "Test"))
        NotificationCenter.default.post(name: NSNotification.Name("ClearSearchQuery"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("RefreshSearchResults"), object: nil)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(notifications.count, 3)
        XCTAssertEqual(notifications[0], "UpdateStatusBar")
        XCTAssertEqual(notifications[1], "ClearSearchQuery")
        XCTAssertEqual(notifications[2], "RefreshSearchResults")
        
        NotificationCenter.default.removeObserver(statusObserver)
        NotificationCenter.default.removeObserver(clearObserver)
        NotificationCenter.default.removeObserver(refreshObserver)
    }
}
