//
//  EndToEndFlowTests.swift
//  ClariFi iOSTests
//
//  Integration tests for end-to-end flows
//

import XCTest
import CoreData
@testable import ClariFi_iOS

@MainActor
class EndToEndFlowTests: XCTestCase {
    
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
    
    // MARK: - Statement Upload Flow
    
    func testStatementUploadEndToEndFlow() async throws {
        // Test the complete statement upload flow
        let expectation = XCTestExpectation(description: "Statement upload completes")
        
        // Create mock statement data
        let statementText = """
        Date,Description,Amount
        2024-01-01,Starbucks Coffee,5.50
        2024-01-02,Grocery Store,45.20
        2024-01-03,Gas Station,32.10
        """
        
        // Resolve dependencies
        let ocrService: VisionOCRService = diContainer.resolve(VisionOCRService.self)
        let parserService: SmartTransactionParser = diContainer.resolve(SmartTransactionParser.self)
        let transactionRepo: any TransactionRepository = diContainer.resolve(TransactionRepository.self)
        let accountRepo: any AccountRepository = diContainer.resolve(AccountRepository.self)
        let statementRepo: any StatementRepository = diContainer.resolve(StatementRepository.self)
        
        // Create ViewModel
        let viewModel = StatementUploadViewModel(
            ocrService: ocrService,
            parserService: parserService,
            transactionRepository: transactionRepo,
            accountRepository: accountRepo,
            statementRepository: statementRepo,
            llmService: nil,
            context: context
        )
        
        // Test the flow
        await viewModel.processStatement(statementText, format: .csv)
        
        // Wait for processing to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Verify transactions were created
        let transactions = try await transactionRepo.fetchAll()
        XCTAssertEqual(transactions.count, 3)
        
        // Verify statement was saved
        let statements = try await statementRepo.fetchAll()
        XCTAssertEqual(statements.count, 1)
    }
    
    // MARK: - Transaction Categorization Flow
    
    func testTransactionCategorizationEndToEndFlow() async throws {
        // Test the complete transaction categorization flow
        let expectation = XCTestExpectation(description: "Transaction categorization completes")
        
        // Create test transactions
        let transactions = createTestTransactions()
        
        // Resolve dependencies
        let categoryService: CategoryService = diContainer.resolve(CategoryService.self)
        let transactionRepo: any TransactionRepository = diContainer.resolve(TransactionRepository.self)
        
        // Save transactions
        for transaction in transactions {
            try await transactionRepo.save(transaction)
        }
        
        // Test categorization
        let result = try await categoryService.categorizeTransaction(
            merchant: "Starbucks Coffee",
            amount: Decimal(5.50),
            description: "Coffee purchase"
        )
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result.category, "Food & Dining")
        XCTAssertGreaterThan(result.confidence, 0.5)
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Budget Creation and Monitoring Flow
    
