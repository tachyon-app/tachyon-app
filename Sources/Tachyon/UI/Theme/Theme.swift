import SwiftUI

/// Defines the color palette and styling for the app
protocol Theme {
    var id: String { get }
    var name: String { get }
    
    // MARK: - Window
    var windowBackgroundColor: Color { get }
    var windowBorderColor: Color { get }
    var windowCornerRadius: CGFloat { get }
    var windowBackgroundGradient: AnyView? { get }
    
    // MARK: - Search Field
    var searchFieldBackgroundColor: Color { get }
    var searchFieldTextColor: Color { get }
    var searchFieldPlaceholderColor: Color { get }
    var searchIconColor: Color { get }
    
    // MARK: - Results
    var resultRowBackgroundColor: Color { get }
    var resultRowSelectedBackgroundColor: Color { get }
    var resultRowTextColor: Color { get }
    var resultRowSelectedTextColor: Color { get }
    var resultRowSubtextColor: Color { get }
    var resultRowSelectedSubtextColor: Color { get }
    var resultIconColor: Color { get }
    var resultSelectedIconColor: Color { get }
    
    // MARK: - Status Bar
    var statusBarBackgroundColor: Color { get }
    var statusBarTextColor: Color { get }
    
    // MARK: - Common
    var accentColor: Color { get }
    var separatorColor: Color { get }
}

enum ThemeType: String, CaseIterable, Identifiable {
    case `default` = "Default"
    case purple = "Purple"
    
    var id: String { rawValue }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: any Theme
    @Published var activeThemeType: ThemeType {
        didSet {
            updateTheme()
            saveTheme()
        }
    }
    
    private init() {
        // Load saved theme
        let savedThemeRaw = UserDefaults.standard.string(forKey: "SelectedTheme") ?? ThemeType.default.rawValue
        let themeType = ThemeType(rawValue: savedThemeRaw) ?? .default
        
        self.activeThemeType = themeType
        
        // Set initial theme instance
        switch themeType {
        case .default:
            self.currentTheme = DefaultTheme()
        case .purple:
            // Placeholder for now, avoids circular dependency before file creation
            self.currentTheme = DefaultTheme() 
        }
    }
    
    func updateTheme() {
        switch activeThemeType {
        case .default:
            currentTheme = DefaultTheme()
        case .purple:
             currentTheme = PurpleTheme()
        }
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(activeThemeType.rawValue, forKey: "SelectedTheme")
    }
}
