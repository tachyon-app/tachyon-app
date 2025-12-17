import Foundation

public struct KeyCodeMapper {
    /// Format a keyboard shortcut for display
    public static func format(keyCode: UInt32, modifiers: UInt32) -> String {
        var result = ""
        
        // Add modifiers
        if modifiers & 256 != 0 { // cmdKey
            result += "⌘"
        }
        if modifiers & 2048 != 0 { // optionKey
            result += "⌥"
        }
        if modifiers & 4096 != 0 { // controlKey
            result += "⌃"
        }
        if modifiers & 512 != 0 { // shiftKey
            result += "⇧"
        }
        
        // Add key symbol
        result += symbol(for: keyCode)
        
        return result
    }
    
    /// Get symbol for key code
    public static func symbol(for keyCode: UInt32) -> String {
        switch keyCode {
        // Arrow keys
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
            
        // Letters
        case 0: return "A"
        case 2: return "D"
        case 3: return "F"
        case 5: return "G"
        case 8: return "C"
        case 14: return "E"
        case 17: return "T"
        case 32: return "U"
        case 34: return "I"
        case 36: return "↩"  // Return
        case 38: return "J"
        case 40: return "K"
            
        default: return "?"
        }
    }
    
    /// Check if key code is valid
    public static func isValid(_ keyCode: UInt32) -> Bool {
        // Key codes 0-127 are valid (0 is 'A' key)
        return keyCode < 128
    }
}
