import SwiftUI
import TachyonCore

/// Settings view section for managing Tachyon Scenes
struct ScenesSettingsSection: View {
    @ObservedObject var viewModel: ScenesSettingsViewModel
    @State private var showLayoutDesigner = false
    @State private var sceneToEdit: WindowScene?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("SCENES")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(0.6)
                
                Spacer()
                
                Button(action: { 
                    sceneToEdit = nil
                    showLayoutDesigner = true 
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Create Scene")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "#3B86F7"))
                }
                .buttonStyle(.plain)
            }
            
            // Activation message
            if let message = viewModel.activationMessage {
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(message.hasPrefix("✅") ? .green : 
                                   message.hasPrefix("⚠️") ? .yellow : .red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(6)
            }
            
            // Scenes List
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if viewModel.scenes.isEmpty {
                EmptyScenesView()
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.scenes) { scene in
                        SceneRow(
                            scene: scene,
                            onActivate: { viewModel.activateScene(scene) },
                            onDelete: { viewModel.deleteScene(scene) },
                            onEdit: {
                                sceneToEdit = scene
                            },
                            onUpdateShortcut: { keyCode, modifiers in
                                viewModel.updateShortcut(scene, keyCode: keyCode, modifiers: modifiers)
                            },
                            onClearShortcut: { viewModel.clearShortcut(scene) }
                        )
                    }
                }
            }
        }
        // Sheet for creating new layout
        .sheet(isPresented: $showLayoutDesigner) {
            LayoutDesignerView(isPresented: $showLayoutDesigner, sceneToEdit: nil)
        }
        // Sheet for editing existing layout (uses item: to properly pass the scene)
        .sheet(item: $sceneToEdit) { scene in
            LayoutDesignerSheetWrapper(scene: scene, onDismiss: { sceneToEdit = nil })
        }
    }
}

/// Wrapper to properly pass scene to LayoutDesignerView
struct LayoutDesignerSheetWrapper: View {
    let scene: WindowScene
    let onDismiss: () -> Void
    @State private var isPresented = true
    
    var body: some View {
        LayoutDesignerView(isPresented: $isPresented, sceneToEdit: scene)
            .onChange(of: isPresented) { newValue in
                if !newValue {
                    onDismiss()
                }
            }
    }
}

/// Empty state view for scenes
struct EmptyScenesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 32))
                .foregroundColor(Color.white.opacity(0.2))
            
            Text("No scenes recorded")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.white.opacity(0.5))
            
            Text("Record your first scene to save and recall window layouts")
                .font(.system(size: 12))
                .foregroundColor(Color.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(hex: "#1e1e1e"))
        .cornerRadius(8)
    }
}

/// Individual scene row
struct SceneRow: View {
    let scene: WindowScene
    let onActivate: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onUpdateShortcut: (UInt32, UInt32) -> Void
    let onClearShortcut: () -> Void
    
    @State private var isHovered = false
    @State private var isRecordingShortcut = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Scene icon
            Image(systemName: scene.isFullWorkspace ? "rectangle.3.group.fill" : "display")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#3B86F7"))
                .frame(width: 32)
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(scene.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(scene.isEnabled ? 0.85 : 0.4))
                
                Text(sceneDescription)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
            
            // Shortcut badge/recorder
            if isRecordingShortcut {
                SceneShortcutRecorderView(
                    isRecording: $isRecordingShortcut,
                    onShortcutRecorded: { keyCode, modifiers in
                        onUpdateShortcut(keyCode, modifiers)
                    }
                )
                .frame(width: 120, height: 28)
            } else if let shortcutString = scene.shortcutString {
                Button(action: { isRecordingShortcut = true }) {
                    Text(shortcutString)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#252525"))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Change Shortcut") { isRecordingShortcut = true }
                    Button("Clear Shortcut", role: .destructive) { onClearShortcut() }
                }
            } else {
                Button(action: { isRecordingShortcut = true }) {
                    Text("Set Shortcut")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .opacity(isHovered ? 1 : 0)
            }
            
            // Activate button
            Button(action: onActivate) {
                Image(systemName: "play.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
            .help("Activate this scene")
            
            // Edit button (opens full designer)
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0)
            .help("Edit layout")
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "#1e1e1e"))
        .cornerRadius(6)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private var sceneDescription: String {
        let displayText = scene.isFullWorkspace ? "Full Workspace" : "Display \(scene.targetDisplayIndex! + 1)"
        return "\(displayText) • \(scene.displayCount) display\(scene.displayCount == 1 ? "" : "s")"
    }
}

/// Shortcut recorder view for scenes - uses local event monitor for key capture
struct SceneShortcutRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    let onShortcutRecorded: (UInt32, UInt32) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isRecording: $isRecording, onShortcutRecorded: onShortcutRecorded)
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.stringValue = "Press shortcut..."
        field.isEditable = false
        field.isSelectable = false
        field.isBordered = true
        field.backgroundColor = NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 0.2)
        field.textColor = NSColor.white.withAlphaComponent(0.5)
        field.font = NSFont.systemFont(ofSize: 12)
        field.alignment = .center
        field.bezelStyle = .roundedBezel
        field.focusRingType = .none
        
        // Start monitoring when view appears
        context.coordinator.startMonitoring()
        
        return field
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        // Update coordinator bindings
        context.coordinator.isRecording = $isRecording
        context.coordinator.onShortcutRecorded = onShortcutRecorded
    }
    
    static func dismantleNSView(_ nsView: NSTextField, coordinator: Coordinator) {
        coordinator.stopMonitoring()
    }
    
    class Coordinator {
        var isRecording: Binding<Bool>
        var onShortcutRecorded: (UInt32, UInt32) -> Void
        var localMonitor: Any?
        
        init(isRecording: Binding<Bool>, onShortcutRecorded: @escaping (UInt32, UInt32) -> Void) {
            self.isRecording = isRecording
            self.onShortcutRecorded = onShortcutRecorded
        }
        
        func startMonitoring() {
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self = self else { return event }
                
                let keyCode = event.keyCode
                
                // Escape cancels
                if keyCode == 53 {
                    DispatchQueue.main.async {
                        self.isRecording.wrappedValue = false
                    }
                    return nil
                }
                
                // Build modifiers
                var modifiers: UInt32 = 0
                if event.modifierFlags.contains(.command) { modifiers |= 256 }
                if event.modifierFlags.contains(.shift) { modifiers |= 512 }
                if event.modifierFlags.contains(.option) { modifiers |= 2048 }
                if event.modifierFlags.contains(.control) { modifiers |= 4096 }
                
                // Require at least one modifier
                if modifiers > 0 {
                    DispatchQueue.main.async {
                        self.onShortcutRecorded(UInt32(keyCode), modifiers)
                        self.isRecording.wrappedValue = false
                    }
                    return nil // Consume the event
                }
                
                return event
            }
        }
        
        func stopMonitoring() {
            if let monitor = localMonitor {
                NSEvent.removeMonitor(monitor)
                localMonitor = nil
            }
        }
        
        deinit {
            stopMonitoring()
        }
    }
}
