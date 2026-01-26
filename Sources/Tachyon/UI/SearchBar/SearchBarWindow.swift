import Cocoa
import SwiftUI

/// Floating search bar window
public class SearchBarWindow: NSWindow {
    
    private let searchBarView: SearchBarView
    private let viewModel = SearchBarViewModel() // Own the ViewModel
    private var localEventMonitor: Any?
    private var shouldHandleEvents = true
    
    /// Track the last screen where the window was displayed
    private var lastScreen: NSScreen?
    /// Track the last position on that screen (relative to screen frame)
    private var lastPositionOnScreen: NSPoint?
    
    /// Callback to open settings
    public var onOpenSettings: (() -> Void)?
    
    public init() {
        // Create the SwiftUI view
        searchBarView = SearchBarView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: searchBarView.ignoresSafeArea(.all))
        
        // Configure hosting view for transparency
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = CGColor.clear
        hostingView.layer?.isOpaque = false
        
        // Window configuration
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 560),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // Window properties
        self.level = .floating
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.hasShadow = true
        self.isMovableByWindowBackground = true  // Allow dragging the window by its background
        self.contentView = hostingView
        self.contentView?.wantsLayer = true
        self.contentView?.layer?.backgroundColor = CGColor.clear
        
        // Center on screen
        self.center()
        
        // Start hidden
        self.orderOut(nil)
        
        // Connect hide callback
        viewModel.onHideWindow = { [weak self] in
            print("🙈 Hide callback triggered")
            self?.hide()
        }
        
        // Note: Using fixed height approach - no dynamic resize needed
        // This eliminates animation jitter between AppKit window and SwiftUI content
        
        // Monitor for Escape key and Cmd+,
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            // Debug logging
            if event.keyCode == 53 { // Escape key
                print("🔍 Escape key detected in SearchBarWindow")
                print("   shouldHandleEvents: \(self.shouldHandleEvents)")
                print("   isKeyWindow: \(self.isKeyWindow)")
                print("   isVisible: \(self.isVisible)")
            }
            
            guard self.shouldHandleEvents, self.isKeyWindow && self.isVisible else {
                // Only handle events when enabled, key window, and visible
                if event.keyCode == 53 {
                    print("   ❌ Not handling - guard failed")
                }
                return event
            }
            
            print("🔑 Key pressed: \(event.keyCode)")
            
            // Check for Cmd+, (keycode 43)
            if event.keyCode == 43 && event.modifierFlags.contains(.command) {
                print("⚙️ Cmd+, detected - opening settings")
                self.onOpenSettings?()
                return nil // Consume the event
            }
            
            // When camera is showing, handle camera-specific keys
            if self.viewModel.showingCameraView {
                if event.keyCode == 53 { // Escape - Close camera
                    print("⬅️ Escape - closing camera view")
                    self.viewModel.cameraService.stopSession()
                    self.viewModel.showingCameraView = false
                    // Focus back on search bar after closing camera
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        NotificationCenter.default.post(name: NSNotification.Name("FocusSearchBar"), object: nil)
                    }
                    return nil
                }
                if event.keyCode == 36 { // Enter - Take Photo
                    print("📸 Enter - taking photo in camera view")
                    // Trigger flash effect
                    NotificationCenter.default.post(name: NSNotification.Name("CameraFlash"), object: nil)
                    Task { @MainActor in
                        do {
                            let photo = try await self.viewModel.cameraService.capturePhoto()
                            let savedURL = try self.viewModel.cameraService.savePhoto(photo)
                            NotificationCenter.default.post(
                                name: NSNotification.Name("UpdateStatusBar"),
                                object: ("📸", "Photo saved to \(savedURL.lastPathComponent)")
                            )
                        } catch {
                            print("❌ Photo capture failed: \(error)")
                        }
                    }
                    return nil
                }
                // Consume all other keys when camera is showing to prevent search bar interaction
                return nil
            }
            
            if event.keyCode == 53 { // 53 is Escape
                // Handle go-back navigation directly
                if self.viewModel.showingCameraView {
                    print("⬅️ Escape - closing camera view")
                    self.viewModel.cameraService.stopSession()
                    self.viewModel.showingCameraView = false
                    // Focus back on search bar after closing camera
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        NotificationCenter.default.post(name: NSNotification.Name("FocusSearchBar"), object: nil)
                    }
                    return nil
                } else if self.viewModel.isCollectingArguments {
                    print("⬅️ Escape - exiting inline argument mode")
                    self.viewModel.exitInlineArgumentMode()
                    return nil
                } else if self.viewModel.showingScriptOutput != nil {
                    print("⬅️ Escape - dismissing script output")
                    self.viewModel.showingScriptOutput = nil
                    return nil
                } else if self.viewModel.showingScriptArgumentForm != nil {
                    print("⬅️ Escape - dismissing script argument form")
                    self.viewModel.showingScriptArgumentForm = nil
                    return nil
                } else if self.viewModel.showingLinkForm != nil {
                    print("⬅️ Escape - dismissing link form")
                    self.viewModel.showingLinkForm = nil
                    return nil
                }
                
                // Only hide window when at main search screen
                print("🛑 Escape detected in monitor - hiding search bar")
                self.hide()
                return nil // Consume the event
            } else if event.keyCode == 125 { // Arrow Down
                self.viewModel.selectNext()
                return nil
            } else if event.keyCode == 126 { // Arrow Up
                self.viewModel.selectPrevious()
                return nil
            }
            return event
        }
    }
    
    /// Toggle window visibility
    public func toggle() {
        if self.isVisible {
            hide()
        } else {
            show()
        }
    }
    
    /// Show the search bar
    public func show() {
        // Get the current focused screen
        guard let currentScreen = NSScreen.main else { return }
        let screenFrame = currentScreen.visibleFrame
        let windowFrame = self.frame
        
        // Check if we're on the same screen as last time
        let isSameScreen = lastScreen != nil && lastScreen == currentScreen
        
        if isSameScreen, let lastPosition = lastPositionOnScreen {
            // Restore the last position on the same screen
            self.setFrameOrigin(lastPosition)
            print("📍 Restored position: \(lastPosition)")
        } else {
            // Position the search bar at upper-center of screen (like Spotlight)
            // Place the window so the TOP of the window is at about 2/3 up from bottom
            // This puts the search bar in a comfortable position with room for results below
            let x = screenFrame.midX - windowFrame.width / 2
            let windowTop = screenFrame.minY + screenFrame.height * 0.75  // 3/4 up from bottom = 1/4 from top
            let y = windowTop - windowFrame.height
            
            print("📍 Screen frame: \(screenFrame), height: \(screenFrame.height)")
            print("📍 Window top at: \(windowTop), origin y: \(y)")
            
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        // Update tracking
        lastScreen = currentScreen
        
        shouldHandleEvents = true
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Focus the search field via notification after a short delay
        // This ensures the window is fully visible and SwiftUI view is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            NotificationCenter.default.post(name: NSNotification.Name("FocusSearchBar"), object: nil)
        }
    }
    
    /// Hide the search bar
    public func hide() {
        // Save current position for next time (on same screen)
        lastPositionOnScreen = self.frame.origin
        
        shouldHandleEvents = false
        self.orderOut(nil)
        searchBarView.clearSearch()
    }
    
    /// Disable event handling (e.g., when settings window is open)
    public func disableEventHandling() {
        shouldHandleEvents = false
    }
    
    /// Enable event handling
    public func enableEventHandling() {
        shouldHandleEvents = true
    }
    
    // Allow clicking through when not focused
    public override var canBecomeKey: Bool {
        return true
    }
}