    func testBudgetCreationAndMonitoringEndToEndFlow() async throws {
        // Test the complete budget creation and monitoring flow
        let expectation = XCTestExpectation(description: "Budget creation and monitoring completes")
        
        // Resolve dependencies
        let budgetRepo: any BudgetRepository = diContainer.resolve(BudgetRepository.self)
        let budgetCategoryRepo: any BudgetCategoryRepository = diContainer.resolve(BudgetCategoryRepository.self)
        let transactionRepo: any TransactionRepository = diContainer.resolve(TransactionRepository.self)
        let monitoringService: BudgetMonitoringService = diContainer.resolve(BudgetMonitoringService.self)
        
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
        
        // Create budget categories
        let foodCategory = BudgetCategory(context: context)
        foodCategory.id = UUID()
        foodCategory.name = "Food & Dining"
        foodCategory.budgetedAmount = NSDecimalNumber(value: 500)
        foodCategory.spentAmount = NSDecimalNumber(value: 0)
        foodCategory.alertThreshold = 0.8
        foodCategory.rolloverEnabled = false
        foodCategory.budget = budget
        foodCategory.createdAt = Date()
        foodCategory.updatedAt = Date()
        
        try await budgetCategoryRepo.save(foodCategory)
        
        // Create test transactions
        let transactions = createTestTransactions()
        for transaction in transactions {
            try await transactionRepo.save(transaction)
        }
        
        // Test budget monitoring
        let budgetStatus = try await monitoringService.getBudgetStatus()
        
        XCTAssertNotNil(budgetStatus)
        XCTAssertEqual(budgetStatus?.budget.name, "Test Budget")
        XCTAssertEqual(budgetStatus?.categoryStatuses.count, 1)
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Cashflow Forecasting Flow
    
    func testCashflowForecastingEndToEndFlow() async throws {
        // Test the complete cashflow forecasting flow
        let expectation = XCTestExpectation(description: "Cashflow forecasting completes")
        
        // Create test transactions
        let transactions = createTestTransactions(count: 50)
        for transaction in transactions {
            try await transactionRepo.save(transaction)
        }
        
        // Resolve dependencies
        let forecastingService: CashflowForecastingService = diContainer.resolve(CashflowForecastingService.self)
        
        // Test forecasting
        let forecast = try await forecastingService.generateForecast(months: 3)
        
        XCTAssertNotNil(forecast)
        XCTAssertEqual(forecast.predictions.count, 3)
        XCTAssertGreaterThan(forecast.confidenceLevel, 0)
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Scenario Planning Flow
    
    func testScenarioPlanningEndToEndFlow() async throws {
        // Test the complete scenario planning flow
        let expectation = XCTestExpectation(description: "Scenario planning completes")
        
        // Create test transactions
        let transactions = createTestTransactions(count: 30)
        for transaction in transactions {
            try await transactionRepo.save(transaction)
        }
        
        // Resolve dependencies
        let scenarioService: ScenarioPlanningService = diContainer.resolve(ScenarioPlanningService.self)
        
        // Test scenario generation
        let scenarios = try await scenarioService.generateCommonScenarios()
        
        XCTAssertFalse(scenarios.isEmpty)
        
        // Test scenario execution
        if let firstScenario = scenarios.first {
            let result = try await scenarioService.runScenario(firstScenario)
            
            XCTAssertNotNil(result)
            XCTAssertEqual(result.scenario.id, firstScenario.id)
            XCTAssertNotNil(result.baseline)
            XCTAssertNotNil(result.projected)
            XCTAssertNotNil(result.impact)
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Analytics Flow
    
    func testAnalyticsEndToEndFlow() async throws {
        // Test the complete analytics flow
        let expectation = XCTestExpectation(description: "Analytics flow completes")
        
        // Resolve dependencies
        let analyticsService: PostHogAnalyticsService = diContainer.resolve(PostHogAnalyticsService.self)
        
        // Test event tracking
        analyticsService.track(event: .appLaunched)
        analyticsService.track(event: .transactionAdded, properties: ["amount": 100.0])
        analyticsService.track(event: .budgetCreated, properties: ["category": "Food & Dining"])
        
        // Wait for events to be processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Error Handling Flow
    
    func testErrorHandlingEndToEndFlow() async throws {
        // Test error handling across the application
        let expectation = XCTestExpectation(description: "Error handling completes")
        
        // Test DI container error handling
        do {
            let _: String = diContainer.resolve(String.self)
            XCTFail("Should have thrown an error")
        } catch {
            // Expected error
        }
        
        // Test repository error handling
        let transactionRepo: any TransactionRepository = diContainer.resolve(TransactionRepository.self)
        
        do {
            let _ = try await transactionRepo.fetchById(UUID())
            XCTFail("Should have thrown an error")
        } catch {
            // Expected error
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Performance Flow
    
    func testPerformanceEndToEndFlow() async throws {
        // Test performance with large datasets
        let expectation = XCTestExpectation(description: "Performance test completes")
        
        // Create large dataset
        let transactions = createTestTransactions(count: 1000)
        for transaction in transactions {
            try await transactionRepo.save(transaction)
        }
        
        // Test performance of various operations
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test transaction fetching
        let fetchedTransactions = try await transactionRepo.fetchAll()
        XCTAssertEqual(fetchedTransactions.count, 1000)
        
        // Test categorization performance
        let categoryService: CategoryService = diContainer.resolve(CategoryService.self)
        let result = try await categoryService.categorizeTransaction(
            merchant: "Test Merchant",
            amount: Decimal(100.0),
            description: "Test transaction"
        )
        XCTAssertNotNil(result)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Verify performance is acceptable
        XCTAssertLessThan(executionTime, 5.0) // Should complete in under 5 seconds
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 10.0)
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
        
        diContainer.registerSingleton(VisionOCRService.self) { _ in
            VisionOCRService()
        }
        
        diContainer.registerSingleton(SmartTransactionParser.self) { _ in
            SmartTransactionParser()
        }
        
        diContainer.registerSingleton(CategoryService.self) { _ in
            CategoryService(context: self.context, backgroundContextProvider: self.backgroundContextProvider)
        }
        
        diContainer.registerSingleton(BudgetMonitoringService.self) { _ in
            BudgetMonitoringService(
                budgetRepository: self.diContainer.resolve(BudgetRepository.self),
                budgetCategoryRepository: self.diContainer.resolve(BudgetCategoryRepository.self),
                transactionRepository: self.diContainer.resolve(TransactionRepository.self),
                context: self.context
            )
        }
        
        diContainer.registerSingleton(CashflowForecastingService.self) { _ in
            CashflowForecastingService(context: self.context, backgroundContextProvider: self.backgroundContextProvider)
        }
        
        diContainer.registerSingleton(ScenarioPlanningService.self) { _ in
            ScenarioPlanningService(context: self.context, backgroundContextProvider: self.backgroundContextProvider)
        }
        
        diContainer.registerSingleton(PostHogAnalyticsService.self) { _ in
            PostHogAnalyticsService()
        }
    }
    
    private func createTestTransactions(count: Int = 10) -> [Transaction] {
        var transactions: [Transaction] = []
        
        for i in 0..<count {
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.amount = NSDecimalNumber(value: Double.random(in: 10...100))
            transaction.merchant = "Test Merchant \(i)"
            transaction.description = "Test transaction \(i)"
            transaction.date = Date()
            transaction.category = "Test Category"
            transaction.account = nil
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
            transactions.append(transaction)
        }
        
        return transactions
    }
}
