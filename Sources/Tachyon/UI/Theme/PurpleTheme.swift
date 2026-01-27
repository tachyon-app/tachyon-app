import SwiftUI

struct PurpleTheme: Theme {
    let id = ThemeType.purple.id
    let name = ThemeType.purple.rawValue
    
    // MARK: - Window
    let windowBackgroundColor = Color(hex: "#2D1B69")
    let windowBorderColor = Color(hex: "#8F80D1").opacity(0.3)
    let windowCornerRadius: CGFloat = 20
    
    var windowBackgroundGradient: AnyView? {
        AnyView(
            ZStack(alignment: .top) {
                // Deep purple gradient
                LinearGradient(
                    colors: [
                        Color(hex: "#2D1B69"),
                        Color(hex: "#1A0F3C")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Glassy overlay
                Color.white.opacity(0.05)
                
                // Top highlight
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
            }
        )
    }
    
    // MARK: - Search Field
    let searchFieldBackgroundColor = Color.black.opacity(0.2)
    let searchFieldTextColor = Color.white
    let searchFieldPlaceholderColor = Color.white.opacity(0.5)
    let searchIconColor = Color(hex: "#D450E6") // Pinkish purple
    
    // MARK: - Results
    let resultRowBackgroundColor = Color.clear
    let resultRowSelectedBackgroundColor = Color(hex: "#5E17EB").opacity(0.3)
    
    let resultRowTextColor = Color.white
    let resultRowSelectedTextColor = Color.white
    
    let resultRowSubtextColor = Color(hex: "#B8B8D0")
    let resultRowSelectedSubtextColor = Color.white.opacity(0.9)
    
    let resultIconColor = Color(hex: "#B8B8D0")
    let resultSelectedIconColor = Color(hex: "#D450E6")
    
    // MARK: - Status Bar
    let statusBarBackgroundColor = Color.black.opacity(0.2)
    let statusBarTextColor = Color(hex: "#B8B8D0")
    
    // MARK: - Common
    let accentColor = Color(hex: "#D450E6")
    let separatorColor = Color.white.opacity(0.1)
}
