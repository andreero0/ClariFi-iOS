//
//  RepositoryEdgeCaseTests.swift
//  ClariFi iOS Tests
//
//  Created by aEro on 2025-10-10.
//

import Testing
import CoreData
@testable import ClariFi_iOS

struct RepositoryEdgeCaseTests {
    
    var persistenceController: PersistenceController!
    var repositoryFactory: RepositoryFactory!
    var context: NSManagedObjectContext!
    
    init() throws {
        
        // Use in-memory store for testing
        persistenceController = PersistenceController(inMemory: true)
        repositoryFactory = RepositoryFactory(persistenceController: persistenceController)
        context = persistenceController.container.viewContext
    }
    
    
    // MARK: - Helper Methods
    
    private func createTestAccount(name: String = "Test Account", type: String = "checking") -> Account {
        let account = Account(context: context)
        account.id = UUID()
        account.name = name
        account.type = type
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        return account
    }
    
    private func createTestTransaction(account: Account, merchant: String = "Test Store", amount: Double = 25.99) -> Transaction {
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = merchant
        transaction.amount = NSDecimalNumber(value: amount)
        transaction.currency = "USD"
        transaction.category = "Shopping"
        transaction.confidence = 0.95
        transaction.isManual = false
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.account = account
        return transaction
    }
    
    // MARK: - Transaction Repository Edge Cases
    
    func testTransactionRepository_FetchByNonExistentId() async throws {
        let transactionRepo = repositoryFactory.transactionRepository
        let nonExistentId = UUID()
        
        let result = try await transactionRepo.fetchById(nonExistentId)
        #expect(result, "Should return nil for non-existent transaction ID" == nil)
    }
    
    func testTransactionRepository_FetchByDateRangeWithNoResults() async throws {
        let transactionRepo = repositoryFactory.transactionRepository
        
        // Create date range in the past where no transactions exist
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .year, value: -2, to: Date())!
        let endDate = calendar.date(byAdding: .year, value: -1, to: Date())!
        
