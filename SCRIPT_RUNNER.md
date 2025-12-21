# Script Runner Engine - Feature Documentation

## Overview

The Script Runner Engine is a Raycast-compatible script execution system for Tachyon that allows you to run custom scripts directly from the search bar with full metadata support, multiple output modes, and periodic scheduling.

## Features

### ✅ Implemented

1. **Raycast-Compatible Metadata Parsing**
   - Supports `#` and `//` comment prefixes
   - Parses all Raycast metadata fields
   - JSON argument definitions
   - Schema validation

2. **Script Execution**
   - Shebang detection and interpreter resolution
   - Subprocess spawning with proper argument passing
   - Working directory configuration
   - Separate stdout/stderr capture
   - Live output streaming for fullOutput mode

3. **Four Output Modes**
   - `fullOutput`: Terminal-like view with live streaming
   - `compact`: Last line shown in status bar
   - `inline`: First line shown inline with search result
   - `silent`: Status messages only

4. **Script Scheduling**
   - Periodic execution based on `refreshTime`
   - Supports: "1h", "30m", "10s", "1d"
   - Automatic execution tracking

5. **Script Management**
   - Scripts stored in `~/.tachyon/scripts/`
   - Import via file picker
   - Hotkey assignment
   - Enable/disable toggle
   - Context menu actions (Open, Show in Finder, Delete)

6. **UI Components**
   - Integrated status bar in search view
   - Script output view with rerun capability
   - Argument input form for parameterized scripts
   - Settings UI for script management

## Script Metadata Format

### Required Fields

```bash
#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title My Script
# @raycast.mode fullOutput
```

### Optional Fields

```bash
# @raycast.packageName Developer Tools
# @raycast.icon 🚀
# @raycast.description What this script does
# @raycast.refreshTime 1h
# @raycast.currentDirectoryPath /path/to/directory
# @raycast.needsConfirmation true
```

### Arguments

```bash
# @raycast.argument1 {"type": "text", "placeholder": "Your name", "optional": false}
# @raycast.argument2 {"type": "password", "placeholder": "API Key", "optional": true}
```

## Usage Examples

### Example 1: Simple Hello World (fullOutput)

```bash
#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Hello World
# @raycast.mode fullOutput

echo "Hello from Tachyon!"
echo "Current time: $(date)"
```

### Example 2: System Info (compact)

```bash
#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title System Info
# @raycast.mode compact

echo "CPU: $(sysctl -n machdep.cpu.brand_string)"
```

### Example 3: Git Status (inline)

```bash
#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Git Status
# @raycast.mode inline
# @raycast.currentDirectoryPath ~/code/myproject

git status --short | wc -l | xargs echo "Changed files:"
```

### Example 4: With Arguments

```bash
#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Greet User
# @raycast.mode compact
# @raycast.argument1 {"type": "text", "placeholder": "Your name", "optional": false}

echo "Hello, $1! Welcome to Tachyon."
```

### Example 5: Scheduled Script

```bash
#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Check Disk Space
# @raycast.mode silent
# @raycast.refreshTime 1h

df -h / | tail -1 | awk '{print "Disk usage: " $5}'
```

## Architecture

### Core Components

```
ScriptRunner/
├── ScriptMetadata.swift       # Data models
├── ScriptRecord.swift          # Database model
├── ScriptFileManager.swift     # File management
├── MetadataParser.swift        # Magic comment parser
├── ScriptExecutor.swift        # Process execution
├── ScriptScheduler.swift       # Periodic execution
└── ScriptRunnerPlugin.swift    # Plugin integration

UI/
├── ScriptRunner/
│   ├── ScriptOutputView.swift         # fullOutput mode view
│   └── ScriptArgumentInputView.swift  # Argument collection
├── Settings/
│   ├── ScriptCommandsSettingsView.swift  # Management UI
│   └── AddEditScriptSheet.swift          # Add/Edit form
└── Components/
    └── StatusBarComponent.swift       # Status display
```

