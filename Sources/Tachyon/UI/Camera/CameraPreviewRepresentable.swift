import SwiftUI
import AVFoundation

/// NSViewRepresentable wrapper for AVCaptureVideoPreviewLayer
/// Displays the live camera feed in SwiftUI
struct CameraPreviewRepresentable: NSViewRepresentable {
    let session: AVCaptureSession?
    let isMirrored: Bool
    
    func makeNSView(context: Context) -> CameraPreviewNSView {
        let view = CameraPreviewNSView()
        if let session = session {
            view.setupPreviewLayer(with: session)
        }
        return view
    }
    
    func updateNSView(_ nsView: CameraPreviewNSView, context: Context) {
        nsView.updateMirroring(isMirrored)
        
        // Update session if changed
        if let session = session, nsView.previewLayer?.session !== session {
            nsView.setupPreviewLayer(with: session)
        }
    }
}

/// Custom NSView that hosts the AVCaptureVideoPreviewLayer
class CameraPreviewNSView: NSView {
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }
    
    func setupPreviewLayer(with session: AVCaptureSession) {
        // Remove existing preview layer
        previewLayer?.removeFromSuperlayer()
        
        // Create new preview layer
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = bounds
        
        // Add to layer
        layer?.addSublayer(preview)
        previewLayer = preview
    }
    
    func updateMirroring(_ isMirrored: Bool) {
        guard let connection = previewLayer?.connection,
              connection.isVideoMirroringSupported else { return }
        
        connection.automaticallyAdjustsVideoMirroring = false
        connection.isVideoMirrored = isMirrored
    }
    
    override func layout() {
        super.layout()
        previewLayer?.frame = bounds
    }
    
    override var isFlipped: Bool {
        return true
    }
}
