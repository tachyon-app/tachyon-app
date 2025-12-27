# Focus Mode

Tachyon's Focus Mode helps you stay productive with timer-based focus sessions, Spotify music integration, and visual focus indicators.

## Quick Start

Type `fo` in the search bar to start a focus session (fuzzy matching supported).

**Commands:**
```
focus           → Quick start with last config (default: 25 min)
focus 25        → Start 25-minute session
focus 1 hour    → Start 60-minute session
pause focus     → Pause active session
resume focus    → Resume paused session
stop focus      → End session
```

## Features

### Timer Sessions

| Query | Duration |
|-------|----------|
| `focus 15` | 15 minutes |
| `focus 25` | 25 minutes (Pomodoro) |
| `focus 45` | 45 minutes |
| `focus 1 hour` | 60 minutes |

### Timer Display Options

**Floating Window** (default)
- Large countdown timer with progress bar
- Goal text display
- Hover controls: Pause/Resume, Stop, Minimize
- Draggable anywhere on screen

**Status Bar** (minimized)
- Compact timer: `08:55 ●●●○○ ⋯`
- Click to open action menu
- Actions: Complete, Pause/Resume, Cancel, Detach

**Your preference is remembered!** Minimize once → future sessions start minimized.

### Progress Bar

Both timer displays show a progress bar that fills as your session progresses. The color matches your glow border setting (cyan default).

### Spotify Music 🎵

Enable/disable music in Settings → Focus Mode.

**Supported URLs:**
- Tracks: `https://open.spotify.com/track/...`
- Albums: `https://open.spotify.com/album/...`
- Playlists: `https://open.spotify.com/playlist/...`
- Podcasts: `https://open.spotify.com/show/...`
- Episodes: `https://open.spotify.com/episode/...`

On session start, Tachyon randomly picks one item and plays it via Spotify.

### Glowing Screen Border ✨

Visual indicator that you're in focus mode:
- Gradient fade from screen edges inward
- Works on **all monitors**
- Appears above menu bar

**Settings:**
- Color: 9 preset colors (Blue, Purple, Pink, Red, Orange, Yellow, Green, Cyan, White)
- Spread: Subtle (10px), Medium (30px), Intense (50px)

### Completion Celebration 🎉

When your session completes:
1. **Green flash** - Border flashes green twice
2. **Notification** - Styled banner in top-right corner
3. **Sound** - Glass chime

## Settings

**Settings → Focus Mode:**

| Setting | Description |
|---------|-------------|
| Music Toggle | Enable/disable Spotify integration |
| Music Items | Add/remove Spotify URLs |
| Border Toggle | Enable/disable glow border |
| Border Color | Choose from 9 preset colors |
| Border Spread | Subtle, Medium, or Intense |

## Tips

1. **Fuzzy Search** - Type `fo` or `foc` to find focus commands
2. **Quick Focus** - Just type `focus` to use last-used duration
3. **Status Bar** - Minimize for less distraction, preference is saved
4. **Complete Early** - Use "Complete" in status bar menu to end with celebration
5. **Preview** - Test border appearance in settings before starting
