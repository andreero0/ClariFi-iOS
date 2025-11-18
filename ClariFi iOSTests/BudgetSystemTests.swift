//
//  BudgetSystemTests.swift
//  ClariFi_iOSTests
//
//  Created by Kiro on 2025-10-10.
//

import Testing
import CoreData
@testable import ClariFi_iOS

struct BudgetSystemTests {
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    var budgetRepository: CoreDataBudgetRepository!
    var budgetCategoryRepository: CoreDataBudgetCategoryRepository!
    var transactionRepository: CoreDataTransactionRepository!
    var accountRepository: CoreDataAccountRepository!
    var templateService: BudgetTemplateService!
    var monitoringService: BudgetMonitoringService!
    var testAccount: Account!
    
    init() throws {
        
        
        // Use in-memory store for testing
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
        
        // Initialize repositories
        budgetRepository = CoreDataBudgetRepository(context: context)
        budgetCategoryRepository = CoreDataBudgetCategoryRepository(context: context)
        transactionRepository = CoreDataTransactionRepository(context: context)
        accountRepository = CoreDataAccountRepository(context: context)
        
        // Initialize services
        templateService = BudgetTemplateService.shared
        monitoringService = BudgetMonitoringService(
            budgetRepository: budgetRepository,
            budgetCategoryRepository: budgetCategoryRepository,
            transactionRepository: transactionRepository,
            context: context
        )
        
        // Create test account
        testAccount = Account(context: context)
        testAccount.id = UUID()
        testAccount.name = "Test Account"
        testAccount.type = "debit"
        testAccount.lastFourDigits = "1234"
        testAccount.isActive = true
        testAccount.createdAt = Date()
        testAccount.updatedAt = Date()
        try? context.save()
    }
    
    
    // MARK: - Helper Methods
    
    private func createBudgetCreationViewModel() -> BudgetCreationViewModel {
        return BudgetCreationViewModel(
            budgetRepository: budgetRepository,
            budgetCategoryRepository: budgetCategoryRepository,
            templateService: templateService,
            context: context
        )
    }
    
    private func createTestBudget(period: BudgetPeriod = .monthly, rolloverEnabled: Bool = false) -> Budget {
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = period.rawValue
        budget.startDate = Date()
        budget.isActive = true
        budget.rolloverEnabled = rolloverEnabled
        budget.createdAt = Date()
        budget.updatedAt = Date()
        try? context.save()
        return budget
    }
    
    private func createTestCategory(budget: Budget, name: String, budgeted: Decimal, spent: Decimal = 0, threshold: Float = 0.8, rollover: Bool = false) -> BudgetCategory {
        let category = BudgetCategory(context: context)
        category.id = UUID()
        category.name = name
        category.budgetedAmount = budgeted as NSDecimalNumber
        category.spentAmount = spent as NSDecimalNumber
        category.alertThreshold = threshold
        category.rolloverEnabled = rollover
        category.createdAt = Date()
        category.updatedAt = Date()
        category.budget = budget
        try? context.save()
        return category
    }
    
    private func createTestTransaction(amount: Decimal, category: String, date: Date = Date()) -> Transaction {
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.merchant = "Test Merchant"
        transaction.amount = amount as NSDecimalNumber
        transaction.category = category
        transaction.date = date
        transaction.account = testAccount
        transaction.isManual = true
        transaction.confidence = 1.0
        transaction.currency = "USD"
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        try? context.save()
        return transaction
    }
    
    // MARK: - Budget Creation and Template Tests
    
    func testGetAllTemplates_ReturnsAllFourTemplates() {
        let templates = templateService.getAllTemplates()
        
        #expect(templates.count == 4)
        #expect(templates.contains { $0.id == "student" } == true)
        #expect(templates.contains { $0.id == "gig-worker" } == true)
        #expect(templates.contains { $0.id == "family" } == true)
        #expect(templates.contains { $0.id == "professional" } == true)
    }
    
