//
//  Transaction+CoreDataProperties.swift
//  
//
//  Created by aEro on 2025-10-12.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Transaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Transaction> {
        return NSFetchRequest<Transaction>(entityName: "Transaction")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var merchant: String?
    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var currency: String?
    @NSManaged public var category: String?
    @NSManaged public var confidence: Float
    @NSManaged public var isManual: Bool
    @NSManaged public var notes: String?
    @NSManaged public var tags: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var account: Account?
    @NSManaged public var statement: Statement?

}

extension Transaction : Identifiable {

}
