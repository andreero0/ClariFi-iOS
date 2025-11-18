//
//  LLMCacheThreadSafetyTests.swift
//  ClariFi iOSTests
//
//  Tests for LLM cache thread safety and race conditions
//

import XCTest
@testable import ClariFi_iOS

@MainActor
class LLMCacheThreadSafetyTests: XCTestCase {
    
    var cache: LLMCache!
    
    override func setUp() async throws {
        try await super.setUp()
        cache = LLMCache()
    }
    
    override func tearDown() async throws {
        cache = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Cache Operations
    
    func testCacheSetAndGet() async throws {
        let result = LLMCategorizationResult(
            category: "Food & Dining",
            confidence: 0.8,
            reasoning: "Test reasoning"
        )
        
        await cache.setResponse(result, for: "test_key")
        let retrieved = await cache.getResponse(for: "test_key")
        
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.category, "Food & Dining")
        XCTAssertEqual(retrieved?.confidence, 0.8)
    }
    
    func testCacheMiss() async throws {
        let result = await cache.getResponse(for: "nonexistent_key")
        XCTAssertNil(result)
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentReads() async throws {
        let result = LLMCategorizationResult(
            category: "Test Category",
            confidence: 0.9,
            reasoning: "Test reasoning"
        )
        
        await cache.setResponse(result, for: "concurrent_key")
        
        // Test concurrent reads
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    let retrieved = await self.cache.getResponse(for: "concurrent_key")
                    XCTAssertNotNil(retrieved)
                    XCTAssertEqual(retrieved?.category, "Test Category")
                }
            }
        }
    }
    
    func testConcurrentWrites() async throws {
        // Test concurrent writes to different keys
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    let result = LLMCategorizationResult(
                        category: "Category \(i)",
                        confidence: Float(i) / 100.0,
                        reasoning: "Reasoning \(i)"
                    )
                    await self.cache.setResponse(result, for: "key_\(i)")
                }
            }
        }
        
        // Verify all writes completed
        for i in 0..<100 {
            let result = await cache.getResponse(for: "key_\(i)")
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.category, "Category \(i)")
        }
    }
    
    func testConcurrentReadsAndWrites() async throws {
        // Test concurrent reads and writes to same key
        await withTaskGroup(of: Void.self) { group in
            // Add write tasks
            for i in 0..<50 {
                group.addTask {
                    let result = LLMCategorizationResult(
                        category: "Write \(i)",
                        confidence: 0.8,
                        reasoning: "Write reasoning"
                    )
                    await self.cache.setResponse(result, for: "shared_key")
                }
            }
            
            // Add read tasks
            for _ in 0..<50 {
                group.addTask {
                    let result = await self.cache.getResponse(for: "shared_key")
                    // Result might be nil or have any of the written values
                    if let result = result {
                        XCTAssertTrue(result.category.hasPrefix("Write"))
                        XCTAssertEqual(result.confidence, 0.8)
                    }
                }
            }
        }
    }
    
    // MARK: - Merchant Normalization Cache Tests
    
    func testMerchantNormalizationCache() async throws {
        await cache.setMerchantNormalization("STARBUCKS", for: "starbucks coffee")
        let normalized = await cache.getMerchantNormalization(for: "starbucks coffee")
        
        XCTAssertEqual(normalized, "STARBUCKS")
    }
    
    func testConcurrentMerchantNormalization() async throws {
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    await self.cache.setMerchantNormalization("MERCHANT_\(i)", for: "merchant_\(i)")
                }
            }
        }
        
        // Verify all normalizations
        for i in 0..<100 {
            let normalized = await cache.getMerchantNormalization(for: "merchant_\(i)")
            XCTAssertEqual(normalized, "MERCHANT_\(i)")
        }
    }
    
    // MARK: - Cache Eviction Tests
    
    func testCacheEviction() async throws {
        // Fill cache beyond max size
        for i in 0..<1500 { // More than maxResponseCacheSize (1000)
            let result = LLMCategorizationResult(
                category: "Category \(i)",
                confidence: 0.8,
                reasoning: "Reasoning"
            )
            await cache.setResponse(result, for: "key_\(i)")
        }
        
        // Check cache stats
        let stats = await cache.getCacheStats()
        XCTAssertLessThanOrEqual(stats.responseCount, 1000) // Should be at max size
    }
    
    func testMerchantCacheEviction() async throws {
        // Fill merchant cache beyond max size
        for i in 0..<600 { // More than maxMerchantCacheSize (500)
            await cache.setMerchantNormalization("MERCHANT_\(i)", for: "merchant_\(i)")
        }
        
        // Check cache stats
        let stats = await cache.getCacheStats()
        XCTAssertLessThanOrEqual(stats.merchantCount, 500) // Should be at max size
    }
    
    // MARK: - Cache Clear Tests
    
    func testClearAll() async throws {
        // Add some data
        let result = LLMCategorizationResult(
            category: "Test Category",
            confidence: 0.8,
            reasoning: "Test reasoning"
        )
        await cache.setResponse(result, for: "test_key")
        await cache.setMerchantNormalization("TEST", for: "test_merchant")
        
        // Verify data exists
        XCTAssertNotNil(await cache.getResponse(for: "test_key"))
        XCTAssertNotNil(await cache.getMerchantNormalization(for: "test_merchant"))
        
        // Clear cache
        await cache.clearAll()
        
        // Verify data is gone
        XCTAssertNil(await cache.getResponse(for: "test_key"))
        XCTAssertNil(await cache.getMerchantNormalization(for: "test_merchant"))
        
        // Verify stats are zero
        let stats = await cache.getCacheStats()
        XCTAssertEqual(stats.responseCount, 0)
        XCTAssertEqual(stats.merchantCount, 0)
    }
    
    // MARK: - Race Condition Tests
    
    func testRaceConditionPrevention() async throws {
        // Test that actor isolation prevents race conditions
        let expectation = XCTestExpectation(description: "Race condition test")
        expectation.expectedFulfillmentCount = 1000
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<1000 {
                group.addTask {
                    // Simulate race condition scenario
                    let result = LLMCategorizationResult(
                        category: "Race \(i)",
                        confidence: 0.8,
                        reasoning: "Race test"
                    )
                    await self.cache.setResponse(result, for: "race_key")
                    
                    let retrieved = await self.cache.getResponse(for: "race_key")
                    XCTAssertNotNil(retrieved)
                    
                    expectation.fulfill()
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
}
