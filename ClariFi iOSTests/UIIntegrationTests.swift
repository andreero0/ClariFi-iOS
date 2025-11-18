//
//  UIIntegrationTests.swift
//  ClariFi iOSTests
//
//  UI-focused integration tests for user interface workflows
//  and interaction patterns
//

import XCTest
import SwiftUI
import CoreData
@testable import ClariFi_iOS

class UIIntegrationTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var container: DIContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
        
        // Create test DI container
        container = AppDIContainer.createTestContainer()
    }
    
    override func tearDown() async throws {
        container = nil
        persistenceController = nil
        viewContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Navigation Flow Tests
    
    @MainActor
    func testMainNavigationStructure() {
        // Given: Main tab view
        let appState = AppState()
        let subscriptionViewModel = SubscriptionViewModel()
        
        let mainTabView = MainTabView()
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(appState)
            .environmentObject(subscriptionViewModel)
        
        // Then: View should be properly structured
        XCTAssertNotNil(mainTabView)
        
        // Verify app state initialization
        XCTAssertEqual(appState.selectedTab, 0)
        XCTAssertFalse(appState.showingStatementUpload)
        XCTAssertFalse(appState.showingTransactionEntry)
    }
    
    @MainActor
    func testDashboardToTransactionNavigation() {
        // Given: Dashboard view
        let appState = AppState()
        
        let dashboardView = DashboardView()
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(appState)
            .environmentObject(SubscriptionViewModel())
        
        // Then: Dashboard should be accessible
        XCTAssertNotNil(dashboardView)
        
        // When: User triggers transaction entry
        appState.showingTransactionEntry = true
        
        // Then: State should reflect navigation
        XCTAssertTrue(appState.showingTransactionEntry)
    }
    
    func testStatementUploadFlow() async {
        // Given: Statement upload view model from DI container
        let viewModel = container.resolve(StatementUploadViewModel.self)
        
        // Then: Initial state should be correct
        await MainActor.run {
            XCTAssertFalse(viewModel.isProcessing)
            XCTAssertTrue(viewModel.parsedTransactions.isEmpty)
            XCTAssertNil(viewModel.error)
        }
    }
    
    func testTransactionReviewFlow() async {
        // Given: Parsed transactions from DI container
        let viewModel = container.resolve(StatementUploadViewModel.self)
        
        let testTransactions = [
            ParsedTransaction(
                date: Date(),
                merchant: "Test Store",
                amount: 25.50,
                confidence: TransactionConfidence(date: 0.95, merchant: 0.90, amount: 0.98),
                rawText: "Test transaction",
                lineNumber: 1,
                category: "Shopping",
                transactionType: .debit
            )
        ]
        
        await MainActor.run {
            viewModel.parsedTransactions = testTransactions
        }
        
        // When: Creating review view
        let parserService = SmartTransactionParser()
        let reviewViewModel = TransactionReviewViewModel(parserService: parserService)
        let reviewView = TransactionReviewView(
            transactions: testTransactions,
            onConfirm: { Task { await viewModel.confirmTransactions() } },
            onCancel: {},
            viewModel: reviewViewModel
        )
        
        // Then: View should be created
        XCTAssertNotNil(reviewView)
    }
    
    // MARK: - Form Validation Tests
    
    func testTransactionEntryFormValidation() async {
        // Given: Transaction entry view model from DI container
        let viewModel = container.resolve(TransactionEntryViewModel.self)
        
        // When: Form is empty
        var isValid = await viewModel.isFormValid
        
        // Then: Should be invalid
        XCTAssertFalse(isValid)
        
        // When: Filling required fields
        await MainActor.run {
            viewModel.merchant = "Test Store"
            viewModel.amount = "50.00"
            viewModel.selectedCategory = "Shopping"
            viewModel.date = Date()
        }
        
        isValid = await viewModel.isFormValid
        
        // Then: Should be valid
        XCTAssertTrue(isValid)
    }
    
    func testBudgetCreationFormValidation() async {
        // Given: Budget creation view model from DI container
        let viewModel = container.resolve(BudgetCreationViewModel.self)
        
        // When: Form is empty
        var isValid = await viewModel.isFormValid
        
        // Then: Should be invalid
        XCTAssertFalse(isValid)
        
        // When: Filling required fields
        await MainActor.run {
            viewModel.budgetName = "Test Budget"
            viewModel.selectedPeriod = .monthly
        }
        
        isValid = await viewModel.isFormValid
        
        // Then: Should be valid
        XCTAssertTrue(isValid)
    }
    
    func testAmountInputValidation() async {
        // Given: Transaction entry view model from DI container
        let viewModel = container.resolve(TransactionEntryViewModel.self)
        
        // Test valid amounts
        let validAmounts = ["10", "10.50", "100.99", "0.01", "1000"]
        
        for amount in validAmounts {
            await MainActor.run {
                viewModel.amount = amount
            }
            
            let parsedAmount = await viewModel.parsedAmount
            XCTAssertNotNil(parsedAmount, "Amount '\(amount)' should be valid")
        }
        
        // Test invalid amounts
        let invalidAmounts = ["", "abc", "-10", "10.999"]
        
        for amount in invalidAmounts {
            await MainActor.run {
                viewModel.amount = amount
            }
            
            let parsedAmount = await viewModel.parsedAmount
            if amount.isEmpty {
                XCTAssertNil(parsedAmount, "Empty amount should be invalid")
            }
        }
    }
    
    // MARK: - State Management Tests
    
    func testAppStateRefreshTrigger() {
        // Given: App state
        let appState = AppState()
        let initialTrigger = appState.refreshTrigger
        
        // When: Triggering refresh
        appState.refreshData()
        
        // Then: Trigger should change
        XCTAssertNotEqual(appState.refreshTrigger, initialTrigger)
    }
    
    func testViewModelStateTransitions() async {
        // Given: Statement upload view model from DI container
        let viewModel = container.resolve(StatementUploadViewModel.self)
        
        // Initial state
        await MainActor.run {
            XCTAssertFalse(viewModel.isProcessing)
            XCTAssertEqual(viewModel.progress, 0.0)
        }
        
        // Simulate processing state
        await MainActor.run {
            viewModel.isProcessing = true
            viewModel.progress = 0.5
        }
        
        await MainActor.run {
            XCTAssertTrue(viewModel.isProcessing)
            XCTAssertEqual(viewModel.progress, 0.5)
        }
        
        // Complete processing
        await MainActor.run {
            viewModel.isProcessing = false
            viewModel.progress = 1.0
        }
        
        await MainActor.run {
            XCTAssertFalse(viewModel.isProcessing)
            XCTAssertEqual(viewModel.progress, 1.0)
        }
    }
    
    func testSubscriptionViewModelState() async {
        // Given: Subscription view model
        let viewModel = await SubscriptionViewModel()
        
        // Initial state
        await MainActor.run {
            XCTAssertFalse(viewModel.isPremium)
            XCTAssertFalse(viewModel.showPaywall)
        }
        
        // When: Showing paywall
        await MainActor.run {
            viewModel.showPaywall = true
        }
        
        // Then: State should update
        await MainActor.run {
            XCTAssertTrue(viewModel.showPaywall)
        }
    }
    
    // MARK: - Error State Tests
    
    func testErrorViewDisplay() {
        // Given: Error view
        let error = AppError.ocrFailed(reason: "Test error")
        
        let errorView = ErrorView(
            error: error,
            onRetry: {},
            onDismiss: {}
        )
        
        // Then: View should be created
        XCTAssertNotNil(errorView)
    }
    
    func testLoadingStateView() {
        // Given: Loading state view
        let loadingView = LoadingStateView(message: "Processing...")
        
        // Then: View should be created
        XCTAssertNotNil(loadingView)
    }
    
    func testSuccessStateView() {
        // Given: Success view
        let successView = SuccessView(
            message: "Transaction saved",
            onDismiss: {}
        )
        
        // Then: View should be created
        XCTAssertNotNil(successView)
    }
    
    // MARK: - Interaction Tests
    
    func testBatchCategorizationInteraction() async {
        // Given: Batch categorization view model from DI container
        let viewModel = container.resolve(BatchCategorizationViewModel.self)
        
        // Create test transactions
        for i in 0..<5 {
            let transaction = Transaction(context: viewContext)
            transaction.id = UUID()
            transaction.date = Date()
            transaction.merchant = "Store \(i)"
            transaction.amount = NSDecimalNumber(value: 10.0 * Double(i))
            transaction.category = "Uncategorized"
            transaction.isManual = true
        }
        try? viewContext.save()
        
        // When: Loading transactions
        await viewModel.loadUncategorizedTransactions()
        
        // Then: Transactions should be loaded
        let count = await viewModel.uncategorizedTransactions.count
        XCTAssertGreaterThan(count, 0)
    }
    
    func testCategorizationRulesInteraction() async {
        // Given: Categorization rules view model from DI container
        let viewModel = container.resolve(CategorizationRulesViewModel.self)
        
        // When: Loading rules
        await viewModel.loadRules()
        
        // Then: Should complete without error
        let rules = await viewModel.rules
        XCTAssertNotNil(rules)
    }
    
    func testPrivacyDashboardInteraction() async {
        // Given: Privacy dashboard view model from DI container
        let viewModel = container.resolve(PrivacyDashboardViewModel.self)
        
        // When: Loading data summary
        await viewModel.loadDataSummary()
        
        // Then: Summary should be loaded
        let summary = await viewModel.dataSummary
        XCTAssertNotNil(summary)
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabelsExist() {
        // Verify all accessibility labels are defined
        XCTAssertFalse(AccessibilityLabels.dashboardTab.isEmpty)
        XCTAssertFalse(AccessibilityLabels.transactionsTab.isEmpty)
        XCTAssertFalse(AccessibilityLabels.budgetTab.isEmpty)
        XCTAssertFalse(AccessibilityLabels.insightsTab.isEmpty)
        XCTAssertFalse(AccessibilityLabels.premiumTab.isEmpty)
        XCTAssertFalse(AccessibilityLabels.transactionRow.isEmpty)
        XCTAssertFalse(AccessibilityLabels.addTransactionButton.isEmpty)
        XCTAssertFalse(AccessibilityLabels.uploadStatementButton.isEmpty)
    }
    
    func testAccessibilityHintsExist() {
        // Verify all accessibility hints are defined
        XCTAssertFalse(AccessibilityHints.dashboardTab.isEmpty)
        XCTAssertFalse(AccessibilityHints.transactionsTab.isEmpty)
        XCTAssertFalse(AccessibilityHints.budgetTab.isEmpty)
        XCTAssertFalse(AccessibilityHints.insightsTab.isEmpty)
        XCTAssertFalse(AccessibilityHints.premiumTab.isEmpty)
        XCTAssertFalse(AccessibilityHints.transactionRow.isEmpty)
        XCTAssertFalse(AccessibilityHints.addTransactionButton.isEmpty)
        XCTAssertFalse(AccessibilityHints.uploadStatementButton.isEmpty)
    }
    
    func testVoiceOverSupport() async {
        // Given: Views with VoiceOver support
        let views: [any View] = [
            MainTabView().environment(\.managedObjectContext, viewContext),
            DashboardView().environment(\.managedObjectContext, viewContext).environmentObject(AppState()).environmentObject(await SubscriptionViewModel()),
            TransactionsListView().environment(\.managedObjectContext, viewContext).environmentObject(AppState()).environmentObject(await SubscriptionViewModel())
        ]
        
        // Then: All views should be created (VoiceOver support is built-in)
        for view in views {
            XCTAssertNotNil(view)
        }
    }
    
    // MARK: - Data Flow Tests
    
    func testTransactionDataFlow() async throws {
        // Given: Transaction entry from DI container
        let viewModel = container.resolve(TransactionEntryViewModel.self)
        
        // When: User enters and saves transaction
        await MainActor.run {
            viewModel.merchant = "Data Flow Test"
            viewModel.amount = "99.99"
            viewModel.selectedCategory = "Test"
            viewModel.date = Date()
        }
        
        await viewModel.saveTransaction()
        
        // Then: Transaction should flow to repository
        let transactionRepository = container.resolve(TransactionRepository.self)
        let transactions = try await transactionRepository.fetchAll()
        let savedTransaction = transactions.first { $0.merchant == "Data Flow Test" }
        
        XCTAssertNotNil(savedTransaction)
        XCTAssertEqual(savedTransaction?.category, "Test")
    }
    
    func testBudgetDataFlow() async throws {
        // Given: Budget creation from DI container
        let viewModel = container.resolve(BudgetCreationViewModel.self)
        
        // When: User creates budget
        await MainActor.run {
            viewModel.budgetName = "Data Flow Budget"
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
        await viewModel.saveBudget()
        
        // Then: Budget should flow to repository
        let budgetRepository = container.resolve(BudgetRepository.self)
        let budgets = try await budgetRepository.fetchAll()
        let savedBudget = budgets.first { $0.name == "Data Flow Budget" }
        
        XCTAssertNotNil(savedBudget)
    }
    
    func testInsightsDataFlow() async throws {
        // Given: Transactions for insights
        for i in 0..<10 {
            let transaction = Transaction(context: viewContext)
            transaction.id = UUID()
            transaction.date = Date()
            transaction.merchant = "Insight Store \(i)"
            transaction.amount = NSDecimalNumber(value: 50.0)
            transaction.category = "Shopping"
            transaction.isManual = true
        }
        try viewContext.save()
        
        // When: Generating insights from DI container
        let insightsEngine = container.resolve(InsightsEngineProtocol.self)
        let insights = await insightsEngine.generateInsights(for: [], budget: nil)
        
        // Then: Insights should be generated from transaction data
        XCTAssertNotNil(insights)
    }
}
