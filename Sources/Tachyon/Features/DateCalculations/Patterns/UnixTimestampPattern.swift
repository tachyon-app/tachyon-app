import Foundation

/// Parses Unix timestamps (seconds, milliseconds, microseconds)
class UnixTimestampPattern: DatePattern {
    
    func parse(_ input: String) -> DateResult? {
        let lower = input.lowercased()
        
        // 1. Check for explicit "now" keywords
        if lower == "now in unix" || 
           lower == "current epoch" || 
           lower == "unix timestamp" ||
           lower == "epoch" {
            return DateResult(date: Date(), type: .unixTimestamp, expression: input)
        }
        
        // 2. Check for numeric timestamp
        // Try to extract timestamp from text (e.g., "timestamp: 1703347200")
        let pattern = "\\b(\\d{10,16})\\b"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
           let range = Range(match.range, in: input) {
            let timestampStr = String(input[range])
            if let number = Int64(timestampStr), number > 0 {
                let digits = timestampStr.count
                
                // Seconds (10 digits only): 1973 - 2286
                if digits == 10 {
                    let date = Date(timeIntervalSince1970: TimeInterval(number))
                    return DateResult(date: date, type: .unixTimestamp, expression: input)
                }
                
                // Milliseconds (13 digits)
                if digits == 13 {
                    let date = Date(timeIntervalSince1970: TimeInterval(number) / 1000.0)
                    return DateResult(date: date, type: .unixTimestamp, expression: input)
                }
                
                // Microseconds (16 digits)
                if digits == 16 {
                    let date = Date(timeIntervalSince1970: TimeInterval(number) / 1_000_000.0)
                    return DateResult(date: date, type: .unixTimestamp, expression: input)
                }
            }
        }
        
        return nil
    }
}
