import Foundation
import Combine
import AppKit

/// Central manager for focus mode state and coordination
public class FocusModeManager: ObservableObject {
    
    public static let shared = FocusModeManager()
    
    @Published public private(set) var currentSession: FocusSession?
    @Published public private(set) var isActive: Bool = false
    
    // Settings
    @Published public var currentProfile: FocusProfileRecord?
    @Published public var musicItems: [SpotifyItem] = []
    
    // Computed properties for UI compatibility
    public var isMusicEnabled: Bool {
        get { currentProfile?.isMusicEnabled ?? true }
        set {
            if var profile = currentProfile {
                profile.isMusicEnabled = newValue
                updateProfile(profile)
            }
        }
    }
    
    public var borderSettings: FocusBorderSettings {
        get { currentProfile?.borderSettings ?? FocusBorderSettings() }
        set {
            if var profile = currentProfile {
                profile.borderSettings = newValue
                updateProfile(profile)
            }
        }
    }
    
    public var lastDuration: TimeInterval {
        get { currentProfile?.lastDuration ?? 1500 }
        set {
            if var profile = currentProfile {
                profile.lastDuration = newValue
                updateProfile(profile)
            }
        }
    }
    
    public var prefersStatusBar: Bool {
        get { currentProfile?.prefersStatusBar ?? false }
        set {
            if var profile = currentProfile {
                profile.prefersStatusBar = newValue
                updateProfile(profile)
            }
        }
    }
    
    private var timer: Timer?
    private let spotifyPlayer = SpotifyPlayerService()
    private let repository: FocusProfileRepository
    
    private init() {
        // Initialize repository with shared DB queue
        // In a real app we might want dependency injection, but this is a singleton
        guard let dbQueue = StorageManager.shared.dbQueue else {
            fatalError("Database not initialized")
        }
        self.repository = FocusProfileRepository(dbQueue: dbQueue)
        
        loadSettings()
    }
    
    // MARK: - Session Management
    
    /// Start a new focus session
    public func startSession(duration: TimeInterval, goal: String? = nil) {
        // Save last duration for quick focus
        if var profile = currentProfile {
            profile.lastDuration = duration
            updateProfile(profile)
        }
        
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
        
        // Show timer UI based on user preference
        if prefersStatusBar {
            FocusStatusBarController.shared.show()
        } else {
            FocusBarWindowController.shared.show()
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
    
    /// Complete the current session (ends immediately with success)
    public func completeSession() {
        guard var session = currentSession else { return }
        session.complete()
        currentSession = nil
        isActive = false
        timer?.invalidate()
        
        // Flash green border for celebration
        FocusBorderWindowController.shared.flashGreen()
        
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
        // Show custom notification window (styled like Raycast)
        FocusCompletionNotification.show(goal: goal)
        
        // Also post to internal notification center
        NotificationCenter.default.post(
            name: NSNotification.Name("UpdateStatusBar"),
            object: ("🎉", "Focus session complete!")
        )
    }
    
    // MARK: - Music Management
    
    public func addMusicItem(_ item: SpotifyItem) {
        guard let profile = currentProfile else { return }
        
        // Avoid duplicates - check by URL
        guard !musicItems.contains(where: { $0.url == item.url }) else {
            return
        }
        
        let record = SpotifyItemRecord(
            profileId: profile.id,
            url: item.url,
            type: item.type.rawValue,
            title: item.title
        )
        
        do {
            try repository.addSpotifyItem(record)
            loadMusicItems() // Reload from DB
        } catch {
            print("Failed to add music item: \(error)")
        }
    }
    
    public func removeMusicItem(_ item: SpotifyItem) {
        guard let _ = currentProfile else { return }
        
        do {
            try repository.removeSpotifyItem(item.id)
            loadMusicItems() // Reload from DB
        } catch {
            print("Failed to remove music item: \(error)")
        }
    }
    
    // MARK: - Persistence
    
    // Compatibility method for UI calls
    public func saveSettings() {
        if let profile = currentProfile {
            updateProfile(profile)
        }
    }
    
    private func loadSettings() {
        do {
            // Load active profile
            if let profile = try repository.fetchActiveProfile() {
                self.currentProfile = profile
                loadMusicItems()
            } else {
                print("No active profile found")
            }
        } catch {
            print("Failed to load settings: \(error)")
        }
    }
    
    private func loadMusicItems() {
        guard let profile = currentProfile else { return }
        
        do {
            let records = try repository.fetchSpotifyItems(for: profile.id)
            self.musicItems = records.map { $0.toSpotifyItem() }
        } catch {
            print("Failed to load music items: \(error)")
        }
    }
    
    private func updateProfile(_ profile: FocusProfileRecord) {
        do {
            try repository.save(profile)
            self.currentProfile = profile
        } catch {
            print("Failed to save profile: \(error)")
        }
    }
}
