# System Commands

Tachyon provides quick access to 26 essential macOS system commands directly from the search bar. Control your Mac's power settings, appearance, audio, and more without leaving your keyboard.

## Usages

Type the command name or keyword into the search bar and press `Enter` to execute.

- **Instant Execution**: Most commands execute immediately
- **Confirmation Dialogs**: Destructive actions (restart, shutdown, etc.) show confirmation prompts
- **Keyboard-First**: All commands accessible without touching your mouse

## Command Categories

### Power & Session Management

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

### System Settings & Appearance

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

### Audio & Volume Control

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

### File & Disk Management

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

### Application Management

Control running applications and windows.

| Command | Description | Keywords |
|---------|-------------|----------|
| **Quit All Apps** | Quit all running applications | quit all, close all |
| **Hide All Apps** | Hide all application windows | hide all, minimize |
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

## Safety Features

### Confirmation Dialogs

Destructive commands require confirmation before execution:
- **Restart** - Confirms before restarting
- **Shutdown** - Confirms before shutting down
- **Log Out** - Confirms before logging out
- **Empty Trash** - Confirms before permanently deleting
- **Quit All Apps** - Confirms before closing all apps
- **Eject All Disks** - Confirms before ejecting

### Safe Commands

These commands execute immediately without confirmation:
- Sleep, Lock Screen, Sleep Displays
- Toggle settings (Dark Mode, Wi-Fi, Bluetooth, etc.)
- Volume controls
- Show/Hide operations

## Permissions

Some commands may require accessibility permissions:
- **First Use**: macOS may prompt for permissions
- **Settings**: Grant permissions in System Settings → Privacy & Security → Accessibility
- **Required For**: Volume control, display settings, some system toggles

## Search & Discovery

### Fuzzy Matching

Commands are discoverable through fuzzy search:
```
slp → Finds "Sleep"
loc → Finds "Lock Screen"
vol → Finds all volume commands
```

### Keyword Search

Search by function or category:
```
dark → Finds "Toggle Dark Mode"
audio → Finds all audio commands
power → Finds power-related commands
```

### Browse All

Type `system` to see all available system commands.

## Tips

- Commands are **case-insensitive**: `SLEEP` works the same as `sleep`
- Use **partial matches**: Type `vol` to find volume commands
- **Confirmation dialogs** prevent accidental destructive actions
- Commands use **native macOS APIs** for reliability
- Most commands execute in **under 100ms** for instant response

## Keyboard Shortcuts

While system commands don't have built-in shortcuts, you can:
1. Use Tachyon's global hotkey to open search
2. Type the command name
3. Press Enter to execute

This is often faster than navigating through System Settings!
