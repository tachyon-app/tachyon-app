import Foundation

/// Type of calculation performed
public enum CalculationType {
    case math
    case percentage
    case unitConversion
    case currency
}

/// Result from a calculation
public struct CalculationResult {
    public let expression: String
    public let result: Double
    public let formattedResult: String
    public let inputLabel: String
    public let outputLabel: String
    public let type: CalculationType
    
    // Currency-specific properties
    public let fromCurrency: String?
    public let toCurrency: String?
    public let amount: Double?
    public let lastUpdated: Date?
    
    // Unit conversion-specific properties
    public let inputUnit: String?
    public let outputUnit: String?
    
    public init(
        expression: String,
        result: Double,
        formattedResult: String? = nil,
        inputLabel: String = "",
        outputLabel: String = "",
        type: CalculationType,
        fromCurrency: String? = nil,
        toCurrency: String? = nil,
        amount: Double? = nil,
        lastUpdated: Date? = nil,
        inputUnit: String? = nil,
        outputUnit: String? = nil
    ) {
        self.expression = expression
        self.result = result
        self.formattedResult = formattedResult ?? Self.formatNumber(result)
        self.inputLabel = inputLabel
        self.outputLabel = outputLabel.isEmpty ? Self.numberToWords(result) : outputLabel
        self.type = type
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
        self.amount = amount
        self.lastUpdated = lastUpdated
        self.inputUnit = inputUnit
        self.outputUnit = outputUnit
    }
    
    /// Time ago string for currency rates
    public var timeAgoString: String? {
        guard let updated = lastUpdated else { return nil }
        
        let now = Date()
        let interval = now.timeIntervalSince(updated)
        
        if interval < 60 {
            return "Updated just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "Updated \(minutes) \(minutes == 1 ? "minute" : "minutes") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "Updated \(hours) \(hours == 1 ? "hour" : "hours") ago"
        } else {
            let days = Int(interval / 86400)
            return "Updated \(days) \(days == 1 ? "day" : "days") ago"
        }
    }
    
    /// Format a number with thousands separators and appropriate decimal places
    private static func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = number.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    /// Convert number to words (simple implementation for common numbers)
    private static func numberToWords(_ number: Double) -> String {
        let rounded = Int(number.rounded())
        
        let ones = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"]
        let teens = ["Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"]
        let tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"]
        
        if rounded == 0 { return "Zero" }
        if rounded < 10 { return ones[rounded] }
        if rounded < 20 { return teens[rounded - 10] }
        if rounded < 100 {
            let tensDigit = rounded / 10
            let onesDigit = rounded % 10
            return tens[tensDigit] + (onesDigit > 0 ? " " + ones[onesDigit] : "")
        }
        if rounded < 1000 {
            let hundreds = rounded / 100
            let remainder = rounded % 100
            var result = ones[hundreds] + " Hundred"
            if remainder > 0 {
                result += " " + numberToWords(Double(remainder))
            }
            return result
        }
        if rounded < 1_000_000 {
            let thousands = rounded / 1000
            let remainder = rounded % 1000
            var result = numberToWords(Double(thousands)) + " Thousand"
            if remainder > 0 {
                result += " " + numberToWords(Double(remainder))
            }
            return result
        }
        
        return formatNumber(number) // Fallback for very large numbers
    }
}
