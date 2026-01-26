import SwiftUI
import AppKit

/// Custom NSView that captures keyboard events for camera views
class CameraKeyEventCapture: NSView {
    var onKeyDown: ((NSEvent) -> Bool)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        if let handler = onKeyDown, handler(event) {
            return // Event was handled
        }
        super.keyDown(with: event)
    }
}

/// A view that captures keyboard events for camera views
struct CameraKeyboardEventView: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Bool
    
    func makeNSView(context: Context) -> CameraKeyEventCapture {
        let view = CameraKeyEventCapture()
        view.onKeyDown = onKeyDown
        return view
    }
    
    func updateNSView(_ nsView: CameraKeyEventCapture, context: Context) {
        nsView.onKeyDown = onKeyDown
    }
}
