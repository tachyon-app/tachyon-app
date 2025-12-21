import SwiftUI
import AppKit

/// Sheet for adding or editing a script (matching Raycast/Quicklink UI style)
struct AddEditScriptSheet: View {
    let script: ScriptRecord?
    let onSave: (ScriptRecord) -> Void
    let onCancel: () -> Void
    
    @State private var selectedTemplate: ScriptTemplate = .bash
    @State private var title: String = ""
    @State private var mode: ScriptMode = .fullOutput
    @State private var description: String = ""
    @State private var packageName: String = ""
    @State private var refreshTime: RefreshTimeOption = .none
    @State private var focusedField: Field? = nil
    @State private var hasAttemptedSave: Bool = false
    
    enum Field {
        case title, description, packageName
    }
    
    private var isEditing: Bool { script != nil }
    
    enum RefreshTimeOption: String, CaseIterable, Identifiable {
        case none = "None"
        case fiveMinutes = "5 Minutes"
        case tenMinutes = "10 Minutes"
        case thirtyMinutes = "30 Minutes"
        case oneHour = "1 Hour"
        case threeHours = "3 Hours"
        case sixHours = "6 Hours"
        case twelveHours = "12 Hours"
        case oneDay = "1 Day"
        
        var id: String { rawValue }
        
        var value: String? {
            switch self {
            case .none: return nil
            case .fiveMinutes: return "5m"
            case .tenMinutes: return "10m"
            case .thirtyMinutes: return "30m"
            case .oneHour: return "1h"
            case .threeHours: return "3h"
            case .sixHours: return "6h"
            case .twelveHours: return "12h"
            case .oneDay: return "1d"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onCancel) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {}) {
                    Text("Learn More")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.white.opacity(0.04))
            
            // Form content
            ScrollView {
                VStack(spacing: 24) {
                    // Template selection (only for new scripts)
                    if !isEditing {
                        HStack(alignment: .center, spacing: 16) {
                            Text("Template")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.5))
                                .frame(width: 90, alignment: .trailing)
                            
                            Picker("", selection: $selectedTemplate) {
                                ForEach(ScriptTemplate.allCases) { template in
                                    Text(template.rawValue).tag(template)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // Mode
                    HStack(alignment: .center, spacing: 16) {
                        Text("Mode")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.5))
                            .frame(width: 90, alignment: .trailing)
                        
                        Picker("", selection: $mode) {
                            ForEach(ScriptMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue.capitalized).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Title
                    HStack(alignment: .center, spacing: 16) {
                        Text("Title")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.5))
                            .frame(width: 90, alignment: .trailing)
                        
                        ZStack {
                            TextField("Command Title", text: $title, onEditingChanged: { editing in
                                withAnimation(.easeOut(duration: 0.15)) {
                                    if editing {
                                        focusedField = .title
                                    } else if focusedField == .title {
                                        focusedField = nil
                                    }
                                }
                            })
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Color(hex: "#1e1e1e"))
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(
                                        focusedField == .title ? Color.white.opacity(0.8) :
                                        (hasAttemptedSave && title.isEmpty ? Color.red.opacity(0.5) : Color.white.opacity(0.08)),
                                        lineWidth: focusedField == .title ? 1.5 : 0.5
                                    )
                            )
                        }
                    }
                    
                    // Description
                    HStack(alignment: .center, spacing: 16) {
                        Text("Description")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.5))
                            .frame(width: 90, alignment: .trailing)
                        
