# Search & App Launcher

The core feature of Tachyon is the intelligent Search Bar and App Launcher. It allows you to quickly launch applications, find files, and execute commands without taking your hands off the keyboard.

## Usage

1. **Invoke Tachyon**: Press the global hotkey (default: `Option + Space`) to open the search bar.
2. **Type to Search**: Start typing the name of an application, file, or command.
3. **Select & Act**:
   - Use `↑` and `↓` arrow keys to navigate results.
   - Press `Enter` to open the selected item (launch app, open file, run command).

## App Launcher

Tachyon automatically indexes applications from standard macOS locations:
- `/Applications`
- `/System/Applications`
- `~/Applications`
- `/System/Library/CoreServices/Applications`

### Features
- **Fuzzy Search**: You don't need to type the exact name. Partial matches and initials often work (e.g., "chr" for Chrome).
- **Prioritization**: Frequently used apps will appear higher in the results over time (managed by the `QueryEngine`).
- **Performance**: The launcher uses a lightweight index to ensure results appear instantly.

## Default View

When you first open Tachyon without typing, it displays a list of your most recently or frequently used applications (limited to top 20 initially) to provide instant access to your daily tools.
