# Tachyon UI/UX Design System Guide for AI Agents

> **Critical**: This document defines the exact UI/UX standards for Tachyon. All UI changes MUST follow these guidelines to maintain Raycast-level polish and consistency.

---

## 🎨 Design Philosophy

**Core Principle**: Clone Raycast's aesthetic exactly. Every pixel matters.

### Key Tenets
1. **Subtlety Over Obviousness** - Reduced opacities, invisible borders
2. **Precision Over Approximation** - Every measurement is intentional
3. **Darkness Over Lightness** - Darker backgrounds create premium feel
4. **Tightness Over Looseness** - Compact spacing, efficient use of space
5. **Smoothness Over Abruptness** - 120-200ms animations everywhere
6. **Consistency Over Variation** - Unified spacing and sizing system

---

## 🧪 Test-Driven Development (TDD)

**Core Principle**: All features MUST be developed using strict Test-Driven Development. Tests are not optional - they are the specification.

### TDD Workflow

#### 1. Red Phase - Write Failing Tests First
```swift
// ALWAYS write tests BEFORE implementation
// Tests define the contract and expected behavior

import XCTest
@testable import Tachyon

class CalculatorTests: XCTestCase {
    func testBasicAddition() {
        let calculator = Calculator()
        let result = calculator.evaluate("2 + 2")
        XCTAssertEqual(result.value, 4.0)
    }
    
    func testComplexExpression() {
        let calculator = Calculator()
        let result = calculator.evaluate("(10 + 5) * 2")
        XCTAssertEqual(result.value, 30.0)
    }
}
```

#### 2. Green Phase - Minimal Implementation
- Write the **minimum code** needed to make tests pass
- Don't add features not covered by tests
- Keep it simple and focused

#### 3. Refactor Phase - Improve Code Quality
- Clean up implementation while keeping tests green
- Extract reusable components
- Improve naming and structure
- **Tests must remain passing throughout**

### Testing Requirements

#### Coverage Standards
- **Minimum 80% code coverage** for all new features
- **100% coverage** for critical business logic (calculations, data transformations, etc.)
- All public APIs must have corresponding tests
- Edge cases and error conditions must be tested

#### Test Organization
```swift
// Organize tests by feature in Tests/ directory
Tests/
├── Features/
│   ├── Calculator/
│   │   ├── CalculatorTests.swift
│   │   ├── ExpressionParserTests.swift
│   │   └── UnitConverterTests.swift
│   ├── Search/
│   │   ├── SearchEngineTests.swift
│   │   └── QueryParserTests.swift
│   └── WindowSnapping/
│       ├── SnappingEngineTests.swift
│       └── HotkeyManagerTests.swift
└── UI/
    ├── SearchBarTests.swift
    └── SettingsViewTests.swift
```

#### What to Test

**✅ MUST Test:**
1. **Business Logic** - All calculations, transformations, algorithms
2. **Data Models** - Validation, serialization, relationships
3. **API Contracts** - Public methods, expected inputs/outputs
4. **Edge Cases** - Empty inputs, null values, boundary conditions
5. **Error Handling** - Invalid inputs, network failures, exceptions
6. **State Management** - State transitions, persistence, synchronization
7. **Integration Points** - Database operations, external APIs, system interactions

