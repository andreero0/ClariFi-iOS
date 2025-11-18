//
//  PrivacyControlsTests.swift
//  ClariFi iOS Tests
//
//  Created by aEro on 2025-10-10.
//

import Testing
import CoreData
@testable import ClariFi_iOS

struct PrivacyControlsTests {
    
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
    
    private func createTestData() async throws {
        let accountRepo = repositoryFactory.accountRepository
        let transactionRepo = repositoryFactory.transactionRepository
        let budgetRepo = repositoryFactory.budgetRepository
        let categoryRepo = repositoryFactory.budgetCategoryRepository
        let statementRepo = repositoryFactory.statementRepository
        
        // Create account
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Privacy Test Account"
        account.type = "checking"
        account.lastFourDigits = "1234"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        // Create transactions
        let transaction1 = Transaction(context: context)
        transaction1.id = UUID()
        transaction1.date = Date()
        transaction1.merchant = "Privacy Store 1"
        transaction1.amount = NSDecimalNumber(value: 25.99)
        transaction1.currency = "USD"
        transaction1.category = "Shopping"
        transaction1.confidence = 0.95
        transaction1.isManual = false
        transaction1.notes = "Test transaction 1"
        transaction1.createdAt = Date()
        transaction1.updatedAt = Date()
        transaction1.account = account
        
        let transaction2 = Transaction(context: context)
        transaction2.id = UUID()
        transaction2.date = Date().addingTimeInterval(-86400) // Yesterday
        transaction2.merchant = "Privacy Store 2"
        transaction2.amount = NSDecimalNumber(value: 15.50)
        transaction2.currency = "USD"
        transaction2.category = "Food"
        transaction2.confidence = 0.88
        transaction2.isManual = true
        transaction2.notes = "Test transaction 2"
        transaction2.createdAt = Date()
        transaction2.updatedAt = Date()
        transaction2.account = account
        
        // Create budget
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Privacy Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        // Create budget category
        let category = BudgetCategory(context: context)
        category.id = UUID()
        category.name = "Privacy Category"
        category.budgetedAmount = NSDecimalNumber(value: 500.0)
        category.spentAmount = NSDecimalNumber(value: 41.49) // Sum of transactions
        category.rolloverEnabled = false
        category.alertThreshold = 0.8
        category.createdAt = Date()
        category.updatedAt = Date()
        category.budget = budget
        
        // Create statement
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "privacy_test.pdf"
        statement.uploadDate = Date()
        statement.fileHash = "privacy_hash_123"
        statement.processingStatus = "completed"
        statement.fileSize = 2048
        statement.documentType = "pdf"
        statement.createdAt = Date()
        statement.updatedAt = Date()
        
        // Save all data
        try await accountRepo.save(account)
        try await transactionRepo.save(transaction1)
        try await transactionRepo.save(transaction2)
        try await budgetRepo.save(budget)
        try await categoryRepo.save(category)
        try await statementRepo.save(statement)
    }
    
    // MARK: - Data Export Tests
    
    func testDataExportCompleteness() async throws {
        // Create test data
        try await createTestData()
        
        // Get all data for export verification
        let accounts = try await repositoryFactory.accountRepository.fetchAll()
        let transactions = try await repositoryFactory.transactionRepository.fetchAll()
        let budgets = try await repositoryFactory.budgetRepository.fetchAll()
        let categories = try await repositoryFactory.budgetCategoryRepository.fetchAll()
        let statements = try await repositoryFactory.statementRepository.fetchAll()
        
        // Verify test data was created
        #expect(accounts.count == 1)
        #expect(transactions.count == 2)
        #expect(budgets.count == 1)
        #expect(categories.count == 1)
        #expect(statements.count == 1)
        
        // Verify data contains expected privacy-sensitive information
        let account = accounts.first!
        #expect(account.name == "Privacy Test Account")
        #expect(account.lastFourDigits == "1234")
        
        let transaction = transactions.first!
        #expect(transaction.merchant.contains("Privacy Store" == true))
        #expect(transaction.notes != nil)
        #expect(transaction.notes!.contains("Test transaction" == true))
        
        let statement = statements.first!
        #expect(statement.fileName == "privacy_test.pdf")
        #expect(statement.fileHash == "privacy_hash_123")
    }
    