    func testGetTemplateById_WithValidId_ReturnsTemplate() {
        let template = templateService.getTemplate(byId: "student")
        
        #expect(template != nil)
        #expect(template?.id == "student")
        #expect(template?.name == "Student Budget")
    }
    
    func testGetTemplateById_WithInvalidId_ReturnsNil() {
        let template = templateService.getTemplate(byId: "invalid-id")
        
        #expect(template == nil)
    }
    
    func testStudentTemplate_HasCorrectCategories() {
        let template = templateService.getTemplate(byId: "student")
        
        #expect(template != nil)
        #expect(template?.categories.count == 8)
        #expect(template?.categories.contains { $0.name == "Tuition & Fees" } ?? false == true)
        #expect(template?.categories.contains { $0.name == "Books & Supplies" } ?? false == true)
        #expect(template?.categories.contains { $0.name == "Housing" } ?? false == true)
        #expect(template?.defaultPeriod == .monthly)
        #expect(template?.rolloverEnabled ?? false == true)
    }
    
    func testGigWorkerTemplate_HasCorrectCategories() {
        let template = templateService.getTemplate(byId: "gig-worker")
        
        #expect(template != nil)
        #expect(template?.categories.count == 8)
        #expect(template?.categories.contains { $0.name == "Business Expenses" } ?? false == true)
        #expect(template?.categories.contains { $0.name == "Taxes & Savings" } ?? false == true)
        #expect(template?.defaultPeriod == .monthly)
    }
    
    func testFamilyTemplate_HasCorrectCategories() {
        let template = templateService.getTemplate(byId: "family")
        
        #expect(template != nil)
        #expect(template?.categories.count == 10)
        #expect(template?.categories.contains { $0.name == "Childcare & Education" } ?? false == true)
        #expect(template?.rolloverEnabled ?? true == false)
    }
    
    func testProfessionalTemplate_HasCorrectCategories() {
        let template = templateService.getTemplate(byId: "professional")
        
        #expect(template != nil)
        #expect(template?.categories.count == 10)
        #expect(template?.categories.contains { $0.name == "Professional Development" } ?? false == true)
        #expect(template?.rolloverEnabled ?? false == true)
    }
    
    func testCalculateCategoryAmounts_WithValidTemplate_CalculatesCorrectly() {
        let template = templateService.getTemplate(byId: "student")!
        let totalBudget = Decimal(1000)
        
        let amounts = templateService.calculateCategoryAmounts(template: template, totalBudget: totalBudget)
        
        #expect(amounts.count == template.categories.count)
        
        // Check specific category calculation
        let tuitionAmount = amounts["Tuition & Fees"]
        #expect(tuitionAmount != nil)
        #expect(tuitionAmount == Decimal(300), accuracy: 0.01) // 30% of 1000
    }
    
    func testSelectTemplate_AppliesTemplateSettings() async {
        let viewModel = createBudgetCreationViewModel()
        let template = templateService.getTemplate(byId: "student")!
        
        await MainActor.run {
            viewModel.selectTemplate(template)
            
            #expect(viewModel.budgetName == "Student Budget")
            #expect(viewModel.selectedPeriod == .monthly)
            #expect(viewModel.rolloverEnabled == true)
            #expect(viewModel.categories.count == 8)
        }
    }
    
    func testSelectTemplate_WithTotalAmount_CalculatesProportionally() async {
        let viewModel = createBudgetCreationViewModel()
        let template = templateService.getTemplate(byId: "student")!
        
        await MainActor.run {
            viewModel.totalBudgetAmount = "2000"
            viewModel.selectTemplate(template)
            
            // Check that amounts are calculated based on percentages
            let tuitionCategory = viewModel.categories.first { $0.name == "Tuition & Fees" }
            #expect(tuitionCategory != nil)
            #expect(tuitionCategory?.amount == Decimal(600), accuracy: 0.01) // 30% of 2000
        }
    }
    
