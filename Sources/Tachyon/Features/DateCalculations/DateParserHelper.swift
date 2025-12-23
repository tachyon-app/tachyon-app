import Foundation

/// Helper to parse natural language dates using NSDataDetector
class DateParserHelper {
    static let shared = DateParserHelper()
    
    private let detector: NSDataDetector?
    
    private init() {
        // Checking for Date and Time
        self.detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
    }
    
    func parse(_ input: String) -> Date? {
        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        guard let matches = detector?.matches(in: input, options: [], range: range) else {
            return nil
        }
        
        // Return the first valid date found
        return matches.first?.date
    }
}
