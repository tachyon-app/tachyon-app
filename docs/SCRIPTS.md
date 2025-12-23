# Script Commands

Extend Tachyon's capabilities by writing your own scripts. Tachyon supports scripts written in Bash, Python, Ruby, Swift, AppleScript, Node.js, and more.

## Getting Started

1. Go to **Settings > Scripts**.
2. Add a directory where you will store your scripts.
3. Tachyon will scan this directory and make executable scripts available in the search bar.

## Script Format

Tachyon scripts use a special metadata header (Magic Comments) similar to Raycast to define how they behave.

### Example: Hello World (Bash)

```bash
#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Hello World
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Utils

echo "Hello from Tachyon!"
```

## Metadata Reference

| Field | Description |
|-------|-------------|
| `@raycast.schemaVersion` | Must be `1`. |
| `@raycast.title` | The name of the command as it appears in search. |
| `@raycast.mode` | How results are displayed. (See below) |
| `@raycast.icon` | Emoji or URL to an icon image. |
| `@raycast.packageName` | Group name (subtitle) for the script. |
| `@raycast.argumentX` | Define input arguments (see below). |
| `@raycast.needsConfirmation` | `true` if the user must confirm before running. |

## Execution Modes

- **`fullOutput`**: Opens a dedicated view to display the complete output of the script. Good for logs or long text.
- **`compact`**: Displays the last line of output in the Tachyon status bar (toast). Good for quick status checks.
- **`inline`**: Replaces the search result title with the output.
- **`silent`**: Runs in the background without showing output (unless an error occurs).

## Arguments

Scripts can accept input from the user. define arguments using `@raycast.argument1`, `@raycast.argument2`, etc.

```bash
# @raycast.argument1 { "type": "text", "placeholder": "Name" }
```

- **type**: `text` or `password`.
- **placeholder**: Text shown in the input field.
- **optional**: `true` or `false` (default is false).
