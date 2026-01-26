import SwiftUI
import TachyonCore

/// Tab options for Window Snapping settings
enum WindowSnappingTab: String, CaseIterable {
    case shortcuts = "Shortcuts"
    case scenes = "Scenes"
}

/// Window Snapping settings view with customizable shortcuts and scenes tabs
struct WindowSnappingSettingsView: View {
    @StateObject private var viewModel = WindowSnappingSettingsViewModel()
    @StateObject private var scenesViewModel = ScenesSettingsViewModel()
    @State private var selectedTab: WindowSnappingTab = .shortcuts
    
    var body: some View {
        ScrollView {
            HStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 28) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Window Snapping")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(selectedTab == .shortcuts 
                                 ? "Customize keyboard shortcuts for window management" 
                                 : "Save and restore window layouts")
                                .font(.system(size: 13))
                                .foregroundColor(Color.white.opacity(0.55))
                        }
                        
                        Spacer()
                        
                        if selectedTab == .shortcuts {
                            Button("Reset to Defaults") {
                                viewModel.resetToDefaults()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                    
                    // Tab Picker
                    HStack(spacing: 0) {
                        ForEach(WindowSnappingTab.allCases, id: \.self) { tab in
                            Button(action: { selectedTab = tab }) {
                                VStack(spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: tab == .shortcuts ? "keyboard" : "rectangle.3.group")
                                            .font(.system(size: 13))
                                        Text(tab.rawValue)
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(selectedTab == tab ? Color(hex: "#3B86F7") : .white.opacity(0.5))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    
                                    // Underline indicator
                                    Rectangle()
                                        .fill(selectedTab == tab ? Color(hex: "#3B86F7") : Color.clear)
                                        .frame(height: 2)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .background(
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1)
                        }
                    )
                    
                    // Content based on selected tab
                    if selectedTab == .shortcuts {
                        shortcutsContent
                    } else {
                        ScenesSettingsSection(viewModel: scenesViewModel)
                    }
                }
                .frame(maxWidth: 700)
                
                Spacer()
            }
            .padding(.vertical, 40)
        }
        .onAppear {
            viewModel.loadShortcuts()
            scenesViewModel.loadScenes()
        }
    }
    
    @ViewBuilder
    private var shortcutsContent: some View {
        if viewModel.isLoading {
            ProgressView()
                .progressViewStyle(.circular)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 40)
        } else {
            VStack(spacing: 24) {
                ShortcutSection(
                    title: "Halves",
                    shortcuts: viewModel.halves,
                    onUpdate: viewModel.updateShortcut
                )
                
                ShortcutSection(
                    title: "Quarters",
                    shortcuts: viewModel.quarters,
                    onUpdate: viewModel.updateShortcut
                )
                
                ShortcutSection(
                    title: "Thirds",
                    shortcuts: viewModel.thirds,
                    onUpdate: viewModel.updateShortcut
                )
                
                ShortcutSection(
                    title: "Multi-Monitor",
                    shortcuts: viewModel.multiMonitor,
                    onUpdate: viewModel.updateShortcut
                )
                
                ShortcutSection(
                    title: "Other",
                    shortcuts: viewModel.other,
                    onUpdate: viewModel.updateShortcut
                )
            }
        }
    }
}

/// Section for a group of shortcuts
struct ShortcutSection: View {
    let title: String
    let shortcuts: [WindowSnappingShortcut]
    let onUpdate: (WindowSnappingShortcut) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.4))
                .textCase(.uppercase)
                .tracking(0.6)
            
            VStack(spacing: 8) {
                ForEach(shortcuts, id: \.id) { shortcut in
                    ShortcutRow(
                        shortcut: shortcut,
                        onUpdate: onUpdate
                    )
                }
            }
        }
    }
}

/// Individual shortcut row
struct ShortcutRow: View {
    let shortcut: WindowSnappingShortcut
    let onUpdate: (WindowSnappingShortcut) -> Void
    