    func testCreateBudget_WithValidData_SavesSuccessfully() async {
        let viewModel = createBudgetCreationViewModel()
        
        await MainActor.run {
            viewModel.budgetName = "My Budget"
            viewModel.selectedPeriod = .monthly
            viewModel.startDate = Date()
            viewModel.rolloverEnabled = true
            viewModel.categories = [
                BudgetCategoryInput(id: UUID(), name: "Food", amount: 500, alertThreshold: 0.8, rolloverEnabled: true, color: "green"),
                BudgetCategoryInput(id: UUID(), name: "Transport", amount: 200, alertThreshold: 0.8, rolloverEnabled: true, color: "blue")
            ]
        }
        
        await viewModel.createBudget()
        
        await MainActor.run {
            #expect(viewModel.isLoading == false)
            #expect(viewModel.error == nil)
            #expect(viewModel.showingSuccess == true)
        }
        
        // Verify budget was saved
        let budget = try? await budgetRepository.fetchActiveBudget()
        #expect(budget != nil)
        #expect(budget?.name == "My Budget")
        #expect(budget?.isActive ?? false == true)
        
        // Verify categories were saved
        let categories = try? await budgetCategoryRepository.fetchByBudget(budget!)
        #expect(categories?.count == 2)
    }
    
    func testCreateBudget_DeactivatesExistingBudget() async {
        // Create existing budget
        let existingBudget = createTestBudget()
        #expect(existingBudget.isActive == true)
        
        let viewModel = createBudgetCreationViewModel()
        
        await MainActor.run {
            viewModel.budgetName = "New Budget"
            viewModel.selectedPeriod = .monthly
            viewModel.categories = [
                BudgetCategoryInput(id: UUID(), name: "Food", amount: 500, alertThreshold: 0.8, rolloverEnabled: false, color: nil)
            ]
        }
        
        await viewModel.createBudget()
        
        // Verify old budget is deactivated
        context.refresh(existingBudget, mergeChanges: true)
        #expect(existingBudget.isActive == false)
        
        // Verify new budget is active
        let newBudget = try? await budgetRepository.fetchActiveBudget()
        #expect(newBudget != nil)
        #expect(newBudget?.name == "New Budget")
        #expect(newBudget?.isActive ?? false == true)
    }
    
    func testIsValid_WithCompleteData_ReturnsTrue() async {
        let viewModel = createBudgetCreationViewModel()
        
        await MainActor.run {
            viewModel.budgetName = "Test Budget"
            viewModel.categories = [
                BudgetCategoryInput(id: UUID(), name: "Food", amount: 500, alertThreshold: 0.8, rolloverEnabled: false, color: nil)
            ]
            
            #expect(viewModel.isValid == true)
        }
    }
    
    func testIsValid_WithEmptyName_ReturnsFalse() async {
        let viewModel = createBudgetCreationViewModel()
        
        await MainActor.run {
            viewModel.budgetName = ""
            viewModel.categories = [
                BudgetCategoryInput(id: UUID(), name: "Food", amount: 500, alertThreshold: 0.8, rolloverEnabled: false, color: nil)
            ]
            
            #expect(viewModel.isValid == false)
        }
    }
    
    func testIsValid_WithEmptyCategories_ReturnsFalse() async {
        let viewModel = createBudgetCreationViewModel()
        
        await MainActor.run {
            viewModel.budgetName = "Test Budget"
            viewModel.categories = []
            
            #expect(viewModel.isValid == false)
        }
    }
    
    func testIsValid_WithInvalidCategoryAmount_ReturnsFalse() async {
        let viewModel = createBudgetCreationViewModel()
        
        await MainActor.run {
            viewModel.budgetName = "Test Budget"
            viewModel.categories = [
                BudgetCategoryInput(id: UUID(), name: "Food", amount: 0, alertThreshold: 0.8, rolloverEnabled: false, color: nil)
            ]
            
            #expect(viewModel.isValid == false)
        }
    }
    
