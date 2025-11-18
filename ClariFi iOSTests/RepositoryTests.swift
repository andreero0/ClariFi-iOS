//
//  RepositoryTests.swift
//  ClariFi iOS Tests
//
//  Created by aEro on 2025-10-10.
//

import Testing
import CoreData
@testable import ClariFi_iOS

struct RepositoryTests {
    
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
        account.lastFourDigits = "1234"
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
    
    private func createTestBudget(name: String = "Test Budget", period: String = "monthly") -> Budget {
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = name
        budget.period = period
        budget.startDate = Date()
        budget.isActive = true
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        return budget
    }
    
    private func createTestBudgetCategory(budget: Budget, name: String = "Test Category", budgetedAmount: Double = 100.0) -> BudgetCategory {
        let category = BudgetCategory(context: context)
        category.id = UUID()
        category.name = name
        category.budgetedAmount = NSDecimalNumber(value: budgetedAmount)
        category.spentAmount = NSDecimalNumber(value: 0.0)
        category.rolloverEnabled = false
        category.alertThreshold = 0.8
        category.createdAt = Date()
        category.updatedAt = Date()
        category.budget = budget
        return category
    }
    
    private func createTestStatement(fileName: String = "test.pdf", fileHash: String = "abc123") -> Statement {
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = fileName
        statement.uploadDate = Date()
        statement.fileHash = fileHash
        statement.processingStatus = "pending"
        statement.fileSize = 1024
        statement.documentType = "pdf"
        statement.createdAt = Date()
        statement.updatedAt = Date()
        return statement
    }
    
    // MARK: - Account Repository Tests
    
    func testAccountRepository_CreateAndFetch() async throws {
        let accountRepo = repositoryFactory.accountRepository
        
        // Create test account
        let account = createTestAccount()
        
        // Save account
        try await accountRepo.save(account)
        
        // Fetch account
        let fetchedAccount = try await accountRepo.fetchById(account.id!)
        #expect(fetchedAccount != nil)
        #expect(fetchedAccount?.name == "Test Account")
        #expect(fetchedAccount?.type == "checking")
    }
    
    func testAccountRepository_FetchActiveAccounts() async throws {
        let accountRepo = repositoryFactory.accountRepository
        
        // Create active account
        let activeAccount = createTestAccount(name: "Active Account")
        activeAccount.isActive = true
        
        // Create inactive account
        let inactiveAccount = createTestAccount(name: "Inactive Account", type: "savings")
        inactiveAccount.isActive = false
        
        try await accountRepo.save(activeAccount)
        try await accountRepo.save(inactiveAccount)
        
        // Fetch only active accounts
        let activeAccounts = try await accountRepo.fetchActiveAccounts()
        #expect(activeAccounts.count == 1)
        #expect(activeAccounts.first?.name == "Active Account")
    }
    
    // MARK: - Transaction Repository Tests
    
    func testTransactionRepository_CreateAndFetch() async throws {
        let transactionRepo = repositoryFactory.transactionRepository
        let accountRepo = repositoryFactory.accountRepository
        
        // Create test account first
        let account = createTestAccount()
        try await accountRepo.save(account)
        
        // Create test transaction
        let transaction = createTestTransaction(account: account)
        
        // Save transaction
        try await transactionRepo.save(transaction)
        
        // Fetch transaction
        let fetchedTransaction = try await transactionRepo.fetchById(transaction.id!)
        #expect(fetchedTransaction != nil)
        #expect(fetchedTransaction?.merchant == "Test Store")
        #expect(fetchedTransaction?.amount == NSDecimalNumber(value: 25.99))
    }
    
    func testTransactionRepository_FetchByDateRange() async throws {
        let transactionRepo = repositoryFactory.transactionRepository
        let accountRepo = repositoryFactory.accountRepository
        
        // Create test account
        let account = createTestAccount()
        try await accountRepo.save(account)
        
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // Create transactions with different dates
        let todayTransaction = createTestTransaction(account: account, merchant: "Today Store")
        todayTransaction.date = today
        
        let yesterdayTransaction = createTestTransaction(account: account, merchant: "Yesterday Store", amount: 20.00)
        yesterdayTransaction.date = yesterday
        
        try await transactionRepo.save(todayTransaction)
        try await transactionRepo.save(yesterdayTransaction)
        
        // Fetch transactions in date range
        let transactions = try await transactionRepo.fetchByDateRange(yesterday, tomorrow)
        #expect(transactions.count == 2)
        
        // Fetch only today's transactions
        let todayTransactions = try await transactionRepo.fetchByDateRange(today, today)
        #expect(todayTransactions.count == 1)
        #expect(todayTransactions.first?.merchant == "Today Store")
    }
    
    // MARK: - Budget Repository Tests
    
