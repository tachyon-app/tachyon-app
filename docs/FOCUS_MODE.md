# Focus Mode

Tachyon's Focus Mode helps you stay productive with timer-based focus sessions, Spotify music integration, and optional visual focus indicators.

## Quick Start

Type `focus` in the search bar to start a focus session with your last-used configuration.

**Basic Commands:**
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

Start a focus session by typing `focus` followed by a duration:

| Query | Duration |
|-------|----------|
| `focus 15` | 15 minutes |
| `focus 25` | 25 minutes (Pomodoro) |
| `focus 45` | 45 minutes |
| `focus 1 hour` | 60 minutes |
| `focus 90 min` | 90 minutes |

The floating timer bar shows:
- ⏱ Remaining time (large display)
- 📝 Goal text (if set)
- ⏸ Pause/Resume button (on hover)
- ✕ Stop button (on hover)
- ➖ Minimize button (on hover)

**Tip:** The timer bar is draggable - move it anywhere on your screen!

### Spotify Music Integration 🎵

Add your favorite focus music in Settings:

1. Copy a Spotify URL (track, album, or playlist)
2. Paste it in the Focus Mode settings
3. The app automatically extracts the title and artwork
4. Add multiple items to build your focus playlist

**On session start:** Tachyon randomly picks one item and tells Spotify to play it!

**Supported Spotify URLs:**
- Tracks: `https://open.spotify.com/track/...`
- Albums: `https://open.spotify.com/album/...`
- Playlists: `https://open.spotify.com/playlist/...`

### Glowing Screen Border ✨

Enable a beautiful animated border around your screen to:
- Create a focused visual environment
- Know at-a-glance that you're in focus mode
- Works on **all monitors**

**Settings:**
- Toggle: Enable/Disable
- Color: Choose any color
- Thickness: Thin / Medium / Thick

The border has a subtle glow animation similar to iOS Siri.

### Session Notifications

When your focus session ends, you'll receive a macOS notification:
- 🎉 "Focus Session Complete!"
- Your goal text (if you set one)

## Floating Timer Bar

The focus bar appears when you start a session:

```
┌─────────────────────────┐
│  25:00    📝 Goal text  │
│  ⏸  ✕  ─                │
└─────────────────────────┘
```

**Controls (visible on hover):**
- ⏸ Pause/▶ Resume session
- ✕ Stop session
- ➖ Minimize to menu bar

**Behavior:**
- Always on top of other windows
- Draggable - move anywhere on screen
- Translucent design, doesn't distract

## Settings

Configure Focus Mode in Tachyon → Settings → Focus:

### Music
- Add Spotify URLs
- View added items as pills with artwork
- Remove items with the × button

### Visual Border
- Enable/disable glowing border
- Pick border color
- Choose thickness (Thin/Medium/Thick)

## Tips

1. **Quick Focus** - Just type `focus` to start with your last-used duration
2. **Natural Language** - Type `focus 1 hour` or `focus 30 min`
3. **Spotify Required** - Music feature requires Spotify installed
4. **Multi-Monitor** - The glowing border appears on all connected screens
5. **Keyboard First** - All controls accessible via Tachyon search bar

## Keyboard Commands

| Command | Action |
|---------|--------|
| `focus` | Quick start |
| `focus [duration]` | Start with specific duration |
| `pause focus` | Pause session |
| `resume focus` | Resume session |
| `stop focus` | End session |
