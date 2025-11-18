//
//  CoreDataRepositories.swift
//  ClariFi iOS
//
//  Created by aEro on 2025-10-10.
//

import Foundation
import CoreData

// MARK: - Base Core Data Repository
class BaseCoreDataRepository<T: NSManagedObject>: BaseRepository {
    typealias Entity = T
    
    internal let context: NSManagedObjectContext
    internal let entityName: String
    internal let backgroundContextProvider: BackgroundContextProvider
    
    init(
        context: NSManagedObjectContext,
        entityName: String,
        backgroundContextProvider: BackgroundContextProvider? = nil
    ) {
        self.context = context
        self.entityName = entityName
        
        if let provider = backgroundContextProvider {
            self.backgroundContextProvider = provider
        } else {
            // Fallback to shared persistence container when explicit provider not supplied.
            self.backgroundContextProvider = BackgroundContextProvider(
                persistentContainer: PersistenceController.shared.container
            )
        }
    }
    
    func save(_ entity: T) async throws {
        try await context.perform {
            // Set timestamps if entity has them
            if var timestampedEntity = entity as? TimestampedEntity {
                let now = Date()
                if timestampedEntity.createdAt == nil {
                    timestampedEntity.createdAt = now
                }
                timestampedEntity.updatedAt = now
            }
            
            try self.context.save()
        }
    }
    
    func delete(_ entity: T) async throws {
        try await context.perform {
            self.context.delete(entity)
            try self.context.save()
        }
    }
    
    func fetchAll() async throws -> [T] {
        try await context.perform {
            let request = NSFetchRequest<T>(entityName: self.entityName)
            return try self.context.fetch(request)
        }
    }
    
    func fetchById(_ id: UUID) async throws -> T? {
        try await context.perform {
            let request = NSFetchRequest<T>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            return try self.context.fetch(request).first
        }
    }
}

// MARK: - Transaction Repository Implementation
class CoreDataTransactionRepository: BaseCoreDataRepository<Transaction>, TransactionRepository {
    
    init(context: NSManagedObjectContext, backgroundContextProvider: BackgroundContextProvider? = nil) {
        super.init(
            context: context,
            entityName: "Transaction",
            backgroundContextProvider: backgroundContextProvider
        )
    }
    
    func fetchByDateRange(_ startDate: Date, _ endDate: Date) async throws -> [Transaction] {
        try await context.perform {
            let request = NSFetchRequest<Transaction>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as CVarArg, endDate as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            return try self.context.fetch(request)
        }
    }
    
    func fetchByAccount(_ account: Account) async throws -> [Transaction] {
        try await context.perform {
            let request = NSFetchRequest<Transaction>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "account == %@", account)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            return try self.context.fetch(request)
        }
    }
    
    func fetchByCategory(_ category: String) async throws -> [Transaction] {
        try await context.perform {
            let request = NSFetchRequest<Transaction>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "category == %@", category)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            return try self.context.fetch(request)
        }
    }
    
    func fetchByMerchant(_ merchant: String) async throws -> [Transaction] {
        try await context.perform {
            let request = NSFetchRequest<Transaction>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "merchant CONTAINS[cd] %@", merchant)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            return try self.context.fetch(request)
        }
    }
    
    func fetchLowConfidenceTransactions(threshold: Float = 0.7) async throws -> [Transaction] {
        try await context.perform {
            let request = NSFetchRequest<Transaction>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "confidence < %f", threshold)
            request.sortDescriptors = [NSSortDescriptor(key: "confidence", ascending: true)]
            return try self.context.fetch(request)
        }
    }
    
    func batchUpdate(_ transactions: [Transaction]) async throws {
        try await context.perform {
            let now = Date()
            for transaction in transactions {
                transaction.updatedAt = now
            }
            try self.context.save()
        }
    }
    
    func updateTransaction(
        _ transaction: Transaction,
        date: Date?,
        merchant: String?,
        amount: Decimal?,
        category: String?,
        notes: String?
    ) async throws -> Transaction {
        try await context.perform {
            if let date = date {
                transaction.date = date
            }
            if let merchant = merchant {
                transaction.merchant = merchant
            }
            if let amount = amount {
                transaction.amount = NSDecimalNumber(decimal: amount)
            }
            if let category = category {
                transaction.category = category
            }
            if let notes = notes {
                transaction.notes = notes
            }
            
            transaction.updatedAt = Date()
            try self.context.save()
            
            return transaction
        }
    }
    
    func fetchRecentTransactions(limit: Int = 50) async throws -> [Transaction] {
        try await context.perform {
            let request = NSFetchRequest<Transaction>(entityName: self.entityName)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            request.fetchLimit = limit
            return try self.context.fetch(request)
        }
    }
    
    func searchTransactions(query: String) async throws -> [Transaction] {
        try await context.perform {
            let request = NSFetchRequest<Transaction>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "merchant CONTAINS[cd] %@ OR category CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", 
                                          query, query, query)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            return try self.context.fetch(request)
        }
    }
}

