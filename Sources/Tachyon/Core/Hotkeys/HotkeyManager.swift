import Foundation
import Carbon

/// Manages global hotkey registration using Carbon APIs
public final class HotkeyManager {
    
    public static let shared = HotkeyManager()
    
    private var hotkeys: [HotkeyRegistration] = []
    private var eventHandler: EventHandlerRef?
    
    private init() {
        setupEventHandler()
    }
    
    deinit {
        cleanup()
    }
    
    /// Register a global hotkey
    /// - Parameters:
    ///   - keyCode: The key code (e.g., 123 for left arrow)
    ///   - modifiers: Modifier flags (cmdKey, optionKey, controlKey, shiftKey)
    ///   - handler: Closure to execute when hotkey is pressed
    /// - Returns: Registration ID for later unregistration
    @discardableResult
    public func register(
        keyCode: UInt32,
        modifiers: UInt32,
        handler: @escaping () -> Void
    ) -> UUID {
        let id = UUID()
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType("TACH".fourCharCodeValue)
        // Use magnitude to ensure positive value for UInt32
        hotKeyID.id = UInt32(truncatingIfNeeded: id.hashValue)
        
        var hotkeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
        
        guard status == noErr, let ref = hotkeyRef else {
            print("❌ Failed to register hotkey: keyCode=\(keyCode), modifiers=\(modifiers)")
            return id
        }
        
        let registration = HotkeyRegistration(
            id: id,
            keyCode: keyCode,
            modifiers: modifiers,
            hotkeyRef: ref,
            handler: handler
        )
        
        hotkeys.append(registration)
        
        print("✅ Registered hotkey: keyCode=\(keyCode), modifiers=\(modifiers)")
        
        return id
    }
    
    /// Unregister a hotkey by ID
    /// - Parameter id: The registration ID returned from register()
    public func unregister(_ id: UUID) {
        guard let index = hotkeys.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        let registration = hotkeys[index]
        UnregisterEventHotKey(registration.hotkeyRef)
        hotkeys.remove(at: index)
        
        print("✅ Unregistered hotkey: \(id)")
    }
    
    /// Unregister all hotkeys
    public func unregisterAll() {
        for registration in hotkeys {
            UnregisterEventHotKey(registration.hotkeyRef)
        }
        hotkeys.removeAll()
        
        print("✅ Unregistered all hotkeys")
    }
    
    // MARK: - Event Handling
    
    private func setupEventHandler() {
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                return manager.handleHotkeyEvent(event!)
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
    }
    
    private func handleHotkeyEvent(_ event: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        
        guard status == noErr else {
            return OSStatus(eventNotHandledErr)
        }
        
        // Find and execute the handler
        if let registration = hotkeys.first(where: { UInt32(truncatingIfNeeded: $0.id.hashValue) == hotKeyID.id }) {
            // Execute handler on main thread
            DispatchQueue.main.async {
                registration.handler()
            }
            return noErr
        }
        
        return OSStatus(eventNotHandledErr)
    }
    
    private func cleanup() {
        unregisterAll()
        
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }
}

// MARK: - Supporting Types

private struct HotkeyRegistration {
    let id: UUID
    let keyCode: UInt32
    let modifiers: UInt32
    let hotkeyRef: EventHotKeyRef
    let handler: () -> Void
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
