# Camera

Capture photos directly from Tachyon using your Mac's built-in or external webcam.

---

## Quick Start

1. Open Tachyon with `Cmd + Space`
2. Type `camera` and press `Enter`
3. Press `Enter` again to take a photo
4. Press `Escape` to close and return to search

---

## Features

### Live Preview
- Real-time camera feed displayed in the Tachyon window
- Mirrored by default (like a selfie camera)
- Works with built-in FaceTime and external USB cameras

### Photo Capture
- Press `Enter` to capture a photo
- Visual flash effect confirms capture
- Photos save automatically to your configured folder (default: Desktop)
- Format: `Tachyon_Photo_YYYY-MM-DD_HH-mm-ss.png`

### Configuring Save Location
1. Open Settings (`⌘,`)
2. Go to **General** tab
3. Find **Camera** section
4. Click the folder button to choose your preferred save location

### Auto-Focus Return
- Pressing `Escape` closes the camera
- Search bar is automatically focused
- Camera session is fully released (no background usage)

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Enter` | Take photo (saves to configured folder) |
| `Escape` | Close camera, return to search bar |

---

## Permissions

### First-Time Setup

1. macOS will prompt for camera access when you first open the camera
2. Click **Allow** to grant permission
3. If denied, the camera view shows instructions to enable access

### Enabling Permission Later

1. Open **System Settings**
2. Go to **Privacy & Security → Camera**
3. Enable the toggle for **Tachyon**

---

## Technical Notes

- Uses AVFoundation for hardware camera access
- Camera session stops completely when view closes
- No background camera usage when not visible
- Designed for future video recording support