// MARK: - Account Repository Implementation
class CoreDataAccountRepository: BaseCoreDataRepository<Account>, AccountRepository {
    
    init(context: NSManagedObjectContext, backgroundContextProvider: BackgroundContextProvider? = nil) {
        super.init(
            context: context,
            entityName: "Account",
            backgroundContextProvider: backgroundContextProvider
        )
    }
    
    func fetchActiveAccounts() async throws -> [Account] {
        try await context.perform {
            let request = NSFetchRequest<Account>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "isActive == YES")
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            return try self.context.fetch(request)
        }
    }
    
    func fetchByType(_ type: String) async throws -> [Account] {
        try await context.perform {
            let request = NSFetchRequest<Account>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "type == %@", type)
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            return try self.context.fetch(request)
        }
    }
    
    func deactivateAccount(_ account: Account) async throws {
        try await context.perform {
            account.isActive = false
            account.updatedAt = Date()
            try self.context.save()
        }
    }
    
    func getTransactionCount(for account: Account) async throws -> Int {
        try await context.perform {
            let request = NSFetchRequest<Transaction>(entityName: "Transaction")
            request.predicate = NSPredicate(format: "account == %@", account)
            return try self.context.count(for: request)
        }
    }
    
    func getOrCreateDefaultAccount() async throws -> Account {
        try await context.perform {
            // First, try to find an existing default account
            let request = NSFetchRequest<Account>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "isDefault == YES")
            request.fetchLimit = 1
            
            if let existingAccount = try self.context.fetch(request).first {
                return existingAccount
            }
            
            // Create a new default account if none exists
            let newAccount = Account(context: self.context)
            newAccount.id = UUID()
            newAccount.name = "Default Account"
            newAccount.type = "checking"
            newAccount.isActive = true
            newAccount.isDefault = true
            newAccount.createdAt = Date()
            newAccount.updatedAt = Date()
            
            try self.context.save()
            return newAccount
        }
    }
}

// MARK: - Budget Repository Implementation
class CoreDataBudgetRepository: BaseCoreDataRepository<Budget>, BudgetRepository {
    
    init(context: NSManagedObjectContext, backgroundContextProvider: BackgroundContextProvider? = nil) {
        super.init(
            context: context,
            entityName: "Budget",
            backgroundContextProvider: backgroundContextProvider
        )
    }
    
    func fetchActiveBudget() async throws -> Budget? {
        try await context.perform {
            let request = NSFetchRequest<Budget>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "isActive == YES")
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            request.fetchLimit = 1
            return try self.context.fetch(request).first
        }
    }
    
    func fetchByPeriod(_ period: String) async throws -> [Budget] {
        try await context.perform {
            let request = NSFetchRequest<Budget>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "period == %@", period)
            request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
            return try self.context.fetch(request)
        }
    }
    
    func deactivateBudget(_ budget: Budget) async throws {
        try await context.perform {
            budget.isActive = false
            budget.updatedAt = Date()
            try self.context.save()
        }
    }
    
    func fetchBudgetWithCategories(_ budgetId: UUID) async throws -> Budget? {
        try await context.perform {
            let request = NSFetchRequest<Budget>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "id == %@", budgetId as CVarArg)
            request.relationshipKeyPathsForPrefetching = ["categories"]
            request.fetchLimit = 1
            return try self.context.fetch(request).first
        }
    }
}

// MARK: - Budget Category Repository Implementation
class CoreDataBudgetCategoryRepository: BaseCoreDataRepository<BudgetCategory>, BudgetCategoryRepository {
    
    init(context: NSManagedObjectContext, backgroundContextProvider: BackgroundContextProvider? = nil) {
        super.init(
            context: context,
            entityName: "BudgetCategory",
            backgroundContextProvider: backgroundContextProvider
        )
    }
    
    func fetchByBudget(_ budget: Budget) async throws -> [BudgetCategory] {
        try await context.perform {
            let request = NSFetchRequest<BudgetCategory>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "budget == %@", budget)
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            return try self.context.fetch(request)
        }
    }
    
    func fetchByName(_ name: String, in budget: Budget) async throws -> BudgetCategory? {
        try await context.perform {
            let request = NSFetchRequest<BudgetCategory>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "name == %@ AND budget == %@", name, budget)
            request.fetchLimit = 1
            return try self.context.fetch(request).first
        }
    }
    
    func updateSpentAmount(_ category: BudgetCategory, amount: NSDecimalNumber) async throws {
        try await context.perform {
            category.spentAmount = amount
            category.updatedAt = Date()
            try self.context.save()
        }
    }
    
    func fetchOverBudgetCategories(in budget: Budget) async throws -> [BudgetCategory] {
        try await context.perform {
            let request = NSFetchRequest<BudgetCategory>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "budget == %@ AND spentAmount > budgetedAmount", budget)
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            return try self.context.fetch(request)
        }
    }
}

