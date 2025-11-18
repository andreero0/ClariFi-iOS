//
//  RepositoryProtocols.swift
//  ClariFi iOS
//
//  Created by aEro on 2025-10-10.
//

import Foundation
import CoreData

// MARK: - Base Repository Protocol
protocol BaseRepository {
    associatedtype Entity: NSManagedObject
    
    func save(_ entity: Entity) async throws
    func delete(_ entity: Entity) async throws
    func fetchAll() async throws -> [Entity]
    func fetchById(_ id: UUID) async throws -> Entity?
}

// MARK: - Transaction Repository Protocol
protocol TransactionRepository: BaseRepository where Entity == Transaction {
    func fetchByDateRange(_ startDate: Date, _ endDate: Date) async throws -> [Transaction]
    func fetchByAccount(_ account: Account) async throws -> [Transaction]
    func fetchByCategory(_ category: String) async throws -> [Transaction]
    func fetchByMerchant(_ merchant: String) async throws -> [Transaction]
    func fetchLowConfidenceTransactions(threshold: Float) async throws -> [Transaction]
    func batchUpdate(_ transactions: [Transaction]) async throws
    func updateTransaction(
        _ transaction: Transaction,
        date: Date?,
        merchant: String?,
        amount: Decimal?,
        category: String?,
        notes: String?
    ) async throws -> Transaction
    func fetchRecentTransactions(limit: Int) async throws -> [Transaction]
    func searchTransactions(query: String) async throws -> [Transaction]
}

// MARK: - Account Repository Protocol
protocol AccountRepository: BaseRepository where Entity == Account {
    func fetchActiveAccounts() async throws -> [Account]
    func fetchByType(_ type: String) async throws -> [Account]
    func deactivateAccount(_ account: Account) async throws
    func getTransactionCount(for account: Account) async throws -> Int
    func getOrCreateDefaultAccount() async throws -> Account
}

// MARK: - Budget Repository Protocol
protocol BudgetRepository: BaseRepository where Entity == Budget {
    func fetchActiveBudget() async throws -> Budget?
    func fetchByPeriod(_ period: String) async throws -> [Budget]
    func deactivateBudget(_ budget: Budget) async throws
    func fetchBudgetWithCategories(_ budgetId: UUID) async throws -> Budget?
}

// MARK: - Budget Category Repository Protocol
protocol BudgetCategoryRepository: BaseRepository where Entity == BudgetCategory {
    func fetchByBudget(_ budget: Budget) async throws -> [BudgetCategory]
    func fetchByName(_ name: String, in budget: Budget) async throws -> BudgetCategory?
    func updateSpentAmount(_ category: BudgetCategory, amount: NSDecimalNumber) async throws
    func fetchOverBudgetCategories(in budget: Budget) async throws -> [BudgetCategory]
}

// MARK: - Statement Repository Protocol
protocol StatementRepository: BaseRepository where Entity == Statement {
    func fetchByHash(_ hash: String) async throws -> Statement?
    func fetchByProcessingStatus(_ status: String) async throws -> [Statement]
    func fetchRecentStatements(limit: Int) async throws -> [Statement]
    func updateProcessingStatus(_ statement: Statement, status: String) async throws
    func fetchStatementWithTransactions(_ statementId: UUID) async throws -> Statement?
}

// MARK: - Recurring Transaction Repository Protocol
protocol RecurringTransactionRepository: BaseRepository where Entity == RecurringTransaction {
    func fetchActiveRecurring() async throws -> [RecurringTransaction]
    func fetchByAccount(_ account: Account) async throws -> [RecurringTransaction]
    func fetchDueTransactions(upToDate: Date) async throws -> [RecurringTransaction]
    func updateNextOccurrence(_ recurring: RecurringTransaction, nextDate: Date) async throws
    func deactivateRecurring(_ recurring: RecurringTransaction) async throws
}

// MARK: - Repository Error Types
enum RepositoryError: LocalizedError {
    case entityNotFound(String)
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case validationFailed(String)
    case duplicateEntity(String)
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .entityNotFound(let entity):
            return "Entity not found: \(entity)"
        case .saveFailed(let error):
            return "Save failed: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Fetch failed: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Delete failed: \(error.localizedDescription)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .duplicateEntity(let entity):
            return "Duplicate entity: \(entity)"
        case .notImplemented:
            return "This functionality is not yet implemented"
        }
    }
}