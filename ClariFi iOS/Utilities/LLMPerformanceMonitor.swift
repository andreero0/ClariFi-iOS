//
//  LLMPerformanceMonitor.swift
//  ClariFi_iOS
//
//  Created for tracking LLM performance metrics and debugging
//

import Foundation
import os.log

/// Performance monitoring for LLM categorization service
@MainActor
class LLMPerformanceMonitor: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = LLMPerformanceMonitor()
    
    // MARK: - Published Metrics
    
    @Published private(set) var metrics: PerformanceMetrics
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: "com.clarifi.ios", category: "LLMPerformance")
    private var queryStartTimes: [UUID: Date] = [:]
    
    // MARK: - Initialization
    
    private init() {
        self.metrics = PerformanceMetrics()
        logger.info("LLMPerformanceMonitor initialized")
    }
    
    // MARK: - Query Tracking
    
    /// Start tracking a query
    /// - Returns: Query ID for tracking
    func startQuery() -> UUID {
        let queryId = UUID()
        queryStartTimes[queryId] = Date()
        logger.debug("Started tracking query: \(queryId.uuidString)")
        return queryId
    }
    
    /// End tracking a query with success
    /// - Parameters:
    ///   - queryId: The query ID returned from startQuery()
    ///   - method: The categorization method used
    ///   - category: The predicted category
    func endQuery(queryId: UUID, method: CategorizationMethod, category: String) {
        guard let startTime = queryStartTimes[queryId] else {
            logger.warning("No start time found for query: \(queryId.uuidString)")
            return
        }
        
        let duration = Date().timeIntervalSince(startTime)
        queryStartTimes.removeValue(forKey: queryId)
        
        // Update metrics
        metrics.totalQueries += 1
        metrics.queryTimes.append(duration)
        
        // Keep only last 100 query times to prevent unbounded growth
        if metrics.queryTimes.count > 100 {
            metrics.queryTimes.removeFirst()
        }
        
        // Track method usage
        switch method {
        case .llm:
            metrics.llmSuccessCount += 1
            logger.info("LLM query completed in \(String(format: "%.3f", duration))s - Category: \(category)")
        case .pattern:
            metrics.fallbackCount += 1
            logger.info("Fallback to pattern matching in \(String(format: "%.3f", duration))s - Category: \(category)")
        case .rule:
            metrics.fallbackCount += 1
            logger.info("Fallback to rule-based in \(String(format: "%.3f", duration))s - Category: \(category)")
        case .manual, .learned:
            break
        }
        
        logger.debug("Total queries: \(self.metrics.totalQueries), LLM success: \(self.metrics.llmSuccessCount), Fallbacks: \(self.metrics.fallbackCount)")
    }
    
    /// End tracking a query with failure
    /// - Parameters:
    ///   - queryId: The query ID returned from startQuery()
    ///   - error: The error that occurred
    func endQueryWithError(queryId: UUID, error: Error) {
        guard let startTime = queryStartTimes[queryId] else {
            logger.warning("No start time found for failed query: \(queryId.uuidString)")
            return
        }
        
        let duration = Date().timeIntervalSince(startTime)
        queryStartTimes.removeValue(forKey: queryId)
        
        metrics.totalQueries += 1
        metrics.errorCount += 1
        metrics.queryTimes.append(duration)
        
        if metrics.queryTimes.count > 100 {
            metrics.queryTimes.removeFirst()
        }
        
        logger.error("Query failed after \(String(format: "%.3f", duration))s - Error: \(error.localizedDescription)")
    }
    
    // MARK: - Accuracy Tracking
    
    /// Record categorization accuracy when user confirms or corrects
    /// - Parameters:
    ///   - predicted: The category predicted by the system
    ///   - actual: The category confirmed by the user
    ///   - method: The categorization method used
    func recordAccuracy(predicted: String, actual: String, method: CategorizationMethod) {
        let isCorrect = predicted.lowercased() == actual.lowercased()
        
        metrics.totalCategorizations += 1
        if isCorrect {
            metrics.correctCategorizations += 1
        }
        
        // Track by method
        switch method {
        case .llm:
            metrics.llmCategorizations += 1
            if isCorrect {
                metrics.llmCorrectCategorizations += 1
            }
            logger.info("LLM categorization \(isCorrect ? "correct" : "incorrect"): predicted=\(predicted), actual=\(actual)")
        case .pattern:
            metrics.patternCategorizations += 1
            if isCorrect {
                metrics.patternCorrectCategorizations += 1
            }
            logger.info("Pattern categorization \(isCorrect ? "correct" : "incorrect"): predicted=\(predicted), actual=\(actual)")
        case .rule:
            metrics.ruleCategorizations += 1
            if isCorrect {
                metrics.ruleCorrectCategorizations += 1
            }
            logger.info("Rule categorization \(isCorrect ? "correct" : "incorrect"): predicted=\(predicted), actual=\(actual)")
        case .manual, .learned:
            break
        }
    }
    
    // MARK: - Metrics Retrieval
    
    /// Get current performance metrics
    func getMetrics() -> PerformanceMetrics {
        return metrics
    }
    
    /// Get average query time
    func getAverageQueryTime() -> TimeInterval {
        guard !metrics.queryTimes.isEmpty else { return 0 }
        return metrics.queryTimes.reduce(0, +) / Double(metrics.queryTimes.count)
    }
    
    /// Get LLM success rate (percentage)
    func getLLMSuccessRate() -> Double {
        guard metrics.totalQueries > 0 else { return 0 }
        return Double(metrics.llmSuccessCount) / Double(metrics.totalQueries) * 100
    }
    
    /// Get fallback frequency (percentage)
    func getFallbackRate() -> Double {
        guard metrics.totalQueries > 0 else { return 0 }
        return Double(metrics.fallbackCount) / Double(metrics.totalQueries) * 100
    }
    
    /// Get overall categorization accuracy (percentage)
    func getOverallAccuracy() -> Double {
        guard metrics.totalCategorizations > 0 else { return 0 }
        return Double(metrics.correctCategorizations) / Double(metrics.totalCategorizations) * 100
    }
    
    /// Get LLM-specific categorization accuracy (percentage)
    func getLLMAccuracy() -> Double {
        guard metrics.llmCategorizations > 0 else { return 0 }
        return Double(metrics.llmCorrectCategorizations) / Double(metrics.llmCategorizations) * 100
    }
    
    /// Get pattern-matching categorization accuracy (percentage)
    func getPatternAccuracy() -> Double {
        guard metrics.patternCategorizations > 0 else { return 0 }
        return Double(metrics.patternCorrectCategorizations) / Double(metrics.patternCategorizations) * 100
    }
    
    // MARK: - Logging & Debugging
    
    /// Log current performance summary
    func logPerformanceSummary() {
        logger.info("""
        === LLM Performance Summary ===
        Total Queries: \(self.metrics.totalQueries)
        LLM Success: \(self.metrics.llmSuccessCount) (\(String(format: "%.1f", self.getLLMSuccessRate()))%)
        Fallbacks: \(self.metrics.fallbackCount) (\(String(format: "%.1f", self.getFallbackRate()))%)
        Errors: \(self.metrics.errorCount)
        Avg Query Time: \(String(format: "%.3f", self.getAverageQueryTime()))s
        
        Categorization Accuracy:
        - Overall: \(String(format: "%.1f", self.getOverallAccuracy()))% (\(self.metrics.correctCategorizations)/\(self.metrics.totalCategorizations))
        - LLM: \(String(format: "%.1f", self.getLLMAccuracy()))% (\(self.metrics.llmCorrectCategorizations)/\(self.metrics.llmCategorizations))
        - Pattern: \(String(format: "%.1f", self.getPatternAccuracy()))% (\(self.metrics.patternCorrectCategorizations)/\(self.metrics.patternCategorizations))
        ==============================
        """)
    }
    
    /// Export metrics as dictionary for analytics
    func exportMetrics() -> [String: Any] {
        return [
            "totalQueries": metrics.totalQueries,
            "llmSuccessCount": metrics.llmSuccessCount,
            "fallbackCount": metrics.fallbackCount,
            "errorCount": metrics.errorCount,
            "averageQueryTime": getAverageQueryTime(),
            "llmSuccessRate": getLLMSuccessRate(),
            "fallbackRate": getFallbackRate(),
            "totalCategorizations": metrics.totalCategorizations,
            "correctCategorizations": metrics.correctCategorizations,
            "overallAccuracy": getOverallAccuracy(),
            "llmAccuracy": getLLMAccuracy(),
            "patternAccuracy": getPatternAccuracy()
        ]
    }
    
    // MARK: - Reset
    
    /// Reset all metrics (useful for testing)
    func reset() {
        metrics = PerformanceMetrics()
        queryStartTimes.removeAll()
        logger.info("Performance metrics reset")
    }
}

// MARK: - Performance Metrics Model

struct PerformanceMetrics {
    // Query tracking
    var totalQueries: Int = 0
    var llmSuccessCount: Int = 0
    var fallbackCount: Int = 0
    var errorCount: Int = 0
    var queryTimes: [TimeInterval] = []
    
    // Accuracy tracking
    var totalCategorizations: Int = 0
    var correctCategorizations: Int = 0
    
    // Method-specific accuracy
    var llmCategorizations: Int = 0
    var llmCorrectCategorizations: Int = 0
    var patternCategorizations: Int = 0
    var patternCorrectCategorizations: Int = 0
    var ruleCategorizations: Int = 0
    var ruleCorrectCategorizations: Int = 0
}
