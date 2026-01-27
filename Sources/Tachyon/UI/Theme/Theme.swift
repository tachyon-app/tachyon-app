import SwiftUI

/// Defines the color palette and styling for the app
protocol Theme {
    var id: String { get }
    var name: String { get }
    
    // MARK: - Window
    var windowBackgroundColor: Color { get }
    var windowBorderColor: Color { get }
    var windowCornerRadius: CGFloat { get }
    var windowWidth: CGFloat { get }
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

extension Theme {
    var windowWidth: CGFloat { 680 }
}

struct ThemeType: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let isCustom: Bool
    
    static let `default` = ThemeType(id: "Default", name: "Default", isCustom: false)
    
    static var allStandard: [ThemeType] = [.default]
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
    
    // Store loaded custom themes: [ID: Theme]
    private var customThemes: [String: CodableTheme] = [:]
    @Published var availableThemes: [ThemeType] = ThemeType.allStandard
    
    private init() {
        // Load custom themes first
        let loadedThemes = ThemeManager.loadCustomThemes()
        var themesMap: [String: CodableTheme] = [:]
        var themeTypes: [ThemeType] = ThemeType.allStandard
        
        for theme in loadedThemes {
            themesMap[theme.id] = theme
            themeTypes.append(ThemeType(id: theme.id, name: theme.name, isCustom: true))
        }
        
        self.customThemes = themesMap
        self.availableThemes = themeTypes
        
        // Load saved theme
        let savedThemeId = UserDefaults.standard.string(forKey: "SelectedThemeId") ?? ThemeType.default.id
        
        // Find matching theme type
        var initialThemeType: ThemeType = .default
        if let match = themeTypes.first(where: { $0.id == savedThemeId }) {
            initialThemeType = match
        }
        
        self.activeThemeType = initialThemeType
        
        // Set initial theme instance
        if initialThemeType.id == ThemeType.default.id {
            self.currentTheme = DefaultTheme()
        // Removed hardcoded PurpleTheme
        } else if let customTheme = themesMap[initialThemeType.id] {
            self.currentTheme = customTheme
        } else {
            self.currentTheme = DefaultTheme()
        }
    }
    
    func reloadThemes() {
        print("🔄 Reloading themes...")
        let loadedThemes = ThemeManager.loadCustomThemes()
        var themesMap: [String: CodableTheme] = [:]
        var themeTypes: [ThemeType] = ThemeType.allStandard
        
        for theme in loadedThemes {
            themesMap[theme.id] = theme
            themeTypes.append(ThemeType(id: theme.id, name: theme.name, isCustom: true))
        }
        
        self.customThemes = themesMap
        self.availableThemes = themeTypes
        
        // If current theme was removed, revert to default
        if !themeTypes.contains(where: { $0.id == self.activeThemeType.id }) {
            self.activeThemeType = .default
        } else {
            // Re-apply current theme to ensure any changes are picked up
            updateTheme()
        }
        print("✅ Reloaded \(loadedThemes.count) custom themes")
    }
    
    private static func loadCustomThemes() -> [CodableTheme] {
        let files = ThemeFileManager.shared.listThemeFiles()
        var themes: [CodableTheme] = []
        
        for url in files {
            do {
                let theme = try ThemeFileManager.shared.loadTheme(from: url)
                themes.append(theme)
                print("🎨 Loaded theme: \(theme.name) (\(theme.id))")
            } catch {
                print("⚠️ Failed to load theme at \(url.path): \(error)")
            }
        }
        
        return themes
    }
    
    func updateTheme() {
        if activeThemeType == .default {
            currentTheme = DefaultTheme()
        } else if let customTheme = customThemes[activeThemeType.id] {
            currentTheme = customTheme
        } else {
            print("⚠️ Unknown theme type: \(activeThemeType.id), falling back to default")
            currentTheme = DefaultTheme()
        }
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(activeThemeType.id, forKey: "SelectedThemeId")
    }
}

// MARK: - Codable Theme Support

