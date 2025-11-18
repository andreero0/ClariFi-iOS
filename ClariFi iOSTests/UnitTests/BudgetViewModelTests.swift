//
//  BudgetViewModelTests.swift
//  ClariFi_iOS Tests
//
//  Unit tests for BudgetViewModel using DI container and mocks
//

import XCTest
import CoreData
@testable import ClariFi_iOS

@MainActor
final class BudgetViewModelTests: XCTestCase {
    
    var container: DIContainer!
    var viewModel: BudgetViewModel!
    var mockBudgetRepository: MockBudgetRepository!
    var mockBudgetCategoryRepository: MockBudgetCategoryRepository!
    var mockTransactionRepository: MockTransactionRepository!
    var mockMonitoringService: MockBudgetMonitoringService!
    var context: NSManagedObjectContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory Core Data context
        let persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
        
        // Create mock repositories
        mockBudgetRepository = MockBudgetRepository()
        mockBudgetCategoryRepository = MockBudgetCategoryRepository()
        mockTransactionRepository = MockTransactionRepository()
        mockMonitoringService = MockBudgetMonitoringService()
        
        // Create test container with mocks
        container = AppDIContainer()
        container.registerSingleton(BudgetRepository.self) { _ in
            self.mockBudgetRepository
        }
        container.registerSingleton(BudgetCategoryRepository.self) { _ in
            self.mockBudgetCategoryRepository
        }
        container.registerSingleton(TransactionRepository.self) { _ in
            self.mockTransactionRepository
        }
        container.registerSingleton(BudgetMonitoringServiceProtocol.self) { _ in
            self.mockMonitoringService
        }
        
        // Create ViewModel with injected dependencies
        viewModel = BudgetViewModel(
            budgetRepository: mockBudgetRepository,
            budgetCategoryRepository: mockBudgetCategoryRepository,
            transactionRepository: mockTransactionRepository,
            monitoringService: mockMonitoringService,
            context: context
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockBudgetRepository = nil
        mockBudgetCategoryRepository = nil
        mockTransactionRepository = nil
        mockMonitoringService = nil
        container = nil
        context = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertNil(viewModel.budgetStatus)
        XCTAssertTrue(viewModel.alerts.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Load Budget Status Tests
    
    func testLoadBudgetStatusSuccess() async {
        // Arrange
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.isActive = true
        
        let expectedStatus = BudgetStatus(
            budget: budget,
            totalSpent: 500,
            totalBudgeted: 1000,
            percentageUsed: 0.5,
            categoryStatuses: [],
            isOverBudget: false,
            daysRemaining: 15
        )
        mockMonitoringService.mockBudgetStatus = expectedStatus
        
        // Act
        await viewModel.loadBudgetStatus()
        
        // Assert
        XCTAssertTrue(mockMonitoringService.checkBudgetStatusCalled)
        XCTAssertNotNil(viewModel.budgetStatus)
        XCTAssertEqual(viewModel.budgetStatus?.totalSpent, 500)
        XCTAssertEqual(viewModel.budgetStatus?.totalBudgeted, 1000)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    func testLoadBudgetStatusError() async {
        // Arrange
        mockMonitoringService.shouldThrowError = true
        
        // Act
        await viewModel.loadBudgetStatus()
        
        // Assert
        XCTAssertTrue(mockMonitoringService.checkBudgetStatusCalled)
        XCTAssertNil(viewModel.budgetStatus)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
    }
    
    // MARK: - Process Transaction Tests
    
    func testProcessNewTransactionSuccess() async {
        // Arrange
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.merchant = "Test Merchant"
        transaction.amount = NSDecimalNumber(value: 50)
        
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        
        let expectedStatus = BudgetStatus(
            budget: budget,
            totalSpent: 550,
            totalBudgeted: 1000,
            percentageUsed: 0.55,
            categoryStatuses: [],
            isOverBudget: false,
            daysRemaining: 15
        )
        mockMonitoringService.mockBudgetStatus = expectedStatus
        
        // Act
        await viewModel.processNewTransaction(transaction)
        
        // Assert
        XCTAssertTrue(mockMonitoringService.checkBudgetStatusCalled)
        XCTAssertNotNil(viewModel.budgetStatus)
        XCTAssertNil(viewModel.error)
    }
    
    func testProcessNewTransactionError() async {
        // Arrange
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        mockMonitoringService.shouldThrowError = true
        
        // Act
        await viewModel.processNewTransaction(transaction)
        
        // Assert
        XCTAssertNotNil(viewModel.error)
    }
    
    // MARK: - Alert Management Tests
    
    func testDismissAlert() {
        // Arrange
        let alert1 = BudgetAlert(
            id: UUID(),
            type: .approaching,
            severity: .warning,
            message: "Alert 1",
            categoryName: "Food"
        )
        let alert2 = BudgetAlert(
            id: UUID(),
            type: .exceeded,
            severity: .critical,
            message: "Alert 2",
            categoryName: "Shopping"
        )
        viewModel.alerts = [alert1, alert2]
        
        // Act
        viewModel.dismissAlert(alert1)
        
        // Assert
        XCTAssertEqual(viewModel.alerts.count, 1)
        XCTAssertEqual(viewModel.alerts.first?.id, alert2.id)
    }
    
    func testClearAllAlerts() {
        // Arrange
        let alert1 = BudgetAlert(
            id: UUID(),
            type: .approaching,
            severity: .warning,
            message: "Alert 1",
            categoryName: "Food"
        )
        let alert2 = BudgetAlert(
            id: UUID(),
            type: .exceeded,
            severity: .critical,
            message: "Alert 2",
            categoryName: "Shopping"
        )
        viewModel.alerts = [alert1, alert2]
        
        // Act
        viewModel.clearAllAlerts()
        
        // Assert
        XCTAssertTrue(viewModel.alerts.isEmpty)
    }
}
