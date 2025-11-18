//
//  CategoryMigration.swift
//  ClariFi iOS
//
//  Created by Kiro on 2025-10-13.
//

import Foundation
import CoreData

/// Handles migration of legacy category names to canonical category names
class CategoryMigration {
    
    // MARK: - Migration Version Tracking
    
    private static let migrationVersionKey = "CategoryMigrationVersion"
    private static let currentMigrationVersion = 1
    
    /// Check if migration is needed
    static func isMigrationNeeded() -> Bool {
        let currentVersion = UserDefaults.standard.integer(forKey: migrationVersionKey)
        return currentVersion < currentMigrationVersion
    }
    
    /// Mark migration as complete
    private static func markMigrationComplete() {
        UserDefaults.standard.set(currentMigrationVersion, forKey: migrationVersionKey)
    }
    
    // MARK: - Legacy Category Mappings
    
    /// Maps legacy category names to canonical names
    private static let legacyCategoryMappings: [String: String] = [
        // Housing variations
        "Housing": "housing",
        "Housing & Rent": "housing",
        "Housing (BAH)": "housing",
        "Housing & Home Office": "housing",
        "Rent/Mortgage": "housing",
        "Rent": "housing",
        "Mortgage": "housing",
        
        // Food variations
        "Food & Groceries": "food_groceries",
        "Groceries": "food_groceries",
        "Food": "food_groceries",
        "Food & Dining": "food_groceries",
        
        // Dining variations
        "Dining & Restaurants": "dining",
        "Dining Out": "dining",
        "Restaurants": "dining",
        "Eating Out": "dining",
        
        // Transportation variations
        "Transportation": "transportation",
        "Car Payment": "transportation",
        "Gas & Fuel": "transportation",
        "Public Transit": "transportation",
        "Vehicle Expenses": "transportation",
        "Gas": "transportation",
        "Fuel": "transportation",
        
        // Utilities variations
        "Utilities": "utilities",
        "Electric": "utilities",
        "Water": "utilities",
        "Natural Gas": "utilities",
        "Internet": "utilities",
        "Phone": "utilities",
        
        // Healthcare variations
        "Healthcare": "healthcare",
        "Medical": "healthcare",
        "Health Insurance": "healthcare",
        "Prescriptions": "healthcare",
        "Doctor Visits": "healthcare",
        
        // Insurance variations
        "Insurance": "insurance",
        "Life Insurance": "insurance",
        "Auto Insurance": "insurance",
        "Home Insurance": "insurance",
        
        // Education variations
        "Education": "education",
        "Tuition": "education",
        "Student Loans": "education",
        "Books": "education",
        "School Supplies": "education",
        
        // Entertainment variations
        "Entertainment": "entertainment",
        "Movies": "entertainment",
        "Concerts": "entertainment",
        "Hobbies": "entertainment",
        "Recreation": "entertainment",
        
        // Shopping variations
        "Shopping": "shopping",
        "Clothing": "shopping",
        "Personal Care": "shopping",
        "Household Items": "shopping",
        
        // Subscriptions variations
        "Subscriptions": "subscriptions",
        "Streaming Services": "subscriptions",
        "Memberships": "subscriptions",
        "Software": "subscriptions",
        
        // Savings variations
        "Savings": "savings",
        "Emergency Fund": "savings",
        "Retirement": "savings",
        "Investments": "savings",
        
        // Debt variations
        "Debt Payment": "debt_payment",
        "Credit Card Payment": "debt_payment",
        "Loan Payment": "debt_payment",
        
        // Childcare variations
        "Childcare": "childcare",
        "Daycare": "childcare",
        "Babysitting": "childcare",
        "Child Support": "childcare",
        
        // Pet care variations
        "Pet Care": "pet_care",
        "Veterinary": "pet_care",
        "Pet Food": "pet_care",
        "Pet Supplies": "pet_care",
        
        // Gifts variations
        "Gifts": "gifts",
        "Donations": "gifts",
        "Charity": "gifts",
        "Presents": "gifts",
        "Gifts & Donations": "gifts",
        
        // Travel variations
        "Travel": "travel",
        "Vacation": "travel",
        "Hotels": "travel",
        "Flights": "travel",
        
        // Income variations
        "Income": "income",
        "Salary": "income",
        "Wages": "income",
        "Bonus": "income",
        "Side Income": "income",
        
        // Transfer variations
        "Transfer": "transfer",
        "Account Transfer": "transfer",
        "Internal Transfer": "transfer",
        
        // Other variations
        "Other": "other",
        "Miscellaneous": "other",
        "Uncategorized": "other"
    ]
    
    // MARK: - Migration Methods
    
