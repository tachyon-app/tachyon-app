import AppKit
import SwiftUI

/// Controller for focus border windows on all monitors
public class FocusBorderWindowController {
    
    public static let shared = FocusBorderWindowController()
    
    private var windows: [NSWindow] = []
    private var settings: FocusBorderSettings = FocusBorderSettings()
    
    private init() {}
    
    /// Show glowing border on all screens
    public func show(settings: FocusBorderSettings) {
        // Ensure we're on main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.show(settings: settings)
            }
            return
        }
        
        self.settings = settings
        hide() // Remove existing windows
        
        for screen in NSScreen.screens {
            let window = createBorderWindow(for: screen, settings: settings)
            windows.append(window)
            window.orderFront(nil)
        }
    }
    
    /// Hide all border windows
    public func hide() {
        // Ensure we're on main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.hide()
            }
            return
        }
        
        windows.forEach { $0.close() }
        windows.removeAll()
    }
    
    /// Update border settings
    public func updateSettings(_ settings: FocusBorderSettings) {
        self.settings = settings
        if !windows.isEmpty {
            show(settings: settings)
        }
    }
    
    // MARK: - Window Creation
    
    private func createBorderWindow(for screen: NSScreen, settings: FocusBorderSettings) -> NSWindow {
        let frame = screen.frame
        
        let window = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        window.level = .screenSaver // Above everything
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // Create simple border view using NSView instead of SwiftUI
        let borderView = BorderNSView(settings: settings)
        borderView.frame = NSRect(origin: .zero, size: frame.size)
        window.contentView = borderView
        
        return window
    }
}

/// Simple NSView for the glowing border (avoids SwiftUI hosting issues)
class BorderNSView: NSView {
    let settings: FocusBorderSettings
    
    init(settings: FocusBorderSettings) {
        self.settings = settings
        super.init(frame: .zero)
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        let borderWidth = settings.thickness.pixelWidth
        let color = NSColor(hexString: settings.colorHex)
        
        // Draw outer glow
        context.setStrokeColor(color.withAlphaComponent(0.6).cgColor)
        context.setLineWidth(borderWidth * 1.5)
        context.setShadow(offset: .zero, blur: borderWidth, color: color.cgColor)
        context.stroke(bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2))
        
        // Draw inner border
        context.setShadow(offset: .zero, blur: 0, color: nil)
        context.setStrokeColor(color.withAlphaComponent(0.9).cgColor)
        context.setLineWidth(borderWidth / 2)
        context.stroke(bounds.insetBy(dx: borderWidth / 4, dy: borderWidth / 4))
    }
}

// MARK: - NSColor Hex Extension

extension NSColor {
    convenience init(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }
        
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
