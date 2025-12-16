import SwiftUI

/// Raycast-style sheet for creating/editing custom links
struct AddEditCustomLinkSheet: View {
    let viewModel: CustomLinksSettingsViewModel
    @Binding var isPresented: Bool
    let linkToEdit: CustomLinkRecord?
    
    @State private var name: String = ""
    @State private var urlTemplate: String = ""
    @State private var focusedField: Field? = nil
    @State private var hasAttemptedSave: Bool = false
    
    enum Field {
        case name, link
    }
    
    private var isEditing: Bool {
        linkToEdit != nil
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
                            TextField("Quicklink name", text: $name, onEditingChanged: { editing in
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
                    
                    // Link field
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .center, spacing: 16) {
                            Text("Link")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.5))
                                .frame(width: 90, alignment: .trailing)
                            
                            ZStack {
                                TextField("https://google.com/search?q={argument}", text: $urlTemplate, onEditingChanged: { editing in
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        if editing {
                                            focusedField = .link
                                        } else if focusedField == .link {
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
                                            focusedField == .link ? Color.white.opacity(0.8) :
                                            (hasAttemptedSave && urlTemplate.isEmpty ? Color.red.opacity(0.5) : Color.white.opacity(0.08)),
                                            lineWidth: focusedField == .link ? 1.5 : 0.5
                                        )
                                )
                            }
                        }
                        
                        HStack {
                            Spacer()
                                .frame(width: 106)
                            
                            Text("Include {Dynamic Placeholders} for context like the selected or copied text in the link")
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
                    Image(systemName: "link")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#3B86F7"))
                    
                    Text(isEditing ? "Edit Custom Link" : "Create Custom Link")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: {
                    hasAttemptedSave = true
                    saveLink()
                }) {
                    HStack(spacing: 6) {
                        Text(isEditing ? "Save Custom Link" : "Create Custom Link")
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
        .frame(width: 700, height: 420)
        .background(Color(hex: "#161616"))
        .onAppear {
            if let link = linkToEdit {
                name = link.name
                urlTemplate = link.urlTemplate
            }
        }
        .background(
            Button("") {
                if canSave {
                    hasAttemptedSave = true
                    saveLink()
                }
            }
            .keyboardShortcut(.return, modifiers: .command)
            .hidden()
        )
    }
    
    private var canSave: Bool {
        !name.isEmpty && !urlTemplate.isEmpty
    }
    
    private func saveLink() {
        guard canSave else { return }
        
        Task {
            // Fetch favicon in background
            let favicon = await FaviconService.shared.fetchFavicon(for: urlTemplate)
            
            await MainActor.run {
                if let existing = linkToEdit {
                    viewModel.updateLink(
                        id: existing.id,
                        name: name,
                        urlTemplate: urlTemplate,
                        icon: favicon ?? existing.icon,
                        defaults: existing.defaults
                    )
                } else {
                    viewModel.addLink(
                        name: name,
                        urlTemplate: urlTemplate,
                        icon: favicon,
                        defaults: [:]
                    )
                }
                
                isPresented = false
            }
        }
    }
}
