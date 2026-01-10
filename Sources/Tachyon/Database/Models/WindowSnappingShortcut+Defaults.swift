import Foundation

extension WindowSnappingShortcut {
    public static let defaults: [WindowSnappingShortcut] = [
        // Halves
        .init(action: "leftHalf", keyCode: 123, modifiers: 6144, isEnabled: true),   // Ctrl+Opt+←
        .init(action: "rightHalf", keyCode: 124, modifiers: 6144, isEnabled: true),  // Ctrl+Opt+→
        .init(action: "topHalf", keyCode: 126, modifiers: 6144, isEnabled: true),    // Ctrl+Opt+↑
        .init(action: "bottomHalf", keyCode: 125, modifiers: 6144, isEnabled: true), // Ctrl+Opt+↓
        
        // Cycle Quarters (clockwise: TL → TR → BR → BL)
        .init(action: "cycleQuarters", keyCode: 21, modifiers: 6144, isEnabled: true),  // Ctrl+Opt+4
        
        // Cycle Three-Quarters
        .init(action: "cycleThreeQuarters", keyCode: 12, modifiers: 6144, isEnabled: true),  // Ctrl+Opt+Q
        
        // Cycle Thirds
        .init(action: "cycleThirds", keyCode: 20, modifiers: 6144, isEnabled: true),  // Ctrl+Opt+3
        
        // Cycle Two-Thirds
        .init(action: "cycleTwoThirds", keyCode: 17, modifiers: 6144, isEnabled: true),  // Ctrl+Opt+T
        
        // Multi-Monitor (Ctrl+Opt+Cmd = 4096 + 2048 + 256 = 6400)
        .init(action: "nextDisplay", keyCode: 124, modifiers: 6400, isEnabled: true),     // Ctrl+Opt+Cmd+→
        .init(action: "previousDisplay", keyCode: 123, modifiers: 6400, isEnabled: true), // Ctrl+Opt+Cmd+←
        
        // Maximize & Center
        .init(action: "maximize", keyCode: 36, modifiers: 6144, isEnabled: true),  // Ctrl+Opt+Enter
        .init(action: "center", keyCode: 8, modifiers: 6144, isEnabled: true)      // Ctrl+Opt+C
    ]
}
