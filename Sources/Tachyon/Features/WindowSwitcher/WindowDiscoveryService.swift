import Foundation
import Cocoa
import CoreGraphics

class WindowDiscoveryService {
    
    static let shared = WindowDiscoveryService()
    
    private let snapshotCache = NSCache<NSNumber, NSImage>()
    private let imageGenerationQueue = DispatchQueue(label: "com.tachyon.windowswitcher.imageGeneration", qos: .userInteractive)
    
    private init() {
        snapshotCache.countLimit = 50
    }
    
    private func checkScreenRecordingPermission() -> Bool {
        if #available(macOS 10.15, *) {
            return CGPreflightScreenCaptureAccess()
        }
        return true // Assume yes on older OS
    }
    
    func fetchWindows() -> [WindowInfo] {
        if !checkScreenRecordingPermission() {
            print("❌ WindowDiscovery: Screen Recording permission is MISSING. Thumbnails will be empty.")
            // We still proceed to get titles/frames which don't need this permission usually (metadata only)
            // Actually CGWindowListCopyWindowInfo might work partially or return filtered list.
        }
        
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            print("❌ WindowDiscovery: Failed to fetch window list")
            return []
        }
        
        print("🔍 WindowDiscovery: Fetched \(infoList.count) raw window entries")
        
        let myPID = ProcessInfo.processInfo.processIdentifier
        var windows: [WindowInfo] = []
        
        for entry in infoList {
            let id = (entry[kCGWindowNumber as String] as? CGWindowID) ?? 0
            let layer = entry[kCGWindowLayer as String] as? Int32 ?? -1
            let ownerPID = entry[kCGWindowOwnerPID as String] as? pid_t ?? 0
            let appName = (entry[kCGWindowOwnerName as String] as? String) ?? "Unknown"
            
            // Log entry for debugging (first 10 or so)
            // print(" - Entry: \(id) | \(appName) | Layer: \(layer)")
            
            guard layer == 0 else { continue } // kCGNormalWindowLevel
            
            guard ownerPID != myPID else { continue }
            
            guard let boundsDict = entry[kCGWindowBounds as String] as? [String: Any],
                  let frame = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else { continue }
            
            // Filter out small ghost windows or menubar-like windows
            if frame.width < 50 || frame.height < 50 { 
                // print("   -> Skipped small frame: \(frame)")
                continue 
            }
            
            let title = (entry[kCGWindowName as String] as? String) ?? ""
            
            // Relaxed empty title check for now - Screen Recording permission issue?
            // if title.isEmpty { continue }

            var window = WindowInfo(
                id: id,
                ownerPID: ownerPID,
                appName: appName,
                title: title,
                frame: frame,
                layer: layer,
                appIcon: nil,
                snapshot: nil
            )
            
            // Check if application is running
            guard let runningApp = NSRunningApplication(processIdentifier: ownerPID) else {
                continue // Skip dead processes
            }
            
            // Synchronously load app icon (fast enough usually, or can be cached/async)
            if let appPath = runningApp.bundleURL?.path {
                window.appIcon = NSWorkspace.shared.icon(forFile: appPath)
            } else {
                 // Fallback if we can't find the running app bundle, try to find by name? 
                 // For now, leave nil or default? 
                 // NSWorkspace.shared.icon(forFile:) works with full paths.
                 // We can also try getting it from the pid via NSRunningApplication
            }
            // If still nil, maybe use a default icon?
            if window.appIcon == nil {
                // Try to get icon for the app by name if possible, or just generic application icon
                // Using a generic executable icon as fallback
                 window.appIcon = NSWorkspace.shared.icon(forFileType: NSFileTypeForHFSTypeCode(OSType(kGenericApplicationIcon)))
            }

            windows.append(window)
        }
        
        return windows
    }
    
    func generateSnapshot(for window: WindowInfo, completion: @escaping (NSImage?) -> Void) {
        if let cached = snapshotCache.object(forKey: NSNumber(value: window.id)) {
            // print("🔍 WindowDiscovery: Cache hit for \(window.appName)")
            completion(cached)
            return
        }
        
        imageGenerationQueue.async { [weak self] in
            // print("🔍 WindowDiscovery: Generating snapshot for \(window.id) (\(window.appName))")
            let imageOption: CGWindowImageOption = [.boundsIgnoreFraming, .bestResolution]
            // Use CGRect.null to capture the window's actual bounds instead of enforcing frame which might be slightly off
            guard let cgImage = CGWindowListCreateImage(.null, .optionIncludingWindow, window.id, imageOption) else {
                print("❌ WindowDiscovery: Failed to create CGImage for \(window.appName) (ID: \(window.id))")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            let nsImage = NSImage(cgImage: cgImage, size: window.frame.size)
            self?.snapshotCache.setObject(nsImage, forKey: NSNumber(value: window.id))
            // print("✅ WindowDiscovery: Snapshot created for \(window.appName)")
            
            DispatchQueue.main.async {
                completion(nsImage)
            }
        }
    }
}
