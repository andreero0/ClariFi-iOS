//
//  InsightsEngineTests.swift
//  ClariFi_iOS Tests
//
//  Tests for InsightsEngine service with mock dependencies
//

import XCTest
import CoreData
@testable import ClariFi_iOS

@MainActor
final class InsightsEngineTests: XCTestCase {
    
    var sut: InsightsEngine!
    var context: NSManagedObjectContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory Core Data stack for testing
        let persistenceController = PersistenceController.preview
        context = persistenceController.container.viewContext
        
        sut = InsightsEngine(context: context)
    }
    
    override func tearDown() async throws {
        sut = nil
        context = nil
        try await super.tearDown()
    }
    
    // MARK: - Spending Trends Tests
    
    func testGenerateSpendingTrends_WithTransactions_ReturnsCorrectTotals() async throws {
        // Arrange
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: startDate)!
        let period = DateInterval(start: startDate, end: endDate)
        
        let transactions = createTestTransactions(count: 10, startDate: startDate, endDate: endDate)
        
        // Act
        let trends = await sut.generateSpendingTrends(for: period, transactions: transactions)
        
        // Assert
        XCTAssertEqual(trends.period, period)
        XCTAssertGreaterThan(trends.totalSpending, 0)
        XCTAssertGreaterThan(trends.averageDaily, 0)
        XCTAssertFalse(trends.categoryBreakdown.isEmpty)
        XCTAssertFalse(trends.topMerchants.isEmpty)
    }
    
    func testGenerateSpendingTrends_WithNoTransactions_ReturnsZeroTotals() async throws {
        // Arrange
        let period = DateInterval(start: Date(), duration: 2592000) // 30 days
        let transactions: [Transaction] = []
        
        // Act
        let trends = await sut.generateSpendingTrends(for: period, transactions: transactions)
        
        // Assert
        XCTAssertEqual(trends.totalSpending, 0)
        XCTAssertEqual(trends.averageDaily, 0)
        XCTAssertTrue(trends.categoryBreakdown.isEmpty)
        XCTAssertTrue(trends.topMerchants.isEmpty)
    }
    
    func testGenerateSpendingTrends_WithPreviousPeriod_CalculatesComparison() async throws {
        // Arrange
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: now)!
        
        let currentPeriod = DateInterval(start: thirtyDaysAgo, end: now)
        
        // Create transactions for both periods
        let currentTransactions = createTestTransactions(count: 5, startDate: thirtyDaysAgo, endDate: now, baseAmount: 100)
        let previousTransactions = createTestTransactions(count: 5, startDate: sixtyDaysAgo, endDate: thirtyDaysAgo, baseAmount: 50)
        
        let allTransactions = currentTransactions + previousTransactions
        
        // Act
        let trends = await sut.generateSpendingTrends(for: currentPeriod, transactions: allTransactions)
        
        // Assert
        XCTAssertNotNil(trends.comparisonToPrevious)
        XCTAssertGreaterThan(trends.comparisonToPrevious!, 0) // Should show increase
    }
    
    // MARK: - Insight Generation Tests
    
    func testGenerateInsights_WithIncreasedSpending_ReturnsSpendingTrendInsight() async throws {
        // Arrange
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: now)!
        
        // Recent spending is higher
        let recentTransactions = createTestTransactions(count: 10, startDate: thirtyDaysAgo, endDate: now, baseAmount: 200)
        let oldTransactions = createTestTransactions(count: 10, startDate: sixtyDaysAgo, endDate: thirtyDaysAgo, baseAmount: 100)
        
        let allTransactions = recentTransactions + oldTransactions
        
        // Act
        let insights = await sut.generateInsights(for: allTransactions, budget: nil)
        
        // Assert
        XCTAssertFalse(insights.isEmpty)
        let spendingTrendInsights = insights.filter { $0.type == .spendingTrend }
        XCTAssertFalse(spendingTrendInsights.isEmpty)
        XCTAssertTrue(spendingTrendInsights.first?.title.contains("Increased") ?? false)
    }
    
    func testGenerateInsights_WithBudget_ReturnsBudgetAlerts() async throws {
        // Arrange
        let budget = createTestBudget()
        let category = createTestBudgetCategory(budget: budget, name: "Food", budgeted: 100)
        
        // Create transactions that exceed budget
        let transactions = createTestTransactions(count: 5, category: "Food", baseAmount: 30)
        
        // Act
        let insights = await sut.generateInsights(for: transactions, budget: budget)
        
        // Assert
        let budgetAlerts = insights.filter { $0.type == .budgetAlert }
        XCTAssertFalse(budgetAlerts.isEmpty)
    }
    
    func testGenerateInsights_WithRecurringCharges_ReturnsRecurringInsights() async throws {
        // Arrange
        let transactions = createRecurringTransactions(merchant: "Netflix", count: 4, amount: 15.99)
        
        // Act
        let insights = await sut.generateInsights(for: transactions, budget: nil)
        
        // Assert
        let recurringInsights = insights.filter { $0.type == .recurringCharge }
        XCTAssertFalse(recurringInsights.isEmpty)
    }
    
    func testGenerateInsights_WithUnusualSpending_ReturnsUnusualSpendingInsight() async throws {
        // Arrange
        // Create normal transactions
        var transactions = createTestTransactions(count: 30, baseAmount: 50)
        
        // Add an unusually large transaction
        let largeTransaction = createTestTransaction(merchant: "Large Purchase", amount: 500, date: Date())
        transactions.append(largeTransaction)
        
        // Act
        let insights = await sut.generateInsights(for: transactions, budget: nil)
        
        // Assert
        let unusualInsights = insights.filter { $0.type == .unusualSpending }
        XCTAssertFalse(unusualInsights.isEmpty)
    }
    
    // MARK: - Insight Prioritization Tests
    
    func testPrioritizeInsights_SortsByImpactScore() {
        // Arrange
        let lowPriorityInsight = createInsight(priority: .low, confidence: 0.5, relevance: 0.5)
        let highPriorityInsight = createInsight(priority: .high, confidence: 0.9, relevance: 0.9)
        let mediumPriorityInsight = createInsight(priority: .medium, confidence: 0.7, relevance: 0.7)
        
        let insights = [lowPriorityInsight, highPriorityInsight, mediumPriorityInsight]
        
        // Act
        let prioritized = sut.prioritizeInsights(insights)
        
        // Assert
        XCTAssertEqual(prioritized.count, 3)
        XCTAssertEqual(prioritized[0].priority, .high)
        XCTAssertEqual(prioritized[1].priority, .medium)
        XCTAssertEqual(prioritized[2].priority, .low)
    }
    
    func testPrioritizeInsights_WithEqualPriority_SortsByConfidence() {
        // Arrange
        let lowConfidence = createInsight(priority: .medium, confidence: 0.5, relevance: 0.7)
        let highConfidence = createInsight(priority: .medium, confidence: 0.9, relevance: 0.7)
        
        let insights = [lowConfidence, highConfidence]
        
        // Act
        let prioritized = sut.prioritizeInsights(insights)
        
        // Assert
        XCTAssertEqual(prioritized[0].confidence, 0.9)
        XCTAssertEqual(prioritized[1].confidence, 0.5)
    }
    
    // MARK: - Helper Methods
    
    private func createTestTransactions(count: Int, startDate: Date = Date(), endDate: Date = Date(), baseAmount: Decimal = 100, category: String = "Food") -> [Transaction] {
        var transactions: [Transaction] = []
        let timeInterval = endDate.timeIntervalSince(startDate) / Double(count)
        
        for i in 0..<count {
            let date = startDate.addingTimeInterval(timeInterval * Double(i))
            let transaction = createTestTransaction(
                merchant: "Merchant \(i)",
                amount: baseAmount + Decimal(i),
                date: date,
                category: category
            )
            transactions.append(transaction)
        }
        
        return transactions
    }
    
    private func createRecurringTransactions(merchant: String, count: Int, amount: Decimal) -> [Transaction] {
        var transactions: [Transaction] = []
        let now = Date()
        
        for i in 0..<count {
            let date = Calendar.current.date(byAdding: .month, value: -i, to: now)!
            let transaction = createTestTransaction(merchant: merchant, amount: amount, date: date)
            transactions.append(transaction)
        }
        
        return transactions
    }
    
    private func createTestTransaction(merchant: String, amount: Decimal, date: Date, category: String = "Other") -> Transaction {
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.merchant = merchant
        transaction.amount = NSDecimalNumber(decimal: amount)
        transaction.date = date
        transaction.category = category
        transaction.transactionDescription = "Test transaction"
        return transaction
    }
    
    private func createTestBudget() -> Budget {
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.isActive = true
        budget.startDate = Date()
        return budget
    }
    
    private func createTestBudgetCategory(budget: Budget, name: String, budgeted: Decimal) -> BudgetCategory {
        let category = BudgetCategory(context: context)
        category.id = UUID()
        category.name = name
        category.budgetedAmount = NSDecimalNumber(decimal: budgeted)
        category.alertThreshold = 0.8
        category.budget = budget
        return category
    }
    
    private func createInsight(priority: InsightPriority, confidence: Float, relevance: Float) -> Insight {
        return Insight(
            id: UUID(),
            type: .spendingTrend,
            priority: priority,
            title: "Test Insight",
            description: "Test description",
            explanation: "Test explanation",
            actionItems: [],
            confidence: confidence,
            dataSourceCount: 10,
            generatedAt: Date(),
            relevanceScore: relevance
        )
    }
}
