import SwiftUI
import AppKit

/// Settings view for managing script commands
struct ScriptCommandsSettingsView: View {
    @StateObject private var viewModel = ScriptCommandsSettingsViewModel()
    @State private var showingAddSheet = false
    @State private var editingScript: ScriptRecord?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Add button
            HStack {
                Text("Script Commands")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showingAddSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Add Script")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#3B86F7"))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("n", modifiers: .command)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Scripts list
            if viewModel.scripts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "terminal")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No scripts yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Add your first script to get started")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.scripts) { script in
                            ScriptRowView(
                                script: script,
                                onEdit: { editingScript = script },
                                onDelete: { viewModel.deleteScript(script) },
                                onOpenInEditor: { viewModel.openScriptInEditor(script) },
                                onShowInFinder: { viewModel.showScriptInFinder(script) },
                                onToggleEnabled: { viewModel.toggleEnabled(script) },
                                onHotkeyChange: { hotkey in
                                    viewModel.updateHotkey(for: script, hotkey: hotkey)
                                }
                            )
                            
                            if script.id != viewModel.scripts.last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.05))
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(hex: "#1a1a1a"))
        .sheet(isPresented: $showingAddSheet) {
            AddEditScriptSheet(
                script: nil,
                onSave: { script in
                    viewModel.addScript(script)
                    showingAddSheet = false
                },
                onCancel: { showingAddSheet = false }
            )
        }
        .sheet(item: $editingScript) { script in
            AddEditScriptSheet(
                script: script,
                onSave: { updatedScript in
                    viewModel.updateScript(updatedScript)
                    editingScript = nil
                },
                onCancel: { editingScript = nil }
            )
        }
        .onAppear {
            viewModel.loadScripts()
        }
    }
}

/// Individual script row
struct ScriptRowView: View {
    let script: ScriptRecord
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onOpenInEditor: () -> Void
    let onShowInFinder: () -> Void
    let onToggleEnabled: () -> Void
    let onHotkeyChange: (String?) -> Void
    
    @State private var isRecordingHotkey = false
    @State private var showingContextMenu = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            if let iconData = script.icon, let nsImage = NSImage(data: iconData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .frame(width: 32, height: 32)
                    .cornerRadius(6)
            } else {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#3B86F7"))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(6)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(script.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(script.scriptMode.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    
                    if let packageName = script.packageName {
                        Text("·")
                            .foregroundColor(.white.opacity(0.3))
                        Text(packageName)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            
            Spacer()
            
            // Hotkey
            HotkeyRecorderView(
                hotkey: script.hotkey,
                isRecording: $isRecordingHotkey,
                onChange: onHotkeyChange
            )
            
            // Enabled toggle
            Toggle("", isOn: Binding(
                get: { script.isEnabled },
                set: { _ in onToggleEnabled() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            
            // Context menu button
            Menu {
                Button("Edit") { onEdit() }
                Button("Open in Editor") { onOpenInEditor() }
                Button("Show in Finder") { onShowInFinder() }
                Divider()
                Button("Delete", role: .destructive) { onDelete() }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 24, height: 24)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Edit") { onEdit() }
            Button("Open in Editor") { onOpenInEditor() }
            Button("Show in Finder") { onShowInFinder() }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}

/// Hotkey recorder component
struct HotkeyRecorderView: View {
    let hotkey: String?
    @Binding var isRecording: Bool
    let onChange: (String?) -> Void
    
    var body: some View {
        Button(action: { isRecording.toggle() }) {
            if isRecording {
                Text("Press keys...")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#3B86F7").opacity(0.3))
                    .cornerRadius(4)
            } else if let hotkey = hotkey {
                Text(hotkey)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(4)
            } else {
                Text("Record Hotkey")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(4)
            }
        }
        .buttonStyle(.plain)
    }
}

/// ViewModel for script commands settings
@MainActor
class ScriptCommandsSettingsViewModel: ObservableObject {
    @Published var scripts: [ScriptRecord] = []
    
    func loadScripts() {
        do {
            scripts = try StorageManager.shared.getAllScripts()
                .sorted { $0.title < $1.title }
        } catch {
            print("❌ Failed to load scripts: \(error)")
        }
    }
    
    func addScript(_ script: ScriptRecord) {
        do {
            try StorageManager.shared.saveScript(script)
            loadScripts()
        } catch {
            print("❌ Failed to save script: \(error)")
        }
    }
    
    func updateScript(_ script: ScriptRecord) {
        do {
            try StorageManager.shared.saveScript(script)
            loadScripts()
        } catch {
            print("❌ Failed to update script: \(error)")
        }
    }
    
    func deleteScript(_ script: ScriptRecord) {
        // Show confirmation dialog
        let alert = NSAlert()
        alert.messageText = "Delete \"\(script.title)\"?"
        alert.informativeText = "This will delete the script file and cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            do {
                try StorageManager.shared.deleteScript(id: script.id)
                try ScriptFileManager.shared.deleteScript(fileName: script.fileName)
                loadScripts()
            } catch {
                print("❌ Failed to delete script: \(error)")
            }
        }
    }
    
    func openScriptInEditor(_ script: ScriptRecord) {
        let fileURL = ScriptFileManager.shared.scriptURL(for: script.fileName)
        NSWorkspace.shared.open(fileURL)
    }
    
    func showScriptInFinder(_ script: ScriptRecord) {
        let fileURL = ScriptFileManager.shared.scriptURL(for: script.fileName)
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }
    
    func toggleEnabled(_ script: ScriptRecord) {
        var updatedScript = script
        updatedScript.isEnabled.toggle()
        updateScript(updatedScript)
    }
    
    func updateHotkey(for script: ScriptRecord, hotkey: String?) {
        var updatedScript = script
        updatedScript.hotkey = hotkey
        updateScript(updatedScript)
    }
}