struct CodableTheme: Theme, Codable {
    let id: String
    let name: String
    
    // MARK: - Window
    let windowBackgroundColorHex: String
    let windowBackgroundGradientColors: [String]?
    let windowBorderColorHex: String
    let windowCornerRadius: CGFloat
    let windowWidth: CGFloat // Protocol requirement
    
    // MARK: - Search Field
    let searchFieldBackgroundColorHex: String
    let searchFieldTextColorHex: String
    let searchFieldPlaceholderColorHex: String
    let searchIconColorHex: String
    
    // MARK: - Results
    let resultRowBackgroundColorHex: String
    let resultRowSelectedBackgroundColorHex: String
    let resultRowTextColorHex: String
    let resultRowSelectedTextColorHex: String
    let resultRowSubtextColorHex: String
    let resultRowSelectedSubtextColorHex: String
    let resultIconColorHex: String
    let resultSelectedIconColorHex: String
    
    // MARK: - Status Bar
    let statusBarBackgroundColorHex: String
    let statusBarTextColorHex: String
    
    // MARK: - Common
    let accentColorHex: String
    let separatorColorHex: String
    
    // MARK: - Theme Protocol Implementation
    
    var windowBackgroundColor: Color { Color(hex: windowBackgroundColorHex) }
    var windowBorderColor: Color { Color(hex: windowBorderColorHex) }
    