    func testDataExportSecurity() async throws {
        // Create test data
        try await createTestData()
        
        // Simulate data export process
        let accounts = try await repositoryFactory.accountRepository.fetchAll()
        let transactions = try await repositoryFactory.transactionRepository.fetchAll()
        
        // Verify sensitive data is included in export (as it should be for user data portability)
        let account = accounts.first!
        #expect(account.name.isEmpty, "Account name should be included in export" == false)
        #expect(account.lastFourDigits, "Last four digits should be included in export" != nil)
        
        let transaction = transactions.first!
        #expect(transaction.merchant.isEmpty, "Merchant should be included in export" == false)
        #expect(transaction.amount, "Amount should be included in export" != nil)
        #expect(transaction.notes, "Notes should be included in export" != nil)
        
        // Verify timestamps are included for audit trail
        #expect(account.createdAt, "Creation timestamp should be included" != nil)
        #expect(account.updatedAt, "Update timestamp should be included" != nil)
        #expect(transaction.createdAt, "Transaction creation timestamp should be included" != nil)
        #expect(transaction.updatedAt, "Transaction update timestamp should be included" != nil)
    }
    
    // MARK: - Data Deletion Tests
    
    func testCompleteDataDeletion() async throws {
        // Create test data
        try await createTestData()
        
        // Verify data exists
        let initialAccounts = try await repositoryFactory.accountRepository.fetchAll()
        let initialTransactions = try await repositoryFactory.transactionRepository.fetchAll()
        let initialBudgets = try await repositoryFactory.budgetRepository.fetchAll()
        let initialCategories = try await repositoryFactory.budgetCategoryRepository.fetchAll()
        let initialStatements = try await repositoryFactory.statementRepository.fetchAll()
        
        #expect(initialAccounts.isEmpty == false)
        #expect(initialTransactions.isEmpty == false)
        #expect(initialBudgets.isEmpty == false)
        #expect(initialCategories.isEmpty == false)
        #expect(initialStatements.isEmpty == false)
        
        // Perform complete data deletion
        try await persistenceController.deleteAllData()
        
        // Verify all data is completely deleted
        let remainingAccounts = try await repositoryFactory.accountRepository.fetchAll()
        let remainingTransactions = try await repositoryFactory.transactionRepository.fetchAll()
        let remainingBudgets = try await repositoryFactory.budgetRepository.fetchAll()
        let remainingCategories = try await repositoryFactory.budgetCategoryRepository.fetchAll()
        let remainingStatements = try await repositoryFactory.statementRepository.fetchAll()
        
        #expect(remainingAccounts.isEmpty, "All accounts should be deleted" == true)
        #expect(remainingTransactions.isEmpty, "All transactions should be deleted" == true)
        #expect(remainingBudgets.isEmpty, "All budgets should be deleted" == true)
        #expect(remainingCategories.isEmpty, "All budget categories should be deleted" == true)
        #expect(remainingStatements.isEmpty, "All statements should be deleted" == true)
    }
    
    func testSelectiveDataDeletion() async throws {
        // Create test data
        try await createTestData()
        
        let accountRepo = repositoryFactory.accountRepository
        let transactionRepo = repositoryFactory.transactionRepository
        let budgetRepo = repositoryFactory.budgetRepository
        
        // Get initial data
        let accounts = try await accountRepo.fetchAll()
        let budgets = try await budgetRepo.fetchAll()
        
        #expect(accounts.count == 1)
        #expect(budgets.count == 1)
        
        // Delete only transactions (selective deletion)
        let transactions = try await transactionRepo.fetchAll()
        for transaction in transactions {
            try await transactionRepo.delete(transaction)
        }
        
        // Verify only transactions are deleted
        let remainingAccounts = try await accountRepo.fetchAll()
        let remainingTransactions = try await transactionRepo.fetchAll()
        let remainingBudgets = try await budgetRepo.fetchAll()
        
        #expect(remainingAccounts.count == 1, "Accounts should remain")
        #expect(remainingTransactions.isEmpty, "Transactions should be deleted" == true)
        #expect(remainingBudgets.count == 1, "Budgets should remain")
    }
    
    // MARK: - Data Retention Tests
    
    func testDataRetentionPolicies() async throws {
        let transactionRepo = repositoryFactory.transactionRepository
        let accountRepo = repositoryFactory.accountRepository
        
        // Create account
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Retention Test Account"
        account.type = "checking"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        try await accountRepo.save(account)
        
        // Create transactions with different ages
        let calendar = Calendar.current
        let now = Date()
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now)!
        let twoYearsAgo = calendar.date(byAdding: .year, value: -2, to: now)!
        
