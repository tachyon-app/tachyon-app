import AppKit
import SwiftUI

/// Controller for the floating focus timer bar
public class FocusBarWindowController: ObservableObject {
    
    public static let shared = FocusBarWindowController()
    
    private var window: NSWindow?
    @Published public var isMinimized: Bool = false
    
    private init() {}
    
    /// Show the floating timer bar
    public func show() {
        if window != nil { return }
        
        let barView = FocusBarView()
        let hostingView = NSHostingView(rootView: barView.environmentObject(FocusModeManager.shared))
        
        // Get primary screen
        guard let screen = NSScreen.main else { return }
        
        // Position at bottom-right
        let windowSize = NSSize(width: 220, height: 70)
        let origin = NSPoint(
            x: screen.visibleFrame.maxX - windowSize.width - 20,
            y: screen.visibleFrame.minY + 20
        )
        
        // Use NSPanel for non-activating floating window
        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: windowSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.becomesKeyOnlyIfNeeded = true
        
        panel.contentView = hostingView
        panel.orderFront(nil)
        
        self.window = panel
        isMinimized = false
    }
    
    /// Hide the floating timer bar
    public func hide() {
        window?.close()
        window = nil
    }
    
    /// Minimize to menu bar
    public func minimize() {
        hide()
        isMinimized = true
        FocusStatusBarController.shared.show()
        
        // Save preference for future sessions
        FocusModeManager.shared.prefersStatusBar = true
        FocusModeManager.shared.saveSettings()
    }
    
    /// Restore from minimized state
    public func restore() {
        isMinimized = false
        FocusStatusBarController.shared.hide()
        show()
        
        // Save preference for future sessions
        FocusModeManager.shared.prefersStatusBar = false
        FocusModeManager.shared.saveSettings()
    }
}

/// SwiftUI view for the floating timer bar
struct FocusBarView: View {
    @EnvironmentObject var manager: FocusModeManager
    @State private var isHovering = false
    
    var remainingTimeString: String {
        guard let session = manager.currentSession else { return "00:00" }
        let remaining = session.remainingTime
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progressValue: Double {
        manager.currentSession?.progress ?? 0
    }
    
    /// Progress bar color - matches glow border if enabled, otherwise uses default cyan
    var progressColor: Color {
        if manager.borderSettings.isEnabled {
            return Color(hex: manager.borderSettings.color.hex)
        } else {
            return Color(hex: "#5AC8FA") // Default cyan
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Timer display
                VStack(alignment: .leading, spacing: 2) {
                    Text(remainingTimeString)
                        .font(.system(size: 28, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    if let goal = manager.currentSession?.goal, !goal.isEmpty {
                        Text(goal)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Control buttons (visible on hover)
                if isHovering {
                    HStack(spacing: 4) {
                        // Pause/Resume button
                        FocusBarButton(
                            systemName: manager.currentSession?.state == .paused ? "play.fill" : "pause.fill",
                            action: {
                                if manager.currentSession?.state == .paused {
                                    manager.resumeSession()
                                } else {
                                    manager.pauseSession()
                                }
                            }
                        )
                        
                        // Stop button
                        FocusBarButton(
                            systemName: "xmark",
                            action: {
                                manager.stopSession()
                                FocusBarWindowController.shared.hide()
                            }
                        )
                        
                        // Minimize button
                        FocusBarButton(
                            systemName: "minus",
                            action: {
                                FocusBarWindowController.shared.minimize()
                            }
                        )
                    }
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progressValue, height: 4)
                        .animation(.linear(duration: 0.5), value: progressValue)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.3))
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

/// Button with proper hit area for focus bar
struct FocusBarButton: View {
    let systemName: String
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isHovering ? Color.white.opacity(0.2) : Color.clear)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}
