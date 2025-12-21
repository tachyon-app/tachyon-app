import Foundation

/// Timer-based scheduler for scripts with refreshTime
@MainActor
public class ScriptScheduler {
    public static let shared = ScriptScheduler()
    
    private var timers: [UUID: Timer] = [:]
    private let executor = ScriptExecutor()
    private let parser = MetadataParser()
    
    private init() {}
    
    /// Schedule a script for periodic execution
    /// - Parameters:
    ///   - script: Script record to schedule
    ///   - metadata: Parsed metadata containing refreshTime
    public func schedule(_ script: ScriptRecord, metadata: ScriptMetadata) {
        // Cancel existing timer if any
        cancel(scriptId: script.id)
        
        guard let refreshTime = metadata.refreshTime,
              let interval = parseRefreshTime(refreshTime) else {
            return
        }
        
        print("📅 Scheduling script '\(script.title)' to run every \(refreshTime)")
        
        // Create timer
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.executeScheduledScript(script, metadata: metadata)
            }
        }
        
        timers[script.id] = timer
        
        // Run immediately on first schedule
        Task {
            await executeScheduledScript(script, metadata: metadata)
        }
    }
    
    /// Cancel scheduled execution for a script
    /// - Parameter scriptId: ID of the script to cancel
    public func cancel(scriptId: UUID) {
        if let timer = timers[scriptId] {
            timer.invalidate()
            timers.removeValue(forKey: scriptId)
            print("🛑 Cancelled scheduled execution for script \(scriptId)")
        }
    }
    
    /// Cancel all scheduled scripts
    public func cancelAll() {
        for (_, timer) in timers {
            timer.invalidate()
        }
        timers.removeAll()
        print("🛑 Cancelled all scheduled scripts")
    }
    
    /// Parse refresh time string to TimeInterval
    /// Supports: "1h", "30m", "10s", "1d"
    /// - Parameter value: Refresh time string
    /// - Returns: TimeInterval in seconds, or nil if invalid
    private func parseRefreshTime(_ value: String) -> TimeInterval? {
        let trimmed = value.trimmingCharacters(in: .whitespaces).lowercased()
        
        // Extract number and unit
        guard let lastChar = trimmed.last,
              let unit = String(lastChar).first else {
            return nil
        }
        
        let numberString = String(trimmed.dropLast())
        guard let number = Double(numberString), number > 0 else {
            return nil
        }
        
        // Convert to seconds based on unit
        switch unit {
        case "s": // seconds
            return number
        case "m": // minutes
            return number * 60
        case "h": // hours
            return number * 60 * 60
        case "d": // days
            return number * 60 * 60 * 24
        default:
            return nil
        }
    }
    
    /// Execute a scheduled script
    private func executeScheduledScript(_ script: ScriptRecord, metadata: ScriptMetadata) async {
        let fileURL = ScriptFileManager.shared.scriptURL(for: script.fileName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("❌ Scheduled script file not found: \(script.fileName)")
            cancel(scriptId: script.id)
            return
        }
        
        print("⏰ Running scheduled script: \(script.title)")
        
        do {
            let result = try await executor.execute(
                fileURL: fileURL,
                metadata: metadata,
                arguments: [:] // Scheduled scripts run without arguments
            )
            
            if result.isSuccess {
                print("✅ Scheduled script '\(script.title)' completed successfully")
                
                // Update last executed time
                var updatedScript = script
                updatedScript.lastExecuted = Date()
                try? StorageManager.shared.saveScript(updatedScript)
            } else {
                print("❌ Scheduled script '\(script.title)' failed with exit code \(result.exitCode)")
                print("   stderr: \(result.stderr)")
            }
        } catch {
            print("❌ Error executing scheduled script '\(script.title)': \(error)")
        }
    }
}