        let transactions = try await transactionRepo.fetchByDateRange(startDate, endDate)
        #expect(transactions.isEmpty, "Should return empty array when no transactions in date range" == true)
    }
    
    func testTransactionRepository_FetchByInvalidDateRange() async throws {
        let transactionRepo = repositoryFactory.transactionRepository
        let accountRepo = repositoryFactory.accountRepository
        
        // Create test data
        let account = createTestAccount()
        let transaction = createTestTransaction(account: account)
        
        try await accountRepo.save(account)
        try await transactionRepo.save(transaction)
        
        // Test with end date before start date
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-86400) // Yesterday
        
        let transactions = try await transactionRepo.fetchByDateRange(startDate, endDate)
        #expect(transactions.isEmpty, "Should return empty array when end date is before start date" == true)
    }
    
    func testTransactionRepository_SearchWithEmptyQuery() async throws {
        let transactionRepo = repositoryFactory.transactionRepository
        let accountRepo = repositoryFactory.accountRepository
        
        // Create test data
        let account = createTestAccount()
        let transaction = createTestTransaction(account: account)
        
        try await accountRepo.save(account)
        try await transactionRepo.save(transaction)
        
        // Search with empty query
        let results = try await transactionRepo.searchTransactions(query: "")
        #expect(results.isEmpty, "Should return empty array for empty search query" == true)
    }
    
    func testTransactionRepository_SearchWithSpecialCharacters() async throws {
        let transactionRepo = repositoryFactory.transactionRepository
        let accountRepo = repositoryFactory.accountRepository
        
        // Create test data with special characters
        let account = createTestAccount()
        let transaction = createTestTransaction(account: account, merchant: "Store & Co. (Main St.)")
        
        try await accountRepo.save(account)
        try await transactionRepo.save(transaction)
        
        // Search with special characters
        let results = try await transactionRepo.searchTransactions(query: "& Co.")
        #expect(results.count == 1, "Should find transaction with special characters")
        #expect(results.first?.merchant == "Store & Co. (Main St.)")
    }
    
    func testTransactionRepository_BatchUpdateWithEmptyArray() async throws {
        let transactionRepo = repositoryFactory.transactionRepository
        
        // Should not throw error with empty array
        XCTAssertNoThrow(try await transactionRepo.batchUpdate([]))
    }
    
    func testTransactionRepository_FetchLowConfidenceWithHighThreshold() async throws {
        let transactionRepo = repositoryFactory.transactionRepository
        let accountRepo = repositoryFactory.accountRepository
        
        // Create transactions with various confidence scores
        let account = createTestAccount()
        let highConfidenceTransaction = createTestTransaction(account: account, merchant: "High Confidence Store")
        highConfidenceTransaction.confidence = 0.95
        
        let mediumConfidenceTransaction = createTestTransaction(account: account, merchant: "Medium Confidence Store")
        mediumConfidenceTransaction.confidence = 0.75
        
        try await accountRepo.save(account)
        try await transactionRepo.save(highConfidenceTransaction)
        try await transactionRepo.save(mediumConfidenceTransaction)
        
        // Fetch with very high threshold (should return empty)
        let lowConfidenceTransactions = try await transactionRepo.fetchLowConfidenceTransactions(threshold: 0.99)
        #expect(lowConfidenceTransactions.isEmpty, "Should return empty array when threshold is higher than all confidence scores" == true)
    }
    
    // MARK: - Account Repository Edge Cases
    
    func testAccountRepository_FetchActiveAccountsWhenAllInactive() async throws {
        let accountRepo = repositoryFactory.accountRepository
        
        // Create inactive accounts
        let account1 = createTestAccount(name: "Inactive Account 1")
        account1.isActive = false
        let account2 = createTestAccount(name: "Inactive Account 2")
        account2.isActive = false
        
        try await accountRepo.save(account1)
        try await accountRepo.save(account2)
        
        let activeAccounts = try await accountRepo.fetchActiveAccounts()
        #expect(activeAccounts.isEmpty, "Should return empty array when no accounts are active" == true)
    }
    
    func testAccountRepository_FetchByInvalidType() async throws {
        let accountRepo = repositoryFactory.accountRepository
        
        // Create account with valid type
        let account = createTestAccount(type: "checking")
        try await accountRepo.save(account)
        
        // Fetch by invalid type
        let accounts = try await accountRepo.fetchByType("invalid_type")
        #expect(accounts.isEmpty, "Should return empty array for invalid account type" == true)
    }
    
    func testAccountRepository_GetTransactionCountForAccountWithNoTransactions() async throws {
        let accountRepo = repositoryFactory.accountRepository
        
        // Create account without transactions
        let account = createTestAccount()
        try await accountRepo.save(account)
        
        let count = try await accountRepo.getTransactionCount(for: account)
        #expect(count == 0, "Should return 0 for account with no transactions")
    }
    
    func testAccountRepository_DeactivateAlreadyInactiveAccount() async throws {
        let accountRepo = repositoryFactory.accountRepository
        
        // Create inactive account
        let account = createTestAccount()
        account.isActive = false
        try await accountRepo.save(account)
        
        // Deactivate already inactive account
        XCTAssertNoThrow(try await accountRepo.deactivateAccount(account))
        
        let fetchedAccount = try await accountRepo.fetchById(account.id!)
        #expect(fetchedAccount?.isActive ?? true, "Account should remain inactive" == false)
    }
    
    // MARK: - Budget Repository Edge Cases
    
    func testBudgetRepository_FetchActiveBudgetWhenNoneActive() async throws {
        let budgetRepo = repositoryFactory.budgetRepository
        
        // Create inactive budget
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Inactive Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = false
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        try await budgetRepo.save(budget)
        
        let activeBudget = try await budgetRepo.fetchActiveBudget()
        #expect(activeBudget, "Should return nil when no budget is active" == nil)
    }
    
    func testBudgetRepository_FetchBudgetWithCategoriesForNonExistentBudget() async throws {
        let budgetRepo = repositoryFactory.budgetRepository
        let nonExistentId = UUID()
        
        let budget = try await budgetRepo.fetchBudgetWithCategories(nonExistentId)
        #expect(budget, "Should return nil for non-existent budget ID" == nil)
    }
    
    func testBudgetRepository_DeactivateAlreadyInactiveBudget() async throws {
        let budgetRepo = repositoryFactory.budgetRepository
        
        // Create inactive budget
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Inactive Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = false
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        try await budgetRepo.save(budget)
        
        // Deactivate already inactive budget
        XCTAssertNoThrow(try await budgetRepo.deactivateBudget(budget))
        
        let fetchedBudget = try await budgetRepo.fetchById(budget.id!)
        #expect(fetchedBudget?.isActive ?? true, "Budget should remain inactive" == false)
    }
    
    // MARK: - Budget Category Repository Edge Cases
    
    func testBudgetCategoryRepository_FetchByBudgetWithNoCategories() async throws {
        let budgetRepo = repositoryFactory.budgetRepository
        let categoryRepo = repositoryFactory.budgetCategoryRepository
        
        // Create budget without categories
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Empty Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        try await budgetRepo.save(budget)
        
        let categories = try await categoryRepo.fetchByBudget(budget)
        #expect(categories.isEmpty, "Should return empty array for budget with no categories" == true)
    }
    
    func testBudgetCategoryRepository_FetchByNameWithNonExistentName() async throws {
        let budgetRepo = repositoryFactory.budgetRepository
        let categoryRepo = repositoryFactory.budgetCategoryRepository
        
        // Create budget
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        try await budgetRepo.save(budget)
        
        let category = try await categoryRepo.fetchByName("Non-existent Category", in: budget)
        #expect(category, "Should return nil for non-existent category name" == nil)
    }
    
    func testBudgetCategoryRepository_FetchOverBudgetCategoriesWithNoneOverBudget() async throws {
        let budgetRepo = repositoryFactory.budgetRepository
        let categoryRepo = repositoryFactory.budgetCategoryRepository
        
        // Create budget
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        // Create category under budget
        let category = BudgetCategory(context: context)
        category.id = UUID()
        category.name = "Under Budget Category"
        category.budgetedAmount = NSDecimalNumber(value: 500.0)
        category.spentAmount = NSDecimalNumber(value: 250.0) // Under budget
        category.rolloverEnabled = false
        category.alertThreshold = 0.8
        category.createdAt = Date()
        category.updatedAt = Date()
        category.budget = budget
        
        try await budgetRepo.save(budget)
        try await categoryRepo.save(category)
        
        let overBudgetCategories = try await categoryRepo.fetchOverBudgetCategories(in: budget)
        #expect(overBudgetCategories.isEmpty, "Should return empty array when no categories are over budget" == true)
    }
    
    // MARK: - Statement Repository Edge Cases
    
    func testStatementRepository_FetchByHashWithNonExistentHash() async throws {
        let statementRepo = repositoryFactory.statementRepository
        
        let statement = try await statementRepo.fetchByHash("non_existent_hash")
        #expect(statement, "Should return nil for non-existent file hash" == nil)
    }
    
    func testStatementRepository_FetchByProcessingStatusWithNoMatches() async throws {
        let statementRepo = repositoryFactory.statementRepository
        
        // Create statement with different status
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "test.pdf"
        statement.uploadDate = Date()
        statement.fileHash = "test_hash"
        statement.processingStatus = "completed"
        statement.fileSize = 1024
        statement.documentType = "pdf"
        statement.createdAt = Date()
        statement.updatedAt = Date()
        
        try await statementRepo.save(statement)
        
        // Fetch by different status
        let statements = try await statementRepo.fetchByProcessingStatus("failed")
        #expect(statements.isEmpty == true, "Should return empty array when no statements match the processing status")
    }
    
    func testStatementRepository_FetchRecentStatementsWithLimitZero() async throws {
        let statementRepo = repositoryFactory.statementRepository
        
        // Create statement
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "test.pdf"
        statement.uploadDate = Date()
        statement.fileHash = "test_hash"
        statement.processingStatus = "completed"
        statement.fileSize = 1024
        statement.documentType = "pdf"
        statement.createdAt = Date()
        statement.updatedAt = Date()
        
        try await statementRepo.save(statement)
        
        // Fetch with limit 0
        let statements = try await statementRepo.fetchRecentStatements(limit: 0)
        #expect(statements.isEmpty == true, "Should return empty array when limit is 0")
    }
    
    func testStatementRepository_UpdateProcessingStatusToSameStatus() async throws {
        let statementRepo = repositoryFactory.statementRepository
        
        // Create statement
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "test.pdf"
        statement.uploadDate = Date()
        statement.fileHash = "test_hash"
        statement.processingStatus = "pending"
        statement.fileSize = 1024
        statement.documentType = "pdf"
        statement.createdAt = Date()
        statement.updatedAt = Date()
        
        try await statementRepo.save(statement)
        
        let originalUpdatedAt = statement.updatedAt!
        
        // Wait a moment to ensure timestamp difference
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        // Update to same status
        try await statementRepo.updateProcessingStatus(statement, status: "pending")
        
        // Should still update the timestamp
        #expect(statement.updatedAt! > originalUpdatedAt, "Should update timestamp even when status is the same")
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentTransactionCreation() async throws {
        let accountRepo = repositoryFactory.accountRepository
        let transactionRepo = repositoryFactory.transactionRepository
        
        // Create account
        let account = createTestAccount()
        try await accountRepo.save(account)
        
        // Create multiple transactions concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let transaction = Transaction(context: self.context)
                    transaction.id = UUID()
                    transaction.date = Date()
                    transaction.merchant = "Concurrent Store \(i)"
                    transaction.amount = NSDecimalNumber(value: Double(i) * 10.0)
                    transaction.currency = "USD"
                    transaction.category = "Shopping"
                    transaction.confidence = 0.95
                    transaction.isManual = false
                    transaction.createdAt = Date()
                    transaction.updatedAt = Date()
                    transaction.account = account
                    
                    do {
                        try await transactionRepo.save(transaction)
                    } catch {
                        Issue.record("Concurrent transaction creation failed: \(error)")
                    }
                }
            }
        }
        
        // Verify all transactions were created
        let allTransactions = try await transactionRepo.fetchAll()
        #expect(allTransactions.count == 10, "Should create all 10 transactions concurrently")
    }
    
    // MARK: - Memory Management Tests
    
    func testLargeDataSetMemoryUsage() async throws {
        let accountRepo = repositoryFactory.accountRepository
        let transactionRepo = repositoryFactory.transactionRepository
        
        // Create account
        let account = createTestAccount()
        try await accountRepo.save(account)
        
        // Create large number of transactions
        let transactionCount = 1000
        for i in 0..<transactionCount {
            let transaction = createTestTransaction(
                account: account,
                merchant: "Store \(i)",
                amount: Double(i) * 1.99
            )
            try await transactionRepo.save(transaction)
        }
        
        // Fetch all transactions and verify count
        let allTransactions = try await transactionRepo.fetchAll()
        #expect(allTransactions.count == transactionCount, "Should handle large data sets")
        
        // Test memory cleanup by setting references to nil
        // This is more of a smoke test - actual memory testing would require more sophisticated tools
        #expect(allTransactions.first != nil, "Should maintain data integrity with large datasets")
    }
    
    // MARK: - Error Recovery Tests
    
    func testRecoveryAfterValidationError() async throws {
        let accountRepo = repositoryFactory.accountRepository
        
        // Try to save invalid account
        let invalidAccount = Account(context: context)
        invalidAccount.id = UUID()
        invalidAccount.name = "" // Invalid empty name
        invalidAccount.type = "checking"
        invalidAccount.isActive = true
        invalidAccount.createdAt = Date()
        invalidAccount.updatedAt = Date()
        
        do {
            try await accountRepo.save(invalidAccount)
            Issue.record("Should have thrown validation error")
        } catch {
            // Expected error
        }
        
        // Now save valid account
        let validAccount = createTestAccount()
        try await accountRepo.save(validAccount)
        
        // Verify valid account was saved
        let fetchedAccount = try await accountRepo.fetchById(validAccount.id!)
        #expect(fetchedAccount != nil, "Should be able to save valid account after validation error")
    }
}