import SwiftUI

/// Settings window with horizontal tab bar (Raycast-style)
public struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    
  /// Settings tabs
enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case clipboard = "Clipboard"
    case sources = "Sources"
    case scriptCommands = "Script Commands"
    case windowSnapping = "Window Snapping"
    case focusMode = "Focus Mode"
    case hotkeys = "Hotkeys"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .clipboard: return "doc.on.clipboard"
        case .sources: return "square.grid.2x2"
        case .scriptCommands: return "terminal"
        case .windowSnapping: return "rectangle.split.3x3"
        case .focusMode: return "timer"
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
                    case .clipboard:
                        ClipboardHistorySettingsView()
                    case .sources:
                        SourcesSettingsView()
                    case .scriptCommands:
                        ScriptCommandsSettingsView()
                    case .windowSnapping:
                        WindowSnappingSettingsView()
                    case .focusMode:
                        FocusModeSettingsView()
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
    @StateObject private var launchAtLoginService = LaunchAtLoginService.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var photoSaveLocation: URL = {
        if let savedPath = UserDefaults.standard.string(forKey: "CameraDefaultSaveLocation") {
            return URL(fileURLWithPath: savedPath)
        }
        return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
    }()
    
    var body: some View {
        ScrollView {
            HStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 28) {
                    // Header with logo
                    VStack(alignment: .leading, spacing: 7) {
                        if let logoImage = TachyonAssets.logo {
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
                    
                    // Appearance Section
                    SettingsSection(title: "Appearance") {
                        VStack(alignment: .leading, spacing: 8) {
                            SettingsRow(label: "Theme") {
                                HStack(spacing: 8) {
                                    Picker("", selection: $themeManager.activeThemeType) {
                                        ForEach(themeManager.availableThemes) { theme in
                                            Text(theme.name).tag(theme)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 140)
                                    
                                    Button(action: {
                                        themeManager.reloadThemes()
                                    }) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 11))
                                            .frame(width: 20, height: 20)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Reload Themes")
                                    .background(Color(hex: "#2a2a2a"))
                                    .cornerRadius(4)
                                }
                            }
                            
                            HStack {
                                Spacer()
                                Button(action: {
                                    ThemeFileManager.shared.openThemesFolder()
                                }) {
                                    Text("Open Themes Folder")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(hex: "#3B86F7"))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.06))
                    
                    // Startup Section
                    SettingsSection(title: "Startup") {
                        SettingsRow(label: "Launch at Login") {
                            Toggle("", isOn: $launchAtLoginService.isEnabled)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .tint(Color(hex: "#3B86F7"))
                        }
                        
                        Text("Automatically start Tachyon when you log in to your Mac.")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.4))
                            .padding(.top, 6)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.06))
                    
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
                    
                    Divider()
                        .background(Color.white.opacity(0.06))
                    
                    // Camera Section
                    SettingsSection(title: "Camera") {
                        SettingsRow(label: "Photo Save Location") {
                            Button(action: selectPhotoSaveLocation) {
                                HStack(spacing: 6) {
                                    Image(systemName: "folder")
                                        .font(.system(size: 12))
                                    Text(photoSaveLocation.lastPathComponent)
                                        .font(.system(size: 12))
                                        .lineLimit(1)
                                }
                                .foregroundColor(Color.white.opacity(0.75))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(hex: "#252525"))
                                .cornerRadius(5)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Text("Photos captured with the camera will be saved to this folder.")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.4))
                            .padding(.top, 6)
                    }
                }
                .frame(maxWidth: 600)
                
                Spacer()
            }
            .padding(.vertical, 40)
        }
    }
    
    private func selectPhotoSaveLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = photoSaveLocation
        panel.prompt = "Select"
        panel.message = "Choose where to save camera photos"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                photoSaveLocation = url
                UserDefaults.standard.set(url.path, forKey: "CameraDefaultSaveLocation")
                // Notify CameraService to update immediately
                NotificationCenter.default.post(
                    name: NSNotification.Name("CameraSaveLocationChanged"),
                    object: url
                )
            }
        }
    }
}

