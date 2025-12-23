# Quicklinks (Custom Links)

Quicklinks allow you to create shortcuts to your favorite websites, local files, or deep links into other applications.

## Creating a Quicklink

1. Open **Settings > Quicklinks**.
2. Click the `+` button to add a new link.
3. **Name**: The command name you will type to find this link (e.g., "Google Search").
4. **Link**: The URL to open.

## Dynamic Links (Arguments)

You can pass arguments to your links by including `{query}` or other placeholders in the URL.

**Example: Search Google**
- **Link**: `https://www.google.com/search?q={query}`

When you select this Quicklink in Tachyon, the interface will prompt you to enter the text for `{query}` before opening the URL.

## Advanced Usage
- **App Schemes**: Use URL schemes like `spotify://`, `zoommtg://`, or `vscode://` to control other apps.
- **Local Files**: Use `file:///Users/username/Documents/Report.pdf` to open specific files.