    /// Migrate a single category name to canonical format
    static func migrateCategory(_ categoryName: String) -> String {
        // First check if it's already a canonical name
        if CategoryDefinition.allCategories.contains(where: { $0.canonicalName == categoryName }) {
            return categoryName
        }
        
        // Check legacy mappings
        if let canonical = legacyCategoryMappings[categoryName] {
            return canonical
        }
        
        // Try case-insensitive match
        if let canonical = legacyCategoryMappings.first(where: { 
            $0.key.lowercased() == categoryName.lowercased() 
        })?.value {
            return canonical
        }
        
        // Default to "other" if no match found
        return "other"
    }
    
    /// Perform full migration on Core Data context
    static func performMigration(context: NSManagedObjectContext) async throws -> MigrationResult {
        guard isMigrationNeeded() else {
            return MigrationResult(
                transactionsMigrated: 0,
                budgetCategoriesMigrated: 0,
                recurringTransactionsMigrated: 0,
                categorizationRulesMigrated: 0,
                merchantPatternsMigrated: 0,
                errors: []
            )
        }
        
        var result = MigrationResult(
            transactionsMigrated: 0,
            budgetCategoriesMigrated: 0,
            recurringTransactionsMigrated: 0,
            categorizationRulesMigrated: 0,
            merchantPatternsMigrated: 0,
            errors: []
        )
        
        do {
            // Migrate transactions
            result.transactionsMigrated = try await migrateTransactions(context: context)
            
            // Migrate budget categories
            result.budgetCategoriesMigrated = try await migrateBudgetCategories(context: context)
            
            // Migrate recurring transactions
            result.recurringTransactionsMigrated = try await migrateRecurringTransactions(context: context)
            
            // Migrate categorization rules
            result.categorizationRulesMigrated = try await migrateCategorizationRules(context: context)
            
            // Migrate merchant patterns
            result.merchantPatternsMigrated = try await migrateMerchantPatterns(context: context)
            
            // Save changes
            if context.hasChanges {
                try context.save()
            }
            
            // Mark migration as complete
            markMigrationComplete()
            
        } catch {
            result.errors.append(error)
            throw error
        }
        
        return result
    }
    
    // MARK: - Entity-Specific Migration
    
    private static func migrateTransactions(context: NSManagedObjectContext) async throws -> Int {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Transaction")
        let transactions = try context.fetch(fetchRequest)
        
        var migratedCount = 0
        
        for transaction in transactions {
            guard let oldCategory = transaction.value(forKey: "category") as? String else {
                continue
            }
            
            let newCategory = migrateCategory(oldCategory)
            
            // Only update if category changed
            if newCategory != oldCategory {
                transaction.setValue(newCategory, forKey: "category")
                transaction.setValue(Date(), forKey: "updatedAt")
                migratedCount += 1
            }
        }
        
        return migratedCount
    }
    
    private static func migrateBudgetCategories(context: NSManagedObjectContext) async throws -> Int {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "BudgetCategory")
        let budgetCategories = try context.fetch(fetchRequest)
        
        var migratedCount = 0
        
        for budgetCategory in budgetCategories {
            guard let oldName = budgetCategory.value(forKey: "name") as? String else {
                continue
            }
            
            let newName = migrateCategory(oldName)
            
            // Only update if category changed
            if newName != oldName {
                budgetCategory.setValue(newName, forKey: "name")
                
                // Update display name if it matches the old name
                if let displayName = budgetCategory.value(forKey: "displayName") as? String,
                   displayName == oldName {
                    // Get the proper display name from CategoryDefinition
                    if let categoryDef = CategoryDefinition.allCategories.first(where: { $0.canonicalName == newName }) {
                        budgetCategory.setValue(categoryDef.displayName, forKey: "displayName")
                    }
                }
                
                budgetCategory.setValue(Date(), forKey: "updatedAt")
                migratedCount += 1
            }
        }
        
