# Calculator Feature

## Current Implementation

The calculator plugin provides real-time math evaluation, unit conversions, and currency conversion directly in the search bar.

### Supported Features

#### ✅ Math Expressions
- Basic arithmetic: `2+2`, `10-3`, `5*6`, `20/4`
- Percentages: `100*30%` = 30, `50+10%` = 55
- Math functions: `sqrt(16)`, `sin(0)`, `cos(0)`, `log(100)`, `ln(2.71)`
- Constants: `pi`, `e`
- Scientific notation: `2e3`, `3.14e-2`
- Operator precedence and parentheses: `2+3*4`, `(2+3)*4`

#### ✅ Unit Conversions
Six categories using Foundation's Measurement API:
- **Length**: km, m, cm, mm, miles, feet, inches, yards
  - Example: `5 km to miles`, `100 inches to cm`
- **Temperature**: Celsius, Fahrenheit, Kelvin
  - Example: `100 F to C`, `0 C to K`
- **Mass**: kg, g, lb, oz
  - Example: `1 kg to lb`, `100 g to oz`
- **Volume**: liters, ml, gallons, cups, fluid ounces
  - Example: `1 liter to gallons`, `100 ml to fl oz`
- **Time**: seconds, minutes, hours, days, weeks
  - Example: `2 hours to minutes`, `365 days to hours`
- **Data**: bytes, KB, MB, GB, TB
  - Example: `1 GB to MB`, `2048 bytes to KB`

#### 🔶 Currency Conversion (Limited)
Currently supports 31 major currencies via Frankfurter API:
- Supported: AUD, BGN, BRL, CAD, CHF, CNY, CZK, DKK, EUR, GBP, HKD, HUF, IDR, ILS, INR, ISK, JPY, KRW, MXN, MYR, NOK, NZD, PHP, PLN, RON, SEK, SGD, THB, TRY, USD, ZAR
- Features:
  - Live exchange rates with 1-hour caching
  - Shows "1 USD = X.XXXX EUR • Updated just now" in subtitle
  - Supports both symbol (`$100 to eur`) and code (`100 USD to EUR`) patterns
- **Limitation**: Does not support exotic currencies (e.g., ARS, VND, KZT)
  - Shows helpful message: "Currency not supported - We're working on adding more currencies"

#### ✅ History & Clipboard
- Press Enter to copy result to clipboard
- Success notification appears in status bar

---

## Future Enhancements

### 🎯 Priority: Hybrid Currency API Approach

**Problem**: Frankfurter API only supports 31 major currencies, excluding many important ones like:
- ARS (Argentine Peso)
- VND (Vietnamese Dong)
- KZT (Kazakhstani Tenge)
- And 130+ other currencies

**Planned Solution**: Implement a hybrid approach with fallback APIs

#### Implementation Plan

1. **Primary API**: Continue using Frankfurter for the 31 supported currencies
   - Fast and reliable
   - No API key required
   - Good for 90% of use cases

2. **Fallback APIs** (in order of preference):
   - **ExchangeRate-API** (https://www.exchangerate-api.com/)
     - Free tier: 1,500 requests/month
     - Supports 161 currencies
     - No API key for basic usage
   - **CurrencyAPI** (https://currencyapi.com/)
     - Free tier: 300 requests/month
     - Supports 150+ currencies
     - Requires API key
   - **Fixer.io** (https://fixer.io/)
     - Free tier: 100 requests/month
     - Supports 170 currencies
     - Requires API key

3. **Implementation Details**:
   ```swift
   // In CurrencyService.swift
   private func fetchRate(from: String, to: String) async -> CachedRate? {
       // Try Frankfurter first (if both currencies supported)
       if supportedByFrankfurter(from, to) {
           if let rate = await fetchFromFrankfurter(from, to) {
               return rate
           }
       }
       
       // Fallback to ExchangeRate-API for exotic currencies
       if let rate = await fetchFromExchangeRateAPI(from, to) {
           return rate
       }
       
       // Final fallback or return error
       return nil
   }
   ```

4. **Configuration**:
   - Add optional API keys to user settings (for paid tiers if needed)
   - Allow users to configure which APIs to use
   - Show in subtitle which API provided the rate (for transparency)

5. **Benefits**:
   - Covers 160+ currencies instead of 31
   - Maintains fast response for common currencies
   - Graceful degradation if one API is down
   - Future-proof for adding more providers

---

### 🎨 Custom Raycast-Style UI

**Current**: Results shown in standard list view
**Goal**: Custom card UI matching Raycast exactly

```
┌─────────────────────────────────────────────────────┐
│ Calculator (section header)                          │
├─────────────────────────────────────────────────────┤
│                                                      │
│     100*30%            →           30                │
│                                                      │
│   [Percentage]                  [Thirty]             │
│                                                      │
│             (Updated 3 hours ago for currency)       │
└─────────────────────────────────────────────────────┘
```

Implementation:
- Create `CalculatorResultView.swift` with custom layout
- Add `customViewData` to `QueryResult.swift`
- Modify `ResultsListView.swift` to detect and render calculator results specially

---

### 📊 Calculation History

Store last 100 calculations in SQLite database for quick access to previous results.

Implementation:
- Create `CalculationHistoryRecord.swift` (GRDB model)
- Add migration in `StorageManager.swift`
- Option to show recent calculations when search bar opens

---

### 🔧 Additional Features

- **More Math Functions**: `tan`, `asin`, `acos`, `atan`, `exp`, `pow`
- **Binary/Hex/Octal**: Support for `0b1010`, `0xFF`, `0o77`
- **Custom Units**: User-defined conversion factors
- **Expression Variables**: `x = 5; y = 10; x * y`

---

## Technical Details

### Architecture

```
CalculatorPlugin
├── CalculatorEngine (recursive descent parser)
├── UnitConverter (Foundation Measurement API)
└── CurrencyService (Frankfurter API)
```

### Files

- `Sources/Tachyon/Features/Calculator/`
  - `CalculatorPlugin.swift` - Plugin entry point
  - `CalculatorEngine.swift` - Math expression parser
  - `UnitConverter.swift` - Unit conversion logic
  - `CurrencyService.swift` - Currency API integration
  - `CalculationResult.swift` - Data models

### Testing

- `Tests/TachyonTests/FeatureTests/`
  - `CalculatorEngineTests.swift`
  - `UnitConverterTests.swift`
  - `CurrencyServiceTests.swift`

---

## Decision Log

### 2025-12-23: Currency API Limitation

**Decision**: Use Frankfurter API for initial implementation with validation
**Rationale**: 
- Simple, no API key required
- Covers 31 most common currencies (90% of use cases)
- Fast and reliable
**Limitation**: Doesn't support exotic currencies like ARS
**Future**: Implement hybrid approach with fallback to ExchangeRate-API

### 2025-12-23: TDD Approach

**Decision**: Write tests first, then implementation
**Rationale**: Ensures comprehensive test coverage and clear API design
**Status**: Core tests written, some need fixes for optional unwrapping

### 2025-12-23: Custom UI Deferred  

**Decision**: Use standard list view initially, custom UI later
**Rationale**: Get functional calculator working first, then polish UI
**Priority**: Medium (after hybrid currency API)
