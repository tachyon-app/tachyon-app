import Foundation

/// Settings for the focus mode glowing border
public struct FocusBorderSettings: Codable, Equatable {
    public var isEnabled: Bool
    public var color: BorderColor
    public var thickness: BorderThickness
    
    public init(
        isEnabled: Bool = false,
        color: BorderColor = .blue,
        thickness: BorderThickness = .medium
    ) {
        self.isEnabled = isEnabled
        self.color = color
        self.thickness = thickness
    }
    
    // Legacy support for colorHex
    public var colorHex: String {
        color.hex
    }
}

/// Predefined colors for the focus border
public enum BorderColor: String, Codable, CaseIterable, Identifiable {
    case blue = "Blue"
    case purple = "Purple"
    case pink = "Pink"
    case red = "Red"
    case orange = "Orange"
    case yellow = "Yellow"
    case green = "Green"
    case cyan = "Cyan"
    case white = "White"
    
    public var id: String { rawValue }
    
    public var hex: String {
        switch self {
        case .blue: return "#007AFF"
        case .purple: return "#AF52DE"
        case .pink: return "#FF2D55"
        case .red: return "#FF3B30"
        case .orange: return "#FF9500"
        case .yellow: return "#FFCC00"
        case .green: return "#34C759"
        case .cyan: return "#5AC8FA"
        case .white: return "#FFFFFF"
        }
    }
}

/// Thickness options for the focus border
public enum BorderThickness: String, Codable, CaseIterable {
    case thin = "Thin"
    case medium = "Medium"
    case thick = "Thick"
    
    /// Pixel width for each thickness
    public var pixelWidth: CGFloat {
        switch self {
        case .thin: return 4
        case .medium: return 8
        case .thick: return 12
        }
    }
}
