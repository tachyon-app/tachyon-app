import Foundation

/// Type of date calculation result
public enum DateResultType {
    case unixTimestamp      // 1703376600
    case naturalLanguage    // "tomorrow"
    case dateArithmetic     // "today + 3 days"
    case timezone           // "time in Tokyo"
    case dateDifference     // "dec 25 - today"
    case weekDayInfo        // "week number"
}

/// Helper struct to hold formats
public struct DateFormats {
    public let humanReadable: String
    public let iso8601: String
    public let rfc2822: String
    public let unixSeconds: Int64
    public let unixMilliseconds: Int64
    public let relative: String
}

/// Result of a date calculation
public struct DateResult {
    public let date: Date
    public let type: DateResultType
    public let expression: String
    public let timeZone: TimeZone
    
    // Cached formats
    public let formats: DateFormats
    
    public init(date: Date, type: DateResultType, expression: String, timeZone: TimeZone = .current) {
        self.date = date
        self.type = type
        self.expression = expression
        self.timeZone = timeZone
        self.formats = Self.generateFormats(for: date, timeZone: timeZone)
    }
    
    private static func generateFormats(for date: Date, timeZone: TimeZone) -> DateFormats {
        // Unix
        let seconds = Int64(date.timeIntervalSince1970)
        let millis = Int64(date.timeIntervalSince1970 * 1000)
        
        // ISO 8601
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = timeZone
        let iso = isoFormatter.string(from: date)
        
        // RFC 2822 (Common email/web format)
        let rfcFormatter = DateFormatter()
        rfcFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        rfcFormatter.locale = Locale(identifier: "en_US_POSIX")
        rfcFormatter.timeZone = timeZone
        let rfc = rfcFormatter.string(from: date)
        
        // Human Readable (Full date + time)
        let humanFormatter = DateFormatter()
        humanFormatter.dateStyle = .full
        humanFormatter.timeStyle = .medium
        humanFormatter.timeZone = timeZone
        let human = humanFormatter.string(from: date)
        
        // Relative - calculate exact days for precision
        let relative = calculateRelativeDescription(for: date)
        
        return DateFormats(
            humanReadable: human,
            iso8601: iso,
            rfc2822: rfc,
            unixSeconds: seconds,
            unixMilliseconds: millis,
            relative: relative
        )
    }
    
    private static func calculateRelativeDescription(for date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate the difference in days
        let components = calendar.dateComponents([.day, .hour], from: now, to: date)
        
        guard let days = components.day else {
            return "unknown"
        }
        
        if days == 0 {
            // Same day - show hours
            if let hours = components.hour {
                if hours == 0 {
                    return "now"
                } else if hours > 0 {
                    return "in \(hours) hour\(hours == 1 ? "" : "s")"
                } else {
                    return "\(-hours) hour\(hours == -1 ? "" : "s") ago"
                }
            }
            return "today"
        } else if days == 1 {
            return "in 1 day"
        } else if days == -1 {
            return "1 day ago"
        } else if days > 0 {
            return "in \(days) days"
        } else {
            return "\(-days) days ago"
        }
    }
    
    /// Get the primary subtitle to display in the UI
    public var primarySubtitle: String {
        switch type {
        case .unixTimestamp:
            return "Unix: \(formats.unixSeconds) • ISO: \(formats.iso8601)"
        case .naturalLanguage, .dateArithmetic:
            return "\(formats.relative) • \(formats.iso8601)"
        case .timezone:
            return "\(timeZone.identifier) • \(formats.iso8601)"
        case .dateDifference:
            return formats.relative
        case .weekDayInfo:
            let cal = Calendar.current
            let week = cal.component(.weekOfYear, from: date)
            let day = cal.ordinality(of: .day, in: .year, for: date) ?? 0
            return "Week \(week) • Day \(day) of 365"
        }
    }
}
