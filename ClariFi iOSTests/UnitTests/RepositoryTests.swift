//
//  RepositoryTests.swift
//  ClariFi iOS Tests
//
//  Created by Kiro on 2025-10-11.
//  Test coverage for Core Data repository implementations
//

import XCTest
import CoreData
@testable import ClariFi_iOS

/// Comprehensive tests for Core Data repository implementations
/// Tests use in-memory Core Data stack for isolation
class RepositoryTests: XCTestCase {
    
    var context: NSManagedObjectContext!
    var transactionRepo: CoreDataTransactionRepository!
    var accountRepo: CoreDataAccountRepository!
    var budgetRepo: CoreDataBudgetRepository!
    var budgetCategoryRepo: CoreDataBudgetCategoryRepository!
    var statementRepo: CoreDataStatementRepository!
    var recurringRepo: CoreDataRecurringTransactionRepository!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory Core Data stack for testing
        context = PersistenceController.preview.container.viewContext
        
        // Initialize repositories
        transactionRepo = CoreDataTransactionRepository(context: context)
        accountRepo = CoreDataAccountRepository(context: context)
        budgetRepo = CoreDataBudgetRepository(context: context)
        budgetCategoryRepo = CoreDataBudgetCategoryRepository(context: context)
        statementRepo = CoreDataStatementRepository(context: context)
        recurringRepo = CoreDataRecurringTransactionRepository(context: context)
    }
    
    override func tearDown() {
        // Clean up test data
        let entities = ["Transaction", "Account", "Budget", "BudgetCategory", "Statement", "RecurringTransaction"]
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try? context.execute(deleteRequest)
        }
        
        context = nil
        transactionRepo = nil
        accountRepo = nil
        budgetRepo = nil
        budgetCategoryRepo = nil
        statementRepo = nil
        recurringRepo = nil
        
        super.tearDown()
    }
    
    // MARK: - Transaction Repository Tests
    
    func testTransactionRepository_SaveAndFetch() async throws {
        // Arrange
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.merchant = "Test Merchant"
        transaction.amount = NSDecimalNumber(value: 100.50)
        transaction.date = Date()
        transaction.category = "Food"
        
        // Act
        try await transactionRepo.save(transaction)
        let fetched = try await transactionRepo.fetchById(transaction.id!)
        
        // Assert
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.merchant, "Test Merchant")
        XCTAssertEqual(fetched?.amount, NSDecimalNumber(value: 100.50))
        XCTAssertNotNil(fetched?.createdAt, "CreatedAt should be set automatically")
        XCTAssertNotNil(fetched?.updatedAt, "UpdatedAt should be set automatically")
    }
    
    func testTransactionRepository_FetchByDateRange() async throws {
        // Arrange
        let startDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
        let endDate = Date()
        
        let transaction1 = createTestTransaction(date: startDate.addingTimeInterval(24 * 60 * 60))
        let transaction2 = createTestTransaction(date: startDate.addingTimeInterval(48 * 60 * 60))
        let transaction3 = createTestTransaction(date: startDate.addingTimeInterval(-24 * 60 * 60)) // Outside range
        
        try await transactionRepo.save(transaction1)
        try await transactionRepo.save(transaction2)
        try await transactionRepo.save(transaction3)
        
        // Act
        let results = try await transactionRepo.fetchByDateRange(startDate, endDate)
        
        // Assert
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains(where: { $0.id == transaction1.id }))
        XCTAssertTrue(results.contains(where: { $0.id == transaction2.id }))
        XCTAssertFalse(results.contains(where: { $0.id == transaction3.id }))
    }
    
    func testTransactionRepository_FetchByCategory() async throws {
        // Arrange
        let transaction1 = createTestTransaction(category: "Food")
        let transaction2 = createTestTransaction(category: "Food")
        let transaction3 = createTestTransaction(category: "Transport")
        
        try await transactionRepo.save(transaction1)
        try await transactionRepo.save(transaction2)
        try await transactionRepo.save(transaction3)
        
        // Act
        let results = try await transactionRepo.fetchByCategory("Food")
        
        // Assert
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.category == "Food" })
    }
    
    func testTransactionRepository_SearchTransactions() async throws {
        // Arrange
        let transaction1 = createTestTransaction(merchant: "Starbucks Coffee")
        let transaction2 = createTestTransaction(merchant: "Coffee Bean")
        let transaction3 = createTestTransaction(merchant: "McDonald's")
        
        try await transactionRepo.save(transaction1)
        try await transactionRepo.save(transaction2)
        try await transactionRepo.save(transaction3)
        
        // Act
        let results = try await transactionRepo.searchTransactions(query: "coffee")
        
        // Assert
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains(where: { $0.id == transaction1.id }))
        XCTAssertTrue(results.contains(where: { $0.id == transaction2.id }))
    }
    
    func testTransactionRepository_BatchUpdate() async throws {
        // Arrange
        let transaction1 = createTestTransaction()
        let transaction2 = createTestTransaction()
        
        try await transactionRepo.save(transaction1)
        try await transactionRepo.save(transaction2)
        
        let originalUpdatedAt1 = transaction1.updatedAt
        let originalUpdatedAt2 = transaction2.updatedAt
        
        // Wait a moment to ensure timestamp difference
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Act
        transaction1.category = "Updated Category"
        transaction2.category = "Updated Category"
        try await transactionRepo.batchUpdate([transaction1, transaction2])
        
        // Assert
        XCTAssertNotEqual(transaction1.updatedAt, originalUpdatedAt1)
        XCTAssertNotEqual(transaction2.updatedAt, originalUpdatedAt2)
        XCTAssertEqual(transaction1.category, "Updated Category")
        XCTAssertEqual(transaction2.category, "Updated Category")
    }
    
    // MARK: - Account Repository Tests
    
    func testAccountRepository_GetOrCreateDefaultAccount() async throws {
        // Act - First call should create
        let account1 = try await accountRepo.getOrCreateDefaultAccount()
        
        // Assert
        XCTAssertNotNil(account1)
        XCTAssertEqual(account1.name, "Default Account")
        XCTAssertTrue(account1.isDefault)
        XCTAssertTrue(account1.isActive)
        
        // Act - Second call should return existing
        let account2 = try await accountRepo.getOrCreateDefaultAccount()
        
        // Assert
        XCTAssertEqual(account1.id, account2.id, "Should return same account")
    }
    
    func testAccountRepository_FetchActiveAccounts() async throws {
        // Arrange
        let account1 = createTestAccount(name: "Active 1", isActive: true)
        let account2 = createTestAccount(name: "Active 2", isActive: true)
        let account3 = createTestAccount(name: "Inactive", isActive: false)
        
        try await accountRepo.save(account1)
        try await accountRepo.save(account2)
        try await accountRepo.save(account3)
        
        // Act
        let results = try await accountRepo.fetchActiveAccounts()
        
        // Assert
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.isActive })
    }
    
    func testAccountRepository_DeactivateAccount() async throws {
        // Arrange
        let account = createTestAccount(isActive: true)
        try await accountRepo.save(account)
        
        XCTAssertTrue(account.isActive)
        
        // Act
        try await accountRepo.deactivateAccount(account)
        
        // Assert
        XCTAssertFalse(account.isActive)
        XCTAssertNotNil(account.updatedAt)
    }
    
    // MARK: - Budget Repository Tests
    
    func testBudgetRepository_FetchActiveBudget() async throws {
        // Arrange
        let budget1 = createTestBudget(name: "Active Budget", isActive: true)
        let budget2 = createTestBudget(name: "Inactive Budget", isActive: false)
        
        try await budgetRepo.save(budget1)
        try await budgetRepo.save(budget2)
        
        // Act
        let result = try await budgetRepo.fetchActiveBudget()
        
        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Active Budget")
        XCTAssertTrue(result?.isActive ?? false)
    }
    
    func testBudgetRepository_FetchByPeriod() async throws {
        // Arrange
        let budget1 = createTestBudget(period: "monthly")
        let budget2 = createTestBudget(period: "monthly")
        let budget3 = createTestBudget(period: "weekly")
        
        try await budgetRepo.save(budget1)
        try await budgetRepo.save(budget2)
        try await budgetRepo.save(budget3)
        
        // Act
        let results = try await budgetRepo.fetchByPeriod("monthly")
        
        // Assert
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.period == "monthly" })
    }
    
    func testBudgetRepository_DeactivateBudget() async throws {
        // Arrange
        let budget = createTestBudget(isActive: true)
        try await budgetRepo.save(budget)
        
        XCTAssertTrue(budget.isActive)
        
        // Act
        try await budgetRepo.deactivateBudget(budget)
        
        // Assert
        XCTAssertFalse(budget.isActive)
        XCTAssertNotNil(budget.updatedAt)
    }
    
    // MARK: - Budget Category Repository Tests
    
    func testBudgetCategoryRepository_FetchByBudget() async throws {
        // Arrange
        let budget1 = createTestBudget(name: "Budget 1")
        let budget2 = createTestBudget(name: "Budget 2")
        
        try await budgetRepo.save(budget1)
        try await budgetRepo.save(budget2)
        
        let category1 = createTestBudgetCategory(name: "Food", budget: budget1)
        let category2 = createTestBudgetCategory(name: "Transport", budget: budget1)
        let category3 = createTestBudgetCategory(name: "Food", budget: budget2)
        
        try await budgetCategoryRepo.save(category1)
        try await budgetCategoryRepo.save(category2)
        try await budgetCategoryRepo.save(category3)
        
        // Act
        let results = try await budgetCategoryRepo.fetchByBudget(budget1)
        
        // Assert
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.budget == budget1 })
    }
    
    func testBudgetCategoryRepository_UpdateSpentAmount() async throws {
        // Arrange
        let budget = createTestBudget()
        try await budgetRepo.save(budget)
        
        let category = createTestBudgetCategory(budget: budget)
        category.spentAmount = NSDecimalNumber(value: 100)
        try await budgetCategoryRepo.save(category)
        
        // Act
        try await budgetCategoryRepo.updateSpentAmount(category, amount: NSDecimalNumber(value: 250))
        
        // Assert
        XCTAssertEqual(category.spentAmount, NSDecimalNumber(value: 250))
        XCTAssertNotNil(category.updatedAt)
    }
    
    func testBudgetCategoryRepository_FetchOverBudgetCategories() async throws {
        // Arrange
        let budget = createTestBudget()
        try await budgetRepo.save(budget)
        
        let category1 = createTestBudgetCategory(name: "Food", budget: budget)
        category1.budgetedAmount = NSDecimalNumber(value: 500)
        category1.spentAmount = NSDecimalNumber(value: 600) // Over budget
        
        let category2 = createTestBudgetCategory(name: "Transport", budget: budget)
        category2.budgetedAmount = NSDecimalNumber(value: 300)
        category2.spentAmount = NSDecimalNumber(value: 250) // Under budget
        
        try await budgetCategoryRepo.save(category1)
        try await budgetCategoryRepo.save(category2)
        
        // Act
        let results = try await budgetCategoryRepo.fetchOverBudgetCategories(in: budget)
        
        // Assert
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Food")
    }
    
    // MARK: - Statement Repository Tests
    
    func testStatementRepository_FetchByHash() async throws {
        // Arrange
        let statement = createTestStatement(fileHash: "abc123")
        try await statementRepo.save(statement)
        
        // Act
        let result = try await statementRepo.fetchByHash("abc123")
        
        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.fileHash, "abc123")
    }
    
    func testStatementRepository_FetchByProcessingStatus() async throws {
        // Arrange
        let statement1 = createTestStatement(status: "pending")
        let statement2 = createTestStatement(status: "pending")
        let statement3 = createTestStatement(status: "completed")
        
        try await statementRepo.save(statement1)
        try await statementRepo.save(statement2)
        try await statementRepo.save(statement3)
        
        // Act
        let results = try await statementRepo.fetchByProcessingStatus("pending")
        
        // Assert
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.processingStatus == "pending" })
    }
    
    func testStatementRepository_UpdateProcessingStatus() async throws {
        // Arrange
        let statement = createTestStatement(status: "pending")
        try await statementRepo.save(statement)
        
        XCTAssertEqual(statement.processingStatus, "pending")
        
        // Act
        try await statementRepo.updateProcessingStatus(statement, status: "completed")
        
        // Assert
        XCTAssertEqual(statement.processingStatus, "completed")
        XCTAssertNotNil(statement.updatedAt)
    }
    
    // MARK: - Recurring Transaction Repository Tests
    
    func testRecurringTransactionRepository_FetchActiveRecurring() async throws {
        // Arrange
        let recurring1 = createTestRecurringTransaction(isActive: true)
        let recurring2 = createTestRecurringTransaction(isActive: true)
        let recurring3 = createTestRecurringTransaction(isActive: false)
        
        try await recurringRepo.save(recurring1)
        try await recurringRepo.save(recurring2)
        try await recurringRepo.save(recurring3)
        
        // Act
        let results = try await recurringRepo.fetchActiveRecurring()
        
        // Assert
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.isActive })
    }
    
    func testRecurringTransactionRepository_FetchDueTransactions() async throws {
        // Arrange
        let now = Date()
        let yesterday = now.addingTimeInterval(-24 * 60 * 60)
        let tomorrow = now.addingTimeInterval(24 * 60 * 60)
        
        let recurring1 = createTestRecurringTransaction(nextOccurrence: yesterday, isActive: true)
        let recurring2 = createTestRecurringTransaction(nextOccurrence: now, isActive: true)
        let recurring3 = createTestRecurringTransaction(nextOccurrence: tomorrow, isActive: true)
        
        try await recurringRepo.save(recurring1)
        try await recurringRepo.save(recurring2)
        try await recurringRepo.save(recurring3)
        
        // Act
        let results = try await recurringRepo.fetchDueTransactions(upToDate: now)
        
        // Assert
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains(where: { $0.id == recurring1.id }))
        XCTAssertTrue(results.contains(where: { $0.id == recurring2.id }))
    }
    
    func testRecurringTransactionRepository_UpdateNextOccurrence() async throws {
        // Arrange
        let recurring = createTestRecurringTransaction()
        let originalDate = recurring.nextOccurrence
        try await recurringRepo.save(recurring)
        
        let newDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now
        
        // Act
        try await recurringRepo.updateNextOccurrence(recurring, nextDate: newDate)
        
        // Assert
        XCTAssertNotEqual(recurring.nextOccurrence, originalDate)
        XCTAssertEqual(recurring.nextOccurrence, newDate)
        XCTAssertNotNil(recurring.updatedAt)
    }
    
    // MARK: - Test Helpers
    
    private func createTestTransaction(
        merchant: String = "Test Merchant",
        amount: Decimal = 100.0,
        date: Date = Date(),
        category: String = "Food"
    ) -> Transaction {
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.merchant = merchant
        transaction.amount = NSDecimalNumber(decimal: amount)
        transaction.date = date
        transaction.category = category
        return transaction
    }
    
    private func createTestAccount(
        name: String = "Test Account",
        isActive: Bool = true
    ) -> Account {
        let account = Account(context: context)
        account.id = UUID()
        account.name = name
        account.type = "checking"
        account.isActive = isActive
        return account
    }
    
    private func createTestBudget(
        name: String = "Test Budget",
        period: String = "monthly",
        isActive: Bool = true
    ) -> Budget {
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = name
        budget.period = period
        budget.isActive = isActive
        budget.startDate = Date()
        budget.endDate = Date().addingTimeInterval(30 * 24 * 60 * 60)
        return budget
    }
    
    private func createTestBudgetCategory(
        name: String = "Test Category",
        budget: Budget
    ) -> BudgetCategory {
        let category = BudgetCategory(context: context)
        category.id = UUID()
        category.name = name
        category.budget = budget
        category.budgetedAmount = NSDecimalNumber(value: 500)
        category.spentAmount = NSDecimalNumber(value: 0)
        return category
    }
    
    private func createTestStatement(
        fileHash: String = "test_hash",
        status: String = "pending"
    ) -> Statement {
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileHash = fileHash
        statement.processingStatus = status
        statement.uploadDate = Date()
        return statement
    }
    
    private func createTestRecurringTransaction(
        nextOccurrence: Date = Date(),
        isActive: Bool = true
    ) -> RecurringTransaction {
        let recurring = RecurringTransaction(context: context)
        recurring.id = UUID()
        recurring.merchant = "Test Recurring"
        recurring.amount = NSDecimalNumber(value: 50)
        recurring.frequency = "monthly"
        recurring.nextOccurrence = nextOccurrence
        recurring.isActive = isActive
        return recurring
    }
}
