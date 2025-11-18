//
//  CategoryMigrationExample.swift
//  ClariFi iOS
//
//  Created by Kiro on 2025-10-13.
//
//  Example usage of CategoryMigration utility
//

import Foundation
import CoreData

/// Example of how to integrate CategoryMigration into the app lifecycle
class CategoryMigrationExample {
    
    /// Run migration on app launch
    /// Call this from ClariFi_iOSApp.init() or ContentView.onAppear
    static func runMigrationOnAppLaunch(context: NSManagedObjectContext) {
        Task {
            do {
                // Check if migration is needed
                guard CategoryMigration.isMigrationNeeded() else {
                    print("✅ Category migration not needed - already up to date")
                    return
                }
                
                print("🔄 Starting category migration...")
                
                // Perform migration
                let result = try await CategoryMigration.performMigration(context: context)
                
                // Log results
                if result.isSuccessful {
                    print("✅ Category migration completed successfully!")
                    print("   - Transactions migrated: \(result.transactionsMigrated)")
                    print("   - Budget categories migrated: \(result.budgetCategoriesMigrated)")
                    print("   - Recurring transactions migrated: \(result.recurringTransactionsMigrated)")
                    print("   - Categorization rules migrated: \(result.categorizationRulesMigrated)")
                    print("   - Merchant patterns migrated: \(result.merchantPatternsMigrated)")
                    print("   - Total migrated: \(result.totalMigrated)")
                    
                    // Validate migration
                    let validation = try await CategoryMigration.validateMigration(context: context)
                    if validation.isValid {
                        print("✅ Migration validation passed - all categories are canonical")
                    } else {
                        print("⚠️ Migration validation found issues:")
                        print("   - Invalid transactions: \(validation.invalidTransactions.count)")
                        print("   - Invalid budget categories: \(validation.invalidBudgetCategories.count)")
                        print("   - Invalid recurring transactions: \(validation.invalidRecurringTransactions.count)")
                        print("   - Invalid categorization rules: \(validation.invalidCategorizationRules.count)")
                        print("   - Invalid merchant patterns: \(validation.invalidMerchantPatterns.count)")
                    }
                } else {
                    print("❌ Category migration failed with errors:")
                    for error in result.errors {
                        print("   - \(error.localizedDescription)")
                    }
                }
                
            } catch {
                print("❌ Category migration error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Example: Migrate a single category name in code
    static func exampleSingleCategoryMigration() {
        let legacyCategory = "Housing & Rent"
        let canonicalCategory = CategoryMigration.migrateCategory(legacyCategory)
        
        print("Legacy: '\(legacyCategory)' -> Canonical: '\(canonicalCategory)'")
        // Output: Legacy: 'Housing & Rent' -> Canonical: 'housing'
    }
    
    /// Example: Validate categories before saving
    static func exampleValidateBeforeSave(categoryName: String) -> Bool {
        let canonicalNames = Set(CategoryDefinition.allCategories.map { $0.canonicalName })
        
        if canonicalNames.contains(categoryName) {
            print("✅ Category '\(categoryName)' is valid")
            return true
        } else {
            print("⚠️ Category '\(categoryName)' is not canonical - migrating...")
            let migratedCategory = CategoryMigration.migrateCategory(categoryName)
            print("   Migrated to: '\(migratedCategory)'")
            return false
        }
    }
    
    /// Example: Manual migration trigger (for testing or admin tools)
    static func manualMigrationTrigger(context: NSManagedObjectContext) async throws {
        print("🔄 Manual migration triggered...")
        
        // Force migration by clearing version
        UserDefaults.standard.removeObject(forKey: "CategoryMigrationVersion")
        
        // Run migration
        let result = try await CategoryMigration.performMigration(context: context)
        
        print("✅ Manual migration completed:")
        print("   Total items migrated: \(result.totalMigrated)")
    }
}

// MARK: - Integration Points

/*
 To integrate CategoryMigration into your app:
 
 1. Add to ClariFi_iOSApp.swift:
 
    @main
    struct ClariFi_iOSApp: App {
        let persistenceController = PersistenceController.shared
        
        init() {
            // Run migration on app launch
            CategoryMigrationExample.runMigrationOnAppLaunch(
                context: persistenceController.container.viewContext
            )
        }
        
        var body: some Scene {
            WindowGroup {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
 
 2. Or add to ContentView.swift:
 
    struct ContentView: View {
        @Environment(\.managedObjectContext) private var viewContext
        
        var body: some View {
            MainTabView()
                .onAppear {
                    CategoryMigrationExample.runMigrationOnAppLaunch(context: viewContext)
                }
        }
    }
 
 3. Use in ViewModels when saving categories:
 
    class TransactionEntryViewModel: ObservableObject {
        func saveTransaction(category: String) {
            // Ensure category is canonical before saving
            let canonicalCategory = CategoryMigration.migrateCategory(category)
            
            // Save with canonical category
            transaction.category = canonicalCategory
            // ...
        }
    }
 
 4. Add to Settings/Admin panel for manual migration:
 
    Button("Run Category Migration") {
        Task {
            try? await CategoryMigrationExample.manualMigrationTrigger(
                context: viewContext
            )
        }
    }
 */