                        ZStack {
                            TextField("Descriptive summary", text: $description, onEditingChanged: { editing in
                                withAnimation(.easeOut(duration: 0.15)) {
                                    if editing {
                                        focusedField = .description
                                    } else if focusedField == .description {
                                        focusedField = nil
                                    }
                                }
                            })
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Color(hex: "#1e1e1e"))
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(
                                        focusedField == .description ? Color.white.opacity(0.8) : Color.white.opacity(0.08),
                                        lineWidth: focusedField == .description ? 1.5 : 0.5
                                    )
                            )
                        }
                    }
                    
                    // Package Name
                    HStack(alignment: .center, spacing: 16) {
                        Text("Package Name")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.5))
                            .frame(width: 90, alignment: .trailing)
                        
                        ZStack {
                            TextField("E.g., Developer Utils", text: $packageName, onEditingChanged: { editing in
                                withAnimation(.easeOut(duration: 0.15)) {
                                    if editing {
                                        focusedField = .packageName
                                    } else if focusedField == .packageName {
                                        focusedField = nil
                                    }
                                }
                            })
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Color(hex: "#1e1e1e"))
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(
                                        focusedField == .packageName ? Color.white.opacity(0.8) : Color.white.opacity(0.08),
                                        lineWidth: focusedField == .packageName ? 1.5 : 0.5
                                    )
                            )
                        }
                    }
                    
                    // Refresh Time
                    HStack(alignment: .center, spacing: 16) {
                        Text("Refresh Time")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.5))
                            .frame(width: 90, alignment: .trailing)
                        
                        Picker("", selection: $refreshTime) {
                            ForEach(RefreshTimeOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 50)
                .padding(.top, 32)
                .padding(.bottom, 20)
            }
            
            Spacer()
            
            Divider()
                .background(Color.white.opacity(0.04))
            
            // Bottom action bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "terminal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#3B86F7"))
                    
                    Text(isEditing ? "Edit Script Command" : "Create Script Command")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: {
                    hasAttemptedSave = true
                    handleSave()
                }) {
                    HStack(spacing: 6) {
                        Text(isEditing ? "Save Script" : "Create Script")
                            .font(.system(size: 13, weight: .medium))
                        
                        Text("⌘↵")
                            .font(.system(size: 10, weight: .medium))
                            .opacity(0.5)
                    }
                    .foregroundColor(canSave ? .white : Color.white.opacity(0.4))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(canSave ? Color(hex: "#3B86F7") : Color.white.opacity(0.04))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .frame(width: 700, height: 500)
        .background(Color(hex: "#161616"))
        .onAppear {
            if let script = script {
                loadScriptData(script)
            }
        }
        .background(
            Button("") {
                if canSave {
                    hasAttemptedSave = true
                    handleSave()
                }
            }
            .keyboardShortcut(.return, modifiers: .command)
            .hidden()
        )
    }
    
    private var canSave: Bool {
        !title.isEmpty
    }
    
    private func loadScriptData(_ script: ScriptRecord) {
        title = script.title
        mode = script.scriptMode
        description = ""
        packageName = script.packageName ?? ""
        
        // Map refresh time to option
        if let rt = script.refreshTime {
            refreshTime = RefreshTimeOption.allCases.first { $0.value == rt } ?? .none
        }
    }
    
    private func handleSave() {
        guard canSave else { return }
        
        if isEditing, let existingScript = script {
            // Update existing script
            var updatedScript = existingScript
            updatedScript.title = title
            updatedScript.scriptMode = mode
            updatedScript.packageName = packageName.isEmpty ? nil : packageName
            updatedScript.refreshTime = refreshTime.value
            
            onSave(updatedScript)
        } else {
            // Create new script from template
            do {
                // Generate script content
                let scriptContent = selectedTemplate.generateScript(
                    title: title,
                    mode: mode,
                    description: description.isEmpty ? nil : description,
                    packageName: packageName.isEmpty ? nil : packageName,
                    refreshTime: refreshTime.value
                )
                
                // Generate filename
                let fileName = ScriptTemplate.generateFileName(from: title, template: selectedTemplate)
                
                // Write script file
                let scriptURL = ScriptFileManager.shared.scriptURL(for: fileName)
                try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
                
                // Set executable permissions
                try FileManager.default.setAttributes(
                    [.posixPermissions: 0o755],
                    ofItemAtPath: scriptURL.path
                )
                
                // Create database record
                let newScript = ScriptRecord(
                    fileName: fileName,
                    title: title,
                    packageName: packageName.isEmpty ? nil : packageName,
                    mode: mode,
                    refreshTime: refreshTime.value
                )
                
                onSave(newScript)
            } catch {
                print("❌ Failed to create script: \(error)")
                // TODO: Show error alert
            }
        }
    }
}
