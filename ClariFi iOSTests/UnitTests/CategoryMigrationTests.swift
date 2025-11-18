//
//  CategoryMigrationTests.swift
//  ClariFi iOS Tests
//
//  Created by Kiro on 2025-10-13.
//

import XCTest
import CoreData
@testable import ClariFi_iOS

class CategoryMigrationTests: XCTestCase {
    
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory Core Data stack for testing
        let persistentContainer = NSPersistentContainer(name: "ClariFi_iOS")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }
        
        context = persistentContainer.viewContext
    }
    
    override func tearDown() {
        context = nil
        super.tearDown()
    }
    
    // MARK: - Category Mapping Tests
    
    func testMigrateCategoryWithExactMatch() {
        // Test exact legacy category name match
        XCTAssertEqual(CategoryMigration.migrateCategory("Housing"), "housing")
        XCTAssertEqual(CategoryMigration.migrateCategory("Food & Groceries"), "food_groceries")
        XCTAssertEqual(CategoryMigration.migrateCategory("Transportation"), "transportation")
    }
    
    func testMigrateCategoryWithVariations() {
        // Test various legacy names map to same canonical name
        XCTAssertEqual(CategoryMigration.migrateCategory("Housing"), "housing")
        XCTAssertEqual(CategoryMigration.migrateCategory("Housing & Rent"), "housing")
        XCTAssertEqual(CategoryMigration.migrateCategory("Rent/Mortgage"), "housing")
        XCTAssertEqual(CategoryMigration.migrateCategory("Rent"), "housing")
    }
    
    func testMigrateCategoryWithCaseInsensitive() {
        // Test case-insensitive matching
        XCTAssertEqual(CategoryMigration.migrateCategory("housing"), "housing")
        XCTAssertEqual(CategoryMigration.migrateCategory("HOUSING"), "housing")
        XCTAssertEqual(CategoryMigration.migrateCategory("HoUsInG"), "housing")
    }
    
    func testMigrateCategoryAlreadyCanonical() {
        // Test that canonical names pass through unchanged
        XCTAssertEqual(CategoryMigration.migrateCategory("housing"), "housing")
        XCTAssertEqual(CategoryMigration.migrateCategory("food_groceries"), "food_groceries")
        XCTAssertEqual(CategoryMigration.migrateCategory("dining"), "dining")
    }
    
    func testMigrateCategoryUnknown() {
        // Test that unknown categories default to "other"
        XCTAssertEqual(CategoryMigration.migrateCategory("Unknown Category"), "other")
        XCTAssertEqual(CategoryMigration.migrateCategory("Random"), "other")
        XCTAssertEqual(CategoryMigration.migrateCategory(""), "other")
    }
    
    func testMigrateCategoryAllLegacyMappings() {
        // Test a comprehensive set of legacy mappings
        let testCases: [(String, String)] = [
            ("Housing", "housing"),
            ("Food & Groceries", "food_groceries"),
            ("Dining Out", "dining"),
            ("Car Payment", "transportation"),
            ("Electric", "utilities"),
            ("Medical", "healthcare"),
            ("Auto Insurance", "insurance"),
            ("Tuition", "education"),
            ("Movies", "entertainment"),
            ("Clothing", "shopping"),
            ("Streaming Services", "subscriptions"),
            ("Emergency Fund", "savings"),
            ("Credit Card Payment", "debt_payment"),
            ("Daycare", "childcare"),
            ("Pet Food", "pet_care"),
            ("Charity", "gifts"),
            ("Vacation", "travel"),
            ("Salary", "income"),
            ("Account Transfer", "transfer"),
            ("Miscellaneous", "other")
        ]
        
        for (legacy, canonical) in testCases {
            XCTAssertEqual(
                CategoryMigration.migrateCategory(legacy),
                canonical,
                "Failed to migrate '\(legacy)' to '\(canonical)'"
            )
        }
    }
    
    // MARK: - Transaction Migration Tests
    
    func testMigrateTransactions() async throws {
        // Create test transactions with legacy categories
        let transaction1 = NSEntityDescription.insertNewObject(forEntityName: "Transaction", into: context)
        transaction1.setValue(UUID(), forKey: "id")
        transaction1.setValue(Date(), forKey: "date")
        transaction1.setValue("Test Merchant", forKey: "merchant")
        transaction1.setValue(NSDecimalNumber(value: 100.0), forKey: "amount")
        transaction1.setValue("Housing & Rent", forKey: "category")
        transaction1.setValue(Date(), forKey: "createdAt")
        transaction1.setValue(Date(), forKey: "updatedAt")
        
        let transaction2 = NSEntityDescription.insertNewObject(forEntityName: "Transaction", into: context)
        transaction2.setValue(UUID(), forKey: "id")
        transaction2.setValue(Date(), forKey: "date")
        transaction2.setValue("Grocery Store", forKey: "merchant")
        transaction2.setValue(NSDecimalNumber(value: 50.0), forKey: "amount")
        transaction2.setValue("Food & Groceries", forKey: "category")
        transaction2.setValue(Date(), forKey: "createdAt")
        transaction2.setValue(Date(), forKey: "updatedAt")
        
        try context.save()
        
        // Perform migration
        let result = try await CategoryMigration.performMigration(context: context)
        
        // Verify migration results
        XCTAssertTrue(result.isSuccessful)
        XCTAssertEqual(result.transactionsMigrated, 2)
        
        // Verify categories were updated
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Transaction")
        let transactions = try context.fetch(fetchRequest)
        
        XCTAssertEqual(transactions[0].value(forKey: "category") as? String, "housing")
        XCTAssertEqual(transactions[1].value(forKey: "category") as? String, "food_groceries")
    }
    
    // MARK: - Budget Category Migration Tests
    
    func testMigrateBudgetCategories() async throws {
        // Create test budget with categories
        let budget = NSEntityDescription.insertNewObject(forEntityName: "Budget", into: context)
        budget.setValue(UUID(), forKey: "id")
        budget.setValue("Test Budget", forKey: "name")
        budget.setValue("monthly", forKey: "period")
        budget.setValue(Date(), forKey: "startDate")
        budget.setValue(Date(), forKey: "createdAt")
        budget.setValue(Date(), forKey: "updatedAt")
        
        let category1 = NSEntityDescription.insertNewObject(forEntityName: "BudgetCategory", into: context)
        category1.setValue(UUID(), forKey: "id")
        category1.setValue("Housing & Rent", forKey: "name")
        category1.setValue("Housing & Rent", forKey: "displayName")
        category1.setValue(NSDecimalNumber(value: 1500.0), forKey: "budgetedAmount")
        category1.setValue(NSDecimalNumber(value: 0.0), forKey: "spentAmount")
        category1.setValue(Date(), forKey: "createdAt")
        category1.setValue(Date(), forKey: "updatedAt")
        category1.setValue(budget, forKey: "budget")
        
        let category2 = NSEntityDescription.insertNewObject(forEntityName: "BudgetCategory", into: context)
        category2.setValue(UUID(), forKey: "id")
        category2.setValue("Dining Out", forKey: "name")
        category2.setValue("Dining Out", forKey: "displayName")
        category2.setValue(NSDecimalNumber(value: 300.0), forKey: "budgetedAmount")
        category2.setValue(NSDecimalNumber(value: 0.0), forKey: "spentAmount")
        category2.setValue(Date(), forKey: "createdAt")
        category2.setValue(Date(), forKey: "updatedAt")
        category2.setValue(budget, forKey: "budget")
        
        try context.save()
        
        // Perform migration
        let result = try await CategoryMigration.performMigration(context: context)
        
        // Verify migration results
        XCTAssertTrue(result.isSuccessful)
        XCTAssertEqual(result.budgetCategoriesMigrated, 2)
        
        // Verify categories were updated
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "BudgetCategory")
        let categories = try context.fetch(fetchRequest)
        
        XCTAssertEqual(categories[0].value(forKey: "name") as? String, "housing")
        XCTAssertEqual(categories[0].value(forKey: "displayName") as? String, "Housing & Rent")
        XCTAssertEqual(categories[1].value(forKey: "name") as? String, "dining")
        XCTAssertEqual(categories[1].value(forKey: "displayName") as? String, "Dining & Restaurants")
    }
    
    // MARK: - Validation Tests
    
    func testValidationWithValidCategories() async throws {
        // Create transactions with canonical categories
        let transaction = NSEntityDescription.insertNewObject(forEntityName: "Transaction", into: context)
        transaction.setValue(UUID(), forKey: "id")
        transaction.setValue(Date(), forKey: "date")
        transaction.setValue("Test", forKey: "merchant")
        transaction.setValue(NSDecimalNumber(value: 100.0), forKey: "amount")
        transaction.setValue("housing", forKey: "category")
        transaction.setValue(Date(), forKey: "createdAt")
        transaction.setValue(Date(), forKey: "updatedAt")
        
        try context.save()
        
        // Validate
        let result = try await CategoryMigration.validateMigration(context: context)
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.totalInvalid, 0)
    }
    
    func testValidationWithInvalidCategories() async throws {
        // Create transactions with invalid categories
        let transaction = NSEntityDescription.insertNewObject(forEntityName: "Transaction", into: context)
        transaction.setValue(UUID(), forKey: "id")
        transaction.setValue(Date(), forKey: "date")
        transaction.setValue("Test", forKey: "merchant")
        transaction.setValue(NSDecimalNumber(value: 100.0), forKey: "amount")
        transaction.setValue("Invalid Category", forKey: "category")
        transaction.setValue(Date(), forKey: "createdAt")
        transaction.setValue(Date(), forKey: "updatedAt")
        
        try context.save()
        
        // Validate
        let result = try await CategoryMigration.validateMigration(context: context)
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.invalidTransactions.count, 1)
        XCTAssertEqual(result.invalidTransactions[0], "Invalid Category")
    }
    
    // MARK: - Migration Version Tracking Tests
    
    func testMigrationVersionTracking() {
        // Clear any existing migration version
        UserDefaults.standard.removeObject(forKey: "CategoryMigrationVersion")
        
        // Should need migration initially
        XCTAssertTrue(CategoryMigration.isMigrationNeeded())
        
        // After migration, should not need it again
        // Note: We can't directly test this without exposing markMigrationComplete
        // but the performMigration method will handle this
    }
    
    // MARK: - Edge Cases
    
    func testMigrateEmptyDatabase() async throws {
        // Perform migration on empty database
        let result = try await CategoryMigration.performMigration(context: context)
        
        XCTAssertTrue(result.isSuccessful)
        XCTAssertEqual(result.totalMigrated, 0)
    }
    
    func testMigrateAlreadyMigratedData() async throws {
        // Create transaction with canonical category
        let transaction = NSEntityDescription.insertNewObject(forEntityName: "Transaction", into: context)
        transaction.setValue(UUID(), forKey: "id")
        transaction.setValue(Date(), forKey: "date")
        transaction.setValue("Test", forKey: "merchant")
        transaction.setValue(NSDecimalNumber(value: 100.0), forKey: "amount")
        transaction.setValue("housing", forKey: "category")
        transaction.setValue(Date(), forKey: "createdAt")
        transaction.setValue(Date(), forKey: "updatedAt")
        
        try context.save()
        
        // Perform migration
        let result = try await CategoryMigration.performMigration(context: context)
        
        // Should not migrate already canonical categories
        XCTAssertTrue(result.isSuccessful)
        XCTAssertEqual(result.transactionsMigrated, 0)
    }
}
