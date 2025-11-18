//
//  CategoryConsistencyTests.swift
//  ClariFi iOSTests
//
//  Integration tests for category consistency across the application
//  Tests Requirements: 2.1, 2.2, 2.4
//

import XCTest
import SwiftUI
import CoreData
@testable import ClariFi_iOS

class CategoryConsistencyTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var container: DIContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory persistence controller for testing
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
        
        // Create test DI container
        container = AppDIContainer.createTestContainer(inMemoryContext: viewContext)
    }
    
    override func tearDown() async throws {
        // Clean up test data
        try? await cleanupTestData()
        container = nil
        persistenceController = nil
        viewContext = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func cleanupTestData() async throws {
        let entities = ["Transaction", "Budget", "BudgetCategory", "Account", "Statement"]
        
        for entityName in entities {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try? viewContext.execute(deleteRequest)
        }
        
        try viewContext.save()
    }
    
    private func createTestAccount(name: String = "Test Account") -> Account {
        let account = Account(context: viewContext)
        account.id = UUID()
        account.name = name
        account.type = "checking"
        account.lastFourDigits = "1234"
        return account
    }
    
    // MARK: - Budget Creation from Template Tests
    
    func testBudgetCreationFromTemplate_UsesCanonicalCategories() async throws {
        // Test Requirements: 2.1, 2.2 - Budget templates use canonical category names
        
        // Given: A budget template service
        let templateService = container.resolve(BudgetTemplateService.self)
        let categoryMappingService = container.resolve(CategoryMappingServiceProtocol.self)
        
        // When: Loading a budget template
        let template = templateService.getTemplate(byId: "student")
        XCTAssertNotNil(template, "Student template should exist")
        
        // Then: All template categories should map to canonical categories
        for categoryTemplate in template!.categories {
            let canonicalCategory = categoryMappingService.getCanonicalCategory(from: categoryTemplate.name)
            XCTAssertNotNil(
                canonicalCategory,
                "Template category '\(categoryTemplate.name)' should map to a canonical category"
            )
            
            // Verify the canonical name is set correctly
            XCTAssertEqual(
                categoryTemplate.canonicalName,
                canonicalCategory?.canonicalName,
                "Template category '\(categoryTemplate.name)' should have correct canonical name"
            )
        }
    }
    
    func testBudgetCreationFromTemplate_AllTemplatesHaveValidCategories() async throws {
        // Test Requirements: 2.1, 2.2 - All budget templates use valid canonical categories
        
        // Given: All available budget templates
        let templateService = container.resolve(BudgetTemplateService.self)
        let categoryMappingService = container.resolve(CategoryMappingServiceProtocol.self)
        let allTemplates = templateService.getAllTemplates()
        
        XCTAssertGreaterThan(allTemplates.count, 0, "Should have budget templates")
        
        // When/Then: Verify each template's categories map correctly
        for template in allTemplates {
            for categoryTemplate in template.categories {
                let canonicalCategory = categoryMappingService.getCanonicalCategory(from: categoryTemplate.name)
                XCTAssertNotNil(
                    canonicalCategory,
                    "Template '\(template.name)' category '\(categoryTemplate.name)' should map to canonical category"
                )
            }
        }
    }
    
    func testBudgetCreationFromTemplate_CreatesConsistentBudget() async throws {
        // Test Requirements: 2.1, 2.2 - Budget creation uses canonical categories
        
        // Given: A budget creation view model
        let budgetViewModel = container.resolve(BudgetCreationViewModel.self)
        let budgetRepository = container.resolve(BudgetRepository.self)
        let categoryMappingService = container.resolve(CategoryMappingServiceProtocol.self)
        
        // When: Creating a budget from template
        await MainActor.run {
            budgetViewModel.budgetName = "Test Student Budget"
            budgetViewModel.selectedPeriod = "monthly"
            budgetViewModel.selectedTemplate = "student"
        }
        
        await budgetViewModel.loadTemplate()
        await budgetViewModel.saveBudget()
        
        // Then: Budget should be created with canonical category names
        let budgets = try await budgetRepository.fetchAll()
        let createdBudget = budgets.first { $0.name == "Test Student Budget" }
        
        XCTAssertNotNil(createdBudget, "Budget should be created")
        
        let budgetCategories = createdBudget?.categories?.allObjects as? [BudgetCategory] ?? []
        XCTAssertGreaterThan(budgetCategories.count, 0, "Budget should have categories")
        
        // Verify all budget categories use canonical names
        for budgetCategory in budgetCategories {
            let categoryName = budgetCategory.name ?? ""
            let canonicalCategory = categoryMappingService.getCanonicalCategory(from: categoryName)
            
            XCTAssertNotNil(
                canonicalCategory,
                "Budget category '\(categoryName)' should be a valid canonical category"
            )
        }
    }
    
    // MARK: - Transaction Entry with Budget Categories Tests
    
    func testTransactionEntry_UsesCanonicalCategories() async throws {
        // Test Requirements: 2.1, 2.2, 2.3 - Transaction entry uses canonical categories
        
        // Given: A transaction entry view model
        let transactionViewModel = container.resolve(TransactionEntryViewModel.self)
        let categoryMappingService = container.resolve(CategoryMappingServiceProtocol.self)
        
        // When: Loading available categories
        await transactionViewModel.loadAccounts()
        
        // Then: All available categories should be canonical
        let availableCategories = await transactionViewModel.availableCategories
        XCTAssertGreaterThan(availableCategories.count, 0, "Should have available categories")
        
        for category in availableCategories {
            XCTAssertEqual(
                category.canonicalName,
                category.id,
                "Category ID should match canonical name"
            )
            
            // Verify category exists in mapping service
            let mappedCategory = categoryMappingService.getCanonicalCategory(from: category.canonicalName)
            XCTAssertNotNil(mappedCategory, "Category should exist in mapping service")
        }
    }
    
    func testTransactionEntry_SavesCanonicalCategoryName() async throws {
        // Test Requirements: 2.3 - Transactions store canonical category names
        
        // Given: A transaction entry view model
        let transactionViewModel = container.resolve(TransactionEntryViewModel.self)
        let transactionRepository = container.resolve(TransactionRepository.self)
        let account = createTestAccount()
        try viewContext.save()
        
        // When: Creating a transaction with a category
        await MainActor.run {
            transactionViewModel.date = Date()
            transactionViewModel.merchant = "Test Merchant"
            transactionViewModel.amount = "50.00"
            transactionViewModel.selectedCategory = "food_groceries"
            transactionViewModel.selectedAccount = account
        }
        
        await transactionViewModel.saveTransaction()
        
        // Then: Transaction should be saved with canonical category name
        let transactions = try await transactionRepository.fetchAll()
        let savedTransaction = transactions.first { $0.merchant == "Test Merchant" }
        
        XCTAssertNotNil(savedTransaction, "Transaction should be saved")
        XCTAssertEqual(
            savedTransaction?.category,
            "food_groceries",
            "Transaction should store canonical category name"
        )
    }
    
    // MARK: - Category Matching Across Budget and Transactions Tests
    
    func testCategoryMatching_BudgetAndTransactionCategoriesAlign() async throws {
        // Test Requirements: 2.1, 2.2, 2.4 - Budget and transaction categories match
        
        // Given: A budget with categories
        let budget = Budget(context: viewContext)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        
        let housingCategory = BudgetCategory(context: viewContext)
        housingCategory.id = UUID()
        housingCategory.name = "housing"
        housingCategory.budgetedAmount = NSDecimalNumber(value: 1000)
        housingCategory.budget = budget
        
        let foodCategory = BudgetCategory(context: viewContext)
        foodCategory.id = UUID()
        foodCategory.name = "food_groceries"
        foodCategory.budgetedAmount = NSDecimalNumber(value: 500)
        foodCategory.budget = budget
        
        try viewContext.save()
        
        // When: Creating transactions with matching categories
        let account = createTestAccount()
        
        let transaction1 = Transaction(context: viewContext)
        transaction1.id = UUID()
        transaction1.date = Date()
        transaction1.merchant = "Landlord"
        transaction1.amount = NSDecimalNumber(value: 1000)
        transaction1.category = "housing"
        transaction1.isManual = true
        transaction1.account = account
        
        let transaction2 = Transaction(context: viewContext)
        transaction2.id = UUID()
        transaction2.date = Date()
        transaction2.merchant = "Grocery Store"
        transaction2.amount = NSDecimalNumber(value: 150)
        transaction2.category = "food_groceries"
        transaction2.isManual = true
        transaction2.account = account
        
        try viewContext.save()
        
        // Then: Transaction categories should match budget categories exactly
        let budgetCategories = budget.categories?.allObjects as? [BudgetCategory] ?? []
        let budgetCategoryNames = Set(budgetCategories.compactMap { $0.name })
        
        let transactionRepository = container.resolve(TransactionRepository.self)
        let transactions = try await transactionRepository.fetchAll()
        let transactionCategoryNames = Set(transactions.compactMap { $0.category })
        
        // Verify all transaction categories exist in budget
        for transactionCategory in transactionCategoryNames {
            XCTAssertTrue(
                budgetCategoryNames.contains(transactionCategory),
                "Transaction category '\(transactionCategory)' should exist in budget categories"
            )
        }
    }
    
    func testCategoryMatching_BudgetTrackingUsesCanonicalNames() async throws {
        // Test Requirements: 2.4 - Budget tracking matches transactions by canonical name
        
        // Given: A budget with canonical category names
        let budget = Budget(context: viewContext)
        budget.id = UUID()
        budget.name = "Tracking Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        
        let diningCategory = BudgetCategory(context: viewContext)
        diningCategory.id = UUID()
        diningCategory.name = "dining"
        diningCategory.budgetedAmount = NSDecimalNumber(value: 300)
        diningCategory.budget = budget
        
        try viewContext.save()
        
        // When: Adding transactions with the same canonical category
        let account = createTestAccount()
        
        for i in 1...3 {
            let transaction = Transaction(context: viewContext)
            transaction.id = UUID()
            transaction.date = Date()
            transaction.merchant = "Restaurant \(i)"
            transaction.amount = NSDecimalNumber(value: 50)
            transaction.category = "dining"
            transaction.isManual = true
            transaction.account = account
        }
        
        try viewContext.save()
        
        // Then: Budget monitoring should correctly track spending
        let budgetViewModel = container.resolve(BudgetViewModel.self)
        await budgetViewModel.loadBudgetStatus()
        
        let budgetStatus = await budgetViewModel.budgetStatus
        XCTAssertNotNil(budgetStatus, "Budget status should be loaded")
        
        // Verify spending is tracked correctly (3 transactions * $50 = $150)
        let categoryStatuses = budgetStatus?.categoryStatuses ?? []
        let diningStatus = categoryStatuses.first { $0.category.name == "dining" }
        
        XCTAssertNotNil(diningStatus, "Dining category status should exist")
        XCTAssertEqual(
            diningStatus?.spent as Decimal?,
            150,
            "Should track $150 spent in dining category"
        )
    }
    
    // MARK: - No Category Name Mismatches Tests
    
    func testNoCategoryMismatches_AllCategoriesAreCanonical() async throws {
        // Test Requirements: 2.1, 2.2 - Verify no category name mismatches
        
        // Given: Multiple budgets and transactions
        let categoryMappingService = container.resolve(CategoryMappingServiceProtocol.self)
        let allCanonicalNames = Set(categoryMappingService.getAllCategories().map { $0.canonicalName })
        
        // Create budgets from different templates
        let templateService = container.resolve(BudgetTemplateService.self)
        let templates = ["student", "professional", "family"]
        
        for templateId in templates {
            guard let template = templateService.getTemplate(byId: templateId) else { continue }
            
            let budget = Budget(context: viewContext)
            budget.id = UUID()
            budget.name = "\(template.name) Test"
            budget.period = "monthly"
            budget.startDate = Date()
            budget.isActive = false
            
            for categoryTemplate in template.categories {
                let budgetCategory = BudgetCategory(context: viewContext)
                budgetCategory.id = UUID()
                budgetCategory.name = categoryTemplate.canonicalName
                budgetCategory.budgetedAmount = categoryTemplate.suggestedAmount as NSDecimalNumber
                budgetCategory.budget = budget
            }
        }
        
        try viewContext.save()
        
        // When: Checking all budget categories
        let budgetRepository = container.resolve(BudgetRepository.self)
        let budgets = try await budgetRepository.fetchAll()
        
        // Then: All budget categories should use canonical names
        for budget in budgets {
            let categories = budget.categories?.allObjects as? [BudgetCategory] ?? []
            for category in categories {
                let categoryName = category.name ?? ""
                XCTAssertTrue(
                    allCanonicalNames.contains(categoryName),
                    "Budget category '\(categoryName)' in budget '\(budget.name ?? "")' should be a canonical name"
                )
            }
        }
    }
    
    func testNoCategoryMismatches_TransactionCategoriesMatchBudget() async throws {
        // Test Requirements: 2.4 - No mismatches between transaction and budget categories
        
        // Given: A budget with specific categories
        let budget = Budget(context: viewContext)
        budget.id = UUID()
        budget.name = "Consistency Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        
        let categoryNames = ["housing", "food_groceries", "transportation", "utilities"]
        for categoryName in categoryNames {
            let budgetCategory = BudgetCategory(context: viewContext)
            budgetCategory.id = UUID()
            budgetCategory.name = categoryName
            budgetCategory.budgetedAmount = NSDecimalNumber(value: 500)
            budgetCategory.budget = budget
        }
        
        try viewContext.save()
        
        // When: Creating transactions with the same categories
        let account = createTestAccount()
        
        for categoryName in categoryNames {
            let transaction = Transaction(context: viewContext)
            transaction.id = UUID()
            transaction.date = Date()
            transaction.merchant = "Test Merchant for \(categoryName)"
            transaction.amount = NSDecimalNumber(value: 100)
            transaction.category = categoryName
            transaction.isManual = true
            transaction.account = account
        }
        
        try viewContext.save()
        
        // Then: All transaction categories should match budget categories exactly
        let transactionRepository = container.resolve(TransactionRepository.self)
        let transactions = try await transactionRepository.fetchAll()
        
        let budgetCategories = budget.categories?.allObjects as? [BudgetCategory] ?? []
        let budgetCategoryNames = Set(budgetCategories.compactMap { $0.name })
        
        for transaction in transactions {
            let transactionCategory = transaction.category ?? ""
            XCTAssertTrue(
                budgetCategoryNames.contains(transactionCategory),
                "Transaction category '\(transactionCategory)' should exist in budget"
            )
        }
    }
    
    func testNoCategoryMismatches_DisplayNamesAreConsistent() async throws {
        // Test Requirements: 2.1, 2.2 - Display names are consistent across the app
        
        // Given: Category mapping service
        let categoryMappingService = container.resolve(CategoryMappingServiceProtocol.self)
        let allCategories = categoryMappingService.getAllCategories()
        
        // When/Then: Verify each category has consistent display name
        for category in allCategories {
            let displayName1 = categoryMappingService.getDisplayName(for: category.canonicalName)
            let displayName2 = category.displayName
            
            XCTAssertEqual(
                displayName1,
                displayName2,
                "Display name for '\(category.canonicalName)' should be consistent"
            )
            
            // Verify mapping back to canonical works
            let mappedCategory = categoryMappingService.getCanonicalCategory(from: displayName1)
            XCTAssertNotNil(mappedCategory, "Display name should map back to canonical category")
            XCTAssertEqual(
                mappedCategory?.canonicalName,
                category.canonicalName,
                "Display name should map to correct canonical category"
            )
        }
    }
    
    // MARK: - End-to-End Category Consistency Tests
    
    func testEndToEnd_BudgetCreationToTransactionTracking() async throws {
        // Test Requirements: 2.1, 2.2, 2.4 - Complete workflow maintains category consistency
        
        // Given: Create a budget from template
        let budgetViewModel = container.resolve(BudgetCreationViewModel.self)
        
        await MainActor.run {
            budgetViewModel.budgetName = "E2E Test Budget"
            budgetViewModel.selectedPeriod = "monthly"
            budgetViewModel.selectedTemplate = "professional"
        }
        
        await budgetViewModel.loadTemplate()
        await budgetViewModel.saveBudget()
        
        // Get the created budget
        let budgetRepository = container.resolve(BudgetRepository.self)
        let budgets = try await budgetRepository.fetchAll()
        let createdBudget = budgets.first { $0.name == "E2E Test Budget" }
        XCTAssertNotNil(createdBudget, "Budget should be created")
        
        let budgetCategories = createdBudget?.categories?.allObjects as? [BudgetCategory] ?? []
        XCTAssertGreaterThan(budgetCategories.count, 0, "Budget should have categories")
        
        // When: Create transactions using the same categories
        let transactionViewModel = container.resolve(TransactionEntryViewModel.self)
        let account = createTestAccount()
        try viewContext.save()
        
        // Pick a few categories from the budget
        let testCategories = Array(budgetCategories.prefix(3))
        
        for budgetCategory in testCategories {
            await MainActor.run {
                transactionViewModel.date = Date()
                transactionViewModel.merchant = "Merchant for \(budgetCategory.name ?? "")"
                transactionViewModel.amount = "75.00"
                transactionViewModel.selectedCategory = budgetCategory.name ?? ""
                transactionViewModel.selectedAccount = account
            }
            
            await transactionViewModel.saveTransaction()
        }
        
        // Then: Budget tracking should work correctly
        let budgetTrackingViewModel = container.resolve(BudgetViewModel.self)
        await budgetTrackingViewModel.loadBudgetStatus()
        
        let budgetStatus = await budgetTrackingViewModel.budgetStatus
        XCTAssertNotNil(budgetStatus, "Budget status should be loaded")
        
        // Verify spending is tracked for each category
        let categoryStatuses = budgetStatus?.categoryStatuses ?? []
        
        for budgetCategory in testCategories {
            let categoryName = budgetCategory.name ?? ""
            let categoryStatus = categoryStatuses.first { $0.category.name == categoryName }
            
            XCTAssertNotNil(
                categoryStatus,
                "Category status should exist for '\(categoryName)'"
            )
            XCTAssertEqual(
                categoryStatus?.spent as Decimal?,
                75,
                "Should track $75 spent in '\(categoryName)'"
            )
        }
    }
    
    func testEndToEnd_MultipleTemplatesNoConflicts() async throws {
        // Test Requirements: 2.1, 2.2 - Multiple templates don't create category conflicts
        
        // Given: Multiple budgets from different templates
        let templateService = container.resolve(BudgetTemplateService.self)
        let categoryMappingService = container.resolve(CategoryMappingServiceProtocol.self)
        let templates = ["student", "professional", "family", "minimalist"]
        
        var allUsedCategories: Set<String> = []
        
        // When: Creating budgets from different templates
        for templateId in templates {
            guard let template = templateService.getTemplate(byId: templateId) else { continue }
            
            let budget = Budget(context: viewContext)
            budget.id = UUID()
            budget.name = "\(template.name) Budget"
            budget.period = "monthly"
            budget.startDate = Date()
            budget.isActive = false
            
            for categoryTemplate in template.categories {
                let budgetCategory = BudgetCategory(context: viewContext)
                budgetCategory.id = UUID()
                budgetCategory.name = categoryTemplate.canonicalName
                budgetCategory.budgetedAmount = categoryTemplate.suggestedAmount as NSDecimalNumber
                budgetCategory.budget = budget
                
                allUsedCategories.insert(categoryTemplate.canonicalName)
            }
        }
        
        try viewContext.save()
        
        // Then: All categories should be valid canonical categories
        let allCanonicalCategories = categoryMappingService.getAllCategories()
        let canonicalNames = Set(allCanonicalCategories.map { $0.canonicalName })
        
        for usedCategory in allUsedCategories {
            XCTAssertTrue(
                canonicalNames.contains(usedCategory),
                "Category '\(usedCategory)' should be a valid canonical category"
            )
        }
        
        // Verify no duplicate or conflicting category names
        let budgetRepository = container.resolve(BudgetRepository.self)
        let budgets = try await budgetRepository.fetchAll()
        
        for budget in budgets {
            let categories = budget.categories?.allObjects as? [BudgetCategory] ?? []
            let categoryNames = categories.compactMap { $0.name }
            let uniqueNames = Set(categoryNames)
            
            XCTAssertEqual(
                categoryNames.count,
                uniqueNames.count,
                "Budget '\(budget.name ?? "")' should not have duplicate categories"
            )
        }
    }
}
