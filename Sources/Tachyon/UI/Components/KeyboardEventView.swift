import SwiftUI
import AppKit

/// A view that captures keyboard events and forwards them to closures
/// Compatible with macOS 13+
struct ClipboardKeyboardEventView: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Bool
    
    func makeNSView(context: Context) -> ClipboardKeyEventCapture {
        let view = ClipboardKeyEventCapture()
        view.onKeyDown = onKeyDown
        return view
    }
    
    func updateNSView(_ nsView: ClipboardKeyEventCapture, context: Context) {
        nsView.onKeyDown = onKeyDown
    }
}

/// Custom NSView that captures keyboard events for clipboard history
class ClipboardKeyEventCapture: NSView {
    var onKeyDown: ((NSEvent) -> Bool)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        if let handler = onKeyDown, handler(event) {
            return // Event was handled
        }
        super.keyDown(with: event)
    }
}

/// View modifier for handling keyboard events in clipboard history
struct ClipboardKeyboardModifier: ViewModifier {
    let onKeyDown: (NSEvent) -> Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                ClipboardKeyboardEventView(onKeyDown: onKeyDown)
                    .frame(width: 0, height: 0)
            )
    }
}

extension View {
    /// Add a keyboard event handler for clipboard history
    func onKeyboardEvent(_ handler: @escaping (NSEvent) -> Bool) -> some View {
        modifier(ClipboardKeyboardModifier(onKeyDown: handler))
    }
}

/// Key codes for common keys
enum KeyCode: UInt16 {
    case returnKey = 36
    case delete = 51
    case escape = 53
    case upArrow = 126
    case downArrow = 125
    case leftArrow = 123
    case rightArrow = 124
    case p = 35
    case v = 9
    case c = 8
}