    func testBudgetRepository_CreateAndFetchActive() async throws {
        let budgetRepo = repositoryFactory.budgetRepository
        
        // Create test budget
        let budget = createTestBudget()
        
        try await budgetRepo.save(budget)
        
        // Fetch active budget
        let activeBudget = try await budgetRepo.fetchActiveBudget()
        #expect(activeBudget != nil)
        #expect(activeBudget?.name == "Test Budget")
        #expect(activeBudget?.period == "monthly")
    }
    
    // MARK: - Budget Category Repository Tests
    
    func testBudgetCategoryRepository_CreateAndFetch() async throws {
        let budgetRepo = repositoryFactory.budgetRepository
        let categoryRepo = repositoryFactory.budgetCategoryRepository
        
        // Create test budget
        let budget = createTestBudget()
        try await budgetRepo.save(budget)
        
        // Create test category
        let category = createTestBudgetCategory(budget: budget, name: "Food", budgetedAmount: 500.0)
        try await categoryRepo.save(category)
        
        // Fetch category
        let fetchedCategory = try await categoryRepo.fetchById(category.id!)
        #expect(fetchedCategory != nil)
        #expect(fetchedCategory?.name == "Food")
        #expect(fetchedCategory?.budgetedAmount == NSDecimalNumber(value: 500.0))
    }
    
    // MARK: - Statement Repository Tests
    
    func testStatementRepository_CreateAndFetch() async throws {
        let statementRepo = repositoryFactory.statementRepository
        
        // Create test statement
        let statement = createTestStatement()
        try await statementRepo.save(statement)
        
        // Fetch statement
        let fetchedStatement = try await statementRepo.fetchById(statement.id!)
        #expect(fetchedStatement != nil)
        #expect(fetchedStatement?.fileName == "test.pdf")
        #expect(fetchedStatement?.fileHash == "abc123")
    }
    
    // MARK: - Core Data Model Validation Tests
    
    func testTransactionValidation_InvalidMerchant() {
        let transaction = createTestTransaction(account: createTestAccount())
        transaction.merchant = "" // Invalid empty merchant
        
        XCTAssertThrowsError(try transaction.validateForInsert()) { error in
            XCTAssertTrue(error is ValidationError)
            if let validationError = error as? ValidationError {
                XCTAssertEqual(validationError, CoreDataValidationError.invalidMerchant)
            }
        }
    }
    
    func testTransactionValidation_InvalidAmount() {
        let transaction = createTestTransaction(account: createTestAccount())
        transaction.amount = NSDecimalNumber.zero // Invalid zero amount
        
        XCTAssertThrowsError(try transaction.validateForInsert()) { error in
            XCTAssertTrue(error is ValidationError)
            if let validationError = error as? ValidationError {
                XCTAssertEqual(validationError, CoreDataValidationError.invalidAmount)
            }
        }
    }
    
    func testAccountValidation_InvalidType() {
        let account = createTestAccount()
        account.type = "invalid_type" // Invalid account type
        
        XCTAssertThrowsError(try account.validateForInsert()) { error in
            XCTAssertTrue(error is ValidationError)
            if let validationError = error as? ValidationError {
                XCTAssertEqual(validationError, CoreDataValidationError.invalidAccountType)
            }
        }
    }
    
    // MARK: - Repository CRUD Operation Tests
    
    func testTransactionRepository_BatchUpdate() async throws {
        let accountRepo = repositoryFactory.accountRepository
        let transactionRepo = repositoryFactory.transactionRepository
        
        // Create account and transactions
        let account = createTestAccount()
        let transaction1 = createTestTransaction(account: account, merchant: "Store 1")
        let transaction2 = createTestTransaction(account: account, merchant: "Store 2")
        
        try await accountRepo.save(account)
        try await transactionRepo.save(transaction1)
        try await transactionRepo.save(transaction2)
        
        // Update categories
        transaction1.category = "Food"
        transaction2.category = "Transport"
        
        // Batch update
        try await transactionRepo.batchUpdate([transaction1, transaction2])
        
        // Verify updates
        let updatedTransaction1 = try await transactionRepo.fetchById(transaction1.id!)
        let updatedTransaction2 = try await transactionRepo.fetchById(transaction2.id!)
        
        #expect(updatedTransaction1?.category == "Food")
        #expect(updatedTransaction2?.category == "Transport")
    }
    
    func testAccountRepository_GetTransactionCount() async throws {
        let accountRepo = repositoryFactory.accountRepository
        let transactionRepo = repositoryFactory.transactionRepository
        
        // Create account and transactions
        let account = createTestAccount()
        let transaction1 = createTestTransaction(account: account)
        let transaction2 = createTestTransaction(account: account)
        
        try await accountRepo.save(account)
        try await transactionRepo.save(transaction1)
        try await transactionRepo.save(transaction2)
        
        // Get transaction count
        let count = try await accountRepo.getTransactionCount(for: account)
        #expect(count == 2)
    }
}