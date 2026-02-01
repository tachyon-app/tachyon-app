import Foundation
import Cocoa
import Combine

enum SwitcherState {
    case idle
    case active
    case navigating
    case committing
}

class WindowSwitcherViewModel: ObservableObject {
    @Published var state: SwitcherState = .idle
    @Published var windows: [WindowInfo] = []
    @Published var selectedIndex: Int = 0
    
    private let discoveryService = WindowDiscoveryService.shared
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    var selectedWindow: WindowInfo? {
        guard windows.indices.contains(selectedIndex) else { return nil }
        return windows[selectedIndex]
    }
    
    init() {
        setupGlobalEventTap()
    }
    
    deinit {
        if let eventTap = eventTap, let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
    }
    
    func setupGlobalEventTap() {
        print("🔍 WindowSwitcher: Attempting to setup global event tap...")
        // We need to capture Option (flags) and Tab (keydown).
        // Since we want to suppress the system Alt-Tab, we need an active tap.
        
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        // Retrieve the C-function pointer for the callback
        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) in
            // Unsafe bitcast to get the instance back
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let viewModel = Unmanaged<WindowSwitcherViewModel>.fromOpaque(refcon).takeUnretainedValue()
            return viewModel.handleEvent(proxy: proxy, type: type, event: event)
        }
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: selfPointer
        ) else {
            print("❌ WindowSwitcher: Failed to create event tap. Check accessibility permissions.")
            return
        }
        
        print("✅ WindowSwitcher: Event tap created successfully")
        
        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    
    // Core Logic
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // print("🔍 WindowSwitcher: Event received type: \(type.rawValue)")
        
        if type == .tapDisabledByTimeout {
            print("⚠️ WindowSwitcher: Event tap disabled by timeout - re-enabling")
            CGEvent.tapEnable(tap: eventTap!, enable: true)
            return Unmanaged.passUnretained(event)
        }
        
        if type == .tapDisabledByUserInput {
            print("⚠️ WindowSwitcher: Event tap disabled by user input - re-enabling")
            CGEvent.tapEnable(tap: eventTap!, enable: true)
            return Unmanaged.passUnretained(event)
        }
        
        if type == .flagsChanged {
            let flags = event.flags
            let isOptionPressed = flags.contains(.maskAlternate)
            // print("WindowSwitcher: Flags changed. Option: \(isOptionPressed)")
            
            DispatchQueue.main.async {
                self.handleModifierChange(isOptionPressed: isOptionPressed)
            }
            
            // If we are active, we might want to swallow the Option-up event to prevent system menu trigger if needed?
            // Usually we let flags pass through unless we are strictly swallowing everything.
            // But for Alt-Tab logic, KeyDown is the trigger.
            return Unmanaged.passUnretained(event)
        }
        
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            
            // Tab is 48
            if keyCode == 48 {
                let flags = event.flags
                let isOptionPressed = flags.contains(.maskAlternate)
                let isShiftPressed = flags.contains(.maskShift)
                
                if isOptionPressed {
                    // This is Option+Tab
                    print("🔥 WindowSwitcher: Option+Tab detected!")
                    DispatchQueue.main.async {
                        self.handleTab(isShift: isShiftPressed)
                    }
                    // Swallow the event!
                    return nil
                }
            }
            
            // While Active/Navigating, we want to capture Arrows and Escape
            // Escape is 53
            if keyCode == 53 {
                if state == .active || state == .navigating {
                    DispatchQueue.main.async {
                        self.cancelSwitcher()
                    }
                    return nil
                }
            }
            
            // Left Arrow (123) or 'h' (4)
            if keyCode == 123 || keyCode == 4 {
                if state == .active || state == .navigating {
                    DispatchQueue.main.async {
                        self.navigate(direction: -1)
                    }
                    return nil
                }
            }
            
            // Right Arrow (124) or 'l' (37)
            if keyCode == 124 || keyCode == 37 {
                if state == .active || state == .navigating {
                    DispatchQueue.main.async {
                        self.navigate(direction: 1)
                    }
                    return nil
                }
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    // MARK: - State Machine Actions
    
    private func handleModifierChange(isOptionPressed: Bool) {
        if isOptionPressed {
            // Option pressed. Attempt to transition from Idle?
            // Usually we wait for Tab to transition to Active.
            // But if we are in Active/Navigating and Option is released, we Commit.
        } else {
            // Option Released
            if state == .active || state == .navigating {
                commitSelection()
            }
        }
    }
    
    private func handleTab(isShift: Bool) {
        if state == .idle {
            activateSwitcher()
        } else if state == .active || state == .navigating {
            navigate(direction: isShift ? -1 : 1)
        }
    }
    
    private func activateSwitcher() {
        print("🔍 WindowSwitcher: activateSwitcher called")
        self.windows = discoveryService.fetchWindows()
        print("🔍 WindowSwitcher: Found \(windows.count) windows")
        
        guard !windows.isEmpty else {
            print("⚠️ WindowSwitcher: No windows found, aborting activation")
            return
        }
        
        // Select the second window (MRU) if available, otherwise first
        // If only 1 window, select it.
        // If >1 window: index 0 is usually current app (if not filtered) or the most recent one.
        // If we filtered out "Self", then index 0 is the previous app.
        // System Alt-Tab starts at index 1 usually (current app is 0).
        // BUT our discovery excludes "Self".
        // So index 0 is the "Previous App".
        // If we are currently IN an app, and we press Alt-Tab, we want to go to the PREVIOUS app (Index 1 in system list, but Index 0 in our filtered list?).
        // Let's assume standard behavior:
        // App A is focused. App B is behind.
        // User hits Alt-Tab.
        // Current App A is usually excluded from the list? Or included at the end?
        // Standard Alt-Tab: Shows All apps. Highlight is on 2nd item (index 1).
        // Our requirements: "Select the 2nd window in the list (Most Recently Used)."
        
        // Re-reading Filter: "Exclude the switcher app's own PID." (Tachyon).
        // So the "Current App" (e.g. Chrome) IS in the list.
        // Logic:
        // If currently focused app is in the list, it's at index 0.
        // Use `selectedIndex = 1` to switch to previous.
        
        if windows.count > 1 {
            selectedIndex = 1
        } else {
            selectedIndex = 0
        }
        
        state = .active
        // Show Window (handled by View/Controller binding to state)
    }
    
    private func navigate(direction: Int) {
        state = .navigating
        var nextIndex = selectedIndex + direction
        if nextIndex >= windows.count { nextIndex = 0 }
        if nextIndex < 0 { nextIndex = windows.count - 1 }
        
        print("🔍 WindowSwitcher: Navigation \(selectedIndex) -> \(nextIndex)")
        selectedIndex = nextIndex
    }
    
    private func commitSelection() {
        state = .committing
        if let window = selectedWindow {
            AccessibilityHelpers.focusWindow(window)
        }
        
        // Reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.state = .idle
            self.windows = []
        }
    }
    private func cancelSwitcher() {
        print("❌ WindowSwitcher: Cancelled")
        state = .idle
        windows = []
    }
}
