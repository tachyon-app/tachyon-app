import Foundation

/// Currency conversion service using Frankfurter API
public class CurrencyService {
    
    private var rateCache: [String: CachedRate] = [:]
    private let cacheExpiryInterval: TimeInterval = 3600 // 1 hour
    
    // Frankfurter API only supports these 31 major currencies
    // See: https://api.frankfurter.app/currencies
    private let supportedCurrencies: Set<String> = [
        "AUD", "BGN", "BRL", "CAD", "CHF", "CNY", "CZK", "DKK", "EUR", "GBP",
        "HKD", "HUF", "IDR", "ILS", "INR", "ISK", "JPY", "KRW", "MXN", "MYR",
        "NOK", "NZD", "PHP", "PLN", "RON", "SEK", "SGD", "THB", "TRY", "USD", "ZAR"
    ]
    
    public init() {}
    
    /// Convert currency (e.g., "$100 to eur", "100 USD in EUR")
    public func convert(_ input: String) async -> CalculationResult? {
        guard let parsed = parseInput(input) else {
            return nil
        }
        
        // Validate currencies are supported
        guard supportedCurrencies.contains(parsed.fromCurrency) else {
            print("❌ Currency \(parsed.fromCurrency) not supported by Frankfurter")
            return createUnsupportedCurrencyResult(input, currency: parsed.fromCurrency)
        }
        
        guard supportedCurrencies.contains(parsed.toCurrency) else {
            print("❌ Currency \(parsed.toCurrency) not supported by Frankfurter")
            return createUnsupportedCurrencyResult(input, currency: parsed.toCurrency)
        }
        
        // Fetch rates
        guard let rate = await fetchRate(from: parsed.fromCurrency, to: parsed.toCurrency) else {
            return nil
        }
        
        let convertedAmount = parsed.amount * rate.exchangeRate
        
        // Format with currency symbol
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = parsed.toCurrency
        formatter.maximumFractionDigits = 2
        let formattedResult = formatter.string(from: NSNumber(value: convertedAmount)) ?? "\(convertedAmount)"
        
        return CalculationResult(
            expression: input,
            result: convertedAmount,
            formattedResult: formattedResult,
            inputLabel: currencyLabel(parsed.fromCurrency),
            outputLabel: currencyLabel(parsed.toCurrency),
            type: .currency,
            fromCurrency: parsed.fromCurrency,
            toCurrency: parsed.toCurrency,
            amount: parsed.amount,
            lastUpdated: rate.timestamp
        )
    }
    
    /// Clear all cached rates
    public func clearCache() {
        rateCache.removeAll()
    }
    
    /// Create an error result for unsupported currencies
    private func createUnsupportedCurrencyResult(_ input: String, currency: String) -> CalculationResult? {
        return CalculationResult(
            expression: input,
            result: 0,
            formattedResult: "Currency not supported",
            inputLabel: "\(currency) is not currently supported",
            outputLabel: "We're working on adding more currencies",
            type: .currency
        )
    }
    
    // MARK: - Parsing
    
    private struct ParsedCurrency {
        let amount: Double
        let fromCurrency: String
        let toCurrency: String
    }
    
    private func parseInput(_ input: String) -> ParsedCurrency? {
        // Pattern 1: Symbol + amount + to/in + currency code ($100 to eur)
        if let result = parseSymbolPattern(input) {
            return result
        }
        
        // Pattern 2: Amount + currency code + to/in + currency code (100 USD to EUR)
        if let result = parseCodePattern(input) {
            return result
        }
        
        return nil
    }
    
    private func parseSymbolPattern(_ input: String) -> ParsedCurrency? {
        // Pattern: $100 to eur, €50 in usd
        let pattern = #"([\\$€£¥])([\d.]+)\s+(to|in)\s+([a-zA-Z]{3})"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) else {
            return nil
        }
        
        guard let symbolRange = Range(match.range(at: 1), in: input),
              let amountRange = Range(match.range(at: 2), in: input),
              let toCodeRange = Range(match.range(at: 4), in: input),
              let amount = Double(input[amountRange]) else {
            return nil
        }
        
        let symbol = String(input[symbolRange])
        let toCurrency = String(input[toCodeRange]).uppercased()
        
        guard let fromCurrency = currencyFromSymbol(symbol) else {
            return nil
        }
        
        return ParsedCurrency(amount: amount, fromCurrency: fromCurrency, toCurrency: toCurrency)
    }
    
    private func parseCodePattern(_ input: String) -> ParsedCurrency? {
        // Pattern: 100 USD to EUR, 50 GBP in JPY
        let pattern = #"([\d.]+)\s+([a-zA-Z]{3})\s+(to|in)\s+([a-zA-Z]{3})"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) else {
            return nil
        }
        
        guard let amountRange = Range(match.range(at: 1), in: input),
              let fromCodeRange = Range(match.range(at: 2), in: input),
              let toCodeRange = Range(match.range(at: 4), in: input),
              let amount = Double(input[amountRange]) else {
            return nil
        }
        
        let fromCurrency = String(input[fromCodeRange]).uppercased()
        let toCurrency = String(input[toCodeRange]).uppercased()
        
        return ParsedCurrency(amount: amount, fromCurrency: fromCurrency, toCurrency: toCurrency)
    }
    
    private func currencyFromSymbol(_ symbol: String) -> String? {
        switch symbol {
        case "$": return "USD"
        case "€": return "EUR"
        case "£": return "GBP"
        case "¥": return "JPY"
        default: return nil
        }
    }
    
    private func currencyLabel(_ code: String) -> String {
        switch code {
        case "USD": return "American Dollars"
        case "EUR": return "Euros"
        case "GBP": return "British Pounds"
        case "JPY": return "Japanese Yen"
        case "CAD": return "Canadian Dollars"
        case "AUD": return "Australian Dollars"
        case "CHF": return "Swiss Francs"
        case "CNY": return "Chinese Yuan"
        case "INR": return "Indian Rupees"
        default: return code
        }
    }
    
    // MARK: - Rate Fetching
    
    private struct CachedRate {
        let exchangeRate: Double
        let timestamp: Date
    }
    
    private func fetchRate(from: String, to: String) async -> CachedRate? {
        let cacheKey = "\(from)-\(to)"
        
        // Check cache
        if let cached = rateCache[cacheKey] {
            let age = Date().timeIntervalSince(cached.timestamp)
            if age < cacheExpiryInterval {
                return cached
            }
        }
        
        // Fetch from Frankfurter API
        // https://www.frankfurter.app/latest?from=USD&to=EUR
        let urlString = "https://api.frankfurter.app/latest?from=\(from)&to=\(to)"
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let rates = json["rates"] as? [String: Double],
               let rate = rates[to] {
                
                let cached = CachedRate(exchangeRate: rate, timestamp: Date())
                rateCache[cacheKey] = cached
                return cached
            }
        } catch {
            print("Error fetching currency rate: \(error)")
        }
        
        return nil
    }
}
