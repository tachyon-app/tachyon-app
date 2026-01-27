import Foundation
import AppKit
import ApplicationServices

/// Protocol for window accessibility operations (allows mocking in tests)
public protocol WindowAccessibilityServiceProtocol {
    func getFrontmostWindowElement() throws -> AXUIElement?
    func getWindowFrame(_ element: AXUIElement) throws -> CGRect
    func setWindowFrame(_ element: AXUIElement, frame: CGRect) throws
}

/// Errors that can occur during accessibility operations
public enum WindowAccessibilityError: Error {
    case accessibilityNotEnabled
    case noFrontmostWindow
    case cannotGetFrame
    case cannotSetFrame
    case invalidElement
}

/// Service for interacting with windows via macOS Accessibility APIs
public class WindowAccessibilityService: WindowAccessibilityServiceProtocol {
    
    public init() {}
    
    /// Get the frontmost window element
    public func getFrontmostWindowElement() throws -> AXUIElement? {
        // Get the frontmost application
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            throw WindowAccessibilityError.noFrontmostWindow
        }
        
        let pid = frontmostApp.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        // Get the focused window
        var focusedWindow: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        )
        
        guard result == .success, let window = focusedWindow else {
            // Try to get main window if focused window fails
            var mainWindow: CFTypeRef?
            let mainResult = AXUIElementCopyAttributeValue(
                appElement,
                kAXMainWindowAttribute as CFString,
                &mainWindow
            )
            
            guard mainResult == .success, let window = mainWindow else {
                throw WindowAccessibilityError.noFrontmostWindow
            }
            
            return (window as! AXUIElement)
        }
        
        return (focusedWindow as! AXUIElement)
    }
    
    /// Get the frame of a window element
    public func getWindowFrame(_ element: AXUIElement) throws -> CGRect {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        
        // Get position
        let posResult = AXUIElementCopyAttributeValue(
            element,
            kAXPositionAttribute as CFString,
            &positionValue
        )
        
        // Get size
        let sizeResult = AXUIElementCopyAttributeValue(
            element,
            kAXSizeAttribute as CFString,
            &sizeValue
        )
        
        guard posResult == .success, sizeResult == .success,
              let posValue = positionValue, let szValue = sizeValue else {
            throw WindowAccessibilityError.cannotGetFrame
        }
        
        var position = CGPoint.zero
        var size = CGSize.zero
        
        AXValueGetValue(posValue as! AXValue, .cgPoint, &position)
        AXValueGetValue(szValue as! AXValue, .cgSize, &size)
        
        // Convert from Cocoa coordinates (origin at bottom-left) to screen coordinates
        // macOS Accessibility uses screen coordinates with origin at top-left
        return CGRect(origin: position, size: size)
    }
    
    /// Set the frame of a window element
    public func setWindowFrame(_ element: AXUIElement, frame: CGRect) throws {
        // Create position value
        var position = frame.origin
        guard let positionValue = AXValueCreate(.cgPoint, &position) else {
            throw WindowAccessibilityError.cannotSetFrame
        }
        
        // Create size value
        var size = frame.size
        guard let sizeValue = AXValueCreate(.cgSize, &size) else {
            throw WindowAccessibilityError.cannotSetFrame
        }
        
        // Robust strategy for cross-display moves:
        // 1. Set position to move to the new screen/location.
        // 2. Set size (post-sizing).
        
        print("🔍 DEBUG: setWindowFrame - Target: \(frame)")
        
        // Step 1: Set Position
        let posResult = AXUIElementSetAttributeValue(
            element,
            kAXPositionAttribute as CFString,
            positionValue
        )
        print("🔍 DEBUG: setWindowFrame - Set Pos Result: \(posResult.rawValue)")
        
        guard posResult == .success else {
            throw WindowAccessibilityError.cannotSetFrame
        }
        
        // Step 2: Post-size (definitive)
        // We do this immediately. If it fails to resize fully, we enter a retry loop.
        let sizeResultValue = AXUIElementSetAttributeValue(
            element,
            kAXSizeAttribute as CFString,
            sizeValue
        )
        print("🔍 DEBUG: setWindowFrame - Set Size Result: \(sizeResultValue.rawValue)")
        
        // Verify and Retry Logic
        // We verify if the frame was actually set correctly. If not, we retry up to 3 times
        // with small delays, which is often needed for macOS to register the screen change.
        var attempts = 0
        let maxAttempts = 3
        
        while attempts < maxAttempts {
            // Check current frame
            if let currentFrame = try? getWindowFrame(element) {
                print("🔍 DEBUG: setWindowFrame - Retry Check Loop \(attempts) - Current: \(currentFrame)")
                
                // Check if frame matches within tolerance
                let tolerance: CGFloat = 20.0
                let widthDiff = abs(currentFrame.width - frame.width)
                let heightDiff = abs(currentFrame.height - frame.height)
                let xDiff = abs(currentFrame.origin.x - frame.origin.x)
                let yDiff = abs(currentFrame.origin.y - frame.origin.y)
                
                print("🔍 DEBUG: setWindowFrame - Diffs: w=\(widthDiff) h=\(heightDiff) x=\(xDiff) y=\(yDiff)")
                
                // If dimensions match reasonably well, we are done
                if widthDiff < tolerance && heightDiff < tolerance && xDiff < tolerance && yDiff < tolerance {
                    print("🔍 DEBUG: setWindowFrame - Success!")
                    return
                }
            }
            
            // If we are here, potential failure. Wait briefly and retry sizing/positioning
            attempts += 1
            print("🔍 DEBUG: setWindowFrame - Retrying \(attempts)...")
            usleep(20000) // 20ms
            
            // Re-apply position then size
            _ = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, positionValue)
            _ = AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sizeValue)
        }
        print("🔍 DEBUG: setWindowFrame - Failed after \(maxAttempts) attempts")
    }
    
    /// Check if accessibility permissions are granted
    public static func checkAccessibilityPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
