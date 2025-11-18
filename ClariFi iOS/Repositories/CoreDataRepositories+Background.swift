//
//  CoreDataRepositories+Background.swift
//  ClariFi iOS
//
//  Created by AI Assistant on 2025-10-10.
//
//  Background context extensions for Core Data repositories
//

import Foundation
import CoreData

// MARK: - Background Transaction Repository

extension CoreDataTransactionRepository {
    
    /// Fetch transactions using background context and return DTOs
    func fetchAllDTOs() async throws -> [TransactionDTO] {
        return try await backgroundContextProvider.performBackgroundTaskWithDTOs { context in
            let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            return try context.fetchDTOs(request) { TransactionDTO(from: $0) }
        }
    }
    
    /// Fetch transactions by date range using background context
    func fetchByDateRangeDTOs(_ startDate: Date, _ endDate: Date) async throws -> [TransactionDTO] {
        return try await backgroundContextProvider.performBackgroundTaskWithDTOs { context in
            let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            return try context.fetchDTOs(request) { TransactionDTO(from: $0) }
        }
    }
    
    /// Fetch transactions by category using background context
    func fetchByCategoryDTOs(_ category: String) async throws -> [TransactionDTO] {
        return try await backgroundContextProvider.performBackgroundTaskWithDTOs { context in
            let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            request.predicate = NSPredicate(format: "category == %@", category)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            return try context.fetchDTOs(request) { TransactionDTO(from: $0) }
        }
    }
    
    /// Fetch low confidence transactions using background context
    func fetchLowConfidenceTransactionsDTOs(threshold: Float) async throws -> [TransactionDTO] {
        return try await backgroundContextProvider.performBackgroundTaskWithDTOs { context in
            let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            request.predicate = NSPredicate(format: "confidence < %f", threshold)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            return try context.fetchDTOs(request) { TransactionDTO(from: $0) }
        }
    }
    
    /// Search transactions using background context
    func searchTransactionsDTOs(query: String) async throws -> [TransactionDTO] {
        return try await backgroundContextProvider.performBackgroundTaskWithDTOs { context in
            let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            request.predicate = NSPredicate(format: "merchant CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", query, query)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            return try context.fetchDTOs(request) { TransactionDTO(from: $0) }
        }
    }
    
    /// Batch update transactions using background context
    func batchUpdateDTOs(_ transactionDTOs: [TransactionDTO]) async throws {
        try await backgroundContextProvider.performBackgroundTask { context in
            for dto in transactionDTOs {
                let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
                
                if let transaction = try context.fetch(request).first {
                    transaction.date = dto.date
                    transaction.amount = NSDecimalNumber(decimal: dto.amount)
                    transaction.merchant = dto.merchant
                    transaction.category = dto.category
                    transaction.notes = dto.notes
                    transaction.confidence = dto.confidence
                }
            }
            
            try context.safeSave()
        }
    }
}

// MARK: - Background Account Repository

extension CoreDataAccountRepository {
    
    /// Fetch active accounts using background context
    func fetchActiveAccountsDTOs() async throws -> [AccountDTO] {
        return try await backgroundContextProvider.performBackgroundTaskWithDTOs { context in
            let request: NSFetchRequest<Account> = Account.fetchRequest()
            request.predicate = NSPredicate(format: "isActive == YES")
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            return try context.fetchDTOs(request) { AccountDTO(from: $0) }
        }
    }
    
    /// Fetch accounts by type using background context
    func fetchByTypeDTOs(_ type: String) async throws -> [AccountDTO] {
        return try await backgroundContextProvider.performBackgroundTaskWithDTOs { context in
            let request: NSFetchRequest<Account> = Account.fetchRequest()
            request.predicate = NSPredicate(format: "type == %@", type)
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            return try context.fetchDTOs(request) { AccountDTO(from: $0) }
        }
    }
    
    /// Get transaction count for account using background context
    func getTransactionCountDTO(for accountId: UUID) async throws -> Int {
        return try await backgroundContextProvider.performBackgroundTask { context in
            let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            request.predicate = NSPredicate(format: "account.id == %@", accountId as CVarArg)
            
            return try context.count(for: request)
        }
    }
}

