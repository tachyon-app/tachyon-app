import Foundation

/// Settings for the focus mode glowing border
public struct FocusBorderSettings: Codable, Equatable {
    public var isEnabled: Bool
    public var colorHex: String
    public var thickness: BorderThickness
    
    public init(
        isEnabled: Bool = false,
        colorHex: String = "#007AFF",
        thickness: BorderThickness = .medium
    ) {
        self.isEnabled = isEnabled
        self.colorHex = colorHex
        self.thickness = thickness
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
