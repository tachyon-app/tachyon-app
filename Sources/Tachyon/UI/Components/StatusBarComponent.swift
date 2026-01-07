import SwiftUI

/// Persistent status bar component for search bar footer
struct StatusBarComponent: View {
    enum State {
        case hint(String)
        case scriptRunning(String)
        case scriptSuccess(String)
        case scriptError(String)
        
        var icon: String {
            switch self {
            case .hint: return "🚀"
            case .scriptRunning: return "⏳"
            case .scriptSuccess: return "✅"
            case .scriptError: return "❌"
            }
        }
        
        var message: String {
            switch self {
            case .hint(let msg),
                 .scriptRunning(let msg),
                 .scriptSuccess(let msg),
                 .scriptError(let msg):
                return msg
            }
        }
        
        var indicatorColor: Color {
            switch self {
            case .hint: return Color(hex: "#3B86F7")
            case .scriptRunning: return Color.orange
            case .scriptSuccess: return Color.green
            case .scriptError: return Color.red
            }
        }
    }
    
    let state: State
    let showActionButtons: Bool
    
    init(state: State, showActionButtons: Bool = true) {
        self.state = state
        self.showActionButtons = showActionButtons
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Left side: Icon and message
            HStack(spacing: 10) {
                // Indicator dot
                Circle()
                    .fill(state.indicatorColor)
                    .frame(width: 8, height: 8)
                
                // Message text
                Text(state.message)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Right side: Action buttons (Raycast-style)
            if showActionButtons {
                HStack(spacing: 16) {
                    // Enter hint
                    HStack(spacing: 6) {
                        Text("Open")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                        Text("↵")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(hex: "#3B86F7"))
                    }
                    
                    // Divider
                    Text("|")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.2))
                    
                    // Actions hint
                    HStack(spacing: 6) {
                        Text("Actions")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                        Text("⌘K")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(hex: "#3B86F7"))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.clear)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1),
            alignment: .top
        )
    }
}

#Preview {
    VStack(spacing: 0) {
        StatusBarComponent(state: .hint("Type to search apps and commands..."))
        StatusBarComponent(state: .scriptRunning("Executing script..."))
        StatusBarComponent(state: .scriptSuccess("Script completed successfully"))
        StatusBarComponent(state: .scriptError("Script failed with code 1"))
    }
    .frame(width: 680)
    .background(Color(hex: "#1a1a1a"))
}
