//
//  Budget+Extensions.swift
//  ClariFi_iOS
//
//  Extensions for Budget and BudgetCategory Core Data entities
//

import Foundation
import CoreData

extension Budget {
    
    /// Returns the template ID if this budget was created from a template
    var sourceTemplateId: String? {
        return templateId
    }
    
    /// Sets the template ID to track which template was used
    func setSourceTemplate(_ templateId: String) {
        self.templateId = templateId
    }
}

extension BudgetCategory {
    
    /// Returns the canonical category name (stored in the name field)
    var canonicalName: String {
        return name ?? "other"
    }
    
    /// Returns the display-friendly category name
    var categoryDisplayName: String {
        // If displayName is set, use it
        if let display = displayName, !display.isEmpty {
            return display
        }
        
        // Otherwise, look up from CategoryDefinition
        guard let categoryName = name else { return "Other" }
        
        return CategoryDefinition.allCategories
            .first { $0.canonicalName == categoryName }?
            .displayName ?? categoryName.capitalized
    }
    
    /// Sets both canonical and display names
    func setCategory(canonical: String, display: String) {
        self.name = canonical
        self.displayName = display
    }
    
    /// Remaining amount in budget
    var remainingAmount: Decimal {
        let budgeted = budgetedAmount as Decimal? ?? 0
        let spent = spentAmount as Decimal? ?? 0
        return budgeted - spent
    }
    
    /// Percentage of budget spent
    var percentageSpent: Double {
        let budgeted = budgetedAmount as Decimal? ?? 0
        let spent = spentAmount as Decimal? ?? 0
        
        guard budgeted > 0 else { return 0 }
        
        let percentage = (spent / budgeted) as NSDecimalNumber
        return percentage.doubleValue
    }
    
    /// Whether the alert threshold has been exceeded
    var isOverThreshold: Bool {
        return percentageSpent >= Double(alertThreshold)
    }
}
