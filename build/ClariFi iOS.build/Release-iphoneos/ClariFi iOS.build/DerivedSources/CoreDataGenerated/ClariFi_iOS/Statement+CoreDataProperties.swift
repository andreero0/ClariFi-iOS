//
//  Statement+CoreDataProperties.swift
//  
//
//  Created by aEro on 2025-10-12.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Statement {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Statement> {
        return NSFetchRequest<Statement>(entityName: "Statement")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var fileName: String?
    @NSManaged public var uploadDate: Date?
    @NSManaged public var fileHash: String?
    @NSManaged public var processingStatus: String?
    @NSManaged public var fileSize: Int64
    @NSManaged public var documentType: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var transactions: NSSet?

}

// MARK: Generated accessors for transactions
extension Statement {

    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: Transaction)

    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: Transaction)

    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)

    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)

}

extension Statement : Identifiable {

}
