import AppKit
import SwiftUI

/// Custom notification window that appears like a macOS notification banner
public class FocusCompletionNotification {
    
    private static var window: NSWindow?
    
    /// Show completion notification
    public static func show(goal: String?) {
        DispatchQueue.main.async {
            hideExisting()
            
            // Play sound
            if let sound = NSSound(named: "Glass") {
                sound.play()
            }
            
            // Get screen
            guard let screen = NSScreen.main else { return }
            
            // Create notification view
            let notificationView = FocusCompletionView(goal: goal)
            let hostingView = NSHostingView(rootView: notificationView)
            
            // Position in top-right (like macOS notifications)
            let windowWidth: CGFloat = 320
            let windowHeight: CGFloat = 72
            let padding: CGFloat = 16
            
            let origin = NSPoint(
                x: screen.visibleFrame.maxX - windowWidth - padding,
                y: screen.visibleFrame.maxY - windowHeight - padding
            )
            
            // Create borderless window
            let window = NSWindow(
                contentRect: NSRect(origin: origin, size: NSSize(width: windowWidth, height: windowHeight)),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            window.level = .floating
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = true
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .transient]
            window.isReleasedWhenClosed = false
            
            window.contentView = hostingView
            
            // Animate in
            window.alphaValue = 0
            window.orderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                window.animator().alphaValue = 1
            }
            
            self.window = window
            
            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                dismiss()
            }
        }
    }
    
    private static func hideExisting() {
        window?.orderOut(nil)
        window = nil
    }
    
    public static func dismiss() {
        guard let window = window else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
            self.window = nil
        })
    }
}

// MARK: - Notification View

struct FocusCompletionView: View {
    let goal: String?
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.green)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text("Focus session completed")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(goal ?? "You stayed focused.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Close button (visible on hover)
            if isHovering {
                Button(action: {
                    FocusCompletionNotification.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.black.opacity(0.4))
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            FocusCompletionNotification.dismiss()
        }
    }
}