**Example - Comprehensive Test Suite:**
```swift
class CalculatorTests: XCTestCase {
    var calculator: Calculator!
    
    override func setUp() {
        super.setUp()
        calculator = Calculator()
    }
    
    // MARK: - Basic Operations
    func testAddition() { /* ... */ }
    func testSubtraction() { /* ... */ }
    func testMultiplication() { /* ... */ }
    func testDivision() { /* ... */ }
    
    // MARK: - Edge Cases
    func testDivisionByZero() {
        let result = calculator.evaluate("10 / 0")
        XCTAssertTrue(result.isError)
        XCTAssertEqual(result.errorMessage, "Division by zero")
    }
    
    func testEmptyExpression() {
        let result = calculator.evaluate("")
        XCTAssertTrue(result.isError)
    }
    
    func testInvalidSyntax() {
        let result = calculator.evaluate("2 + + 3")
        XCTAssertTrue(result.isError)
    }
    
    // MARK: - Complex Expressions
    func testOrderOfOperations() {
        XCTAssertEqual(calculator.evaluate("2 + 3 * 4").value, 14.0)
    }
    
    func testParentheses() {
        XCTAssertEqual(calculator.evaluate("(2 + 3) * 4").value, 20.0)
    }
    
    // MARK: - Unit Conversions
    func testTemperatureConversion() {
        let result = calculator.evaluate("32°F to °C")
        XCTAssertEqual(result.value, 0.0, accuracy: 0.01)
    }
    
    // MARK: - History
    func testHistoryTracking() {
        calculator.evaluate("2 + 2")
        calculator.evaluate("5 * 3")
        XCTAssertEqual(calculator.history.count, 2)
    }
    
    func testHistoryLimit() {
        for i in 1...150 {
            calculator.evaluate("\(i) + 1")
        }
        XCTAssertEqual(calculator.history.count, 100) // Max 100 entries
    }
}
```

#### Test Quality Standards

**✅ Good Tests:**
- **Fast** - Run in milliseconds
- **Independent** - No dependencies between tests
- **Repeatable** - Same result every time
- **Self-validating** - Clear pass/fail
- **Timely** - Written before implementation
- **Readable** - Clear intent and assertions

**❌ Bad Tests:**
- Tests that depend on external services
- Tests that require specific execution order
- Tests with random or time-dependent behavior
- Tests that test implementation details instead of behavior
- Overly complex tests that are hard to understand

### Running Tests

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter CalculatorTests

# Run with coverage
swift test --enable-code-coverage

# Generate coverage report
xcrun llvm-cov report .build/debug/TachyonPackageTests.xctest/Contents/MacOS/TachyonPackageTests
```

### Continuous Integration

- All tests MUST pass before merging
- Coverage reports must meet minimum thresholds
- Failed tests block deployment
- Test results should be visible in PR reviews

### TDD Best Practices

1. **Write the test first** - No exceptions
2. **One test at a time** - Focus on one behavior
3. **Keep tests simple** - One assertion per test when possible
4. **Use descriptive names** - `testCalculatorReturnsErrorWhenDividingByZero`
5. **Test behavior, not implementation** - Focus on what, not how
6. **Refactor with confidence** - Tests enable safe refactoring
7. **Mock external dependencies** - Keep tests isolated and fast
8. **Test edge cases** - Empty, null, negative, boundary values
9. **Document with tests** - Tests are living documentation
10. **Keep tests maintainable** - Refactor tests as you refactor code

---

## 📖 Documentation Requirements

**Core Principle**: Every feature MUST be extensively documented for end users. Documentation is not an afterthought - it's part of the feature.

### Documentation Structure

```
docs/
├── README.md                 # Overview and quick start
├── FEATURES.md              # Feature catalog
├── CALCULATOR.md            # Calculator feature guide
├── SEARCH.md                # Search feature guide
├── WINDOW_SNAPPING.md       # Window snapping guide
├── CUSTOM_LINKS.md          # Custom links guide
├── KEYBOARD_SHORTCUTS.md    # Complete shortcut reference
├── SETTINGS.md              # Settings documentation
├── TROUBLESHOOTING.md       # Common issues and solutions
└── CHANGELOG.md             # Version history
```

### Feature Documentation Template

Every feature MUST have a dedicated documentation file following this structure:

```markdown
# Feature Name

## Overview
Brief description of what the feature does and why it's useful.

## Quick Start
Simplest possible example to get started.

## How It Works
Detailed explanation of the feature's functionality.

## Usage Examples
Multiple real-world examples showing different use cases.

## Advanced Features
Power user features and advanced configurations.

## Keyboard Shortcuts
All relevant keyboard shortcuts for this feature.

## Settings
Configuration options and customization.

## Tips & Tricks
Best practices and productivity tips.

## Troubleshooting
Common issues and how to resolve them.

