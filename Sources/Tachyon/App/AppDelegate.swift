import Cocoa
import SwiftUI
import Carbon
import TachyonCore

/// AppDelegate manages the global state of the app
/// - Menu bar item
/// - Global hotkey registration
/// - Search bar window
class AppDelegate: NSObject, NSApplicationDelegate {
    
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
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
        unregisterGlobalHotkey()
    }
    
    // MARK: - Menu Bar
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "Tachyon")
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
        // Register Cmd+Space
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType("TACH".fourCharCodeValue)
        hotKeyID.id = 1
        
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        // Install event handler
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
        
        // Register hotkey: Cmd+Space (keycode 49 = space)
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
    
    func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Tachyon Settings"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: 800, height: 600))
            window.center()
            
            settingsWindow = window
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
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