/// Hotkeys settings view
struct HotkeysSettingsView: View {
    @StateObject private var windowSnappingViewModel = WindowSnappingSettingsViewModel()
    
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
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Window Snapping shortcuts
                    if windowSnappingViewModel.isLoading {
                        SettingsSection(title: "Window Snapping") {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                        }
                    } else {
                        windowSnappingSection
                    }
                }
                .frame(maxWidth: 600)
                
                Spacer()
            }
            .padding(.vertical, 40)
        }
        .onAppear {
            windowSnappingViewModel.loadShortcuts()
        }
    }
    
    @ViewBuilder
    private var windowSnappingSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Section header with link to full settings
            HStack {
                Text("WINDOW SNAPPING")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.4))
                    .tracking(0.6)
                
                Spacer()
                
                Text("Customize in Window Snapping tab")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#3B86F7"))
            }
            
            VStack(alignment: .leading, spacing: 16) {
                // Halves
                if !windowSnappingViewModel.halves.isEmpty {
                    HotkeysShortcutGroup(
                        title: "Halves",
                        shortcuts: windowSnappingViewModel.halves
                    )
                }
                
                // Quarters
                if !windowSnappingViewModel.quarters.isEmpty {
                    HotkeysShortcutGroup(
                        title: "Quarters",
                        shortcuts: windowSnappingViewModel.quarters
                    )
                }
                
                // Thirds
                if !windowSnappingViewModel.thirds.isEmpty {
                    HotkeysShortcutGroup(
                        title: "Thirds",
                        shortcuts: windowSnappingViewModel.thirds
                    )
                }
                
                // Multi-Monitor
                if !windowSnappingViewModel.multiMonitor.isEmpty {
                    HotkeysShortcutGroup(
                        title: "Multi-Monitor",
                        shortcuts: windowSnappingViewModel.multiMonitor
                    )
                }
                
                // Other
                if !windowSnappingViewModel.other.isEmpty {
                    HotkeysShortcutGroup(
                        title: "Other",
                        shortcuts: windowSnappingViewModel.other
                    )
                }
            }
        }
    }
}

/// Group of window snapping shortcuts for display in Hotkeys view
struct HotkeysShortcutGroup: View {
    let title: String
    let shortcuts: [WindowSnappingShortcut]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.white.opacity(0.6))
            
            VStack(spacing: 6) {
                ForEach(shortcuts.filter { $0.isEnabled }, id: \.id) { shortcut in
                    HStack {
                        Text(shortcut.displayName)
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.85))
                        
                        Spacer()
                        
                        HotkeysShortcutBadge(shortcut: shortcut)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

/// Compact shortcut badge for Hotkeys view
struct HotkeysShortcutBadge: View {
    let shortcut: WindowSnappingShortcut
    
    var body: some View {
        HStack(spacing: 3) {
            // Modifier keys
            if shortcut.modifiers & 4096 != 0 {  // controlKey
                Text("⌃")
                    .modifier(HotkeyKeyStyle())
            }
            if shortcut.modifiers & 2048 != 0 {  // optionKey
                Text("⌥")
                    .modifier(HotkeyKeyStyle())
            }
            if shortcut.modifiers & 256 != 0 {  // cmdKey
                Text("⌘")
                    .modifier(HotkeyKeyStyle())
            }
            if shortcut.modifiers & 512 != 0 {  // shiftKey
                Text("⇧")
                    .modifier(HotkeyKeyStyle())
            }
            
            // Key
            Text(KeyCodeMapper.symbol(for: shortcut.keyCode))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color(hex: "#252525"))
                .cornerRadius(4)
        }
    }
}

/// Shared style for hotkey modifier keys
struct HotkeyKeyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.6))
            .frame(width: 20, height: 20)
            .background(Color(hex: "#1e1e1e"))
            .cornerRadius(3)
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
