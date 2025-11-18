//
//  MockRepositories.swift
//  ClariFi_iOS Tests
//
//  Mock implementations for repository protocols to support testing
//

import Foundation
import CoreData

// MARK: - Mock Transaction Repository

@MainActor
class MockTransactionRepository: TransactionRepository {
    typealias Entity = Transaction
    
    // Tracking flags
    var saveCalled = false
    var deleteCalled = false
    var fetchAllCalled = false
    var fetchByIdCalled = false
    var fetchByDateRangeCalled = false
    var fetchByAccountCalled = false
    var fetchByCategoryCalled = false
    var fetchByMerchantCalled = false
    var fetchLowConfidenceCalled = false
    var batchUpdateCalled = false
    var fetchRecentCalled = false
    var searchCalled = false
    
    // Configurable behavior
    var mockTransactions: [Transaction] = []
    var shouldThrowError = false
    var errorToThrow: RepositoryError = .fetchFailed(NSError(domain: "MockRepository", code: 1))
    var saveCallCount = 0
    var deleteCallCount = 0
    
    // Captured parameters
    var lastSavedTransaction: Transaction?
    var lastDeletedTransaction: Transaction?
    var lastSearchQuery: String?
    var lastDateRange: (start: Date, end: Date)?
    var lastAccount: Account?
    var lastCategory: String?
    var lastMerchant: String?
    
    func save(_ entity: Transaction) async throws {
        saveCalled = true
        saveCallCount += 1
        lastSavedTransaction = entity
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Add to mock data if not already present
        if !mockTransactions.contains(where: { $0.id == entity.id }) {
            mockTransactions.append(entity)
        }
    }
    
    func delete(_ entity: Transaction) async throws {
        deleteCalled = true
        deleteCallCount += 1
        lastDeletedTransaction = entity
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockTransactions.removeAll { $0.id == entity.id }
    }
    
    func fetchAll() async throws -> [Transaction] {
        fetchAllCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockTransactions
    }
    
    func fetchById(_ id: UUID) async throws -> Transaction? {
        fetchByIdCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockTransactions.first { $0.id == id }
    }
    
    func fetchByDateRange(_ startDate: Date, _ endDate: Date) async throws -> [Transaction] {
        fetchByDateRangeCalled = true
        lastDateRange = (startDate, endDate)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockTransactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return date >= startDate && date <= endDate
        }
    }
    
    func fetchByAccount(_ account: Account) async throws -> [Transaction] {
        fetchByAccountCalled = true
        lastAccount = account
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockTransactions.filter { $0.account == account }
    }
    
    func fetchByCategory(_ category: String) async throws -> [Transaction] {
        fetchByCategoryCalled = true
        lastCategory = category
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockTransactions.filter { $0.category == category }
    }
    
    func fetchByMerchant(_ merchant: String) async throws -> [Transaction] {
        fetchByMerchantCalled = true
        lastMerchant = merchant
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockTransactions.filter { $0.merchant == merchant }
    }
    
    func fetchLowConfidenceTransactions(threshold: Float) async throws -> [Transaction] {
        fetchLowConfidenceCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockTransactions.filter { $0.confidence < threshold }
    }
    
    func batchUpdate(_ transactions: [Transaction]) async throws {
        batchUpdateCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Update mock data
        for transaction in transactions {
            if let index = mockTransactions.firstIndex(where: { $0.id == transaction.id }) {
                mockTransactions[index] = transaction
            }
        }
    }
    
    func fetchRecentTransactions(limit: Int) async throws -> [Transaction] {
        fetchRecentCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return Array(mockTransactions.sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }.prefix(limit))
    }
    
    func searchTransactions(query: String) async throws -> [Transaction] {
        searchCalled = true
        lastSearchQuery = query
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        let lowercaseQuery = query.lowercased()
        return mockTransactions.filter { transaction in
            (transaction.merchant?.lowercased().contains(lowercaseQuery) ?? false) ||
            (transaction.category?.lowercased().contains(lowercaseQuery) ?? false) ||
            (transaction.notes?.lowercased().contains(lowercaseQuery) ?? false)
        }
    }
    
    // Helper method to reset state
    func reset() {
        saveCalled = false
        deleteCalled = false
        fetchAllCalled = false
        fetchByIdCalled = false
        fetchByDateRangeCalled = false
        fetchByAccountCalled = false
        fetchByCategoryCalled = false
        fetchByMerchantCalled = false
        fetchLowConfidenceCalled = false
        batchUpdateCalled = false
        fetchRecentCalled = false
        searchCalled = false
        
        mockTransactions.removeAll()
        shouldThrowError = false
        saveCallCount = 0
        deleteCallCount = 0
        
        lastSavedTransaction = nil
        lastDeletedTransaction = nil
        lastSearchQuery = nil
        lastDateRange = nil
        lastAccount = nil
        lastCategory = nil
        lastMerchant = nil
    }
}