### Database Schema

```sql
CREATE TABLE script_commands (
    id TEXT PRIMARY KEY,
    fileName TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    packageName TEXT,
    mode TEXT NOT NULL DEFAULT 'fullOutput',
    icon BLOB,
    hotkey TEXT,
    refreshTime TEXT,
    isEnabled BOOLEAN NOT NULL DEFAULT true,
    lastExecuted DATETIME,
    createdAt DATETIME NOT NULL
);
```

### Notification System

The Script Runner uses NotificationCenter for inter-component communication:

- `ShowScriptOutputView`: Display fullOutput mode view
- `ShowScriptArgumentForm`: Show argument input form
- `UpdateStatusBar`: Update status bar message

## Testing

### Manual Test Cases

1. **Full Output Mode**
   - Create script with `mode: fullOutput`
   - Execute from search bar
   - Verify terminal-like view appears
   - Check live output streaming
   - Verify "Done in X.XXs" message
   - Test "Rerun Script" button

2. **Compact Mode**
   - Create script with `mode: compact`
   - Execute and verify last line shows in status bar
   - Check green indicator appears

3. **Inline Mode**
   - Create script with `mode: inline`
   - Verify first line shows as subtitle in search results
   - Check output updates after execution

4. **Silent Mode**
   - Create script with `mode: silent`
   - Verify only status messages appear
   - Check "Script finished running" message

5. **With Arguments**
   - Create script with argument definitions
   - Execute and verify input form appears
   - Test required vs optional arguments
   - Test password field masking

6. **Scheduled Execution**
   - Create script with `refreshTime: 10s`
   - Wait and verify automatic execution
   - Check lastExecuted timestamp updates

7. **Settings Management**
   - Add new script via file picker
   - Edit existing script
   - Assign hotkey
   - Toggle enable/disable
   - Delete script (verify confirmation)

### Unit Tests

Run tests with:
```bash
swift test
```

Test coverage includes:
- Metadata parsing (all fields, edge cases)
- Script execution (shebang detection, arguments, exit codes)
- Scheduler (time parsing, periodic execution)
- File management (import, delete, path resolution)

## Known Limitations

1. **Swift 6 Concurrency Warnings**: The code has some MainActor isolation warnings that are benign in Swift 5.9 but will need to be addressed for Swift 6 compatibility.

2. **Hotkey Conflicts**: The hotkey recorder UI is a placeholder - full conflict detection needs to be implemented.

3. **Error Handling**: Some error cases could use more user-friendly error messages and recovery options.

## Future Enhancements

1. **Script Templates**: Pre-built templates for common use cases
2. **Script Marketplace**: Share and discover scripts
3. **Environment Variables**: Custom environment variable support
4. **Script Debugging**: Built-in debugging tools
5. **Output Formatting**: Markdown/HTML rendering support
6. **Script Dependencies**: Package manager integration

## Migration Notes

The v4 database migration runs automatically on first launch after updating. Existing users will see a new "Script Commands" tab in Settings.

## Troubleshooting

### Script Not Appearing in Search

1. Check script is in `~/.tachyon/scripts/`
2. Verify script has valid metadata (schemaVersion=1, title present)
3. Check script is enabled in Settings
4. Restart Tachyon

### Script Execution Fails

1. Verify shebang is correct (`#!/bin/bash`, `#!/usr/bin/env python3`, etc.)
2. Check script has execute permissions (`chmod +x script.sh`)
3. Test script in terminal first
4. Check stderr output in fullOutput mode

### Scheduled Script Not Running

1. Verify `refreshTime` format is correct ("1h", "30m", etc.)
2. Check script is enabled
3. Look for execution errors in console logs

## Contributing

When adding new features to the Script Runner:

1. Follow the existing plugin architecture
2. Add unit tests for new functionality
3. Update this documentation
4. Test all four output modes
5. Verify database migrations work correctly

## Credits

Inspired by [Raycast Script Commands](https://github.com/raycast/script-commands)
