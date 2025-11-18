//
//  CategorizationTests.swift
//  ClariFi_iOSTests
//
//  Unit tests for transaction categorization system
//

import Testing
import CoreData
@testable import ClariFi_iOS

@MainActor
struct CategorizationTests {
    let context: NSManagedObjectContext
    let categoryService: CategoryService
    let ruleEngine: RuleEngine
    let transactionRepository: CoreDataTransactionRepository
    
    init() async throws {
        // Create in-memory Core Data stack
        let container = NSPersistentContainer(name: "ClariFi_iOS")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            #expect(error == nil)
        }
        
        context = container.viewContext
        transactionRepository = CoreDataTransactionRepository(context: context)
        categoryService = CategoryService(context: context, transactionRepository: transactionRepository)
        ruleEngine = RuleEngine(context: context, categoryService: categoryService)
    }
    
    // MARK: - Automatic Categorization Tests
    
    func testBuiltInPatternMatching() async throws {
        // Test common merchant patterns
        let testCases: [(merchant: String, expectedCategory: String)] = [
            ("Starbucks Coffee", "Dining & Restaurants"),
            ("WALMART SUPERCENTER", "Groceries"),
            ("Target Store #1234", "Groceries"),
            ("Uber Trip", "Transportation"),
            ("Netflix Subscription", "Entertainment"),
            ("Amazon.com", "Shopping"),
            ("CVS Pharmacy", "Healthcare")
        ]
        
        for testCase in testCases {
            let result = try await categoryService.categorize(merchant: testCase.merchant, amount: 10.00)
            XCTAssertEqual(result.category, testCase.expectedCategory,
                          "Failed to categorize '\(testCase.merchant)' correctly")
            XCTAssertGreaterThan(result.confidence, 0.5,
                               "Confidence too low for '\(testCase.merchant)'")
            #expect(result.matchType == .patternMatch)
        }
    }
    
    func testBuiltInPatternCaseInsensitivity() async throws {
        let variations = ["STARBUCKS", "starbucks", "StArBuCkS", "Starbucks"]
        
        for merchant in variations {
            let result = try await categoryService.categorize(merchant: merchant, amount: 5.00)
            #expect(result.category == "Dining & Restaurants")
            #expect(result.matchType == .patternMatch)
        }
    }
    
    func testDefaultCategoryForUnknownMerchant() async throws {
        let result = try await categoryService.categorize(merchant: "Unknown Merchant XYZ", amount: 25.00)
        
        #expect(result.category == "Other")
        #expect(result.confidence < 0.5)
        #expect(result.matchType == .default_)
        #expect(result.matchedPattern == nil)
    }
    
    func testCategorizationWithSpecialCharacters() async throws {
        let merchants = [
            "McDonald's Restaurant",
            "Trader Joe's",
            "L&L Hawaiian BBQ",
            "7-Eleven Store"
        ]
        
        for merchant in merchants {
            let result = try await categoryService.categorize(merchant: merchant, amount: 15.00)
            #expect(result.category != nil)
            #expect(result.confidence > 0.0)
        }
    }
    
    // MARK: - Learning from Corrections Tests
    
    func testLearnFromSingleCorrection() async throws {
        let merchant = "Local Coffee Shop"
        let category = "Dining & Restaurants"
        
        // Learn from correction
        try await categoryService.learnFromCorrection(merchant: merchant, category: category)
        
        // Verify it was learned
        let result = try await categoryService.categorize(merchant: merchant, amount: 5.00)
        #expect(result.category == category)
        #expect(result.matchType == .learned)
        #expect(result.confidence >= 0.7)
    }
    
    func testLearnFromMultipleCorrections() async throws {
        let merchant = "My Favorite Store"
        let category = "Shopping"
        
        // Learn multiple times
        for _ in 0..<3 {
            try await categoryService.learnFromCorrection(merchant: merchant, category: category)
        }
        
        // Verify confidence increases with repetition
        let result = try await categoryService.categorize(merchant: merchant, amount: 20.00)
        #expect(result.category == category)
        #expect(result.confidence > 0.8)
    }
    
    func testLearnedPatternOverridesBuiltIn() async throws {
        let merchant = "Starbucks"
        let newCategory = "Entertainment" // Override default "Dining"
        
        // Learn new category
        try await categoryService.learnFromCorrection(merchant: merchant, category: newCategory)
        
        // Verify learned pattern takes precedence
        let result = try await categoryService.categorize(merchant: merchant, amount: 5.00)
        #expect(result.category == newCategory)
        #expect(result.matchType == .learned)
    }
    
    func testUpdateExistingLearnedPattern() async throws {
        let merchant = "Test Merchant"
        
        // Learn first category
        try await categoryService.learnFromCorrection(merchant: merchant, category: "Shopping")
        
        // Change to different category
        try await categoryService.learnFromCorrection(merchant: merchant, category: "Entertainment")
        
        // Verify it uses the updated category
        let result = try await categoryService.categorize(merchant: merchant, amount: 10.00)
        #expect(result.category == "Entertainment")
    }
    
    func testMerchantHistoryTracking() async throws {
        let merchant = "Test Store"
        
        // Create transactions with different categories
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "debit"
        
        let categories = ["Shopping", "Shopping", "Groceries", "Shopping"]
        for category in categories {
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.merchant = merchant
            transaction.category = category
            transaction.amount = 10.00 as NSDecimalNumber
            transaction.date = Date()
            transaction.account = account
        }
        try context.save()
        
        // Get history
        let history = try await categoryService.getMerchantHistory(for: merchant)
        
        #expect(history["Shopping"] == 3)
        #expect(history["Groceries"] == 1)
    }
    
    // MARK: - Rule Engine Tests
    
    func testCreateAndApplySimpleRule() async throws {
        // Create rule
        let rule = try await ruleEngine.createRule(
            name: "Coffee Shops",
            merchantPattern: "coffee",
            category: "Dining & Restaurants",
            matchType: .contains,
            priority: 10
        )
        
        #expect(rule.id != nil)
        #expect(rule.isActive == true)
        #expect(rule.priority == 10)
        
        // Create transaction
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "debit"
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.merchant = "Local Coffee Shop"
        transaction.amount = 5.00 as NSDecimalNumber
        transaction.date = Date()
        transaction.account = account
        try context.save()
        
        // Apply rule
        let category = try await ruleEngine.applyRulesToTransaction(transaction)
        
        #expect(category == "Dining & Restaurants")
        #expect(rule.applicationCount == 1)
    }
    
    func testRuleMatchTypes() async throws {
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "debit"
        
        // Test exact match
        let exactRule = try await ruleEngine.createRule(
            name: "Exact Match",
            merchantPattern: "starbucks",
            category: "Dining & Restaurants",
            matchType: .exact,
            priority: 10
        )
        
        let transaction1 = Transaction(context: context)
        transaction1.id = UUID()
        transaction1.merchant = "Starbucks"
        transaction1.amount = 5.00 as NSDecimalNumber
        transaction1.date = Date()
        transaction1.account = account
        
        let category1 = try await ruleEngine.applyRulesToTransaction(transaction1)
        #expect(category1 == "Dining & Restaurants")
        
        // Test contains match
        let containsRule = try await ruleEngine.createRule(
            name: "Contains Match",
            merchantPattern: "market",
            category: "Groceries",
            matchType: .contains,
            priority: 9
        )
        
        let transaction2 = Transaction(context: context)
        transaction2.id = UUID()
        transaction2.merchant = "Supermarket Store"
        transaction2.amount = 50.00 as NSDecimalNumber
        transaction2.date = Date()
        transaction2.account = account
        
        let category2 = try await ruleEngine.applyRulesToTransaction(transaction2)
        #expect(category2 == "Groceries")
        
        // Test starts with match
        let startsWithRule = try await ruleEngine.createRule(
            name: "Starts With Match",
            merchantPattern: "amazon",
            category: "Shopping",
            matchType: .startsWith,
            priority: 8
        )
        
        let transaction3 = Transaction(context: context)
        transaction3.id = UUID()
        transaction3.merchant = "Amazon.com"
        transaction3.amount = 30.00 as NSDecimalNumber
        transaction3.date = Date()
        transaction3.account = account
        
        let category3 = try await ruleEngine.applyRulesToTransaction(transaction3)
        #expect(category3 == "Shopping")
    }
    
    func testRuleWithAmountConstraints() async throws {
        // Create rule with amount constraints
        let rule = try await ruleEngine.createRule(
            name: "Large Purchases",
            merchantPattern: "store",
            category: "Shopping",
            matchType: .contains,
            priority: 10,
            minAmount: 100.00,
            maxAmount: 500.00
        )
        
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "debit"
        
        // Test transaction within range
        let transaction1 = Transaction(context: context)
        transaction1.id = UUID()
        transaction1.merchant = "Big Store"
        transaction1.amount = 200.00 as NSDecimalNumber
        transaction1.date = Date()
        transaction1.account = account
        
        let category1 = try await ruleEngine.applyRulesToTransaction(transaction1)
        #expect(category1 == "Shopping")
        
        // Test transaction below minimum
        let transaction2 = Transaction(context: context)
        transaction2.id = UUID()
        transaction2.merchant = "Small Store"
        transaction2.amount = 50.00 as NSDecimalNumber
        transaction2.date = Date()
        transaction2.account = account
        
        let category2 = try await ruleEngine.applyRulesToTransaction(transaction2)
        #expect(category2 == nil)
        
        // Test transaction above maximum
        let transaction3 = Transaction(context: context)
        transaction3.id = UUID()
        transaction3.merchant = "Expensive Store"
        transaction3.amount = 600.00 as NSDecimalNumber
        transaction3.date = Date()
        transaction3.account = account
        
        let category3 = try await ruleEngine.applyRulesToTransaction(transaction3)
        #expect(category3 == nil)
    }
    
    func testRegexRuleMatching() async throws {
        // Create regex rule for pattern matching
        let rule = try await ruleEngine.createRule(
            name: "Gas Stations",
            merchantPattern: "^(shell|chevron|exxon|bp)",
            category: "Transportation",
            matchType: .regex,
            priority: 10
        )
        
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "debit"
        
        let merchants = ["Shell Gas Station", "Chevron #1234", "Exxon Mobile", "BP Station"]
        
        for merchant in merchants {
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.merchant = merchant
            transaction.amount = 40.00 as NSDecimalNumber
            transaction.date = Date()
            transaction.account = account
            
            let category = try await ruleEngine.applyRulesToTransaction(transaction)
            #expect(category == "Transportation", "Failed for merchant: \(merchant)")
        }
    }
    
    func testInvalidRegexPattern() async throws {
        // Attempt to create rule with invalid regex
        do {
            _ = try await ruleEngine.createRule(
                name: "Invalid Regex",
                merchantPattern: "[invalid(regex",
                category: "Other",
                matchType: .regex,
                priority: 5
            )
            Issue.record("Should have thrown error for invalid regex")
        } catch {
            // Expected to throw
            #expect(error is NSError == true)
        }
    }
    
    // MARK: - Rule Conflict Resolution Tests
    
    func testRulePriorityResolution() async throws {
        // Create two conflicting rules with different priorities
        let lowPriorityRule = try await ruleEngine.createRule(
            name: "Low Priority",
            merchantPattern: "store",
            category: "Shopping",
            matchType: .contains,
            priority: 5
        )
        
        let highPriorityRule = try await ruleEngine.createRule(
            name: "High Priority",
            merchantPattern: "store",
            category: "Groceries",
            matchType: .contains,
            priority: 10
        )
        
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "debit"
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.merchant = "Big Store"
        transaction.amount = 50.00 as NSDecimalNumber
        transaction.date = Date()
        transaction.account = account
        try context.save()
        
        // Apply rules - should use high priority rule
        let category = try await ruleEngine.applyRulesToTransaction(transaction)
        
        #expect(category == "Groceries")
        #expect(highPriorityRule.applicationCount == 1)
        #expect(lowPriorityRule.applicationCount == 0)
    }
    
    func testDetectConflictingRules() async throws {
        // Create multiple matching rules
        _ = try await ruleEngine.createRule(
            name: "Rule 1",
            merchantPattern: "coffee",
            category: "Dining & Restaurants",
            matchType: .contains,
            priority: 10
        )
        
        _ = try await ruleEngine.createRule(
            name: "Rule 2",
            merchantPattern: "coffee",
            category: "Entertainment",
            matchType: .contains,
            priority: 8
        )
        
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "debit"
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.merchant = "Coffee Shop"
        transaction.amount = 5.00 as NSDecimalNumber
        transaction.date = Date()
        transaction.account = account
        
        // Detect conflicts
        let conflicts = try await ruleEngine.detectConflicts(for: transaction)
        
        #expect(conflicts.count == 2)
    }
    
    func testBatchRuleApplication() async throws {
        // Create rule
        _ = try await ruleEngine.createRule(
            name: "Coffee Rule",
            merchantPattern: "coffee",
            category: "Dining & Restaurants",
            matchType: .contains,
            priority: 10
        )
        
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "debit"
        
        // Create multiple transactions
        var transactions: [Transaction] = []
        let merchants = ["Coffee Shop A", "Coffee Shop B", "Random Store", "Coffee House"]
        
        for merchant in merchants {
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.merchant = merchant
            transaction.amount = 5.00 as NSDecimalNumber
            transaction.date = Date()
            transaction.account = account
            transactions.append(transaction)
        }
        try context.save()
        
        // Apply rules to all transactions
        let result = try await ruleEngine.applyRulesToTransactions(transactions)
        
        #expect(result.appliedCount == 3) // 3 coffee shops
        #expect(result.skippedCount == 1) // 1 random store
        #expect(result.errors.isEmpty == true)
    }
    
    func testBatchApplicationWithConflicts() async throws {
        // Create conflicting rules
        _ = try await ruleEngine.createRule(
            name: "Rule 1",
            merchantPattern: "shop",
            category: "Shopping",
            matchType: .contains,
            priority: 10
        )
        
        _ = try await ruleEngine.createRule(
            name: "Rule 2",
            merchantPattern: "shop",
            category: "Groceries",
            matchType: .contains,
            priority: 5
        )
        
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "debit"
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.merchant = "Shop Store"
        transaction.amount = 25.00 as NSDecimalNumber
        transaction.date = Date()
        transaction.account = account
        try context.save()
        
        // Apply rules
        let result = try await ruleEngine.applyRulesToTransactions([transaction])
        
        #expect(result.appliedCount == 1)
        #expect(result.conflicts.count == 1)
        #expect(transaction.category == "Shopping") // Higher priority wins
    }
    
    // MARK: - Rule Management Tests
    
    func testUpdateRule() async throws {
        // Create rule
        let rule = try await ruleEngine.createRule(
            name: "Original Name",
            merchantPattern: "original",
            category: "Shopping",
            matchType: .contains,
            priority: 5
        )
        
        // Update rule
        try await ruleEngine.updateRule(
            rule,
            name: "Updated Name",
            merchantPattern: "updated",
            category: "Groceries",
            priority: 10
        )
        
        #expect(rule.name == "Updated Name")
        #expect(rule.merchantPattern == "updated")
        #expect(rule.category == "Groceries")
        #expect(rule.priority == 10)
    }
    
    func testDeleteRule() async throws {
        // Create rule
        let rule = try await ruleEngine.createRule(
            name: "Test Rule",
            merchantPattern: "test",
            category: "Other",
            matchType: .contains,
            priority: 5
        )
        
        let ruleId = rule.id
        
        // Delete rule
        try await ruleEngine.deleteRule(rule)
        
        // Verify deletion
        let fetchRequest: NSFetchRequest<CategorizationRule> = CategorizationRule.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", ruleId! as CVarArg)
        let results = try context.fetch(fetchRequest)
        
        #expect(results.isEmpty == true)
    }
    
    func testFetchActiveRulesOnly() async throws {
        // Create active and inactive rules
        let activeRule = try await ruleEngine.createRule(
            name: "Active Rule",
            merchantPattern: "active",
            category: "Shopping",
            matchType: .contains,
            priority: 10
        )
        
        let inactiveRule = try await ruleEngine.createRule(
            name: "Inactive Rule",
            merchantPattern: "inactive",
            category: "Other",
            matchType: .contains,
            priority: 5
        )
        
        try await ruleEngine.updateRule(inactiveRule, isActive: false)
        
        // Fetch active rules
        let activeRules = try await ruleEngine.fetchActiveRules()
        
        #expect(activeRules.count == 1)
        #expect(activeRules.first?.id == activeRule.id)
    }
    
    func testReorderRules() async throws {
        // Create multiple rules
        let rule1 = try await ruleEngine.createRule(
            name: "Rule 1",
            merchantPattern: "test1",
            category: "Shopping",
            matchType: .contains,
            priority: 1
        )
        
        let rule2 = try await ruleEngine.createRule(
            name: "Rule 2",
            merchantPattern: "test2",
            category: "Groceries",
            matchType: .contains,
            priority: 2
        )
        
        let rule3 = try await ruleEngine.createRule(
            name: "Rule 3",
            merchantPattern: "test3",
            category: "Dining & Restaurants",
            matchType: .contains,
            priority: 3
        )
        
        // Reorder: rule3, rule1, rule2
        try await ruleEngine.reorderRules([rule3, rule1, rule2])
        
        #expect(rule3.priority == 3)
        #expect(rule1.priority == 2)
        #expect(rule2.priority == 1)
    }
    
    // MARK: - Integration Tests
    
    func testRuleTakesPrecedenceOverLearning() async throws {
        let merchant = "Test Merchant"
        
        // Learn a category
        try await categoryService.learnFromCorrection(merchant: merchant, category: "Shopping")
        
        // Create a rule with higher priority
        _ = try await ruleEngine.createRule(
            name: "Override Rule",
            merchantPattern: merchant.lowercased(),
            category: "Groceries",
            matchType: .exact,
            priority: 10
        )
        
        // Categorize should use rule, not learned pattern
        let result = try await categoryService.categorize(merchant: merchant, amount: 10.00)
        
        #expect(result.category == "Groceries")
        #expect(result.matchType == .exactRule)
    }
    
    func testCategorizationPriorityOrder() async throws {
        let merchant = "Starbucks Coffee"
        
        // 1. Built-in pattern exists (Dining)
        let builtInResult = try await categoryService.categorize(merchant: merchant, amount: 5.00)
        #expect(builtInResult.category == "Dining & Restaurants")
        #expect(builtInResult.matchType == .patternMatch)
        
        // 2. Learn a different category (should override built-in)
        try await categoryService.learnFromCorrection(merchant: merchant, category: "Entertainment")
        let learnedResult = try await categoryService.categorize(merchant: merchant, amount: 5.00)
        #expect(learnedResult.category == "Entertainment")
        #expect(learnedResult.matchType == .learned)
        
        // 3. Create a rule (should override learned)
        _ = try await ruleEngine.createRule(
            name: "Starbucks Rule",
            merchantPattern: "starbucks",
            category: "Shopping",
            matchType: .contains,
            priority: 10
        )
        let ruleResult = try await categoryService.categorize(merchant: merchant, amount: 5.00)
        #expect(ruleResult.category == "Shopping")
        #expect(ruleResult.matchType == .exactRule)
    }
    
    func testSuggestedCategories() async throws {
        let merchant = "Coffee Place"
        
        // Learn pattern
        try await categoryService.learnFromCorrection(merchant: merchant, category: "Dining & Restaurants")
        
        // Get suggestions
        let suggestions = try await categoryService.getSuggestedCategories(for: merchant)
        
        #expect(suggestions.isEmpty == false)
        #expect(suggestions.first?.category == "Dining & Restaurants")
        #expect(suggestions.allSatisfy { $0.confidence > 0 } == true)
    }
}
