import Cocoa
import SwiftUI

/// Floating search bar window
public class SearchBarWindow: NSPanel {
    
    private let searchBarView: SearchBarView
    private let viewModel = SearchBarViewModel() // Own the ViewModel
    private var localEventMonitor: Any?
    
    public init() {
        // Create the SwiftUI view with the ViewModel
        searchBarView = SearchBarView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: searchBarView)
        
        // Window configuration for floating panel
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500), // Keep large height for now
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // Window properties
        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.contentView = hostingView
        
        // Center on screen
        self.center()
        
        // Start hidden
        self.orderOut(nil)
        
        // Connect hide callback
        viewModel.onHideWindow = { [weak self] in
            print("🙈 Hide callback triggered")
            self?.hide()
        }
        
        // Connect height callback
        // Connect height callback
        viewModel.onHeightChanged = { [weak self] height in
            // animate frame change
            guard let self = self else { return }
            
            let newHeight = max(height, 80) // Minimum height for search bar
            let currentFrame = self.frame
            
            // Calculate new origin to keep top anchored
            let heightDiff = newHeight - currentFrame.height
            let newY = currentFrame.origin.y - heightDiff
            
            let newFrame = NSRect(
                x: currentFrame.origin.x,
                y: newY,
                width: currentFrame.width,
                height: newHeight
            )
            
            // Only animate if the change is significant
            if abs(heightDiff) > 1 {
                self.animator().setFrame(newFrame, display: true)
            }
        }
        
        // Monitor for Escape key
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            print("🔑 Key pressed: \(event.keyCode)")
            if event.keyCode == 53 { // 53 is Escape
                print("🛑 Escape detected in monitor")
                self?.hide()
                return nil // Consume the event
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
    func show() {
        // Center on the screen with the cursor
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = self.frame
            
            // Position near top of screen
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.maxY - windowFrame.height - 100
            
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Focus the search field
        searchBarView.focusSearchField()
    }
    
    /// Hide the search bar
    func hide() {
        self.orderOut(nil)
        searchBarView.clearSearch()
    }
    
    // Allow clicking through when not focused
    public override var canBecomeKey: Bool {
        return true
    }
}
