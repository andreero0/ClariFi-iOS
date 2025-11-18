//
//  RecurringTransactionService.swift
//  ClariFi iOS
//
//  Created by Kiro on 2025-10-10.
//

import Foundation
import CoreData

enum RecurringFrequency: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
    
    var displayName: String {
        return self.rawValue
    }
    
    func nextOccurrence(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
}

protocol RecurringTransactionService {
    func createRecurringTransaction(
        merchant: String,
        amount: Decimal,
        category: String,
        account: Account,
        frequency: RecurringFrequency,
        startDate: Date,
        endDate: Date?,
        notes: String?
    ) async throws -> RecurringTransaction
    
    func processRecurringTransactions(upToDate: Date) async throws -> [Transaction]
    func updateRecurringTransaction(_ recurring: RecurringTransaction) async throws
    func deleteRecurringTransaction(_ recurring: RecurringTransaction) async throws
    func fetchActiveRecurringTransactions() async throws -> [RecurringTransaction]
}

class CoreDataRecurringTransactionService: RecurringTransactionService {
    private let recurringRepository: any RecurringTransactionRepository
    private let transactionRepository: any TransactionRepository
    private let context: NSManagedObjectContext
    
    init(
        recurringRepository: any RecurringTransactionRepository,
        transactionRepository: any TransactionRepository,
        context: NSManagedObjectContext
    ) {
        self.recurringRepository = recurringRepository
        self.transactionRepository = transactionRepository
        self.context = context
    }
    
    func createRecurringTransaction(
        merchant: String,
        amount: Decimal,
        category: String,
        account: Account,
        frequency: RecurringFrequency,
        startDate: Date,
        endDate: Date?,
        notes: String?
    ) async throws -> RecurringTransaction {
        let recurring = RecurringTransaction(context: context)
        recurring.id = UUID()
        recurring.merchant = merchant
        recurring.amount = NSDecimalNumber(decimal: amount)
        recurring.currency = "USD"
        recurring.category = category
        recurring.notes = notes
        recurring.frequency = frequency.rawValue
        recurring.startDate = startDate
        recurring.endDate = endDate
        recurring.nextOccurrence = startDate
        recurring.isActive = true
        recurring.account = account
        recurring.createdAt = Date()
        recurring.updatedAt = Date()
        
        try await recurringRepository.save(recurring)
        return recurring
    }
    
    func processRecurringTransactions(upToDate: Date = Date()) async throws -> [Transaction] {
        let dueRecurring = try await recurringRepository.fetchDueTransactions(upToDate: upToDate)
        var createdTransactions: [Transaction] = []
        
        for recurring in dueRecurring {
            // Check if end date has passed
            if let endDate = recurring.endDate, recurring.nextOccurrence ?? Date() > endDate {
                try await recurringRepository.deactivateRecurring(recurring)
                continue
            }
            
            // Create transaction
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.date = recurring.nextOccurrence ?? Date()
            transaction.merchant = recurring.merchant
            transaction.amount = recurring.amount ?? NSDecimalNumber(value: 0)
            transaction.currency = recurring.currency ?? "USD"
            transaction.category = recurring.category
            transaction.confidence = 1.0
            transaction.isManual = true
            transaction.notes = recurring.notes
            transaction.account = recurring.account
            transaction.statement = nil
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
            
            try await transactionRepository.save(transaction)
            createdTransactions.append(transaction)
            
            // Update next occurrence
            guard let frequency = RecurringFrequency(rawValue: recurring.frequency ?? "") else {
                continue
            }
            
            let nextDate = frequency.nextOccurrence(from: recurring.nextOccurrence ?? Date())
            try await recurringRepository.updateNextOccurrence(recurring, nextDate: nextDate)
        }
        
        return createdTransactions
    }
    
    func updateRecurringTransaction(_ recurring: RecurringTransaction) async throws {
        recurring.updatedAt = Date()
        try await recurringRepository.save(recurring)
    }
    
    func deleteRecurringTransaction(_ recurring: RecurringTransaction) async throws {
        try await recurringRepository.delete(recurring)
    }
    
    func fetchActiveRecurringTransactions() async throws -> [RecurringTransaction] {
        return try await recurringRepository.fetchActiveRecurring()
    }
}