## Technical Details
(Optional) Implementation details for advanced users.
```

### Documentation Standards

#### 1. User-Focused Language
**✅ DO:**
- "Press `⌘Space` to open Tachyon"
- "Type your calculation and press Enter to copy the result"
- "The calculator supports complex expressions like `(10 + 5) * 2`"

**❌ DON'T:**
- "The hotkey manager registers a global event listener"
- "The parser tokenizes the input string"
- "The view model observes the calculation state"

#### 2. Rich Examples
Every feature should include **at least 5-10 practical examples**:

```markdown
## Calculator Examples

### Basic Arithmetic
- `2 + 2` → 4
- `10 - 3` → 7
- `5 * 6` → 30
- `100 / 4` → 25

### Complex Expressions
- `(10 + 5) * 2` → 30
- `2^8` → 256
- `sqrt(144)` → 12

### Unit Conversions
- `100 USD to EUR` → 92.50 EUR
- `32°F to °C` → 0°C
- `10 miles to km` → 16.09 km
- `5 hours to minutes` → 300 minutes

### Percentages
- `20% of 150` → 30
- `150 + 20%` → 180
- `150 - 20%` → 120
```

#### 3. Visual Aids
- Include screenshots for UI features
- Use code blocks for examples
- Add tables for reference information
- Use emoji for visual scanning (✅ ❌ 💡 ⚠️)

#### 4. Keyboard Shortcuts
Always document keyboard shortcuts in macOS format:
- `⌘` Command
- `⌥` Option
- `⌃` Control
- `⇧` Shift
- `↵` Return/Enter
- `⌫` Delete
- `⎋` Escape

#### 5. Progressive Disclosure
Organize from simple to complex:
1. **Quick Start** - Get started in 30 seconds
2. **Common Use Cases** - Cover 80% of usage
3. **Advanced Features** - Power user capabilities
4. **Technical Details** - For those who want to know more

### Documentation Checklist

When adding a new feature, ensure:

- [ ] Feature has dedicated `.md` file in `docs/`
- [ ] Feature is listed in `docs/FEATURES.md`
- [ ] Quick start section with simple example
- [ ] At least 5-10 usage examples
- [ ] All keyboard shortcuts documented
- [ ] Settings and configuration options explained
- [ ] Screenshots for UI features
- [ ] Troubleshooting section for common issues
- [ ] Updated `CHANGELOG.md` with new feature
- [ ] Cross-references to related features
- [ ] Reviewed for clarity by someone unfamiliar with the feature

### Example: Complete Feature Documentation

**docs/CALCULATOR.md:**
```markdown
# Calculator

## Overview
Tachyon includes a powerful calculator that appears inline as you type. It supports basic arithmetic, complex expressions, unit conversions, and currency conversion.

## Quick Start
1. Open Tachyon with `⌘Space`
2. Type `2 + 2`
3. See the result (4) appear instantly
4. Press `↵` to copy the result

## Basic Calculations

Type any mathematical expression:
- `2 + 2` → 4
- `10 * 5` → 50
- `100 / 4` → 25
- `15 - 3` → 12

## Complex Expressions

Use parentheses and multiple operations:
- `(10 + 5) * 2` → 30
- `2^8` → 256
- `sqrt(144)` → 12
- `sin(90)` → 1

## Unit Conversions

### Temperature
- `32°F to °C` → 0°C
- `100°C to °F` → 212°F

### Distance
- `10 miles to km` → 16.09 km
- `5 km to meters` → 5000 m

### Time
- `2 hours to minutes` → 120 minutes
- `90 seconds to minutes` → 1.5 minutes

### Currency
- `100 USD to EUR` → 92.50 EUR (live rates)
- `50 GBP to USD` → 63.50 USD

## History

Tachyon remembers your last 100 calculations.
- Access history with `⌘H`
- Search through history
- Click any result to copy it

## Keyboard Shortcuts

- `↵` - Copy result to clipboard
- `⌘H` - View calculation history
- `⎋` - Clear input

## Settings

