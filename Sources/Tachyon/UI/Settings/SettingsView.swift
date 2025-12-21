import SwiftUI

/// Settings window with horizontal tab bar (Raycast-style)
public struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    
  /// Settings tabs
enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case sources = "Sources"
    case scriptCommands = "Script Commands"
    case windowSnapping = "Window Snapping"
    case hotkeys = "Hotkeys"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .sources: return "square.grid.2x2"
        case .scriptCommands: return "terminal"
        case .windowSnapping: return "rectangle.split.3x3"
        case .hotkeys: return "keyboard"
        }
    }
}
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Darker background (matching Raycast)
            Rectangle()
                .fill(.ultraThinMaterial)
                .background(Color(hex: "#1a1a1a").opacity(0.95))
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title bar area with tabs
                VStack(spacing: 0) {
                    // Spacer for macOS traffic lights (reduced for tighter spacing)
                    Spacer()
                        .frame(height: 32)
                    
                    // Centered tabs
                    HStack(spacing: 0) {
                        Spacer()
                        
                        HStack(spacing: 4) {
                            ForEach(SettingsTab.allCases) { tab in
                                TabButton(
                                    title: tab.rawValue,
                                    icon: tab.icon,
                                    isSelected: selectedTab == tab
                                ) {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        selectedTab = tab
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
                
                // Content area (transparent to show gradient)
                Group {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsView()
                    case .sources:
                        SourcesSettingsView()
                    case .scriptCommands:
                        ScriptCommandsSettingsView()
                    case .windowSnapping:
                        WindowSnappingSettingsView()
                    case .hotkeys:
                        HotkeysSettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onExitCommand {
            NSApp.keyWindow?.close()
        }
    }
}

/// Tab button for horizontal tab bar (Raycast style)
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
            }
            .frame(width: 85)
            .padding(.vertical, 7)
            .contentShape(Rectangle()) // Make entire area clickable
            .background(
                Color.clear
            )
            .overlay(
                // Bottom border for selected state
                Rectangle()
                    .fill(isSelected ? Color(hex: "#3B86F7") : Color.clear)
                    .frame(height: 2)
                    .offset(y: 1),
                alignment: .bottom
            )
            .opacity(isSelected ? 1.0 : (isHovered ? 0.75 : 1.0))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

/// General settings view with dark theme
struct GeneralSettingsView: View {
    var body: some View {
        ScrollView {
            HStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 28) {
                    // Header with logo
                    VStack(alignment: .leading, spacing: 7) {
                        if let logoImage = NSImage(contentsOfFile: "/Users/pablo/code/flashcast/Resources/Logo.png") {
                            Image(nsImage: logoImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 56, height: 56)
                        }
                        
                        Text("Tachyon")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Blazing fast productivity launcher for macOS")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.55))
                    }
                    
                    // Global Hotkey Section
                    SettingsSection(title: "Global Hotkey") {
                        SettingsRow(label: "Show Tachyon") {
                            HStack(spacing: 6) {
                                Text("⌘")
                                    .font(.system(size: 13, design: .monospaced))
                                Text("Space")
                                    .font(.system(size: 13, design: .monospaced))
                            }
                            .foregroundColor(Color.white.opacity(0.75))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Color(hex: "#252525"))
                            .cornerRadius(5)
                        }
                        
                        Text("To use ⌘Space, disable Spotlight's keyboard shortcut in System Settings → Keyboard → Keyboard Shortcuts → Spotlight.")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.4))
                            .padding(.top, 6)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.06))
                    
                    // Settings Hotkey Section
                    SettingsSection(title: "Settings") {
                        SettingsRow(label: "Open Settings") {
                            HStack(spacing: 6) {
                                Text("⌘")
                                    .font(.system(size: 13, design: .monospaced))
                                Text(",")
                                    .font(.system(size: 13, design: .monospaced))
                            }
                            .foregroundColor(Color.white.opacity(0.8))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(hex: "#2a2a2a"))
                            .cornerRadius(4)
                        }
                        
                        Text("Press ⌘, while the search bar is focused to open settings.")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.4))
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: 600)
                
                Spacer()
            }
            .padding(.vertical, 40)
        }
    }
}

/// Hotkeys settings view
struct HotkeysSettingsView: View {
    var body: some View {
        ScrollView {
            HStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 32) {
                    Text("Keyboard Shortcuts")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    
                    SettingsSection(title: "Search Bar") {
                        SettingsRow(label: "Toggle Search Bar") {
                            KeyboardShortcutView(keys: ["⌘", "Space"])
                        }
                        SettingsRow(label: "Close Search Bar") {
                            KeyboardShortcutView(keys: ["⎋"])
                        }
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    SettingsSection(title: "Navigation") {
                        SettingsRow(label: "Next Result") {
                            KeyboardShortcutView(keys: ["↓"])
                        }
                        SettingsRow(label: "Previous Result") {
                            KeyboardShortcutView(keys: ["↑"])
                        }
                        SettingsRow(label: "Execute Result") {
                            KeyboardShortcutView(keys: ["↵"])
                        }
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    SettingsSection(title: "Settings") {
                        SettingsRow(label: "Open Settings") {
                            KeyboardShortcutView(keys: ["⌘", ","])
                        }
                        SettingsRow(label: "Close Settings") {
                            KeyboardShortcutView(keys: ["⎋"])
                        }
                    }
                }
                .frame(maxWidth: 600)
                
                Spacer()
            }
            .padding(.vertical, 40)
        }
    }
}

/// Keyboard shortcut display
struct KeyboardShortcutView: View {
    let keys: [String]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.75))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color(hex: "#252525"))
                    .cornerRadius(5)
            }
        }
    }
}

/// Settings section container
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.4))
                .textCase(.uppercase)
                .tracking(0.6)
            
            VStack(alignment: .leading, spacing: 10) {
                content
            }
        }
    }
}

/// Settings row with label and control
struct SettingsRow<Content: View>: View {
    let label: String
    let control: Content
    
    init(label: String, @ViewBuilder control: () -> Content) {
        self.label = label
        self.control = control()
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.85))
            
            Spacer()
            
            control
        }
        .padding(.vertical, 3)
    }
}

/// Placeholder for settings views we haven't built yet
struct PlaceholderSettingsView: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 48))
                .foregroundColor(Color.white.opacity(0.3))
            
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Coming soon...")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
