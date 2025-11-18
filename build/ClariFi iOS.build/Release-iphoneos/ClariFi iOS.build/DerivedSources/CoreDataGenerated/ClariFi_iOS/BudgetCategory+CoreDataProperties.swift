//
//  BudgetCategory+CoreDataProperties.swift
//  
//
//  Created by aEro on 2025-10-12.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension BudgetCategory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BudgetCategory> {
        return NSFetchRequest<BudgetCategory>(entityName: "BudgetCategory")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var budgetedAmount: NSDecimalNumber?
    @NSManaged public var spentAmount: NSDecimalNumber?
    @NSManaged public var rolloverEnabled: Bool
    @NSManaged public var alertThreshold: Float
    @NSManaged public var color: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var budget: Budget?

}

extension BudgetCategory : Identifiable {

}
