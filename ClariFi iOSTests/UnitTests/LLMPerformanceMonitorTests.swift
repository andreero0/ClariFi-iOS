//
//  LLMPerformanceMonitorTests.swift
//  ClariFi_iOS
//
//  Tests for LLM performance monitoring
//

import XCTest
@testable import ClariFi_iOS

@MainActor
final class LLMPerformanceMonitorTests: XCTestCase {
    
    var monitor: LLMPerformanceMonitor!
    
    override func setUp() async throws {
        try await super.setUp()
        monitor = LLMPerformanceMonitor.shared
        monitor.reset()
    }
    
    override func tearDown() async throws {
        monitor.reset()
        try await super.tearDown()
    }
    
    // MARK: - Query Tracking Tests
    
    func testStartAndEndQuery() async throws {
        // Given
        let queryId = monitor.startQuery()
        
        // When
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        monitor.endQuery(queryId: queryId, method: .llm, category: "food_groceries")
        
        // Then
        let metrics = monitor.getMetrics()
        XCTAssertEqual(metrics.totalQueries, 1)
        XCTAssertEqual(metrics.llmSuccessCount, 1)
        XCTAssertEqual(metrics.fallbackCount, 0)
        XCTAssertEqual(metrics.errorCount, 0)
        XCTAssertGreaterThan(monitor.getAverageQueryTime(), 0.09)
    }
    
    func testQueryWithError() async throws {
        // Given
        let queryId = monitor.startQuery()
        
        // When
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        monitor.endQueryWithError(queryId: queryId, error: NSError(domain: "test", code: 1))
        
        // Then
        let metrics = monitor.getMetrics()
        XCTAssertEqual(metrics.totalQueries, 1)
        XCTAssertEqual(metrics.errorCount, 1)
        XCTAssertEqual(metrics.llmSuccessCount, 0)
    }
    
    func testFallbackTracking() async throws {
        // Given
        let queryId = monitor.startQuery()
        
        // When
        monitor.endQuery(queryId: queryId, method: .pattern, category: "dining")
        
        // Then
        let metrics = monitor.getMetrics()
        XCTAssertEqual(metrics.totalQueries, 1)
        XCTAssertEqual(metrics.fallbackCount, 1)
        XCTAssertEqual(metrics.llmSuccessCount, 0)
        XCTAssertEqual(monitor.getFallbackRate(), 100.0)
    }
    
    func testMultipleQueries() async throws {
        // Given & When
        for i in 0..<5 {
            let queryId = monitor.startQuery()
            let method: CategorizationMethod = i % 2 == 0 ? .llm : .pattern
            monitor.endQuery(queryId: queryId, method: method, category: "test")
        }
        
        // Then
        let metrics = monitor.getMetrics()
        XCTAssertEqual(metrics.totalQueries, 5)
        XCTAssertEqual(metrics.llmSuccessCount, 3)
        XCTAssertEqual(metrics.fallbackCount, 2)
        XCTAssertEqual(monitor.getLLMSuccessRate(), 60.0)
        XCTAssertEqual(monitor.getFallbackRate(), 40.0)
    }
    
    // MARK: - Accuracy Tracking Tests
    
    func testAccuracyTracking() async throws {
        // Given & When
        monitor.recordAccuracy(predicted: "food_groceries", actual: "food_groceries", method: .llm)
        monitor.recordAccuracy(predicted: "dining", actual: "food_groceries", method: .llm)
        monitor.recordAccuracy(predicted: "housing", actual: "housing", method: .pattern)
        
        // Then
        let metrics = monitor.getMetrics()
        XCTAssertEqual(metrics.totalCategorizations, 3)
        XCTAssertEqual(metrics.correctCategorizations, 2)
        XCTAssertEqual(monitor.getOverallAccuracy(), 66.66666666666667, accuracy: 0.01)
        
        XCTAssertEqual(metrics.llmCategorizations, 2)
        XCTAssertEqual(metrics.llmCorrectCategorizations, 1)
        XCTAssertEqual(monitor.getLLMAccuracy(), 50.0)
        
        XCTAssertEqual(metrics.patternCategorizations, 1)
        XCTAssertEqual(metrics.patternCorrectCategorizations, 1)
        XCTAssertEqual(monitor.getPatternAccuracy(), 100.0)
    }
    
