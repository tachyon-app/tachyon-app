import SwiftUI

/// Settings window with tabbed interface
public struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    
    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case appLauncher = "App Launcher"
        case scripts = "Scripts"
        case customLinks = "Custom Links"
        case windowSnapping = "Window Snapping"
        case clipboard = "Clipboard"
        case focusMode = "Focus Mode"
        case searchEngines = "Search Engines"
        case hotkeys = "Hotkeys"
    }
    
    public init() {}
    
    public var body: some View {
        HSplitView {
            // Sidebar
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: iconForTab(tab))
                    .tag(tab)
            }
            .frame(minWidth: 200, idealWidth: 220)
            .listStyle(.sidebar)
            
            // Content
            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .appLauncher:
                    PlaceholderSettingsView(title: "App Launcher Settings")
                case .scripts:
                    PlaceholderSettingsView(title: "Script Settings")
                case .customLinks:
                    PlaceholderSettingsView(title: "Custom Links Settings")
                case .windowSnapping:
                    PlaceholderSettingsView(title: "Window Snapping Settings")
                case .clipboard:
                    PlaceholderSettingsView(title: "Clipboard Settings")
                case .focusMode:
                    PlaceholderSettingsView(title: "Focus Mode Settings")
                case .searchEngines:
                    SearchEnginesSettingsView()
                case .hotkeys:
                    PlaceholderSettingsView(title: "Hotkeys Settings")
                }
            }
            .frame(minWidth: 500)
            .padding()
        }
        .frame(minWidth: 700, minHeight: 500)
    }
    
    private func iconForTab(_ tab: SettingsTab) -> String {
        switch tab {
        case .general: return "gearshape"
        case .appLauncher: return "app.badge"
        case .scripts: return "terminal"
        case .customLinks: return "link"
        case .windowSnapping: return "rectangle.split.3x1"
        case .clipboard: return "doc.on.clipboard"
        case .focusMode: return "timer"
        case .searchEngines: return "magnifyingglass"
        case .hotkeys: return "keyboard"
        }
    }
}

/// General settings view
struct GeneralSettingsView: View {
    var body: some View {
        Form {
            Section {
                Text("Tachyon")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Blazing fast productivity launcher for macOS")
                    .foregroundColor(.secondary)
            }
            
            Section("Global Hotkey") {
                HStack {
                    Text("Show Tachyon:")
                    Spacer()
                    Text("⌘ Space")
                        .font(.system(.body, design: .monospaced))
                        .padding(6)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Text("To use ⌘Space, you need to disable Spotlight's keyboard shortcut in System Settings > Keyboard > Keyboard Shortcuts > Spotlight.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Appearance") {
                // TODO: Add appearance settings
                Text("Coming soon...")
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

/// Placeholder for settings views we haven't built yet
struct PlaceholderSettingsView: View {
    let title: String
    
    var body: some View {
        VStack {
            Image(systemName: "hammer.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
    }
}
