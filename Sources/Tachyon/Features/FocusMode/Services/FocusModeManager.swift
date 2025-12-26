import Foundation
import Combine
import AppKit

/// Central manager for focus mode state and coordination
public class FocusModeManager: ObservableObject {
    
    public static let shared = FocusModeManager()
    
    @Published public private(set) var currentSession: FocusSession?
    @Published public private(set) var isActive: Bool = false
    
    // Settings
    @Published public var isMusicEnabled: Bool = true
    @Published public var musicItems: [SpotifyItem] = []
    @Published public var borderSettings: FocusBorderSettings = FocusBorderSettings()
    @Published public var lastDuration: TimeInterval = 1500 // 25 min default
    
    private var timer: Timer?
    private let spotifyPlayer = SpotifyPlayerService()
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Session Management
    
    /// Start a new focus session
    public func startSession(duration: TimeInterval, goal: String? = nil) {
        // Save last duration for quick focus
        lastDuration = duration
        saveSettings()
        
        // Select random music if available and enabled
        let selectedMusic = isMusicEnabled ? musicItems.randomElement() : nil
        
        // Create and start session
        var session = FocusSession(
            duration: duration,
            goal: goal,
            selectedMusic: selectedMusic
        )
        session.start()
        
        currentSession = session
        isActive = true
        
        // Start timer
        startTimer()
        
        // Play music if selected and enabled
        if isMusicEnabled, let music = selectedMusic {
            Task {
                try? await spotifyPlayer.play(item: music)
            }
        }
        
        // Show border if enabled
        if borderSettings.isEnabled {
            FocusBorderWindowController.shared.show(settings: borderSettings)
        }
    }
    
    /// Pause the current session
    public func pauseSession() {
        guard var session = currentSession, session.state == .active else { return }
        session.pause()
        currentSession = session
        timer?.invalidate()
        
        // Pause music only if we started music
        if session.selectedMusic != nil {
            Task {
                try? await spotifyPlayer.pause()
            }
        }
    }
    
    /// Resume the current session
    public func resumeSession() {
        guard var session = currentSession, session.state == .paused else { return }
        session.resume()
        currentSession = session
        startTimer()
        
        // Resume music only if we started music
        if session.selectedMusic != nil {
            Task {
                try? await spotifyPlayer.resume()
            }
        }
    }
    
    /// Stop the current session
    public func stopSession() {
        guard var session = currentSession else { return }
        session.stop()
        currentSession = nil
        isActive = false
        timer?.invalidate()
        
        // Hide border
        FocusBorderWindowController.shared.hide()
        
        // Pause music only if we started music
        if session.selectedMusic != nil {
            Task {
                try? await spotifyPlayer.pause()
            }
        }
    }
    
    /// Complete the current session
    private func completeSession() {
        guard var session = currentSession else { return }
        session.complete()
        currentSession = nil
        isActive = false
        timer?.invalidate()
        
        // Hide border
        FocusBorderWindowController.shared.hide()
        
        // Send notification
        sendCompletionNotification(goal: session.goal)
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
    }
    
    private func timerTick() {
        guard let session = currentSession else { return }
        
        if session.remainingTime <= 0 {
            completeSession()
        } else {
            // Trigger UI update
            objectWillChange.send()
        }
    }
    
    // MARK: - Notifications
    
    private func sendCompletionNotification(goal: String?) {
        // Ensure we're on the main thread
        DispatchQueue.main.async {
            // Play a nicer sound
            if let sound = NSSound(named: "Glass") {
                sound.play()
            } else {
                NSSound.beep()
            }
            
            // Show a visible alert dialog
            let alert = NSAlert()
            alert.messageText = "Focus Session Complete! 🎉"
            alert.informativeText = goal ?? "Great work! Time for a break."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.icon = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)
            
            // Bring app to front and show alert
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
            
            // Also post to status bar for search window
            NotificationCenter.default.post(
                name: NSNotification.Name("UpdateStatusBar"),
                object: ("🎉", "Focus session complete!")
            )
        }
    }
    
    // MARK: - Music Management
    
    public func addMusicItem(_ item: SpotifyItem) {
        // Avoid duplicates - check by URL
        guard !musicItems.contains(where: { $0.url == item.url }) else {
            return
        }
        musicItems.append(item)
        saveSettings()
    }
    
    public func removeMusicItem(_ item: SpotifyItem) {
        musicItems.removeAll { $0.id == item.id }
        saveSettings()
    }
    
    // MARK: - Persistence
    
    private func loadSettings() {
        isMusicEnabled = UserDefaults.standard.object(forKey: "focusMusicEnabled") as? Bool ?? true
        
        if let data = UserDefaults.standard.data(forKey: "focusMusicItems"),
           let items = try? JSONDecoder().decode([SpotifyItem].self, from: data) {
            musicItems = items
        }
        
        if let data = UserDefaults.standard.data(forKey: "focusBorderSettings"),
           let settings = try? JSONDecoder().decode(FocusBorderSettings.self, from: data) {
            borderSettings = settings
        }
        
        lastDuration = UserDefaults.standard.double(forKey: "focusLastDuration")
        if lastDuration == 0 { lastDuration = 1500 }
    }
    
    
    public func saveSettings() {
        UserDefaults.standard.set(isMusicEnabled, forKey: "focusMusicEnabled")
        
        if let data = try? JSONEncoder().encode(musicItems) {
            UserDefaults.standard.set(data, forKey: "focusMusicItems")
        }
        
        if let data = try? JSONEncoder().encode(borderSettings) {
            UserDefaults.standard.set(data, forKey: "focusBorderSettings")
        }
        
        UserDefaults.standard.set(lastDuration, forKey: "focusLastDuration")
    }
}
