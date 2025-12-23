# Search Engines

Tachyon serves as a central hub for searching the web. You can configure custom search engines that can be triggered directly or used as fallbacks when no local match is found.

## Configuration

1. Go to **Settings > Search Engines**.
2. Add a new engine with a **Name**, **Keyword**, and **URL Template**.

## Usage

### Fallback Search
If you type a query that doesn't match any apps, commands, or files, Tachyon will offer to "Search in [Default Engine]" (usually Google) or other configured engines.

### Direct Access
Your configured search engines appear in the search results. Selecting one allows you to perform a web search for your current query instantly.

## URL Template
The URL must contain `{{query}}` where your search terms should be inserted.

**Examples:**
- **Google**: `https://www.google.com/search?q={{query}}`
- **GitHub**: `https://github.com/search?q={{query}}`
- **Twitter**: `https://twitter.com/search?q={{query}}`
