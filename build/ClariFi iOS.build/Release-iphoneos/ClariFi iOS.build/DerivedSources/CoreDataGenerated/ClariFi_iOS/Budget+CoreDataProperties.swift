//
//  Budget+CoreDataProperties.swift
//  
//
//  Created by aEro on 2025-10-12.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Budget {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Budget> {
        return NSFetchRequest<Budget>(entityName: "Budget")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var period: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var rolloverEnabled: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var categories: NSSet?

}

// MARK: Generated accessors for categories
extension Budget {

    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: BudgetCategory)

    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: BudgetCategory)

    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: NSSet)

    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: NSSet)

}

extension Budget : Identifiable {

}
