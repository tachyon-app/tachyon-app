import Foundation
import AppKit
import GRDB

/// Plugin for script command execution
@MainActor
public class ScriptRunnerPlugin: Plugin {
    public var id: String { "script-runner" }
    public var name: String { "Script Commands" }
    
    private var scripts: [ScriptRecord] = []
    private var metadataCache: [UUID: ScriptMetadata] = [:]
    private var inlineOutputCache: [UUID: String] = [:] // For inline mode
    private var scheduledScripts: Set<UUID> = [] // Track which scripts are scheduled
    private var cancellable: AnyDatabaseCancellable?
    
    private let parser = MetadataParser()
    private let executor = ScriptExecutor()
    private let scheduler = ScriptScheduler.shared
    
    public init() {
        startObservation()
    }
    
    private func startObservation() {
        let request = ScriptRecord.all()
        let observation = ValueObservation.tracking { db in
            try request.fetchAll(db)
        }
        
        guard let dbQueue = StorageManager.shared.dbQueue else {
            print("❌ StorageManager DB not available for ScriptRunner")
            return
        }
        
        cancellable = observation.start(
            in: dbQueue,
            onError: { error in
                print("❌ ScriptRunnerPlugin observation error: \(error)")
            },
            onChange: { [weak self] scripts in
                Task { @MainActor in
                    await self?.handleScriptsUpdate(scripts)
                }
            }
        )
    }
    
    private func handleScriptsUpdate(_ scripts: [ScriptRecord]) async {
        self.scripts = scripts.filter { $0.isEnabled }
        print("✅ ScriptRunnerPlugin updated with \(self.scripts.count) enabled scripts")
        
        // Parse metadata and schedule scripts with refreshTime
        for script in self.scripts {
            let fileURL = ScriptFileManager.shared.scriptURL(for: script.fileName)
            
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                continue
            }
            
            do {
                let metadata = try parser.parse(fileURL: fileURL)
                metadataCache[script.id] = metadata
                
                // Schedule if has refreshTime (only if not already scheduled)
                if let refreshTime = metadata.refreshTime {
                    if !scheduledScripts.contains(script.id) {
                    scheduledScripts.insert(script.id)
                } else if metadata.refreshTime == nil && scheduledScripts.contains(script.id) {
                        print("📅 Scheduled script '\(script.title)' for every \(refreshTime)")
                    }
                } else if scheduledScripts.contains(script.id) {
                }
                
                // For inline mode, execute once to get initial output
                if script.scriptMode == .inline && metadata.arguments.isEmpty {
                    await updateInlineOutput(for: script, metadata: metadata)
                }
            } catch {
                print("❌ Failed to parse metadata for script '\(script.title)': \(error)")
            }
        }
        
