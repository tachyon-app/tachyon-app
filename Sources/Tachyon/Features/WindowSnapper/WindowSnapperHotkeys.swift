import Foundation
import Carbon

/// Default keyboard shortcuts for window snapping (Rectangle-compatible)
public struct WindowSnapperHotkeys {
    
    /// Hotkey configuration for a window action
    public struct HotkeyConfig {
        public let action: WindowAction
        public let keyCode: UInt32
        public let modifiers: UInt32
        public let displayName: String
        
        public init(action: WindowAction, keyCode: UInt32, modifiers: UInt32, displayName: String) {
            self.action = action
            self.keyCode = keyCode
            self.modifiers = modifiers
            self.displayName = displayName
        }
    }
    
    /// All default hotkey configurations
    public static let defaults: [HotkeyConfig] = [
        // Halves
        HotkeyConfig(
            action: .leftHalf,
            keyCode: UInt32(kVK_LeftArrow),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥←"
        ),
        HotkeyConfig(
            action: .rightHalf,
            keyCode: UInt32(kVK_RightArrow),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥→"
        ),
        HotkeyConfig(
            action: .topHalf,
            keyCode: UInt32(kVK_UpArrow),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥↑"
        ),
        HotkeyConfig(
            action: .bottomHalf,
            keyCode: UInt32(kVK_DownArrow),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥↓"
        ),
        
        // Cycle Quarters
        HotkeyConfig(
            action: .cycleQuarters,
            keyCode: UInt32(kVK_ANSI_4),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥4"
        ),
        
        // Cycle Three-Quarters
        HotkeyConfig(
            action: .cycleThreeQuarters,
            keyCode: UInt32(kVK_ANSI_Q),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥Q"
        ),
        
        // Cycle Thirds
        HotkeyConfig(
            action: .cycleThirds,
            keyCode: UInt32(kVK_ANSI_3),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥3"
        ),
        
        // Cycle Two-Thirds
        HotkeyConfig(
            action: .cycleTwoThirds,
            keyCode: UInt32(kVK_ANSI_T),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥T"
        ),
        
        // Maximize & Center
        HotkeyConfig(
            action: .maximize,
            keyCode: UInt32(kVK_Return),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥↵"
        ),
        HotkeyConfig(
            action: .center,
            keyCode: UInt32(kVK_ANSI_C),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥C"
        ),
        
        // Multi-display
        HotkeyConfig(
            action: .nextDisplay,
            keyCode: UInt32(kVK_RightArrow),
            modifiers: UInt32(controlKey | optionKey | cmdKey),
            displayName: "⌃⌥⌘→"
        ),
        HotkeyConfig(
            action: .previousDisplay,
            keyCode: UInt32(kVK_LeftArrow),
            modifiers: UInt32(controlKey | optionKey | cmdKey),
            displayName: "⌃⌥⌘←"
        ),
    ]
    
    /// Get hotkey config for a specific action
    public static func config(for action: WindowAction) -> HotkeyConfig? {
        return defaults.first { $0.action == action }
    }
}
