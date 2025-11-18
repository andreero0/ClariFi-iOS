//
//  MockRepositoriesTests.swift
//  ClariFi_iOS Tests
//
//  Tests to verify mock repository implementations work correctly
//

import XCTest
import CoreData
@testable import ClariFi_iOS

@MainActor
final class MockRepositoriesTests: XCTestCase {
    
    var context: NSManagedObjectContext!
    
    override func setUp() async throws {
        try await super.setUp()
        context = PersistenceController.preview.container.viewContext
    }
    
    override func tearDown() async throws {
        context = nil
        try await super.tearDown()
    }
    
    // MARK: - MockTransactionRepository Tests
    
    func testMockTransactionRepository_SaveAndFetch() async throws {
        // Arrange
        let mockRepo = MockTransactionRepository()
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.merchant = "Test Merchant"
        transaction.amount = NSDecimalNumber(value: 100.0)
        
        // Act
        try await mockRepo.save(transaction)
        let fetched = try await mockRepo.fetchAll()
        
        // Assert
        XCTAssertTrue(mockRepo.saveCalled)
        XCTAssertEqual(mockRepo.saveCallCount, 1)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.merchant, "Test Merchant")
    }
    
    func testMockTransactionRepository_ErrorHandling() async throws {
        // Arrange
        let mockRepo = MockTransactionRepository()
        mockRepo.shouldThrowError = true
        
        // Act & Assert
        do {
            _ = try await mockRepo.fetchAll()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is RepositoryError)
        }
    }
    
    func testMockTransactionRepository_Reset() async throws {
        // Arrange
        let mockRepo = MockTransactionRepository()
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        try await mockRepo.save(transaction)
        
        // Act
        mockRepo.reset()
        
        // Assert
        XCTAssertFalse(mockRepo.saveCalled)
        XCTAssertEqual(mockRepo.saveCallCount, 0)
        XCTAssertEqual(mockRepo.mockTransactions.count, 0)
    }
    
    // MARK: - MockAccountRepository Tests
    
    func testMockAccountRepository_SaveAndFetch() async throws {
        // Arrange
        let mockRepo = MockAccountRepository()
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.isActive = true
        
        // Act
        try await mockRepo.save(account)
        let fetched = try await mockRepo.fetchActiveAccounts()
        
        // Assert
        XCTAssertTrue(mockRepo.saveCalled)
        XCTAssertTrue(mockRepo.fetchActiveAccountsCalled)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Test Account")
    }
    
    func testMockAccountRepository_GetOrCreateDefault() async throws {
        // Arrange
        let mockRepo = MockAccountRepository()
        
        // Act
        let account = try await mockRepo.getOrCreateDefaultAccount()
        
        // Assert
        XCTAssertTrue(mockRepo.getOrCreateDefaultAccountCalled)
        XCTAssertEqual(account.name, "Default Account")
        XCTAssertTrue(account.isActive)
    }
    
    // MARK: - MockBudgetRepository Tests
    
    func testMockBudgetRepository_SaveAndFetchActive() async throws {
        // Arrange
        let mockRepo = MockBudgetRepository()
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.isActive = true
        
        // Act
        try await mockRepo.save(budget)
        let activeBudget = try await mockRepo.fetchActiveBudget()
        
        // Assert
        XCTAssertTrue(mockRepo.saveCalled)
        XCTAssertTrue(mockRepo.fetchActiveBudgetCalled)
        XCTAssertNotNil(activeBudget)
        XCTAssertEqual(activeBudget?.name, "Test Budget")
    }
    
    func testMockBudgetRepository_DeactivateBudget() async throws {
        // Arrange
        let mockRepo = MockBudgetRepository()
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.isActive = true
        
        // Act
        try await mockRepo.deactivateBudget(budget)
        
        // Assert
        XCTAssertTrue(mockRepo.deactivateBudgetCalled)
        XCTAssertFalse(budget.isActive)
    }
    
    // MARK: - MockBudgetCategoryRepository Tests
    
    func testMockBudgetCategoryRepository_SaveAndFetchByBudget() async throws {
        // Arrange
        let mockRepo = MockBudgetCategoryRepository()
        let budget = Budget(context: context)
        budget.id = UUID()
        
        let category = BudgetCategory(context: context)
        category.id = UUID()
        category.name = "Food"
        category.budget = budget
        
        // Act
        try await mockRepo.save(category)
        let categories = try await mockRepo.fetchByBudget(budget)
        
        // Assert
        XCTAssertTrue(mockRepo.saveCalled)
        XCTAssertTrue(mockRepo.fetchByBudgetCalled)
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories.first?.name, "Food")
    }
    
    func testMockBudgetCategoryRepository_UpdateSpentAmount() async throws {
        // Arrange
        let mockRepo = MockBudgetCategoryRepository()
        let category = BudgetCategory(context: context)
        category.id = UUID()
        category.spent = NSDecimalNumber(value: 0)
        
        let newAmount = NSDecimalNumber(value: 150.0)
        
        // Act
        try await mockRepo.updateSpentAmount(category, amount: newAmount)
        
        // Assert
        XCTAssertTrue(mockRepo.updateSpentAmountCalled)
        XCTAssertEqual(category.spent, newAmount)
    }
    
    // MARK: - MockStatementRepository Tests
    
    func testMockStatementRepository_SaveAndFetchByHash() async throws {
        // Arrange
        let mockRepo = MockStatementRepository()
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileHash = "test-hash-123"
        
        // Act
        try await mockRepo.save(statement)
        let fetched = try await mockRepo.fetchByHash("test-hash-123")
        
        // Assert
        XCTAssertTrue(mockRepo.saveCalled)
        XCTAssertTrue(mockRepo.fetchByHashCalled)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.fileHash, "test-hash-123")
    }
    
    func testMockStatementRepository_UpdateProcessingStatus() async throws {
        // Arrange
        let mockRepo = MockStatementRepository()
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.processingStatus = "pending"
        
        // Act
        try await mockRepo.updateProcessingStatus(statement, status: "completed")
        
        // Assert
        XCTAssertTrue(mockRepo.updateProcessingStatusCalled)
        XCTAssertEqual(statement.processingStatus, "completed")
    }
    
    // MARK: - MockRecurringTransactionRepository Tests
    
    func testMockRecurringTransactionRepository_SaveAndFetchActive() async throws {
        // Arrange
        let mockRepo = MockRecurringTransactionRepository()
        let recurring = RecurringTransaction(context: context)
        recurring.id = UUID()
        recurring.merchant = "Netflix"
        recurring.isActive = true
        
        // Act
        try await mockRepo.save(recurring)
        let active = try await mockRepo.fetchActiveRecurring()
        
        // Assert
        XCTAssertTrue(mockRepo.saveCalled)
        XCTAssertTrue(mockRepo.fetchActiveRecurringCalled)
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active.first?.merchant, "Netflix")
    }
    
    func testMockRecurringTransactionRepository_UpdateNextOccurrence() async throws {
        // Arrange
        let mockRepo = MockRecurringTransactionRepository()
        let recurring = RecurringTransaction(context: context)
        recurring.id = UUID()
        recurring.nextOccurrence = Date()
        
        let newDate = Date().addingTimeInterval(86400 * 30) // 30 days from now
        
        // Act
        try await mockRepo.updateNextOccurrence(recurring, nextDate: newDate)
        
        // Assert
        XCTAssertTrue(mockRepo.updateNextOccurrenceCalled)
        XCTAssertEqual(recurring.nextOccurrence, newDate)
    }
}
