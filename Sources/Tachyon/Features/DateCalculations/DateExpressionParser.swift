import Foundation

/// Protocol for parsing date patterns
protocol DatePattern {
    func parse(_ input: String) -> DateResult?
}

/// Helper for standard date patterns
class DatePatterns {
    static let unixTimestamp = UnixTimestampPattern()
    static let relativeDate = RelativeDatePattern()
    static let arithmetic = DateArithmeticPattern()
    static let difference = DateDifferencePattern()
    static let weekDay = WeekDayNumberPattern()
    static let timezone = TimezonePattern()
    static let durationUntil = DurationUntilPattern()
    
    static var all: [DatePattern] {
        return [
            unixTimestamp,
            durationUntil,  // Check this early for "days until" queries
            relativeDate,
            arithmetic,
            difference,
            weekDay,
            timezone
        ]
    }
}

/// Main parser class
class DateExpressionParser {
    
    func parse(_ input: String) -> DateResult? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        for pattern in DatePatterns.all {
            if let result = pattern.parse(trimmed) {
                return result
            }
        }
        
        return nil
    }
}
