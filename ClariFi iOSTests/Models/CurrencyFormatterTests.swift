//
//  CurrencyFormatterTests.swift
//  ClariFi iOSTests
//
//  Created by AI Assistant on 2025-10-10.
//
//  Tests for CurrencyFormatter caching and performance
//

import XCTest
@testable import ClariFi_iOS

final class CurrencyFormatterTests: XCTestCase {
    
    var formatter: CurrencyFormatter!
    
    override func setUp() {
        super.setUp()
        formatter = CurrencyFormatter.shared
    }
    
    override func tearDown() {
        formatter = nil
        super.tearDown()
    }
    
    // MARK: - Basic Formatting Tests
    
    func testBasicCurrencyFormatting() async {
        // Given
        let amount = Decimal(1234.56)
        let currency = Currency.usd
        
        // When
        let formatted = await formatter.format(amount, currency: currency)
        
        // Then
        XCTAssertTrue(formatted.contains("1,234.56"))
        XCTAssertTrue(formatted.contains("$"))
    }
    
    func testDifferentCurrencies() async {
        // Given
        let amount = Decimal(1000.00)
        
        // When/Then
        let usdFormatted = await formatter.format(amount, currency: .usd)
        let eurFormatted = await formatter.format(amount, currency: .eur)
        let gbpFormatted = await formatter.format(amount, currency: .gbp)
        
        XCTAssertTrue(usdFormatted.contains("$"))
        XCTAssertTrue(eurFormatted.contains("€"))
        XCTAssertTrue(gbpFormatted.contains("£"))
    }
    
    func testFormatWithSymbol() async {
        // Given
        let amount = Decimal(999.99)
        let currency = Currency.usd
        
        // When
        let formatted = await formatter.formatWithSymbol(amount, currency: currency)
        
        // Then
        XCTAssertEqual(formatted, "$999.99")
    }
    
    func testSynchronousFormatting() {
        // Given
        let amount = Decimal(500.00)
        let currency = Currency.usd
        
        // When
        let formatted = formatter.formatSync(amount, currency: currency)
        
        // Then
        XCTAssertTrue(formatted.contains("500"))
        XCTAssertTrue(formatted.contains("$"))
    }
    
    // MARK: - Cache Performance Tests
    
    func testFormatterCaching() async {
        // Given
        let amount = Decimal(100.00)
        let currency = Currency.usd
        
        // When - Format multiple times
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<100 {
            _ = await formatter.format(amount, currency: currency)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Then - Should be fast due to caching
        XCTAssertLessThan(duration, 1.0, "Cached formatting should be fast")
        
        // Verify cache has entries
        let cacheSize = await formatter.getCacheStats()
        XCTAssertGreaterThan(cacheSize, 0, "Cache should have entries")
    }
    
    func testCacheReuse() async {
        // Given
        let amount1 = Decimal(100.00)
        let amount2 = Decimal(200.00)
        let currency = Currency.usd
        
        // When - Format with same currency multiple times
        let formatted1 = await formatter.format(amount1, currency: currency)
        let formatted2 = await formatter.format(amount2, currency: currency)
        
        // Then - Cache should be reused
        let cacheSize = await formatter.getCacheStats()
        XCTAssertEqual(cacheSize, 1, "Cache should have only one formatter for USD")
        
        // Both should be properly formatted
        XCTAssertTrue(formatted1.contains("100"))
        XCTAssertTrue(formatted2.contains("200"))
    }
    
    func testMultipleCurrencyCaching() async {
        // Given
        let amount = Decimal(100.00)
        let currencies: [Currency] = [.usd, .eur, .gbp, .jpy, .cad]
        
        // When - Format with different currencies
        for currency in currencies {
            _ = await formatter.format(amount, currency: currency)
        }
        
        // Then - Cache should have formatters for all currencies
        let cacheSize = await formatter.getCacheStats()
        XCTAssertEqual(cacheSize, currencies.count, "Cache should have formatters for all currencies")
    }
    
    // MARK: - Cache Management Tests
    
    func testCacheClearing() async {
        // Given - Populate cache
        let amount = Decimal(100.00)
        _ = await formatter.format(amount, currency: .usd)
        _ = await formatter.format(amount, currency: .eur)
        
        // Verify cache is populated
        let initialCacheSize = await formatter.getCacheStats()
        XCTAssertGreaterThan(initialCacheSize, 0)
        
        // When - Clear cache
        formatter.clearCache()
        
        // Wait a moment for async clear to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then - Cache should be empty
        let finalCacheSize = await formatter.getCacheStats()
        XCTAssertEqual(finalCacheSize, 0, "Cache should be empty after clearing")
    }
    
    // MARK: - Parsing Tests
    
    func testCurrencyParsing() {
        // Given
        let currency = Currency.usd
        
        // When/Then
        XCTAssertEqual(formatter.parse("$1,234.56", currency: currency), Decimal(1234.56))
        XCTAssertEqual(formatter.parse("$100", currency: currency), Decimal(100))
        XCTAssertEqual(formatter.parse("$0.99", currency: currency), Decimal(0.99))
        XCTAssertNil(formatter.parse("invalid", currency: currency))
    }
    
    func testParsingWithDifferentFormats() {
        // Given
        let currency = Currency.usd
        
        // When/Then
        XCTAssertEqual(formatter.parse("1,234.56", currency: currency), Decimal(1234.56))
        XCTAssertEqual(formatter.parse("1234.56", currency: currency), Decimal(1234.56))
        XCTAssertEqual(formatter.parse("$1,234.56", currency: currency), Decimal(1234.56))
    }
    
    // MARK: - Edge Cases
    
    func testZeroAmount() async {
        // Given
        let amount = Decimal(0)
        let currency = Currency.usd
        
        // When
        let formatted = await formatter.format(amount, currency: currency)
        
        // Then
        XCTAssertTrue(formatted.contains("0"))
    }
    
    func testNegativeAmount() async {
        // Given
        let amount = Decimal(-100.50)
        let currency = Currency.usd
        
        // When
        let formatted = await formatter.format(amount, currency: currency)
        
        // Then
        XCTAssertTrue(formatted.contains("-"))
        XCTAssertTrue(formatted.contains("100.50"))
    }
    
    func testLargeAmount() async {
        // Given
        let amount = Decimal(999999.99)
        let currency = Currency.usd
        
        // When
        let formatted = await formatter.format(amount, currency: currency)
        
        // Then
        XCTAssertTrue(formatted.contains("999,999.99"))
    }
    
    // MARK: - Performance Benchmarks
    
    func testPerformanceComparison() async {
        // Given
        let amount = Decimal(1234.56)
        let currency = Currency.usd
        let iterations = 1000
        
        // Test cached performance
        let cachedStartTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = await formatter.format(amount, currency: currency)
        }
        let cachedDuration = CFAbsoluteTimeGetCurrent() - cachedStartTime
        
        // Test synchronous performance (no caching)
        let syncStartTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = formatter.formatSync(amount, currency: currency)
        }
        let syncDuration = CFAbsoluteTimeGetCurrent() - syncStartTime
        
        // Then - Cached should be faster
        print("Cached formatting: \(cachedDuration)s")
        print("Sync formatting: \(syncDuration)s")
        
        // Cached should be significantly faster
        XCTAssertLessThan(cachedDuration, syncDuration, "Cached formatting should be faster than sync")
    }
}
