import Foundation

/// Handles timezone queries: "time in Tokyo", "nyc time"
class TimezonePattern: DatePattern {
    
    // Pattern: (time in|current time|time) [city]
    // Or simpler: just look for known city names in the string if "time" is present
    
    private let data = TimezoneData.shared
    
    func parse(_ input: String) -> DateResult? {
        let lower = input.lowercased()
        
        // 1. Check for timezone conversion: "[time] [city1] in [city2]"
        // Example: "5pm london in tokyo", "3pm nyc in paris"
        if let conversionResult = parseTimezoneConversion(lower, originalInput: input) {
            return conversionResult
        }
        
        // 2. Check for "time in [city]"
        if lower.hasPrefix("time in ") {
            let city = String(lower.dropFirst(8)).trimmingCharacters(in: .whitespaces)
            if let tz = data.getTimeZone(for: city) {
                return DateResult(date: Date(), type: .timezone, expression: input, timeZone: tz)
            }
        }
        
        // 3. Check for "current time [city]"
        if lower.hasPrefix("current time ") {
            let city = String(lower.dropFirst(13)).trimmingCharacters(in: .whitespaces)
             if let tz = data.getTimeZone(for: city) {
                return DateResult(date: Date(), type: .timezone, expression: input, timeZone: tz)
            }
        }
        
        // 4. Check for specific city shortcuts if "time" is mentioned
        // e.g. "nyc time", "tokyo time"
        if lower.hasSuffix(" time") {
            let city = String(lower.dropLast(5)).trimmingCharacters(in: .whitespaces)
            if let tz = data.getTimeZone(for: city) {
                return DateResult(date: Date(), type: .timezone, expression: input, timeZone: tz)
            }
        }
        
        return nil
    }
    
    private func parseTimezoneConversion(_ input: String, originalInput: String) -> DateResult? {
        // Pattern: [time] [city1] in [city2]
        // We need to find " in " and split around it
        
        guard let inRange = input.range(of: " in ") else { return nil }
        
        let beforeIn = String(input[..<inRange.lowerBound]).trimmingCharacters(in: .whitespaces)
        let afterIn = String(input[inRange.upperBound...]).trimmingCharacters(in: .whitespaces)
        
        // afterIn should be a city
        guard let targetTz = data.getTimeZone(for: afterIn) else { return nil }
        
        // beforeIn should be "[time] [city]"
        // Try to parse it
        let components = beforeIn.components(separatedBy: .whitespaces)
        guard components.count >= 2 else { return nil }
        
        // Last component should be the source city
        let sourceCity = components.last!
        guard let sourceTz = data.getTimeZone(for: sourceCity) else { return nil }
        
        // Everything before the last component is the time
        let timeString = components.dropLast().joined(separator: " ")
        
        // Parse the time (e.g., "5pm", "3:30pm", "14:00")
        guard let timeComponents = parseTime(timeString) else { return nil }
        
        // Create a date in the source timezone
        var calendar = Calendar.current
        calendar.timeZone = sourceTz
        
        let now = Date()
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.timeZone = sourceTz
        
        guard let sourceDate = calendar.date(from: dateComponents) else { return nil }
        
        // Return the date with the target timezone
        return DateResult(date: sourceDate, type: .timezone, expression: originalInput, timeZone: targetTz)
    }
    
    private func parseTime(_ input: String) -> (hour: Int, minute: Int)? {
        let lower = input.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Check for am/pm
        let isPM = lower.hasSuffix("pm")
        let isAM = lower.hasSuffix("am")
        
        // Remove am/pm
        var timeStr = lower
        if isPM || isAM {
            timeStr = String(timeStr.dropLast(2)).trimmingCharacters(in: .whitespaces)
        }
        
        // Split by colon if present
        let parts = timeStr.components(separatedBy: ":")
        
        var hour: Int
        var minute = 0
        
        if parts.count == 1 {
            // Just hour (e.g., "5", "14")
            guard let h = Int(parts[0]) else { return nil }
            hour = h
        } else if parts.count == 2 {
            // Hour and minute (e.g., "5:30", "14:45")
            guard let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
            hour = h
            minute = m
        } else {
            return nil
        }
        
        // Apply AM/PM
        if isPM && hour < 12 {
            hour += 12
        } else if isAM && hour == 12 {
            hour = 0
        }
        
        // Validate
        guard hour >= 0 && hour < 24 && minute >= 0 && minute < 60 else { return nil }
        
        return (hour, minute)
    }
}