### Decimal Precision
Configure how many decimal places to show:
- Settings → Calculator → Decimal Places (default: 2)

### Currency Updates
Currency rates update every 6 hours automatically.

## Tips & Tricks

💡 **Quick Copy**: Press Enter to instantly copy the result
💡 **Chaining**: Use the previous result with `ans` variable
💡 **Percentages**: `150 + 20%` adds 20% to 150

## Troubleshooting

**Q: Currency conversion shows "Rate unavailable"**
A: Check your internet connection. Rates require network access.

**Q: Calculator doesn't appear**
A: Make sure you're typing a valid mathematical expression.

**Q: Result is incorrect**
A: Check operator precedence. Use parentheses to clarify: `(2 + 3) * 4`

## Supported Functions

| Function | Example | Result |
|----------|---------|--------|
| sqrt(x) | sqrt(16) | 4 |
| sin(x) | sin(90) | 1 |
| cos(x) | cos(0) | 1 |
| tan(x) | tan(45) | 1 |
| log(x) | log(100) | 2 |
| ln(x) | ln(e) | 1 |
| abs(x) | abs(-5) | 5 |
| round(x) | round(3.7) | 4 |
```

### Keeping Documentation Updated

1. **Update docs WITH code changes** - Not after
2. **Review docs in PRs** - Documentation is part of the feature
3. **Test examples** - Ensure all examples actually work
4. **Get feedback** - Have someone unfamiliar test the docs
5. **Version documentation** - Note which version features were added

### Documentation Best Practices

1. **Write for beginners** - Assume no prior knowledge
2. **Show, don't tell** - Use examples liberally
3. **Be concise** - Respect the reader's time
4. **Use active voice** - "Press Enter" not "Enter should be pressed"
5. **Test your examples** - Every example must work
6. **Update screenshots** - Keep visuals current
7. **Link related topics** - Help users discover features
8. **Include search keywords** - Think about how users will search
9. **Provide context** - Explain why, not just how
10. **Maintain consistency** - Use same terminology throughout

---

## 🎯 Color System

### Background Colors
```swift
// Main backgrounds
#161616  // Primary background (almost black) - sheets, modals
#1a1a1a  // Secondary background - main windows
#1e1e1e  // Input field backgrounds
#252525  // Keyboard shortcut badges, slightly elevated elements

// Interactive backgrounds
Color.white.opacity(0.03)  // Inactive pill/button background
Color.white.opacity(0.04)  // Hover state (very subtle)
Color.white.opacity(0.05)  // Button background (subtle)
Color.white.opacity(0.06)  // Hover state (buttons), disabled button bg
Color.white.opacity(0.08)  // Unfocused border (almost invisible)

// Accent colors
#3B86F7  // Primary blue (links, primary actions)
#FF6B35  // Secondary orange (search engines)
```

### Text Colors
```swift
// Text opacities
Color.white.opacity(1.0)   // Primary text (headings, important)
Color.white.opacity(0.9)   // High emphasis text
Color.white.opacity(0.85)  // Body text
Color.white.opacity(0.75)  // Medium emphasis
Color.white.opacity(0.7)   // Secondary text
Color.white.opacity(0.6)   // Tertiary text
Color.white.opacity(0.55)  // Subtle text
Color.white.opacity(0.5)   // Labels, placeholders
Color.white.opacity(0.45)  // De-emphasized text
Color.white.opacity(0.4)   // Helper text, hints
Color.white.opacity(0.35)  // Very subtle helper text
```

### Border & Divider Colors
```swift
// Borders
Color.white.opacity(0.08)  // Default border (0.5px width)
Color.white.opacity(0.8)   // Focused border (1.5px width)
Color.red.opacity(0.5)     // Error border (validation)

// Dividers
Color.white.opacity(0.04)  // Ultra-subtle dividers (sheets)
Color.white.opacity(0.06)  // Subtle dividers (main UI)
```

---

## 📏 Spacing System

### Base Unit: 4px
All spacing should be multiples of 4px (or occasionally 2px for micro-adjustments).

### Standard Spacing Values
```swift
// Micro spacing
2px   // Tight spacing between related elements
3px   // Text line spacing
4px   // Minimum spacing
6px   // Small gaps
7px   // Pill/button internal spacing
8px   // Icon spacing, small gaps

