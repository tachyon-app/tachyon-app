import Foundation
import AppKit

/// Plugin for launching macOS applications and System Settings preference panes
public final class AppLauncherPlugin: Plugin {
    
    public var id: String { "app-launcher" }
    public var name: String { "App Launcher" }
    
    private var indexedApps: [AppInfo] = []
    private var systemSettingsPanes: [SystemSettingsPane] = []
    
    public init() {
        indexApps()
        indexSystemSettings()
    }
    
    public func search(query: String) -> [QueryResult] {
        // Combine apps and system settings results
        var results: [QueryResult] = []
        
        // If query is empty, return top apps (not system settings to avoid clutter)
        if query.isEmpty {
            results.append(contentsOf: indexedApps.prefix(20).map { createResult(from: $0) })
            return results
        }
        
        // Return all apps and system settings - QueryEngine will score and filter them
        results.append(contentsOf: indexedApps.map { createResult(from: $0) })
        results.append(contentsOf: systemSettingsPanes.map { createResult(from: $0) })
        return results
    }
    
    // MARK: - Private
    
    private func indexApps() {
        var apps: [AppInfo] = []
        var seenURLs = Set<URL>()
        
        // Search common application directories
        let searchPaths = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            "/System/Library/CoreServices/Applications",
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        ]
        
        for searchPath in searchPaths {
            if let appURLs = try? FileManager.default.contentsOfDirectory(
                at: URL(fileURLWithPath: searchPath),
                includingPropertiesForKeys: [.isApplicationKey, .applicationIsScriptableKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) {
                for appURL in appURLs {
                    // Filter duplicates
                    if seenURLs.contains(appURL) { continue }
                    
                    // Strict filtering
                    let ext = appURL.pathExtension
                    if ext == "app" {
                        // Exclude .appex or embedded apps if any slip through
                        if appURL.path.contains(".appex") { continue }
                        
                        if let appInfo = AppInfo(url: appURL) {
                            apps.append(appInfo)
                            seenURLs.insert(appURL)
                        }
                    }
                }
            }
        }
        
        indexedApps = apps.sorted { $0.name < $1.name }
    }
    