    // MARK: - Spending Tracking and Alert Generation Tests
    
    func testGetBudgetStatus_CalculatesSpendingCorrectly() async throws {
        let budget = createTestBudget()
        let category = createTestCategory(budget: budget, name: "Food", budgeted: 500)
        
        // Create transactions
        _ = createTestTransaction(amount: 100, category: "Food")
        _ = createTestTransaction(amount: 150, category: "Food")
        
        let status = try await monitoringService.getBudgetStatus()
        
        #expect(status != nil)
        #expect(status?.categoryStatuses.count == 1)
        
        let foodStatus = status?.categoryStatuses.first { $0.category.name == "Food" }
        #expect(foodStatus != nil)
        #expect(foodStatus?.spent == 250)
        #expect(foodStatus?.remaining == 250)
        #expect(foodStatus?.percentageUsed == 0.5, accuracy: 0.01)
        #expect(foodStatus?.isOverBudget ?? true == false)
    }
    
    func testGetBudgetStatus_DetectsOverBudget() async throws {
        let budget = createTestBudget()
        let category = createTestCategory(budget: budget, name: "Shopping", budgeted: 200)
        
        // Create transactions that exceed budget
        _ = createTestTransaction(amount: 150, category: "Shopping")
        _ = createTestTransaction(amount: 100, category: "Shopping")
        
        let status = try await monitoringService.getBudgetStatus()
        
        let shoppingStatus = status?.categoryStatuses.first { $0.category.name == "Shopping" }
        #expect(shoppingStatus != nil)
        #expect(shoppingStatus?.spent == 250)
        #expect(shoppingStatus?.isOverBudget ?? false == true)
        #expect(shoppingStatus?.remaining == -50)
    }
    
    func testGetBudgetStatus_GeneratesApproachingAlert() async throws {
        let budget = createTestBudget()
        let category = createTestCategory(budget: budget, name: "Entertainment", budgeted: 100, threshold: 0.8)
        
        // Spend 85% of budget (above threshold but not over)
        _ = createTestTransaction(amount: 85, category: "Entertainment")
        
        let status = try await monitoringService.getBudgetStatus()
        
        #expect(status != nil)
        #expect(status?.alerts.isEmpty ?? true == false)
        
        let alert = status?.alerts.first { $0.categoryName == "Entertainment" }
        #expect(alert != nil)
        #expect(alert?.type == .approaching)
        #expect(alert?.severity == .warning)
    }
    
    func testGetBudgetStatus_GeneratesExceededAlert() async throws {
        let budget = createTestBudget()
        let category = createTestCategory(budget: budget, name: "Dining", budgeted: 300)
        
        // Exceed budget
        _ = createTestTransaction(amount: 200, category: "Dining")
        _ = createTestTransaction(amount: 150, category: "Dining")
        
        let status = try await monitoringService.getBudgetStatus()
        
        let alert = status?.alerts.first { $0.categoryName == "Dining" }
        #expect(alert != nil)
        #expect(alert?.type == .exceeded)
        #expect(alert?.severity == .critical)
    }
    
    func testProcessTransaction_UpdatesCategorySpending() async throws {
        let budget = createTestBudget()
        let category = createTestCategory(budget: budget, name: "Groceries", budgeted: 400)
        
        let transaction = createTestTransaction(amount: 50, category: "Groceries")
        
        try await monitoringService.processTransaction(transaction)
        
        context.refresh(category, mergeChanges: true)
        #expect(category.spentAmount as Decimal == 50)
    }
    
    func testProcessTransaction_GeneratesAlertWhenThresholdExceeded() async throws {
        let budget = createTestBudget()
        let category = createTestCategory(budget: budget, name: "Transport", budgeted: 100, spent: 70, threshold: 0.8)
        
        let transaction = createTestTransaction(amount: 15, category: "Transport")
        
        var alertReceived = false
        let expectation = XCTestExpectation(description: "Alert published")
        
        let cancellable = monitoringService.alertsPublisher.sink { alerts in
            if !alerts.isEmpty {
                alertReceived = true
                expectation.fulfill()
            }
        }
        
        try await monitoringService.processTransaction(transaction)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        #expect(alertReceived == true)
        
        cancellable.cancel()
    }
    
