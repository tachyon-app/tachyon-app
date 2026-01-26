import Foundation
import AppKit
import ApplicationServices

/// Result of scene activation
public enum SceneActivationResult {
    case success(applied: Int, launched: [String])
    case partialMatch(applied: Int, skipped: Int, launched: [String])
    case displayMismatch(required: Int, current: Int)
    case failed(Error)
    
    public var isSuccess: Bool {
        switch self {
        case .success, .partialMatch:
            return true
        case .displayMismatch, .failed:
            return false
        }
    }
}

/// Errors for scene activation
public enum SceneActivationError: Error, LocalizedError {
    case sceneNotFound
    case noWindowsInScene
    case displayMismatch(required: Int, current: Int)
    case accessibilityNotEnabled
    case failedToPositionWindow(appName: String, reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .sceneNotFound:
            return "Scene not found"
        case .noWindowsInScene:
            return "Scene contains no windows"
        case .displayMismatch(let required, let current):
            return "Scene requires \(required) displays but only \(current) are connected"
        case .accessibilityNotEnabled:
            return "Accessibility permissions are required"
        case .failedToPositionWindow(let appName, let reason):
            return "Failed to position \(appName): \(reason)"
        }
    }
}

/// Service for activating (recalling) scene layouts
public class SceneActivationService {
    
    private let accessibility: WindowAccessibilityServiceProtocol
    
    public init(accessibility: WindowAccessibilityServiceProtocol = WindowAccessibilityService()) {
        self.accessibility = accessibility
    }
    
    /// Check if the current display configuration matches scene requirements
    public func canActivate(_ scene: WindowScene) -> Bool {
        let currentDisplayCount = NSScreen.screens.count
        
        if scene.isFullWorkspace {
            // Full workspace scenes require exact display count match
            return currentDisplayCount >= scene.displayCount
        } else {
            // Specific display scenes just need that display to exist
            guard let targetIndex = scene.targetDisplayIndex else { return false }
            return targetIndex < currentDisplayCount
        }
    }
    
    /// Activate a scene, positioning all windows
    /// - Parameters:
    ///   - scene: The scene to activate
    ///   - windows: The windows belonging to this scene
    ///   - forcePartial: If true, apply partial match even when display count mismatches
    /// - Returns: Result indicating success, partial match, or failure
    public func activate(
        _ scene: WindowScene,
        windows: [SceneWindow],
        forcePartial: Bool = false
    ) async throws -> SceneActivationResult {
        let currentDisplayCount = NSScreen.screens.count
        
        // Check display configuration
        if !canActivate(scene) && !forcePartial {
            return .displayMismatch(required: scene.displayCount, current: currentDisplayCount)
        }
        
        var appliedCount = 0
        var skippedCount = 0
        var launchedApps: [String] = []
        
        // Group windows by app
        let windowsByApp = Dictionary(grouping: windows) { $0.bundleId }
        
        for (bundleId, appWindows) in windowsByApp {
            // Launch app if not running
            let runningApp = try await ensureAppRunning(
                bundleId: bundleId,
                appPath: appWindows.first?.appPath,
                appName: appWindows.first?.appName ?? bundleId
            )
            
            if runningApp.wasLaunched {
                launchedApps.append(appWindows.first?.appName ?? bundleId)
                
                // Give newly launched app time to create windows
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            // Track which windows we've already positioned for this app
            var usedWindowIndices: Set<Int> = []
            
            // Position each window for this app
            for sceneWindow in appWindows {
                // Skip windows for displays that don't exist
                if sceneWindow.displayIndex >= currentDisplayCount {
                    skippedCount += 1
                    continue
                }
                
                guard let screen = SceneGeometry.screen(forIndex: sceneWindow.displayIndex) else {
                    skippedCount += 1
                    continue
                }
                
                let targetFrame = sceneWindow.toAbsoluteFrame(visibleFrame: screen.visibleFrame)
                
                // Try to position the window (may spawn new window if needed)
                if try await positionAppWindow(
                    app: runningApp.app,
                    targetFrame: targetFrame,
                    bundleId: bundleId,
                    usedIndices: &usedWindowIndices
                ) {
                    appliedCount += 1
                } else {
                    skippedCount += 1
                }
            }
        }
        
        if skippedCount > 0 {
            return .partialMatch(applied: appliedCount, skipped: skippedCount, launched: launchedApps)
        } else {
            return .success(applied: appliedCount, launched: launchedApps)
        }
    }
    
    // MARK: - App Launching
    
    /// Ensure an app is running, launching it if necessary
    private func ensureAppRunning(
        bundleId: String,
        appPath: String?,
        appName: String
    ) async throws -> (app: NSRunningApplication, wasLaunched: Bool) {
        // Check if already running
        if let existing = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) {
            return (existing, false)
        }
        
        // Try to launch the app
        let app: NSRunningApplication
        
        if let path = appPath {
            // Launch from recorded path
            let url = URL(fileURLWithPath: path)
            let config = NSWorkspace.OpenConfiguration()
            config.activates = false
            config.hides = false
            
            app = try await NSWorkspace.shared.openApplication(at: url, configuration: config)
        } else {
            // Try to launch by bundle ID
            guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
                throw SceneActivationError.failedToPositionWindow(
                    appName: appName,
                    reason: "Application not found"
                )
            }
            
            let config = NSWorkspace.OpenConfiguration()
            config.activates = false
            config.hides = false
            
            app = try await NSWorkspace.shared.openApplication(at: appURL, configuration: config)
        }
        