// MARK: - Mock Account Repository

@MainActor
class MockAccountRepository: AccountRepository {
    typealias Entity = Account
    
    // Tracking flags
    var saveCalled = false
    var deleteCalled = false
    var fetchAllCalled = false
    var fetchByIdCalled = false
    var fetchActiveAccountsCalled = false
    var fetchByTypeCalled = false
    var deactivateAccountCalled = false
    var getTransactionCountCalled = false
    var getOrCreateDefaultAccountCalled = false
    
    // Configurable behavior
    var mockAccounts: [Account] = []
    var shouldThrowError = false
    var errorToThrow: RepositoryError = .fetchFailed(NSError(domain: "MockRepository", code: 1))
    var saveCallCount = 0
    var deleteCallCount = 0
    var mockTransactionCount: Int = 0
    var mockDefaultAccount: Account?
    
    // Captured parameters
    var lastSavedAccount: Account?
    var lastDeletedAccount: Account?
    var lastAccountType: String?
    var lastDeactivatedAccount: Account?
    var lastTransactionCountAccount: Account?
    
    func save(_ entity: Account) async throws {
        saveCalled = true
        saveCallCount += 1
        lastSavedAccount = entity
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if !mockAccounts.contains(where: { $0.id == entity.id }) {
            mockAccounts.append(entity)
        }
    }
    
    func delete(_ entity: Account) async throws {
        deleteCalled = true
        deleteCallCount += 1
        lastDeletedAccount = entity
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockAccounts.removeAll { $0.id == entity.id }
    }
    
    func fetchAll() async throws -> [Account] {
        fetchAllCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockAccounts
    }
    
    func fetchById(_ id: UUID) async throws -> Account? {
        fetchByIdCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockAccounts.first { $0.id == id }
    }
    
    func fetchActiveAccounts() async throws -> [Account] {
        fetchActiveAccountsCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockAccounts.filter { $0.isActive }
    }
    
    func fetchByType(_ type: String) async throws -> [Account] {
        fetchByTypeCalled = true
        lastAccountType = type
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockAccounts.filter { $0.type == type }
    }
    
    func deactivateAccount(_ account: Account) async throws {
        deactivateAccountCalled = true
        lastDeactivatedAccount = account
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        account.isActive = false
    }
    
    func getTransactionCount(for account: Account) async throws -> Int {
        getTransactionCountCalled = true
        lastTransactionCountAccount = account
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockTransactionCount
    }
    
    func getOrCreateDefaultAccount() async throws -> Account {
        getOrCreateDefaultAccountCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let defaultAccount = mockDefaultAccount {
            return defaultAccount
        }
        
        // Create a default account if not provided
        let context = PersistenceController.preview.container.viewContext
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Default Account"
        account.type = "checking"
        account.isActive = true
        mockDefaultAccount = account
        mockAccounts.append(account)
        return account
    }
    
    // Helper method to reset state
    func reset() {
        saveCalled = false
        deleteCalled = false
        fetchAllCalled = false
        fetchByIdCalled = false
        fetchActiveAccountsCalled = false
        fetchByTypeCalled = false
        deactivateAccountCalled = false
        getTransactionCountCalled = false
        getOrCreateDefaultAccountCalled = false
        
        mockAccounts.removeAll()
        shouldThrowError = false
        saveCallCount = 0
        deleteCallCount = 0
        mockTransactionCount = 0
        mockDefaultAccount = nil
        
        lastSavedAccount = nil
        lastDeletedAccount = nil
        lastAccountType = nil
        lastDeactivatedAccount = nil
        lastTransactionCountAccount = nil
    }
}

// MARK: - Mock Budget Repository

@MainActor
class MockBudgetRepository: BudgetRepository {
    typealias Entity = Budget
    
    // Tracking flags
    var saveCalled = false
    var deleteCalled = false
    var fetchAllCalled = false
    var fetchByIdCalled = false
    var fetchActiveBudgetCalled = false
    var fetchByPeriodCalled = false
    var deactivateBudgetCalled = false
    var fetchBudgetWithCategoriesCalled = false
    
    // Configurable behavior
    var mockBudgets: [Budget] = []
    var shouldThrowError = false
    var errorToThrow: RepositoryError = .fetchFailed(NSError(domain: "MockRepository", code: 1))
    var saveCallCount = 0
    var deleteCallCount = 0
    var mockActiveBudget: Budget?
    
