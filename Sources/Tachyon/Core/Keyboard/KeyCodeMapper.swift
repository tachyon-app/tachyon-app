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
        // Letters (A-Z)
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
            
        // Special keys
        case 36: return "↩"  // Return
        case 48: return "⇥"  // Tab
        case 49: return "␣"  // Space
        case 51: return "⌫"  // Delete
        case 53: return "⎋"  // Escape
            
        // Arrow keys
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
            
        // Function keys
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
            
        default: return "?"
        }
    }
    
    /// Check if key code is valid
    public static func isValid(_ keyCode: UInt32) -> Bool {
        // Key codes 0-127 are valid (0 is 'A' key)
        return keyCode < 128
    }
}
