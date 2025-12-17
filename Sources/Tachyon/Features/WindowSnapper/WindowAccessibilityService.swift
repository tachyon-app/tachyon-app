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
        
        print("🔧 Setting frame: \(frame)")
        
        // For cross-display moves, we need to:
        // 1. Set position first to move to new screen
        // 2. Then set size (which may be constrained by old screen)
        // 3. Set size AGAIN to ensure it takes effect on new screen
        
        // Set position first
        let posResult = AXUIElementSetAttributeValue(
            element,
            kAXPositionAttribute as CFString,
            positionValue
        )
        
        print("🔧 Position set result: \(posResult == .success ? "SUCCESS" : "FAILED (\(posResult.rawValue))")")
        
        // Set size
        let sizeResult = AXUIElementSetAttributeValue(
            element,
            kAXSizeAttribute as CFString,
            sizeValue
        )
        
        print("🔧 Size set result: \(sizeResult == .success ? "SUCCESS" : "FAILED (\(sizeResult.rawValue))")")
        
        guard posResult == .success && sizeResult == .success else {
            throw WindowAccessibilityError.cannotSetFrame
        }
        
        // Verify the frame was actually set
        let actualFrame = try getWindowFrame(element)
        print("🔧 Actual frame after setting: \(actualFrame)")
        
        // If size didn't take effect (common with cross-display moves), set it again
        let sizeTolerance: CGFloat = 10.0
        if abs(actualFrame.width - frame.width) > sizeTolerance || 
           abs(actualFrame.height - frame.height) > sizeTolerance {
            print("🔧 Size mismatch detected, setting size again...")
            
            let sizeResult2 = AXUIElementSetAttributeValue(
                element,
                kAXSizeAttribute as CFString,
                sizeValue
            )
            
            print("🔧 Second size set result: \(sizeResult2 == .success ? "SUCCESS" : "FAILED (\(sizeResult2.rawValue))")")
            
            let finalFrame = try getWindowFrame(element)
            print("🔧 Final frame: \(finalFrame)")
        }
    }
    
    /// Check if accessibility permissions are granted
    public static func checkAccessibilityPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