    // Captured parameters
    var lastSavedBudget: Budget?
    var lastDeletedBudget: Budget?
    var lastPeriod: String?
    var lastDeactivatedBudget: Budget?
    var lastBudgetIdForCategories: UUID?
    
    func save(_ entity: Budget) async throws {
        saveCalled = true
        saveCallCount += 1
        lastSavedBudget = entity
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if !mockBudgets.contains(where: { $0.id == entity.id }) {
            mockBudgets.append(entity)
        }
    }
    
    func delete(_ entity: Budget) async throws {
        deleteCalled = true
        deleteCallCount += 1
        lastDeletedBudget = entity
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockBudgets.removeAll { $0.id == entity.id }
    }
    
    func fetchAll() async throws -> [Budget] {
        fetchAllCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockBudgets
    }
    
    func fetchById(_ id: UUID) async throws -> Budget? {
        fetchByIdCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockBudgets.first { $0.id == id }
    }
    
    func fetchActiveBudget() async throws -> Budget? {
        fetchActiveBudgetCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let activeBudget = mockActiveBudget {
            return activeBudget
        }
        
        return mockBudgets.first { $0.isActive }
    }
    
    func fetchByPeriod(_ period: String) async throws -> [Budget] {
        fetchByPeriodCalled = true
        lastPeriod = period
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockBudgets.filter { $0.period == period }
    }
    
    func deactivateBudget(_ budget: Budget) async throws {
        deactivateBudgetCalled = true
        lastDeactivatedBudget = budget
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        budget.isActive = false
    }
    
    func fetchBudgetWithCategories(_ budgetId: UUID) async throws -> Budget? {
        fetchBudgetWithCategoriesCalled = true
        lastBudgetIdForCategories = budgetId
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockBudgets.first { $0.id == budgetId }
    }
    
    // Helper method to reset state
    func reset() {
        saveCalled = false
        deleteCalled = false
        fetchAllCalled = false
        fetchByIdCalled = false
        fetchActiveBudgetCalled = false
        fetchByPeriodCalled = false
        deactivateBudgetCalled = false
        fetchBudgetWithCategoriesCalled = false
        
        mockBudgets.removeAll()
        shouldThrowError = false
        saveCallCount = 0
        deleteCallCount = 0
        mockActiveBudget = nil
        
        lastSavedBudget = nil
        lastDeletedBudget = nil
        lastPeriod = nil
        lastDeactivatedBudget = nil
        lastBudgetIdForCategories = nil
    }
}


// MARK: - Mock Budget Category Repository

@MainActor
class MockBudgetCategoryRepository: BudgetCategoryRepository {
    typealias Entity = BudgetCategory
    
    // Tracking flags
    var saveCalled = false
    var deleteCalled = false
    var fetchAllCalled = false
    var fetchByIdCalled = false
    var fetchByBudgetCalled = false
    var fetchByNameCalled = false
    var updateSpentAmountCalled = false
    var fetchOverBudgetCategoriesCalled = false
    
    // Configurable behavior
    var mockCategories: [BudgetCategory] = []
    var shouldThrowError = false
    var errorToThrow: RepositoryError = .fetchFailed(NSError(domain: "MockRepository", code: 1))
    var saveCallCount = 0
    var deleteCallCount = 0
    
    // Captured parameters
    var lastSavedCategory: BudgetCategory?
    var lastDeletedCategory: BudgetCategory?
    var lastBudget: Budget?
    var lastCategoryName: String?
    var lastUpdatedCategory: BudgetCategory?
    var lastUpdatedAmount: NSDecimalNumber?
    var lastOverBudgetBudget: Budget?
    
    func save(_ entity: BudgetCategory) async throws {
        saveCalled = true
        saveCallCount += 1
        lastSavedCategory = entity
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if !mockCategories.contains(where: { $0.id == entity.id }) {
            mockCategories.append(entity)
        }
    }
    
    func delete(_ entity: BudgetCategory) async throws {
        deleteCalled = true
        deleteCallCount += 1
        lastDeletedCategory = entity
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockCategories.removeAll { $0.id == entity.id }
    }
    
    func fetchAll() async throws -> [BudgetCategory] {
        fetchAllCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockCategories
    }
    
    func fetchById(_ id: UUID) async throws -> BudgetCategory? {
        fetchByIdCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockCategories.first { $0.id == id }
    }
    
    func fetchByBudget(_ budget: Budget) async throws -> [BudgetCategory] {
        fetchByBudgetCalled = true
        lastBudget = budget
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockCategories.filter { $0.budget == budget }
    }
    
