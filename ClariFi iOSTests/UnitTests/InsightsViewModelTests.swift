//
//  InsightsViewModelTests.swift
//  ClariFi_iOS Tests
//
//  Unit tests for InsightsViewModel using DI container and mocks
//

import XCTest
import CoreData
@testable import ClariFi_iOS

@MainActor
final class InsightsViewModelTests: XCTestCase {
    
    var container: DIContainer!
    var viewModel: InsightsViewModel!
    var mockInsightsEngine: MockInsightsEngine!
    var mockTransactionRepository: MockTransactionRepository!
    var mockBudgetRepository: MockBudgetRepository!
    var context: NSManagedObjectContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory Core Data context
        let persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
        
        // Create mock dependencies
        mockInsightsEngine = MockInsightsEngine()
        mockTransactionRepository = MockTransactionRepository()
        mockBudgetRepository = MockBudgetRepository()
        
        // Create test container with mocks
        container = AppDIContainer()
        container.registerSingleton(InsightsEngineProtocol.self) { _ in
            self.mockInsightsEngine
        }
        container.registerSingleton(TransactionRepository.self) { _ in
            self.mockTransactionRepository
        }
        container.registerSingleton(BudgetRepository.self) { _ in
            self.mockBudgetRepository
        }
        
        // Create ViewModel with injected dependencies
        viewModel = InsightsViewModel(
            insightsEngine: mockInsightsEngine,
            transactionRepository: mockTransactionRepository,
            budgetRepository: mockBudgetRepository,
            context: context
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockInsightsEngine = nil
        mockTransactionRepository = nil
        mockBudgetRepository = nil
        container = nil
        context = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertTrue(viewModel.insights.isEmpty)
        XCTAssertTrue(viewModel.dismissedInsightIds.isEmpty)
        XCTAssertNil(viewModel.selectedInsight)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Load Insights Tests
    
    func testLoadInsightsSuccess() async {
        // Arrange
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.merchant = "Test Merchant"
        transaction.amount = NSDecimalNumber(value: 100)
        transaction.category = "Food"
        transaction.date = Date()
        mockTransactionRepository.mockTransactions = [transaction]
        
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.isActive = true
        mockBudgetRepository.mockActiveBudget = budget
        
        let insight = Insight(
            id: UUID(),
            type: .spendingPattern,
            title: "High spending on Food",
            message: "You spent $100 on food this week",
            priority: .medium,
            impactScore: 0.7,
            actionable: true,
            actionTitle: "Review spending",
            relatedCategory: "Food",
            relatedTransactions: [transaction.id!],
            createdAt: Date()
        )
        mockInsightsEngine.mockInsights = [insight]
        
        // Act
        await viewModel.loadInsights()
        
        // Assert
        XCTAssertTrue(mockTransactionRepository.fetchAllCalled)
        XCTAssertTrue(mockBudgetRepository.fetchActiveBudgetCalled)
        XCTAssertTrue(mockInsightsEngine.generateInsightsCalled)
        XCTAssertEqual(viewModel.insights.count, 1)
        XCTAssertEqual(viewModel.insights.first?.title, "High spending on Food")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    func testLoadInsightsError() async {
        // Arrange
        mockTransactionRepository.shouldThrowError = true
        
        // Act
        await viewModel.loadInsights()
        
        // Assert
        XCTAssertTrue(mockTransactionRepository.fetchAllCalled)
        XCTAssertTrue(viewModel.insights.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
    }
    
    func testLoadInsightsFiltersDismissed() async {
        // Arrange
        let insight1 = Insight(
            id: UUID(),
            type: .spendingPattern,
            title: "Insight 1",
            message: "Message 1",
            priority: .medium,
            impactScore: 0.7,
            actionable: true,
            actionTitle: nil,
            relatedCategory: nil,
            relatedTransactions: [],
            createdAt: Date()
        )
        let insight2 = Insight(
            id: UUID(),
            type: .budgetAlert,
            title: "Insight 2",
            message: "Message 2",
            priority: .high,
            impactScore: 0.8,
            actionable: true,
            actionTitle: nil,
            relatedCategory: nil,
            relatedTransactions: [],
            createdAt: Date()
        )
        
        mockInsightsEngine.mockInsights = [insight1, insight2]
        mockTransactionRepository.mockTransactions = []
        
        // Dismiss insight1
        viewModel.dismissedInsightIds.insert(insight1.id)
        
        // Act
        await viewModel.loadInsights()
        
        // Assert
        XCTAssertEqual(viewModel.insights.count, 1)
        XCTAssertEqual(viewModel.insights.first?.id, insight2.id)
    }
    
    // MARK: - Dismiss Insight Tests
    
    func testDismissInsight() {
        // Arrange
        let insight = Insight(
            id: UUID(),
            type: .spendingPattern,
            title: "Test Insight",
            message: "Test Message",
            priority: .medium,
            impactScore: 0.7,
            actionable: true,
            actionTitle: nil,
            relatedCategory: nil,
            relatedTransactions: [],
            createdAt: Date()
        )
        viewModel.insights = [insight]
        
        // Act
        viewModel.dismissInsight(insight)
        
        // Assert
        XCTAssertTrue(viewModel.dismissedInsightIds.contains(insight.id))
        XCTAssertTrue(viewModel.insights.isEmpty)
    }
    
    // MARK: - Select Insight Tests
    
    func testSelectInsight() {
        // Arrange
        let insight = Insight(
            id: UUID(),
            type: .spendingPattern,
            title: "Test Insight",
            message: "Test Message",
            priority: .medium,
            impactScore: 0.7,
            actionable: true,
            actionTitle: nil,
            relatedCategory: nil,
            relatedTransactions: [],
            createdAt: Date()
        )
        
        // Act
        viewModel.selectInsight(insight)
        
        // Assert
        XCTAssertNotNil(viewModel.selectedInsight)
        XCTAssertEqual(viewModel.selectedInsight?.id, insight.id)
    }
    
    func testClearSelectedInsight() {
        // Arrange
        let insight = Insight(
            id: UUID(),
            type: .spendingPattern,
            title: "Test Insight",
            message: "Test Message",
            priority: .medium,
            impactScore: 0.7,
            actionable: true,
            actionTitle: nil,
            relatedCategory: nil,
            relatedTransactions: [],
            createdAt: Date()
        )
        viewModel.selectedInsight = insight
        
        // Act
        viewModel.clearSelectedInsight()
        
        // Assert
        XCTAssertNil(viewModel.selectedInsight)
    }
    
    // MARK: - Filter Tests
    
    func testGetInsightsByPriority() async {
        // Arrange
        let highPriorityInsight = Insight(
            id: UUID(),
            type: .budgetAlert,
            title: "High Priority",
            message: "Message",
            priority: .high,
            impactScore: 0.9,
            actionable: true,
            actionTitle: nil,
            relatedCategory: nil,
            relatedTransactions: [],
            createdAt: Date()
        )
        let mediumPriorityInsight = Insight(
            id: UUID(),
            type: .spendingPattern,
            title: "Medium Priority",
            message: "Message",
            priority: .medium,
            impactScore: 0.6,
            actionable: true,
            actionTitle: nil,
            relatedCategory: nil,
            relatedTransactions: [],
            createdAt: Date()
        )
        
        mockInsightsEngine.mockInsights = [highPriorityInsight, mediumPriorityInsight]
        mockTransactionRepository.mockTransactions = []
        
        await viewModel.loadInsights()
        
        // Act
        let highPriorityInsights = viewModel.getInsightsByPriority(.high)
        let mediumPriorityInsights = viewModel.getInsightsByPriority(.medium)
        
        // Assert
        XCTAssertEqual(highPriorityInsights.count, 1)
        XCTAssertEqual(highPriorityInsights.first?.title, "High Priority")
        XCTAssertEqual(mediumPriorityInsights.count, 1)
        XCTAssertEqual(mediumPriorityInsights.first?.title, "Medium Priority")
    }
    
    func testGetInsightsByType() async {
        // Arrange
        let budgetAlertInsight = Insight(
            id: UUID(),
            type: .budgetAlert,
            title: "Budget Alert",
            message: "Message",
            priority: .high,
            impactScore: 0.9,
            actionable: true,
            actionTitle: nil,
            relatedCategory: nil,
            relatedTransactions: [],
            createdAt: Date()
        )
        let spendingPatternInsight = Insight(
            id: UUID(),
            type: .spendingPattern,
            title: "Spending Pattern",
            message: "Message",
            priority: .medium,
            impactScore: 0.6,
            actionable: true,
            actionTitle: nil,
            relatedCategory: nil,
            relatedTransactions: [],
            createdAt: Date()
        )
        
        mockInsightsEngine.mockInsights = [budgetAlertInsight, spendingPatternInsight]
        mockTransactionRepository.mockTransactions = []
        
        await viewModel.loadInsights()
        
        // Act
        let budgetAlerts = viewModel.getInsightsByType(.budgetAlert)
        let spendingPatterns = viewModel.getInsightsByType(.spendingPattern)
        
        // Assert
        XCTAssertEqual(budgetAlerts.count, 1)
        XCTAssertEqual(budgetAlerts.first?.title, "Budget Alert")
        XCTAssertEqual(spendingPatterns.count, 1)
        XCTAssertEqual(spendingPatterns.first?.title, "Spending Pattern")
    }
    
    // MARK: - Refresh Tests
    
    func testRefreshInsights() async {
        // Arrange
        let insight = Insight(
            id: UUID(),
            type: .spendingPattern,
            title: "Test Insight",
            message: "Test Message",
            priority: .medium,
            impactScore: 0.7,
            actionable: true,
            actionTitle: nil,
            relatedCategory: nil,
            relatedTransactions: [],
            createdAt: Date()
        )
        mockInsightsEngine.mockInsights = [insight]
        mockTransactionRepository.mockTransactions = []
        
        // Act
        await viewModel.refreshInsights()
        
        // Assert
        XCTAssertTrue(mockInsightsEngine.generateInsightsCalled)
        XCTAssertEqual(viewModel.insights.count, 1)
    }
}
