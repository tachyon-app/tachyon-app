import Foundation
import AppKit

/// Plugin providing system control commands
public class SystemCommandsPlugin: Plugin {
    public var id: String { "system-commands" }
    public var name: String { "System Commands" }
    
    private let executor = AppleScriptExecutor.shared
    private lazy var commands: [SystemCommand] = createCommands()
    
    public init() {}
    
    public func search(query: String) -> [QueryResult] {
        guard !query.isEmpty else { return [] }
        
        let lowercaseQuery = query.lowercased()
        
        // Filter commands by name or keywords
        let matchedCommands = commands.filter { command in
            command.name.lowercased().contains(lowercaseQuery) ||
            command.keywords.contains(where: { $0.lowercased().contains(lowercaseQuery) })
        }
        
        return matchedCommands.map { command in
            QueryResult(
                id: UUID(),
                title: command.name,
                subtitle: command.description,
                icon: command.icon,
                alwaysShow: false,
                hideWindowAfterExecution: true,
                action: {
                    Task {
                        let result = await command.action()
                        if result.success {
                            if let message = result.message {
                                self.showNotification(message)
                            }
                        } else {
                            let errorMsg = result.error?.localizedDescription ?? result.message ?? "Command failed"
                            self.showNotification("Error: \(errorMsg)")
                        }
                    }
                }
            )
        }
    }
    
    private func showNotification(_ message: String) {
        NotificationCenter.default.post(
            name: NSNotification.Name("UpdateStatusBar"),
            object: ("ℹ️", message)
        )
    }
    
    // MARK: - Command Definitions
    