    // MARK: - Rollover Calculations and Period Management Tests
    
    func testBudgetPeriod_NextPeriodStart_Weekly() {
        let period = BudgetPeriod.weekly
        let startDate = Date()
        
        let nextStart = period.nextPeriodStart(from: startDate)
        
        let calendar = Calendar.current
        let daysDiff = calendar.dateComponents([.day], from: startDate, to: nextStart).day
        #expect(daysDiff == 7)
    }
    
    func testBudgetPeriod_NextPeriodStart_Monthly() {
        let period = BudgetPeriod.monthly
        let startDate = Date()
        
        let nextStart = period.nextPeriodStart(from: startDate)
        
        let calendar = Calendar.current
        let monthsDiff = calendar.dateComponents([.month], from: startDate, to: nextStart).month
        #expect(monthsDiff == 1)
    }
    
    func testBudgetPeriod_PeriodEnd_Weekly() {
        let period = BudgetPeriod.weekly
        let startDate = Date()
        
        let endDate = period.periodEnd(from: startDate)
        
        let calendar = Calendar.current
        let daysDiff = calendar.dateComponents([.day], from: startDate, to: endDate).day
        #expect(daysDiff == 6)
    }
    
    func testBudgetPeriod_PeriodEnd_Monthly() {
        let period = BudgetPeriod.monthly
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        
        let endDate = period.periodEnd(from: startDate)
        
        let components = calendar.dateComponents([.year, .month, .day], from: endDate)
        #expect(components.year == 2025)
        #expect(components.month == 1)
        #expect(components.day == 31)
    }
    
    func testCheckAndPerformRollover_WithExpiredPeriod_PerformsRollover() async throws {
        let calendar = Calendar.current
        let pastDate = calendar.date(byAdding: .month, value: -2, to: Date())!
        
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Expired Budget"
        budget.period = BudgetPeriod.monthly.rawValue
        budget.startDate = pastDate
        budget.isActive = true
        budget.rolloverEnabled = true
        budget.createdAt = Date()
        budget.updatedAt = Date()
        try context.save()
        
        let category = createTestCategory(budget: budget, name: "Savings", budgeted: 500, spent: 300, rollover: true)
        
        try await monitoringService.checkAndPerformRollover()
        
        context.refresh(budget, mergeChanges: true)
        context.refresh(category, mergeChanges: true)
        
        // Budget start date should be updated
        #expect(budget.startDate! > pastDate)
        
        // Category spent should be reset
        #expect(category.spentAmount as Decimal == 0)
        
        // Category budget should include rollover (500 + 200 remaining)
        #expect(category.budgetedAmount as Decimal == 700)
    }
    
    func testCheckAndPerformRollover_WithRolloverDisabled_DoesNotRollover() async throws {
        let calendar = Calendar.current
        let pastDate = calendar.date(byAdding: .month, value: -2, to: Date())!
        
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "No Rollover Budget"
        budget.period = BudgetPeriod.monthly.rawValue
        budget.startDate = pastDate
        budget.isActive = true
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        try context.save()
        
        let category = createTestCategory(budget: budget, name: "Food", budgeted: 400, spent: 250, rollover: false)
        
        try await monitoringService.checkAndPerformRollover()
        
        context.refresh(category, mergeChanges: true)
        
        // Budget should remain the same (no rollover)
        #expect(category.budgetedAmount as Decimal == 400)
        
        // Spent should be reset
        #expect(category.spentAmount as Decimal == 0)
    }
    
