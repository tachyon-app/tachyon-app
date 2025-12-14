# Tachyon ⚡

A blazing-fast productivity launcher for macOS, built natively in Swift.

## Features

- **App Launcher** - Launch applications with fuzzy search
- **Custom Links** - URL templates with placeholders (Coming soon)
- **Script Runner** - Raycast-compatible script execution (Coming soon)
- **Window Snapping** - Rectangle-style window management (Coming soon)
- **Clipboard History** - Smart clipboard manager (Coming soon)
- **Focus Mode** - Pomodoro timer with DND and Spotify (Coming soon)
- **Search Engines** - Custom search templates (Coming soon)
- **Global Hotkeys** - Customizable keyboard shortcuts

## Installation

### Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later

### Building from Source

1. Clone the repository:
```bash
git clone https://github.com/yourusername/tachyon.git
cd tachyon
```

2. Build and run:
```bash
./run.sh
```

Or manually:
```bash
swift build
.build/debug/Tachyon
```

Or open in Xcode:
```bash
open Package.swift
```

**Note**: The app runs as a menu bar application (no dock icon). Look for the ⚡ icon in your menu bar.

### Disabling Spotlight

To use Cmd+Space with Tachyon, you need to disable Spotlight's keyboard shortcut:

1. Open **System Settings**
2. Go to **Keyboard** → **Keyboard Shortcuts** → **Spotlight**
3. Uncheck "Show Spotlight search"

## Development

### Running Tests

```bash
swift test
```

### Test Coverage

Current test coverage:
- ✅ FuzzyMatcher: 12 tests
- ✅ QueryEngine: 7 tests  
- ✅ AppLauncher: 4 tests

**Total: 23 tests passing**

### Architecture

Tachyon follows a plugin-based architecture:

```
┌─────────────────┐
│   Search Bar    │
└────────┬────────┘
         │
    ┌────▼─────┐
    │  Query   │
    │  Engine  │
    └────┬─────┘
         │
    ┌────▼──────────────────────┐
    │       Plugins              │
    ├───────────────────────────┤
    │ • App Launcher             │
    │ • Custom Links             │
    │ • Script Runner            │
    │ • Window Snapper           │
    │ • Clipboard History        │
    │ • Focus Mode               │
    │ • Search Engines           │
    └────────────────────────────┘
```

### TDD Approach

We follow Test-Driven Development:

1. Write tests first
2. Implement feature to pass tests
3. Refactor while keeping tests green

See `Tests/TachyonTests/` for examples.

## Roadmap

### Phase 1: Foundation ✅
- [x] Project setup
- [x] Global hotkey system
- [x] Search bar UI
- [x] Query engine with fuzzy matching
- [x] App launcher plugin

### Phase 2: Core Features (In Progress)
- [ ] Custom links
- [ ] Search engines
- [ ] Settings UI enhancements

### Phase 3: Advanced Features
- [ ] Window snapping (Rectangle-compatible)
- [ ] Clipboard history
- [ ] Script runner (Raycast-compatible)
- [ ] Focus mode

### Phase 4: Polish
- [ ] Performance optimization
- [ ] App icon and branding
- [ ] Onboarding experience

## Contributing

Tachyon is open source! Contributions are welcome.

1. Fork the repository
2. Create a feature branch
3. Write tests for your changes
4. Implement your feature
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Inspired by [Raycast](https://www.raycast.com/)
- Window snapping defaults match [Rectangle](https://rectangleapp.com/)
- Built with ❤️ and Swift