        let recentTransaction = Transaction(context: context)
        recentTransaction.id = UUID()
        recentTransaction.date = now
        recentTransaction.merchant = "Recent Store"
        recentTransaction.amount = NSDecimalNumber(value: 25.0)
        recentTransaction.currency = "USD"
        recentTransaction.category = "Shopping"
        recentTransaction.confidence = 1.0
        recentTransaction.isManual = true
        recentTransaction.createdAt = now
        recentTransaction.updatedAt = now
        recentTransaction.account = account
        
        let oldTransaction = Transaction(context: context)
        oldTransaction.id = UUID()
        oldTransaction.date = oneYearAgo
        oldTransaction.merchant = "Old Store"
        oldTransaction.amount = NSDecimalNumber(value: 50.0)
        oldTransaction.currency = "USD"
        oldTransaction.category = "Shopping"
        oldTransaction.confidence = 1.0
        oldTransaction.isManual = true
        oldTransaction.createdAt = oneYearAgo
        oldTransaction.updatedAt = oneYearAgo
        oldTransaction.account = account
        
        let veryOldTransaction = Transaction(context: context)
        veryOldTransaction.id = UUID()
        veryOldTransaction.date = twoYearsAgo
        veryOldTransaction.merchant = "Very Old Store"
        veryOldTransaction.amount = NSDecimalNumber(value: 75.0)
        veryOldTransaction.currency = "USD"
        veryOldTransaction.category = "Shopping"
        veryOldTransaction.confidence = 1.0
        veryOldTransaction.isManual = true
        veryOldTransaction.createdAt = twoYearsAgo
        veryOldTransaction.updatedAt = twoYearsAgo
        veryOldTransaction.account = account
        
        try await transactionRepo.save(recentTransaction)
        try await transactionRepo.save(oldTransaction)
        try await transactionRepo.save(veryOldTransaction)
        
        // Test date range queries for retention policies
        let cutoffDate = calendar.date(byAdding: .year, value: -1, to: now)!
        let recentTransactions = try await transactionRepo.fetchByDateRange(cutoffDate, now)
        
        // Should include recent and one-year-old transactions
        #expect(recentTransactions.count == 2)
        
