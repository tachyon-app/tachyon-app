import Foundation

extension WindowSnappingShortcut {
    public static let defaults: [WindowSnappingShortcut] = [
        // Halves
        .init(action: "leftHalf", keyCode: 123, modifiers: 6144, isEnabled: true),   // Ctrl+Opt+←
        .init(action: "rightHalf", keyCode: 124, modifiers: 6144, isEnabled: true),  // Ctrl+Opt+→
        .init(action: "topHalf", keyCode: 126, modifiers: 6144, isEnabled: true),    // Ctrl+Opt+↑
        .init(action: "bottomHalf", keyCode: 125, modifiers: 6144, isEnabled: true), // Ctrl+Opt+↓
        
        // Quarters
        .init(action: "topLeftQuarter", keyCode: 32, modifiers: 6144, isEnabled: true),     // Ctrl+Opt+U
        .init(action: "topRightQuarter", keyCode: 34, modifiers: 6144, isEnabled: true),    // Ctrl+Opt+I
        .init(action: "bottomLeftQuarter", keyCode: 38, modifiers: 6144, isEnabled: true),  // Ctrl+Opt+J
        .init(action: "bottomRightQuarter", keyCode: 40, modifiers: 6144, isEnabled: true), // Ctrl+Opt+K
        
        // Multi-Monitor
        .init(action: "nextDisplay", keyCode: 124, modifiers: 6656, isEnabled: true),     // Ctrl+Opt+Cmd+→
        .init(action: "previousDisplay", keyCode: 123, modifiers: 6656, isEnabled: true), // Ctrl+Opt+Cmd+←
        
        // Thirds
        .init(action: "firstThird", keyCode: 2, modifiers: 6144, isEnabled: true),    // Ctrl+Opt+D
        .init(action: "centerThird", keyCode: 3, modifiers: 6144, isEnabled: true),   // Ctrl+Opt+F
        .init(action: "lastThird", keyCode: 5, modifiers: 6144, isEnabled: true),     // Ctrl+Opt+G
        
        // Two Thirds
        .init(action: "firstTwoThirds", keyCode: 14, modifiers: 6144, isEnabled: true),  // Ctrl+Opt+E
        .init(action: "lastTwoThirds", keyCode: 17, modifiers: 6144, isEnabled: true),   // Ctrl+Opt+T
        
        // Three Quarters
        .init(action: "firstThreeQuarters", keyCode: 36, modifiers: 6144, isEnabled: true),  // Ctrl+Opt+Enter
        .init(action: "lastThreeQuarters", keyCode: 8, modifiers: 6144, isEnabled: true),    // Ctrl+Opt+C
        
        // Other
        .init(action: "maximize", keyCode: 124, modifiers: 6400, isEnabled: true),  // Ctrl+Cmd+→
        .init(action: "center", keyCode: 123, modifiers: 6400, isEnabled: true)     // Ctrl+Cmd+←
    ]
}
