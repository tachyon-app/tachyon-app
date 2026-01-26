import Foundation
import Combine
import AppKit

/// ViewModel for Scene settings management
@MainActor
public class ScenesSettingsViewModel: ObservableObject {
    @Published public var scenes: [WindowScene] = []
    @Published public var isLoading = false
    @Published public var activationMessage: String?
    
    private var repository: SceneRepository?
    private let activationService = SceneActivationService()
    
    public init() {
        setupRepository()
        setupNotifications()
    }
    
    private func setupRepository() {
        guard let dbQueue = StorageManager.shared.dbQueue else {
            print("❌ Database not available")
            return
        }
        repository = SceneRepository(dbQueue: dbQueue)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .scenesDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadScenes()
        }
    }
    
    // MARK: - Loading
    
    public func loadScenes() {
        guard let repository = repository else { return }
        
        isLoading = true
        
        Task {
            do {
                scenes = try repository.fetchAll()
                isLoading = false
            } catch {
                print("❌ Failed to load scenes: \(error)")
                isLoading = false
            }
        }
    }
    
    // MARK: - Activation
    
    /// Activate a scene
    public func activateScene(_ scene: WindowScene, forcePartial: Bool = false) {
        guard let repository = repository else { return }
        
        activationMessage = "Activating scene..."
        
        Task {
            do {
                let windows = try repository.fetchWindows(forSceneId: scene.id)
                let result = try await activationService.activate(scene, windows: windows, forcePartial: forcePartial)
                
                switch result {
                case .success(let applied, let launched):
                    var message = "✅ Activated \(applied) windows"
                    if !launched.isEmpty {
                        message += ", launched: \(launched.joined(separator: ", "))"
                    }
                    activationMessage = message
                    
                case .partialMatch(let applied, let skipped, let launched):
                    var message = "⚠️ Partial: \(applied) applied, \(skipped) skipped"
                    if !launched.isEmpty {
                        message += ", launched: \(launched.joined(separator: ", "))"
                    }
                    activationMessage = message
                    
                case .displayMismatch(let required, let current):
                    activationMessage = "❌ Requires \(required) displays, but only \(current) connected"
                    
                case .failed(let error):
                    activationMessage = "❌ Failed: \(error.localizedDescription)"
                }
                
                // Clear message after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    self?.activationMessage = nil
                }
            } catch {
                activationMessage = "❌ Error: \(error.localizedDescription)"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    self?.activationMessage = nil
                }
            }
        }
    }
    
    // MARK: - Mutations
    
    /// Delete a scene
    public func deleteScene(_ scene: WindowScene) {
        guard let repository = repository else { return }
        
        Task {
            do {
                try repository.delete(id: scene.id)
                loadScenes()
                
                NotificationCenter.default.post(name: .scenesDidChange, object: nil)
                print("✅ Deleted scene: \(scene.name)")
            } catch {
                print("❌ Failed to delete scene: \(error)")
            }
        }
    }
    
    /// Rename a scene
    public func renameScene(_ scene: WindowScene, to newName: String) {
        guard let repository = repository else { return }
        
        var updated = scene
        updated.name = newName
        
        Task {
            do {
                try repository.update(updated)
                loadScenes()
                print("✅ Renamed scene to: \(newName)")
            } catch {
                print("❌ Failed to rename scene: \(error)")
            }
        }
    }
    
    /// Update scene shortcut
    public func updateShortcut(_ scene: WindowScene, keyCode: UInt32, modifiers: UInt32) {
        guard let repository = repository else { return }
        
        Task {
            do {
                // Check for conflicts
                if let conflict = try repository.validateShortcut(
                    keyCode: keyCode,
                    modifiers: modifiers,
                    excludingSceneId: scene.id
                ) {
                    print("⚠️ Shortcut conflicts with scene: \(conflict.name)")
                    // Handle conflict - for now just proceed
                }
                
                try repository.updateShortcut(sceneId: scene.id, keyCode: keyCode, modifiers: modifiers)
                loadScenes()
                
                NotificationCenter.default.post(name: .scenesDidChange, object: nil)
                print("✅ Updated shortcut for scene: \(scene.name)")
            } catch {
                print("❌ Failed to update shortcut: \(error)")
            }
        }
    }
    
    /// Clear shortcut for a scene
    public func clearShortcut(_ scene: WindowScene) {
        guard let repository = repository else { return }
        
        Task {
            do {
                try repository.updateShortcut(sceneId: scene.id, keyCode: nil, modifiers: nil)
                loadScenes()
                
                NotificationCenter.default.post(name: .scenesDidChange, object: nil)
                print("✅ Cleared shortcut for scene: \(scene.name)")
            } catch {
                print("❌ Failed to clear shortcut: \(error)")
            }
        }
    }
    
    /// Toggle scene enabled state
    public func toggleEnabled(_ scene: WindowScene) {
        guard let repository = repository else { return }
        
        var updated = scene
        updated.isEnabled.toggle()
        
        Task {
            do {
                try repository.update(updated)
                loadScenes()
                
                NotificationCenter.default.post(name: .scenesDidChange, object: nil)
            } catch {
                print("❌ Failed to toggle scene: \(error)")
            }
        }
    }
}

// MARK: - Notifications

public extension Notification.Name {
    static let scenesDidChange = Notification.Name("scenesDidChange")
    static let sceneRecordingStarted = Notification.Name("sceneRecordingStarted")
    static let sceneRecordingEnded = Notification.Name("sceneRecordingEnded")
}
