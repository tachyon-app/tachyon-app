# Date & Time Calculations

Tachyon includes powerful date and time calculation features that let you work with dates, timestamps, timezones, and perform date arithmetic directly from the search bar.

## Usages

Type your date query into the search bar. Results appear instantly with multiple format options.

- **Copy Result**: Press `Enter` to copy the formatted date to your clipboard.
- **Multiple Formats**: Each result includes Unix timestamp, ISO 8601, RFC 2822, and human-readable formats.

## Features

### Unix Timestamp Conversion

Convert Unix timestamps to human-readable dates and vice versa.

**Supported Formats:**
- **10-digit** (seconds): `1703347200`
- **13-digit** (milliseconds): `1703347200000`
- **16-digit** (microseconds): `1703347200000000`

**Keywords:**
- `now in unix` - Get current Unix timestamp
- `current epoch` - Same as above
- `unix timestamp` - Current timestamp
- `epoch` - Current timestamp

**Examples:**
```
1703347200
→ Saturday, 23 December 2023 at 16:00:00
→ Unix: 1703347200 | ISO: 2023-12-23T16:00:00Z

now in unix
→ Current Unix timestamp with all formats
```

### Natural Language Dates

Parse dates using natural language expressions.

**Simple Dates:**
- `today` - Current date
- `tomorrow` - Next day
- `yesterday` - Previous day
- `now` - Current date and time

**Weekdays:**
- `monday`, `tuesday`, etc. - Next occurrence of that weekday
- `next friday` - Explicitly next Friday
- `last monday` - Previous Monday

**Relative Dates:**
- `in 2 days` - Two days from now
- `in 3 weeks` - Three weeks from now
- `in 5 months` - Five months from now
- `3 days ago` - Three days in the past
- `2 weeks ago` - Two weeks in the past

**Complex Patterns:**
- `monday in 3 weeks` - Monday occurring in 3 weeks
- `friday in 2 months` - Friday occurring in 2 months

**Examples:**
```
tomorrow
→ Sunday, 24 December 2023 at 12:00:00

next friday
→ Friday, 29 December 2023 at 12:00:00

in 2 weeks
→ Saturday, 6 January 2024 at 12:00:00
```

### Date Arithmetic

Perform calculations with dates using addition and subtraction.

**Syntax:** `[date] [+/-] [amount] [unit]`

**Supported Units:**
- seconds, minutes, hours
- days, weeks, months, years
- Both singular and plural forms work

**Examples:**
```
today + 3 days
→ Tuesday, 26 December 2023

tomorrow - 2 hours
→ Sunday, 24 December 2023 at 10:00:00

now + 1 week
→ Sunday, 30 December 2023
```

### Timezone Conversions

Get current time in any timezone or convert times between timezones.

**Simple Timezone Queries:**
- `time in tokyo` - Current time in Tokyo
- `time in new york` - Current time in New York
- `nyc time` - Using city abbreviations
- `london time` - Current time in London

**Timezone Conversions:**
- `5pm london in tokyo` - Convert 5 PM London time to Tokyo
- `9am nyc in paris` - Convert 9 AM NYC time to Paris
- `12pm utc in sydney` - Convert noon UTC to Sydney

**Supported Cities:**
Over 50 major cities worldwide including:
- **Americas**: New York (NYC), Los Angeles (LA), San Francisco (SF), Chicago, Toronto, Mexico City
- **Europe**: London, Paris, Berlin, Madrid, Rome, Amsterdam
- **Asia**: Tokyo, Singapore, Hong Kong, Dubai, Mumbai, Beijing
- **Oceania**: Sydney, Melbourne, Auckland

**Examples:**
```
time in tokyo
→ Monday, 25 December 2023 at 01:00:00 JST

5pm london in tokyo
→ Tuesday, 26 December 2023 at 02:00:00 JST
```

### Duration Calculations

Calculate time remaining until a specific date or event.

**Syntax:** `days until [date]` or `time until [date]`

**Special Dates:**
- `christmas` → December 25
- `new year` → January 1
- `halloween` → October 31
- `valentine` → February 14

**Examples:**
```
days until christmas
→ 2 days until December 25, 2023

time until new year
→ 8 days until January 1, 2024

days until march 15
→ 82 days until March 15, 2024
```

### Date Differences

Calculate the difference between two dates.

**Syntax:** `[date1] - [date2]`

**Examples:**
```
tomorrow - today
→ 1 day

dec 25 - today
→ 2 days
```

### Week & Day Numbers

Get ISO week numbers and day of year information.

**Queries:**
- `week number` - Current ISO week number
- `what week is it` - Same as above
- `day number` - Current day of year
- `day of year` - Same as above

**Examples:**
```
week number
→ Week 51, Day 6 of 2023

day of year
→ Day 357 of 365
```

## Output Formats

Every date result includes multiple formats for easy copying:

- **Human-Readable**: "Saturday, 23 December 2023 at 16:00:00"
- **Unix Seconds**: 1703347200
- **Unix Milliseconds**: 1703347200000
- **ISO 8601**: 2023-12-23T16:00:00Z
- **RFC 2822**: Sat, 23 Dec 2023 16:00:00 +0000
- **Relative**: "in 2 days" or "3 days ago"

## Tips

- All queries are **case-insensitive**: `TODAY` works the same as `today`
- Results **always show** even if they don't match your query text exactly
- Use **natural language** - the parser is smart and flexible
- **Copy any format** by pressing Enter on the result
- Dates are calculated in your **local timezone** unless specified otherwise
