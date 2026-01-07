import SwiftUI
import AppKit

/// Specific window subclass for Clipboard History to handle events like Escape key
class ClipboardWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    
    override func cancelOperation(_ sender: Any?) {
        // Handle Escape (Cancel)
        ClipboardHistoryWindowController.shared.hide()
    }
    
    override func keyDown(with event: NSEvent) {
        // Handle Escape key (keyCode 53) manually if cancelOperation doesn't catch it
        if event.keyCode == 53 {
            ClipboardHistoryWindowController.shared.hide()
            return
        }
        super.keyDown(with: event)
    }
}

/// Window controller for the Clipboard History feature
/// Manages the floating window that displays clipboard history
public class ClipboardHistoryWindowController: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = ClipboardHistoryWindowController()
    
    // MARK: - Properties
    
    public enum PresentationSource {
        case hotkey
        case searchBar
    }
    
    public private(set) var window: NSWindow?
    private var hostingView: NSHostingView<ClipboardHistoryView>?
    private var presentationSource: PresentationSource = .hotkey
    
    @Published public private(set) var isVisible: Bool = false
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupNotifications()
    }
    
    // MARK: - Public API
    
    /// Show the clipboard history window
    public func show(source: PresentationSource = .hotkey) {
        self.presentationSource = source
        
        if window == nil {
            createWindow()
        }
        
        guard let window = window else { return }
        
        // Refresh items before showing (on MainActor)
        Task { @MainActor in
            ClipboardHistoryManager.shared.refreshItems()
        }
        
        // Position window at center of screen
        positionWindow(window)
        
        // Show window with animation
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }
        
        isVisible = true
        
        // Activate the app
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// Hide the clipboard history window
    public func hide() {
        guard let window = window, isVisible else { return }
        
        // Capture source and reset immediately to prevent recursion loop
        let source = presentationSource
        presentationSource = .hotkey
        
        // Re-open search bar if we came from there
        if source == .searchBar {
            NotificationCenter.default.post(name: NSNotification.Name("ShowSearchBar"), object: nil)
        }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            window.orderOut(nil)
            self?.isVisible = false
        })
    }
    
    /// Toggle visibility
    public func toggle(source: PresentationSource = .hotkey) {
        if isVisible {
            hide()
        } else {
            show(source: source)
        }
    }
    
    // MARK: - Private Methods
    
    private func createWindow() {
        // Create hosting view
        let historyView = ClipboardHistoryView(manager: ClipboardHistoryManager.shared)
        hostingView = NSHostingView(rootView: historyView)
        
        // Create window
        let window = ClipboardWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 480),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingView
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.isMovableByWindowBackground = true
        
        // Handle window losing focus
        window.delegate = self
        
        self.window = window
    }
    
    private func positionWindow(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame
        
        // Center horizontally, position in upper third vertically
        let x = screenFrame.midX - windowFrame.width / 2
        let y = screenFrame.midY - windowFrame.height / 2 + screenFrame.height * 0.1
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloseNotification),
            name: .closeClipboardHistoryWindow,
            object: nil
        )
    }
    
    @objc private func handleCloseNotification() {
        hide()
    }
}

// MARK: - NSWindowDelegate

extension ClipboardHistoryWindowController: NSWindowDelegate {
    public func windowDidResignKey(_ notification: Notification) {
        // Hide when window loses focus
        hide()
    }
}
