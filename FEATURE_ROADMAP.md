# Tachyon vs Raycast: Missing Features

## Priority Matrix (Effort vs Impact)

```
                        HIGH IMPACT
                            │
    ┌───────────────────────┼───────────────────────┐
    │                       │                       │
    │  🎯 DO FIRST          │  📋 PLAN CAREFULLY    │
    │                       │  • Window Switcher    │
    │                       │    (Alt-Tab style)    │
    │  • Calculator         │  • Clipboard History  │
    │  • System Commands    │  • File Search        │
    │  • Emoji Picker       │  • Snippets           │
    │  • Date Calculations  │  • AI Integration     │
    │                       │                       │
LOW ├───────────────────────┼───────────────────────┤ HIGH
EFFORT                      │                       EFFORT
    │                       │                       │
    │  ⏳ FILL INS          │  🔮 FUTURE            │
    │                       │                       │
    │  • Command Aliases    │  • Focus Mode         │
    │  • Camera Preview     │  • Extension API      │
    │  • Hyper Key          │  • Browser Extension  │
    │  • Color Picker       │  • Notes              │
    │                       │  • Auto Quit Apps     │
    │                       │                       │
    └───────────────────────┼───────────────────────┘
                            │
                        LOW IMPACT
```

---

## 🎯 DO FIRST: Low Effort, High Impact

| Feature | Effort | Description |
|---------|--------|-------------|
| **Calculator** | ~2 days | Math expressions in search bar, unit/currency conversions |
| **System Commands** | ~1 day | Sleep, lock, volume, brightness, dark mode, empty trash |
| **Emoji Picker** | ~1 day | Quick emoji search, recently used, categories |
| **Date Calculations** | ~1 day | "today + 30 days", date diffs, timezone conversion |

---

## 📋 PLAN CAREFULLY: High Effort, High Impact

| Feature | Effort | Description |
|---------|--------|-------------|
| **Clipboard History** | ~1 week | Text/image/file history, search, pinned items *(already planned)* |
| **File Search** | ~1 week | Spotlight integration, preview, recent files |
| **Snippets** | ~1 week | Text templates with variables, auto-expansion |
| **AI Integration** | ~2 weeks | Chat with LLMs, custom AI commands *(requires API keys)* |

---

## ⏳ FILL INS: Low Effort, Lower Impact

| Feature | Effort | Description |
|---------|--------|-------------|
| **Command Aliases** | ~0.5 days | "gc" → "git commit" shortcuts |
| **Camera Preview** | ~0.5 days | Quick camera check before meetings |
| **Hyper Key** | ~1 day | Caps Lock → Ctrl+Option+Cmd+Shift |
| **Color Picker** | ~2 days | Pick from screen, HEX/RGB/HSL conversion |

---

## 🔮 FUTURE: High Effort, Lower Priority

| Feature | Effort | Description |
|---------|--------|-------------|
| **Focus Mode** | ~2 weeks | DND, Pomodoro, app blocking *(already planned)* |
| **Extension API** | ~1 month | Developer SDK, plugin marketplace |
| **Browser Extension** | ~1 week | Tab search, bookmarks, current page actions |
| **Notes** | ~1 week | Quick capture, local storage |
| **Auto Quit Apps** | ~3 days | Quit idle apps automatically |

---

## Recommended Order

1. **Calculator** — Quick win, every launcher has this
2. **System Commands** — Low effort, rounds out feature set  
3. **Emoji Picker** — Fun, frequently used
4. **Clipboard History** — Already planned, very high value
5. **File Search** — Core launcher functionality

---

**Currently Implemented ✅**: App Launcher • Fuzzy Search • Custom Links • Search Engines • Script Runner • Window Snapping • Global Hotkeys • Clipboard History