        let transactionMerchants = recentTransactions.map { $0.merchant }.sorted()
        #expect(transactionMerchants.contains("Recent Store" == true))
        #expect(transactionMerchants.contains("Old Store" == true))
        #expect(transactionMerchants.contains("Very Old Store" == false))
    }
    
    // MARK: - Privacy Audit Tests
    
    func testDataAccessAuditTrail() async throws {
        // Create test data
        try await createTestData()
        
        let transactionRepo = repositoryFactory.transactionRepository
        let accountRepo = repositoryFactory.accountRepository
        
        // Simulate data access operations
        let accounts = try await accountRepo.fetchAll()
        #expect(accounts.isEmpty == false)
        
        let account = accounts.first!
        let accountTransactions = try await transactionRepo.fetchByAccount(account)
        #expect(accountTransactions.isEmpty == false)
        
        // Verify timestamps are maintained for audit purposes
        for transaction in accountTransactions {
            #expect(transaction.createdAt, "Creation timestamp should exist for audit" != nil)
            #expect(transaction.updatedAt, "Update timestamp should exist for audit" != nil)
            #expect(transaction.createdAt! <= transaction.updatedAt!, "Update time should be >= creation time")
        }
        
        // Verify account audit information
        #expect(account.createdAt, "Account creation timestamp should exist" != nil)
        #expect(account.updatedAt, "Account update timestamp should exist" != nil)
    }
    
    func testDataModificationAuditTrail() async throws {
        let accountRepo = repositoryFactory.accountRepository
        
        // Create account
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Audit Test Account"
        account.type = "checking"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        let originalCreatedAt = account.createdAt!
        let originalUpdatedAt = account.updatedAt!
        
        try await accountRepo.save(account)
        
        // Wait a moment to ensure timestamp difference
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        // Modify account
        account.name = "Modified Audit Test Account"
        try await accountRepo.save(account)
        
        // Verify audit trail
        let updatedAccount = try await accountRepo.fetchById(account.id!)!
        #expect(updatedAccount.createdAt == originalCreatedAt, "Creation timestamp should not change")
        #expect(updatedAccount.updatedAt! > originalUpdatedAt, "Update timestamp should be newer")
        #expect(updatedAccount.name == "Modified Audit Test Account", "Name should be updated")
    }
    
    // MARK: - Data Anonymization Tests
    
    func testDataAnonymizationCapability() async throws {
        let transactionRepo = repositoryFactory.transactionRepository
        let accountRepo = repositoryFactory.accountRepository
        
        // Create account with identifiable information
        let account = Account(context: context)
        account.id = UUID()
        account.name = "John Doe's Checking"
        account.type = "checking"
        account.lastFourDigits = "1234"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        // Create transaction with identifiable information
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = "John's Favorite Coffee Shop"
        transaction.amount = NSDecimalNumber(value: 4.50)
        transaction.currency = "USD"
        transaction.category = "Food"
        transaction.confidence = 1.0
        transaction.isManual = true
        transaction.notes = "Daily coffee for John"
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.account = account
        
        try await accountRepo.save(account)
        try await transactionRepo.save(transaction)
        
        // Simulate anonymization process
        account.name = "Anonymous Account"
        account.lastFourDigits = "****"
        
        transaction.merchant = "Coffee Shop"
        transaction.notes = "Daily coffee"
        
        try await accountRepo.save(account)
        try await transactionRepo.save(transaction)
        
        // Verify anonymization
        let anonymizedAccount = try await accountRepo.fetchById(account.id!)!
        let anonymizedTransaction = try await transactionRepo.fetchById(transaction.id!)!
        
        #expect(anonymizedAccount.name == "Anonymous Account")
        #expect(anonymizedAccount.lastFourDigits == "****")
        #expect(anonymizedTransaction.merchant == "Coffee Shop")
        #expect(anonymizedTransaction.notes == "Daily coffee")
        
        // Verify non-sensitive data is preserved
        #expect(anonymizedTransaction.amount == NSDecimalNumber(value: 4.50))
        #expect(anonymizedTransaction.category == "Food")
        #expect(anonymizedAccount.type == "checking")
    }
    
    // MARK: - Privacy Compliance Tests
    
    func testGDPRComplianceDataPortability() async throws {
        // Create comprehensive test data
        try await createTestData()
        
        // Simulate GDPR data portability request
        let allAccounts = try await repositoryFactory.accountRepository.fetchAll()
        let allTransactions = try await repositoryFactory.transactionRepository.fetchAll()
        let allBudgets = try await repositoryFactory.budgetRepository.fetchAll()
        let allCategories = try await repositoryFactory.budgetCategoryRepository.fetchAll()
        let allStatements = try await repositoryFactory.statementRepository.fetchAll()
        
        // Verify all user data is accessible for export
        #expect(allAccounts.isEmpty, "User should be able to export all account data" == false)
        #expect(allTransactions.isEmpty, "User should be able to export all transaction data" == false)
        #expect(allBudgets.isEmpty, "User should be able to export all budget data" == false)
        #expect(allCategories.isEmpty, "User should be able to export all category data" == false)
        #expect(allStatements.isEmpty, "User should be able to export all statement data" == false)
        
        // Verify data completeness for portability
        let account = allAccounts.first!
        #expect(account.id, "Account ID should be exportable" != nil)
        #expect(account.name, "Account name should be exportable" != nil)
        #expect(account.type, "Account type should be exportable" != nil)
        #expect(account.createdAt, "Account creation date should be exportable" != nil)
        
        let transaction = allTransactions.first!
        #expect(transaction.id, "Transaction ID should be exportable" != nil)
        #expect(transaction.date, "Transaction date should be exportable" != nil)
        #expect(transaction.merchant, "Transaction merchant should be exportable" != nil)
        #expect(transaction.amount, "Transaction amount should be exportable" != nil)
    }
    
    func testRightToErasure() async throws {
        // Create test data
        try await createTestData()
        
        // Verify data exists
        let initialDataCount = try await repositoryFactory.accountRepository.fetchAll().count +
                              try await repositoryFactory.transactionRepository.fetchAll().count +
                              try await repositoryFactory.budgetRepository.fetchAll().count +
                              try await repositoryFactory.statementRepository.fetchAll().count
        
        #expect(initialDataCount > 0, "Test data should exist")
        
        // Exercise right to erasure (complete data deletion)
        try await persistenceController.deleteAllData()
        
        // Verify complete erasure
        let finalDataCount = try await repositoryFactory.accountRepository.fetchAll().count +
                            try await repositoryFactory.transactionRepository.fetchAll().count +
                            try await repositoryFactory.budgetRepository.fetchAll().count +
                            try await repositoryFactory.statementRepository.fetchAll().count
        
        #expect(finalDataCount == 0, "All user data should be completely erased")
    }
}