// Standard spacing
10px  // Content spacing
12px  // Field padding (horizontal), section spacing
14px  // Medium spacing
16px  // Large spacing, field gaps
18px  // Section top padding
20px  // Container padding

// Macro spacing
24px  // Large container padding
28px  // Form field spacing
32px  // Major section spacing
40px  // Extra large spacing
50px  // Form horizontal padding
60px  // Maximum spacing
```

### Component-Specific Spacing

#### List Items
```swift
.padding(.horizontal, 20)  // Row horizontal padding
.padding(.vertical, 12)    // Row vertical padding
spacing: 0                 // No gap between rows
```

#### Form Fields
```swift
.padding(.horizontal, 50)  // Form horizontal padding
.padding(.top, 32)         // Form top padding
spacing: 24                // Between fields
```

#### Headers/Footers
```swift
.padding(.horizontal, 24)  // Header/footer horizontal
.padding(.vertical, 12)    // Header/footer vertical
```

---

## 🔤 Typography System

### Font Sizes
```swift
// Headings
26px  // Large heading (settings page title)
24px  // Section heading
18px  // Subsection heading

// Body text
13px  // Primary body text, labels, buttons (MOST COMMON)
12px  // Secondary text, helper text
11px  // Small text, section headers (uppercase)
10px  // Keyboard shortcuts, micro text
```

### Font Weights
```swift
.semibold  // Headings, important actions
.medium    // Labels, buttons, emphasized text (MOST COMMON)
.regular   // Body text, inputs
```

### Text Styles
```swift
// Primary button/label
.font(.system(size: 13, weight: .medium))
.foregroundColor(.white)

// Secondary text
.font(.system(size: 13, weight: .regular))
.foregroundColor(Color.white.opacity(0.5))

// Helper text
.font(.system(size: 11))
.foregroundColor(Color.white.opacity(0.35))

// Section header (uppercase)
.font(.system(size: 11, weight: .semibold))
.foregroundColor(Color.white.opacity(0.4))
.textCase(.uppercase)
.tracking(0.6)
```

---

## 🎛️ Component Specifications

### Buttons

#### Primary Button (Enabled)
```swift
.font(.system(size: 13, weight: .medium))
.foregroundColor(.white)
.padding(.horizontal, 16)
.padding(.vertical, 7)
.background(Color(hex: "#3B86F7"))
.cornerRadius(6)
```

#### Primary Button (Disabled)
```swift
.foregroundColor(Color.white.opacity(0.4))
.background(Color.white.opacity(0.04))  // Almost invisible
```

#### Secondary Button
```swift
.font(.system(size: 12))
.foregroundColor(Color.white.opacity(0.4))
.buttonStyle(.plain)
```

#### Icon Button
```swift
Image(systemName: "arrow.left")
    .font(.system(size: 13, weight: .medium))
    .foregroundColor(Color.white.opacity(0.6))
    .frame(width: 28, height: 28)
    .background(Color.white.opacity(0.05))
    .cornerRadius(5)
```

### Text Fields

#### Standard Input Field
```swift
TextField("Placeholder", text: $binding, onEditingChanged: { editing in
    // Track focus state
})
.textFieldStyle(PlainTextFieldStyle())
.font(.system(size: 13))
.foregroundColor(.white)
.padding(.horizontal, 12)
.padding(.vertical, 9)
.background(Color(hex: "#1e1e1e"))
.cornerRadius(5)
.overlay(
    RoundedRectangle(cornerRadius: 5)
        .stroke(
            isFocused ? Color.white.opacity(0.8) :
            (hasError ? Color.red.opacity(0.5) : Color.white.opacity(0.08)),
            lineWidth: isFocused ? 1.5 : 0.5
        )
)
```

#### Focus State Management
```swift
@State private var focusedField: Field? = nil