    @State private var isRecording = false
    @State private var isEnabled: Bool
    @State private var isHovered = false
    @State private var conflictWarning: String?
    
    init(shortcut: WindowSnappingShortcut, onUpdate: @escaping (WindowSnappingShortcut) -> Void) {
        self.shortcut = shortcut
        self.onUpdate = onUpdate
        self._isEnabled = State(initialValue: shortcut.isEnabled)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 16) {
                // Action name
                Text(shortcut.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(isEnabled ? 0.85 : 0.4))
                    .frame(width: 200, alignment: .leading)
                
                Spacer()
                
                // Shortcut recorder button
                Button(action: {
                    conflictWarning = nil
                    isRecording = true
                    // Temporarily disable all window snapping hotkeys
                    NotificationCenter.default.post(
                        name: .windowSnappingRecordingStarted,
                        object: nil
                    )
                }) {
                    if isRecording {
                        Text("Press shortcut...")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(minWidth: 120)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    } else {
                        ShortcutBadge(shortcut: shortcut)
                            .opacity(isEnabled ? 1.0 : 0.4)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(isHovered ? Color.white.opacity(0.05) : Color.clear)
                            .cornerRadius(6)
                    }
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHovered = hovering && !isRecording
                }
                .background(
                    ShortcutRecorderView(
                        isRecording: $isRecording,
                        onShortcutRecorded: { keyCode, modifiers in
                            // Re-enable hotkeys
                            NotificationCenter.default.post(
                                name: .windowSnappingRecordingEnded,
                                object: nil
                            )
                            // Validate before updating
                            validateAndUpdate(keyCode: keyCode, modifiers: modifiers)
                        }
                    )
                )
                
                // Enable/Disable toggle
                Toggle("", isOn: $isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .onChange(of: isEnabled) { newValue in
                        var updated = shortcut
                        updated.isEnabled = newValue
                        onUpdate(updated)
                    }
            }
            
            // Conflict warning
            if let warning = conflictWarning {
                Text(warning)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .padding(.leading, 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "#1e1e1e"))
        .cornerRadius(6)
    }
    
    private func validateAndUpdate(keyCode: UInt32, modifiers: UInt32) {
        // Check if this combination is already used by another shortcut
        guard let dbQueue = StorageManager.shared.dbQueue else { return }
        let repository = WindowSnappingShortcutRepository(dbQueue: dbQueue)
        
        Task {
            do {
                let allShortcuts = try repository.fetchAll()
                
                // Check for conflicts (excluding self)
                let conflicts = allShortcuts.filter {
                    $0.keyCode == keyCode &&
                    $0.modifiers == modifiers &&
                    $0.id != shortcut.id
                }
                
                if let conflict = conflicts.first {
                    await MainActor.run {
                        // Close recording state
                        isRecording = false
                        
                        // Show confirmation dialog
                        let alert = NSAlert()
                        alert.messageText = "Shortcut Already in Use"
                        alert.informativeText = "This shortcut is already assigned to \"\(conflict.displayName)\".\n\nDo you want to reassign it to \"\(shortcut.displayName)\"?"
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: "Reassign")
                        alert.addButton(withTitle: "Cancel")
                        
                        let response = alert.runModal()
                        
                        if response == .alertFirstButtonReturn {
                            // User chose to reassign
                            // Clear the conflict's shortcut (set to 0,0 as disabled)
                            var clearedConflict = conflict
                            clearedConflict.keyCode = 0
                            clearedConflict.modifiers = 0
                            clearedConflict.isEnabled = false
                            
                            do {
                                try repository.update(clearedConflict)
                                
                                // Now update this shortcut
                                var updated = shortcut
                                updated.keyCode = keyCode
                                updated.modifiers = modifiers
                                try repository.update(updated)
                                
                                // Trigger reload
                                onUpdate(updated)
                                
                                conflictWarning = nil
                            } catch {
                                conflictWarning = "❌ Failed to update: \(error.localizedDescription)"
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    conflictWarning = nil
                                }
                            }
                        } else {
                            // User cancelled
                            conflictWarning = nil
                        }
                    }
                } else {
                    // No conflict, update directly
                    var updated = shortcut
                    updated.keyCode = keyCode
                    updated.modifiers = modifiers
                    await MainActor.run {
                        onUpdate(updated)
                        conflictWarning = nil
                    }
                }
            } catch {
                print("❌ Failed to validate shortcut: \(error)")
                await MainActor.run {
                    isRecording = false
                    conflictWarning = "❌ Error: \(error.localizedDescription)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        conflictWarning = nil
                    }
                }
            }
        }
    }
}

