# Creating Custom Themes for Tachyon

Tachyon supports custom themes via JSON files. You can create your own themes to customize the look and feel of the launcher.

## location

Theme files must be placed in:
`~/.tachyon/themes/`

The filename must end with `.json` (e.g., `~/.tachyon/themes/my-red-theme.json`).

## JSON Structure

A theme file is a JSON object containing color definitions. All colors must be specified as Hex strings.

### Transparency (Alpha Channel)
You can control the transparency (alpha) of any color by using an **8-digit Hex code**.
- Format: `#AARRGGBB` (Alpha, Red, Green, Blue)
- Example: `#80FF0000` is 50% transparent Red.
- `00` is fully transparent, `FF` is fully opaque.

If you use a standard 6-digit Hex code (e.g., `#FF0000`), it is treated as fully opaque (`#FF....`).

### Metadata

| Key | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Unique identifier for your theme (e.g., "my-custom-theme") |
| `name` | String | Display name shown in Settings (e.g., "My Custom Theme") |

### Window Configuration

| Key | Type | Description |
| :--- | :--- | :--- |
| `windowBackgroundColor` | Hex Color | Base background color of the window |
| `windowBackgroundGradientColors` | [Hex Color] | **Optional**. Array of colors for a linear gradient background. Overrides `windowBackgroundColor`. |
| `windowBorderColor` | Window border color | `#00000033` (Transparent Black) |
| `windowCornerRadius` | Corner radius of the window | `12.0` |
| `windowWidth` | Width of the search window (optional) | `680.0` (Default) |

### Search Field
| Key | Description | Example |
| :--- | :--- | :--- |
| `searchFieldBackgroundColor` | Hex Color | Background color of the search input area |
| `searchFieldTextColor` | Hex Color | Color of the text typed in the search bar |
| `searchFieldPlaceholderColor` | Hex Color | Color of the placeholder text |
| `searchIconColor` | Hex Color | Color of the magnifying glass icon |

### Results List

| Key | Type | Description |
| :--- | :--- | :--- |
| `resultRowBackgroundColor` | Hex Color | Default background color for unselected rows |
| `resultRowSelectedBackgroundColor` | Hex Color | Background color for the selected row |
| `resultRowTextColor` | Hex Color | Text color for unselected rows |
| `resultRowSelectedTextColor` | Hex Color | Text color for the selected row |
| `resultRowSubtextColor` | Hex Color | Subtitle text color for unselected rows |
| `resultRowSelectedSubtextColor` | Hex Color | Subtitle text color for the selected row |
| `resultIconColor` | Hex Color | Icon color for unselected rows |
| `resultSelectedIconColor` | Hex Color | Icon color for the selected row |

### Status Bar & Common

| Key | Type | Description |
| :--- | :--- | :--- |
| `statusBarBackgroundColor` | Hex Color | Background color of the status bar (bottom area) |
| `statusBarTextColor` | Hex Color | Text/Icon color in the status bar |
| `accentColor` | Hex Color | Primary accent color (used for focus indicators, etc.) |
| `separatorColor` | Hex Color | Color of the thin line separating search field and results |

## Example Theme

Save this as `~/.tachyon/themes/dracula.json`:

```json
{
  "id": "dracula",
  "name": "Dracula",
  "windowBackgroundColor": "#282a36",
  "windowBorderColor": "#6272a4",
  "windowCornerRadius": 10.0,
  
  "searchFieldBackgroundColor": "#44475a",
  "searchFieldTextColor": "#f8f8f2",
  "searchFieldPlaceholderColor": "#6272a4",
  "searchIconColor": "#bd93f9",
  
  "resultRowBackgroundColor": "#282a36",
  "resultRowSelectedBackgroundColor": "#44475a",
  "resultRowTextColor": "#f8f8f2",
  "resultRowSelectedTextColor": "#50fa7b",
  "resultRowSubtextColor": "#6272a4",
  "resultRowSelectedSubtextColor": "#8be9fd",
  "resultIconColor": "#6272a4",
  "resultSelectedIconColor": "#50fa7b",
  
  "statusBarBackgroundColor": "#282a36",
  "statusBarTextColor": "#bd93f9",
  
  "accentColor": "#ff79c6",
  "separatorColor": "#44475a"
}
```

## Loading Your Theme

1. Place your JSON file in `~/.tachyon/themes/`.
2. Open Tachyon Settings (`Cmd+,`).
3. Go to **Appearance**.
4. Click **Reload Themes** (or restart the app).
5. Select your new theme from the dropdown properly.
