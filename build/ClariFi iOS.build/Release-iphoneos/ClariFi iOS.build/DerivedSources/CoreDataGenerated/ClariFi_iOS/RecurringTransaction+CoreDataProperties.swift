//
//  RecurringTransaction+CoreDataProperties.swift
//  
//
//  Created by aEro on 2025-10-12.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension RecurringTransaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecurringTransaction> {
        return NSFetchRequest<RecurringTransaction>(entityName: "RecurringTransaction")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var merchant: String?
    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var currency: String?
    @NSManaged public var category: String?
    @NSManaged public var notes: String?
    @NSManaged public var frequency: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var nextOccurrence: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var account: Account?

}

extension RecurringTransaction : Identifiable {

}
