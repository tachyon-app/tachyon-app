import Foundation
import AppKit

/// Calculator Plugin that detects and evaluates calculations, unit conversions, and currency
public class CalculatorPlugin: Plugin {
    public var id: String { "calculator" }
    public var name: String { "Calculator" }
    
    private let calculator = CalculatorEngine()
    private let unitConverter = UnitConverter()
    private let currencyService = CurrencyService()
    
    // Cache for currency results
    private var currencyCache: [String: CalculationResult] = [:]
    private var pendingCurrencyQueries: Set<String> = []
    
    public init() {}
    
    public func search(query: String) -> [QueryResult] {
        var results: [QueryResult] = []
        
        // Check cached currency result first
        if let cachedCurrency = currencyCache[query] {
            results.append(createResult(from: cachedCurrency))
            return results  // Return currency result immediately
        }
        
        // Check if this looks like a currency query
        let looksCurrency = looksLikeCurrency(query)
        
        // Try math expression (only if not currency-like and no currency symbols)
        let hasCurrencySymbols = query.contains("$") || query.contains("€") || query.contains("£") || query.contains("¥")
        if !hasCurrencySymbols && !looksCurrency, let mathResult = calculator.evaluate(query) {
            results.append(createResult(from: mathResult))
            return results
        }
        
        // Try unit conversion (only if not currency-like)
        if !looksCurrency, let unitResult = unitConverter.convert(query) {
            results.append(createResult(from: unitResult))
            return results
        }
        
        // Try currency conversion (async) if it looks like currency
        if looksCurrency && !pendingCurrencyQueries.contains(query) {
            pendingCurrencyQueries.insert(query)
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let currencyResult = await self.currencyService.convert(query) {
                    // Cache the result
                    self.currencyCache[query] = currencyResult
                    self.pendingCurrencyQueries.remove(query)
                    
                    // Trigger refresh
                    NotificationCenter.default.post(
                        name: NSNotification.Name("RefreshSearchResults"),
                        object: nil
                    )
                } else {
                    self.pendingCurrencyQueries.remove(query)
                }
            }
        }
        
        return results
    }
    
    /// Check if query looks like a currency conversion pattern
    private func looksLikeCurrency(_ query: String) -> Bool {
        // Symbol pattern: $100 to eur, €50 in usd
        let symbolPattern = #"[\$€£¥][\d.]+\s+(to|in)\s+[a-zA-Z]{3}"#
        if let _ = query.range(of: symbolPattern, options: .regularExpression) {
            return true
        }
        
        // Code pattern: 100 USD to EUR, 50 ARS to USD
        let codePattern = #"[\d.]+\s+[a-zA-Z]{3}\s+(to|in)\s+[a-zA-Z]{3}"#
        if let _ = query.range(of: codePattern, options: .regularExpression) {
            return true
        }
        
        return false
    }
    
    private func createResult(from calculation: CalculationResult) -> QueryResult {
        // Build subtitle with exchange rate info for currency
        var subtitle = "\(calculation.expression) = \(calculation.formattedResult)"
        
        if calculation.type == .currency,
           let from = calculation.fromCurrency,
           let to = calculation.toCurrency,
           let amount = calculation.amount {
            // Calculate the rate
            let rate = calculation.result / amount
            let rateFormatted = String(format: "%.4f", rate)
            
            // Add exchange rate info on same line
            subtitle += " • 1 \(from) = \(rateFormatted) \(to)"
            
            // Add timestamp if available
            if let timeAgo = calculation.timeAgoString {
                subtitle += " • \(timeAgo)"
            }
        }
        
        return QueryResult(
            id: UUID(),
            title: "Calculator",
            subtitle: subtitle,
            icon: "function",
            alwaysShow: true,
            hideWindowAfterExecution: true,
            action: {
                // Copy result to clipboard
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(calculation.formattedResult, forType: .string)
                
                // Show success notification
                NotificationCenter.default.post(
                    name: NSNotification.Name("UpdateStatusBar"),
                    object: ("✅", "Copied \(calculation.formattedResult) to clipboard")
                )
            }
        )
    }
}
