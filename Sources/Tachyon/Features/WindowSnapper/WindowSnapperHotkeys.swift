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
        
        // Quarters
        HotkeyConfig(
            action: .topLeftQuarter,
            keyCode: UInt32(kVK_ANSI_U),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥U"
        ),
        HotkeyConfig(
            action: .topRightQuarter,
            keyCode: UInt32(kVK_ANSI_I),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥I"
        ),
        HotkeyConfig(
            action: .bottomLeftQuarter,
            keyCode: UInt32(kVK_ANSI_J),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥J"
        ),
        HotkeyConfig(
            action: .bottomRightQuarter,
            keyCode: UInt32(kVK_ANSI_K),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥K"
        ),
        
        // Three Quarters
        HotkeyConfig(
            action: .firstThreeQuarters,
            keyCode: UInt32(kVK_LeftArrow),
            modifiers: UInt32(controlKey | optionKey | shiftKey),
            displayName: "⌃⌥⇧←"
        ),
        HotkeyConfig(
            action: .lastThreeQuarters,
            keyCode: UInt32(kVK_RightArrow),
            modifiers: UInt32(controlKey | optionKey | shiftKey),
            displayName: "⌃⌥⇧→"
        ),
        
        // Thirds
        HotkeyConfig(
            action: .firstThird,
            keyCode: UInt32(kVK_ANSI_D),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥D"
        ),
        HotkeyConfig(
            action: .centerThird,
            keyCode: UInt32(kVK_ANSI_F),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥F"
        ),
        HotkeyConfig(
            action: .lastThird,
            keyCode: UInt32(kVK_ANSI_G),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥G"
        ),
        
        // Two Thirds
        HotkeyConfig(
            action: .firstTwoThirds,
            keyCode: UInt32(kVK_ANSI_E),
            modifiers: UInt32(controlKey | optionKey),
            displayName: "⌃⌥E"
        ),
        HotkeyConfig(
            action: .lastTwoThirds,
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
