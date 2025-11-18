//
//  Transaction+Extensions.swift
//  ClariFi_iOS
//
//  Extensions for Transaction Core Data entity
//

import Foundation
import CoreData

extension Transaction {
    
    /// Returns the canonical category name (stored in the category field)
    var canonicalCategory: String {
        return category ?? "other"
    }
    
    /// Returns the display-friendly category name
    var displayCategory: String {
        guard let categoryName = category else { return "Other" }
        
        // Use CategoryMappingService to get display name
        // For now, return a basic mapping
        return CategoryDefinition.allCategories
            .first { $0.canonicalName == categoryName }?
            .displayName ?? categoryName.capitalized
    }
    
    /// Returns the categorization method used
    var categorizationMethodEnum: CategorizationMethod {
        guard let methodString = categorizationMethod else {
            return .manual
        }
        return CategorizationMethod(rawValue: methodString) ?? .manual
    }
    
    /// Sets the categorization method
    func setCategorizationMethod(_ method: CategorizationMethod) {
        self.categorizationMethod = method.rawValue
    }
}

/// Enum representing how a transaction was categorized
enum CategorizationMethod: String, Codable {
    case manual = "manual"
    case llm = "llm"
    case learned = "learned"
    case pattern = "pattern"
    case rule = "rule"
}
