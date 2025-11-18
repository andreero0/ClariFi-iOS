//
//  Account+CoreDataProperties.swift
//  
//
//  Created by aEro on 2025-10-12.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Account {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Account> {
        return NSFetchRequest<Account>(entityName: "Account")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var type: String?
    @NSManaged public var lastFourDigits: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var isDefault: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var transactions: NSSet?
    @NSManaged public var recurringTransactions: NSSet?

}

// MARK: Generated accessors for transactions
extension Account {

    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: Transaction)

    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: Transaction)

    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)

    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)

}

// MARK: Generated accessors for recurringTransactions
extension Account {

    @objc(addRecurringTransactionsObject:)
    @NSManaged public func addToRecurringTransactions(_ value: RecurringTransaction)

    @objc(removeRecurringTransactionsObject:)
    @NSManaged public func removeFromRecurringTransactions(_ value: RecurringTransaction)

    @objc(addRecurringTransactions:)
    @NSManaged public func addToRecurringTransactions(_ values: NSSet)

    @objc(removeRecurringTransactions:)
    @NSManaged public func removeFromRecurringTransactions(_ values: NSSet)

}

extension Account : Identifiable {

}
