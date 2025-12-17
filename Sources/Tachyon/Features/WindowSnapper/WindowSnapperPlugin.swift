import Foundation
import AppKit

/// Plugin that exposes window snapping actions through the search bar
public class WindowSnapperPlugin: Plugin {
    
    public var id: String { "window-snapper" }
    public var name: String { "Window Snapper" }
    
    private let service: WindowSnapperService
    
    public init(service: WindowSnapperService = WindowSnapperService()) {
        self.service = service
    }
    
    public func search(query: String) -> [QueryResult] {
        guard !query.isEmpty else { return [] }
        
        // Search through all window actions
        let actions = WindowAction.allCases.filter { action in
            // Skip display actions (they're hotkey-only)
            if action == .nextDisplay || action == .previousDisplay || action == .fullscreen {
                return false
            }
            
            // Fuzzy match on display name
            let displayName = action.displayName.lowercased()
            let searchQuery = query.lowercased()
            
            return displayName.contains(searchQuery) ||
                   searchQuery.split(separator: " ").allSatisfy { displayName.contains($0) }
        }
        
        return actions.map { action in
            QueryResult(
                id: UUID(),
                title: action.displayName,
                subtitle: "Snap window to \(action.displayName.lowercased())",
                icon: "rectangle.split.3x3",
                iconPath: nil,
                iconData: nil,
                alwaysShow: false,
                hideWindowAfterExecution: true,
                action: { [weak self] in
                    self?.executeAction(action)
                }
            )
        }
    }
    
    private func executeAction(_ action: WindowAction) {
        do {
            try service.execute(action)
        } catch {
            print("❌ Failed to execute window action \(action): \(error)")
            
            // Check if it's an accessibility error
            if error as? WindowAccessibilityError == .accessibilityNotEnabled {
                // Show alert to user
                DispatchQueue.main.async {
                    self.showAccessibilityAlert()
                }
            }
        }
    }
    
    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "Tachyon needs accessibility permissions to control windows. Please grant access in System Settings → Privacy & Security → Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Settings
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
