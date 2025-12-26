import Foundation

/// Represents a focus session with timer and state management
public struct FocusSession: Identifiable {
    public let id: UUID
    public var goal: String?
    public var duration: TimeInterval
    public var startTime: Date?
    public var pausedAt: Date?
    public var totalPausedTime: TimeInterval = 0
    public var state: FocusSessionState = .pending
    public var selectedMusic: SpotifyItem?
    
    public init(
        id: UUID = UUID(),
        duration: TimeInterval,
        goal: String? = nil,
        selectedMusic: SpotifyItem? = nil
    ) {
        self.id = id
        self.duration = duration
        self.goal = goal
        self.selectedMusic = selectedMusic
    }
    
    /// Remaining time in seconds
    public var remainingTime: TimeInterval {
        guard let startTime = startTime else { return duration }
        
        let elapsed: TimeInterval
        if let pausedAt = pausedAt {
            // If paused, calculate elapsed up to pause point
            elapsed = pausedAt.timeIntervalSince(startTime) - totalPausedTime
        } else {
            // If active, calculate elapsed up to now
            elapsed = Date().timeIntervalSince(startTime) - totalPausedTime
        }
        
        return max(0, duration - elapsed)
    }
    
    /// Whether the session timer has completed
    public var isComplete: Bool {
        return state == .active && remainingTime <= 0
    }
    
    // MARK: - State Transitions
    
    public mutating func start() {
        guard state == .pending else { return }
        startTime = Date()
        state = .active
    }
    
    public mutating func pause() {
        guard state == .active else { return }
        pausedAt = Date()
        state = .paused
    }
    
    public mutating func resume() {
        guard state == .paused, let pausedAt = pausedAt else { return }
        totalPausedTime += Date().timeIntervalSince(pausedAt)
        self.pausedAt = nil
        state = .active
    }
    
    public mutating func stop() {
        state = .cancelled
    }
    
    public mutating func complete() {
        state = .completed
    }
}

/// State of a focus session
public enum FocusSessionState: String, Codable {
    case pending
    case active
    case paused
    case completed
    case cancelled
}
