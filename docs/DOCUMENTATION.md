# Tachyon Documentation

Welcome to the complete Tachyon documentation. This guide covers all features and configuration options available in the application.

---

## Table of Contents
1. [Search & App Launcher](#search--app-launcher)
2. [System Commands](#system-commands)
3. [Calculator](#calculator)
4. [Date & Time Calculations](#date--time-calculations)
5. [Focus Mode](#focus-mode)
6. [Window Management (Snapping)](#window-management-snapping)
7. [Quicklinks (Custom Links)](#quicklinks-custom-links)
8. [Search Engines](#search-engines)
9. [Script Commands](#script-commands)
10. [Settings](#settings)

---

## Search & App Launcher

The core feature of Tachyon is the intelligent Search Bar and App Launcher. It allows you to quickly launch applications, find files, and execute commands without taking your hands off the keyboard.

### Usage

1. **Invoke Tachyon**: Press the global hotkey (default: `Option + Space`) to open the search bar.
2. **Type to Search**: Start typing the name of an application, file, or command.
3. **Select & Act**:
   - Use `↑` and `↓` arrow keys to navigate results.
   - Press `Enter` to open the selected item (launch app, open file, run command).

### App Launcher

Tachyon automatically indexes applications from standard macOS locations:
- `/Applications`
- `/System/Applications`
- `~/Applications`
- `/System/Library/CoreServices/Applications`

### Features
- **Fuzzy Search**: You don't need to type the exact name. Partial matches and initials often work (e.g., "chr" for Chrome).
- **Prioritization**: Frequently used apps will appear higher in the results over time (managed by the `QueryEngine`).
- **Performance**: The launcher uses a lightweight index to ensure results appear instantly.

### Default View

When you first open Tachyon without typing, it displays a list of your most recently or frequently used applications (limited to top 20 initially) to provide instant access to your daily tools.

---

## System Commands

Tachyon provides quick access to 26 essential macOS system commands directly from the search bar. Control your Mac's power settings, appearance, audio, and more without leaving your keyboard.

### Usages

Type the command name or keyword into the search bar and press `Enter` to execute.

- **Instant Execution**: Most commands execute immediately
- **Confirmation Dialogs**: Destructive actions (restart, shutdown, etc.) show confirmation prompts
- **Keyboard-First**: All commands accessible without touching your mouse

### Command Categories

#### Power & Session Management

Control your Mac's power state and user session.

| Command | Description | Keywords |
|---------|-------------|----------|
| **Sleep** | Put Mac to sleep | sleep, rest |
| **Sleep Displays** | Turn off displays only | display sleep, screen off |
| **Lock Screen** | Lock your Mac | lock, secure |
| **Log Out** | Log out current user | logout, sign out |
| **Restart** | Restart your Mac | restart, reboot |
| **Shutdown** | Shut down your Mac | shutdown, power off |

**Examples:**
```
sleep
→ Puts Mac to sleep immediately

lock
→ Locks the screen

restart
→ Shows confirmation, then restarts
```

#### System Settings & Appearance

Toggle system-wide settings and appearance options.

| Command | Description | Keywords |
|---------|-------------|----------|
| **Toggle Dark Mode** | Switch between light/dark mode | dark mode, appearance, theme |
| **Toggle Wi-Fi** | Turn Wi-Fi on/off | wifi, wireless |
| **Toggle Bluetooth** | Turn Bluetooth on/off | bluetooth, bt |
| **Toggle Night Shift** | Enable/disable Night Shift | night shift, blue light |
| **Toggle True Tone** | Enable/disable True Tone | true tone, display |

**Examples:**
```
dark mode
→ Toggles between light and dark appearance

wifi
→ Turns Wi-Fi on or off

night shift
→ Toggles Night Shift mode
```

#### Audio & Volume Control

Manage system audio settings and volume levels.

| Command | Description | Keywords |
|---------|-------------|----------|
| **Mute** | Mute system audio | mute, silence |
| **Unmute** | Unmute system audio | unmute, sound on |
| **Set Volume 0%** | Set volume to 0% | volume 0, silent |
| **Set Volume 25%** | Set volume to 25% | volume 25, quiet |
| **Set Volume 50%** | Set volume to 50% | volume 50, medium |
| **Set Volume 75%** | Set volume to 75% | volume 75, loud |
| **Set Volume 100%** | Set volume to 100% | volume 100, max |

**Examples:**
```
mute
→ Mutes all system audio

volume 50
→ Sets volume to 50%

unmute
→ Restores audio
```

#### File & Disk Management

Manage files, trash, and disk operations.

| Command | Description | Keywords |
|---------|-------------|----------|
| **Empty Trash** | Permanently delete trash items | empty trash, delete |
| **Open Trash** | Open Trash folder | trash, bin |
| **Toggle Hidden Files** | Show/hide hidden files in Finder | hidden files, show all |
| **Eject All Disks** | Safely eject all external disks | eject, unmount |

**Examples:**
```
empty trash
→ Shows confirmation, then empties trash

hidden files
→ Toggles visibility of hidden files

eject
→ Ejects all external disks safely
```

#### Application Management

Control running applications and windows.

| Command | Description | Keywords |
|---------|-------------|----------|
| **Quit All Apps** | Quit all running applications | quit all, close all |
| **Hide All Apps** | Hide all application windows | hide all, minmize |
| **Unhide All Apps** | Show all hidden applications | unhide all, show all |
| **Show Desktop** | Hide all windows, show desktop | desktop, show desktop |

**Examples:**
```
quit all
→ Closes all running applications

show desktop
→ Hides all windows to show desktop

hide all
→ Hides all application windows
```

### Safety Features

#### Confirmation Dialogs

Destructive commands require confirmation before execution:
- **Restart** - Confirms before restarting
- **Shutdown** - Confirms before shutting down
- **Log Out** - Confirms before logging out
- **Empty Trash** - Confirms before permanently deleting
- **Quit All Apps** - Confirms before closing all apps
- **Eject All Disks** - Confirms before ejecting

#### Safe Commands

These commands execute immediately without confirmation:
- Sleep, Lock Screen, Sleep Displays
- Toggle settings (Dark Mode, Wi-Fi, Bluetooth, etc.)
- Volume controls
- Show/Hide operations

### Permissions

Some commands may require accessibility permissions:
- **First Use**: macOS may prompt for permissions
- **Settings**: Grant permissions in System Settings → Privacy & Security → Accessibility
- **Required For**: Volume control, display settings, some system toggles

### Search & Discovery

#### Fuzzy Matching

Commands are discoverable through fuzzy search:
```
slp → Finds "Sleep"
loc → Finds "Lock Screen"
vol → Finds all volume commands
```

#### Keyword Search

Search by function or category:
```
dark → Finds "Toggle Dark Mode"
audio → Finds all audio commands
power → Finds power-related commands
```

#### Browse All

Type `system` to see all available system commands.

---

## Calculator

Tachyon includes a powerful built-in calculator that parses math expressions, performs unit conversions, and converts currencies directly within the search bar.

### Usages

Simply type your math expression or conversion query into the search bar. The result will appear as a search result item.

- **Copy Result**: Press `Enter` on the result to copy it to your clipboard.

### Features

#### Math Expressions
Perform basic and advanced arithmetic operations:
- **Basic**: `2+2`, `10-3`, `5*6`, `20/4`
- **Percentages**: `100*30%` (30), `50+10%` (55)
- **Functions**: `sqrt(16)`, `sin(0)`, `cos(pi)`, `log(100)`
- **Constants**: `pi`, `e`
- **Scientific Notation**: `2e3`, `3.14e-2`

#### Unit Conversions
Convert between various units of measurement. The syntax is typically `[value] [unit] to [target_unit]`.

**Supported Categories:**
- **Length**: km, m, cm, mm, miles, feet, inches, yards
- **Temperature**: Celsius, Fahrenheit, Kelvin
- **Mass**: kg, g, lb, oz
- **Volume**: liters, ml, gallons, cups, fl oz
- **Time**: seconds, minutes, hours, days
- **Data**: bytes, KB, MB, GB, TB

#### Currency Conversion
Convert between major world currencies using live exchange rates.
- **Syntax**: `100 USD to EUR`, `$50 to GBP`
- **Supported Currencies**: Includes AUD, CAD, CHF, CNY, EUR, GBP, JPY, USD, and many others (30+ major currencies).
- **Updates**: Rates are cached locally and updated hourly.

*Note: Requires an internet connection to fetch the latest exchange rates.*

---

## Date & Time Calculations

Tachyon includes powerful date and time calculation features that let you work with dates, timestamps, timezones, and perform date arithmetic directly from the search bar.

### Usages

Type your date query into the search bar. Results appear instantly with multiple format options.

- **Copy Result**: Press `Enter` to copy the formatted date to your clipboard.
- **Multiple Formats**: Each result includes Unix timestamp, ISO 8601, RFC 2822, and human-readable formats.

### Features

#### Unix Timestamp Conversion

Convert Unix timestamps to human-readable dates and vice versa.

**Supported Formats:**
- **10-digit** (seconds): `1703347200`
- **13-digit** (milliseconds): `1703347200000`
- **16-digit** (microseconds): `1703347200000000`

**Keywords:**
- `now in unix` - Get current Unix timestamp
- `current epoch` - Same as above
- `unix timestamp` - Current timestamp
- `epoch` - Current timestamp

#### Natural Language Dates

Parse dates using natural language expressions.

**Simple Dates:**
- `today` - Current date
- `tomorrow` - Next day
- `yesterday` - Previous day
- `now` - Current date and time

**Weekdays:**
- `monday`, `tuesday`, etc. - Next occurrence of that weekday
- `next friday` - Explicitly next Friday
- `last monday` - Previous Monday

**Relative Dates:**
- `in 2 days` - Two days from now
- `3 days ago` - Three days in the past

**Complex Patterns:**
- `monday in 3 weeks` - Monday occurring in 3 weeks

#### Date Arithmetic

Perform calculations with dates using addition and subtraction.

**Syntax:** `[date] [+/-] [amount] [unit]`

**Supported Units:**
- seconds, minutes, hours
- days, weeks, months, years
- Both singular and plural forms work

#### Timezone Conversions

Get current time in any timezone or convert times between timezones.

**Simple Timezone Queries:**
- `time in tokyo` - Current time in Tokyo
- `nyc time` - Using city abbreviations
- `london time` - Current time in London

**Timezone Conversions:**
- `5pm london in tokyo` - Convert 5 PM London time to Tokyo
- `9am nyc in paris` - Convert 9 AM NYC time to Paris

**Supported Cities:**
Over 50 major cities worldwide including New York, Los Angeles, London, Paris, Tokyo, Singapore, etc.

#### Duration Calculations

Calculate time remaining until a specific date or event.

**Syntax:** `days until [date]` or `time until [date]`

**Special Dates:**
- `christmas`, `new year`, `halloween`, `valentine`

#### Date Differences

Calculate the difference between two dates.

**Syntax:** `[date1] - [date2]`

#### Week & Day Numbers

Get ISO week numbers and day of year information.

**Queries:**
- `week number` - Current ISO week number
- `day number` - Current day of year

### Output Formats

Every date result includes multiple formats for easy copying:
- **Human-Readable**: "Saturday, 23 December 2023 at 16:00:00"
- **Unix Seconds**: 1703347200
- **Unix Milliseconds**: 1703347200000
- **ISO 8601**: 2023-12-23T16:00:00Z
- **RFC 2822**: Sat, 23 Dec 2023 16:00:00 +0000
- **Relative**: "in 2 days" or "3 days ago"

---

## Focus Mode

Tachyon's Focus Mode helps you stay productive with timer-based focus sessions, Spotify music integration, and visual focus indicators.

### Quick Start

Type `focus` in the search bar to start a focus session.

**Commands:**
```
focus           → Quick start with last config (default: 25 min)
focus 25        → Start 25-minute session
pause focus     → Pause active session
resume focus    → Resume paused session
stop focus      → End session
```

### Features

#### Timer Sessions
- `focus 15`, `focus 25`, `focus 45`, `focus 1 hour`

#### Timer Display Options
- **Floating Window**: Large countdown timer, draggable, hover controls.
- **Status Bar**: Compact timer, click for action menu.

#### Spotify Music 🎵
Enable music in Settings to automatically play tracks/playlists/albums on session start.

#### Glowing Screen Border ✨
Visual indicator with custom colors and intensity that appears on all monitors when focusing.

#### Completion Celebration 🎉
Green flash, notification, and sound when the session ends.

---

## Window Management (Snapping)

Organize your workspace efficiently by snapping windows to specific areas of the screen using keyboard shortcuts.

### Features

#### Snap Locations
- **Halves**: Left, Right, Top, Bottom.
- **Quarters**: Top Left, Top Right, Bottom Left, Bottom Right.
- **Thirds**: Left Third, Center Third, Right Third.
- **Two-Thirds**: Left 2/3, Right 2/3.
- **Full Size**: Maximize, Fullscreen, Center.

#### Multi-Monitor Support
- **Next/Previous Display**: Move the active window to an adjacent monitor instantly.

#### Cycling
- **Cycle Quarters**: Moves the window to the next corner clockwise.
- **Cycle Thirds**: Moves between left, center, and right thirds.

### Configuration
Customize all hotkeys in **Settings > Window Management**.
*Note: Requires Accessibility permissions.*

---

## Quicklinks (Custom Links)

Quicklinks allow you to create shortcuts to your favorite websites, local files, or deep links into other applications.

### Creating a Quicklink
1. Open **Settings > Quicklinks**.
2. Click the `+` button to add a new link.
3. Define **Name** and **Link**.

### Dynamic Links (Arguments)
You can include `{query}` in the URL to pass arguments.
Example: `https://www.google.com/search?q={query}`

---

## Search Engines

Configure custom search engines used as fallbacks or triggered directly.

### Configuration
1. Go to **Settings > Search Engines**.
2. Add a new engine with a **Name**, **Keyword**, and **URL Template**.

### URL Template
The URL must contain `{{query}}` where your search terms should be inserted.
Example Google: `https://www.google.com/search?q={{query}}`

---

## Script Commands

Extend Tachyon's capabilities with custom scripts in Bash, Python, Node.js, etc.

### Getting Started
1. Go to **Settings > Scripts**.
2. Add a directory to scan for executable scripts.

### Script Format
Use Raycast-compatible magic comments:
```bash
#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title My Script
# @raycast.mode compact
```

### Execution Modes
- **fullOutput**: Opens a dedicated view.
- **compact**: Displays the last line as a toast.
- **inline**: Replaces result title with output.
- **silent**: Runs in background.

---

## Settings

Access settings via `Cmd + ,` or by searching for "Settings".

### General
- **Launch at Login**
- **Hotkey** (Default: `Option + Space`)
- **Theme** (Light/Dark/System)

### Tabs
- **Window Management**: Snapping shortcuts.
- **Quicklinks**: Custom links management.
- **Scripts**: Script directories and reloading.
- **Search Engines**: Web search providers.

### Data Management
- **Clear History**: Reset clipboard/command data.
- **Permissions**: Verify Accessibility status.