// MARK: - Statement Repository Implementation
class CoreDataStatementRepository: BaseCoreDataRepository<Statement>, StatementRepository {
    
    init(context: NSManagedObjectContext, backgroundContextProvider: BackgroundContextProvider? = nil) {
        super.init(
            context: context,
            entityName: "Statement",
            backgroundContextProvider: backgroundContextProvider
        )
    }
    
    func fetchByHash(_ hash: String) async throws -> Statement? {
        try await context.perform {
            let request = NSFetchRequest<Statement>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "fileHash == %@", hash)
            request.fetchLimit = 1
            return try self.context.fetch(request).first
        }
    }
    
    func fetchByProcessingStatus(_ status: String) async throws -> [Statement] {
        try await context.perform {
            let request = NSFetchRequest<Statement>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "processingStatus == %@", status)
            request.sortDescriptors = [NSSortDescriptor(key: "uploadDate", ascending: false)]
            return try self.context.fetch(request)
        }
    }
    
    func fetchRecentStatements(limit: Int = 20) async throws -> [Statement] {
        try await context.perform {
            let request = NSFetchRequest<Statement>(entityName: self.entityName)
            request.sortDescriptors = [NSSortDescriptor(key: "uploadDate", ascending: false)]
            request.fetchLimit = limit
            return try self.context.fetch(request)
        }
    }
    
    func updateProcessingStatus(_ statement: Statement, status: String) async throws {
        try await context.perform {
            statement.processingStatus = status
            statement.updatedAt = Date()
            try self.context.save()
        }
    }
    
    func fetchStatementWithTransactions(_ statementId: UUID) async throws -> Statement? {
        try await context.perform {
            let request = NSFetchRequest<Statement>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "id == %@", statementId as CVarArg)
            request.relationshipKeyPathsForPrefetching = ["transactions"]
            request.fetchLimit = 1
            return try self.context.fetch(request).first
        }
    }
}

// MARK: - Recurring Transaction Repository Implementation
class CoreDataRecurringTransactionRepository: BaseCoreDataRepository<RecurringTransaction>, RecurringTransactionRepository {
    
    init(context: NSManagedObjectContext, backgroundContextProvider: BackgroundContextProvider? = nil) {
        super.init(
            context: context,
            entityName: "RecurringTransaction",
            backgroundContextProvider: backgroundContextProvider
        )
    }
    
    func fetchActiveRecurring() async throws -> [RecurringTransaction] {
        try await context.perform {
            let request = NSFetchRequest<RecurringTransaction>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "isActive == YES")
            request.sortDescriptors = [NSSortDescriptor(key: "nextOccurrence", ascending: true)]
            return try self.context.fetch(request)
        }
    }
    
    func fetchByAccount(_ account: Account) async throws -> [RecurringTransaction] {
        try await context.perform {
            let request = NSFetchRequest<RecurringTransaction>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "account == %@ AND isActive == YES", account)
            request.sortDescriptors = [NSSortDescriptor(key: "nextOccurrence", ascending: true)]
            return try self.context.fetch(request)
        }
    }
    
    func fetchDueTransactions(upToDate: Date) async throws -> [RecurringTransaction] {
        try await context.perform {
            let request = NSFetchRequest<RecurringTransaction>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "isActive == YES AND nextOccurrence <= %@", upToDate as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "nextOccurrence", ascending: true)]
            return try self.context.fetch(request)
        }
    }
    
    func updateNextOccurrence(_ recurring: RecurringTransaction, nextDate: Date) async throws {
        try await context.perform {
            recurring.nextOccurrence = nextDate
            recurring.updatedAt = Date()
            try self.context.save()
        }
    }
    
    func deactivateRecurring(_ recurring: RecurringTransaction) async throws {
        try await context.perform {
            recurring.isActive = false
            recurring.updatedAt = Date()
            try self.context.save()
        }
    }
}

// MARK: - Timestamped Entity Protocol
protocol TimestampedEntity {
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }
}

// Extend Core Data entities to conform to TimestampedEntity
extension Transaction: TimestampedEntity {}
extension Account: TimestampedEntity {}
extension Budget: TimestampedEntity {}
extension BudgetCategory: TimestampedEntity {}
extension Statement: TimestampedEntity {}
extension RecurringTransaction: TimestampedEntity {}
