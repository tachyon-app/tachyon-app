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
    }
    
    /// Restore from minimized state
    public func restore() {
        isMinimized = false
        show()
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
    
    var body: some View {
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
                HStack(spacing: 8) {
                    // Pause/Resume button
                    Button(action: {
                        if manager.currentSession?.state == .paused {
                            manager.resumeSession()
                        } else {
                            manager.pauseSession()
                        }
                    }) {
                        Image(systemName: manager.currentSession?.state == .paused ? "play.fill" : "pause.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    
                    // Stop button
                    Button(action: {
                        manager.stopSession()
                        FocusBarWindowController.shared.hide()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    
                    // Minimize button
                    Button(action: {
                        FocusBarWindowController.shared.minimize()
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
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
