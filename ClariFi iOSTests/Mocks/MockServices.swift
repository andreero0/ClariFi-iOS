//
//  MockServices.swift
//  ClariFi_iOS Tests
//
//  Mock implementations for service protocols to support testing
//

import Foundation
import CoreData
import Combine

// MARK: - Mock Insights Engine

@MainActor
class MockInsightsEngine: InsightsEngineProtocol {
    var generateInsightsCalled = false
    var generateSpendingTrendsCalled = false
    var prioritizeInsightsCalled = false
    
    var mockInsights: [Insight] = []
    var mockSpendingTrends: SpendingTrends?
    var shouldThrowError = false
    
    func generateInsights(for transactions: [Transaction], budget: Budget?) async -> [Insight] {
        generateInsightsCalled = true
        
        if shouldThrowError {
            return []
        }
        
        return mockInsights
    }
    
    func generateSpendingTrends(for period: DateInterval, transactions: [Transaction]) async -> SpendingTrends {
        generateSpendingTrendsCalled = true
        
        if let trends = mockSpendingTrends {
            return trends
        }
        
        // Return default trends
        return SpendingTrends(
            period: period,
            totalSpending: 0,
            averageDaily: 0,
            categoryBreakdown: [:],
            topMerchants: [],
            comparisonToPrevious: nil,
            projectedMonthly: 0
        )
    }
    
    nonisolated func prioritizeInsights(_ insights: [Insight]) -> [Insight] {
        return insights.sorted { $0.impactScore > $1.impactScore }
    }
}

// MARK: - Mock Category Service

@MainActor
class MockCategoryService: CategoryServiceProtocol {
    var categorizeCalled = false
    var learnFromCorrectionCalled = false
    var getSuggestedCategoriesCalled = false
    var getMerchantHistoryCalled = false
    
    var mockCategorizationResult: CategorizationResult?
    var mockSuggestedCategories: [CategorizationResult] = []
    var mockMerchantHistory: [String: Int] = [:]
    var shouldThrowError = false
    
    func categorize(merchant: String, amount: Decimal) async throws -> CategorizationResult {
        categorizeCalled = true
        
        if shouldThrowError {
            throw NSError(domain: "MockCategoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        
        if let result = mockCategorizationResult {
            return result
        }
        
        // Return default result
        return CategorizationResult(
            category: "Other",
            confidence: 0.5,
            matchedPattern: nil,
            matchType: .default_
        )
    }
    
    func learnFromCorrection(merchant: String, category: String) async throws {
        learnFromCorrectionCalled = true
        
        if shouldThrowError {
            throw NSError(domain: "MockCategoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
    }
    
    func getSuggestedCategories(for merchant: String) async throws -> [CategorizationResult] {
        getSuggestedCategoriesCalled = true
        
        if shouldThrowError {
            throw NSError(domain: "MockCategoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        
        return mockSuggestedCategories
    }
    
    func getMerchantHistory(for merchant: String) async throws -> [String: Int] {
        getMerchantHistoryCalled = true
        
        if shouldThrowError {
            throw NSError(domain: "MockCategoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        
        return mockMerchantHistory
    }
}

// MARK: - Mock Analytics Service

class MockAnalyticsService: AnalyticsServiceProtocol {
    var isEnabled: Bool = true
    var trackedEvents: [(event: AnalyticsEvent, properties: [String: Any]?)] = []
    var identifiedUsers: [(userId: String, properties: [String: Any]?)] = []
    var capturedExceptions: [(error: Error, context: [String: Any]?)] = []
    var viewedScreens: [(name: String, properties: [String: Any]?)] = []
    
    func initialize() {
        print("Mock Analytics initialized")
    }
    
    func identify(userId: String, properties: [String: Any]?) {
        identifiedUsers.append((userId, properties))
    }
    
    func track(event: AnalyticsEvent, properties: [String: Any]?) {
        trackedEvents.append((event, properties))
        print("📊 Mock Analytics: \(event.rawValue) - \(properties ?? [:])")
    }
    
    func screen(name: String, properties: [String: Any]?) {
        viewedScreens.append((name, properties))
    }
    
    func setUserProperty(key: String, value: Any) {
        print("Mock Analytics: Set property \(key) = \(value)")
    }
    
    func reset() {
        trackedEvents.removeAll()
        identifiedUsers.removeAll()
        capturedExceptions.removeAll()
        viewedScreens.removeAll()
    }
    
    func captureException(_ error: Error, context: [String: Any]?) {
        capturedExceptions.append((error, context))
        print("🔥 Mock Analytics: Exception captured - \(error.localizedDescription)")
    }
}

// MARK: - Mock Budget Monitoring Service

@MainActor
class MockBudgetMonitoringService: @preconcurrency BudgetMonitoringServiceProtocol {
    var checkBudgetStatusCalled = false
    var processTransactionCalled = false
    var checkAndPerformRolloverCalled = false
    
    var mockBudgetStatus: BudgetStatus?
    var mockAlerts: [BudgetAlert] = []
    var shouldThrowError = false
    
    private let alertsSubject = PassthroughSubject<[BudgetAlert], Never>()
    var alertsPublisher: AnyPublisher<[BudgetAlert], Never> {
        alertsSubject.eraseToAnyPublisher()
    }
    
    func getBudgetStatus() async throws -> BudgetStatus? {
        checkBudgetStatusCalled = true
        
        if shouldThrowError {
            throw NSError(domain: "MockBudgetMonitoringService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        
        return mockBudgetStatus
    }
    
    func processTransaction(_ transaction: Transaction) async throws {
        processTransactionCalled = true
        
        if shouldThrowError {
            throw NSError(domain: "MockBudgetMonitoringService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
    }
    
    func checkAndPerformRollover() async throws {
        checkAndPerformRolloverCalled = true
        
        if shouldThrowError {
            throw NSError(domain: "MockBudgetMonitoringService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
    }
    
    func publishAlerts(_ alerts: [BudgetAlert]) {
        alertsSubject.send(alerts)
    }
}