TextField("...", text: $text, onEditingChanged: { editing in
    withAnimation(.easeOut(duration: 0.15)) {
        focusedField = editing ? .fieldName : nil
    }
})
```

### Pills/Filters

#### Filter Pill
```swift
HStack(spacing: 6) {
    Image(systemName: icon)
        .font(.system(size: 12, weight: .medium))
    Text(title)
        .font(.system(size: 13, weight: .medium))
}
.foregroundColor(isSelected ? .white : Color.white.opacity(0.6))
.padding(.horizontal, 13)
.padding(.vertical, 8)
.background(
    Capsule()
        .fill(isSelected ? Color(hex: "#3B86F7") : 
              (isHovered ? Color.white.opacity(0.06) : Color.white.opacity(0.03)))
)
```

### List Items

#### Source List Item
```swift
HStack(spacing: 14) {
    // Icon (36x36)
    ZStack {
        RoundedRectangle(cornerRadius: 8)
            .fill(iconColor.opacity(0.12))
            .frame(width: 36, height: 36)
        Image(systemName: icon)
            .font(.system(size: 17, weight: .medium))
            .foregroundColor(iconColor)
    }
    
    // Content
    VStack(alignment: .leading, spacing: 3) {
        Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
        Text(subtitle)
            .font(.system(size: 12, weight: .regular))
            .foregroundColor(Color.white.opacity(0.5))
    }
    
    Spacer()
    
    // Badge
    Text(type)
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(Color.white.opacity(0.45))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.05))
        .cornerRadius(5)
}
.padding(.horizontal, 20)
.padding(.vertical, 12)
.background(isHovered ? Color.white.opacity(0.04) : Color.clear)
.contentShape(Rectangle())
```

### Dividers
```swift
// Sheet dividers (ultra-subtle)
Divider()
    .background(Color.white.opacity(0.04))

// Main UI dividers (subtle)
Divider()
    .background(Color.white.opacity(0.06))
```

### Keyboard Shortcuts Display
```swift
Text("⌘")
    .font(.system(size: 13, design: .monospaced))
    .foregroundColor(Color.white.opacity(0.75))
    .padding(.horizontal, 9)
    .padding(.vertical, 5)
    .background(Color(hex: "#252525"))
    .cornerRadius(5)
```

---

## 🎬 Animation Standards

### Timing
```swift
// Micro interactions
.easeOut(duration: 0.12)  // Quick hover states

// Standard interactions
.easeOut(duration: 0.15)  // Focus states, most animations

// Deliberate actions
.easeOut(duration: 0.2)   // Tab switches, major state changes
```

### Common Patterns
```swift
// Hover state
.onHover { hovering in
    withAnimation(.easeOut(duration: 0.12)) {
        isHovered = hovering
    }
}

// Focus state
onEditingChanged: { editing in
    withAnimation(.easeOut(duration: 0.15)) {
        isFocused = editing
    }
}

// Tab/filter change
withAnimation(.easeOut(duration: 0.2)) {
    selectedTab = newTab
}
```

---

## 📐 Layout Specifications

### Form Sheets (Add/Edit)
```swift
VStack(spacing: 0) {
    // Header
    HStack {
        // Back button (28x28)
        // Learn More link
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 12)
    
    Divider().background(Color.white.opacity(0.04))
    
    // Content
    ScrollView {
        VStack(spacing: 24) {
            // Fields
        }
        .padding(.horizontal, 50)
        .padding(.top, 32)
    }
    
    Spacer()
    
    Divider().background(Color.white.opacity(0.04))
    
    // Footer
    HStack {
        // Icon + title
        Spacer()
        // Action button
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 12)
}
.frame(width: 700, height: 420)  // Custom links
.background(Color(hex: "#161616"))
```

### Settings Window
```swift
VStack(spacing: 0) {
    // Title bar with tabs
    VStack(spacing: 0) {
        Spacer().frame(height: 32)  // Traffic lights
        // Centered tabs
        .padding(.bottom, 20)
    }
    
    // Content
    // Tab content here
}
.frame(minWidth: 800, minHeight: 600)
.background(Color(hex: "#1a1a1a").opacity(0.95))
```

---

## 🎨 Icon Specifications

### System Icons
- Use **SF Symbols** exclusively
- Default weight: `.medium`
- Adjust size per context (see component specs)

### Icon Sizes
```swift
10px  // Micro icons
12px  // Small icons (in pills)
13px  // Standard icons (buttons, list items)
14px  // Medium icons
15px  // Larger icons
17px  // List item icons
18px  // Tab icons
```

### Icon Containers
```swift
// Standard icon container (list items)
.frame(width: 36, height: 36)
.background(iconColor.opacity(0.12))
.cornerRadius(8)

