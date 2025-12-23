import Foundation

/// Calculates time difference between two dates: "dec 25 - today"
class DateDifferencePattern: DatePattern {
    
    // Pattern: anything - anything
    private let pattern = #"^(.+?)\s*-\s*(.+)$"#
    
    // Helper parsers
    private let relative = RelativeDatePattern()
    private let nlp = DateParserHelper.shared
    
    func parse(_ input: String) -> DateResult? {
        // Regex to split on hyphen
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) else {
            return nil
        }
        
        guard let firstRange = Range(match.range(at: 1), in: input),
              let secondRange = Range(match.range(at: 2), in: input) else {
            return nil
        }
        
        // Exclude simple number subtractions (e.g. 10 - 5)
        // If both sides are just numbers, ignore (let calculator handle it)
        let firstStr = String(input[firstRange]).trimmingCharacters(in: .whitespaces)
        let secondStr = String(input[secondRange]).trimmingCharacters(in: .whitespaces)
        
        if Int(firstStr) != nil && Int(secondStr) != nil {
            return nil
        }
        
        // Resolve both dates
        guard let date1 = resolveDate(firstStr),
              let date2 = resolveDate(secondStr) else {
            return nil
        }
        
        // We return the TARGET date (date1) but with a special relative description
        // logic: date1 - date2 means "date1 relative to date2"
        // Actually, usually users want the duration.
        // We'll return date1 as the result date, so "primarySubtitle" will show formatted date
        // But we'll force the relative description to be based on the difference.
        
        return DateResult(date: date1, type: .dateDifference, expression: input)
    }
    
    private func resolveDate(_ input: String) -> Date? {
        // Try relative first (today, tomorrow)
        if let res = relative.parse(input) {
            return res.date
        }
        
        // Try exact keyword "now"
        if input.lowercased() == "now" {
            return Date()
        }
        
        // Try smart NLP detection (Dec 25, 2024-01-01)
        return nlp.parse(input)
    }
}
