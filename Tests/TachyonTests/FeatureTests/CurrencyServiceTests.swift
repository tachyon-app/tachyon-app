import XCTest
@testable import TachyonCore

/// Tests for the Currency Service (TDD approach)
final class CurrencyServiceTests: XCTestCase {
    
    var service: CurrencyService!
    
    override func setUp() {
        super.setUp()
        service = CurrencyService()
    }
    
    // MARK: - Pattern Detection Tests
    
    func testDetectsCurrencyConversion() {
        let expectation = XCTestExpectation(description: "Currency conversion detected")
        
        Task {
            let result = await service.convert("$100 to eur")
            XCTAssertNotNil(result)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testNonCurrencyReturnsNil() {
        let expectation = XCTestExpectation(description: "Non-currency returns nil")
        
        Task {
            let result = await service.convert("hello world")
            XCTAssertNil(result)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Currency Symbol Tests
    
    func testDollarSymbolConversion() async {
        let result = await service.convert("$100 to eur")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.fromCurrency, "USD")
        XCTAssertEqual(result?.toCurrency, "EUR")
        if let amount = result?.amount {
            XCTAssertEqual(amount, 100.0, accuracy: 0.01)
        }
    }
    
    func testEuroSymbolConversion() async {
        let result = await service.convert("€50 to usd")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.fromCurrency, "EUR")
        XCTAssertEqual(result?.toCurrency, "USD")
        if let amount = result?.amount {
            XCTAssertEqual(amount, 50.0, accuracy: 0.01)
        }
    }
    
    func testPoundSymbolConversion() async {
        let result = await service.convert("£200 to usd")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.fromCurrency, "GBP")
        XCTAssertEqual(result?.toCurrency, "USD")
    }
    
    func testYenSymbolConversion() async {
        let result = await service.convert("¥1000 to usd")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.fromCurrency, "JPY")
        XCTAssertEqual(result?.toCurrency, "USD")
    }
    
    // MARK: - Currency Code Tests
    
    func testCurrencyCodeConversion() async {
        let result = await service.convert("100 USD to EUR")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.fromCurrency, "USD")
        XCTAssertEqual(result?.toCurrency, "EUR")
        if let amount = result?.amount {
            XCTAssertEqual(amount, 100.0, accuracy: 0.01)
        }
    }
    
    func testCurrencyCodeWithIn() async {
        let result = await service.convert("100 USD in EUR")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.fromCurrency, "USD")
        XCTAssertEqual(result?.toCurrency, "EUR")
    }
    
    func testCaseInsensitiveCurrency() async {
        let result = await service.convert("100 usd to eur")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.fromCurrency, "USD")
        XCTAssertEqual(result?.toCurrency, "EUR")
    }
    
    // MARK: - Decimal Amount Tests
    
    func testDecimalAmount() async {
        let result = await service.convert("$99.99 to eur")
        XCTAssertNotNil(result)
        if let amount = result?.amount {
            XCTAssertEqual(amount, 99.99, accuracy: 0.01)
        }
    }
    
    // MARK: - Rate Fetching Tests
    
    func testFetchesRatesFromFrankfurter() async {
        let result = await service.convert("$100 to eur")
        XCTAssertNotNil(result)
        // Should have a valid conversion result
        XCTAssertGreaterThan(result!.result, 0, "Should fetch live rate and return positive result")
    }
    
    // MARK: - Caching Tests
    
    func testCachesRates() async {
        // First call should fetch from API
        let result1 = await service.convert("$100 to eur")
        XCTAssertNotNil(result1)
        
        // Second call should use cache
        let result2 = await service.convert("$100 to eur")
        XCTAssertNotNil(result2)
        
        // Results should be the same (from cache)
        if let r1 = result1?.result, let r2 = result2?.result {
            XCTAssertEqual(r1, r2, accuracy: 0.01)
        }
        XCTAssertEqual(result1?.lastUpdated, result2?.lastUpdated)
    }
    
    func testCacheExpiry() async {
        // This test would need to mock time or wait, skip for now
        // In real implementation, cache should expire after 1 hour
    }
    
    // MARK: - Timestamp Tests
    
    func testIncludesTimestamp() async {
        let result = await service.convert("$100 to eur")
        XCTAssertNotNil(result)
        XCTAssertNotNil(result?.lastUpdated)
        
        // Timestamp should be recent (within last minute)
        if let lastUpdated = result?.lastUpdated {
            let now = Date()
            let timeDiff = now.timeIntervalSince(lastUpdated)
            XCTAssertLessThan(timeDiff, 60, "Timestamp should be within last minute")
        }
    }
    
    func testFormatsTimeAgo() async {
        let result = await service.convert("$100 to eur")
        XCTAssertNotNil(result)
        
        let timeAgo = result?.timeAgoString
        XCTAssertNotNil(timeAgo)
        // For a just-fetched result, should say "just now" or similar
        XCTAssertTrue(timeAgo!.contains("now") || timeAgo!.contains("second"))
    }
    
    // MARK: - Label Tests
    
    func testCurrencyLabels() async {
        let result = await service.convert("$100 to eur")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.inputLabel, "American Dollars")
        XCTAssertEqual(result?.outputLabel, "Euros")
    }
    
    // MARK: - Type Property Tests
    
    func testResultType() async {
        let result = await service.convert("$100 to eur")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .currency)
    }
    
    // MARK: - Formatting Tests
    
    func testFormatsWithCurrencySymbol() async {
        let result = await service.convert("$100 to eur")
        XCTAssertNotNil(result)
        // Should include currency symbol in formatted result
        XCTAssertTrue(result!.formattedResult.contains("€"))
    }
    
    func testFormatsWithThousandsSeparator() async {
        let result = await service.convert("$10000 to eur")
        XCTAssertNotNil(result)
        // Should format large numbers with separator
        XCTAssertTrue(result!.formattedResult.contains(",") || result!.formattedResult.contains("."))
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidCurrencyCode() async {
        let _ = await service.convert("100 XXX to USD")
        // Should either return nil or handle gracefully
        // Depending on implementation, might want to show error
    }
    
    func testHandlesNetworkError() async {
        // This would need mock network layer
        // For now, just ensure it doesn't crash
        service.clearCache() // Force network call
        let _ = await service.convert("$100 to eur")
        // Should either return result or nil, but not crash
    }
    
    // MARK: - Supported Currencies Tests
    
    func testCommonCurrencies() async {
        let currencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF"]
        
        for currency in currencies {
            let result = await service.convert("100 USD to \(currency)")
            XCTAssertNotNil(result, "Should support \(currency)")
        }
    }
}