// Small icon container (buttons)
.frame(width: 28, height: 28)
.background(Color.white.opacity(0.05))
.cornerRadius(5)

// Tiny icon container
.frame(width: 26, height: 26)
.background(Color.white.opacity(0.06))
.cornerRadius(5)
```

---

## ✅ Validation & Error States

### Field Validation
```swift
// Track validation state
@State private var hasAttemptedSave: Bool = false

// Apply error border
.overlay(
    RoundedRectangle(cornerRadius: 5)
        .stroke(
            isFocused ? Color.white.opacity(0.8) :
            (hasAttemptedSave && value.isEmpty ? Color.red.opacity(0.5) : 
             Color.white.opacity(0.08)),
            lineWidth: isFocused ? 1.5 : 0.5
        )
)

// Set validation flag on save attempt
Button("Save") {
    hasAttemptedSave = true
    if isValid {
        save()
    }
}
```

### Error Messages
```swift
// Inline error (below field)
if hasError {
    Text(errorMessage)
        .font(.system(size: 11))
        .foregroundColor(.red.opacity(0.8))
        .padding(.top, 4)
}
```

---

## 🎯 Hover States

### Standard Hover Pattern
```swift
@State private var isHovered = false

SomeView()
    .background(isHovered ? Color.white.opacity(0.04) : Color.clear)
    .onHover { hovering in
        withAnimation(.easeOut(duration: 0.12)) {
            isHovered = hovering
        }
    }
```

### Hover Opacity Levels
```swift
// Buttons/Pills
inactive: Color.white.opacity(0.03)
hover:    Color.white.opacity(0.06)

// List items
normal: Color.clear
hover:  Color.white.opacity(0.04)

// Interactive elements
normal: Color.white.opacity(0.05)
hover:  Color.white.opacity(0.08)
```

---

## 🔧 Common Patterns

### Form Field Row
```swift
HStack(alignment: .center, spacing: 16) {
    Text("Label")
        .font(.system(size: 13, weight: .regular))
        .foregroundColor(Color.white.opacity(0.5))
        .frame(width: 90, alignment: .trailing)
    
    // Input field here
}
```

### Helper Text
```swift
HStack {
    Spacer().frame(width: 106)  // Align with field
    Text("Helper text here")
        .font(.system(size: 11))
        .foregroundColor(Color.white.opacity(0.35))
        .fixedSize(horizontal: false, vertical: true)
}
```

### Action Bar (Bottom)
```swift
HStack {
    HStack(spacing: 8) {
        Image(systemName: icon)
            .font(.system(size: 13, weight: .medium))
        Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Color.white.opacity(0.7))
    }
    
    Spacer()
    
    Button(action: save) {
        HStack(spacing: 6) {
            Text("Save")
            Text("⌘↵")
                .font(.system(size: 10, weight: .medium))
                .opacity(0.5)
        }
        // ... button styling
    }
}
.padding(.horizontal, 24)
.padding(.vertical, 12)
```

---

## 📱 Responsive Behavior

### Window Sizes
```swift
// Settings window
.frame(minWidth: 800, minHeight: 600)

// Form sheets
.frame(width: 700, height: 420)  // Custom links
.frame(width: 700, height: 380)  // Search engines

