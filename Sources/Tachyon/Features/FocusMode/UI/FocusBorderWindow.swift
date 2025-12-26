import AppKit
import QuartzCore

/// Controller for focus border windows on all monitors
public class FocusBorderWindowController {
    
    public static let shared = FocusBorderWindowController()
    
    private var windows: [NSWindow] = []
    
    private init() {}
    
    /// Show gradient border on all screens
    public func show(settings: FocusBorderSettings) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.hideInternal()
            
            for screen in NSScreen.screens {
                if let window = self.createWindow(for: screen, settings: settings) {
                    self.windows.append(window)
                    window.orderFrontRegardless()
                }
            }
        }
    }
    
    /// Hide all border windows
    public func hide() {
        DispatchQueue.main.async { [weak self] in
            self?.hideInternal()
        }
    }
    
    private func hideInternal() {
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
    }
    
    // MARK: - Window Creation
    
    private func createWindow(for screen: NSScreen, settings: FocusBorderSettings) -> NSWindow? {
        let frame = screen.frame
        
        let window = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: true
        )
        
        window.level = .screenSaver // Higher level to appear above menu bar
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.hasShadow = false
        window.isReleasedWhenClosed = false
        
        // Container view
        let containerView = NSView(frame: NSRect(origin: .zero, size: frame.size))
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.clear.cgColor
        
        // Add glow effect layers
        setupGlowingBorder(in: containerView.layer!, settings: settings, size: frame.size)
        
        window.contentView = containerView
        return window
    }
    
    private func setupGlowingBorder(in parentLayer: CALayer, settings: FocusBorderSettings, size: NSSize) {
        let color = parseColor(settings.colorHex)
        
        // Glow depth based on thickness setting
        let glowDepth: CGFloat
        switch settings.thickness {
        case .thin:
            glowDepth = 10
        case .medium:
            glowDepth = 30
        case .thick:
            glowDepth = 50
        }
        
        let bounds = CGRect(origin: .zero, size: size)
        
        // Create gradient layers for each edge - color at screen edge fading inward
        
        // Top edge - gradient starts at screen top (bright) fades downward (transparent)
        let topGradient = CAGradientLayer()
        topGradient.frame = CGRect(x: 0, y: bounds.height - glowDepth, width: bounds.width, height: glowDepth)
        topGradient.colors = [
            color,                          // Bright at top edge
            color.copy(alpha: 0.7)!,
            color.copy(alpha: 0.4)!,
            color.copy(alpha: 0.15)!,
            color.copy(alpha: 0)!           // Fade to transparent toward center
        ]
        topGradient.locations = [0.0, 0.25, 0.5, 0.75, 1.0]
        topGradient.startPoint = CGPoint(x: 0.5, y: 1)  // Start at top (screen edge)
        topGradient.endPoint = CGPoint(x: 0.5, y: 0)    // Fade downward (toward center)
        parentLayer.addSublayer(topGradient)
        
        // Bottom edge - gradient starts at screen bottom (bright) fades upward (transparent)
        let bottomGradient = CAGradientLayer()
        bottomGradient.frame = CGRect(x: 0, y: 0, width: bounds.width, height: glowDepth)
        bottomGradient.colors = [
            color,
            color.copy(alpha: 0.7)!,
            color.copy(alpha: 0.4)!,
            color.copy(alpha: 0.15)!,
            color.copy(alpha: 0)!
        ]
        bottomGradient.locations = [0.0, 0.25, 0.5, 0.75, 1.0]
        bottomGradient.startPoint = CGPoint(x: 0.5, y: 0)  // Start at bottom (screen edge)
        bottomGradient.endPoint = CGPoint(x: 0.5, y: 1)    // Fade upward (toward center)
        parentLayer.addSublayer(bottomGradient)
        
        // Left edge - gradient starts at screen left (bright) fades rightward (transparent)
        let leftGradient = CAGradientLayer()
        leftGradient.frame = CGRect(x: 0, y: 0, width: glowDepth, height: bounds.height)
        leftGradient.colors = [
            color,
            color.copy(alpha: 0.7)!,
            color.copy(alpha: 0.4)!,
            color.copy(alpha: 0.15)!,
            color.copy(alpha: 0)!
        ]
        leftGradient.locations = [0.0, 0.25, 0.5, 0.75, 1.0]
        leftGradient.startPoint = CGPoint(x: 0, y: 0.5)    // Start at left (screen edge)
        leftGradient.endPoint = CGPoint(x: 1, y: 0.5)      // Fade rightward (toward center)
        parentLayer.addSublayer(leftGradient)
        
        // Right edge - gradient starts at screen right (bright) fades leftward (transparent)
        let rightGradient = CAGradientLayer()
        rightGradient.frame = CGRect(x: bounds.width - glowDepth, y: 0, width: glowDepth, height: bounds.height)
        rightGradient.colors = [
            color,
            color.copy(alpha: 0.7)!,
            color.copy(alpha: 0.4)!,
            color.copy(alpha: 0.15)!,
            color.copy(alpha: 0)!
        ]
        rightGradient.locations = [0.0, 0.25, 0.5, 0.75, 1.0]
        rightGradient.startPoint = CGPoint(x: 1, y: 0.5)   // Start at right (screen edge)
        rightGradient.endPoint = CGPoint(x: 0, y: 0.5)     // Fade leftward (toward center)
        parentLayer.addSublayer(rightGradient)
    }
    
    private func parseColor(_ hex: String) -> CGColor {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        
        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)
        
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        
        return CGColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
