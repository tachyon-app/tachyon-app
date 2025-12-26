import SwiftUI
import AppKit

/// Settings view for Focus Mode configuration
struct FocusModeSettingsView: View {
    @StateObject private var manager = FocusModeManager.shared
    @State private var spotifyURLInput: String = ""
    @State private var isLoadingMetadata: Bool = false
    @State private var errorMessage: String?
    @FocusState private var isTextFieldFocused: Bool
    
    private let metadataService = SpotifyMetadataService()
    
    var body: some View {
        ScrollView {
            HStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 32) {
                    Text("Focus Mode")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // Spotify Music Section
                    spotifyMusicSection
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Glowing Border Section
                    glowingBorderSection
                }
                .frame(maxWidth: 600)
                
                Spacer()
            }
            .padding(.vertical, 40)
        }
    }
    
    // MARK: - Spotify Music Section
    
    private var spotifyMusicSection: some View {
        SettingsSection(title: "Focus Music") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add Spotify tracks, albums, or playlists to play during focus sessions.")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.6))
                
                // URL Input Field
                HStack(spacing: 12) {
                    ZStack(alignment: .leading) {
                        // Custom placeholder (always visible when empty)
                        if spotifyURLInput.isEmpty {
                            Text("Paste Spotify URL...")
                                .font(.system(size: 13))
                                .foregroundColor(Color.white.opacity(0.4))
                                .padding(.horizontal, 12)
                        }
                        
                        TextField("", text: $spotifyURLInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundColor(.white)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                addSpotifyItem()
                            }
                            .onChange(of: spotifyURLInput) { newValue in
                                // Auto-detect pasted Spotify URLs (only if not already loading)
                                guard !isLoadingMetadata else { return }
                                if newValue.contains("open.spotify.com") && metadataService.isValidSpotifyURL(newValue) {
                                    addSpotifyItem()
                                }
                            }
                    }
                    .background(Color(hex: "#252525"))
                    .cornerRadius(6)
                    
                    Button(action: addSpotifyItem) {
                        if isLoadingMetadata {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 60)
                        } else {
                            Text("Add")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 60)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(hex: "#3B86F7"))
                    .cornerRadius(6)
                    .disabled(spotifyURLInput.isEmpty || isLoadingMetadata)
                    .opacity(spotifyURLInput.isEmpty ? 0.5 : 1)
                }
                
                // Error Message
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
                
                // Music Items List
                if !manager.musicItems.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(manager.musicItems) { item in
                            SpotifyItemRow(item: item) {
                                manager.removeMusicItem(item)
                            }
                        }
                    }
                    .padding(.top, 8)
                } else {
                    Text("No music added. Paste a Spotify URL above to get started.")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.4))
                        .padding(.vertical, 12)
                }
            }
        }
    }
    
    // MARK: - Glowing Border Section
    
    private var glowingBorderSection: some View {
        SettingsSection(title: "Visual Focus Indicator") {
            VStack(alignment: .leading, spacing: 16) {
                // Enable Toggle
                SettingsRow(label: "Show glowing border during focus") {
                    Toggle("", isOn: $manager.borderSettings.isEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .onChange(of: manager.borderSettings.isEnabled) { _ in
                            saveBorderSettings()
                        }
                }
                
                if manager.borderSettings.isEnabled {
                    // Color Picker
                    SettingsRow(label: "Border Color") {
                        ColorPicker("", selection: borderColorBinding)
                            .labelsHidden()
                            .onChange(of: manager.borderSettings.colorHex) { _ in
                                saveBorderSettings()
                            }
                    }
                    
                    // Thickness Picker
                    SettingsRow(label: "Border Thickness") {
                        Picker("", selection: $manager.borderSettings.thickness) {
                            ForEach(BorderThickness.allCases, id: \.self) { thickness in
                                Text(thickness.rawValue).tag(thickness)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                        .onChange(of: manager.borderSettings.thickness) { _ in
                            saveBorderSettings()
                        }
                    }
                    
                    Text("The border will appear when you start a focus session.")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.4))
                }
            }
        }
    }
    
    // MARK: - Color Binding
    
    private var borderColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: manager.borderSettings.colorHex) },
            set: { newColor in
                if let hex = newColor.toHex() {
                    manager.borderSettings.colorHex = hex
                }
            }
        )
    }
    
    // MARK: - Actions
    
    private func addSpotifyItem() {
        guard !spotifyURLInput.isEmpty else { return }
        guard !isLoadingMetadata else { return } // Prevent concurrent adds
        guard metadataService.isValidSpotifyURL(spotifyURLInput) else {
            errorMessage = "Please enter a valid Spotify URL"
            return
        }
        
        let urlToFetch = spotifyURLInput // Capture the URL
        errorMessage = nil
        isLoadingMetadata = true
        spotifyURLInput = "" // Clear immediately to prevent re-triggering
        
        Task {
            do {
                let item = try await metadataService.fetchMetadata(from: urlToFetch)
                await MainActor.run {
                    manager.addMusicItem(item)
                    isLoadingMetadata = false
                    isTextFieldFocused = true // Return focus to input
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to fetch metadata: \(error.localizedDescription)"
                    isLoadingMetadata = false
                    isTextFieldFocused = true // Return focus even on error
                }
            }
        }
    }
    
    private func saveBorderSettings() {
        // Settings are automatically saved by FocusModeManager
        // Just trigger a save
        if let data = try? JSONEncoder().encode(manager.borderSettings) {
            UserDefaults.standard.set(data, forKey: "focusBorderSettings")
        }
    }
    
    private func previewBorder() {
        FocusBorderWindowController.shared.show(settings: manager.borderSettings)
        
        // Hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            FocusBorderWindowController.shared.hide()
        }
    }
}

// MARK: - Spotify Item Row

struct SpotifyItemRow: View {
    let item: SpotifyItem
    let onRemove: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(hex: "#333333"))
                }
                .frame(width: 40, height: 40)
                .cornerRadius(4)
            } else {
                Rectangle()
                    .fill(Color(hex: "#333333"))
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
            
            // Title and Type
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(item.type.rawValue.capitalized)
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.5))
            }
            
            Spacer()
            
            // Remove Button (visible on hover)
            if isHovered {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(10)
        .background(Color(hex: "#252525"))
        .cornerRadius(8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Color Extension for Hex Conversion

extension Color {
    func toHex() -> String? {
        guard let components = NSColor(self).cgColor.components else { return nil }
        
        let r = components.count > 0 ? components[0] : 0
        let g = components.count > 1 ? components[1] : 0
        let b = components.count > 2 ? components[2] : 0
        
        return String(format: "#%02X%02X%02X", 
                     Int(r * 255), 
                     Int(g * 255), 
                     Int(b * 255))
    }
}
