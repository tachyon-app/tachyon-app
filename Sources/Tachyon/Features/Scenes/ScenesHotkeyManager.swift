import Foundation
import AppKit

/// Manages global hotkeys for activating scenes
public class ScenesHotkeyManager {
    public static let shared = ScenesHotkeyManager()
    
    private var registeredHotkeys: [UUID] = []
    
    private let repository: SceneRepository
    private let activationService: SceneActivationService
    
    init() {
        guard let dbQueue = StorageManager.shared.dbQueue else {
            fatalError("Database not available")
        }
        
        self.repository = SceneRepository(dbQueue: dbQueue)
        self.activationService = SceneActivationService()
        
        // Listen for changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadShortcuts),
            name: .scenesDidChange,
            object: nil
        )
        
        // Initial load
        reloadShortcuts()
    }
    
    deinit {
        unregisterAll()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func reloadShortcuts() {
        // Clear existing hotkeys
        unregisterAll()
        
        do {
            let scenes = try repository.fetchEnabled()
            
            for scene in scenes {
                registerHotkey(for: scene)
            }
            
            print("Layout Scenes: Registered \(registeredHotkeys.count) active shortcuts via HotkeyManager")
        } catch {
            print("Layout Scenes: Failed to load shortcuts: \(error)")
        }
    }
    
    private func registerHotkey(for scene: WindowScene) {
        guard let keyCode = scene.shortcutKeyCode,
              let modifiers = scene.shortcutModifiers else { return }
        
        let id = HotkeyManager.shared.register(
            keyCode: keyCode,
            modifiers: modifiers
        ) { [weak self] in
            self?.activateScene(scene.id)
        }
        
        registeredHotkeys.append(id)
    }
    
    private func unregisterAll() {
        for id in registeredHotkeys {
            HotkeyManager.shared.unregister(id)
        }
        registeredHotkeys.removeAll()
    }
    
    private func activateScene(_ sceneId: UUID) {
        Task {
            do {
                guard let scene = try repository.fetch(byId: sceneId) else { return }
                print("Layout Scenes: Activating scene '\(scene.displayName)' via hotkey")
                
                let windows = try repository.fetchWindows(forSceneId: sceneId)
                let result = try await activationService.activate(scene, windows: windows)
                
                // Show HUD or notification if needed
                if !result.isSuccess {
                    print("Layout Scenes: Failed to activate scene: \(result)")
                }
            } catch {
                print("Layout Scenes: Error activating scene: \(error)")
            }
        }
    }
}
