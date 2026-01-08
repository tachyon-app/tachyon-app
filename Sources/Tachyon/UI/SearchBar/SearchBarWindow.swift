import Cocoa
import SwiftUI

/// Floating search bar window
public class SearchBarWindow: NSWindow {
    
    private let searchBarView: SearchBarView
    private let viewModel = SearchBarViewModel() // Own the ViewModel
    private var localEventMonitor: Any?
    private var shouldHandleEvents = true
    
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
            
            if event.keyCode == 53 { // 53 is Escape
                // Handle go-back navigation directly
                if self.viewModel.isCollectingArguments {
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
        // Center on the screen with the cursor
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = self.frame
            
            // Position near top of screen
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.maxY - windowFrame.height - 100
            
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        shouldHandleEvents = true
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Focus the search field
        searchBarView.focusSearchField()
    }
    
    /// Hide the search bar
    public func hide() {
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
