# Tachyon ⚡

A blazing-fast productivity launcher for macOS, built natively in Swift.

## Features

- **App Launcher** - Launch applications with fuzzy search
- **Calculator** - Math expressions, unit conversions, and currency conversion
- **Date & Time** - Natural language dates, Unix timestamps, timezone conversions ✅
- **System Commands** - 26 macOS system controls (sleep, lock, dark mode, etc.) ✅
- **Custom Links** - URL templates with placeholders
- **Search Engines** - Custom search templates
- **Window Snapping** - Rectangle-style window management ✅
- **Script Runner** - Raycast-compatible script execution ✅
- **Clipboard History** - Smart clipboard manager (Coming soon)
- **Focus Mode** - Pomodoro timer with DND and Spotify (Coming soon)
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

### Accessibility Permissions

Window snapping requires accessibility permissions. You'll be prompted to grant access when you first use a window snapping hotkey.

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
- ✅ Calculator: 30+ tests
- ✅ Date & Time: 171 tests (7 pattern types + core components)
- ✅ System Commands: 14 tests
- ✅ CustomLinks: 16 tests
- ✅ SearchEngines: 4 tests
- ✅ WindowGeometry: 25 tests
- ✅ ScreenResolver: 8 tests
- ✅ WindowSnapperService: 9 tests
- ✅ Integration Tests: 32 tests

**Total: 507 tests passing (98.8% pass rate)**

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
    │ • Calculator               │
    │ • Date & Time              │
    │ • System Commands          │
    │ • Custom Links             │
    │ • Search Engines           │
    │ • Script Runner            │
    │ • Window Snapper           │
    │ • Clipboard History        │
    │ • Focus Mode               │
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

### Phase 2: Core Features ✅
- [x] Custom links
- [x] Search engines
- [x] Settings UI enhancements

### Phase 3: Advanced Features ✅
- [x] Window snapping (Rectangle-compatible)
- [x] Calculator with unit & currency conversion
- [x] Date & time calculations
- [x] System commands
- [x] Script runner (Raycast-compatible)
- [ ] Clipboard history
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
