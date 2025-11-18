//
//  BudgetMonitoringServiceTests.swift
//  ClariFi_iOS Tests
//
//  Tests for BudgetMonitoringService with mock dependencies
//

import XCTest
import CoreData
import Combine
@testable import ClariFi_iOS

@MainActor
final class BudgetMonitoringServiceTests: XCTestCase {
    
    var sut: BudgetMonitoringService!
    var context: NSManagedObjectContext!
    var mockBudgetRepository: MockBudgetRepository!
    var mockBudgetCategoryRepository: MockBudgetCategoryRepository!
    var mockTransactionRepository: MockTransactionRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory Core Data stack for testing
        let persistenceController = PersistenceController.preview
        context = persistenceController.container.viewContext
        
        mockBudgetRepository = MockBudgetRepository()
        mockBudgetCategoryRepository = MockBudgetCategoryRepository()
        mockTransactionRepository = MockTransactionRepository()
        cancellables = Set<AnyCancellable>()
        
        sut = BudgetMonitoringService(
            budgetRepository: mockBudgetRepository,
            budgetCategoryRepository: mockBudgetCategoryRepository,
            transactionRepository: mockTransactionRepository,
            context: context
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        context = nil
        mockBudgetRepository = nil
        mockBudgetCategoryRepository = nil
        mockTransactionRepository = nil
        cancellables = nil
        try await super.tearDown()
    }
    
    // MARK: - Budget Status Tests
    
    func testGetBudgetStatus_WithNoBudget_ReturnsNil() async throws {
        // Arrange
        mockBudgetRepository.mockActiveBudget = nil
        
        // Act
        let status = try await sut.getBudgetStatus()
        
        // Assert
        XCTAssertNil(status)
    }
    
    func testGetBudgetStatus_WithBudget_ReturnsStatus() async throws {
        // Arrange
        let budget = createTestBudget()
        let category = createTestBudgetCategory(budget: budget, name: "Food", budgeted: 500)
        
        mockBudgetRepository.mockActiveBudget = budget
        mockBudgetCategoryRepository.mockCategories = [category]
        mockTransactionRepository.mockTransactions = []
        
        // Act
        let status = try await sut.getBudgetStatus()
        
        // Assert
        XCTAssertNotNil(status)
        XCTAssertEqual(status?.budget.id, budget.id)
        XCTAssertEqual(status?.categoryStatuses.count, 1)
        XCTAssertEqual(status?.totalBudgeted, 500)
        XCTAssertEqual(status?.totalSpent, 0)
    }
    
    func testGetBudgetStatus_WithTransactions_CalculatesSpending() async throws {
        // Arrange
        let budget = createTestBudget()
        let category = createTestBudgetCategory(budget: budget, name: "Food", budgeted: 500)
        
        let transactions = [
            createTestTransaction(category: "Food", amount: 100),
            createTestTransaction(category: "Food", amount: 150),
            createTestTransaction(category: "Food", amount: 50)
        ]
        
        mockBudgetRepository.mockActiveBudget = budget
        mockBudgetCategoryRepository.mockCategories = [category]
        mockTransactionRepository.mockTransactions = transactions
        
        // Act
        let status = try await sut.getBudgetStatus()
        
        // Assert
        XCTAssertNotNil(status)
        XCTAssertEqual(status?.totalSpent, 300)
        XCTAssertEqual(status?.categoryStatuses.first?.spent, 300)
        XCTAssertEqual(status?.categoryStatuses.first?.remaining, 200)
    }
    
    func testGetBudgetStatus_WithOverBudget_GeneratesAlert() async throws {
        // Arrange
        let budget = createTestBudget()
        let category = createTestBudgetCategory(budget: budget, name: "Food", budgeted: 100)
        
        let transactions = [
            createTestTransaction(category: "Food", amount: 150)
        ]
        
        mockBudgetRepository.mockActiveBudget = budget
        mockBudgetCategoryRepository.mockCategories = [category]
        mockTransactionRepository.mockTransactions = transactions
        
        // Act
        let status = try await sut.getBudgetStatus()
        
        // Assert
        XCTAssertNotNil(status)
        XCTAssertFalse(status?.alerts.isEmpty ?? true)
        XCTAssertEqual(status?.alerts.first?.type, .exceeded)
        XCTAssertEqual(status?.alerts.first?.severity, .critical)
        XCTAssertTrue(status?.categoryStatuses.first?.isOverBudget ?? false)
    }
    
