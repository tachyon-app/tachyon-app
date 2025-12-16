import Cocoa
import SwiftUI
import Carbon
import TachyonCore

/// AppDelegate manages the global state of the app
/// - Menu bar item
/// - Global hotkey registration
/// - Search bar window
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    
    private var statusItem: NSStatusItem?
    private var searchBarWindow: SearchBarWindow?
    private var settingsWindow: NSWindow?
    private var hotkeyRef: EventHotKeyRef?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - we're a menu bar app
        NSApp.setActivationPolicy(.accessory)
        
        // Setup menu bar
        setupMenuBar()
        
        // Register global hotkey (Cmd+Space)
        registerGlobalHotkey()
        
        // Create search bar window (hidden initially)
        searchBarWindow = SearchBarWindow()
        
        // Pass settings callback to search bar
        searchBarWindow?.onOpenSettings = { [weak self] in
            self?.openSettings()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
        unregisterGlobalHotkey()
    }
    
    // MARK: - Menu Bar
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Use custom logo icon
            if let logoImage = NSImage(contentsOfFile: "/Users/pablo/code/flashcast/Resources/icon.png") {
                logoImage.size = NSSize(width: 18, height: 18)
                logoImage.isTemplate = true // Makes it adapt to menu bar theme
                button.image = logoImage
            } else {
                // Fallback to system icon
                button.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "Tachyon")
            }
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Tachyon", action: #selector(toggleSearchBar), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettingsMenu), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Tachyon", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    // MARK: - Global Hotkey
    
    private func registerGlobalHotkey() {
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        // Install event handler for Cmd+Space
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
                appDelegate.toggleSearchBar()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )
        
        // Register Cmd+Space hotkey
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType("TACH".fourCharCodeValue)
        hotKeyID.id = 1
        
        RegisterEventHotKey(
            49, // Space key
            UInt32(cmdKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
    }
    
    private func unregisterGlobalHotkey() {
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
        }
    }
    
    // MARK: - Actions
    
    @objc func toggleSearchBar() {
        searchBarWindow?.toggle()
    }
    
    @objc func openSettingsMenu() {
        openSettings()
    }
    
    public func openSettings() {
        // Hide search bar when opening settings
        searchBarWindow?.hide()
        
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Tachyon Settings"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isOpaque = false
            window.backgroundColor = .clear
            window.setContentSize(NSSize(width: 800, height: 600))
            window.center()
            
            // Set AppDelegate as the window's delegate to handle events like closing
            window.delegate = self
            
            settingsWindow = window
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        // If the settings window is closing, nil it out so it can be recreated if opened again
        if notification.object as? NSWindow == settingsWindow {
            settingsWindow = nil
        }
    }
    
    // This method is called when the user presses the Escape key
    // for a window that is the first responder and has a cancel button,
    // or if the window's content view handles it.
    // For a standard window with a closable style, pressing Escape usually
    // triggers `cancelOperation(_:)` which can lead to `windowWillClose`.
    // By simply setting the delegate, we allow the default system behavior
    // for Escape to close the window, and then `windowWillClose` handles cleanup.
}

// MARK: - Helper Extension

extension String {
    var fourCharCodeValue: FourCharCode {
        var result: FourCharCode = 0
        for char in self.utf8 {
            result = (result << 8) + FourCharCode(char)
        }
        return result
    }
}
