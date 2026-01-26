import SwiftUI
import AVFoundation

/// Actions menu for camera view, accessible via ⌘K
/// Provides camera controls: mirror, switch camera, save, copy
struct CameraActionsMenu: View {
    @ObservedObject var cameraService: CameraService
    let capturedPhoto: NSImage?
    let onDismiss: () -> Void
    let onSavePhoto: () -> Void
    let onCopyPhoto: () -> Void
    
    @State private var selectedIndex = 0
    
    private var actions: [CameraAction] {
        var items: [CameraAction] = [
            CameraAction(
                id: "mirror",
                title: cameraService.isMirrored ? "Disable Mirror" : "Enable Mirror",
                subtitle: "Flip video horizontally",
                icon: "arrow.left.and.right.righttriangle.left.righttriangle.right",
                shortcut: "M"
            ),
        ]
        
        // Camera switching (only if multiple cameras)
        if cameraService.availableCameras.count > 1 {
            items.append(CameraAction(
                id: "switch",
                title: "Switch Camera",
                subtitle: cameraService.currentCamera?.localizedName ?? "Select camera",
                icon: "arrow.triangle.2.circlepath.camera",
                shortcut: "S"
            ))
        }
        
        // Photo actions
        if capturedPhoto != nil || cameraService.lastCapturedPhoto != nil {
            items.append(CameraAction(
                id: "save",
                title: "Save Photo to...",
                subtitle: "Choose where to save",
                icon: "square.and.arrow.down",
                shortcut: "⌘S"
            ))
            
            items.append(CameraAction(
                id: "copy",
                title: "Copy Photo",
                subtitle: "Copy to clipboard",
                icon: "doc.on.clipboard",
                shortcut: "⌘C"
            ))
        }
        
        items.append(CameraAction(
            id: "settings",
            title: "Set Default Save Location",
            subtitle: cameraService.defaultSaveLocation.path,
            icon: "folder",
            shortcut: nil
        ))
        
        return items
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Actions")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Action items
            VStack(spacing: 2) {
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    actionRow(action: action, isSelected: index == selectedIndex)
                        .onTapGesture {
                            executeAction(action)
                        }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            
            // Camera list (if switching)
            if actions.contains(where: { $0.id == "switch" }) {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                VStack(spacing: 2) {
                    ForEach(cameraService.availableCameras, id: \.uniqueID) { camera in
                        cameraRow(camera: camera)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
            }
        }
        .background(
            CameraKeyboardNavigationHandler(
                itemCount: actions.count,
                selectedIndex: $selectedIndex,
                onSelect: { executeAction(actions[selectedIndex]) },
                onDismiss: onDismiss
            )
        )
    }
    
    private func actionRow(action: CameraAction, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: action.icon)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(action.title)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                if let subtitle = action.subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if let shortcut = action.shortcut {
                Text(shortcut)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue.opacity(0.4) : Color.clear)
        .cornerRadius(6)
    }
    
    private func cameraRow(camera: AVCaptureDevice) -> some View {
        HStack(spacing: 12) {
            Image(systemName: camera.uniqueID == cameraService.currentCamera?.uniqueID ? "checkmark" : "camera")
                .font(.system(size: 14))
                .foregroundColor(camera.uniqueID == cameraService.currentCamera?.uniqueID ? .blue : .white.opacity(0.5))
                .frame(width: 20)
            
            Text(camera.localizedName)
                .font(.system(size: 13))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.clear)
        .cornerRadius(6)
        .onTapGesture {
            cameraService.switchCamera(to: camera)
            onDismiss()
        }
    }
    
    private func executeAction(_ action: CameraAction) {
        switch action.id {
        case "mirror":
            cameraService.toggleMirror()
            onDismiss()
        case "switch":
            // Switch submenu is shown below
            break
        case "save":
            onSavePhoto()
        case "copy":
            onCopyPhoto()
        case "settings":
            setDefaultSaveLocation()
        default:
            break
        }
    }
    
    private func setDefaultSaveLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = cameraService.defaultSaveLocation
        panel.prompt = "Set as Default"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                cameraService.defaultSaveLocation = url
            }
            onDismiss()
        }
    }
}

// MARK: - Supporting Types

private struct CameraAction: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let icon: String
    let shortcut: String?
    
    init(id: String, title: String, subtitle: String? = nil, icon: String, shortcut: String?) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.shortcut = shortcut
    }
}

// MARK: - Keyboard Navigation Handler

private struct CameraKeyboardNavigationHandler: NSViewRepresentable {
    let itemCount: Int
    @Binding var selectedIndex: Int
    let onSelect: () -> Void
    let onDismiss: () -> Void
    
    func makeNSView(context: Context) -> CameraKeyEventCapture {
        let view = CameraKeyEventCapture()
        view.onKeyDown = { event in
            switch event.keyCode {
            case 126: // Up arrow
                if selectedIndex > 0 {
                    selectedIndex -= 1
                }
                return true
            case 125: // Down arrow
                if selectedIndex < itemCount - 1 {
                    selectedIndex += 1
                }
                return true
            case 36: // Enter
                onSelect()
                return true
            case 53: // Escape
                onDismiss()
                return true
            default:
                return false
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: CameraKeyEventCapture, context: Context) {}
}