    private func indexSystemSettings() {
        // Hardcoded list of System Settings panes with their modern macOS URL schemes
        systemSettingsPanes = [
            // General & Appearance
            SystemSettingsPane(name: "General", urlPath: "com.apple.settings.General", keywords: ["appearance", "default browser", "about"]),
            SystemSettingsPane(name: "Appearance", urlPath: "com.apple.Appearance-Settings.extension", keywords: ["dark mode", "light mode", "accent color"]),
            
            // Hardware
            SystemSettingsPane(name: "Displays", urlPath: "com.apple.Displays-Settings.extension", keywords: ["screen", "monitor", "resolution", "display", "brightness", "night shift"]),
            SystemSettingsPane(name: "Sound", urlPath: "com.apple.Sound-Settings.extension", keywords: ["audio", "volume", "speaker", "microphone", "output", "input"]),
            SystemSettingsPane(name: "Keyboard", urlPath: "com.apple.Keyboard-Settings.extension", keywords: ["typing", "shortcuts", "input sources", "text replacement"]),
            SystemSettingsPane(name: "Trackpad", urlPath: "com.apple.Trackpad-Settings.extension", keywords: ["gestures", "scroll", "tap", "click"]),
            SystemSettingsPane(name: "Mouse", urlPath: "com.apple.Mouse-Settings.extension", keywords: ["pointer", "cursor", "scroll", "click"]),
            SystemSettingsPane(name: "Printers & Scanners", urlPath: "com.apple.Print-Scan-Settings.extension", keywords: ["printer", "scanner", "printing"]),
            
            // Network & Wireless
            SystemSettingsPane(name: "Wi-Fi", urlPath: "com.apple.wifi-settings-extension", keywords: ["wireless", "network", "internet", "hotspot"]),
            SystemSettingsPane(name: "Bluetooth", urlPath: "com.apple.BluetoothSettings", keywords: ["wireless", "devices", "pairing"]),
            SystemSettingsPane(name: "Network", urlPath: "com.apple.Network-Settings.extension", keywords: ["ethernet", "vpn", "dns", "proxy", "firewall"]),
            
            // Power & Battery
            SystemSettingsPane(name: "Battery", urlPath: "com.apple.Battery-Settings.extension", keywords: ["power", "energy", "charging", "low power mode"]),
            SystemSettingsPane(name: "Energy Saver", urlPath: "com.apple.EnergySaver-Settings.extension", keywords: ["sleep", "power nap"]),
            
            // Privacy & Security
            SystemSettingsPane(name: "Privacy & Security", urlPath: "com.apple.settings.PrivacySecurity.extension", keywords: ["security", "privacy", "location", "camera", "microphone", "filevault"]),
            SystemSettingsPane(name: "Touch ID & Password", urlPath: "com.apple.Touch-ID-Settings.extension", keywords: ["fingerprint", "password", "login"]),
            SystemSettingsPane(name: "Passwords", urlPath: "com.apple.Passwords-Settings.extension", keywords: ["keychain", "saved passwords", "passkeys"]),
            
            // Desktop & Dock
            SystemSettingsPane(name: "Desktop & Dock", urlPath: "com.apple.Desktop-Settings.extension", keywords: ["dock", "stage manager", "hot corners", "mission control"]),
            SystemSettingsPane(name: "Wallpaper", urlPath: "com.apple.Wallpaper-Settings.extension", keywords: ["background", "desktop picture"]),
            SystemSettingsPane(name: "Screen Saver", urlPath: "com.apple.ScreenSaver-Settings.extension", keywords: ["screensaver"]),
            
            // Notifications & Focus
            SystemSettingsPane(name: "Notifications", urlPath: "com.apple.Notifications-Settings.extension", keywords: ["alerts", "banners", "sounds"]),
            SystemSettingsPane(name: "Focus", urlPath: "com.apple.Focus-Settings.extension", keywords: ["do not disturb", "dnd", "focus mode"]),
            SystemSettingsPane(name: "Screen Time", urlPath: "com.apple.Screen-Time-Settings.extension", keywords: ["usage", "app limits", "downtime"]),
            
            // Users & Accounts
            SystemSettingsPane(name: "Users & Groups", urlPath: "com.apple.Users-Groups-Settings.extension", keywords: ["accounts", "login", "admin"]),
            SystemSettingsPane(name: "Internet Accounts", urlPath: "com.apple.Internet-Accounts-Settings.extension", keywords: ["mail", "calendar", "icloud"]),
            SystemSettingsPane(name: "Apple ID", urlPath: "com.apple.systempreferences.AppleIDSettings", keywords: ["icloud", "apple account"]),
            SystemSettingsPane(name: "Family Sharing", urlPath: "com.apple.Family-Settings.extension", keywords: ["family", "kids", "parental"]),
            
            // Accessibility
            SystemSettingsPane(name: "Accessibility", urlPath: "com.apple.Accessibility-Settings.extension", keywords: ["voiceover", "zoom", "display", "motor", "hearing", "speech"]),
            
            // System
            SystemSettingsPane(name: "Date & Time", urlPath: "com.apple.Date-Time-Settings.extension", keywords: ["clock", "timezone"]),
            SystemSettingsPane(name: "Language & Region", urlPath: "com.apple.Localization-Settings.extension", keywords: ["locale", "language", "format"]),
            SystemSettingsPane(name: "Sharing", urlPath: "com.apple.Sharing-Settings.extension", keywords: ["file sharing", "screen sharing", "remote", "airdrop"]),
            SystemSettingsPane(name: "Time Machine", urlPath: "com.apple.Time-Machine-Settings.extension", keywords: ["backup", "restore"]),
            SystemSettingsPane(name: "Startup Disk", urlPath: "com.apple.Startup-Disk-Settings.extension", keywords: ["boot", "target disk"]),
            SystemSettingsPane(name: "Software Update", urlPath: "com.apple.Software-Update-Settings.extension", keywords: ["updates", "upgrade", "macos"]),
            
            // Siri & Search
            SystemSettingsPane(name: "Siri & Spotlight", urlPath: "com.apple.Siri-Settings.extension", keywords: ["siri", "search", "spotlight"]),
            
            // Control Center
            SystemSettingsPane(name: "Control Center", urlPath: "com.apple.ControlCenter-Settings.extension", keywords: ["menu bar", "control center"]),
            
            // Extensions
            SystemSettingsPane(name: "Extensions", urlPath: "com.apple.ExtensionsPreferences", keywords: ["share", "finder", "actions"]),
        ]
    }
    
    private func createResult(from appInfo: AppInfo) -> QueryResult {
        QueryResult(
            title: appInfo.name,
            subtitle: appInfo.path,
            icon: nil,
            iconPath: appInfo.path,
            action: {
                NSWorkspace.shared.open(appInfo.url)
            }
        )
    }
    
    private func createResult(from pane: SystemSettingsPane) -> QueryResult {
        QueryResult(
            title: pane.name,
            subtitle: "System Settings",
            icon: "gearshape",
            action: {
                // Open the preference pane using the x-apple.systempreferences URL scheme
                // Modern macOS (Ventura+) uses this format
                if let url = URL(string: "x-apple.systempreferences:\(pane.urlPath)") {
                    NSWorkspace.shared.open(url)
                }
            }
        )
    }
}

// MARK: - AppInfo

struct AppInfo {
    let name: String
    let path: String
    let url: URL
    
    init?(url: URL) {
        guard url.pathExtension == "app" else { return nil }
        
        self.url = url
        self.path = url.path
        
        // Get app name from bundle or filename
        if let bundle = Bundle(url: url),
           let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            self.name = displayName
        } else if let bundle = Bundle(url: url),
                  let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
            self.name = bundleName
        } else {
            // Fallback to filename without .app extension
            self.name = url.deletingPathExtension().lastPathComponent
        }
    }
}

// MARK: - SystemSettingsPane

/// Represents a System Settings preference pane
struct SystemSettingsPane {
    let name: String
    let urlPath: String
    let keywords: [String]
    
    init(name: String, urlPath: String, keywords: [String] = []) {
        self.name = name
        self.urlPath = urlPath
        self.keywords = keywords
    }
}