    private func createCommands() -> [SystemCommand] {
        var commands: [SystemCommand] = []
        
        // MARK: Power & Session Commands
        
        commands.append(SystemCommand(
            id: "sleep",
            name: "Sleep",
            description: "Put your Mac to sleep",
            icon: "moon.zzz",
            keywords: ["sleep", "rest"],
            category: .power,
            action: { await self.executeSleep() }
        ))
        
        commands.append(SystemCommand(
            id: "sleep-displays",
            name: "Sleep Displays",
            description: "Turn off displays without sleeping the system",
            icon: "display",
            keywords: ["display", "screen", "sleep"],
            category: .power,
            action: { await self.executeSleepDisplays() }
        ))
        
        commands.append(SystemCommand(
            id: "lock",
            name: "Lock Screen",
            description: "Lock your Mac immediately",
            icon: "lock",
            keywords: ["lock", "secure"],
            category: .power,
            action: { await self.executeLock() }
        ))
        
        commands.append(SystemCommand(
            id: "logout",
            name: "Log Out",
            description: "End the current user session",
            icon: "rectangle.portrait.and.arrow.right",
            keywords: ["logout", "log out", "sign out"],
            category: .power,
            requiresConfirmation: true,
            action: { await self.executeLogout() }
        ))
        
        commands.append(SystemCommand(
            id: "restart",
            name: "Restart",
            description: "Restart your Mac",
            icon: "arrow.clockwise",
            keywords: ["restart", "reboot"],
            category: .power,
            requiresConfirmation: true,
            action: { await self.executeRestart() }
        ))
        
        commands.append(SystemCommand(
            id: "shutdown",
            name: "Shutdown",
            description: "Shut down your Mac",
            icon: "power",
            keywords: ["shutdown", "shut down", "power off"],
            category: .power,
            requiresConfirmation: true,
            action: { await self.executeShutdown() }
        ))
        
        // MARK: Settings & Appearance Commands
        
        commands.append(SystemCommand(
            id: "toggle-dark-mode",
            name: "Toggle System Appearance",
            description: "Switch between Light and Dark mode",
            icon: "moon.circle",
            keywords: ["dark mode", "light mode", "appearance", "theme"],
            category: .settings,
            action: { await self.executeToggleDarkMode() }
        ))
        
        commands.append(SystemCommand(
            id: "toggle-wifi",
            name: "Toggle Wi-Fi",
            description: "Turn Wi-Fi on or off",
            icon: "wifi",
            keywords: ["wifi", "wi-fi", "wireless", "network"],
            category: .settings,
            action: { await self.executeToggleWiFi() }
        ))
        
        commands.append(SystemCommand(
            id: "toggle-bluetooth",
            name: "Toggle Bluetooth",
            description: "Turn Bluetooth on or off",
            icon: "wave.3.right",
            keywords: ["bluetooth", "bt"],
            category: .settings,
            action: { await self.executeToggleBluetooth() }
        ))
        
        commands.append(SystemCommand(
            id: "toggle-night-shift",
            name: "Toggle Night Shift",
            description: "Enable or disable Night Shift",
            icon: "sun.max",
            keywords: ["night shift", "blue light"],
            category: .settings,
            action: { await self.executeToggleNightShift() }
        ))
        
        commands.append(SystemCommand(
            id: "toggle-true-tone",
            name: "Toggle True Tone",
            description: "Enable or disable True Tone display",
            icon: "sun.min",
            keywords: ["true tone", "display"],
            category: .settings,
            action: { await self.executeToggleTrueTone() }
        ))
        
        // MARK: Audio Commands
        
        commands.append(SystemCommand(
            id: "mute",
            name: "Mute",
            description: "Mute system audio",
            icon: "speaker.slash",
            keywords: ["mute", "silence", "quiet"],
            category: .audio,
            action: { await self.executeMute() }
        ))
        
        commands.append(SystemCommand(
            id: "unmute",
            name: "Unmute",
            description: "Unmute system audio",
            icon: "speaker.wave.2",
            keywords: ["unmute", "sound"],
            category: .audio,
            action: { await self.executeUnmute() }
        ))
        
        for volume in [0, 25, 50, 75, 100] {
            commands.append(SystemCommand(
                id: "volume-\(volume)",
                name: "Set Volume to \(volume)%",
                description: "Set system volume to \(volume)%",
                icon: "speaker.wave.3",
                keywords: ["volume", "\(volume)"],
                category: .audio,
                action: { await self.executeSetVolume(volume) }
            ))
        }
        
        // MARK: File Management Commands
        
        commands.append(SystemCommand(
            id: "empty-trash",
            name: "Empty Trash",
            description: "Permanently delete all items in Trash",
            icon: "trash",
            keywords: ["trash", "delete", "empty"],
            category: .fileManagement,
            requiresConfirmation: true,
            action: { await self.executeEmptyTrash() }
        ))
        
        commands.append(SystemCommand(
            id: "open-trash",
            name: "Open Trash",
            description: "Open the Trash folder in Finder",
            icon: "trash.circle",
            keywords: ["trash", "open"],
            category: .fileManagement,
            action: { await self.executeOpenTrash() }
        ))
        
        commands.append(SystemCommand(
            id: "toggle-hidden-files",
            name: "Toggle Hidden Files",
            description: "Show or hide hidden files in Finder",
            icon: "eye.slash",
            keywords: ["hidden files", "dotfiles", "show", "hide"],
            category: .fileManagement,
            action: { await self.executeToggleHiddenFiles() }
        ))
        
        commands.append(SystemCommand(
            id: "eject-all",
            name: "Eject All Disks",
            description: "Safely eject all external drives",
            icon: "eject",
            keywords: ["eject", "unmount", "disk", "drive"],
            category: .fileManagement,
            action: { await self.executeEjectAll() }
        ))
        
        // MARK: Application Management Commands
        
        commands.append(SystemCommand(
            id: "quit-all-apps",
            name: "Quit All Applications",
            description: "Close all running applications",
            icon: "xmark.app",
            keywords: ["quit", "close", "apps"],
            category: .appManagement,
            requiresConfirmation: true,
            action: { await self.executeQuitAllApps() }
        ))
        
        commands.append(SystemCommand(
            id: "hide-others",
            name: "Hide All Apps Except Frontmost",
            description: "Hide all applications except the current one",
            icon: "eye.slash.circle",
            keywords: ["hide", "focus"],
            category: .appManagement,
            action: { await self.executeHideOthers() }
        ))
        
        commands.append(SystemCommand(
            id: "unhide-all",
            name: "Unhide All Hidden Apps",
            description: "Show all hidden applications",
            icon: "eye.circle",
            keywords: ["unhide", "show"],
            category: .appManagement,
            action: { await self.executeUnhideAll() }
        ))
        
        commands.append(SystemCommand(
            id: "show-desktop",
            name: "Show Desktop",
            description: "Reveal the desktop by moving all windows aside",
            icon: "macwindow",
            keywords: ["desktop", "show"],
            category: .appManagement,
            action: { await self.executeShowDesktop() }
        ))
        
        return commands
    }
    