// Popovers
.frame(width: 200)  // Add source popover
```

### ScrollView Usage
- Use `ScrollView` for content that might overflow
- Don't add unnecessary scrolling
- Ensure proper padding inside scroll views

---

## 🚫 Common Mistakes to Avoid

### ❌ DON'T
1. Use hard-coded colors - use the color system
2. Use arbitrary spacing - stick to the 4px grid
3. Use default SwiftUI styles - always customize
4. Forget animations - every interaction should animate
5. Use thick borders - keep them subtle (0.5-1.5px)
6. Use bright backgrounds - keep it dark
7. Forget hover states - everything interactive should respond
8. Use large corner radii - keep them tight (5-8px)
9. Skip validation states - always show errors clearly
10. Use inconsistent font sizes - stick to 11-13px for most UI

### ✅ DO
1. Match Raycast exactly when in doubt
2. Use opacity for all color variations
3. Animate state changes (120-200ms)
4. Test focus states on all inputs
5. Ensure proper keyboard navigation
6. Add `.contentShape(Rectangle())` for clickable areas
7. Use `.buttonStyle(.plain)` for custom buttons
8. Keep spacing tight and consistent
9. Use medium weight for most text
10. Test in dark mode (it's the only mode)

---

## 🎓 Implementation Checklist

When implementing a new UI component:

- [ ] Colors match the color system
- [ ] Spacing follows the 4px grid
- [ ] Typography uses standard sizes (11-13px)
- [ ] Font weights are appropriate (.medium for emphasis)
- [ ] Hover states are implemented with animation
- [ ] Focus states are visible (0.8 opacity border)
- [ ] Validation states show errors clearly
- [ ] Borders are subtle (0.5-1.5px, low opacity)
- [ ] Corner radii are tight (5-8px)
- [ ] Background is dark (#161616, #1a1a1a, #1e1e1e)
- [ ] Icons are SF Symbols with correct size/weight
- [ ] Animations use .easeOut (120-200ms)
- [ ] Padding matches component specifications
- [ ] Button states (enabled/disabled) are clear
- [ ] Keyboard shortcuts are displayed properly
- [ ] Component is responsive to window size
- [ ] Tested against Raycast for visual accuracy

---

## 📚 Reference Components

### Perfect Examples to Study
1. `SourceListItem` - Perfect list item implementation
2. `FilterPill` - Perfect pill/button implementation
3. `AddEditCustomLinkSheet` - Perfect form sheet implementation
4. `AddSourcePopover` - Perfect popover implementation
5. `TabButton` - Perfect tab implementation

### Files to Reference
- `/Sources/Tachyon/UI/Settings/SourcesSettingsView.swift`
- `/Sources/Tachyon/UI/Settings/AddEditCustomLinkSheet.swift`
- `/Sources/Tachyon/UI/Settings/AddEditSearchEngineSheet.swift`
- `/Sources/Tachyon/UI/Settings/SettingsView.swift`

---

## 🎯 Final Note

**When in doubt, make it darker, tighter, and more subtle.**

The difference between good and great UI is in the micro-details:
- 0.04 vs 0.06 opacity
- 12px vs 13px font size
- 5px vs 6px corner radius
- 0.5px vs 1px border width

These tiny differences compound to create a premium feel. Never approximate - be exact.

---

*Last Updated: 2025-12-23*
*Version: 2.0*
*Maintained by: Tachyon Development Team*

---

## 🎯 Summary: The Three Pillars

When developing for Tachyon, remember these three non-negotiable pillars:

### 1. 🎨 Design Excellence
- Clone Raycast's aesthetic exactly
- Every pixel matters
- Dark, tight, subtle, smooth

### 2. 🧪 Test-Driven Development
- Write tests FIRST, always
- Minimum 80% coverage
- Tests are the specification

### 3. 📖 Comprehensive Documentation
- Document for end users, not developers
- Rich examples (5-10 per feature)
- Update docs WITH code changes

**A feature is not complete until it has:**
- ✅ Pixel-perfect UI matching Raycast
- ✅ Comprehensive test suite (80%+ coverage)
- ✅ Complete user documentation with examples

No exceptions. No shortcuts. This is what makes Tachyon exceptional.
