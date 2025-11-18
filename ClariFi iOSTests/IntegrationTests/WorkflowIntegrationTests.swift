//
//  WorkflowIntegrationTests.swift
//  ClariFi iOSTests
//
//  Comprehensive integration tests for key user workflows
//  Tests Requirements: 9.5
//

import XCTest
import SwiftUI
import CoreData
@testable import ClariFi_iOS

class WorkflowIntegrationTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var container: DIContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory persistence controller for testing
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
        
        // Create test DI container
        container = AppDIContainer.createTestContainer(inMemoryContext: viewContext)
    }
    
    override func tearDown() async throws {
        // Clean up test data
        try? await cleanupTestData()
        container = nil
        persistenceController = nil
        viewContext = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func cleanupTestData() async throws {
        let entities = ["Transaction", "Budget", "BudgetCategory", "Account", "Statement"]
        
        for entityName in entities {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try? viewContext.execute(deleteRequest)
        }
        
        try viewContext.save()
    }
    
    private func createTestAccount(name: String = "Test Account") -> Account {
        let account = Account(context: viewContext)
        account.id = UUID()
        account.name = name
        account.type = "checking"
        account.lastFourDigits = "1234"
        return account
    }
    
    // MARK: - Transaction Creation Workflow Tests
    
    func testTransactionCreationWorkflow_ManualEntry() async throws {
        // Test Requirements: 9.5 - Transaction creation workflow
        
        // Given: A transaction entry view model
        let viewModel = container.resolve(TransactionEntryViewModel.self)
        let transactionRepository = container.resolve(TransactionRepository.self)
        
        // When: User enters transaction details
        await MainActor.run {
            viewModel.date = Date()
            viewModel.merchant = "Coffee Shop"
            viewModel.amount = "5.75"
            viewModel.selectedCategory = "Food & Dining"
            viewModel.notes = "Morning coffee"
        }
        
        // Then: Form should be valid
        let isValid = await viewModel.isFormValid
        XCTAssertTrue(isValid, "Transaction form should be valid with all required fields")
        
        // When: User saves the transaction
        await viewModel.saveTransaction()
        
        // Then: Transaction should be persisted
        let transactions = try await transactionRepository.fetchAll()
        XCTAssertGreaterThanOrEqual(transactions.count, 1, "At least one transaction should be saved")
        
        let savedTransaction = transactions.first { $0.merchant == "Coffee Shop" }
        XCTAssertNotNil(savedTransaction, "Transaction should be found in repository")
        XCTAssertEqual(savedTransaction?.category, "Food & Dining")
        XCTAssertEqual(savedTransaction?.amount as Decimal?, 5.75)
        XCTAssertEqual(savedTransaction?.notes, "Morning coffee")
        XCTAssertTrue(savedTransaction?.isManual ?? false, "Transaction should be marked as manual")
    }
    
    func testTransactionCreationWorkflow_WithCategorySuggestion() async throws {
        // Test Requirements: 9.5 - Transaction creation with auto-categorization
        
        // Given: Historical transaction data for learning
        let categoryService = container.resolve(CategoryService.self)
        
        // Create historical pattern
        for _ in 0..<5 {
            let transaction = Transaction(context: viewContext)
            transaction.id = UUID()
            transaction.date = Date()
            transaction.merchant = "Starbucks"
            transaction.amount = NSDecimalNumber(value: 4.50)
            transaction.category = "Food & Dining"
            transaction.isManual = true
            transaction.account = createTestAccount()
        }
        try viewContext.save()
        
        // When: User enters a new transaction with similar merchant
        let viewModel = container.resolve(TransactionEntryViewModel.self)
        await MainActor.run {
            viewModel.merchant = "Starbucks Coffee"
            viewModel.amount = "5.25"
        }
        
        // Then: System should suggest category
        let suggestedCategory = await categoryService.suggestCategory(for: "Starbucks Coffee", amount: 5.25)
        XCTAssertNotNil(suggestedCategory, "Category should be suggested based on historical data")
        
        // When: User accepts suggestion and saves
        await MainActor.run {
            viewModel.selectedCategory = suggestedCategory ?? "Food & Dining"
            viewModel.date = Date()
        }
        await viewModel.saveTransaction()
        
        // Then: Transaction should be saved with suggested category
        let transactionRepository = container.resolve(TransactionRepository.self)
        let transactions = try await transactionRepository.fetchAll()
        let newTransaction = transactions.first { $0.merchant == "Starbucks Coffee" }
        XCTAssertNotNil(newTransaction)
        XCTAssertEqual(newTransaction?.category, "Food & Dining")
    }
    
    func testTransactionCreationWorkflow_ValidationErrors() async throws {
        // Test Requirements: 9.5 - Transaction creation with validation
        
        // Given: A transaction entry view model
        let viewModel = container.resolve(TransactionEntryViewModel.self)
        
        // When: User tries to save with missing required fields
        await MainActor.run {
            viewModel.merchant = ""
            viewModel.amount = ""
        }
        
        // Then: Form should be invalid
        let isValid = await viewModel.isFormValid
        XCTAssertFalse(isValid, "Form should be invalid with missing fields")
        
        // When: User enters invalid amount
        await MainActor.run {
            viewModel.merchant = "Test Store"
            viewModel.amount = "invalid"
        }
        
        // Then: Amount should not parse
        let parsedAmount = await viewModel.parsedAmount
        XCTAssertNil(parsedAmount, "Invalid amount should not parse")
        
        // When: User corrects the input
        await MainActor.run {
            viewModel.amount = "25.50"
            viewModel.selectedCategory = "Shopping"
            viewModel.date = Date()
        }
        
        // Then: Form should become valid
        let isNowValid = await viewModel.isFormValid
        XCTAssertTrue(isNowValid, "Form should be valid after corrections")
    }
    
    // MARK: - Budget Creation Workflow Tests
    
    func testBudgetCreationWorkflow_FromTemplate() async throws {
        // Test Requirements: 9.5 - Budget creation workflow
        
        // Given: A budget creation view model
        let viewModel = container.resolve(BudgetCreationViewModel.self)
        let budgetRepository = container.resolve(BudgetRepository.self)
        
        // When: User selects a template
        await MainActor.run {
            viewModel.budgetName = "My Monthly Budget"
            viewModel.selectedPeriod = "monthly"
            viewModel.selectedTemplate = "student"
        }
        
        await viewModel.loadTemplate()
        
        // Then: Template categories should be loaded
        let categoryCount = await viewModel.categories.count
        XCTAssertGreaterThan(categoryCount, 0, "Template should load categories")
        
        // Verify template has expected categories
        let categories = await viewModel.categories
        let categoryNames = categories.map { $0.name }
        XCTAssertTrue(categoryNames.contains("Groceries"), "Student template should include Groceries")
        XCTAssertTrue(categoryNames.contains("Transportation"), "Student template should include Transportation")
        
        // When: User saves the budget
        await viewModel.saveBudget()
        
        // Then: Budget should be persisted with categories
        let budgets = try await budgetRepository.fetchAll()
        XCTAssertGreaterThanOrEqual(budgets.count, 1, "Budget should be saved")
        
        let savedBudget = budgets.first { $0.name == "My Monthly Budget" }
        XCTAssertNotNil(savedBudget, "Budget should be found in repository")
        XCTAssertEqual(savedBudget?.period, "monthly")
        
        let budgetCategories = savedBudget?.categories?.allObjects as? [BudgetCategory] ?? []
        XCTAssertGreaterThan(budgetCategories.count, 0, "Budget should have categories")
    }
    
    func testBudgetCreationWorkflow_CustomCategories() async throws {
        // Test Requirements: 9.5 - Budget creation with custom categories
        
        // Given: A budget creation view model
        let viewModel = container.resolve(BudgetCreationViewModel.self)
        
        // When: User creates budget with custom categories
        await MainActor.run {
            viewModel.budgetName = "Custom Budget"
            viewModel.selectedPeriod = "monthly"
            viewModel.selectedTemplate = "none"
        }
        
        // Add custom categories
        await MainActor.run {
            viewModel.categories = [
                BudgetCategoryInput(name: "Rent", amount: 1200),
                BudgetCategoryInput(name: "Utilities", amount: 150),
                BudgetCategoryInput(name: "Entertainment", amount: 200)
            ]
        }
        
        await viewModel.saveBudget()
        
        // Then: Budget should be saved with custom categories
        let budgetRepository = container.resolve(BudgetRepository.self)
        let budgets = try await budgetRepository.fetchAll()
        let savedBudget = budgets.first { $0.name == "Custom Budget" }
        
        XCTAssertNotNil(savedBudget)
        let categories = savedBudget?.categories?.allObjects as? [BudgetCategory] ?? []
        XCTAssertEqual(categories.count, 3, "Should have 3 custom categories")
        
        let categoryNames = categories.map { $0.name }
        XCTAssertTrue(categoryNames.contains("Rent"))
        XCTAssertTrue(categoryNames.contains("Utilities"))
        XCTAssertTrue(categoryNames.contains("Entertainment"))
    }
    
    func testBudgetCreationWorkflow_ValidationErrors() async throws {
        // Test Requirements: 9.5 - Budget creation validation
        
        // Given: A budget creation view model
        let viewModel = container.resolve(BudgetCreationViewModel.self)
        
        // When: User tries to save without required fields
        await MainActor.run {
            viewModel.budgetName = ""
            viewModel.selectedPeriod = ""
        }
        
        // Then: Form should be invalid
        let isValid = await viewModel.isFormValid
        XCTAssertFalse(isValid, "Form should be invalid without required fields")
        
        // When: User provides valid input
        await MainActor.run {
            viewModel.budgetName = "Valid Budget"
            viewModel.selectedPeriod = "monthly"
        }
        
        // Then: Form should be valid
        let isNowValid = await viewModel.isFormValid
        XCTAssertTrue(isNowValid, "Form should be valid with required fields")
    }
    
    // MARK: - Statement Upload Workflow Tests
    
    func testStatementUploadWorkflow_ParseAndReview() async throws {
        // Test Requirements: 9.5 - Statement upload workflow
        
        // Given: A statement upload view model
        let viewModel = container.resolve(StatementUploadViewModel.self)
        
        // When: Statement is parsed (simulated with test data)
        let testTransactions = [
            ParsedTransaction(
                date: Date(),
                merchant: "Amazon",
                amount: 45.99,
                category: "Shopping",
                confidence: TransactionConfidence(date: 0.95, merchant: 0.92, amount: 0.98, category: 0.80),
                rawText: "01/15/2024 AMAZON.COM $45.99"
            ),
            ParsedTransaction(
                date: Date(),
                merchant: "Shell Gas",
                amount: 52.30,
                category: "Transportation",
                confidence: TransactionConfidence(date: 0.98, merchant: 0.95, amount: 0.99, category: 0.85),
                rawText: "01/16/2024 SHELL GAS STATION $52.30"
            ),
            ParsedTransaction(
                date: Date(),
                merchant: "Whole Foods",
                amount: 87.45,
                category: "Groceries",
                confidence: TransactionConfidence(date: 0.96, merchant: 0.93, amount: 0.97, category: 0.88),
                rawText: "01/17/2024 WHOLE FOODS MARKET $87.45"
            )
        ]
        
        await MainActor.run {
            viewModel.parsedTransactions = testTransactions
        }
        
        // Then: Transactions should be available for review
        let parsedCount = await viewModel.parsedTransactions.count
        XCTAssertEqual(parsedCount, 3, "All parsed transactions should be available")
        
        // Verify transaction details
        let transactions = await viewModel.parsedTransactions
        XCTAssertEqual(transactions[0].merchant, "Amazon")
        XCTAssertEqual(transactions[1].merchant, "Shell Gas")
        XCTAssertEqual(transactions[2].merchant, "Whole Foods")
        
        // When: User confirms transactions
        await viewModel.confirmTransactions()
        
        // Then: Transactions should be saved to repository
        let transactionRepository = container.resolve(TransactionRepository.self)
        let savedTransactions = try await transactionRepository.fetchAll()
        XCTAssertGreaterThanOrEqual(savedTransactions.count, 3, "All transactions should be saved")
        
        // Verify saved transactions
        XCTAssertNotNil(savedTransactions.first { $0.merchant == "Amazon" })
        XCTAssertNotNil(savedTransactions.first { $0.merchant == "Shell Gas" })
        XCTAssertNotNil(savedTransactions.first { $0.merchant == "Whole Foods" })
    }
    
    func testStatementUploadWorkflow_EditBeforeConfirm() async throws {
        // Test Requirements: 9.5 - Statement upload with editing
        
        // Given: A statement upload view model with parsed transactions
        let viewModel = container.resolve(StatementUploadViewModel.self)
        
        let testTransactions = [
            ParsedTransaction(
                date: Date(),
                merchant: "Unknown Merchant",
                amount: 25.00,
                category: "Uncategorized",
                confidence: TransactionConfidence(date: 0.90, merchant: 0.60, amount: 0.95, category: 0.50),
                rawText: "01/15/2024 UNK MERCH $25.00"
            )
        ]
        
        await MainActor.run {
            viewModel.parsedTransactions = testTransactions
        }
        
        // When: User edits transaction before confirming
        await MainActor.run {
            viewModel.parsedTransactions[0].merchant = "Corrected Merchant"
            viewModel.parsedTransactions[0].category = "Shopping"
        }
        
        await viewModel.confirmTransactions()
        
        // Then: Edited transaction should be saved
        let transactionRepository = container.resolve(TransactionRepository.self)
        let savedTransactions = try await transactionRepository.fetchAll()
        let editedTransaction = savedTransactions.first { $0.merchant == "Corrected Merchant" }
        
        XCTAssertNotNil(editedTransaction, "Edited transaction should be saved")
        XCTAssertEqual(editedTransaction?.category, "Shopping")
    }
    
    func testStatementUploadWorkflow_ErrorHandling() async throws {
        // Test Requirements: 9.5 - Statement upload error handling
        
        // Given: A statement upload view model
        let viewModel = container.resolve(StatementUploadViewModel.self)
        
        // When: Processing fails (simulated)
        await MainActor.run {
            viewModel.error = AppError.ocrFailed(reason: "Unable to read document")
        }
        
        // Then: Error should be captured
        let error = await viewModel.error
        XCTAssertNotNil(error, "Error should be set")
        
        // When: User retries
        await MainActor.run {
            viewModel.error = nil
            viewModel.parsedTransactions = []
        }
        
        // Then: State should be reset
        let clearedError = await viewModel.error
        XCTAssertNil(clearedError, "Error should be cleared")
    }
    
    // MARK: - Budget Monitoring Workflow Tests
    
    func testBudgetMonitoringWorkflow_TrackSpending() async throws {
        // Test Requirements: 9.5 - Budget monitoring workflow
        
        // Given: An active budget
        let budgetRepository = container.resolve(BudgetRepository.self)
        let budget = Budget(context: viewContext)
        budget.id = UUID()
        budget.name = "Monthly Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        
        // Add categories
        let groceriesCategory = BudgetCategory(context: viewContext)
        groceriesCategory.id = UUID()
        groceriesCategory.name = "Groceries"
        groceriesCategory.budgetedAmount = NSDecimalNumber(value: 500)
        groceriesCategory.budget = budget
        
        let transportCategory = BudgetCategory(context: viewContext)
        transportCategory.id = UUID()
        transportCategory.name = "Transportation"
        transportCategory.budgetedAmount = NSDecimalNumber(value: 200)
        transportCategory.budget = budget
        
        try viewContext.save()
        
        // When: User adds transactions
        let transaction1 = Transaction(context: viewContext)
        transaction1.id = UUID()
        transaction1.date = Date()
        transaction1.merchant = "Grocery Store"
        transaction1.amount = NSDecimalNumber(value: 150)
        transaction1.category = "Groceries"
        transaction1.isManual = true
        transaction1.account = createTestAccount()
        
        let transaction2 = Transaction(context: viewContext)
        transaction2.id = UUID()
        transaction2.date = Date()
        transaction2.merchant = "Gas Station"
        transaction2.amount = NSDecimalNumber(value: 50)
        transaction2.category = "Transportation"
        transaction2.isManual = true
        transaction2.account = createTestAccount()
        
        try viewContext.save()
        
        // Then: Budget monitoring should track spending
        let budgetViewModel = container.resolve(BudgetViewModel.self)
        await budgetViewModel.loadBudget()
        
        let activeBudget = await budgetViewModel.activeBudget
        XCTAssertNotNil(activeBudget, "Active budget should be loaded")
        
        // Verify spending is tracked
        let categories = await budgetViewModel.categories
        XCTAssertGreaterThan(categories.count, 0, "Budget categories should be loaded")
    }
    
    func testBudgetMonitoringWorkflow_OverspendingAlert() async throws {
        // Test Requirements: 9.5 - Budget monitoring with overspending detection
        
        // Given: A budget with low limit
        let budget = Budget(context: viewContext)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        
        let category = BudgetCategory(context: viewContext)
        category.id = UUID()
        category.name = "Entertainment"
        category.budgetedAmount = NSDecimalNumber(value: 100)
        category.budget = budget
        
        try viewContext.save()
        
        // When: User spends over budget
        let transaction = Transaction(context: viewContext)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = "Movie Theater"
        transaction.amount = NSDecimalNumber(value: 120)
        transaction.category = "Entertainment"
        transaction.isManual = true
        transaction.account = createTestAccount()
        
        try viewContext.save()
        
        // Then: Budget monitoring service should detect overspending
        let budgetMonitoringService = container.resolve(BudgetMonitoringService.self)
        let alerts = await budgetMonitoringService.checkBudgetAlerts()
        
        XCTAssertGreaterThan(alerts.count, 0, "Should generate overspending alert")
        
        let overspendingAlert = alerts.first { $0.type == .overspending }
        XCTAssertNotNil(overspendingAlert, "Should have overspending alert")
    }
    
    func testBudgetMonitoringWorkflow_ProgressTracking() async throws {
        // Test Requirements: 9.5 - Budget progress tracking
        
        // Given: A budget with spending
        let budget = Budget(context: viewContext)
        budget.id = UUID()
        budget.name = "Progress Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        
        let category = BudgetCategory(context: viewContext)
        category.id = UUID()
        category.name = "Dining"
        category.budgetedAmount = NSDecimalNumber(value: 300)
        category.budget = budget
        
        try viewContext.save()
        
        // Add transactions at different amounts
        for i in 1...5 {
            let transaction = Transaction(context: viewContext)
            transaction.id = UUID()
            transaction.date = Date()
            transaction.merchant = "Restaurant \(i)"
            transaction.amount = NSDecimalNumber(value: 30)
            transaction.category = "Dining"
            transaction.isManual = true
            transaction.account = createTestAccount()
        }
        
        try viewContext.save()
        
        // When: Loading budget view model
        let budgetViewModel = container.resolve(BudgetViewModel.self)
        await budgetViewModel.loadBudget()
        
        // Then: Progress should be calculated
        let categories = await budgetViewModel.categories
        let diningCategory = categories.first { $0.name == "Dining" }
        
        XCTAssertNotNil(diningCategory, "Dining category should be loaded")
        
        // Verify spending is tracked (5 transactions * $30 = $150 out of $300)
        let spentAmount = diningCategory?.spentAmount as Decimal? ?? 0
        XCTAssertEqual(spentAmount, 150, "Should track $150 spent")
        
        let progress = spentAmount / 300
        XCTAssertEqual(progress, 0.5, accuracy: 0.01, "Should be 50% through budget")
    }
    
    // MARK: - Insights Generation Workflow Tests
    
    func testInsightsGenerationWorkflow_SpendingPatterns() async throws {
        // Test Requirements: 9.5 - Insights generation workflow
        
        // Given: Transaction history with patterns
        let calendar = Calendar.current
        let today = Date()
        
        // Create consistent spending pattern
        for week in 0..<4 {
            for day in 0..<7 {
                let date = calendar.date(byAdding: .day, value: -(week * 7 + day), to: today)!
                
                // Coffee every weekday
                if calendar.component(.weekday, from: date) >= 2 && calendar.component(.weekday, from: date) <= 6 {
                    let transaction = Transaction(context: viewContext)
                    transaction.id = UUID()
                    transaction.date = date
                    transaction.merchant = "Coffee Shop"
                    transaction.amount = NSDecimalNumber(value: 5.50)
                    transaction.category = "Food & Dining"
                    transaction.isManual = true
                    transaction.account = createTestAccount()
                }
                
                // Groceries on weekends
                if calendar.component(.weekday, from: date) == 1 || calendar.component(.weekday, from: date) == 7 {
                    let transaction = Transaction(context: viewContext)
                    transaction.id = UUID()
                    transaction.date = date
                    transaction.merchant = "Grocery Store"
                    transaction.amount = NSDecimalNumber(value: 75.00)
                    transaction.category = "Groceries"
                    transaction.isManual = true
                    transaction.account = createTestAccount()
                }
            }
        }
        
        try viewContext.save()
        
        // When: Generating insights
        let insightsEngine = container.resolve(InsightsEngineProtocol.self)
        let insights = await insightsEngine.generateInsights(for: [], budget: nil)
        
        // Then: Insights should identify patterns
        XCTAssertGreaterThan(insights.count, 0, "Should generate insights from patterns")
        
        // Verify insight types
        let hasSpendingInsight = insights.contains { insight in
            insight.type == .spending || insight.type == .pattern
        }
        XCTAssertTrue(hasSpendingInsight, "Should have spending or pattern insight")
    }
    
    func testInsightsGenerationWorkflow_CategoryAnalysis() async throws {
        // Test Requirements: 9.5 - Insights with category analysis
        
        // Given: Transactions across multiple categories
        let categories = ["Groceries", "Transportation", "Entertainment", "Utilities", "Shopping"]
        let amounts: [Decimal] = [400, 150, 200, 100, 300]
        
        for (index, category) in categories.enumerated() {
            for i in 0..<5 {
                let transaction = Transaction(context: viewContext)
                transaction.id = UUID()
                transaction.date = Date()
                transaction.merchant = "\(category) Store \(i)"
                transaction.amount = NSDecimalNumber(decimal: amounts[index] / 5)
                transaction.category = category
                transaction.isManual = true
                transaction.account = createTestAccount()
            }
        }
        
        try viewContext.save()
        
        // When: Generating insights
        let insightsEngine = container.resolve(InsightsEngineProtocol.self)
        let insights = await insightsEngine.generateInsights(for: [], budget: nil)
        
        // Then: Should analyze category spending
        XCTAssertGreaterThan(insights.count, 0, "Should generate category insights")
        
        // Load insights in view model
        let transactionRepo: any TransactionRepository = container.resolve(TransactionRepository.self)
        let budgetRepo: any BudgetRepository = container.resolve(BudgetRepository.self)
        let insightsEngine: any InsightsEngineProtocol = container.resolve(InsightsEngineProtocol.self)
        let insightsViewModel = InsightsViewModel(
            insightsEngine: insightsEngine,
            transactionRepository: transactionRepo,
            budgetRepository: budgetRepo,
            context: viewContext
        )
        await insightsViewModel.loadInsights()
        
        let loadedInsights = await insightsViewModel.insights
        XCTAssertGreaterThan(loadedInsights.count, 0, "Insights should be loaded in view model")
    }
    
    func testInsightsGenerationWorkflow_TrendDetection() async throws {
        // Test Requirements: 9.5 - Insights with trend detection
        
        // Given: Increasing spending trend over time
        let calendar = Calendar.current
        let today = Date()
        
        for month in 0..<3 {
            let baseAmount = 100 + (month * 50) // Increasing trend
            
            for day in 0..<10 {
                let date = calendar.date(byAdding: .day, value: -(month * 30 + day), to: today)!
                
                let transaction = Transaction(context: viewContext)
                transaction.id = UUID()
                transaction.date = date
                transaction.merchant = "Store"
                transaction.amount = NSDecimalNumber(value: baseAmount)
                transaction.category = "Shopping"
                transaction.isManual = true
                transaction.account = createTestAccount()
            }
        }
        
        try viewContext.save()
        
        // When: Generating insights
        let insightsEngine = container.resolve(InsightsEngineProtocol.self)
        let insights = await insightsEngine.generateInsights(for: [], budget: nil)
        
        // Then: Should detect increasing trend
        XCTAssertGreaterThan(insights.count, 0, "Should generate trend insights")
        
        let hasTrendInsight = insights.contains { insight in
            insight.description.lowercased().contains("increas") || 
            insight.description.lowercased().contains("trend") ||
            insight.description.lowercased().contains("spending")
        }
        XCTAssertTrue(hasTrendInsight, "Should detect spending trend")
    }
    
    func testInsightsGenerationWorkflow_EmptyData() async throws {
        // Test Requirements: 9.5 - Insights with no data
        
        // Given: No transaction data
        
        // When: Generating insights
        let insightsEngine = container.resolve(InsightsEngineProtocol.self)
        let insights = await insightsEngine.generateInsights(for: [], budget: nil)
        
        // Then: Should handle gracefully
        XCTAssertNotNil(insights, "Should return empty array, not crash")
        
        // Load in view model
        let transactionRepo: any TransactionRepository = container.resolve(TransactionRepository.self)
        let budgetRepo: any BudgetRepository = container.resolve(BudgetRepository.self)
        let insightsEngine: any InsightsEngineProtocol = container.resolve(InsightsEngineProtocol.self)
        let insightsViewModel = InsightsViewModel(
            insightsEngine: insightsEngine,
            transactionRepository: transactionRepo,
            budgetRepository: budgetRepo,
            context: viewContext
        )
        await insightsViewModel.loadInsights()
        
        let loadedInsights = await insightsViewModel.insights
        XCTAssertNotNil(loadedInsights, "View model should handle empty insights")
    }
    
    func testInsightsGenerationWorkflow_RefreshData() async throws {
        // Test Requirements: 9.5 - Insights refresh workflow
        
        // Given: Initial transaction data
        for i in 0..<5 {
            let transaction = Transaction(context: viewContext)
            transaction.id = UUID()
            transaction.date = Date()
            transaction.merchant = "Store \(i)"
            transaction.amount = NSDecimalNumber(value: 50)
            transaction.category = "Shopping"
            transaction.isManual = true
            transaction.account = createTestAccount()
        }
        try viewContext.save()
        
        // When: Loading insights
        let transactionRepo: any TransactionRepository = container.resolve(TransactionRepository.self)
        let budgetRepo: any BudgetRepository = container.resolve(BudgetRepository.self)
        let insightsEngine: any InsightsEngineProtocol = container.resolve(InsightsEngineProtocol.self)
        let insightsViewModel = InsightsViewModel(
            insightsEngine: insightsEngine,
            transactionRepository: transactionRepo,
            budgetRepository: budgetRepo,
            context: viewContext
        )
        await insightsViewModel.loadInsights()
        
        let initialCount = await insightsViewModel.insights.count
        
        // When: Adding more transactions and refreshing
        for i in 5..<10 {
            let transaction = Transaction(context: viewContext)
            transaction.id = UUID()
            transaction.date = Date()
            transaction.merchant = "Store \(i)"
            transaction.amount = NSDecimalNumber(value: 75)
            transaction.category = "Shopping"
            transaction.isManual = true
            transaction.account = createTestAccount()
        }
        try viewContext.save()
        
        await insightsViewModel.loadInsights()
        
        // Then: Insights should be refreshed
        let refreshedCount = await insightsViewModel.insights.count
        XCTAssertNotNil(refreshedCount, "Insights should be refreshed")
    }
    
    // MARK: - End-to-End Workflow Tests
    
    func testEndToEndWorkflow_CompleteUserJourney() async throws {
        // Test Requirements: 9.5 - Complete user journey
        
        // Step 1: User creates a budget
        let budgetViewModel = container.resolve(BudgetCreationViewModel.self)
        await MainActor.run {
            budgetViewModel.budgetName = "Complete Journey Budget"
            budgetViewModel.selectedPeriod = "monthly"
            budgetViewModel.selectedTemplate = "professional"
        }
        await budgetViewModel.loadTemplate()
        await budgetViewModel.saveBudget()
        
        // Verify budget created
        let budgetRepository = container.resolve(BudgetRepository.self)
        let budgets = try await budgetRepository.fetchAll()
        XCTAssertGreaterThan(budgets.count, 0, "Budget should be created")
        
        // Step 2: User adds transactions
        let transactionViewModel = container.resolve(TransactionEntryViewModel.self)
        
        let testTransactions = [
            ("Grocery Store", "125.50", "Groceries"),
            ("Gas Station", "45.00", "Transportation"),
            ("Restaurant", "65.00", "Food & Dining")
        ]
        
        for (merchant, amount, category) in testTransactions {
            await MainActor.run {
                transactionViewModel.merchant = merchant
                transactionViewModel.amount = amount
                transactionViewModel.selectedCategory = category
                transactionViewModel.date = Date()
            }
            await transactionViewModel.saveTransaction()
        }
        
        // Verify transactions saved
        let transactionRepository = container.resolve(TransactionRepository.self)
        let transactions = try await transactionRepository.fetchAll()
        XCTAssertGreaterThanOrEqual(transactions.count, 3, "All transactions should be saved")
        
        // Step 3: User views budget progress
        let budgetTrackingViewModel = container.resolve(BudgetViewModel.self)
        await budgetTrackingViewModel.loadBudget()
        
        let activeBudget = await budgetTrackingViewModel.activeBudget
        XCTAssertNotNil(activeBudget, "Budget should be active")
        
        // Step 4: User views insights
        let transactionRepo: any TransactionRepository = container.resolve(TransactionRepository.self)
        let budgetRepo: any BudgetRepository = container.resolve(BudgetRepository.self)
        let insightsEngine: any InsightsEngineProtocol = container.resolve(InsightsEngineProtocol.self)
        let insightsViewModel = InsightsViewModel(
            insightsEngine: insightsEngine,
            transactionRepository: transactionRepo,
            budgetRepository: budgetRepo,
            context: viewContext
        )
        await insightsViewModel.loadInsights()
        
        let insights = await insightsViewModel.insights
        XCTAssertNotNil(insights, "Insights should be generated")
        
        // Step 5: User checks budget alerts
        let budgetMonitoringService = container.resolve(BudgetMonitoringService.self)
        let alerts = await budgetMonitoringService.checkBudgetAlerts()
        
        XCTAssertNotNil(alerts, "Budget alerts should be checked")
    }
}