    func testAccuracyByMethod() async throws {
        // Given & When - LLM categorizations
        monitor.recordAccuracy(predicted: "dining", actual: "dining", method: .llm)
        monitor.recordAccuracy(predicted: "dining", actual: "dining", method: .llm)
        monitor.recordAccuracy(predicted: "dining", actual: "food_groceries", method: .llm)
        
        // Pattern categorizations
        monitor.recordAccuracy(predicted: "housing", actual: "housing", method: .pattern)
        monitor.recordAccuracy(predicted: "utilities", actual: "housing", method: .pattern)
        
        // Then
        XCTAssertEqual(monitor.getLLMAccuracy(), 66.66666666666667, accuracy: 0.01)
        XCTAssertEqual(monitor.getPatternAccuracy(), 50.0)
    }
    
    // MARK: - Metrics Export Tests
    
    func testExportMetrics() async throws {
        // Given
        let queryId = monitor.startQuery()
        monitor.endQuery(queryId: queryId, method: .llm, category: "test")
        monitor.recordAccuracy(predicted: "test", actual: "test", method: .llm)
        
        // When
        let exported = monitor.exportMetrics()
        
        // Then
        XCTAssertEqual(exported["totalQueries"] as? Int, 1)
        XCTAssertEqual(exported["llmSuccessCount"] as? Int, 1)
        XCTAssertEqual(exported["totalCategorizations"] as? Int, 1)
        XCTAssertEqual(exported["correctCategorizations"] as? Int, 1)
        XCTAssertNotNil(exported["averageQueryTime"])
        XCTAssertNotNil(exported["llmSuccessRate"])
        XCTAssertNotNil(exported["overallAccuracy"])
    }
    
    // MARK: - Reset Tests
    
    func testReset() async throws {
        // Given
        let queryId = monitor.startQuery()
        monitor.endQuery(queryId: queryId, method: .llm, category: "test")
        monitor.recordAccuracy(predicted: "test", actual: "test", method: .llm)
        
        // When
        monitor.reset()
        
        // Then
        let metrics = monitor.getMetrics()
        XCTAssertEqual(metrics.totalQueries, 0)
        XCTAssertEqual(metrics.llmSuccessCount, 0)
        XCTAssertEqual(metrics.totalCategorizations, 0)
        XCTAssertEqual(monitor.getAverageQueryTime(), 0)
    }
    
    // MARK: - Edge Cases
    
    func testQueryTimesLimit() async throws {
        // Given & When - Add more than 100 queries
        for _ in 0..<150 {
            let queryId = monitor.startQuery()
            monitor.endQuery(queryId: queryId, method: .llm, category: "test")
        }
        
        // Then - Should only keep last 100
        let metrics = monitor.getMetrics()
        XCTAssertEqual(metrics.queryTimes.count, 100)
        XCTAssertEqual(metrics.totalQueries, 150)
    }
    
    func testZeroDivisionSafety() async throws {
        // Given - No data
        
        // When & Then - Should not crash
        XCTAssertEqual(monitor.getAverageQueryTime(), 0)
        XCTAssertEqual(monitor.getLLMSuccessRate(), 0)
        XCTAssertEqual(monitor.getFallbackRate(), 0)
        XCTAssertEqual(monitor.getOverallAccuracy(), 0)
        XCTAssertEqual(monitor.getLLMAccuracy(), 0)
        XCTAssertEqual(monitor.getPatternAccuracy(), 0)
    }
    
    func testInvalidQueryId() async throws {
        // Given
        let invalidQueryId = UUID()
        
        // When & Then - Should handle gracefully
        monitor.endQuery(queryId: invalidQueryId, method: .llm, category: "test")
        monitor.endQueryWithError(queryId: invalidQueryId, error: NSError(domain: "test", code: 1))
        
        // Should not have recorded anything
        let metrics = monitor.getMetrics()
        XCTAssertEqual(metrics.totalQueries, 0)
    }
}
