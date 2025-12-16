import SwiftUI

/// Raycast-style sheet for creating/editing search engines
struct AddEditSearchEngineSheet: View {
    let viewModel: SearchEnginesSettingsViewModel
    @Binding var isPresented: Bool
    let engineToEdit: SearchEngineRecord?
    
    @State private var name: String = ""
    @State private var urlTemplate: String = ""
    @State private var focusedField: Field? = nil
    @State private var hasAttemptedSave: Bool = false
    
    enum Field {
        case name, urlTemplate
    }
    
    private var isEditing: Bool {
        engineToEdit != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    isPresented = false
                }) {
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
                    // Name field
                    HStack(alignment: .center, spacing: 16) {
                        Text("Name")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.5))
                            .frame(width: 90, alignment: .trailing)
                        
                        ZStack {
                            TextField("Search engine name", text: $name, onEditingChanged: { editing in
                                withAnimation(.easeOut(duration: 0.15)) {
                                    if editing {
                                        focusedField = .name
                                    } else if focusedField == .name {
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
                                        focusedField == .name ? Color.white.opacity(0.8) :
                                        (hasAttemptedSave && name.isEmpty ? Color.red.opacity(0.5) : Color.white.opacity(0.08)),
                                        lineWidth: focusedField == .name ? 1.5 : 0.5
                                    )
                            )
                        }
                    }
                    
                    // URL Template field
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .center, spacing: 16) {
                            Text("URL Template")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.5))
                                .frame(width: 90, alignment: .trailing)
                            
                            ZStack {
                                TextField("https://google.com/search?q={{query}}", text: $urlTemplate, onEditingChanged: { editing in
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        if editing {
                                            focusedField = .urlTemplate
                                        } else if focusedField == .urlTemplate {
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
                                            focusedField == .urlTemplate ? Color.white.opacity(0.8) :
                                            (hasAttemptedSave && urlTemplate.isEmpty ? Color.red.opacity(0.5) : Color.white.opacity(0.08)),
                                            lineWidth: focusedField == .urlTemplate ? 1.5 : 0.5
                                        )
                                )
                            }
                        }
                        
                        HStack {
                            Spacer()
                                .frame(width: 106)
                            
                            Text("Use {{query}} as a placeholder for the search query")
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.35))
                                .fixedSize(horizontal: false, vertical: true)
                        }
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
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#FF6B35"))
                    
                    Text(isEditing ? "Edit Search Engine" : "Create Search Engine")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: {
                    hasAttemptedSave = true
                    saveEngine()
                }) {
                    HStack(spacing: 6) {
                        Text(isEditing ? "Save Search Engine" : "Create Search Engine")
                            .font(.system(size: 13, weight: .medium))
                        
                        Text("⌘↵")
                            .font(.system(size: 10, weight: .medium))
                            .opacity(0.5)
                    }
                    .foregroundColor(canSave ? .white : Color.white.opacity(0.4))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(canSave ? Color(hex: "#FF6B35") : Color.white.opacity(0.04))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .frame(width: 700, height: 380)
        .background(Color(hex: "#161616"))
        .onAppear {
            if let engine = engineToEdit {
                name = engine.name
                urlTemplate = engine.urlTemplate
            }
        }
        .background(
            Button("") {
                if canSave {
                    hasAttemptedSave = true
                    saveEngine()
                }
            }
            .keyboardShortcut(.return, modifiers: .command)
            .hidden()
        )
    }
    
    private var canSave: Bool {
        !name.isEmpty && !urlTemplate.isEmpty
    }
    
    private func saveEngine() {
        guard canSave else { return }
        
        Task {
            // Fetch favicon in background
            let favicon = await FaviconService.shared.fetchFavicon(for: urlTemplate)
            
            // Generate a keyword from the name (first letter, lowercase)
            let keyword = String(name.prefix(1)).lowercased()
            
            await MainActor.run {
                if let existing = engineToEdit {
                    viewModel.updateEngine(
                        id: existing.id,
                        name: name,
                        keyword: existing.keyword,
                        urlTemplate: urlTemplate,
                        icon: favicon ?? existing.icon
                    )
                } else {
                    viewModel.addEngine(
                        name: name,
                        keyword: keyword,
                        urlTemplate: urlTemplate,
                        icon: favicon
                    )
                }
                
                isPresented = false
            }
        }
    }
}