        return migratedCount
    }
    
    private static func migrateRecurringTransactions(context: NSManagedObjectContext) async throws -> Int {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "RecurringTransaction")
        let recurringTransactions = try context.fetch(fetchRequest)
        
        var migratedCount = 0
        
        for transaction in recurringTransactions {
            guard let oldCategory = transaction.value(forKey: "category") as? String else {
                continue
            }
            
            let newCategory = migrateCategory(oldCategory)
            
            // Only update if category changed
            if newCategory != oldCategory {
                transaction.setValue(newCategory, forKey: "category")
                transaction.setValue(Date(), forKey: "updatedAt")
                migratedCount += 1
            }
        }
        
        return migratedCount
    }
    
    private static func migrateCategorizationRules(context: NSManagedObjectContext) async throws -> Int {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CategorizationRule")
        let rules = try context.fetch(fetchRequest)
        
        var migratedCount = 0
        
        for rule in rules {
            guard let oldCategory = rule.value(forKey: "category") as? String else {
                continue
            }
            
            let newCategory = migrateCategory(oldCategory)
            
            // Only update if category changed
            if newCategory != oldCategory {
                rule.setValue(newCategory, forKey: "category")
                rule.setValue(Date(), forKey: "updatedAt")
                migratedCount += 1
            }
        }
        
        return migratedCount
    }
    
    private static func migrateMerchantPatterns(context: NSManagedObjectContext) async throws -> Int {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "MerchantPattern")
        let patterns = try context.fetch(fetchRequest)
        
        var migratedCount = 0
        
        for pattern in patterns {
            guard let oldCategory = pattern.value(forKey: "category") as? String else {
                continue
            }
            
            let newCategory = migrateCategory(oldCategory)
            
            // Only update if category changed
            if newCategory != oldCategory {
                pattern.setValue(newCategory, forKey: "category")
                pattern.setValue(Date(), forKey: "updatedAt")
                migratedCount += 1
            }
        }
        
        return migratedCount
    }
    
    // MARK: - Validation
    
    /// Validate that all categories in the database are canonical
    static func validateMigration(context: NSManagedObjectContext) async throws -> CategoryValidationResult {
        var result = CategoryValidationResult(
            isValid: true,
            invalidTransactions: [],
            invalidBudgetCategories: [],
            invalidRecurringTransactions: [],
            invalidCategorizationRules: [],
            invalidMerchantPatterns: []
        )
        
        let canonicalNames = Set(CategoryDefinition.allCategories.map { $0.canonicalName })
        
        // Validate transactions
        let transactionFetch = NSFetchRequest<NSManagedObject>(entityName: "Transaction")
        let transactions = try context.fetch(transactionFetch)
        for transaction in transactions {
            if let category = transaction.value(forKey: "category") as? String,
               !canonicalNames.contains(category) {
                result.isValid = false
                result.invalidTransactions.append(category)
            }
        }
        
        // Validate budget categories
        let budgetCategoryFetch = NSFetchRequest<NSManagedObject>(entityName: "BudgetCategory")
        let budgetCategories = try context.fetch(budgetCategoryFetch)
        for budgetCategory in budgetCategories {
            if let name = budgetCategory.value(forKey: "name") as? String,
               !canonicalNames.contains(name) {
                result.isValid = false
                result.invalidBudgetCategories.append(name)
            }
        }
        
        // Validate recurring transactions
        let recurringFetch = NSFetchRequest<NSManagedObject>(entityName: "RecurringTransaction")
        let recurringTransactions = try context.fetch(recurringFetch)
        for transaction in recurringTransactions {
            if let category = transaction.value(forKey: "category") as? String,
               !canonicalNames.contains(category) {
                result.isValid = false
                result.invalidRecurringTransactions.append(category)
            }
        }
        
        // Validate categorization rules
        let rulesFetch = NSFetchRequest<NSManagedObject>(entityName: "CategorizationRule")
        let rules = try context.fetch(rulesFetch)
        for rule in rules {
            if let category = rule.value(forKey: "category") as? String,
               !canonicalNames.contains(category) {
                result.isValid = false
                result.invalidCategorizationRules.append(category)
            }
        }
        
        // Validate merchant patterns
        let patternsFetch = NSFetchRequest<NSManagedObject>(entityName: "MerchantPattern")
        let patterns = try context.fetch(patternsFetch)
        for pattern in patterns {
            if let category = pattern.value(forKey: "category") as? String,
               !canonicalNames.contains(category) {
                result.isValid = false
                result.invalidMerchantPatterns.append(category)
            }
        }
        
        return result
    }
}

// MARK: - Result Types

struct MigrationResult {
    var transactionsMigrated: Int
    var budgetCategoriesMigrated: Int
    var recurringTransactionsMigrated: Int
    var categorizationRulesMigrated: Int
    var merchantPatternsMigrated: Int
    var errors: [Error]
    
    var totalMigrated: Int {
        transactionsMigrated + budgetCategoriesMigrated + 
        recurringTransactionsMigrated + categorizationRulesMigrated + 
        merchantPatternsMigrated
    }
    
    var isSuccessful: Bool {
        errors.isEmpty
    }
}

struct CategoryValidationResult {
    var isValid: Bool
    var invalidTransactions: [String]
    var invalidBudgetCategories: [String]
    var invalidRecurringTransactions: [String]
    var invalidCategorizationRules: [String]
    var invalidMerchantPatterns: [String]
    
    var totalInvalid: Int {
        invalidTransactions.count + invalidBudgetCategories.count + 
        invalidRecurringTransactions.count + invalidCategorizationRules.count + 
        invalidMerchantPatterns.count
    }
}