// MARK: - Background Budget Repository

extension CoreDataBudgetRepository {
    
    /// Fetch active budget using background context
    func fetchActiveBudgetDTO() async throws -> BudgetDTO? {
        return try await backgroundContextProvider.performBackgroundTaskWithDTOs { context in
            let request: NSFetchRequest<Budget> = Budget.fetchRequest()
            request.predicate = NSPredicate(format: "isActive == YES")
            request.fetchLimit = 1
            
            let budgets = try context.fetch(request)
            return budgets.first.map { BudgetDTO(from: $0) }
        }
    }
    
    /// Fetch budgets by period using background context
    func fetchByPeriodDTOs(_ period: String) async throws -> [BudgetDTO] {
        return try await backgroundContextProvider.performBackgroundTaskWithDTOs { context in
            let request: NSFetchRequest<Budget> = Budget.fetchRequest()
            request.predicate = NSPredicate(format: "period == %@", period)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            return try context.fetchDTOs(request) { BudgetDTO(from: $0) }
        }
    }
}

// MARK: - Background Budget Category Repository

extension CoreDataBudgetCategoryRepository {
    
    /// Fetch budget categories using background context
    func fetchByBudgetDTOs(_ budgetId: UUID) async throws -> [BudgetCategoryDTO] {
        return try await backgroundContextProvider.performBackgroundTaskWithDTOs { context in
            let request: NSFetchRequest<BudgetCategory> = BudgetCategory.fetchRequest()
            request.predicate = NSPredicate(format: "budget.id == %@", budgetId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            return try context.fetchDTOs(request) { BudgetCategoryDTO(from: $0) }
        }
    }
}

// MARK: - Repository Protocol Extensions

extension TransactionRepository {
    
    /// Default implementation using DTOs
    func fetchAllDTOs() async throws -> [TransactionDTO] {
        let transactions = try await fetchAll()
        return transactions.map { TransactionDTO(from: $0) }
    }
    
    func fetchByDateRangeDTOs(_ startDate: Date, _ endDate: Date) async throws -> [TransactionDTO] {
        let transactions = try await fetchByDateRange(startDate, endDate)
        return transactions.map { TransactionDTO(from: $0) }
    }
    
    func fetchByCategoryDTOs(_ category: String) async throws -> [TransactionDTO] {
        let transactions = try await fetchByCategory(category)
        return transactions.map { TransactionDTO(from: $0) }
    }
    
    func fetchLowConfidenceTransactionsDTOs(threshold: Float) async throws -> [TransactionDTO] {
        let transactions = try await fetchLowConfidenceTransactions(threshold: threshold)
        return transactions.map { TransactionDTO(from: $0) }
    }
    
    func searchTransactionsDTOs(query: String) async throws -> [TransactionDTO] {
        let transactions = try await searchTransactions(query: query)
        return transactions.map { TransactionDTO(from: $0) }
    }
}

extension AccountRepository {
    
    func fetchActiveAccountsDTOs() async throws -> [AccountDTO] {
        let accounts = try await fetchActiveAccounts()
        return accounts.map { AccountDTO(from: $0) }
    }
    
    func fetchByTypeDTOs(_ type: String) async throws -> [AccountDTO] {
        let accounts = try await fetchByType(type)
        return accounts.map { AccountDTO(from: $0) }
    }
}

extension BudgetRepository {
    
    func fetchActiveBudgetDTO() async throws -> BudgetDTO? {
        guard let budget = try await fetchActiveBudget() else { return nil }
        return BudgetDTO(from: budget)
    }
    
    func fetchByPeriodDTOs(_ period: String) async throws -> [BudgetDTO] {
        let budgets = try await fetchByPeriod(period)
        return budgets.map { BudgetDTO(from: $0) }
    }
}

extension BudgetCategoryRepository {
    
    func fetchByBudgetDTOs(_ budgetId: UUID) async throws -> [BudgetCategoryDTO] {
        // This would need the budget entity to be passed, but for DTOs we use the ID
        // The concrete implementation should handle this
        throw RepositoryError.notImplemented
    }
}