    var windowBackgroundGradient: AnyView? {
        if let hexColors = windowBackgroundGradientColors, !hexColors.isEmpty {
            let colors = hexColors.map { Color(hex: $0) }
            return AnyView(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        return nil // Fallback to background color
    }
    
    var searchFieldBackgroundColor: Color { Color(hex: searchFieldBackgroundColorHex) }
    var searchFieldTextColor: Color { Color(hex: searchFieldTextColorHex) }
    var searchFieldPlaceholderColor: Color { Color(hex: searchFieldPlaceholderColorHex) }
    var searchIconColor: Color { Color(hex: searchIconColorHex) }
    
    var resultRowBackgroundColor: Color { Color(hex: resultRowBackgroundColorHex) }
    var resultRowSelectedBackgroundColor: Color { Color(hex: resultRowSelectedBackgroundColorHex) }
    var resultRowTextColor: Color { Color(hex: resultRowTextColorHex) }
    var resultRowSelectedTextColor: Color { Color(hex: resultRowSelectedTextColorHex) }
    var resultRowSubtextColor: Color { Color(hex: resultRowSubtextColorHex) }
    var resultRowSelectedSubtextColor: Color { Color(hex: resultRowSelectedSubtextColorHex) }
    var resultIconColor: Color { Color(hex: resultIconColorHex) }
    var resultSelectedIconColor: Color { Color(hex: resultSelectedIconColorHex) }
    
    var statusBarBackgroundColor: Color { Color(hex: statusBarBackgroundColorHex) }
    var statusBarTextColor: Color { Color(hex: statusBarTextColorHex) }
    
    var accentColor: Color { Color(hex: accentColorHex) }
    var separatorColor: Color { Color(hex: separatorColorHex) }
    
    // Coding Keys to map JSON keys to struct properties
    enum CodingKeys: String, CodingKey {
        case id, name
        case windowBackgroundColor, windowBackgroundGradientColors, windowBorderColor, windowCornerRadius, windowWidth
        case searchFieldBackgroundColor, searchFieldTextColor, searchFieldPlaceholderColor, searchIconColor
        case resultRowBackgroundColor, resultRowSelectedBackgroundColor, resultRowTextColor, resultRowSelectedTextColor
        case resultRowSubtextColor, resultRowSelectedSubtextColor, resultIconColor, resultSelectedIconColor
        case statusBarBackgroundColor, statusBarTextColor
        case accentColor, separatorColor
    }
    
    // Custom decoding to map JSON keys directly to Hex properties
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        windowBackgroundColorHex = try container.decode(String.self, forKey: .windowBackgroundColor)
        windowBackgroundGradientColors = try container.decodeIfPresent([String].self, forKey: .windowBackgroundGradientColors)
        windowBorderColorHex = try container.decode(String.self, forKey: .windowBorderColor)
        windowCornerRadius = try container.decode(CGFloat.self, forKey: .windowCornerRadius)
        windowWidth = try container.decodeIfPresent(CGFloat.self, forKey: .windowWidth) ?? 680 // Default width if missing
        
        searchFieldBackgroundColorHex = try container.decode(String.self, forKey: .searchFieldBackgroundColor)
        searchFieldTextColorHex = try container.decode(String.self, forKey: .searchFieldTextColor)
        searchFieldPlaceholderColorHex = try container.decode(String.self, forKey: .searchFieldPlaceholderColor)
        searchIconColorHex = try container.decode(String.self, forKey: .searchIconColor)
        
        resultRowBackgroundColorHex = try container.decode(String.self, forKey: .resultRowBackgroundColor)
        resultRowSelectedBackgroundColorHex = try container.decode(String.self, forKey: .resultRowSelectedBackgroundColor)
        resultRowTextColorHex = try container.decode(String.self, forKey: .resultRowTextColor)
        resultRowSelectedTextColorHex = try container.decode(String.self, forKey: .resultRowSelectedTextColor)
        resultRowSubtextColorHex = try container.decode(String.self, forKey: .resultRowSubtextColor)
        resultRowSelectedSubtextColorHex = try container.decode(String.self, forKey: .resultRowSelectedSubtextColor)
        resultIconColorHex = try container.decode(String.self, forKey: .resultIconColor)
        resultSelectedIconColorHex = try container.decode(String.self, forKey: .resultSelectedIconColor)
        
        statusBarBackgroundColorHex = try container.decode(String.self, forKey: .statusBarBackgroundColor)
        statusBarTextColorHex = try container.decode(String.self, forKey: .statusBarTextColor)
        
        accentColorHex = try container.decode(String.self, forKey: .accentColor)
        separatorColorHex = try container.decode(String.self, forKey: .separatorColor)
    }
    
    // Encoding support (optional, but good for completeness)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        
        try container.encode(windowBackgroundColorHex, forKey: .windowBackgroundColor)
        try container.encode(windowBackgroundGradientColors, forKey: .windowBackgroundGradientColors)
        try container.encode(windowBorderColorHex, forKey: .windowBorderColor)
        try container.encode(windowCornerRadius, forKey: .windowCornerRadius)
        try container.encode(windowWidth, forKey: .windowWidth)
        
        try container.encode(searchFieldBackgroundColorHex, forKey: .searchFieldBackgroundColor)
        try container.encode(searchFieldTextColorHex, forKey: .searchFieldTextColor)
        try container.encode(searchFieldPlaceholderColorHex, forKey: .searchFieldPlaceholderColor)
        try container.encode(searchIconColorHex, forKey: .searchIconColor)
        
        try container.encode(resultRowBackgroundColorHex, forKey: .resultRowBackgroundColor)
        try container.encode(resultRowSelectedBackgroundColorHex, forKey: .resultRowSelectedBackgroundColor)
        try container.encode(resultRowTextColorHex, forKey: .resultRowTextColor)
        try container.encode(resultRowSelectedTextColorHex, forKey: .resultRowSelectedTextColor)
        try container.encode(resultRowSubtextColorHex, forKey: .resultRowSubtextColor)
        try container.encode(resultRowSelectedSubtextColorHex, forKey: .resultRowSelectedSubtextColor)
        try container.encode(resultIconColorHex, forKey: .resultIconColor)
        try container.encode(resultSelectedIconColorHex, forKey: .resultSelectedIconColor)
        
        try container.encode(statusBarBackgroundColorHex, forKey: .statusBarBackgroundColor)
        try container.encode(statusBarTextColorHex, forKey: .statusBarTextColor)
        
        try container.encode(accentColorHex, forKey: .accentColor)
        try container.encode(separatorColorHex, forKey: .separatorColor)
    }
}
