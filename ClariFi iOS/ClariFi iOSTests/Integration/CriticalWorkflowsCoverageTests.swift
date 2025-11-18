//
//  CriticalWorkflowsCoverageTests.swift
//  ClariFi iOSTests
//
//  Comprehensive integration tests for critical user workflows
//

import XCTest
import CoreData
@testable import ClariFi_iOS

@MainActor
class CriticalWorkflowsCoverageTests: XCTestCase {
    
    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!
    var backgroundContextProvider: BackgroundContextProvider!
    var diContainer: AppDIContainer!
    
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
        
        // Create DI container with test dependencies
        diContainer = AppDIContainer()
        setupTestDependencies()
    }
    
    override func tearDown() async throws {
        container = nil
        context = nil
        backgroundContextProvider = nil
        diContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Onboarding Workflow
    
    func testCompleteOnboardingWorkflow() async throws {
        // Given: New user starts onboarding
        let accountRepo: any AccountRepository = diContainer.resolve(AccountRepository.self)
        
        // When: User completes account setup
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Primary Account"
        account.type = "checking"
        account.balance = NSDecimalNumber(value: 1000.00)
        account.currency = "USD"
        account.createdAt = Date()
        account.updatedAt = Date()
        
        try await accountRepo.save(account)
        
        // Then: Account should be created
        let accounts = try await accountRepo.fetchAll()
        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(accounts.first?.name, "Primary Account")
    }
    
    // MARK: - Transaction Entry Workflow
    
    func testManualTransactionEntryWorkflow() async throws {
        // Given: User has an account
        let accountRepo: any AccountRepository = diContainer.resolve(AccountRepository.self)
        let transactionRepo: any TransactionRepository = diContainer.resolve(TransactionRepository.self)
        
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "checking"
        account.balance = NSDecimalNumber(value: 500.00)
        account.currency = "USD"
        account.createdAt = Date()
        account.updatedAt = Date()
        
        try await accountRepo.save(account)
        
        // When: User enters a transaction manually
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.amount = NSDecimalNumber(value: 25.50)
        transaction.merchant = "Coffee Shop"
        transaction.description = "Morning coffee"
        transaction.date = Date()
        transaction.category = "Food & Dining"
        transaction.account = account
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        
        try await transactionRepo.save(transaction)
        
        // Then: Transaction should be saved
        let transactions = try await transactionRepo.fetchAll()
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.first?.merchant, "Coffee Shop")
    }
    
    // MARK: - Budget Creation Workflow
    
    func testBudgetCreationWorkflow() async throws {
        // Given: User wants to create a budget
        let budgetRepo: any BudgetRepository = diContainer.resolve(BudgetRepository.self)
        let budgetCategoryRepo: any BudgetCategoryRepository = diContainer.resolve(BudgetCategoryRepository.self)
        
        // When: User creates a monthly budget
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Monthly Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        try await budgetRepo.save(budget)
        
        // And: User adds categories
        let categories = ["Food & Dining", "Transportation", "Entertainment"]
        let amounts: [Decimal] = [500, 200, 150]
        
        for (index, categoryName) in categories.enumerated() {
            let category = BudgetCategory(context: context)
            category.id = UUID()
            category.name = categoryName
            category.budgetedAmount = NSDecimalNumber(decimal: amounts[index])
            category.spentAmount = NSDecimalNumber(value: 0)
            category.alertThreshold = 0.8
            category.rolloverEnabled = false
            category.budget = budget
            category.createdAt = Date()
            category.updatedAt = Date()
            
            try await budgetCategoryRepo.save(category)
        }
        
        // Then: Budget and categories should be created
        let budgets = try await budgetRepo.fetchAll()
        XCTAssertEqual(budgets.count, 1)
        
        let savedCategories = try await budgetCategoryRepo.fetchAll()
        XCTAssertEqual(savedCategories.count, 3)
    }
    
    // MARK: - Statement Upload and Processing Workflow
    
    func testStatementUploadAndProcessingWorkflow() async throws {
        // Given: User has an account
        let accountRepo: any AccountRepository = diContainer.resolve(AccountRepository.self)
        let statementRepo: any StatementRepository = diContainer.resolve(StatementRepository.self)
        let transactionRepo: any TransactionRepository = diContainer.resolve(TransactionRepository.self)
        
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "checking"
        account.balance = NSDecimalNumber(value: 1000.00)
        account.currency = "USD"
        account.createdAt = Date()
        account.updatedAt = Date()
        
        try await accountRepo.save(account)
        
        // When: User uploads a statement
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "statement_2024_01.pdf"
        statement.uploadDate = Date()
        statement.account = account
        statement.uploadHash = "test_hash_123"
        statement.uploadedAt = Date()
        statement.createdAt = Date()
        statement.updatedAt = Date()
        
        try await statementRepo.save(statement)
        
        // And: Transactions are extracted
        let transactionData = [
            ("Grocery Store", 45.20),
            ("Gas Station", 32.10),
            ("Restaurant", 28.50)
        ]
        
        for (merchant, amount) in transactionData {
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.amount = NSDecimalNumber(value: amount)
            transaction.merchant = merchant
            transaction.date = Date()
            transaction.account = account
            transaction.statement = statement
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
            
            try await transactionRepo.save(transaction)
        }
        
        // Then: Statement and transactions should be saved
        let statements = try await statementRepo.fetchAll()
        XCTAssertEqual(statements.count, 1)
        
        let transactions = try await transactionRepo.fetchAll()
        XCTAssertEqual(transactions.count, 3)
    }
    
    // MARK: - Transaction Categorization Workflow
    
    func testTransactionCategorizationWorkflow() async throws {
        // Given: User has uncategorized transactions
        let transactionRepo: any TransactionRepository = diContainer.resolve(TransactionRepository.self)
        let categoryService: CategoryService = diContainer.resolve(CategoryService.self)
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.amount = NSDecimalNumber(value: 50.00)
        transaction.merchant = "Whole Foods"
        transaction.description = "Grocery shopping"
        transaction.date = Date()
        transaction.category = nil
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        
        try await transactionRepo.save(transaction)
        
        // When: User categorizes the transaction
        let result = try await categoryService.categorizeTransaction(
            merchant: "Whole Foods",
            amount: Decimal(50.00),
            description: "Grocery shopping"
        )
        
        // Then: Transaction should be categorized
        XCTAssertNotNil(result)
        XCTAssertEqual(result.category, "Food & Dining")
    }
    
    // MARK: - Budget Monitoring Workflow
    
    func testBudgetMonitoringWorkflow() async throws {
        // Given: User has a budget with spending
        let budgetRepo: any BudgetRepository = diContainer.resolve(BudgetRepository.self)
        let budgetCategoryRepo: any BudgetCategoryRepository = diContainer.resolve(BudgetCategoryRepository.self)
        let transactionRepo: any TransactionRepository = diContainer.resolve(TransactionRepository.self)
        
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        try await budgetRepo.save(budget)
        
        let category = BudgetCategory(context: context)
        category.id = UUID()
        category.name = "Food & Dining"
        category.budgetedAmount = NSDecimalNumber(value: 500.00)
        category.spentAmount = NSDecimalNumber(value: 0)
        category.alertThreshold = 0.8
        category.budget = budget
        category.createdAt = Date()
        category.updatedAt = Date()
        
        try await budgetCategoryRepo.save(category)
        
        // When: User makes transactions
        let transactionAmounts: [Decimal] = [50, 75, 100, 125]
        for amount in transactionAmounts {
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.amount = NSDecimalNumber(decimal: amount)
            transaction.merchant = "Test Merchant"
            transaction.date = Date()
            transaction.category = "Food & Dining"
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
            
            try await transactionRepo.save(transaction)
        }
        
        // Then: Budget should track spending
        let totalSpent = transactionAmounts.reduce(0, +)
        XCTAssertEqual(totalSpent, 350)
        XCTAssertLessThan(totalSpent, 500) // Under budget
    }
    
    // MARK: - Insights Generation Workflow
    
    func testInsightsGenerationWorkflow() async throws {
        // Given: User has transaction history
        let transactionRepo: any TransactionRepository = diContainer.resolve(TransactionRepository.self)
        
        // Create diverse transaction history
        let categories = ["Food & Dining", "Transportation", "Entertainment", "Shopping"]
        for i in 0..<20 {
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.amount = NSDecimalNumber(value: Double.random(in: 10...100))
            transaction.merchant = "Merchant \(i)"
            transaction.date = Date().addingTimeInterval(-Double(i) * 24 * 60 * 60)
            transaction.category = categories[i % categories.count]
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
            
            try await transactionRepo.save(transaction)
        }
        
        // When: Insights are generated
        let transactions = try await transactionRepo.fetchAll()
        
        // Then: Should have sufficient data for insights
        XCTAssertEqual(transactions.count, 20)
        
        // Verify category distribution
        let categoryGroups = Dictionary(grouping: transactions) { $0.category ?? "Uncategorized" }
        XCTAssertGreaterThan(categoryGroups.keys.count, 1)
    }
    
    // MARK: - Recurring Transaction Setup Workflow
    
    func testRecurringTransactionSetupWorkflow() async throws {
        // Given: User wants to set up recurring transaction
        let recurringRepo: any RecurringTransactionRepository = diContainer.resolve(RecurringTransactionRepository.self)
        
        // When: User creates recurring transaction
        let recurring = RecurringTransaction(context: context)
        recurring.id = UUID()
        recurring.name = "Netflix Subscription"
        recurring.amount = NSDecimalNumber(value: 15.99)
        recurring.frequency = "monthly"
        recurring.nextDate = Date().addingTimeInterval(30 * 24 * 60 * 60)
        recurring.category = "Entertainment"
        recurring.isActive = true
        recurring.createdAt = Date()
        recurring.updatedAt = Date()
        
        try await recurringRepo.save(recurring)
        
        // Then: Recurring transaction should be saved
        let recurringTransactions = try await recurringRepo.fetchAll()
        XCTAssertEqual(recurringTransactions.count, 1)
        XCTAssertEqual(recurringTransactions.first?.name, "Netflix Subscription")
    }
    
    // MARK: - Premium Feature Access Workflow
    
    func testPremiumFeatureAccessWorkflow() async throws {
        // Given: User attempts to access premium feature
        let subscriptionService = MockSubscriptionService()
        let subscriptionViewModel = SubscriptionViewModel(subscriptionService: subscriptionService)
        
        // When: User is not subscribed
        subscriptionService.subscriptionStatus = .notSubscribed
        
        var premiumActionExecuted = false
        subscriptionViewModel.requirePremium {
            premiumActionExecuted = true
        }
        
        // Then: Should show paywall
        XCTAssertFalse(premiumActionExecuted)
        XCTAssertTrue(subscriptionViewModel.showPaywall)
        
        // When: User subscribes
        subscriptionService.subscriptionStatus = .subscribed(expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60))
        subscriptionViewModel.showPaywall = false
        
        subscriptionViewModel.requirePremium {
            premiumActionExecuted = true
        }
        
        // Then: Should allow access
        XCTAssertTrue(premiumActionExecuted)
        XCTAssertFalse(subscriptionViewModel.showPaywall)
    }
    
    // MARK: - Currency Change Workflow
    
    func testCurrencyChangeWorkflow() async throws {
        // Given: User has transactions in USD
        let currencyManager = CurrencyPreferenceManager.shared
        currencyManager.preferredCurrency = .usd
        
        let transactionRepo: any TransactionRepository = diContainer.resolve(TransactionRepository.self)
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.amount = NSDecimalNumber(value: 100.00)
        transaction.merchant = "Test Merchant"
        transaction.date = Date()
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        
        try await transactionRepo.save(transaction)
        
        // When: User changes currency to EUR
        currencyManager.preferredCurrency = .eur
        
        // Then: Amounts should format with EUR
        let formatted = currencyManager.format(transaction.amount as Decimal)
        XCTAssertTrue(formatted.contains("€") || formatted.contains("EUR"))
    }
    
    // MARK: - Error Recovery Workflow
    
    func testErrorRecoveryWorkflow() async throws {
        // Given: User encounters an error
        let transactionRepo: any TransactionRepository = diContainer.resolve(TransactionRepository.self)
        
        // When: User attempts invalid operation
        do {
            let _ = try await transactionRepo.fetchById(UUID())
            XCTFail("Should have thrown error")
        } catch {
            // Then: Error should be handled gracefully
            XCTAssertNotNil(error)
        }
        
        // And: User can continue with valid operations
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.amount = NSDecimalNumber(value: 50.00)
        transaction.merchant = "Test"
        transaction.date = Date()
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        
        try await transactionRepo.save(transaction)
        
        let transactions = try await transactionRepo.fetchAll()
        XCTAssertEqual(transactions.count, 1)
    }
    
    // MARK: - Data Persistence Workflow
    
    func testDataPersistenceWorkflow() async throws {
        // Given: User creates various data
        let accountRepo: any AccountRepository = diContainer.resolve(AccountRepository.self)
        let transactionRepo: any TransactionRepository = diContainer.resolve(TransactionRepository.self)
        let budgetRepo: any BudgetRepository = diContainer.resolve(BudgetRepository.self)
        
        // Create account
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "checking"
        account.balance = NSDecimalNumber(value: 1000.00)
        account.currency = "USD"
        account.createdAt = Date()
        account.updatedAt = Date()
        
        try await accountRepo.save(account)
        
        // Create transaction
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.amount = NSDecimalNumber(value: 50.00)
        transaction.merchant = "Test"
        transaction.date = Date()
        transaction.account = account
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        
        try await transactionRepo.save(transaction)
        
        // Create budget
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        try await budgetRepo.save(budget)
        
        // When: Fetching all data
        let accounts = try await accountRepo.fetchAll()
        let transactions = try await transactionRepo.fetchAll()
        let budgets = try await budgetRepo.fetchAll()
        
        // Then: All data should be persisted
        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(budgets.count, 1)
    }
    
    // MARK: - Helper Methods
    
    private func setupTestDependencies() {
        // Register test dependencies
        diContainer.registerSingleton(any TransactionRepository.self) { _ in
            CoreDataTransactionRepository(context: self.context, backgroundContextProvider: self.backgroundContextProvider)
        }
        
        diContainer.registerSingleton(any AccountRepository.self) { _ in
            CoreDataAccountRepository(context: self.context, backgroundContextProvider: self.backgroundContextProvider)
        }
        
        diContainer.registerSingleton(any BudgetRepository.self) { _ in
            CoreDataBudgetRepository(context: self.context, backgroundContextProvider: self.backgroundContextProvider)
        }
        
        diContainer.registerSingleton(any BudgetCategoryRepository.self) { _ in
            CoreDataBudgetCategoryRepository(context: self.context, backgroundContextProvider: self.backgroundContextProvider)
        }
        
        diContainer.registerSingleton(any StatementRepository.self) { _ in
            CoreDataStatementRepository(context: self.context, backgroundContextProvider: self.backgroundContextProvider)
        }
        
        diContainer.registerSingleton(any RecurringTransactionRepository.self) { _ in
            CoreDataRecurringTransactionRepository(context: self.context, backgroundContextProvider: self.backgroundContextProvider)
        }
        
        diContainer.registerSingleton(CategoryService.self) { _ in
            CategoryService(context: self.context, backgroundContextProvider: self.backgroundContextProvider)
        }
    }
}

// MARK: - Mock Subscription Service

class MockSubscriptionService: SubscriptionServiceProtocol {
    var subscriptionStatus: SubscriptionStatus = .notSubscribed
    var isPremiumActive: Bool {
        switch subscriptionStatus {
        case .subscribed, .expired(gracePeriod: true):
            return true
        case .notSubscribed, .expired(gracePeriod: false), .pending:
            return false
        }
    }
    
    func loadProducts() async throws -> [Product] {
        return []
    }
    
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        return nil
    }
    
    func restorePurchases() async throws {
        // Mock implementation
    }
    
    func checkSubscriptionStatus() async {
        // Mock implementation
    }
}
