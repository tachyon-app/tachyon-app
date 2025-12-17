import Foundation
import Combine
import TachyonCore

/// ViewModel for Window Snapping settings
@MainActor
class WindowSnappingSettingsViewModel: ObservableObject {
    @Published var halves: [WindowSnappingShortcut] = []
    @Published var quarters: [WindowSnappingShortcut] = []
    @Published var thirds: [WindowSnappingShortcut] = []
    @Published var multiMonitor: [WindowSnappingShortcut] = []
    @Published var other: [WindowSnappingShortcut] = []
    @Published var isLoading = false
    
    private var repository: WindowSnappingShortcutRepository?
    
    init() {
        setupRepository()
    }
    
    private func setupRepository() {
        guard let dbQueue = StorageManager.shared.dbQueue else {
            print("❌ Database not available")
            return
        }
        repository = WindowSnappingShortcutRepository(dbQueue: dbQueue)
    }
    
    func loadShortcuts() {
        guard let repository = repository else { return }
        
        isLoading = true
        
        Task {
            do {
                let shortcuts = try repository.fetchAll()
                
                // Group by category
                halves = shortcuts.filter { action in
                    ["leftHalf", "rightHalf", "topHalf", "bottomHalf"].contains(action.action)
                }
                
                quarters = shortcuts.filter { action in
                    ["topLeftQuarter", "topRightQuarter", "bottomLeftQuarter", "bottomRightQuarter"].contains(action.action)
                }
                
                thirds = shortcuts.filter { action in
                    ["firstThird", "centerThird", "lastThird", "firstTwoThirds", "lastTwoThirds", "firstThreeQuarters", "lastThreeQuarters"].contains(action.action)
                }
                
                multiMonitor = shortcuts.filter { action in
                    ["nextDisplay", "previousDisplay"].contains(action.action)
                }
                
                other = shortcuts.filter { action in
                    ["maximize", "center"].contains(action.action)
                }
                
                isLoading = false
            } catch {
                print("❌ Failed to load shortcuts: \(error)")
                isLoading = false
            }
        }
    }
    
    func updateShortcut(_ shortcut: WindowSnappingShortcut) {
        guard let repository = repository else { return }
        
        Task {
            do {
                try repository.update(shortcut)
                
                // Reload to reflect changes
                loadShortcuts()
                
                // Notify app to reload hotkeys
                NotificationCenter.default.post(
                    name: .windowSnappingShortcutsDidChange,
                    object: nil
                )
                
                print("✅ Updated shortcut: \(shortcut.displayName)")
            } catch {
                print("❌ Failed to update shortcut: \(error)")
            }
        }
    }
    
    func resetToDefaults() {
        guard let repository = repository else { return }
        
        Task {
            do {
                try repository.resetToDefaults()
                
                // Reload shortcuts
                loadShortcuts()
                
                // Notify app to reload hotkeys
                NotificationCenter.default.post(
                    name: .windowSnappingShortcutsDidChange,
                    object: nil
                )
                
                print("✅ Reset shortcuts to defaults")
            } catch {
                print("❌ Failed to reset shortcuts: \(error)")
            }
        }
    }
}