        return (app, true)
    }
    
    // MARK: - Window Positioning
    
    /// Position a window for a specific app, using an unused window or spawning a new one
    private func positionAppWindow(
        app: NSRunningApplication,
        targetFrame: CGRect,
        bundleId: String,
        usedIndices: inout Set<Int>
    ) async throws -> Bool {
        // Activate the app to bring it to foreground
        app.activate(options: [])
        
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        // Get the app's windows
        var windowsValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windowsValue
        )
        
        var windowsList = (result == .success) ? (windowsValue as? [AXUIElement]) ?? [] : []
        
        // Find first unused window
        var windowElement: AXUIElement?
        for (index, window) in windowsList.enumerated() {
            if !usedIndices.contains(index) {
                windowElement = window
                usedIndices.insert(index)
                break
            }
        }
        
        // If no unused window, try to spawn a new one
        if windowElement == nil {
            print("🪟 All windows used for \(bundleId), spawning new window...")
            
            if let newWindow = try await spawnNewWindow(for: app, appElement: appElement) {
                windowElement = newWindow
                // Mark the new window index as used
                usedIndices.insert(windowsList.count)
            }
        }
        
        guard let window = windowElement else {
            print("⚠️ No window available for \(bundleId)")
            return false
        }
        
        // Set the window frame
        do {
            try accessibility.setWindowFrame(window, frame: targetFrame)
            
            // Raise the window to front
            AXUIElementPerformAction(window, kAXRaiseAction as CFString)
            
            return true
        } catch {
            print("⚠️ Failed to position window for \(bundleId): \(error)")
            return false
        }
    }
    
    // MARK: - Window Spawning
    
    /// Spawn a new window for an app using System Events menu click
    private func spawnNewWindow(
        for app: NSRunningApplication,
        appElement: AXUIElement
    ) async throws -> AXUIElement? {
        // Get current window count
        let beforeCount = getWindowCount(appElement: appElement)
        
        // Get app name and process name
        let appName = app.localizedName ?? app.bundleIdentifier ?? "Application"
        
        print("🪟 Spawning new window for \(appName)")
        
        // Activate the app first
        app.activate(options: [.activateIgnoringOtherApps])
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Use System Events to click "New Window" menu item
        let script = """
            tell application "System Events"
                tell process "\(appName)"
                    click menu item "New Window" of menu "File" of menu bar 1
                end tell
            end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            if error == nil {
                // Wait for window to appear
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                let afterCount = getWindowCount(appElement: appElement)
                if afterCount > beforeCount {
                    print("✅ Created new window via menu click for \(appName)")
                    return getNewestWindow(appElement: appElement)
                }
            } else {
                print("⚠️ AppleScript error: \(error ?? [:])")
            }
        }
        
        // Fallback: Simulate Cmd+N keystroke
        print("🔄 Trying Cmd+N fallback for \(appName)")
        simulateCmdN()
        
        // Wait for window to appear
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
        
        let afterCount = getWindowCount(appElement: appElement)
        if afterCount > beforeCount {
            print("✅ Created new window via Cmd+N for \(appName)")
            return getNewestWindow(appElement: appElement)
        }
        
        print("⚠️ Could not spawn new window for \(appName)")
        return nil
    }
    
    /// Get the process name for an app (used by System Events)
    private func getProcessName(for app: NSRunningApplication) -> String? {
        // For most apps, localizedName works. For some like VS Code,
        // the process name differs from the app name.
        // We can get it from the executable URL
        if let executableURL = app.executableURL {
            let execName = executableURL.deletingPathExtension().lastPathComponent
            // Some apps like "Visual Studio Code" have executable "Code"
            if !execName.isEmpty && execName != "MacOS" {
                return execName
            }
        }
        
        // Fallback to localizedName
        return app.localizedName
    }
    
    /// Get the current window count for an app
    private func getWindowCount(appElement: AXUIElement) -> Int {
        var windowsValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windowsValue
        )
        
        guard result == .success, let windows = windowsValue as? [AXUIElement] else {
            return 0
        }
        
        return windows.count
    }
    
    /// Get the newest (last) window for an app
    private func getNewestWindow(appElement: AXUIElement) -> AXUIElement? {
        var windowsValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windowsValue
        )
        
        guard result == .success, let windows = windowsValue as? [AXUIElement] else {
            return nil
        }
        
        // The newest window is typically first in the list (most recently focused)
        return windows.first
    }
    
    /// Simulate Cmd+N keystroke to create a new window/document
    private func simulateCmdN() {
        // Key code for 'N' is 45
        let keyCode: CGKeyCode = 45
        
        // Create key down event with Command modifier
        if let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
        }
        
        // Create key up event
        if let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cghidEventTap)
        }
    }
}
