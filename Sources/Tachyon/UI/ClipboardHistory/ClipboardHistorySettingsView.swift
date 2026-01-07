import SwiftUI

/// Settings view for Clipboard History feature
/// Allows configuration of max items, unlimited toggle, and clearing history
struct ClipboardHistorySettingsView: View {
    @ObservedObject var manager = ClipboardHistoryManager.shared
    
    @State private var maxItemsText: String = ""
    @State private var showClearConfirmation = false
    @State private var clearIncludePinned = false
    
    @AppStorage("clipboardHistoryEnabled") private var isEnabled = true
    @AppStorage("clipboardHistoryMaxItems") private var maxItems = 200
    @AppStorage("clipboardHistoryUnlimited") private var isUnlimited = false
    
    var body: some View {
        Form {
            // General section
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    // Enable toggle
                    Toggle(isOn: $isEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable Clipboard History")
                                .font(.system(size: 13))
                            Text("Automatically capture copied content")
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                    }
                    .toggleStyle(.switch)
                    .onChange(of: isEnabled) { newValue in
                        manager.setEnabled(newValue)
                    }
                    
                    Divider()
                    
                    // Unlimited toggle
                    Toggle(isOn: $isUnlimited) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlimited history")
                                .font(.system(size: 13))
                            Text("Keep all clipboard items without limit")
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                    }
                    .toggleStyle(.switch)
                    .onChange(of: isUnlimited) { newValue in
                        manager.updateSettings(maxItems: maxItems, isUnlimited: newValue)
                    }
                    
                    // Max items input (only shown when not unlimited)
                    if !isUnlimited {
                        HStack(spacing: 12) {
                            Text("Maximum items:")
                                .font(.system(size: 13))
                            
                            TextField("", text: $maxItemsText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, design: .monospaced))
                                .frame(width: 80)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(hex: "#1e1e1e"))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                )
                                .onAppear {
                                    maxItemsText = "\(maxItems)"
                                }
                                .onChange(of: maxItemsText) { newValue in
                                    if let value = Int(newValue), value > 0 {
                                        maxItems = value
                                        manager.updateSettings(maxItems: value, isUnlimited: isUnlimited)
                                    }
                                }
                            
                            Text("items")
                                .font(.system(size: 13))
                                .foregroundColor(Color.white.opacity(0.5))
                            
                            Spacer()
                        }
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("General")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.5))
                    .textCase(.uppercase)
            }
            
            // Keyboard shortcut section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Open Clipboard History")
                            .font(.system(size: 13))
                        
                        Spacer()
                        
                        // Display current shortcut
                        HStack(spacing: 2) {
                            KeyboardKey("⌘")
                            KeyboardKey("⇧")
                            KeyboardKey("V")
                        }
                    }
                    
                    Text("Press the shortcut to open clipboard history from anywhere")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .padding(.vertical, 4)
            } header: {
                Text("Keyboard Shortcut")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.5))
                    .textCase(.uppercase)
            }
            
            // Data section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    // Statistics
                    HStack {
                        Text("Items in history:")
                            .font(.system(size: 13))
                        
                        Spacer()
                        
                        Text("\(manager.items.count)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    
                    HStack {
                        Text("Pinned items:")
                            .font(.system(size: 13))
                        
                        Spacer()
                        
                        Text("\(manager.items.filter { $0.isPinned }.count)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    
                    Divider()
                    
                    // Clear history button
                    HStack {
                        Button(action: {
                            clearIncludePinned = false
                            showClearConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear All History")
                            }
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#FF3B30"))
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Data")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.5))
                    .textCase(.uppercase)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .alert("Clear Clipboard History?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear (Keep Pinned)", role: .destructive) {
                manager.clearHistory(exceptPinned: true)
            }
            Button("Clear All", role: .destructive) {
                manager.clearHistory(exceptPinned: false)
            }
        } message: {
            Text("This will permanently delete your clipboard history. Pinned items can be preserved.")
        }
    }
}

// MARK: - Keyboard Key View

private struct KeyboardKey: View {
    let key: String
    
    init(_ key: String) {
        self.key = key
    }
    
    var body: some View {
        Text(key)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color.white.opacity(0.8))
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.1))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
    }
}

// MARK: - Preview

#Preview {
    ClipboardHistorySettingsView()
        .frame(width: 400, height: 500)
        .background(Color(hex: "#2C2C2E"))
}
