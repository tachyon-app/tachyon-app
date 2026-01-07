# Clipboard History

Clipboard History is a core feature of Tachyon that automatically captures everything you copy, making it easy to access, search, and paste previous clipboard contents. It is designed to be fully keyboard-driven and integrates seamlessly with your workflow.

## Features

### Automatic Capture
- **Rich Content**: Captures text, code, images, and file references automatically.
- **Smart Monitoring**: Polls the system clipboard efficiently (every 500ms) with minimal resource usage.
- **Privacy First**: Automatically filters out sensitive data like credit card numbers. All data is stored locally.

### Intelligent Content Types
- **Text**: Plain text content.
- **Code**: Auto-detected code snippets with syntax highlighting (Swift, Python, JS/TS, SQL, etc.).
- **Images**: Captures screenshots and images. **Includes OCR** (Optical Character Recognition) to make text within images searchable.
- **Files**: Captures file and folder paths when copied from Finder, preserving the full file reference.

### Search & OCR
- **Fuzzy Search**: Instantly find any item by typing parts of its content.
- **OCR Integration**: Text within images is automatically recognized using the macOS Vision framework. You can search for an image by the text it contains.
- **Type Filtering**: Quickly filter results by Text, Code, Image, or File.

### User Experience
- **Keyboard First**: Optimized for keyboard navigation. Use arrows to navigate results even while typing in the search bar.
- **Context-Aware Navigation**:
  - If opened via Hotkey (`⌘+Shift+V`): `Esc` closes the window.
  - If opened via Search Bar: `Esc` closes the window and **returns you to the Search Bar**.
- **Mutual Exclusivity**: Opening Clipboard History automatically hides the main Search Bar to prevent clutter.

### Pinning & Storage
- **Pinning**: Important items can be pinned to stay at the top and avoid deletion.
- **Deduplication**: Identical content is not duplicated; instead, the existing item's timestamp is updated.
- **Configurable Limits**: Set a maximum history size or go unlimited.

## Usage

### Opening
- **Keyboard Shortcut**: `⌘ + Shift + V`
- **Search Bar**: Type "Clipboard History" (or "cl") in the main Tachyon search bar (`⌘+Space`).
- **Menu Bar**: Click the Tachyon icon → "Clipboard History".

### Keyboard Shortcuts
| Action | Shortcut |
|--------|----------|
| Open Clipboard History | `⌘ + Shift + V` |
| Navigate List | `↑` / `↓` (works while typing) |
| Copy to Clipboard | `Return` |
| Paste Immediately | `Return` (Standard) or `⌘ + Return` |
| Pin/Unpin Item | `⌘ + P` |
| Delete Item | `⌘ + ⌫` (Cmd + Backspace) |
| Close / Go Back | `Esc` |

### Actions Bar
- **Copy**: Copies the selected item to the system clipboard.
- **Paste**: Copies and immediately pastes the item into your active application.
- **Pin**: Protects the item from being auto-deleted when the history fills up.
- **Delete**: Permanently removes the item.

## Settings

Access settings via `⌘ + ,` or the Menu Bar, then navigate to the **Clipboard** tab.

- **Enable Clipboard History**: Toggle monitoring on/off.
- **History Limit**: Choose between a fixed number of items (default: 200) or Unlimited.
- **Clear History**: Wipes the database (optionally keeping pinned items).

## Technical Details

### Architecture
- **Storage**: SQLite database via GRDB (`~/.tachyon/tachyon.db`).
- **Images**: Stored as files in `~/.tachyon/clipboard_images/` (secure updates pending).
- **OCR**: Uses macOS Vision framework asynchronously. recognized text is indexed for search and displayed in the preview pane.
- **Services**:
  - `ClipboardMonitorService`: Handles polling and content extraction.
  - `ClipboardItemRepository`: Manages database persistence.
  - `SensitiveDataDetector`: Validates content against regex patterns.
  - `OCRService`: Extracts text from images.

### Performance
- **Polling**: 500ms interval.
- **Limits**:
  - Text: 100,000 characters.
  - Images: 10 MB.
  - Files: 20 file paths per copy.
