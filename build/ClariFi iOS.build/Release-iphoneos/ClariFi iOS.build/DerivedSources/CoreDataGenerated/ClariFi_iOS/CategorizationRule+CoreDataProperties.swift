//
//  CategorizationRule+CoreDataProperties.swift
//  
//
//  Created by aEro on 2025-10-12.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension CategorizationRule {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategorizationRule> {
        return NSFetchRequest<CategorizationRule>(entityName: "CategorizationRule")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var merchantPattern: String?
    @NSManaged public var category: String?
    @NSManaged public var priority: Int16
    @NSManaged public var isActive: Bool
    @NSManaged public var matchType: String?
    @NSManaged public var minAmount: NSDecimalNumber?
    @NSManaged public var maxAmount: NSDecimalNumber?
    @NSManaged public var isUserCreated: Bool
    @NSManaged public var applicationCount: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

}

extension CategorizationRule : Identifiable {

}
