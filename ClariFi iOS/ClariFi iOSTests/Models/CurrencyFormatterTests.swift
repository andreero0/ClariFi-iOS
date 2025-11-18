//
//  CurrencyFormatterTests.swift
//  ClariFi iOSTests
//
//  Tests for CurrencyFormatter and FormatterCache performance
//

import XCTest
@testable import ClariFi_iOS

@MainActor
class CurrencyFormatterTests: XCTestCase {
    
    var formatter: CurrencyFormatter!
    
    override func setUp() async throws {
        try await super.setUp()
        formatter = CurrencyFormatter.shared
    }
    
    override func tearDown() async throws {
        formatter = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Formatting Tests
    
    func testBasicCurrencyFormatting() async throws {
        let amount = Decimal(123.45)
        let formatted = await formatter.format(amount, currency: .usd)
        
        XCTAssertTrue(formatted.contains("123"))
        XCTAssertTrue(formatted.contains("45"))
    }
    
    func testDifferentCurrencies() async throws {
        let amount = Decimal(100.00)
        
        let usdFormatted = await formatter.format(amount, currency: .usd)
        let eurFormatted = await formatter.format(amount, currency: .eur)
        let gbpFormatted = await formatter.format(amount, currency: .gbp)
        
        XCTAssertNotEqual(usdFormatted, eurFormatted)
        XCTAssertNotEqual(usdFormatted, gbpFormatted)
        XCTAssertNotEqual(eurFormatted, gbpFormatted)
    }
    
    func testFormatWithSymbol() async throws {
        let amount = Decimal(99.99)
        let formatted = await formatter.formatWithSymbol(amount, currency: .usd)
        
        XCTAssertTrue(formatted.contains("$"))
        XCTAssertTrue(formatted.contains("99"))
    }
    
    func testSyncFormatting() throws {
        let amount = Decimal(50.00)
        let formatted = formatter.formatSync(amount, currency: .usd)
        
        XCTAssertTrue(formatted.contains("50"))
    }
    
    // MARK: - Cache Performance Tests
    
    func testFormatterCaching() async throws {
        let amount = Decimal(100.00)
        
        // First call should create formatter
        let startTime = CFAbsoluteTimeGetCurrent()
        let formatted1 = await formatter.format(amount, currency: .usd)
        let firstCallTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Second call should use cached formatter
        let startTime2 = CFAbsoluteTimeGetCurrent()
        let formatted2 = await formatter.format(amount, currency: .usd)
        let secondCallTime = CFAbsoluteTimeGetCurrent() - startTime2
        
        XCTAssertEqual(formatted1, formatted2)
        XCTAssertLessThan(secondCallTime, firstCallTime) // Second call should be faster
    }
    
    func testCacheStats() async throws {
        let initialStats = await formatter.getCacheStats()
        
        // Use formatter for different currencies
        await formatter.format(Decimal(100), currency: .usd)
        await formatter.format(Decimal(100), currency: .eur)
        await formatter.format(Decimal(100), currency: .gbp)
        
        let finalStats = await formatter.getCacheStats()
        XCTAssertGreaterThan(finalStats, initialStats)
    }
    
    func testCacheClear() async throws {
        // Use formatter to populate cache
        await formatter.format(Decimal(100), currency: .usd)
        let statsBeforeClear = await formatter.getCacheStats()
        XCTAssertGreaterThan(statsBeforeClear, 0)
        
        // Clear cache
        formatter.clearCache()
        
        // Verify cache is cleared
        let statsAfterClear = await formatter.getCacheStats()
        XCTAssertEqual(statsAfterClear, 0)
    }
    
    // MARK: - Performance Tests
    
    func testFormattingPerformance() async throws {
        let amounts = generateTestAmounts(count: 1000)
        
        // Test cached formatter performance
        let startTime = CFAbsoluteTimeGetCurrent()
        for amount in amounts {
            _ = await formatter.format(amount, currency: .usd)
        }
        let cachedTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Verify performance is acceptable
        XCTAssertLessThan(cachedTime, 0.1) // Should complete in under 100ms
        
        print("Cached formatter time for 1000 operations: \(cachedTime)s")
    }
    
    func testConcurrentFormatting() async throws {
        let amounts = generateTestAmounts(count: 100)
        let currencies: [Currency] = [.usd, .eur, .gbp, .jpy, .cad]
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await withTaskGroup(of: Void.self) { group in
            for amount in amounts {
                for currency in currencies {
                    group.addTask {
                        _ = await self.formatter.format(amount, currency: currency)
                    }
                }
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Verify concurrent formatting is fast
        XCTAssertLessThan(executionTime, 0.5) // Should complete in under 500ms
        
        print("Concurrent formatting time: \(executionTime)s")
    }
    
    // MARK: - Edge Cases
    
    func testZeroAmount() async throws {
        let formatted = await formatter.format(Decimal(0), currency: .usd)
        XCTAssertTrue(formatted.contains("0"))
    }
    
    func testNegativeAmount() async throws {
        let formatted = await formatter.format(Decimal(-100), currency: .usd)
        XCTAssertTrue(formatted.contains("-") || formatted.contains("100"))
    }
    
    func testLargeAmount() async throws {
        let largeAmount = Decimal(999999.99)
        let formatted = await formatter.format(largeAmount, currency: .usd)
        XCTAssertTrue(formatted.contains("999999"))
    }
    
    func testSmallAmount() async throws {
        let smallAmount = Decimal(0.01)
        let formatted = await formatter.format(smallAmount, currency: .usd)
        XCTAssertTrue(formatted.contains("0.01") || formatted.contains("1"))
    }
    
    // MARK: - Thread Safety Tests
    
    func testThreadSafety() async throws {
        let expectation = XCTestExpectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = 100
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    let amount = Decimal(i * 10)
                    let currency: Currency = [.usd, .eur, .gbp, .jpy, .cad][i % 5]
                    
                    let formatted = await self.formatter.format(amount, currency: currency)
                    XCTAssertFalse(formatted.isEmpty)
                    
                    expectation.fulfill()
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Helper Methods
    
    private func generateTestAmounts(count: Int) -> [Decimal] {
        var amounts: [Decimal] = []
        for _ in 0..<count {
            amounts.append(Decimal(Double.random(in: 0...1000)))
        }
        return amounts
    }
}
