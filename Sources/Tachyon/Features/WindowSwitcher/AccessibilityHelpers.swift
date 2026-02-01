import Cocoa
import ApplicationServices

class AccessibilityHelpers {
    
    static func checkAccessibilityPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    static func focusWindow(_ window: WindowInfo) {
        let appElement = AXUIElementCreateApplication(window.ownerPID)
        
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
        
        guard result == .success, let windows = windowsRef as? [AXUIElement] else {
            // Fallback: Just activate the app if we can't get windows (restrictions etc)
            activateApp(pid: window.ownerPID)
            return
        }
        
        // Find the matching window
        // We match by ID if possible (kAXWindowNumber?) or by title/size heuristic
        // Note: kAXWindowNumber is not always reliable or available via AX, but let's try.
        // If not, we use Title and Size.
        
        var targetWindowElement: AXUIElement?
        
        for element in windows {
            // Try matching by window ID if available (rarely exposed directly as attribute, but let's check standard ones)
            // Common practice: Match Title and Size/Position.
            
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleRef)
            let axTitle = (titleRef as? String) ?? ""
            
            var sizeRef: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef)
            var axSize = CGSize.zero
            if let sizeVal = sizeRef, CFGetTypeID(sizeVal) == AXValueGetTypeID() {
                // Force cast is safe because we checked TypeID, but 'as! AXValue' might still trigger warnings if types are identical
                // Since they are identical, we can just pass it if the API expects AXValue
                let axValue = sizeVal as! AXValue
                AXValueGetValue(axValue, .cgSize, &axSize)
            }
            
            var posRef: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posRef)
            var axPos = CGPoint.zero
            if let posVal = posRef, CFGetTypeID(posVal) == AXValueGetTypeID() {
                let axValue = posVal as! AXValue
                AXValueGetValue(axValue, .cgPoint, &axPos)
            }
            
            // Check if matches our window info
            // Heuristic usage: Title matches AND Frame is close enough
            // (AX Frame is usually screen coordinates, CGWindowList is also screen coordinates)
            
            let frame = window.frame
            // Allow small error margin for float conversions
            let sizeMatch = abs(axSize.width - frame.width) < 5 && abs(axSize.height - frame.height) < 5
            let posMatch = abs(axPos.x - frame.origin.x) < 5 && abs(axPos.y - frame.origin.y) < 5
            
            if axTitle == window.title && sizeMatch && posMatch {
                targetWindowElement = element
                break
            }
            
            // Second chance: if title mismatch (sometimes window title changes slightly), match strictly by frame
            if sizeMatch && posMatch {
                 targetWindowElement = element
            }
        }
        
        if let target = targetWindowElement {
            // 1. Un-minimize if needed
            var minimizedRef: CFTypeRef?
            AXUIElementCopyAttributeValue(target, kAXMinimizedAttribute as CFString, &minimizedRef)
            if let isMin = minimizedRef as? Bool, isMin {
                AXUIElementSetAttributeValue(target, kAXMinimizedAttribute as CFString, false as CFTypeRef)
            }
            
            // 2. Raise
            AXUIElementPerformAction(target, kAXRaiseAction as CFString)
            
            // 3. Focus (Main)
            AXUIElementSetAttributeValue(target, kAXMainAttribute as CFString, true as CFTypeRef)
        }
        
        // 4. Activate App
        activateApp(pid: window.ownerPID)
    }
    
    private static func activateApp(pid: pid_t) {
        if let app = NSRunningApplication(processIdentifier: pid) {
            app.activate(options: .activateIgnoringOtherApps)
        }
    }
}