    // MARK: - Power & Session Implementations
    
    private func executeSleep() async -> CommandResult {
        let script = "tell application \"System Events\" to sleep"
        let result = await executor.executeAsync(script)
        return result.success ? .success("Mac is going to sleep") : .failure(result.error ?? "Failed to sleep")
    }
    
    private func executeSleepDisplays() async -> CommandResult {
        // Use pmset to sleep displays
        let result = await executor.executeShellCommandAsync("pmset displaysleepnow")
        return result.success ? .success("Displays sleeping") : .failure(result.error ?? "Failed to sleep displays")
    }
    
    private func executeLock() async -> CommandResult {
        let script = """
        tell application "System Events"
            keystroke "q" using {command down, control down}
        end tell
        """
        let result = await executor.executeAsync(script)
        return result.success ? .success() : .failure(result.error ?? "Failed to lock screen")
    }
    
    private func executeLogout() async -> CommandResult {
        let script = "tell application \"System Events\" to log out"
        let result = await executor.executeAsync(script)
        return result.success ? .success() : .failure(result.error ?? "Failed to log out")
    }
    
    private func executeRestart() async -> CommandResult {
        let script = "tell application \"System Events\" to restart"
        let result = await executor.executeAsync(script)
        return result.success ? .success() : .failure(result.error ?? "Failed to restart")
    }
    
    private func executeShutdown() async -> CommandResult {
        let script = "tell application \"System Events\" to shut down"
        let result = await executor.executeAsync(script)
        return result.success ? .success() : .failure(result.error ?? "Failed to shut down")
    }
    
    // MARK: - Settings & Appearance Implementations
    
    private func executeToggleDarkMode() async -> CommandResult {
        let script = """
        tell application "System Events"
            tell appearance preferences
                set dark mode to not dark mode
            end tell
        end tell
        """
        let result = await executor.executeAsync(script)
        return result.success ? .success("Appearance toggled") : .failure(result.error ?? "Failed to toggle appearance")
    }
    
    private func executeToggleWiFi() async -> CommandResult {
        // Get current WiFi state
        let getStateScript = "do shell script \"networksetup -getairportpower en0\""
        let stateResult = await executor.executeAsync(getStateScript)
        
        guard stateResult.success, let output = stateResult.output else {
            return .failure("Failed to get WiFi state")
        }
        
        let isOn = output.contains("On")
        let newState = isOn ? "off" : "on"
        
        let toggleScript = "do shell script \"networksetup -setairportpower en0 \(newState)\""
        let result = await executor.executeAsync(toggleScript)
        
        return result.success ? .success("WiFi turned \(newState)") : .failure(result.error ?? "Failed to toggle WiFi")
    }
    
    private func executeToggleBluetooth() async -> CommandResult {
        let script = "do shell script \"blueutil --power toggle\""
        let result = await executor.executeAsync(script)
        return result.success ? .success("Bluetooth toggled") : .failure(result.error ?? "Failed to toggle Bluetooth")
    }
    
    private func executeToggleNightShift() async -> CommandResult {
        // Night Shift toggle requires CoreBrightness framework or defaults
        let script = """
        do shell script "osascript -e 'tell application \\"System Preferences\\"' -e 'reveal pane id \\"com.apple.preference.displays\\"' -e 'end tell'"
        """
        let result = await executor.executeAsync(script)
        return result.success ? .success("Opening Night Shift settings") : .failure(result.error ?? "Failed to toggle Night Shift")
    }
    
    private func executeToggleTrueTone() async -> CommandResult {
        // True Tone requires private frameworks, open System Preferences instead
        let script = """
        do shell script "osascript -e 'tell application \\"System Preferences\\"' -e 'reveal pane id \\"com.apple.preference.displays\\"' -e 'end tell'"
        """
        let result = await executor.executeAsync(script)
        return result.success ? .success("Opening True Tone settings") : .failure(result.error ?? "Failed to toggle True Tone")
    }
    