        // Cancel scheduling for scripts that were removed or disabled
        let currentScriptIds = Set(self.scripts.map { $0.id })
        let removedScriptIds = scheduledScripts.subtracting(currentScriptIds)
        for scriptId in removedScriptIds {
            scheduler.cancel(scriptId: scriptId)
            scheduledScripts.remove(scriptId)
        }
    }
    
    /// Update inline output cache for a script
    private func updateInlineOutput(for script: ScriptRecord, metadata: ScriptMetadata) async {
        let fileURL = ScriptFileManager.shared.scriptURL(for: script.fileName)
        
        do {
            let result = try await executor.execute(
                fileURL: fileURL,
                metadata: metadata,
                arguments: [:]
            )
            
            if result.isSuccess {
                // Get first line of output
                let firstLine = result.stdout
                    .components(separatedBy: .newlines)
                    .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                
                inlineOutputCache[script.id] = firstLine ?? ""
            }
        } catch {
            print("❌ Failed to get inline output for '\(script.title)': \(error)")
        }
    }
    
    public func search(query: String) -> [QueryResult] {
        guard !query.isEmpty else { return [] }
        
        return scripts
            .filter { $0.title.localizedCaseInsensitiveContains(query) ||
                     $0.packageName?.localizedCaseInsensitiveContains(query) == true }
            .map { script in
                let metadata = metadataCache[script.id]
                let subtitle = buildSubtitle(for: script, metadata: metadata)
                
                return QueryResult(
                    id: script.id,
                    title: script.title,
                    subtitle: subtitle,
                    icon: metadata?.icon ?? "⚡️",
                    iconData: script.icon,
                    alwaysShow: false,
                    hideWindowAfterExecution: false,
                    action: { [weak self] in
                        Task { @MainActor in
                            await self?.executeScript(script)
                        }
                    }
                )
            }
    }
    
    private func buildSubtitle(for script: ScriptRecord, metadata: ScriptMetadata?) -> String {
        // For inline mode, show cached output
        if script.scriptMode == .inline, let output = inlineOutputCache[script.id] {
            return output
        }
        
        // Show package name if available
        if let packageName = script.packageName {
            return packageName
        }
        
        // Show mode
        return "Script Command · \(script.scriptMode.rawValue)"
    }
    
    private func executeScript(_ script: ScriptRecord) async {
        let fileURL = ScriptFileManager.shared.scriptURL(for: script.fileName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("❌ Script file not found: \(script.fileName)")
            // TODO: Show error notification
            return
        }
        
        guard let metadata = metadataCache[script.id] else {
            print("❌ Metadata not cached for script: \(script.title)")
            return
        }
        
        // Check if script needs arguments
        let requiredArgs = metadata.arguments.filter { !$0.optional }
        if !requiredArgs.isEmpty {
            // TODO: Show argument input form
            print("📝 Script requires arguments - showing input form")
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowScriptArgumentForm"),
                object: (script, metadata)
            )
            return
        }
        
        // Check if needs confirmation
        if metadata.needsConfirmation {
            // TODO: Show confirmation dialog
            print("⚠️ Script needs confirmation")
        }
        
        // Execute based on mode
        switch script.scriptMode {
        case .fullOutput:
            // TODO: Show full output view
            print("📺 Showing full output view for '\(script.title)'")
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowScriptOutputView"),
                object: (script, metadata)
            )
            
        case .compact, .silent, .inline:
            // Execute in background and update status bar
            await executeInBackground(script, metadata: metadata)
        }
    }
    
    private func executeInBackground(_ script: ScriptRecord, metadata: ScriptMetadata) async {
        let fileURL = ScriptFileManager.shared.scriptURL(for: script.fileName)
        
        // Update status bar: "Executing..."
        NotificationCenter.default.post(
            name: NSNotification.Name("UpdateStatusBar"),
            object: ("⏳", "Executing \(script.title)...")
        )
        
        do {
            let result = try await executor.execute(
                fileURL: fileURL,
                metadata: metadata,
                arguments: [:]
            )
            
            // Update last executed
            var updatedScript = script
            updatedScript.lastExecuted = Date()
            try? StorageManager.shared.saveScript(updatedScript)
            
            if result.isSuccess {
                handleSuccessfulExecution(script, metadata: metadata, result: result)
            } else {
                handleFailedExecution(script, result: result)
            }
        } catch {
            print("❌ Execution error for '\(script.title)': \(error)")
            NotificationCenter.default.post(
                name: NSNotification.Name("UpdateStatusBar"),
                object: ("❌", "Error: \(error.localizedDescription)")
            )
        }
    }
    
    private func handleSuccessfulExecution(_ script: ScriptRecord, metadata: ScriptMetadata, result: ScriptExecutor.ExecutionResult) {
        switch script.scriptMode {
        case .compact:
            // Show last non-empty line
            let lastLine = result.stdout
                .components(separatedBy: .newlines)
                .reversed()
                .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? ""
            
            NotificationCenter.default.post(
                name: NSNotification.Name("UpdateStatusBar"),
                object: ("✅", lastLine)
            )
            
            // Clear search query to collapse results
            NotificationCenter.default.post(
                name: NSNotification.Name("ClearSearchQuery"),
                object: nil
            )
            
        case .inline:
            // Update cache with first line
            let firstLine = result.stdout
                .components(separatedBy: .newlines)
                .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? ""
            
            inlineOutputCache[script.id] = firstLine
            
            // Show success message in status bar
            NotificationCenter.default.post(
                name: NSNotification.Name("UpdateStatusBar"),
                object: ("✅", "Updated inline output")
            )
            
            // Clear search query to collapse results
            NotificationCenter.default.post(
                name: NSNotification.Name("ClearSearchQuery"),
                object: nil
            )
            
            print("📢 Posting RefreshSearchResults notification")            
            // Trigger search results refresh to show updated inline output
            NotificationCenter.default.post(
                name: NSNotification.Name("RefreshSearchResults"),
                object: nil
            )
        case .silent:
            NotificationCenter.default.post(
                name: NSNotification.Name("UpdateStatusBar"),
                object: ("✅", "Script finished running")
            )
            
            // Clear search query to collapse results
            NotificationCenter.default.post(
                name: NSNotification.Name("ClearSearchQuery"),
                object: nil
            )
            
        case .fullOutput:
            break // Handled separately
        }
    }
    
    private func handleFailedExecution(_ script: ScriptRecord, result: ScriptExecutor.ExecutionResult) {
        let errorMessage = "Script failed with code \(result.exitCode)"
        NotificationCenter.default.post(
            name: NSNotification.Name("UpdateStatusBar"),
            object: ("❌", errorMessage)
        )
    }
}
