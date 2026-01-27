import SwiftUI

struct DefaultTheme: Theme {
    let id = ThemeType.default.id
    let name = ThemeType.default.name
    
    // MARK: - Window
    let windowBackgroundColor = Color(hex: "#1a1a1a")
    let windowBorderColor = Color.white.opacity(0.08)
    let windowCornerRadius: CGFloat = 12
    
    var windowBackgroundGradient: AnyView? {
        AnyView(
            ZStack {
                // Dark gradient background
                LinearGradient(
                    colors: [
                        Color(hex: "#1a1a1a"),
                        Color(hex: "#1f1f1f")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Subtle blue glow at top
                RadialGradient(
                    colors: [
                        Color(hex: "#3B86F7").opacity(0.05),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 300
                )
            }
        )
    }
    
    // MARK: - Search Field
    let searchFieldBackgroundColor = Color.clear
    let searchFieldTextColor = Color.white
    let searchFieldPlaceholderColor = Color.white.opacity(0.4)
    let searchIconColor = Color(hex: "#3B86F7")
    
    // MARK: - Results
    let resultRowBackgroundColor = Color.clear
    let resultRowSelectedBackgroundColor = Color(hex: "#3B86F7").opacity(0.15)
    
    let resultRowTextColor = Color.white
    let resultRowSelectedTextColor = Color.white
    
    let resultRowSubtextColor = Color.white.opacity(0.6)
    let resultRowSelectedSubtextColor = Color.white.opacity(0.8)
    
    let resultIconColor = Color.white.opacity(0.6)
    let resultSelectedIconColor = Color.white
    
    // MARK: - Status Bar
    let statusBarBackgroundColor = Color.clear
    let statusBarTextColor = Color.white.opacity(0.5)
    
    // MARK: - Common
    let accentColor = Color(hex: "#3B86F7")
    let separatorColor = Color.white.opacity(0.08)
}