    func testCheckAndPerformRollover_WithOverspending_DoesNotRolloverNegative() async throws {
        let calendar = Calendar.current
        let pastDate = calendar.date(byAdding: .month, value: -2, to: Date())!
        
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Overspent Budget"
        budget.period = BudgetPeriod.monthly.rawValue
        budget.startDate = pastDate
        budget.isActive = true
        budget.rolloverEnabled = true
        budget.createdAt = Date()
        budget.updatedAt = Date()
        try context.save()
        
        let category = createTestCategory(budget: budget, name: "Shopping", budgeted: 200, spent: 250, rollover: true)
        
        try await monitoringService.checkAndPerformRollover()
        
        context.refresh(category, mergeChanges: true)
        
        // Budget should remain the same (no negative rollover)
        #expect(category.budgetedAmount as Decimal == 200)
        
        // Spent should be reset
        #expect(category.spentAmount as Decimal == 0)
    }
    
    func testCheckAndPerformRollover_GeneratesRolloverAlerts() async throws {
        let calendar = Calendar.current
        let pastDate = calendar.date(byAdding: .month, value: -2, to: Date())!
        
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Alert Budget"
        budget.period = BudgetPeriod.monthly.rawValue
        budget.startDate = pastDate
        budget.isActive = true
        budget.rolloverEnabled = true
        budget.createdAt = Date()
        budget.updatedAt = Date()
        try context.save()
        
        let category = createTestCategory(budget: budget, name: "Utilities", budgeted: 300, spent: 200, rollover: true)
        
        var alertsReceived: [BudgetAlert] = []
        let expectation = XCTestExpectation(description: "Rollover alerts published")
        
        let cancellable = monitoringService.alertsPublisher.sink { alerts in
            alertsReceived.append(contentsOf: alerts)
            if alerts.contains(where: { $0.type == .rollover }) {
                expectation.fulfill()
            }
        }
        
        try await monitoringService.checkAndPerformRollover()
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        let rolloverAlert = alertsReceived.first { $0.type == .rollover && $0.categoryName == "Utilities" }
        #expect(rolloverAlert != nil)
        #expect(rolloverAlert?.severity == .info)
        
        cancellable.cancel()
    }
    
    func testCheckAndPerformRollover_WithCurrentPeriod_DoesNotPerformRollover() async throws {
        let budget = createTestBudget()
        let category = createTestCategory(budget: budget, name: "Current", budgeted: 500, spent: 200, rollover: true)
        
        let originalBudgeted = category.budgetedAmount
        let originalSpent = category.spentAmount
        
        try await monitoringService.checkAndPerformRollover()
        
        context.refresh(category, mergeChanges: true)
        
        // Nothing should change for current period
        #expect(category.budgetedAmount == originalBudgeted)
        #expect(category.spentAmount == originalSpent)
    }
    
    func testGetBudgetStatus_CalculatesDaysRemaining() async throws {
        let budget = createTestBudget(period: .weekly)
        let category = createTestCategory(budget: budget, name: "Test", budgeted: 100)
        
        let status = try await monitoringService.getBudgetStatus()
        
        #expect(status != nil)
        #expect(status?.daysRemaining ?? -1 >= 0)
        #expect(status?.daysRemaining ?? 999 <= 7)
    }
    
    func testGetBudgetStatus_CalculatesTotalBudgetedAndSpent() async throws {
        let budget = createTestBudget()
        _ = createTestCategory(budget: budget, name: "Food", budgeted: 500)
        _ = createTestCategory(budget: budget, name: "Transport", budgeted: 200)
        _ = createTestCategory(budget: budget, name: "Entertainment", budgeted: 100)
        
        _ = createTestTransaction(amount: 100, category: "Food")
        _ = createTestTransaction(amount: 50, category: "Transport")
        
        let status = try await monitoringService.getBudgetStatus()
        
        #expect(status != nil)
        #expect(status?.totalBudgeted == 800)
        #expect(status?.totalSpent == 150)
        #expect(status?.percentageUsed == 0.1875, accuracy: 0.001) // 150/800
    }
}
