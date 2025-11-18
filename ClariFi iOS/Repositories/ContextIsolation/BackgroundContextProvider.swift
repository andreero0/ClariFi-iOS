//
//  BackgroundContextProvider.swift
//  ClariFi iOS
//
//  Created by AI Assistant on 2025-10-10.
//
//  Thread-safe background context provider for Core Data operations
//

import Foundation
import CoreData

/// Thread-safe provider for background Core Data contexts
class BackgroundContextProvider {
    
    // MARK: - Properties
    
    private let persistentContainer: NSPersistentContainer
    private let contextPool: NSMutableArray
    private let poolLock = NSLock()
    private let maxPoolSize = 5
    
    // MARK: - Initialization
    
    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
        self.contextPool = NSMutableArray()
    }
    
    // MARK: - Public Methods
    
    /// Execute a block on a background context with automatic cleanup
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = getBackgroundContext()
        defer { returnContextToPool(context) }
        
        return try await context.perform {
            try block(context)
        }
    }
    
    /// Execute a block on a background context that returns value types
    func performBackgroundTaskWithDTOs<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = getBackgroundContext()
        defer { returnContextToPool(context) }
        
        return try await context.perform {
            try block(context)
        }
    }
    
    /// Create a new background context for long-running operations
    func createBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil // Disable undo for performance
        return context
    }
    
    // MARK: - Private Methods
    
    private func getBackgroundContext() -> NSManagedObjectContext {
        poolLock.lock()
        defer { poolLock.unlock() }
        
        // Try to get a context from the pool
        if contextPool.count > 0 {
            return contextPool.removeLastObject() as! NSManagedObjectContext
        }
        
        // Create a new context if pool is empty
        return createBackgroundContext()
    }
    
    private func returnContextToPool(_ context: NSManagedObjectContext) {
        poolLock.lock()
        defer { poolLock.unlock() }
        
        // Reset context state
        context.reset()
        
        // Return to pool if not full
        if contextPool.count < maxPoolSize {
            contextPool.add(context)
        }
        // Otherwise, let it be deallocated
    }
}

// MARK: - Value Type DTOs

/// Lightweight DTO for Transaction data
struct TransactionDTO {
    let id: UUID
    let date: Date
    let amount: Decimal
    let merchant: String
    let category: String
    let notes: String?
    let confidence: Float
    let accountId: UUID
    let statementId: UUID?
    
    init(from transaction: Transaction) {
        self.id = transaction.id ?? UUID()
        self.date = transaction.date ?? Date()
        self.amount = (transaction.amount as NSDecimalNumber? ?? 0).decimalValue
        self.merchant = transaction.merchant ?? ""
        self.category = transaction.category ?? ""
        self.notes = transaction.notes
        self.confidence = transaction.confidence
        self.accountId = transaction.account?.id ?? UUID()
        self.statementId = transaction.statement?.id
    }
}

/// Lightweight DTO for Account data
struct AccountDTO {
    let id: UUID
    let name: String
    let type: String
    let isActive: Bool
    let createdAt: Date
    
    init(from account: Account) {
        self.id = account.id ?? UUID()
        self.name = account.name ?? ""
        self.type = account.type ?? ""
        self.isActive = account.isActive
        self.createdAt = account.createdAt ?? Date()
    }
}

/// Lightweight DTO for Budget data
struct BudgetDTO {
    let id: UUID
    let name: String
    let period: String
    let totalAmount: Decimal
    let isActive: Bool
    let createdAt: Date
    
    init(from budget: Budget) {
        self.id = budget.id ?? UUID()
        self.name = budget.name ?? ""
        self.period = budget.period ?? ""
        // Compute total from categories
        self.totalAmount = (budget.categories?.allObjects as? [BudgetCategory])?
            .reduce(0) { $0 + ($1.budgetedAmount as NSDecimalNumber? ?? 0).decimalValue } ?? 0
        self.isActive = budget.isActive
        self.createdAt = budget.createdAt ?? Date()
    }
}

/// Lightweight DTO for BudgetCategory data
struct BudgetCategoryDTO {
    let id: UUID
    let name: String
    let amount: Decimal
    let spent: Decimal
    let budgetId: UUID
    
    init(from budgetCategory: BudgetCategory) {
        self.id = budgetCategory.id ?? UUID()
        self.name = budgetCategory.name ?? ""
        self.amount = (budgetCategory.budgetedAmount as NSDecimalNumber? ?? 0).decimalValue
        self.spent = (budgetCategory.spentAmount as NSDecimalNumber? ?? 0).decimalValue
        self.budgetId = budgetCategory.budget?.id ?? UUID()
    }
}

// MARK: - Core Data Extensions

extension NSManagedObjectContext {
    
    /// Safely fetch entities and convert to DTOs
    func fetchDTOs<T: NSManagedObject, DTO>(
        _ request: NSFetchRequest<T>,
        converter: @escaping (T) -> DTO
    ) throws -> [DTO] {
        let entities = try fetch(request)
        return entities.map(converter)
    }
    
    /// Safely save context with error handling
    func safeSave() throws {
        guard hasChanges else { return }
        
        do {
            try save()
        } catch {
            print("Core Data save failed: \(error)")
            rollback()
            throw error
        }
    }
}
