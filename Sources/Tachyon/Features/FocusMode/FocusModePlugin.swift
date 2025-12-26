import Foundation
import AppKit

/// Search plugin for Focus Mode commands
public class FocusModePlugin: Plugin {
    
    public var id: String { "focus-mode" }
    public var name: String { "Focus Mode" }
    
    private let manager = FocusModeManager.shared
    
    public init() {}
    
    public func search(query: String) -> [QueryResult] {
        let lowercased = query.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Handle stop/pause commands
        if lowercased == "stop focus" || lowercased == "end focus" {
            return [createStopResult()]
        }
        
        if lowercased == "pause focus" {
            return [createPauseResult()]
        }
        
        if lowercased == "resume focus" {
            return [createResumeResult()]
        }
        
        // Check if query starts with "focus"
        guard lowercased.hasPrefix("focus") else {
            return []
        }
        
        // Parse duration from query
        let remainder = String(lowercased.dropFirst(5)).trimmingCharacters(in: .whitespaces)
        
        if remainder.isEmpty {
            // Quick focus with last config
            return [createQuickFocusResult()]
        }
        
        // Parse duration
        if let duration = parseDuration(from: remainder) {
            return [createFocusResult(duration: duration)]
        }
        
        // Show preset options
        return createPresetResults()
    }
    
    // MARK: - Duration Parsing
    
    private func parseDuration(from text: String) -> TimeInterval? {
        let pattern = #"(\d+)\s*(min|mins|minute|minutes|hour|hours|h|m)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
              let numberRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        
        guard let number = Double(text[numberRange]) else { return nil }
        
        // Check for unit
        let unitRange = Range(match.range(at: 2), in: text)
        let unit = unitRange.map { String(text[$0]).lowercased() } ?? "min"
        
        switch unit {
        case "hour", "hours", "h":
            return number * 3600
        default:
            return number * 60
        }
    }
    
    // MARK: - Result Creation
    
    private func createQuickFocusResult() -> QueryResult {
        let duration = manager.lastDuration
        let minutes = Int(duration / 60)
        
        return QueryResult(
            id: UUID(),
            title: "Start Focus Session",
            subtitle: "\(minutes) minutes (last used)",
            icon: "timer",
            alwaysShow: true,
            action: { [weak self] in
                self?.manager.startSession(duration: duration)
                FocusBarWindowController.shared.show()
            }
        )
    }
    
    private func createFocusResult(duration: TimeInterval) -> QueryResult {
        let minutes = Int(duration / 60)
        let displayTime = duration >= 3600 ? 
            "\(Int(duration / 3600)) hour\(duration >= 7200 ? "s" : "")" : 
            "\(minutes) minute\(minutes != 1 ? "s" : "")"
        
        return QueryResult(
            id: UUID(),
            title: "Start Focus Session",
            subtitle: displayTime,
            icon: "timer",
            alwaysShow: true,
            action: { [weak self] in
                self?.manager.startSession(duration: duration)
                FocusBarWindowController.shared.show()
            }
        )
    }
    
    private func createPresetResults() -> [QueryResult] {
        let presets: [(minutes: Int, label: String)] = [
            (15, "15 minutes"),
            (25, "25 minutes (Pomodoro)"),
            (45, "45 minutes"),
            (60, "1 hour")
        ]
        
        return presets.map { preset in
            QueryResult(
                id: UUID(),
                title: "Focus for \(preset.label)",
                subtitle: "Start a focus session",
                icon: "timer",
                alwaysShow: true,
                action: { [weak self] in
                    self?.manager.startSession(duration: TimeInterval(preset.minutes * 60))
                    FocusBarWindowController.shared.show()
                }
            )
        }
    }
    
    private func createStopResult() -> QueryResult {
        return QueryResult(
            id: UUID(),
            title: "Stop Focus Session",
            subtitle: "End your current focus session",
            icon: "stop.circle",
            alwaysShow: true,
            action: { [weak self] in
                self?.manager.stopSession()
                FocusBarWindowController.shared.hide()
            }
        )
    }
    
    private func createPauseResult() -> QueryResult {
        return QueryResult(
            id: UUID(),
            title: "Pause Focus Session",
            subtitle: "Temporarily pause your session",
            icon: "pause.circle",
            alwaysShow: true,
            action: { [weak self] in
                self?.manager.pauseSession()
            }
        )
    }
    
    private func createResumeResult() -> QueryResult {
        return QueryResult(
            id: UUID(),
            title: "Resume Focus Session",
            subtitle: "Continue your paused session",
            icon: "play.circle",
            alwaysShow: true,
            action: { [weak self] in
                self?.manager.resumeSession()
            }
        )
    }
}