    // MARK: - Audio Implementations
    
    private func executeMute() async -> CommandResult {
        let script = "set volume output muted true"
        let result = await executor.executeAsync(script)
        return result.success ? .success("Audio muted") : .failure(result.error ?? "Failed to mute")
    }
    
    private func executeUnmute() async -> CommandResult {
        let script = "set volume output muted false"
        let result = await executor.executeAsync(script)
        return result.success ? .success("Audio unmuted") : .failure(result.error ?? "Failed to unmute")
    }
    
    private func executeSetVolume(_ percentage: Int) async -> CommandResult {
        let script = "set volume output volume \(percentage)"
        let result = await executor.executeAsync(script)
        return result.success ? .success("Volume set to \(percentage)%") : .failure(result.error ?? "Failed to set volume")
    }
    
    // MARK: - File Management Implementations
    
    private func executeEmptyTrash() async -> CommandResult {
        let script = """
        tell application "Finder"
            empty trash
        end tell
        """
        let result = await executor.executeAsync(script)
        return result.success ? .success("Trash emptied") : .failure(result.error ?? "Failed to empty trash")
    }
    
    private func executeOpenTrash() async -> CommandResult {
        let script = """
        tell application "Finder"
            open trash
            activate
        end tell
        """
        let result = await executor.executeAsync(script)
        return result.success ? .success() : .failure(result.error ?? "Failed to open trash")
    }
    
    private func executeToggleHiddenFiles() async -> CommandResult {
        let script = """
        do shell script "defaults read com.apple.finder AppleShowAllFiles"
        """
        let readResult = await executor.executeAsync(script)
        
        let currentValue = readResult.output?.trimmingCharacters(in: .whitespacesAndNewlines) == "1"
        let newValue = !currentValue
        
        let toggleScript = """
        do shell script "defaults write com.apple.finder AppleShowAllFiles \(newValue ? "TRUE" : "FALSE"); killall Finder"
        """
        let result = await executor.executeAsync(toggleScript)
        
        return result.success ? .success("Hidden files \(newValue ? "shown" : "hidden")") : .failure(result.error ?? "Failed to toggle hidden files")
    }
    
    private func executeEjectAll() async -> CommandResult {
        let script = """
        tell application "Finder"
            eject (every disk whose ejectable is true)
        end tell
        """
        let result = await executor.executeAsync(script)
        return result.success ? .success("All disks ejected") : .failure(result.error ?? "Failed to eject disks")
    }
    
    // MARK: - Application Management Implementations
    
    private func executeQuitAllApps() async -> CommandResult {
        return await MainActor.run {
            let runningApps = NSWorkspace.shared.runningApplications
            var quitCount = 0
            
            for app in runningApps {
                // Don't quit Finder or this app
                if app.activationPolicy == .regular &&
                   !app.isTerminated &&
                   app.bundleIdentifier != "com.apple.finder" &&
                   app.bundleIdentifier != Bundle.main.bundleIdentifier {
                    app.terminate()
                    quitCount += 1
                }
            }
            
            return .success("Quit \(quitCount) applications")
        }
    }
    
    private func executeHideOthers() async -> CommandResult {
        let script = """
        tell application "System Events"
            set frontApp to name of first application process whose frontmost is true
            set visible of every application process whose name is not frontApp to false
        end tell
        """
        let result = await executor.executeAsync(script)
        return result.success ? .success("Hidden all other apps") : .failure(result.error ?? "Failed to hide apps")
    }
    
    private func executeUnhideAll() async -> CommandResult {
        let script = """
        tell application "System Events"
            set visible of every application process to true
        end tell
        """
        let result = await executor.executeAsync(script)
        return result.success ? .success("Unhidden all apps") : .failure(result.error ?? "Failed to unhide apps")
    }
    
    private func executeShowDesktop() async -> CommandResult {
        let script = """
        tell application "System Events"
            key code 103 using {command down, function down}
        end tell
        """
        let result = await executor.executeAsync(script)
        return result.success ? .success() : .failure(result.error ?? "Failed to show desktop")
    }
}
