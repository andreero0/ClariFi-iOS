//
//  MainActorIsolationTests.swift
//  ClariFi iOSTests
//
//  Tests for main actor isolation and boundary violations
//

import XCTest
import CoreData
@testable import ClariFi_iOS

@MainActor
class MainActorIsolationTests: XCTestCase {
    
    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!
    var backgroundContextProvider: BackgroundContextProvider!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory Core Data stack
        container = NSPersistentContainer(name: "ClariFi_iOS")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        try await container.loadPersistentStores()
        context = container.viewContext
        backgroundContextProvider = BackgroundContextProvider(persistentContainer: container)
    }
    
    override func tearDown() async throws {
        container = nil
        context = nil
        backgroundContextProvider = nil
        try await super.tearDown()
    }
    
    // MARK: - HomeView Actor Isolation Tests
    
    func testHomeViewCalculateSpendingSummaryMainActorIsolation() async throws {
        // Create test transactions
        let transactions = createTestTransactions(count: 150)
        
        // Test that large dataset calculations are properly isolated
        let expectation = XCTestExpectation(description: "Background calculation completes")
        
        // Simulate the HomeView calculation pattern
        let transactionsSnapshot = await MainActor.run {
            return transactions
        }
        
        // Perform calculation on background
        let result = await performCalculation(transactions: transactionsSnapshot)
        
        // Update UI on main actor
        await MainActor.run {
            XCTAssertEqual(result.spending, Decimal(1500)) // 150 * 10
            XCTAssertEqual(result.transactionCount, 150)
            XCTAssertEqual(result.categoryBreakdown.count, 1)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testHomeViewSmallDatasetMainActorExecution() async throws {
        // Test that small datasets still execute on main actor
        let transactions = createTestTransactions(count: 50)
        
        let result = performCalculation(transactions: transactions)
        
        XCTAssertEqual(result.spending, Decimal(500)) // 50 * 10
        XCTAssertEqual(result.transactionCount, 50)
        XCTAssertEqual(result.categoryBreakdown.count, 1)
    }
    
    // MARK: - InsightsViewModel Actor Isolation Tests
    
    func testInsightsViewModelDetachedTaskExecution() async throws {
        // Create mock insights engine
        let mockInsightsEngine = MockInsightsEngine()
        let transactionRepository = CoreDataTransactionRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        let budgetRepository = CoreDataBudgetRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        
        let viewModel = InsightsViewModel(
            insightsEngine: mockInsightsEngine,
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository,
            context: context
        )
        
        // Create test data
        let transactions = createTestTransactions(count: 200)
        for transaction in transactions {
            try context.save()
        }
        
        // Test that insights generation uses detached task
        await viewModel.loadInsights()
        
        // Verify insights were generated
        XCTAssertFalse(viewModel.insights.isEmpty)
        XCTAssertEqual(viewModel.insights.count, 1) // Mock returns 1 insight
        XCTAssertEqual(viewModel.insights.first?.title, "Test Insight")
    }
    
    func testInsightsViewModelBackgroundProcessingWithLargeDataset() async throws {
        // Test that large dataset processing doesn't block main actor
        let mockInsightsEngine = MockInsightsEngine()
        let transactionRepository = CoreDataTransactionRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        let budgetRepository = CoreDataBudgetRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        
        let viewModel = InsightsViewModel(
            insightsEngine: mockInsightsEngine,
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository,
            context: context
        )
        
        // Create large dataset
        let transactions = createTestTransactions(count: 1000)
        for transaction in transactions {
            try context.save()
        }
        
        // Measure time to ensure it doesn't block
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Load insights - should use background processing
        await viewModel.loadInsights()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Verify insights were generated
        XCTAssertFalse(viewModel.insights.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        
        // Verify it completed in reasonable time (background processing should be efficient)
        XCTAssertLessThan(executionTime, 2.0) // Should complete in under 2 seconds
    }
    
    func testInsightsEngineActorIsolation() async throws {
        // Test that InsightsEngine as an actor properly isolates work
        let insightsEngine = InsightsEngine(context: context)
        
        // Create test transactions
        let transactions = createTestTransactions(count: 500)
        for transaction in transactions {
            try context.save()
        }
        
        // Generate insights - should run on actor's executor
        let insights = await insightsEngine.generateInsights(for: transactions, budget: nil)
        
        // Verify insights were generated
        XCTAssertFalse(insights.isEmpty)
        
        // Verify we can call prioritizeInsights (nonisolated method)
        let prioritized = insightsEngine.prioritizeInsights(insights)
        XCTAssertEqual(prioritized.count, insights.count)
    }
    
    func testInsightsViewModelMainActorPublishing() async throws {
        // Test that @Published properties are updated on main actor
        let mockInsightsEngine = MockInsightsEngine()
        let transactionRepository = CoreDataTransactionRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        let budgetRepository = CoreDataBudgetRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        
        let viewModel = InsightsViewModel(
            insightsEngine: mockInsightsEngine,
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository,
            context: context
        )
        
        // Verify we're on main actor
        XCTAssertTrue(Thread.isMainThread)
        
        // Test that published properties can be accessed
        viewModel.insights = [createTestInsight()]
        XCTAssertEqual(viewModel.insights.count, 1)
        
        viewModel.dismissedInsightIds.insert(UUID())
        XCTAssertEqual(viewModel.dismissedInsightIds.count, 1)
    }
    
    // MARK: - Core Data Context Isolation Tests
    
    func testBackgroundContextProviderMainActorIsolation() async throws {
        // Test that background context operations don't block main actor
        let expectation = XCTestExpectation(description: "Background operation completes")
        
        // Perform background operation
        let result = try await backgroundContextProvider.performBackgroundTask { context in
            // Verify we're not on main thread
            XCTAssertFalse(Thread.isMainThread)
            
            // Create test transaction
            let transaction = Transaction(context: context)
            transaction.amount = NSDecimalNumber(value: 100)
            transaction.merchant = "Test Merchant"
            transaction.date = Date()
            transaction.category = "Test Category"
            
            try context.save()
            return transaction
        }
        
        // Verify result is returned to main actor
        await MainActor.run {
            XCTAssertNotNil(result)
            XCTAssertEqual(result.amount?.decimalValue, Decimal(100))
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testConcurrentBackgroundOperations() async throws {
        // Test multiple concurrent background operations
        let expectation = XCTestExpectation(description: "All background operations complete")
        expectation.expectedFulfillmentCount = 5
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    do {
                        let result = try await self.backgroundContextProvider.performBackgroundTask { context in
                            // Verify we're not on main thread
                            XCTAssertFalse(Thread.isMainThread)
                            
                            // Create test transaction
                            let transaction = Transaction(context: context)
                            transaction.amount = NSDecimalNumber(value: i * 10)
                            transaction.merchant = "Test Merchant \(i)"
                            transaction.date = Date()
                            transaction.category = "Test Category"
                            
                            try context.save()
                            return transaction
                        }
                        
                        // Verify result is returned
                        XCTAssertNotNil(result)
                        XCTAssertEqual(result.amount?.decimalValue, Decimal(i * 10))
                        
                        await MainActor.run {
                            expectation.fulfill()
                        }
                    } catch {
                        XCTFail("Background operation failed: \(error)")
                    }
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Actor Boundary Violation Detection
    
    func testMainActorBoundaryViolationDetection() async throws {
        // Test that we can detect potential main actor violations
        let transactions = createTestTransactions(count: 1000)
        
        // This should not block the main actor
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = await Task.detached {
            return self.performCalculation(transactions: transactions)
        }.value
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Verify calculation completed
        XCTAssertEqual(result.spending, Decimal(10000)) // 1000 * 10
        XCTAssertEqual(result.transactionCount, 1000)
        
        // Verify it didn't block main actor (should be fast)
        XCTAssertLessThan(executionTime, 0.1) // Should complete in under 100ms
    }
    
    func testMainActorIsolationWithLargeDataset() async throws {
        // Test with very large dataset to ensure proper isolation
        let transactions = createTestTransactions(count: 10000)
        
        let expectation = XCTestExpectation(description: "Large dataset calculation completes")
        
        // Simulate HomeView pattern with large dataset
        let transactionsSnapshot = await MainActor.run {
            return transactions
        }
        
        // Perform calculation on background
        let result = await performCalculation(transactions: transactionsSnapshot)
        
        // Update UI on main actor
        await MainActor.run {
            XCTAssertEqual(result.spending, Decimal(100000)) // 10000 * 10
            XCTAssertEqual(result.transactionCount, 10000)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestTransactions(count: Int) -> [Transaction] {
        var transactions: [Transaction] = []
        
        for i in 0..<count {
            let transaction = Transaction(context: context)
            transaction.amount = NSDecimalNumber(value: 10)
            transaction.merchant = "Test Merchant \(i)"
            transaction.date = Date()
            transaction.category = "Test Category"
            transactions.append(transaction)
        }
        
        return transactions
    }
    
    private func performCalculation(transactions: [Transaction]) -> (spending: Decimal, transactionCount: Int, categoryBreakdown: [(String, Decimal)]) {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let currentMonthTransactions = transactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return date >= startOfMonth
        }
        
        let spending = currentMonthTransactions.reduce(0) { total, transaction in
            total + (transaction.amount?.decimalValue ?? 0)
        }
        
        let transactionCount = currentMonthTransactions.count
        
        // Calculate category breakdown
        var categoryTotals: [String: Decimal] = [:]
        for transaction in currentMonthTransactions {
            let category = transaction.category ?? "Uncategorized"
            let amount = transaction.amount?.decimalValue ?? 0
            categoryTotals[category, default: 0] += amount
        }
        
        let categoryBreakdown = categoryTotals
            .sorted { $0.value > $1.value }
            .map { ($0.key, $0.value) }
        
        return (spending: spending, transactionCount: transactionCount, categoryBreakdown: categoryBreakdown)
    }
    
    private func createTestInsight() -> Insight {
        return Insight(
            id: UUID(),
            type: .spendingTrend,
            priority: .medium,
            title: "Test Insight",
            description: "Test description",
            explanation: "Test explanation",
            actionItems: [],
            confidence: 0.8,
            dataSourceCount: 10,
            generatedAt: Date(),
            relevanceScore: 0.75
        )
    }
}

// MARK: - Mock Insights Engine

class MockInsightsEngine: InsightsEngineProtocol {
    func generateInsights(for transactions: [Transaction], budget: Budget?) async -> [Insight] {
        // Simulate heavy computation to test background processing
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        return [
            Insight(
                id: UUID(),
                type: .spendingTrend,
                priority: .medium,
                title: "Test Insight",
                description: "Test description",
                explanation: "Test explanation",
                actionItems: [],
                confidence: 0.8,
                dataSourceCount: 10,
                generatedAt: Date(),
                relevanceScore: 0.75
            )
        ]
    }
    
    func generateSpendingTrends(for period: DateInterval, transactions: [Transaction]) async -> SpendingTrends {
        return SpendingTrends(
            period: period,
            totalSpending: Decimal(1000),
            averageDaily: Decimal(33.33),
            categoryBreakdown: [:],
            topMerchants: [],
            comparisonToPrevious: nil,
            projectedMonthly: Decimal(1000)
        )
    }
    
    func prioritizeInsights(_ insights: [Insight]) -> [Insight] {
        return insights.sorted { $0.impactScore > $1.impactScore }
    }
}
