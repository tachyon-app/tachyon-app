import AppKit
import SwiftUI
import Combine

/// Controller for the focus timer status bar item (shown when minimized)
public class FocusStatusBarController {
    
    public static let shared = FocusStatusBarController()
    
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Observe manager changes
        FocusModeManager.shared.$currentSession
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemIfVisible()
            }
            .store(in: &cancellables)
    }
    
    /// Show the status bar timer
    public func show() {
        guard statusItem == nil else { return }
        
        // Create status item with variable length for timer + progress
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            
            // Configure custom view
            updateStatusItemView()
        }
        
        // Start timer for updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStatusItemView()
        }
    }
    
    /// Hide the status bar timer
    public func hide() {
        updateTimer?.invalidate()
        updateTimer = nil
        
        popover?.close()
        popover = nil
        
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }
    
    /// Update the status item's display
    private func updateStatusItemIfVisible() {
        guard statusItem != nil else { return }
        updateStatusItemView()
    }
    
    private func updateStatusItemView() {
        guard let button = statusItem?.button else { return }
        
        // Get current session info
        let manager = FocusModeManager.shared
        guard let session = manager.currentSession else {
            hide()
            return
        }
        
        // Calculate time string
        let remaining = session.remainingTime
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        let timeString = String(format: "%02d:%02d", minutes, seconds)
        
        // Get progress color
        let progressColor: NSColor
        if manager.borderSettings.isEnabled {
            progressColor = NSColor(hex: manager.borderSettings.color.hex)
        } else {
            progressColor = NSColor(hex: "#5AC8FA") // Default cyan
        }
        
        // Create attributed string with timer
        let attributed = NSMutableAttributedString()
        
        // Timer text
        let timerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        attributed.append(NSAttributedString(string: timeString, attributes: timerAttrs))
        
        // Add progress indicator (simple dots)
        let progress = session.progress
        let filledDots = Int(progress * 5)
        let emptyDots = 5 - filledDots
        
        let dotAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8),
            .foregroundColor: progressColor
        ]
        let emptyDotAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8),
            .foregroundColor: NSColor.white.withAlphaComponent(0.3)
        ]
        
        attributed.append(NSAttributedString(string: " ", attributes: timerAttrs))
        attributed.append(NSAttributedString(string: String(repeating: "●", count: filledDots), attributes: dotAttrs))
        attributed.append(NSAttributedString(string: String(repeating: "●", count: emptyDots), attributes: emptyDotAttrs))
        
        // Ellipsis for menu indicator
        attributed.append(NSAttributedString(string: " ⋯", attributes: [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.white.withAlphaComponent(0.5)
        ]))
        
        button.attributedTitle = attributed
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        if popover?.isShown == true {
            popover?.close()
        } else {
            showPopover()
        }
    }
    
    private func showPopover() {
        guard let button = statusItem?.button else { return }
        
        // Close existing popover
        popover?.close()
        
        // Create popover with menu content
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 260, height: 280)
        popover.behavior = .transient
        popover.animates = true
        
        let menuView = FocusStatusBarMenuView()
            .environmentObject(FocusModeManager.shared)
        popover.contentViewController = NSHostingController(rootView: menuView)
        
        self.popover = popover
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}

// MARK: - Status Bar Menu View

struct FocusStatusBarMenuView: View {
    @EnvironmentObject var manager: FocusModeManager
    
    var remainingTimeString: String {
        guard let session = manager.currentSession else { return "00:00" }
        let remaining = session.remainingTime
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var durationString: String {
        guard let session = manager.currentSession else { return "" }
        let minutes = Int(session.duration) / 60
        return "\(minutes) minutes"
    }
    
    var progressValue: Double {
        manager.currentSession?.progress ?? 0
    }
    
    var progressColor: Color {
        if manager.borderSettings.isEnabled {
            return Color(hex: manager.borderSettings.color.hex)
        } else {
            return Color(hex: "#5AC8FA")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with session info
            VStack(alignment: .leading, spacing: 4) {
                Text(manager.currentSession?.goal ?? "Focus Session")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(durationString)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(progressColor)
                            .frame(width: geometry.size.width * progressValue, height: 6)
                    }
                }
                .frame(height: 6)
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Action buttons
            VStack(spacing: 0) {
                FocusMenuButton(
                    title: "Complete",
                    systemImage: "checkmark.circle",
                    action: {
                        manager.completeSession()
                        FocusStatusBarController.shared.hide()
                        FocusBarWindowController.shared.hide()
                    }
                )
                
                if manager.currentSession?.state == .paused {
                    FocusMenuButton(
                        title: "Resume",
                        systemImage: "play.circle",
                        action: {
                            manager.resumeSession()
                        }
                    )
                } else {
                    FocusMenuButton(
                        title: "Pause",
                        systemImage: "pause.circle",
                        action: {
                            manager.pauseSession()
                        }
                    )
                }
                
                FocusMenuButton(
                    title: "Cancel",
                    systemImage: "xmark.circle",
                    action: {
                        manager.stopSession()
                        FocusStatusBarController.shared.hide()
                        FocusBarWindowController.shared.hide()
                    }
                )
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Detach option
            FocusMenuButton(
                title: "Detach from Menu Bar",
                systemImage: "arrow.down.left.and.arrow.up.right",
                action: {
                    FocusStatusBarController.shared.hide()
                    FocusBarWindowController.shared.restore()
                }
            )
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Menu Button

struct FocusMenuButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isHovering ? Color.white.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - NSColor Hex Extension

extension NSColor {
    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        
        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)
        
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
