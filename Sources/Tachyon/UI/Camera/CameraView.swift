import SwiftUI
import AVFoundation

/// Main camera view displaying live camera preview with actions
/// Follows Tachyon's premium dark design language
struct CameraView: View {
    @ObservedObject var cameraService: CameraService
    let onClose: () -> Void
    
    @State private var showActionsMenu = false
    @State private var showSavePanel = false
    @State private var capturedPhoto: NSImage?
    @State private var showPhotoFlash = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content with preview
            ZStack {
                // Camera preview or placeholder
                if cameraService.isRunning {
                    CameraPreviewRepresentable(
                        session: cameraService.captureSession,
                        isMirrored: cameraService.isMirrored
                    )
                    .clipped()
                } else {
                    // Loading or permission denied state
                    cameraPlaceholder
                }
                
                // Back button overlay (top-left)
                VStack {
                    HStack {
                        backButton
                        Spacer()
                    }
                    .padding(16)
                    Spacer()
                }
                
                // Photo flash effect
                if showPhotoFlash {
                    Color.white
                        .opacity(0.8)
                        .animation(.easeOut(duration: 0.1), value: showPhotoFlash)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Status bar (bottom)
            statusBar
        }
        .frame(width: 680, height: 480)
        .background(Color(hex: "#1C1C1E"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .onAppear {
            startCamera()
        }
        .onDisappear {
            // CRITICAL: Always stop camera session when view disappears
            cameraService.stopSession()
        }
        .onExitCommand {
            closeCamera()
        }
        // Keyboard shortcuts
        .background(
            KeyboardShortcutHandler(
                onEnter: takePhoto,
                onCommandK: { showActionsMenu = true },
                onEscape: closeCamera
            )
        )
        .alert("Camera Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        // Actions menu popover
        .overlay(
            actionsMenuOverlay
        )
        // Listen for flash trigger from window-level keyboard handler
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CameraFlash"))) { _ in
            // Flash effect
            withAnimation(.easeIn(duration: 0.05)) {
                showPhotoFlash = true
            }
            // Remove flash after brief moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.1)) {
                    showPhotoFlash = false
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var backButton: some View {
        Button(action: closeCamera) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .help("Close camera (Escape)")
    }
    
    private var cameraPlaceholder: some View {
        VStack(spacing: 16) {
            if cameraService.permissionStatus == .denied {
                Image(systemName: "camera.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.4))
                Text("Camera Access Required")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Enable camera access in System Settings > Privacy & Security > Camera")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                Button("Open System Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                Text("Starting camera...")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#1C1C1E"))
    }
    
    private var statusBar: some View {
        HStack {
            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(cameraService.isRunning ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(cameraService.isRunning ? "Opened camera" : "Starting...")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 16) {
                // Switch Camera button
                if cameraService.availableCameras.count > 1 {
                    Button(action: { cameraService.cycleCamera() }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Switch Camera")
                }

                // Take Photo button
                Button(action: takePhoto) {
                    HStack(spacing: 6) {
                        Text("Take Photo")
                            .font(.system(size: 13, weight: .medium))
                        Text("⏎")
                            .font(.system(size: 11))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(4)
                    }
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .disabled(!cameraService.isRunning)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(hex: "#252525"))
    }
    
    @ViewBuilder
    private var actionsMenuOverlay: some View {
        if showActionsMenu {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    showActionsMenu = false
                }
            
            VStack(spacing: 0) {
                CameraActionsMenu(
                    cameraService: cameraService,
                    capturedPhoto: capturedPhoto,
                    onDismiss: { showActionsMenu = false },
                    onSavePhoto: savePhotoWithPicker,
                    onCopyPhoto: copyPhoto
                )
            }
            .frame(width: 280)
            .background(Color(hex: "#2C2C2E"))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
        }
    }
    
    // MARK: - Actions
    
    private func startCamera() {
        Task {
            do {
                try await cameraService.startSession()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func closeCamera() {
        // CRITICAL: Stop camera session before closing
        cameraService.stopSession()
        onClose()
    }
    
    private func takePhoto() {
        guard cameraService.isRunning else { return }
        
        Task {
            do {
                // Flash effect
                withAnimation(.easeIn(duration: 0.05)) {
                    showPhotoFlash = true
                }
                
                let photo = try await cameraService.capturePhoto()
                capturedPhoto = photo
                
                // Remove flash
                try? await Task.sleep(nanoseconds: 100_000_000)
                withAnimation(.easeOut(duration: 0.1)) {
                    showPhotoFlash = false
                }
                
                // Auto-save to default location
                let savedURL = try cameraService.savePhoto(photo)
                
                // Show notification
                NotificationCenter.default.post(
                    name: NSNotification.Name("UpdateStatusBar"),
                    object: ("📸", "Photo saved to \(savedURL.lastPathComponent)")
                )
            } catch {
                showPhotoFlash = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func savePhotoWithPicker() {
        guard let photo = capturedPhoto ?? cameraService.lastCapturedPhoto else {
            errorMessage = "No photo to save. Take a photo first."
            showError = true
            return
        }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "Tachyon_Photo_\(Date().timeIntervalSince1970).png"
        panel.directoryURL = cameraService.defaultSaveLocation
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    _ = try cameraService.savePhoto(photo, to: url)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("UpdateStatusBar"),
                        object: ("📸", "Photo saved to \(url.lastPathComponent)")
                    )
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            showActionsMenu = false
        }
    }
    
    private func copyPhoto() {
        if let photo = capturedPhoto ?? cameraService.lastCapturedPhoto {
            cameraService.copyPhotoToClipboard(photo)
            NotificationCenter.default.post(
                name: NSNotification.Name("UpdateStatusBar"),
                object: ("📋", "Photo copied to clipboard")
            )
        } else {
            // Take photo first, then copy
            Task {
                do {
                    let photo = try await cameraService.capturePhoto()
                    cameraService.copyPhotoToClipboard(photo)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("UpdateStatusBar"),
                        object: ("📋", "Photo captured and copied to clipboard")
                    )
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
        showActionsMenu = false
    }
}

// MARK: - Keyboard Shortcut Handler

private struct KeyboardShortcutHandler: NSViewRepresentable {
    let onEnter: () -> Void
    let onCommandK: () -> Void
    let onEscape: () -> Void
    
    func makeNSView(context: Context) -> CameraKeyEventCapture {
        let view = CameraKeyEventCapture()
        view.onKeyDown = { event in
            let hasCommand = event.modifierFlags.contains(.command)
            
            switch event.keyCode {
            case 36: // Enter
                onEnter()
                return true
            case 40 where hasCommand: // K
                onCommandK()
                return true
            case 53: // Escape
                onEscape()
                return true
            default:
                return false
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: CameraKeyEventCapture, context: Context) {}
}
