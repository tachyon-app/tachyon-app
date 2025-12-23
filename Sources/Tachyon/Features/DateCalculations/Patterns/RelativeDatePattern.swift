import Foundation

/// Parses natural language relative dates
class RelativeDatePattern: DatePattern {
    
    private let calendar = Calendar.current
    
    // Direct keyword lookups where time isn't specified (defaults to noon or current time)
    private let keywords: [String: (Calendar, Date) -> Date?] = [
        "now": { _, now in now },
        "today": { _, now in now }, // Will format as date
        "tomorrow": { cal, now in cal.date(byAdding: .day, value: 1, to: now) },
        "yesterday": { cal, now in cal.date(byAdding: .day, value: -1, to: now) },
    ]
    
    func parse(_ input: String) -> DateResult? {
        let text = input.lowercased()
        let now = Date()
        
        // 1. Check exact keywords
        if let directAction = keywords[text],
           let date = directAction(calendar, now) {
            return DateResult(date: date, type: .naturalLanguage, expression: input)
        }
        
        // 2. Check "next [weekday]"
        if let nextDate = parseNextWeekday(text, from: now) {
            return DateResult(date: nextDate, type: .naturalLanguage, expression: input)
        }
        
        // 3. Check "last [weekday]"
        if let lastDate = parseLastWeekday(text, from: now) {
            return DateResult(date: lastDate, type: .naturalLanguage, expression: input)
        }
        
        // 4. Check "[weekday] in X [unit]" (e.g., "monday in 3 weeks")
        if let complexDate = parseWeekdayInFuture(text, from: now) {
            return DateResult(date: complexDate, type: .naturalLanguage, expression: input)
        }
        
        // 5. Check "in X [unit]"
        if let futureDate = parseRelativeFuture(text, from: now) {
            return DateResult(date: futureDate, type: .naturalLanguage, expression: input)
        }
        
        // 6. Check "X [unit] ago"
        if let pastDate = parseRelativePast(text, from: now) {
            return DateResult(date: pastDate, type: .naturalLanguage, expression: input)
        }
        
        // 7. Check standalone weekday names (e.g., "monday", "friday")
        if let weekdayDate = parseStandaloneWeekday(text, from: now) {
            return DateResult(date: weekdayDate, type: .naturalLanguage, expression: input)
        }
        
        return nil
    }
    
    private func parseStandaloneWeekday(_ input: String, from date: Date) -> Date? {
        // Check if input is just a weekday name
        guard let targetWeekday = getWeekdayIndex(from: input) else { return nil }
        
        // Find next occurrence of this weekday
        let currentWeekday = calendar.component(.weekday, from: date)
        var daysToAdd = targetWeekday - currentWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7
        }
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: date)
    }
    
    private func parseNextWeekday(_ input: String, from date: Date) -> Date? {
        guard input.hasPrefix("next ") else { return nil }
        
        let weekdayName = String(input.dropFirst(5)).trimmingCharacters(in: .whitespaces)
        guard let targetWeekday = getWeekdayIndex(from: weekdayName) else { return nil }
        
        // Find next occurrence
        let currentWeekday = calendar.component(.weekday, from: date)
        var daysToAdd = targetWeekday - currentWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7
        }
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: date)
    }
    
    private func parseLastWeekday(_ input: String, from date: Date) -> Date? {
        guard input.hasPrefix("last ") else { return nil }
        
        let weekdayName = String(input.dropFirst(5)).trimmingCharacters(in: .whitespaces)
        guard let targetWeekday = getWeekdayIndex(from: weekdayName) else { return nil }
        
        // Find last occurrence (go backwards)
        let currentWeekday = calendar.component(.weekday, from: date)
        var daysToSubtract = currentWeekday - targetWeekday
        if daysToSubtract <= 0 {
            daysToSubtract += 7
        }
        
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: date)
    }
    
    private func parseWeekdayInFuture(_ input: String, from date: Date) -> Date? {
        // Pattern: "[weekday] in X [unit]"
        // Example: "monday in 3 weeks", "friday in 2 months"
        
        // Try to match pattern using regex
        let pattern = #"^(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun)\s+in\s+(\d+)\s+(day|week|month|year)s?$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) else {
            return nil
        }
        
        guard let weekdayRange = Range(match.range(at: 1), in: input),
              let amountRange = Range(match.range(at: 2), in: input),
              let unitRange = Range(match.range(at: 3), in: input) else {
            return nil
        }
        
        let weekdayName = String(input[weekdayRange])
        guard let amount = Int(input[amountRange]) else { return nil }
        let unitString = String(input[unitRange])
        
        // First, advance by the time unit
        guard let futureDate = addTime(amount, unit: unitString, to: date) else { return nil }
        
        // Then, find the target weekday in that future time period
        guard let targetWeekday = getWeekdayIndex(from: weekdayName.lowercased()) else { return nil }
        
        let futureWeekday = calendar.component(.weekday, from: futureDate)
        var daysToAdd = targetWeekday - futureWeekday
        if daysToAdd < 0 {
            daysToAdd += 7
        }
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: futureDate)
    }
    
    private func parseRelativeFuture(_ input: String, from date: Date) -> Date? {
        // "in 2 days", "in 1 week"
        let components = input.components(separatedBy: .whitespaces)
        guard components.count >= 3, components[0] == "in" else { return nil }
        
        guard let amount = Int(components[1]) else { return nil }
        let unitString = components[2] // days, weeks, etc
        
        return addTime(amount, unit: unitString, to: date)
    }
    
    private func parseRelativePast(_ input: String, from date: Date) -> Date? {
        // "2 days ago", "1 week ago"
        let components = input.components(separatedBy: .whitespaces)
        guard components.count >= 3, components.last == "ago" else { return nil }
        
        guard let amount = Int(components[0]) else { return nil }
        let unitString = components[1]
        
        return addTime(-amount, unit: unitString, to: date)
    }
    
    private func addTime(_ amount: Int, unit: String, to date: Date) -> Date? {
        var component: Calendar.Component?
        
        if unit.hasPrefix("second") { component = .second }
        else if unit.hasPrefix("minute") { component = .minute }
        else if unit.hasPrefix("hour") { component = .hour }
        else if unit.hasPrefix("day") { component = .day }
        else if unit.hasPrefix("week") { component = .day; return calendar.date(byAdding: .day, value: amount * 7, to: date) }
        else if unit.hasPrefix("month") { component = .month }
        else if unit.hasPrefix("year") { component = .year }
        
        guard let comp = component else { return nil }
        return calendar.date(byAdding: comp, value: amount, to: date)
    }
    
    private func getWeekdayIndex(from name: String) -> Int? {
        let weekdays = [
            "sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4,
            "thursday": 5, "friday": 6, "saturday": 7
        ]
        
        // Handle abbreviations
        if name.count == 3 {
             let fullNames = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
             if let idx = fullNames.firstIndex(of: name) {
                 return idx + 1
             }
        }
        
        return weekdays[name]
    }
}
