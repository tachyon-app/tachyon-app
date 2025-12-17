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
    
    // Window snapping
    private var windowSnapperService: WindowSnapperService?
    private var windowSnapperHotkeyIDs: [UUID] = []
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - we're a menu bar app
        NSApp.setActivationPolicy(.accessory)
        
        // Setup menu bar
        setupMenuBar()
        
        // Register global hotkey (Cmd+Space)
        registerGlobalHotkey()
        
        // Initialize window snapping
        setupWindowSnapping()
        
        // Listen for shortcut changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadWindowSnappingHotkeys),
            name: .windowSnappingShortcutsDidChange,
            object: nil
        )
        
        // Listen for recording start/end to temporarily disable hotkeys
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(temporarilyDisableWindowSnappingHotkeys),
            name: .windowSnappingRecordingStarted,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadWindowSnappingHotkeys),
            name: .windowSnappingRecordingEnded,
            object: nil
        )
        
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
        unregisterWindowSnappingHotkeys()
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
        searchBarWindow?.disableEventHandling()
        print("⚙️ Settings opened - search bar event handling DISABLED")
        
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            
            // Use custom SettingsWindow that handles Escape key
            let window = SettingsWindow(contentViewController: hostingController)
            window.title = "Tachyon Settings"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
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
            // Re-enable search bar event handling
            searchBarWindow?.enableEventHandling()
            print("✅ Settings closed - search bar event handling RE-ENABLED")
        }
    }
    
    // This method is called when the user presses the Escape key
    // for a window that is the first responder and has a cancel button,
    // or if the window's content view handles it.
    // For a standard window with a closable style, pressing Escape usually
    // triggers `cancelOperation(_:)` which can lead to `windowWillClose`.
    // By simply setting the delegate, we allow the default system behavior
    // for Escape to close the window, and then `windowWillClose` handles cleanup.
    
    // MARK: - Window Snapping
    
    private func setupWindowSnapping() {
        // Check accessibility permissions
        let hasPermission = WindowAccessibilityService.checkAccessibilityPermissions()
        
        if !hasPermission {
            print("⚠️ Accessibility permissions not granted. Window snapping will not work until permissions are granted.")
        }
        
        // Initialize service
        windowSnapperService = WindowSnapperService()
        
        // Register all default hotkeys
        registerWindowSnappingHotkeys()
        
        print("✅ Window snapping initialized")
    }
    
    private func registerWindowSnappingHotkeys() {
        guard let service = windowSnapperService else { return }
        guard let dbQueue = StorageManager.shared.dbQueue else {
            print("❌ Database not available for window snapping shortcuts")
            return
        }
        
        // Create repository
        let repository = WindowSnappingShortcutRepository(dbQueue: dbQueue)
        
        // Load enabled shortcuts from database
        do {
            let shortcuts = try repository.fetchEnabled()
            
            // Register each enabled shortcut
            for shortcut in shortcuts {
                guard let action = shortcut.windowAction else {
                    print("⚠️ Unknown action: \(shortcut.action)")
                    continue
                }
                
                let id = HotkeyManager.shared.register(
                    keyCode: shortcut.keyCode,
                    modifiers: shortcut.modifiers,
                    handler: { [weak service] in
                        do {
                            try service?.execute(action)
                        } catch {
                            print("❌ Failed to execute \(action): \(error)")
                        }
                    }
                )
                windowSnapperHotkeyIDs.append(id)
            }
            
            print("✅ Registered \(windowSnapperHotkeyIDs.count) window snapping hotkeys")
        } catch {
            print("❌ Failed to load window snapping shortcuts: \(error)")
            // Fallback to defaults if database fails
            registerDefaultHotkeys(service: service)
        }
    }
    
    /// Fallback method to register hardcoded defaults if database fails
    private func registerDefaultHotkeys(service: WindowSnapperService) {
        for config in WindowSnapperHotkeys.defaults {
            let id = HotkeyManager.shared.register(
                keyCode: config.keyCode,
                modifiers: config.modifiers,
                handler: { [weak service] in
                    do {
                        try service?.execute(config.action)
                    } catch {
                        print("❌ Failed to execute \(config.action): \(error)")
                    }
                }
            )
            windowSnapperHotkeyIDs.append(id)
        }
        print("✅ Registered \(windowSnapperHotkeyIDs.count) window snapping hotkeys (defaults)")
    }
    
    private func unregisterWindowSnappingHotkeys() {
        for id in windowSnapperHotkeyIDs {
            HotkeyManager.shared.unregister(id)
        }
        windowSnapperHotkeyIDs.removeAll()
        
        print("✅ Unregistered window snapping hotkeys")
    }
    
    
    /// Reload window snapping hotkeys (call this when shortcuts are changed in settings)
    @objc private func reloadWindowSnappingHotkeys() {
        unregisterWindowSnappingHotkeys()
        registerWindowSnappingHotkeys()
        print("🔄 Reloaded window snapping hotkeys")
    }
    
    /// Temporarily disable window snapping hotkeys (during shortcut recording)
    @objc private func temporarilyDisableWindowSnappingHotkeys() {
        unregisterWindowSnappingHotkeys()
        print("⏸️ Temporarily disabled window snapping hotkeys for recording")
    }
}

// MARK: - Settings Window

/// Custom window for settings that properly handles Escape key
class SettingsWindow: NSWindow {
    override func keyDown(with event: NSEvent) {
        // Handle Escape key (keyCode 53)
        if event.keyCode == 53 {
            print("⎋ Escape pressed in SettingsWindow - closing")
            self.close()
        } else {
            super.keyDown(with: event)
        }
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