    func testGetBudgetStatus_NearThreshold_GeneratesWarning() async throws {
        // Arrange
        let budget = createTestBudget()
        let category = createTestBudgetCategory(budget: budget, name: "Food", budgeted: 100, threshold: 0.8)
        
        let transactions = [
            createTestTransaction(category: "Food", amount: 85)
        ]
        
        mockBudgetRepository.mockActiveBudget = budget
        mockBudgetCategoryRepository.mockCategories = [category]
        mockTransactionRepository.mockTransactions = transactions
        
        // Act
        let status = try await sut.getBudgetStatus()
        
        // Assert
        XCTAssertNotNil(status)
        XCTAssertFalse(status?.alerts.isEmpty ?? true)
        XCTAssertEqual(status?.alerts.first?.type, .approaching)
        XCTAssertEqual(status?.alerts.first?.severity, .warning)
        XCTAssertTrue(status?.categoryStatuses.first?.isNearThreshold ?? false)
    }
    
    func testGetBudgetStatus_PublishesAlerts() async throws {
        // Arrange
        let budget = createTestBudget()
        let category = createTestBudgetCategory(budget: budget, name: "Food", budgeted: 100)
        
        let transactions = [
            createTestTransaction(category: "Food", amount: 150)
        ]
        
        mockBudgetRepository.mockActiveBudget = budget
        mockBudgetCategoryRepository.mockCategories = [category]
        mockTransactionRepository.mockTransactions = transactions
        
        let expectation = XCTestExpectation(description: "Alerts published")
        var receivedAlerts: [BudgetAlert] = []
        
        sut.alertsPublisher
            .sink { alerts in
                receivedAlerts = alerts
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Act
        _ = try await sut.getBudgetStatus()
        
        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(receivedAlerts.isEmpty)
    }
    
    // MARK: - Transaction Processing Tests
    
    func testProcessTransaction_WithNoBudget_DoesNothing() async throws {
        // Arrange
        mockBudgetRepository.mockActiveBudget = nil
        let transaction = createTestTransaction(category: "Food", amount: 50)
        
        // Act
        try await sut.processTransaction(transaction)
        
        // Assert
        XCTAssertFalse(mockBudgetCategoryRepository.updateSpentAmountCalled)
    }
    
    func testProcessTransaction_InCurrentPeriod_UpdatesSpending() async throws {
        // Arrange
        let budget = createTestBudget()
        let category = createTestBudgetCategory(budget: budget, name: "Food", budgeted: 500)
        category.spentAmount = NSDecimalNumber(value: 100)
        
        mockBudgetRepository.mockActiveBudget = budget
        mockBudgetCategoryRepository.mockCategory = category
        
        let transaction = createTestTransaction(category: "Food", amount: 50, date: Date())
        
        // Act
        try await sut.processTransaction(transaction)
        
        // Assert
        XCTAssertTrue(mockBudgetCategoryRepository.updateSpentAmountCalled)
        XCTAssertEqual(mockBudgetCategoryRepository.lastUpdatedAmount, NSDecimalNumber(value: 150))
    }
    
    func testProcessTransaction_OutsidePeriod_DoesNotUpdate() async throws {
        // Arrange
        let budget = createTestBudget()
        let category = createTestBudgetCategory(budget: budget, name: "Food", budgeted: 500)
        
        mockBudgetRepository.mockActiveBudget = budget
        mockBudgetCategoryRepository.mockCategory = category
        
        // Transaction from 2 months ago
        let oldDate = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        let transaction = createTestTransaction(category: "Food", amount: 50, date: oldDate)
        
        // Act
        try await sut.processTransaction(transaction)
        
        // Assert
        XCTAssertFalse(mockBudgetCategoryRepository.updateSpentAmountCalled)
    }
    
    func testProcessTransaction_ExceedsBudget_PublishesAlert() async throws {
        // Arrange
        let budget = createTestBudget()
        let category = createTestBudgetCategory(budget: budget, name: "Food", budgeted: 100)
        category.spentAmount = NSDecimalNumber(value: 90)
        
        mockBudgetRepository.mockActiveBudget = budget
        mockBudgetCategoryRepository.mockCategory = category
        
        let expectation = XCTestExpectation(description: "Alert published")
        var receivedAlerts: [BudgetAlert] = []
        
        sut.alertsPublisher
            .sink { alerts in
                receivedAlerts = alerts
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let transaction = createTestTransaction(category: "Food", amount: 20, date: Date())
        
        // Act
        try await sut.processTransaction(transaction)
        
        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(receivedAlerts.isEmpty)
        XCTAssertEqual(receivedAlerts.first?.type, .exceeded)
    }
    
    // MARK: - Rollover Tests
    
    func testCheckAndPerformRollover_BeforePeriodEnd_DoesNothing() async throws {
        // Arrange
        let budget = createTestBudget()
        budget.startDate = Date() // Current period
        
        mockBudgetRepository.mockActiveBudget = budget
        mockBudgetCategoryRepository.mockCategories = []
        
        // Act
        try await sut.checkAndPerformRollover()
        
        // Assert
        XCTAssertFalse(mockBudgetRepository.saveCalled)
    }
    
    func testCheckAndPerformRollover_AfterPeriodEnd_PerformsRollover() async throws {
        // Arrange
        let budget = createTestBudget()
        // Set start date to 2 months ago so period has ended
        budget.startDate = Calendar.current.date(byAdding: .month, value: -2, to: Date())
        
        let category = createTestBudgetCategory(budget: budget, name: "Food", budgeted: 500)
        category.spentAmount = NSDecimalNumber(value: 300)
        category.rolloverEnabled = true
        
        mockBudgetRepository.mockActiveBudget = budget
        mockBudgetCategoryRepository.mockCategories = [category]
        
        // Act
        try await sut.checkAndPerformRollover()
        
        // Assert
        XCTAssertTrue(mockBudgetRepository.saveCalled)
        XCTAssertTrue(mockBudgetCategoryRepository.updateSpentAmountCalled)
    }
    
    func testCheckAndPerformRollover_WithRemainingBudget_RollsOver() async throws {
        // Arrange
        let budget = createTestBudget()
        budget.startDate = Calendar.current.date(byAdding: .month, value: -2, to: Date())
        
        let category = createTestBudgetCategory(budget: budget, name: "Food", budgeted: 500)
        category.spentAmount = NSDecimalNumber(value: 300)
        category.rolloverEnabled = true
        
        mockBudgetRepository.mockActiveBudget = budget
        mockBudgetCategoryRepository.mockCategories = [category]
        
        let expectation = XCTestExpectation(description: "Rollover alert published")
        var receivedAlerts: [BudgetAlert] = []
        
        sut.alertsPublisher
            .sink { alerts in
                receivedAlerts = alerts
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Act
        try await sut.checkAndPerformRollover()
        
        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(receivedAlerts.isEmpty)
        XCTAssertEqual(receivedAlerts.first?.type, .rollover)
    }
    
    func testCheckAndPerformRollover_WithoutRolloverEnabled_DoesNotRollover() async throws {
        // Arrange
        let budget = createTestBudget()
        budget.startDate = Calendar.current.date(byAdding: .month, value: -2, to: Date())
        
        let category = createTestBudgetCategory(budget: budget, name: "Food", budgeted: 500)
        category.spentAmount = NSDecimalNumber(value: 300)
        category.rolloverEnabled = false
        
        mockBudgetRepository.mockActiveBudget = budget
        mockBudgetCategoryRepository.mockCategories = [category]
        
        // Act
        try await sut.checkAndPerformRollover()
        
        // Assert
        // Budget amount should not change
        XCTAssertEqual(category.budgetedAmount, NSDecimalNumber(value: 500))
    }
    
    func testCheckAndPerformRollover_ResetsSpentAmounts() async throws {
        // Arrange
        let budget = createTestBudget()
        budget.startDate = Calendar.current.date(byAdding: .month, value: -2, to: Date())
        
        let category = createTestBudgetCategory(budget: budget, name: "Food", budgeted: 500)
        category.spentAmount = NSDecimalNumber(value: 300)
        
        mockBudgetRepository.mockActiveBudget = budget
        mockBudgetCategoryRepository.mockCategories = [category]
        
        // Act
        try await sut.checkAndPerformRollover()
        
        // Assert
        XCTAssertTrue(mockBudgetCategoryRepository.updateSpentAmountCalled)
        XCTAssertEqual(mockBudgetCategoryRepository.lastUpdatedAmount, NSDecimalNumber(value: 0))
    }
    
    // MARK: - Helper Methods
    
    private func createTestBudget() -> Budget {
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.isActive = true
        budget.startDate = Date()
        budget.createdAt = Date()
        budget.updatedAt = Date()
        return budget
    }
    
    private func createTestBudgetCategory(budget: Budget, name: String, budgeted: Decimal, threshold: Float = 0.8) -> BudgetCategory {
        let category = BudgetCategory(context: context)
        category.id = UUID()
        category.name = name
        category.budgetedAmount = NSDecimalNumber(decimal: budgeted)
        category.spentAmount = NSDecimalNumber(value: 0)
        category.alertThreshold = threshold
        category.rolloverEnabled = false
        category.budget = budget
        return category
    }
    
    private func createTestTransaction(category: String, amount: Decimal, date: Date = Date()) -> Transaction {
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.category = category
        transaction.amount = NSDecimalNumber(decimal: amount)
        transaction.date = date
        transaction.merchant = "Test Merchant"
        return transaction
    }
}

// MARK: - Mock Budget Repository

@MainActor
class MockBudgetRepository: BudgetRepository {
    var mockActiveBudget: Budget?
    var mockBudgets: [Budget] = []
    var saveCalled = false
    var shouldThrowError = false
    
    func fetchAll() async throws -> [Budget] {
        if shouldThrowError {
            throw RepositoryError.fetchFailed(NSError(domain: "test", code: 1))
        }
        return mockBudgets
    }
    
    func fetchById(_ id: UUID) async throws -> Budget? {
        return mockBudgets.first { $0.id == id }
    }
    
    func save(_ entity: Budget) async throws {
        saveCalled = true
        if shouldThrowError {
            throw RepositoryError.saveFailed(NSError(domain: "test", code: 1))
        }
        if !mockBudgets.contains(where: { $0.id == entity.id }) {
            mockBudgets.append(entity)
        }
    }
    
    func delete(_ entity: Budget) async throws {
        if shouldThrowError {
            throw RepositoryError.deleteFailed(NSError(domain: "test", code: 1))
        }
        mockBudgets.removeAll { $0.id == entity.id }
    }
    
    func fetchActiveBudget() async throws -> Budget? {
        if shouldThrowError {
            throw RepositoryError.fetchFailed(NSError(domain: "test", code: 1))
        }
        return mockActiveBudget
    }
}

// MARK: - Mock Budget Category Repository

@MainActor
class MockBudgetCategoryRepository: BudgetCategoryRepository {
    var mockCategories: [BudgetCategory] = []
    var mockCategory: BudgetCategory?
    var updateSpentAmountCalled = false
    var lastUpdatedAmount: NSDecimalNumber?
    var shouldThrowError = false
    
    func fetchAll() async throws -> [BudgetCategory] {
        if shouldThrowError {
            throw RepositoryError.fetchFailed(NSError(domain: "test", code: 1))
        }
        return mockCategories
    }
    
    func fetchById(_ id: UUID) async throws -> BudgetCategory? {
        return mockCategories.first { $0.id == id }
    }
    
    func save(_ entity: BudgetCategory) async throws {
        if shouldThrowError {
            throw RepositoryError.saveFailed(NSError(domain: "test", code: 1))
        }
        if !mockCategories.contains(where: { $0.id == entity.id }) {
            mockCategories.append(entity)
        }
    }
    
    func delete(_ entity: BudgetCategory) async throws {
        if shouldThrowError {
            throw RepositoryError.deleteFailed(NSError(domain: "test", code: 1))
        }
        mockCategories.removeAll { $0.id == entity.id }
    }
    
    func fetchByBudget(_ budget: Budget) async throws -> [BudgetCategory] {
        if shouldThrowError {
            throw RepositoryError.fetchFailed(NSError(domain: "test", code: 1))
        }
        return mockCategories
    }
    
    func fetchByName(_ name: String, in budget: Budget) async throws -> BudgetCategory? {
        if shouldThrowError {
            throw RepositoryError.fetchFailed(NSError(domain: "test", code: 1))
        }
        return mockCategory ?? mockCategories.first { $0.name == name }
    }
    
    func updateSpentAmount(_ category: BudgetCategory, amount: NSDecimalNumber) async throws {
        updateSpentAmountCalled = true
        lastUpdatedAmount = amount
        if shouldThrowError {
            throw RepositoryError.saveFailed(NSError(domain: "test", code: 1))
        }
        category.spentAmount = amount
    }
}
