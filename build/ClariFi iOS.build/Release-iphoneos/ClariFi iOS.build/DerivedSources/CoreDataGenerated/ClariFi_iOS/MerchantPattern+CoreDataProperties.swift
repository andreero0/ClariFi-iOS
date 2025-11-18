//
//  MerchantPattern+CoreDataProperties.swift
//  
//
//  Created by aEro on 2025-10-12.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension MerchantPattern {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MerchantPattern> {
        return NSFetchRequest<MerchantPattern>(entityName: "MerchantPattern")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var merchantName: String?
    @NSManaged public var normalizedName: String?
    @NSManaged public var category: String?
    @NSManaged public var confidence: Float
    @NSManaged public var occurrenceCount: Int32
    @NSManaged public var lastUsed: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

}

extension MerchantPattern : Identifiable {

}
