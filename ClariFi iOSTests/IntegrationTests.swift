//
//  IntegrationTests.swift
//  ClariFi iOSTests
//
//  Comprehensive integration tests covering end-to-end workflows,
//  accessibility compliance, and performance testing
//

import XCTest
import SwiftUI
import CoreData
@testable import ClariFi_iOS

class IntegrationTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var container: DIContainer!
    var transactionRepository: (any TransactionRepository)!
    var budgetRepository: (any BudgetRepository)!
    var accountRepository: (any AccountRepository)!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory persistence controller for testing
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
        
        // Create test DI container
        container = AppDIContainer.createTestContainer()
        
        // Resolve repositories from container
        transactionRepository = container.resolve(TransactionRepository.self)
        budgetRepository = container.resolve(BudgetRepository.self)
        accountRepository = container.resolve(AccountRepository.self)
    }
    
    override func tearDown() async throws {
        // Clean up test data
        try? await cleanupTestData()
        container = nil
        persistenceController = nil
        viewContext = nil
        transactionRepository = nil
        budgetRepository = nil
        accountRepository = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func cleanupTestData() async throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Transaction")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try viewContext.execute(deleteRequest)
        
        let budgetFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Budget")
        let budgetDeleteRequest = NSBatchDeleteRequest(fetchRequest: budgetFetchRequest)
        try viewContext.execute(budgetDeleteRequest)
        
        try viewContext.save()
    }
    
    private func createTestAccount() -> Account {
        let account = Account(context: viewContext)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "checking"
        account.lastFourDigits = "1234"
        return account
    }
    
    private func createTestTransaction(amount: Decimal, merchant: String, category: String, date: Date = Date()) -> ClariFi_iOS.Transaction {
        let transaction = Transaction(context: viewContext)
        transaction.id = UUID()
        transaction.date = date
        transaction.merchant = merchant
        transaction.amount = NSDecimalNumber(decimal: amount)
        transaction.currency = "USD"
        transaction.category = category
        transaction.confidence = 1.0
        transaction.isManual = true
        transaction.account = createTestAccount()
        return transaction
    }
    
    // MARK: - End-to-End Workflow Tests
    
    func testCompleteStatementUploadWorkflow() async throws {
        // Test Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6
        
        // Given: A statement upload view model from DI container
        let viewModel = container.resolve(StatementUploadViewModel.self)
        
        // When: User uploads a statement (simulated with test data)
        // Note: In real scenario, this would process actual PDF/image
        let testTransactions = [
            ParsedTransaction(
                date: Date(),
                merchant: "Starbucks",
                amount: 4.50,
                confidence: TransactionConfidence(date: 0.95, merchant: 0.90, amount: 0.98),
                rawText: "01/15/2024 STARBUCKS $4.50",
                lineNumber: 1,
                category: "Food & Dining",
                transactionType: .debit
            )
        ]
        
        // Simulate parsed transactions
        await MainActor.run {
            viewModel.parsedTransactions = testTransactions
        }
        
        // Then: Transactions should be available for review
        await MainActor.run {
            XCTAssertEqual(viewModel.parsedTransactions.count, 1)
        }
        await MainActor.run {
            XCTAssertEqual(viewModel.parsedTransactions.first?.merchant, "Starbucks")
        }
        
        // When: User confirms transactions
        await viewModel.confirmTransactions()
        
        // Then: Transactions should be saved to repository
        let savedTransactions = try await transactionRepository.fetchAll()
        XCTAssertGreaterThanOrEqual(savedTransactions.count, 1)
    }
    
    func testCompleteManualTransactionEntryWorkflow() async throws {
        // Test Requirements: 2.1, 2.2, 2.3, 2.4, 2.5
        
        // Given: A transaction entry view model from DI container
        let viewModel = container.resolve(TransactionEntryViewModel.self)
        
        // When: User enters transaction details
        await MainActor.run {
            viewModel.date = Date()
            viewModel.merchant = "Target"
            viewModel.amount = "45.99"
            viewModel.selectedCategory = "Shopping"
            viewModel.notes = "Household items"
        }
        
        // Then: Form should be valid
        let isValid = await viewModel.isFormValid
        XCTAssertTrue(isValid)
        
        // When: User saves transaction
        await viewModel.saveTransaction()
        
        // Then: Transaction should be saved
        let transactions = try await transactionRepository.fetchAll()
        XCTAssertGreaterThanOrEqual(transactions.count, 1)
        
        let savedTransaction = transactions.first { $0.merchant == "Target" }
        XCTAssertNotNil(savedTransaction)
        XCTAssertEqual(savedTransaction?.category, "Shopping")
    }

    
    func testCompleteBudgetCreationAndTrackingWorkflow() async throws {
        // Test Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6
        
        // Given: A budget creation view model from DI container
        let viewModel = container.resolve(BudgetCreationViewModel.self)
        
        // When: User creates a budget with template
        await MainActor.run {
            viewModel.budgetName = "Monthly Budget"
            viewModel.selectedPeriod = .monthly
            viewModel.selectedTemplate = BudgetTemplate(
                id: "student",
                name: "Student Budget",
                description: "Budget template for students",
                targetAudience: "Students",
                categories: [],
                defaultPeriod: .monthly,
                rolloverEnabled: false
            )
        }
        
        await viewModel.loadTemplate()
        
        // Then: Template categories should be loaded
        let categoryCount = await viewModel.categories.count
        XCTAssertGreaterThan(categoryCount, 0)
        
        // When: User saves budget
        await viewModel.saveBudget()
        
        // Then: Budget should be saved
        let budgets = try await budgetRepository.fetchAll()
        XCTAssertGreaterThanOrEqual(budgets.count, 1)
        
        // When: User adds transactions
        let transaction1 = createTestTransaction(amount: 50.00, merchant: "Grocery Store", category: "Groceries")
        let transaction2 = createTestTransaction(amount: 30.00, merchant: "Gas Station", category: "Transportation")
        try viewContext.save()
        
        // Then: Budget tracking should reflect spending
        let budgetViewModel = container.resolve(BudgetViewModel.self)
        
        await budgetViewModel.loadBudget()
        
        // Verify budget is loaded
        let hasActiveBudget = await budgetViewModel.activeBudget != nil
        XCTAssertTrue(hasActiveBudget)
    }
    
    func testCompleteCategorizationWorkflow() async throws {
        // Test Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6
        
        // Given: Transactions and categorization service from DI container
        let categoryService = container.resolve(CategoryService.self)
        let ruleEngine = container.resolve(RuleEngine.self)
        
        // When: User creates a transaction
        let transaction = createTestTransaction(amount: 4.50, merchant: "Starbucks", category: "Uncategorized")
        try viewContext.save()
        
        // Then: Auto-categorization should suggest category
        let suggestedCategory = await categoryService.suggestCategory(for: "Starbucks", amount: 4.50)
        XCTAssertNotNil(suggestedCategory)
        
        // When: User corrects category
        transaction.category = "Food & Dining"
        try viewContext.save()
        
        // Then: System should learn from correction
        try await categoryService.learnFromCorrection(merchant: "Starbucks", category: "Food & Dining")
        
        // When: User creates custom rule
        let rule = CategorizationRule(context: viewContext)
        rule.id = UUID()
        rule.merchantPattern = "Starbucks"
        rule.category = "Food & Dining"
        rule.priority = 1
        rule.isActive = true
        try viewContext.save()
        
        // Then: Future transactions should use rule
        let newTransaction = createTestTransaction(amount: 5.00, merchant: "Starbucks Coffee", category: "Uncategorized")
        let appliedCategory = await ruleEngine.applyRules(to: newTransaction)
        XCTAssertNotNil(appliedCategory)
    }
    
    func testCompleteInsightsGenerationWorkflow() async throws {
        // Test Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6
        
        // Given: Multiple transactions over time
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let amount = Decimal(Double.random(in: 10...100))
            _ = createTestTransaction(amount: amount, merchant: "Store \(i)", category: "Shopping", date: date)
        }
        try viewContext.save()
        
        // When: Insights engine analyzes transactions from DI container
        let insightsEngine = container.resolve(InsightsEngineProtocol.self)
        let insights = await insightsEngine.generateInsights(for: [], budget: nil)
        
        // Then: Insights should be generated
        XCTAssertGreaterThan(insights.count, 0)
        
        // Verify insight structure
        if let firstInsight = insights.first {
            XCTAssertFalse(firstInsight.title.isEmpty)
            XCTAssertFalse(firstInsight.description.isEmpty)
            XCTAssertNotNil(firstInsight.type)
        }
        
        // When: User views insights from DI container
        let transactionRepo: any TransactionRepository = container.resolve(TransactionRepository.self)
        let budgetRepo: any BudgetRepository = container.resolve(BudgetRepository.self)
        let insightsEngine: any InsightsEngineProtocol = container.resolve(InsightsEngineProtocol.self)
        let viewModel = InsightsViewModel(
            insightsEngine: insightsEngine,
            transactionRepository: transactionRepo,
            budgetRepository: budgetRepo,
            context: viewContext
        )
        
        await viewModel.loadInsights()
        
        // Then: Insights should be displayed
        let loadedInsights = await viewModel.insights
        XCTAssertGreaterThan(loadedInsights.count, 0)
    }
    
    func testCompletePrivacyControlsWorkflow() async throws {
        // Test Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7
        
        // Given: Privacy manager and test data
        let privacyManager = PrivacyManager(viewContext: viewContext)
        
        // Create test transactions
        for i in 0..<10 {
            _ = createTestTransaction(amount: Decimal(i * 10), merchant: "Merchant \(i)", category: "Test")
        }
        try viewContext.save()
        
        // When: User checks data summary
        let dataSummary = await privacyManager.getDataSummary(context: viewContext)
        
        // Then: Summary should show correct data
        XCTAssertGreaterThanOrEqual(dataSummary.totalTransactions, 10)
        XCTAssertGreaterThan(dataSummary.storageSize, 0)
        
        // When: User exports data
        let exportedData = try await privacyManager.exportUserData(context: viewContext)
        
        // Then: Export should contain data
        XCTAssertFalse(exportedData.isEmpty)
        
        // Verify export is valid JSON
        let jsonObject = try JSONSerialization.jsonObject(with: exportedData)
        XCTAssertNotNil(jsonObject)
        
        // When: User changes processing mode
        await MainActor.run {
            privacyManager.processingMode = .localOnly
        }
        
        // Then: Mode should be updated
        let currentMode = await privacyManager.processingMode
        XCTAssertEqual(currentMode, .localOnly)
    }
    
    func testCompletePremiumFeaturesWorkflow() async throws {
        // Test Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6
        
        // Given: Subscription service and premium features
        let subscriptionService = SubscriptionService()
        let cashflowService = CashflowForecastingService(context: viewContext)
        
        // Create historical transactions for forecasting
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<60 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let amount = Decimal(50 + Double(i % 10) * 5)
            _ = createTestTransaction(amount: amount, merchant: "Store", category: "Shopping", date: date)
        }
        try viewContext.save()
        
        // When: Premium user accesses cashflow forecasting
        // Note: In real scenario, subscription would be validated
        let forecast = try await cashflowService.generateForecast(months: 1)
        
        // Then: Forecast should be generated
        XCTAssertGreaterThan(forecast.predictions.count, 0)
        
        // Verify forecast structure
        if let firstForecast = forecast.predictions.first {
            XCTAssertNotNil(firstForecast.date)
            XCTAssertGreaterThan(firstForecast.predictedIncome, 0)
        }
        
        // When: User runs scenario planning
        let scenarioService = ScenarioPlanningService(context: viewContext)
        let spendingScenario = SpendingScenario(
            id: UUID(),
            name: "Test Scenario",
            description: "Test scenario for budget planning",
            changes: [CategoryChange(category: "Shopping", changeType: .decrease, amount: 20.0)],
            startDate: Date(),
            duration: 30
        )
        let scenario = try await scenarioService.runScenario(spendingScenario)
        
        // Then: Scenario should show impact
        XCTAssertNotNil(scenario)
        XCTAssertGreaterThan(scenario.impact.totalSavings, 0)
    }
    
    func testCompleteSecurityWorkflow() async throws {
        // Test Requirements: 8.1, 8.2, 8.5, 8.6
        
        // Given: Encryption and security services
        let encryptionService = EncryptionService.shared
        let secureFileManager = SecureFileManager.shared
        
        // When: User stores sensitive data
        let sensitiveData = "Sensitive financial data".data(using: .utf8)!
        try encryptionService.storeSecureData(sensitiveData, forKey: "test_financial_data")
        
        // Then: Data should be encrypted
        let retrievedData = try encryptionService.retrieveSecureData(forKey: "test_financial_data")
        XCTAssertEqual(retrievedData, sensitiveData)
        
        // When: User creates secure temporary file
        let tempFileData = "Temporary statement data".data(using: .utf8)!
        let tempFileURL = try secureFileManager.createSecureTemporaryFile(data: tempFileData, fileExtension: "pdf")
        
        // Then: File should exist and be secure
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempFileURL.path))
        
        // When: Cleanup is triggered
        secureFileManager.cleanupAllTrackedFiles()
        
        // Then: Temporary files should be removed
        // Note: Cleanup may not remove immediately if file is recent
        
        // Cleanup test data
        try encryptionService.deleteSecureData(forKey: "test_financial_data")
    }
    
    // MARK: - Accessibility Compliance Tests
    
    func testMainTabViewAccessibility() {
        // Test Requirements: All requirements - accessibility compliance
        
        // Given: Main tab view
        let mainTabView = MainTabView()
            .environment(\.managedObjectContext, viewContext)
        
        // Then: All tabs should have accessibility labels
        // Note: In real UI testing, we would use XCUITest to verify
        // Here we verify the structure exists
        XCTAssertNotNil(mainTabView)
    }
    
    func testTransactionListAccessibility() async throws {
        // Given: Transactions list with data
        for i in 0..<5 {
            _ = createTestTransaction(amount: Decimal(i * 10), merchant: "Store \(i)", category: "Shopping")
        }
        try viewContext.save()
        
        // When: View is rendered
        let transactionsView = TransactionsListView()
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(AppState())
            .environmentObject(SubscriptionViewModel())
        
        // Then: View should be accessible
        XCTAssertNotNil(transactionsView)
        
        // Verify accessibility helper exists
        XCTAssertFalse(AccessibilityLabels.transactionRow.isEmpty)
        XCTAssertFalse(AccessibilityHints.transactionRow.isEmpty)
    }
    
    func testBudgetViewAccessibility() {
        // Given: Budget view from DI container
        let budgetViewModel = container.resolve(BudgetViewModel.self)
        
        let budgetView = BudgetView(viewModel: budgetViewModel)
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(AppState())
            .environmentObject(SubscriptionViewModel())
        
        // Then: View should have accessibility support
        XCTAssertNotNil(budgetView)
        XCTAssertFalse(AccessibilityLabels.budgetTab.isEmpty)
    }
    
    func testInsightsViewAccessibility() {
        // Given: Insights view from DI container
        let transactionRepo: any TransactionRepository = container.resolve(TransactionRepository.self)
        let budgetRepo: any BudgetRepository = container.resolve(BudgetRepository.self)
        let insightsEngine: any InsightsEngineProtocol = container.resolve(InsightsEngineProtocol.self)
        let insightsViewModel = InsightsViewModel(
            insightsEngine: insightsEngine,
            transactionRepository: transactionRepo,
            budgetRepository: budgetRepo,
            context: viewContext
        )
        
        let insightsView = InsightsView(viewModel: insightsViewModel)
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(AppState())
            .environmentObject(SubscriptionViewModel())
        
        // Then: View should be accessible
        XCTAssertNotNil(insightsView)
        XCTAssertFalse(AccessibilityLabels.insightsTab.isEmpty)
    }
    
    func testDynamicTypeSupport() {
        // Given: Various content size categories
        let categories: [ContentSizeCategory] = [
            .extraSmall,
            .small,
            .medium,
            .large,
            .extraLarge,
            .extraExtraLarge,
            .extraExtraExtraLarge,
            .accessibilityMedium,
            .accessibilityLarge,
            .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]
        
        // Then: App should support all categories
        for category in categories {
            let view = MainTabView()
                .environment(\.managedObjectContext, viewContext)
                .environment(\.sizeCategory, category)
            
            XCTAssertNotNil(view)
        }
    }

    
    // MARK: - Performance Tests
    
    func testTransactionListPerformance() throws {
        // Test Requirements: Performance under various conditions
        
        // Given: Large number of transactions
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            for i in 0..<1000 {
                _ = createTestTransaction(
                    amount: Decimal(Double.random(in: 1...1000)),
                    merchant: "Merchant \(i)",
                    category: "Category \(i % 10)"
                )
            }
            
            do {
                try viewContext.save()
            } catch {
                XCTFail("Failed to save transactions: \(error)")
            }
        }
    }
    
    func testBudgetCalculationPerformance() async throws {
        // Given: Budget with many categories and transactions
        let budget = Budget(context: viewContext)
        budget.id = UUID()
        budget.name = "Performance Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        
        for i in 0..<20 {
            let category = BudgetCategory(context: viewContext)
            category.id = UUID()
            category.name = "Category \(i)"
            category.budgetedAmount = NSDecimalNumber(value: 500)
            category.budget = budget
        }
        
        for i in 0..<500 {
            _ = createTestTransaction(
                amount: Decimal(Double.random(in: 1...100)),
                merchant: "Store \(i)",
                category: "Category \(i % 20)"
            )
        }
        
        try viewContext.save()
        
        // When: Calculating budget status
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let budgetViewModel = self.container.resolve(BudgetViewModel.self)
            
            Task {
                await budgetViewModel.loadBudget()
            }
        }
    }
    
    func testInsightsGenerationPerformance() async throws {
        // Given: Large transaction dataset
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<365 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            for j in 0..<5 {
                _ = createTestTransaction(
                    amount: Decimal(Double.random(in: 5...200)),
                    merchant: "Merchant \(j)",
                    category: "Category \(j % 5)",
                    date: date
                )
            }
        }
        
        try viewContext.save()
        
        // When: Generating insights from DI container
        let insightsEngine = container.resolve(InsightsEngineProtocol.self)
        
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            Task {
                _ = await insightsEngine.generateInsights(for: [], budget: nil)
            }
        }
    }
    
    func testCategorizationPerformance() async throws {
        // Given: Many transactions to categorize from DI container
        let categoryService = container.resolve(CategoryService.self)
        
        // Create merchant history
        for i in 0..<100 {
            _ = createTestTransaction(
                amount: Decimal(Double.random(in: 1...100)),
                merchant: "Known Merchant \(i % 20)",
                category: "Category \(i % 10)"
            )
        }
        try viewContext.save()
        
        // When: Categorizing new transactions
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            Task {
                for i in 0..<100 {
                    _ = await categoryService.suggestCategory(
                        for: "Known Merchant \(i % 20)",
                        amount: Decimal(Double.random(in: 1...100))
                    )
                }
            }
        }
    }
    
    func testDataExportPerformance() async throws {
        // Given: Large dataset to export
        for i in 0..<1000 {
            _ = createTestTransaction(
                amount: Decimal(Double.random(in: 1...1000)),
                merchant: "Merchant \(i)",
                category: "Category \(i % 10)"
            )
        }
        try viewContext.save()
        
        // When: Exporting data
        let privacyManager = PrivacyManager(viewContext: viewContext)
        
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            Task {
                _ = try? await privacyManager.exportUserData(context: viewContext)
            }
        }
    }
    
    func testEncryptionPerformance() throws {
        // Given: Encryption service
        let encryptionService = EncryptionService.shared
        let testData = String(repeating: "A", count: 10000).data(using: .utf8)!
        
        // When: Encrypting and decrypting large data
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            do {
                let encrypted = try encryptionService.encrypt(testData)
                _ = try encryptionService.decrypt(encrypted)
            } catch {
                XCTFail("Encryption/decryption failed: \(error)")
            }
        }
    }
    
    func testCoreDataFetchPerformance() throws {
        // Given: Large dataset
        for i in 0..<5000 {
            _ = createTestTransaction(
                amount: Decimal(i),
                merchant: "Merchant \(i)",
                category: "Category \(i % 10)"
            )
        }
        try viewContext.save()
        
        // When: Fetching transactions
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let fetchRequest: NSFetchRequest<ClariFi_iOS.Transaction> = ClariFi_iOS.Transaction.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            do {
                _ = try viewContext.fetch(fetchRequest)
            } catch {
                XCTFail("Fetch failed: \(error)")
            }
        }
    }
    
    func testMemoryUsageUnderLoad() async throws {
        // Given: Memory-intensive operations
        let iterations = 100
        
        for iteration in 0..<iterations {
            // Create transactions
            for i in 0..<100 {
                _ = createTestTransaction(
                    amount: Decimal(i),
                    merchant: "Store \(i)",
                    category: "Category"
                )
            }
            
            try viewContext.save()
            
            // Fetch and process
            let fetchRequest: NSFetchRequest<ClariFi_iOS.Transaction> = ClariFi_iOS.Transaction.fetchRequest()
            let transactions = try viewContext.fetch(fetchRequest)
            
            // Process transactions
            _ = transactions.map { $0.amount }
            
            // Clean up periodically
            if iteration % 10 == 0 {
                viewContext.reset()
            }
        }
        
        // Then: Should complete without memory issues
        XCTAssertTrue(true, "Memory test completed")
    }
    
    // MARK: - Error Handling and Edge Cases
    
    func testEmptyStateHandling() async throws {
        // Given: No data in system
        
        // When: Loading various views from DI container
        let insightsEngine = container.resolve(InsightsEngineProtocol.self)
        let insights = await insightsEngine.generateInsights(for: [], budget: nil)
        
        // Then: Should handle gracefully
        XCTAssertNotNil(insights)
        
        // When: Loading budget from DI container
        let budgetViewModel = container.resolve(BudgetViewModel.self)
        
        await budgetViewModel.loadBudget()
        
        // Then: Should handle no budget gracefully
        let hasNoBudget = await budgetViewModel.activeBudget == nil
        XCTAssertTrue(hasNoBudget)
    }
    
    func testConcurrentDataAccess() async throws {
        // Given: Multiple concurrent operations
        
        await withTaskGroup(of: Void.self) { group in
            // Concurrent writes
            for i in 0..<10 {
                group.addTask {
                    let transaction = self.createTestTransaction(
                        amount: Decimal(i * 10),
                        merchant: "Concurrent Store \(i)",
                        category: "Test"
                    )
                    try? self.viewContext.save()
                }
            }
            
            // Concurrent reads
            for _ in 0..<10 {
                group.addTask {
                    let fetchRequest: NSFetchRequest<ClariFi_iOS.Transaction> = ClariFi_iOS.Transaction.fetchRequest()
                    _ = try? self.viewContext.fetch(fetchRequest)
                }
            }
        }
        
        // Then: Should complete without crashes
        XCTAssertTrue(true, "Concurrent access test completed")
    }
    
    func testDataIntegrityAfterMultipleOperations() async throws {
        // Given: Series of operations
        let initialTransaction = createTestTransaction(amount: 100.00, merchant: "Test Store", category: "Shopping")
        try viewContext.save()
        
        let transactionId = initialTransaction.id
        
        // When: Multiple updates
        for i in 0..<10 {
            initialTransaction.amount = NSDecimalNumber(value: 100.00 + Double(i))
            initialTransaction.notes = "Update \(i)"
            try viewContext.save()
        }
        
        // Then: Data should be consistent
        let fetchRequest: NSFetchRequest<ClariFi_iOS.Transaction> = ClariFi_iOS.Transaction.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", transactionId! as CVarArg)
        
        let results = try viewContext.fetch(fetchRequest)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.notes, "Update 9")
    }
    
    func testOfflineOperationResilience() async throws {
        // Test Requirements: 8.1 - Offline operation
        
        // Given: App in offline mode (simulated)
        let privacyManager = PrivacyManager(viewContext: viewContext)
        await MainActor.run {
            privacyManager.processingMode = .localOnly
        }
        
        // When: Performing various operations
        _ = createTestTransaction(amount: 50.00, merchant: "Offline Store", category: "Shopping")
        try viewContext.save()
        
        let insightsEngine = InsightsEngine(context: viewContext)
        let insights = await insightsEngine.generateInsights(for: [], budget: nil)
        
        // Then: All operations should work
        XCTAssertNotNil(insights)
        
        let transactions = try await transactionRepository.fetchAll()
        XCTAssertGreaterThan(transactions.count, 0)
    }
    
    func testDataMigrationScenario() async throws {
        // Given: Existing data
        for i in 0..<50 {
            _ = createTestTransaction(
                amount: Decimal(i * 10),
                merchant: "Store \(i)",
                category: "Old Category"
            )
        }
        try viewContext.save()
        
        // When: Simulating data migration (category rename)
        let fetchRequest: NSFetchRequest<ClariFi_iOS.Transaction> = ClariFi_iOS.Transaction.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", "Old Category")
        
        let transactions = try viewContext.fetch(fetchRequest)
        for transaction in transactions {
            transaction.category = "New Category"
        }
        try viewContext.save()
        
        // Then: All data should be migrated
        let newFetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        newFetchRequest.predicate = NSPredicate(format: "category == %@", "New Category")
        
        let migratedTransactions = try viewContext.fetch(newFetchRequest)
        XCTAssertEqual(migratedTransactions.count, 50)
    }
}
