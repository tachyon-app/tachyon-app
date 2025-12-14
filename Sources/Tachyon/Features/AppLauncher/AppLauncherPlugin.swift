import Foundation
import AppKit

/// Plugin for launching macOS applications
public final class AppLauncherPlugin: Plugin {
    
    public var id: String { "app-launcher" }
    public var name: String { "App Launcher" }
    
    private var indexedApps: [AppInfo] = []
    
    public init() {
        indexApps()
    }
    
    public func search(query: String) -> [QueryResult] {
        // If query is empty, return all apps (limited to prevent overwhelming UI)
        if query.isEmpty {
            return indexedApps.prefix(20).map { appInfo in
                createResult(from: appInfo)
            }
        }
        
        // Return all apps - QueryEngine will score and filter them
        return indexedApps.map { appInfo in
            createResult(from: appInfo)
        }
    }
    
    // MARK: - Private
    
    private func indexApps() {
        var apps: [AppInfo] = []
        
        // Search common application directories
        let searchPaths = [
            "/Applications",
            "/System/Applications",
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        ]
        
        for searchPath in searchPaths {
            if let appURLs = try? FileManager.default.contentsOfDirectory(
                at: URL(fileURLWithPath: searchPath),
                includingPropertiesForKeys: [.isApplicationKey],
                options: [.skipsHiddenFiles]
            ) {
                for appURL in appURLs {
                    if appURL.pathExtension == "app" {
                        if let appInfo = AppInfo(url: appURL) {
                            apps.append(appInfo)
                        }
                    }
                }
            }
        }
        
        indexedApps = apps.sorted { $0.name < $1.name }
    }
    
    private func createResult(from appInfo: AppInfo) -> QueryResult {
        QueryResult(
            title: appInfo.name,
            subtitle: appInfo.path,
            icon: nil, // TODO: Extract app icon
            action: {
                NSWorkspace.shared.open(appInfo.url)
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
