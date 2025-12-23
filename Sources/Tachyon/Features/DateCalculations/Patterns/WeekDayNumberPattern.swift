import Foundation

/// Handles week numbers and day numbers (epochconverter features)
class WeekDayNumberPattern: DatePattern {
    
    func parse(_ input: String) -> DateResult? {
        let lower = input.lowercased()
        
        // Week number queries
        if lower.contains("week number") || 
           lower == "current week" || 
           lower == "what week is it" ||
           lower == "week no" {
            return DateResult(date: Date(), type: .weekDayInfo, expression: input)
        }
        
        // Day number queries
        if lower.contains("day number") || 
           lower == "day of year" ||
           lower == "current day number" ||
           lower == "what day is it" {
            return DateResult(date: Date(), type: .weekDayInfo, expression: input)
        }
        
        return nil
    }
}