    func fetchByName(_ name: String, in budget: Budget) async throws -> BudgetCategory? {
        fetchByNameCalled = true
        lastCategoryName = name
        lastBudget = budget
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockCategories.first { $0.name == name && $0.budget == budget }
    }
    
    func updateSpentAmount(_ category: BudgetCategory, amount: NSDecimalNumber) async throws {
        updateSpentAmountCalled = true
        lastUpdatedCategory = category
        lastUpdatedAmount = amount
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        category.spentAmount = amount
    }
    
    func fetchOverBudgetCategories(in budget: Budget) async throws -> [BudgetCategory] {
        fetchOverBudgetCategoriesCalled = true
        lastOverBudgetBudget = budget
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockCategories.filter { category in
            category.budget == budget &&
            category.spentAmount?.decimalValue ?? 0 > category.budgetedAmount?.decimalValue ?? 0
        }
    }
    
    // Helper method to reset state
    func reset() {
        saveCalled = false
        deleteCalled = false
        fetchAllCalled = false
        fetchByIdCalled = false
        fetchByBudgetCalled = false
        fetchByNameCalled = false
        updateSpentAmountCalled = false
        fetchOverBudgetCategoriesCalled = false
        
        mockCategories.removeAll()
        shouldThrowError = false
        saveCallCount = 0
        deleteCallCount = 0
        
        lastSavedCategory = nil
        lastDeletedCategory = nil
        lastBudget = nil
        lastCategoryName = nil
        lastUpdatedCategory = nil
        lastUpdatedAmount = nil
        lastOverBudgetBudget = nil
    }
}

// MARK: - Mock Statement Repository

@MainActor
class MockStatementRepository: StatementRepository {
    typealias Entity = Statement
    
    // Tracking flags
    var saveCalled = false
    var deleteCalled = false
    var fetchAllCalled = false
    var fetchByIdCalled = false
    var fetchByHashCalled = false
    var fetchByProcessingStatusCalled = false
    var fetchRecentStatementsCalled = false
    var updateProcessingStatusCalled = false
    var fetchStatementWithTransactionsCalled = false
    
    // Configurable behavior
    var mockStatements: [Statement] = []
    var shouldThrowError = false
    var errorToThrow: RepositoryError = .fetchFailed(NSError(domain: "MockRepository", code: 1))
    var saveCallCount = 0
    var deleteCallCount = 0
    
    // Captured parameters
    var lastSavedStatement: Statement?
    var lastDeletedStatement: Statement?
    var lastHash: String?
    var lastProcessingStatus: String?
    var lastUpdatedStatement: Statement?
    var lastUpdatedStatus: String?
    var lastStatementIdForTransactions: UUID?
    
    func save(_ entity: Statement) async throws {
        saveCalled = true
        saveCallCount += 1
        lastSavedStatement = entity
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if !mockStatements.contains(where: { $0.id == entity.id }) {
            mockStatements.append(entity)
        }
    }
    
    func delete(_ entity: Statement) async throws {
        deleteCalled = true
        deleteCallCount += 1
        lastDeletedStatement = entity
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockStatements.removeAll { $0.id == entity.id }
    }
    
    func fetchAll() async throws -> [Statement] {
        fetchAllCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockStatements
    }
    
    func fetchById(_ id: UUID) async throws -> Statement? {
        fetchByIdCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockStatements.first { $0.id == id }
    }
    
    func fetchByHash(_ hash: String) async throws -> Statement? {
        fetchByHashCalled = true
        lastHash = hash
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockStatements.first { $0.fileHash == hash }
    }
    
    func fetchByProcessingStatus(_ status: String) async throws -> [Statement] {
        fetchByProcessingStatusCalled = true
        lastProcessingStatus = status
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockStatements.filter { $0.processingStatus == status }
    }
    
    func fetchRecentStatements(limit: Int) async throws -> [Statement] {
        fetchRecentStatementsCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return Array(mockStatements.sorted { ($0.uploadDate ?? Date.distantPast) > ($1.uploadDate ?? Date.distantPast) }.prefix(limit))
    }
    
    func updateProcessingStatus(_ statement: Statement, status: String) async throws {
        updateProcessingStatusCalled = true
        lastUpdatedStatement = statement
        lastUpdatedStatus = status
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        statement.processingStatus = status
    }
    
    func fetchStatementWithTransactions(_ statementId: UUID) async throws -> Statement? {
        fetchStatementWithTransactionsCalled = true
        lastStatementIdForTransactions = statementId
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockStatements.first { $0.id == statementId }
    }
    
