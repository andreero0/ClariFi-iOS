//
//  LLMCacheThreadSafetyTests.swift
//  ClariFi iOSTests
//
//  Created by AI Assistant on 2025-10-10.
//
//  Tests for LLM cache thread safety and race condition prevention
//

import XCTest
@testable import ClariFi_iOS

final class LLMCacheThreadSafetyTests: XCTestCase {
    
    var cache: LLMCache!
    
    override func setUp() {
        super.setUp()
        cache = LLMCache()
    }
    
    override func tearDown() {
        cache = nil
        super.tearDown()
    }
    
    // MARK: - Basic Cache Operations
    
    func testBasicResponseCacheOperations() async {
        // Given
        let key = "test_merchant_100"
        let result = LLMCategorizationResult(
            category: "Food & Dining",
            confidence: ConfidenceScore(overall: 0.9, category: 0.9, merchant: 0.8, amount: 0.9),
            reasoning: "Test reasoning"
        )
        
        // When
        let initialValue = await cache.getResponse(for: key)
        await cache.setResponse(result, for: key)
        let cachedValue = await cache.getResponse(for: key)
        
        // Then
        XCTAssertNil(initialValue, "Initial cache should be empty")
        XCTAssertEqual(cachedValue?.category, result.category)
        XCTAssertEqual(cachedValue?.confidence.overall, result.confidence.overall)
    }
    
