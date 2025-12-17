import Foundation

extension Notification.Name {
    /// Posted when window snapping shortcuts are changed in settings
    public static let windowSnappingShortcutsDidChange = Notification.Name("windowSnappingShortcutsDidChange")
    
    /// Posted when shortcut recording starts (to temporarily disable hotkeys)
    public static let windowSnappingRecordingStarted = Notification.Name("windowSnappingRecordingStarted")
    
    /// Posted when shortcut recording ends (to re-enable hotkeys)
    public static let windowSnappingRecordingEnded = Notification.Name("windowSnappingRecordingEnded")
}
