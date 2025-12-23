import Foundation

/// Handles date arithmetic: "today + 3 days", "now - 2 hours"
class DateArithmeticPattern: DatePattern {
    
    private let calendar = Calendar.current
    private let relativeParser = RelativeDatePattern() // Helper to parse base dates
    
    // Pattern: capture everything until +/- then number then unit
    // (.+?)\s*([+-])\s*(\d+)\s*(second|minute|hour|day|week|month|year)s?
    
    func parse(_ input: String) -> DateResult? {
        // Regex to separate base date from arithmetic operation
        let pattern = #"^(.+?)\s*([+-])\s*(\d+)\s*(second|minute|hour|day|week|month|year)s?$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) else {
            return nil
        }
        
        // Extract components
        guard let baseRange = Range(match.range(at: 1), in: input),
              let opRange = Range(match.range(at: 2), in: input),
              let amountRange = Range(match.range(at: 3), in: input),
              let unitRange = Range(match.range(at: 4), in: input) else {
            return nil
        }
        
        let baseString = String(input[baseRange]).trimmingCharacters(in: .whitespaces)
        let operation = String(input[opRange])
        guard let amount = Int(input[amountRange]) else { return nil }
        let unitString = String(input[unitRange])
        
        // Resolve base date
        // Note: For now we support relative dates as base. 
        // We could expand this to support other patterns if needed.
        let baseDate: Date
        if let relativeResult = relativeParser.parse(baseString) {
            baseDate = relativeResult.date
        } else if baseString.lowercased() == "now" {
            baseDate = Date()
        } else {
            return nil
        }
        
        // Apply arithmetic
        let multiplier = (operation == "-") ? -1 : 1
        
        if let resultDate = addTime(amount * multiplier, unit: unitString, to: baseDate) {
            return DateResult(date: resultDate, type: .dateArithmetic, expression: input)
        }
        
        return nil
    }
    
    private func addTime(_ amount: Int, unit: String, to date: Date) -> Date? {
        let unitLower = unit.lowercased()
        var component: Calendar.Component?
        
        if unitLower.hasPrefix("second") { component = .second }
        else if unitLower.hasPrefix("minute") { component = .minute }
        else if unitLower.hasPrefix("hour") { component = .hour }
        else if unitLower.hasPrefix("day") { component = .day }
        else if unitLower.hasPrefix("week") { component = .day; return calendar.date(byAdding: .day, value: amount * 7, to: date) }
        else if unitLower.hasPrefix("month") { component = .month }
        else if unitLower.hasPrefix("year") { component = .year }
        
        guard let comp = component else { return nil }
        return calendar.date(byAdding: comp, value: amount, to: date)
    }
}
