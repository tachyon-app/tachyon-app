# Window Management (Snapping)

Tachyon provides robust window management tools to help you organize your workspace efficiently. You can snap windows to specific areas of the screen using customizable keyboard shortcuts.

## Features

### Snap Locations
- **Halves**: Left, Right, Top, Bottom.
- **Corner Quarters**: Top Left, Top Right, Bottom Left, Bottom Right (screen divided into 4 quadrants).
- **Thirds**: Left Third, Center Third, Right Third.
- **Two-Thirds**: Left 2/3, Right 2/3.
- **Three-Quarters**: Left 3/4, Right 3/4.
- **Full Size**: Maximize, Fullscreen, Center.

### Multi-Monitor Support
- **Next/Previous Display**: Move the active window to an adjacent monitor instantly.

## Cycling
Some actions support "Cycling", allowing you to press the same hotkey repeatedly to rotate through related positions. 
- **Cycle Quarters**: Moves the window to the next vertical quarter (1/4 width columns).
- **Cycle Thirds**: Moves between left, center, and right thirds.

## Default Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Left Half | `⌃⌥←` |
| Right Half | `⌃⌥→` |
| Top Half | `⌃⌥↑` |
| Bottom Half | `⌃⌥↓` |
| Top Left Quarter | `⌃⌥U` |
| Top Right Quarter | `⌃⌥I` |
| Bottom Left Quarter | `⌃⌥J` |
| Bottom Right Quarter | `⌃⌥K` |
| Cycle Quarters | `⌃⌥4` |
| Cycle Three-Quarters | `⌃⌥Q` |
| Cycle Thirds | `⌃⌥3` |
| Cycle Two-Thirds | `⌃⌥T` |
| Maximize | `⌃⌥Enter` |
| Center | `⌃⌥C` |
| Next Display | `⌃⌥⌘→` |
| Previous Display | `⌃⌥⌘←` |

---

## Scenes

Scenes allow you to **save and restore complete window layouts** with a single hotkey. Perfect for switching between work contexts (e.g., coding setup vs. research setup).

### Creating a Scene

1. Open **Settings → Window Snapping → Scenes** tab.
2. Click **"Create Scene"**.
3. Add windows by clicking **"+ Add"** and selecting an app.
4. Configure each window's position and size using:
   - **Size Presets**: Half, Quarter, Two-Thirds, Three-Quarters, etc.
   - **Position Grid**: Click a cell to place the window in that screen region.
   - **Manual Sliders**: Fine-tune X%, Y%, Width%, Height%.
   - **Drag & Drop**: Drag tiles directly on the canvas.
5. Assign a name and save.

### Assigning a Shortcut

After creating a scene, you can assign a global hotkey:

1. Click the **"Set Shortcut"** button on the scene row.
2. Press your desired key combination (e.g., `⌘⌥1`).
3. The shortcut is now active globally.

### Activating a Scene

- **Hotkey**: Press the assigned shortcut from anywhere.
- **Manual**: Click the **play button** on the scene row in Settings.

### Multi-Window Support

Scenes support **multiple windows of the same app**. For example, you can have 2 VSCode windows:
- One on the left half
- One on the right half

When activating the scene:
- If **both windows exist**: They are positioned accordingly.
- If **only one exists**: A **new window is automatically spawned** and positioned.

### How Window Spawning Works

Tachyon tries multiple methods to create new windows:
1. **System Events** (AppleScript): Clicks "File → New Window" menu.
2. **Cmd+N Fallback**: Simulates the keyboard shortcut.

---

## Configuration

You can customize the hotkeys for every window action in the **Settings**.

1. Open Tachyon Settings.
2. Navigate to the **Window Snapping** section.
3. Use the **Shortcuts** tab to customize snapping hotkeys.
4. Use the **Scenes** tab to create and manage window layouts.

*Note: Tachyon must be granted Accessibility permissions in macOS System Preferences for window management to work.*
