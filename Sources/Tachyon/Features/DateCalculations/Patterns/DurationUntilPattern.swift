import Foundation

/// Handles "days until" / "time until" queries
class DurationUntilPattern: DatePattern {
    
    private let nlp = DateParserHelper.shared
    private let relative = RelativeDatePattern()
    
    func parse(_ input: String) -> DateResult? {
        let lower = input.lowercased()
        
        // Pattern: "days until [date]" or "time until [date]"
        if lower.hasPrefix("days until ") {
            let dateStr = String(lower.dropFirst(11)).trimmingCharacters(in: .whitespaces)
            return parseDuration(dateStr: dateStr, input: input)
        }
        
        if lower.hasPrefix("time until ") {
            let dateStr = String(lower.dropFirst(11)).trimmingCharacters(in: .whitespaces)
            return parseDuration(dateStr: dateStr, input: input)
        }
        
        // Pattern: "until [date]"
        if lower.hasPrefix("until ") {
            let dateStr = String(lower.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            return parseDuration(dateStr: dateStr, input: input)
        }
        
        return nil
    }
    
    private func parseDuration(dateStr: String, input: String) -> DateResult? {
        // Try to parse the target date
        var targetDate: Date?
        
        // Check for special dates/holidays first
        if let specialDate = parseSpecialDate(dateStr) {
            targetDate = specialDate
        }
        
        // Try relative date (e.g., "tomorrow")
        if targetDate == nil, let result = relative.parse(dateStr) {
            targetDate = result.date
        }
        
        // Try NLP detection (e.g., "march 15", "dec 25")
        if targetDate == nil {
            targetDate = nlp.parse(dateStr)
        }
        
        guard let target = targetDate else { return nil }
        
        // Return the target date with dateDifference type
        // The relative description will show "in X days"
        return DateResult(date: target, type: .dateDifference, expression: input)
    }
    
    private func parseSpecialDate(_ input: String) -> Date? {
        let lower = input.lowercased().trimmingCharacters(in: .whitespaces)
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        
        var components = DateComponents()
        components.timeZone = calendar.timeZone
        
        switch lower {
        case "christmas", "xmas":
            components.year = currentYear
            components.month = 12
            components.day = 25
            
        case "new year", "new years", "new year's":
            components.year = currentYear + 1
            components.month = 1
            components.day = 1
            
        case "halloween":
            components.year = currentYear
            components.month = 10
            components.day = 31
            
        case "valentine's day", "valentines day", "valentine's", "valentines":
            components.year = currentYear
            components.month = 2
            components.day = 14
            
        case "independence day", "4th of july", "july 4th":
            components.year = currentYear
            components.month = 7
            components.day = 4
            
        default:
            return nil
        }
        
        guard let date = calendar.date(from: components) else { return nil }
        
        // If the date has passed this year, use next year
        if date < now {
            components.year = currentYear + 1
            return calendar.date(from: components)
        }
        
        return date
    }
}