    // Helper method to reset state
    func reset() {
        saveCalled = false
        deleteCalled = false
        fetchAllCalled = false
        fetchByIdCalled = false
        fetchByHashCalled = false
        fetchByProcessingStatusCalled = false
        fetchRecentStatementsCalled = false
        updateProcessingStatusCalled = false
        fetchStatementWithTransactionsCalled = false
        
        mockStatements.removeAll()
        shouldThrowError = false
        saveCallCount = 0
        deleteCallCount = 0
        
        lastSavedStatement = nil
        lastDeletedStatement = nil
        lastHash = nil
        lastProcessingStatus = nil
        lastUpdatedStatement = nil
        lastUpdatedStatus = nil
        lastStatementIdForTransactions = nil
    }
}

// MARK: - Mock Recurring Transaction Repository

@MainActor
class MockRecurringTransactionRepository: RecurringTransactionRepository {
    typealias Entity = RecurringTransaction
    
    // Tracking flags
    var saveCalled = false
    var deleteCalled = false
    var fetchAllCalled = false
    var fetchByIdCalled = false
    var fetchActiveRecurringCalled = false
    var fetchByAccountCalled = false
    var fetchDueTransactionsCalled = false
    var updateNextOccurrenceCalled = false
    var deactivateRecurringCalled = false
    
    // Configurable behavior
    var mockRecurringTransactions: [RecurringTransaction] = []
    var shouldThrowError = false
    var errorToThrow: RepositoryError = .fetchFailed(NSError(domain: "MockRepository", code: 1))
    var saveCallCount = 0
    var deleteCallCount = 0
    
    // Captured parameters
    var lastSavedRecurring: RecurringTransaction?
    var lastDeletedRecurring: RecurringTransaction?
    var lastAccount: Account?
    var lastDueDate: Date?
    var lastUpdatedRecurring: RecurringTransaction?
    var lastNextDate: Date?
    var lastDeactivatedRecurring: RecurringTransaction?
    
    func save(_ entity: RecurringTransaction) async throws {
        saveCalled = true
        saveCallCount += 1
        lastSavedRecurring = entity
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if !mockRecurringTransactions.contains(where: { $0.id == entity.id }) {
            mockRecurringTransactions.append(entity)
        }
    }
    
    func delete(_ entity: RecurringTransaction) async throws {
        deleteCalled = true
        deleteCallCount += 1
        lastDeletedRecurring = entity
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockRecurringTransactions.removeAll { $0.id == entity.id }
    }
    
    func fetchAll() async throws -> [RecurringTransaction] {
        fetchAllCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockRecurringTransactions
    }
    
    func fetchById(_ id: UUID) async throws -> RecurringTransaction? {
        fetchByIdCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockRecurringTransactions.first { $0.id == id }
    }
    
    func fetchActiveRecurring() async throws -> [RecurringTransaction] {
        fetchActiveRecurringCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockRecurringTransactions.filter { $0.isActive }
    }
    
    func fetchByAccount(_ account: Account) async throws -> [RecurringTransaction] {
        fetchByAccountCalled = true
        lastAccount = account
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockRecurringTransactions.filter { $0.account == account }
    }
    
    func fetchDueTransactions(upToDate: Date) async throws -> [RecurringTransaction] {
        fetchDueTransactionsCalled = true
        lastDueDate = upToDate
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockRecurringTransactions.filter { recurring in
            guard let nextOccurrence = recurring.nextOccurrence else { return false }
            return nextOccurrence <= upToDate && recurring.isActive
        }
    }
    
    func updateNextOccurrence(_ recurring: RecurringTransaction, nextDate: Date) async throws {
        updateNextOccurrenceCalled = true
        lastUpdatedRecurring = recurring
        lastNextDate = nextDate
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        recurring.nextOccurrence = nextDate
    }
    
    func deactivateRecurring(_ recurring: RecurringTransaction) async throws {
        deactivateRecurringCalled = true
        lastDeactivatedRecurring = recurring
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        recurring.isActive = false
    }
    
    // Helper method to reset state
    func reset() {
        saveCalled = false
        deleteCalled = false
        fetchAllCalled = false
        fetchByIdCalled = false
        fetchActiveRecurringCalled = false
        fetchByAccountCalled = false
        fetchDueTransactionsCalled = false
        updateNextOccurrenceCalled = false
        deactivateRecurringCalled = false
        
        mockRecurringTransactions.removeAll()
        shouldThrowError = false
        saveCallCount = 0
        deleteCallCount = 0
        
        lastSavedRecurring = nil
        lastDeletedRecurring = nil
        lastAccount = nil
        lastDueDate = nil
        lastUpdatedRecurring = nil
        lastNextDate = nil
        lastDeactivatedRecurring = nil
    }
}
