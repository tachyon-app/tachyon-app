# Tachyon Quick Start Guide

## Running Tachyon

1. **Build and Launch**:
   ```bash
   ./run.sh
   ```

2. **Look for the menu bar icon**: Tachyon runs as a menu bar app. Look for the ⚡ (bolt) icon in your menu bar.

3. **Open the search bar**: Press `Cmd+Space` (or click the menu bar icon and select "Show Tachyon")

4. **Try searching**: Type the name of an application (e.g., "Safari", "Chrome", "Terminal")

5. **Launch an app**: Press Enter when the app you want is selected

## Keyboard Shortcuts

- `Cmd+Space` - Show/hide Tachyon search bar
- `Cmd+,` - Open settings
- `Esc` - Close search bar
- `↑↓` - Navigate results (coming soon)
- `Enter` - Execute selected result

## Current Features

✅ **App Launcher** - Search and launch installed macOS applications
- Indexes apps from `/Applications` and `~/Applications`
- Fuzzy search (try typing "saf" to find Safari)
- Acronym matching (try "gc" for Google Chrome)

## Coming Soon

- Custom Links with URL templates
- Window Snapping (Rectangle-style)
- Clipboard History
- Script Runner (Raycast-compatible)
- Focus Mode with Pomodoro timer
- Custom Search Engines

## Troubleshooting

### Cmd+Space doesn't work
You need to disable Spotlight's keyboard shortcut:
1. Open **System Settings**
2. Go to **Keyboard** → **Keyboard Shortcuts** → **Spotlight**
3. Uncheck "Show Spotlight search"

### App doesn't appear in menu bar
Make sure the app is running:
```bash
ps aux | grep Tachyon
```

If it's not running, launch it with `./run.sh`

### Search bar doesn't show
Check the terminal output for errors. The app requires:
- macOS 13.0 (Ventura) or later
- Accessibility permissions (will be requested on first launch)

## Development

### Running Tests
```bash
swift test
```

### Building for Release
```bash
swift build -c release
```

The release binary will be at `.build/release/Tachyon`

## Need Help?

- Check the [README](README.md) for full documentation
- Review the [implementation plan](/.gemini/antigravity/brain/*/implementation_plan.md)
- Open an issue on GitHub