/// Hidden view that captures keyboard events when recording
struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    let onShortcutRecorded: (UInt32, UInt32) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyCaptureView()
        view.onKeyPress = { keyCode, modifiers in
            // Only record if we have modifiers (prevent recording just a letter)
            if modifiers > 0 {
                onShortcutRecorded(UInt32(keyCode), UInt32(modifiers))
                isRecording = false
            }
        }
        view.isRecording = { [weak view] in
            view?.isRecordingActive ?? false
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let keyView = nsView as? KeyCaptureView {
            keyView.isRecordingActive = isRecording
            if isRecording {
                // Make this view the first responder to capture keys
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }
}

/// NSView that captures keyboard events
class KeyCaptureView: NSView {
    var onKeyPress: ((UInt16, Int) -> Void)?
    var isRecording: (() -> Bool)?
    var isRecordingActive = false
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        guard isRecordingActive else {
            super.keyDown(with: event)
            return
        }
        
        let keyCode = event.keyCode
        var modifiers = 0
        
        // Convert NSEvent modifiers to Carbon modifiers
        if event.modifierFlags.contains(.command) {
            modifiers |= 256  // cmdKey
        }
        if event.modifierFlags.contains(.shift) {
            modifiers |= 512  // shiftKey
        }
        if event.modifierFlags.contains(.option) {
            modifiers |= 2048  // optionKey
        }
        if event.modifierFlags.contains(.control) {
            modifiers |= 4096  // controlKey
        }
        
        // Ignore Escape key (keyCode 53)
        if keyCode == 53 {
            isRecordingActive = false
            return
        }
        
        onKeyPress?(keyCode, modifiers)
    }
}

/// Visual representation of keyboard shortcut
struct ShortcutBadge: View {
    let shortcut: WindowSnappingShortcut
    
    var body: some View {
        HStack(spacing: 3) {
            // Modifier keys
            if hasControl {
                ModifierKey(symbol: "⌃")
            }
            if hasOption {
                ModifierKey(symbol: "⌥")
            }
            if hasCommand {
                ModifierKey(symbol: "⌘")
            }
            if hasShift {
                ModifierKey(symbol: "⇧")
            }
            
            // Key
            Text(KeyCodeMapper.symbol(for: shortcut.keyCode))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "#252525"))
                .cornerRadius(4)
        }
    }
    
    private var hasControl: Bool {
        shortcut.modifiers & 4096 != 0  // controlKey
    }
    
    private var hasOption: Bool {
        shortcut.modifiers & 2048 != 0  // optionKey
    }
    
    private var hasCommand: Bool {
        shortcut.modifiers & 256 != 0  // cmdKey
    }
    
    private var hasShift: Bool {
        shortcut.modifiers & 512 != 0  // shiftKey
    }
}

/// Modifier key badge
struct ModifierKey: View {
    let symbol: String
    
    var body: some View {
        Text(symbol)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white.opacity(0.7))
            .frame(width: 24, height: 24)
            .background(Color(hex: "#1e1e1e"))
            .cornerRadius(4)
    }
}

/// Secondary button style
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color(hex: "#252525"))
            .cornerRadius(6)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