    func testBasicMerchantCacheOperations() async {
        // Given
        let key = "test_merchant"
        let normalized = "Test Merchant Inc"
        
        // When
        let initialValue = await cache.getMerchantNormalization(for: key)
        await cache.setMerchantNormalization(normalized, for: key)
        let cachedValue = await cache.getMerchantNormalization(for: key)
        
        // Then
        XCTAssertNil(initialValue, "Initial cache should be empty")
        XCTAssertEqual(cachedValue, normalized)
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentResponseCacheWrites() async {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent writes")
        expectation.expectedFulfillmentCount = 100
        
        // When - Write to cache from multiple tasks
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    let result = LLMCategorizationResult(
                        category: "Category \(i)",
                        confidence: ConfidenceScore(overall: 0.8, category: 0.8, merchant: 0.8, amount: 0.8),
                        reasoning: "Reasoning \(i)"
                    )
                    await self.cache.setResponse(result, for: "key_\(i)")
                    expectation.fulfill()
                }
            }
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Verify all values were stored correctly
        for i in 0..<100 {
            let result = await cache.getResponse(for: "key_\(i)")
            XCTAssertEqual(result?.category, "Category \(i)")
        }
    }
    
    func testConcurrentMerchantCacheWrites() async {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent merchant writes")
        expectation.expectedFulfillmentCount = 50
        
        // When - Write to merchant cache from multiple tasks
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    await self.cache.setMerchantNormalization("Merchant \(i)", for: "merchant_\(i)")
                    expectation.fulfill()
                }
            }
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Verify all values were stored correctly
        for i in 0..<50 {
            let normalized = await cache.getMerchantNormalization(for: "merchant_\(i)")
            XCTAssertEqual(normalized, "Merchant \(i)")
        }
    }
    
    func testConcurrentReadsAndWrites() async {
        // Given
        let writeExpectation = XCTestExpectation(description: "Concurrent writes")
        let readExpectation = XCTestExpectation(description: "Concurrent reads")
        writeExpectation.expectedFulfillmentCount = 50
        readExpectation.expectedFulfillmentCount = 50
        
        // When - Mix of reads and writes
        await withTaskGroup(of: Void.self) { group in
            // Writers
            for i in 0..<50 {
                group.addTask {
                    let result = LLMCategorizationResult(
                        category: "Category \(i)",
                        confidence: ConfidenceScore(overall: 0.8, category: 0.8, merchant: 0.8, amount: 0.8),
                        reasoning: "Reasoning \(i)"
                    )
                    await self.cache.setResponse(result, for: "key_\(i)")
                    writeExpectation.fulfill()
                }
            }
            
            // Readers
            for i in 0..<50 {
                group.addTask {
                    let result = await self.cache.getResponse(for: "key_\(i)")
                    // Result might be nil if read happens before write, that's OK
                    readExpectation.fulfill()
                }
            }
        }
        
        // Then
        await fulfillment(of: [writeExpectation, readExpectation], timeout: 5.0)
    }
    
    // MARK: - Cache Eviction Tests
    
    func testResponseCacheEviction() async {
        // Given - Fill cache beyond limit (1000 entries)
        let maxEntries = 1000
        let extraEntries = 100
        
        // When - Add more entries than the cache limit
        for i in 0..<(maxEntries + extraEntries) {
            let result = LLMCategorizationResult(
                category: "Category \(i)",
                confidence: ConfidenceScore(overall: 0.8, category: 0.8, merchant: 0.8, amount: 0.8),
                reasoning: "Reasoning \(i)"
            )
            await cache.setResponse(result, for: "key_\(i)")
        }
        
        // Then - Cache should be at or below limit
        let cacheSize = await cache.responseCacheSize
        XCTAssertLessThanOrEqual(cacheSize, maxEntries, "Cache should not exceed maximum size")
        
        // First 100 entries should be evicted (FIFO)
        let firstEntry = await cache.getResponse(for: "key_0")
        XCTAssertNil(firstEntry, "First entries should be evicted")
        
        // Last entries should still be present
        let lastEntry = await cache.getResponse(for: "key_\(maxEntries + extraEntries - 1)")
        XCTAssertNotNil(lastEntry, "Last entries should still be present")
    }
    
    func testMerchantCacheEviction() async {
        // Given - Fill merchant cache beyond limit (500 entries)
        let maxEntries = 500
        let extraEntries = 50
        
        // When - Add more entries than the cache limit
        for i in 0..<(maxEntries + extraEntries) {
            await cache.setMerchantNormalization("Merchant \(i)", for: "merchant_\(i)")
        }
        
        // Then - Cache should be at or below limit
        let cacheSize = await cache.merchantCacheSize
        XCTAssertLessThanOrEqual(cacheSize, maxEntries, "Merchant cache should not exceed maximum size")
        
        // First entries should be evicted (FIFO)
        let firstEntry = await cache.getMerchantNormalization(for: "merchant_0")
        XCTAssertNil(firstEntry, "First merchant entries should be evicted")
        
        // Last entries should still be present
        let lastEntry = await cache.getMerchantNormalization(for: "merchant_\(maxEntries + extraEntries - 1)")
        XCTAssertNotNil(lastEntry, "Last merchant entries should still be present")
    }
    
    // MARK: - Cache Management Tests
    
    func testClearAllCaches() async {
        // Given - Populate both caches
        let result = LLMCategorizationResult(
            category: "Test Category",
            confidence: ConfidenceScore(overall: 0.8, category: 0.8, merchant: 0.8, amount: 0.8),
            reasoning: "Test reasoning"
        )
        await cache.setResponse(result, for: "test_key")
        await cache.setMerchantNormalization("Test Merchant", for: "test_merchant")
        
        // Verify caches are populated
        XCTAssertNotNil(await cache.getResponse(for: "test_key"))
        XCTAssertNotNil(await cache.getMerchantNormalization(for: "test_merchant"))
        
        // When
        await cache.clearAll()
        
        // Then
        XCTAssertNil(await cache.getResponse(for: "test_key"))
        XCTAssertNil(await cache.getMerchantNormalization(for: "test_merchant"))
        XCTAssertEqual(await cache.totalCacheSize, 0)
    }
    
    func testClearResponseCacheOnly() async {
        // Given - Populate both caches
        let result = LLMCategorizationResult(
            category: "Test Category",
            confidence: ConfidenceScore(overall: 0.8, category: 0.8, merchant: 0.8, amount: 0.8),
            reasoning: "Test reasoning"
        )
        await cache.setResponse(result, for: "test_key")
        await cache.setMerchantNormalization("Test Merchant", for: "test_merchant")
        
        // When
        await cache.clearResponseCache()
        
        // Then
        XCTAssertNil(await cache.getResponse(for: "test_key"))
        XCTAssertNotNil(await cache.getMerchantNormalization(for: "test_merchant"))
        XCTAssertEqual(await cache.responseCacheSize, 0)
        XCTAssertEqual(await cache.merchantCacheSize, 1)
    }
    
    func testClearMerchantCacheOnly() async {
        // Given - Populate both caches
        let result = LLMCategorizationResult(
            category: "Test Category",
            confidence: ConfidenceScore(overall: 0.8, category: 0.8, merchant: 0.8, amount: 0.8),
            reasoning: "Test reasoning"
        )
        await cache.setResponse(result, for: "test_key")
        await cache.setMerchantNormalization("Test Merchant", for: "test_merchant")
        
        // When
        await cache.clearMerchantCache()
        
        // Then
        XCTAssertNotNil(await cache.getResponse(for: "test_key"))
        XCTAssertNil(await cache.getMerchantNormalization(for: "test_merchant"))
        XCTAssertEqual(await cache.responseCacheSize, 1)
        XCTAssertEqual(await cache.merchantCacheSize, 0)
    }
    
    // MARK: - Cache Statistics Tests
    
    func testCacheStatistics() async {
        // Given
        let result = LLMCategorizationResult(
            category: "Test Category",
            confidence: ConfidenceScore(overall: 0.8, category: 0.8, merchant: 0.8, amount: 0.8),
            reasoning: "Test reasoning"
        )
        
        // When
        await cache.setResponse(result, for: "test_key")
        await cache.setMerchantNormalization("Test Merchant", for: "test_merchant")
        
        // Then
        XCTAssertEqual(await cache.responseCacheSize, 1)
        XCTAssertEqual(await cache.merchantCacheSize, 1)
        XCTAssertEqual(await cache.totalCacheSize, 2)
    }
}
