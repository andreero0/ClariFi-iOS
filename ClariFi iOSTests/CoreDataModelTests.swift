//
//  CoreDataModelTests.swift
//  ClariFi iOSTests
//
//  Created by aEro on 2025-10-10.
//

import Testing
import CoreData
@testable import ClariFi_iOS

struct CoreDataModelTests {
    
    let persistenceController: PersistenceController
    let context: NSManagedObjectContext
    
    init() throws {
        // Use in-memory store for testing
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
    }
    
    // MARK: - Core Data Model Relationship Tests
    
    @Test func accountTransactionRelationship() throws {
        // Create account
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "checking"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        // Create transactions
        let transaction1 = Transaction(context: context)
        transaction1.id = UUID()
        transaction1.date = Date()
        transaction1.merchant = "Store 1"
        transaction1.amount = NSDecimalNumber(value: 25.99)
        transaction1.currency = "USD"
        transaction1.category = "Shopping"
        transaction1.confidence = 0.95
        transaction1.isManual = false
        transaction1.createdAt = Date()
        transaction1.updatedAt = Date()
        transaction1.account = account
        
        let transaction2 = Transaction(context: context)
        transaction2.id = UUID()
        transaction2.date = Date()
        transaction2.merchant = "Store 2"
        transaction2.amount = NSDecimalNumber(value: 15.50)
        transaction2.currency = "USD"
        transaction2.category = "Food"
        transaction2.confidence = 0.88
        transaction2.isManual = true
        transaction2.createdAt = Date()
        transaction2.updatedAt = Date()
        transaction2.account = account
        
        try context.save()
        
        // Test relationship
        #expect(account.transactions?.count == 2)
        #expect(account.transactions?.contains(transaction1) == true)
        #expect(account.transactions?.contains(transaction2) == true)
        #expect(transaction1.account == account)
        #expect(transaction2.account == account)
    }
    
    @Test func budgetCategoryRelationship() throws {
        // Create budget
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        // Create categories
        let category1 = BudgetCategory(context: context)
        category1.id = UUID()
        category1.name = "Food"
        category1.budgetedAmount = NSDecimalNumber(value: 500.0)
        category1.spentAmount = NSDecimalNumber(value: 0.0)
        category1.rolloverEnabled = false
        category1.alertThreshold = 0.8
        category1.createdAt = Date()
        category1.updatedAt = Date()
        category1.budget = budget
        
        let category2 = BudgetCategory(context: context)
        category2.id = UUID()
        category2.name = "Transport"
        category2.budgetedAmount = NSDecimalNumber(value: 200.0)
        category2.spentAmount = NSDecimalNumber(value: 0.0)
        category2.rolloverEnabled = true
        category2.alertThreshold = 0.9
        category2.createdAt = Date()
        category2.updatedAt = Date()
        category2.budget = budget
        
        try context.save()
        
        // Test relationship
        #expect(budget.categories?.count == 2)
        #expect(budget.categories?.contains(category1) == true)
        #expect(budget.categories?.contains(category2) == true)
        #expect(category1.budget == budget)
        #expect(category2.budget == budget)
    }
    
    func testStatementTransactionRelationship() throws {
        // Create account
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "checking"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        // Create statement
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "test_statement.pdf"
        statement.uploadDate = Date()
        statement.fileHash = "abc123hash"
        statement.processingStatus = "completed"
        statement.fileSize = 2048
        statement.documentType = "pdf"
        statement.createdAt = Date()
        statement.updatedAt = Date()
        
        // Create transactions linked to statement
        let transaction1 = Transaction(context: context)
        transaction1.id = UUID()
        transaction1.date = Date()
        transaction1.merchant = "Statement Store 1"
        transaction1.amount = NSDecimalNumber(value: 45.99)
        transaction1.currency = "USD"
        transaction1.category = "Shopping"
        transaction1.confidence = 0.92
        transaction1.isManual = false
        transaction1.createdAt = Date()
        transaction1.updatedAt = Date()
        transaction1.account = account
        transaction1.statement = statement
        
        let transaction2 = Transaction(context: context)
        transaction2.id = UUID()
        transaction2.date = Date()
        transaction2.merchant = "Statement Store 2"
        transaction2.amount = NSDecimalNumber(value: 12.50)
        transaction2.currency = "USD"
        transaction2.category = "Food"
        transaction2.confidence = 0.85
        transaction2.isManual = false
        transaction2.createdAt = Date()
        transaction2.updatedAt = Date()
        transaction2.account = account
        transaction2.statement = statement
        
        try context.save()
        
        // Test relationship
        XCTAssertEqual(statement.transactions?.count, 2)
        XCTAssertTrue(statement.transactions?.contains(transaction1) ?? false)
        XCTAssertTrue(statement.transactions?.contains(transaction2) ?? false)
        XCTAssertEqual(transaction1.statement, statement)
        XCTAssertEqual(transaction2.statement, statement)
    }
    
    // MARK: - Cascade Delete Tests
    
    func testAccountDeletionCascadesToTransactions() throws {
        // Create account with transactions
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Account to Delete"
        account.type = "checking"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = "Test Store"
        transaction.amount = NSDecimalNumber(value: 25.99)
        transaction.currency = "USD"
        transaction.category = "Shopping"
        transaction.confidence = 0.95
        transaction.isManual = false
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.account = account
        
        try context.save()
        
        let transactionId = transaction.id!
        
        // Delete account
        context.delete(account)
        try context.save()
        
        // Verify transaction was cascade deleted
        let fetchRequest = NSFetchRequest<Transaction>(entityName: "Transaction")
        fetchRequest.predicate = NSPredicate(format: "id == %@", transactionId as CVarArg)
        let remainingTransactions = try context.fetch(fetchRequest)
        
        XCTAssertTrue(remainingTransactions.isEmpty, "Transaction should be cascade deleted when account is deleted")
    }
    
    func testBudgetDeletionCascadesToCategories() throws {
        // Create budget with categories
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Budget to Delete"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        let category = BudgetCategory(context: context)
        category.id = UUID()
        category.name = "Category to Delete"
        category.budgetedAmount = NSDecimalNumber(value: 500.0)
        category.spentAmount = NSDecimalNumber(value: 0.0)
        category.rolloverEnabled = false
        category.alertThreshold = 0.8
        category.createdAt = Date()
        category.updatedAt = Date()
        category.budget = budget
        
        try context.save()
        
        let categoryId = category.id!
        
        // Delete budget
        context.delete(budget)
        try context.save()
        
        // Verify category was cascade deleted
        let fetchRequest = NSFetchRequest<BudgetCategory>(entityName: "BudgetCategory")
        fetchRequest.predicate = NSPredicate(format: "id == %@", categoryId as CVarArg)
        let remainingCategories = try context.fetch(fetchRequest)
        
        XCTAssertTrue(remainingCategories.isEmpty, "Budget category should be cascade deleted when budget is deleted")
    }
    
    func testStatementDeletionCascadesToTransactions() throws {
        // Create account
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "checking"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        // Create statement with transactions
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "statement_to_delete.pdf"
        statement.uploadDate = Date()
        statement.fileHash = "delete_hash"
        statement.processingStatus = "completed"
        statement.fileSize = 1024
        statement.documentType = "pdf"
        statement.createdAt = Date()
        statement.updatedAt = Date()
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = "Statement Store"
        transaction.amount = NSDecimalNumber(value: 35.99)
        transaction.currency = "USD"
        transaction.category = "Shopping"
        transaction.confidence = 0.90
        transaction.isManual = false
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.account = account
        transaction.statement = statement
        
        try context.save()
        
        let transactionId = transaction.id!
        
        // Delete statement
        context.delete(statement)
        try context.save()
        
        // Verify transaction was cascade deleted
        let fetchRequest = NSFetchRequest<Transaction>(entityName: "Transaction")
        fetchRequest.predicate = NSPredicate(format: "id == %@", transactionId as CVarArg)
        let remainingTransactions = try context.fetch(fetchRequest)
        
        XCTAssertTrue(remainingTransactions.isEmpty, "Transaction should be cascade deleted when statement is deleted")
    }
    
    // MARK: - Uniqueness Constraint Tests
    
    func testTransactionUniqueIdConstraint() throws {
        let sharedId = UUID()
        
        // Create first transaction
        let transaction1 = Transaction(context: context)
        transaction1.id = sharedId
        transaction1.date = Date()
        transaction1.merchant = "Store 1"
        transaction1.amount = NSDecimalNumber(value: 25.99)
        transaction1.currency = "USD"
        transaction1.category = "Shopping"
        transaction1.confidence = 0.95
        transaction1.isManual = false
        transaction1.createdAt = Date()
        transaction1.updatedAt = Date()
        
        // Create account for transaction
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "checking"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        transaction1.account = account
        
        try context.save()
        
        // Try to create second transaction with same ID
        let transaction2 = Transaction(context: context)
        transaction2.id = sharedId // Same ID - should violate constraint
        transaction2.date = Date()
        transaction2.merchant = "Store 2"
        transaction2.amount = NSDecimalNumber(value: 15.50)
        transaction2.currency = "USD"
        transaction2.category = "Food"
        transaction2.confidence = 0.88
        transaction2.isManual = true
        transaction2.createdAt = Date()
        transaction2.updatedAt = Date()
        transaction2.account = account
        
        // Should throw constraint violation error
        XCTAssertThrowsError(try context.save()) { error in
            XCTAssertTrue(error is NSError)
            let nsError = error as! NSError
            XCTAssertTrue(nsError.domain.contains("SQLite") || nsError.code == 133) // Constraint violation
        }
    }
    
    func testStatementUniqueHashConstraint() throws {
        let sharedHash = "duplicate_hash_123"
        
        // Create first statement
        let statement1 = Statement(context: context)
        statement1.id = UUID()
        statement1.fileName = "statement1.pdf"
        statement1.uploadDate = Date()
        statement1.fileHash = sharedHash
        statement1.processingStatus = "completed"
        statement1.fileSize = 1024
        statement1.documentType = "pdf"
        statement1.createdAt = Date()
        statement1.updatedAt = Date()
        
        try context.save()
        
        // Try to create second statement with same hash
        let statement2 = Statement(context: context)
        statement2.id = UUID()
        statement2.fileName = "statement2.pdf"
        statement2.uploadDate = Date()
        statement2.fileHash = sharedHash // Same hash - should violate constraint
        statement2.processingStatus = "pending"
        statement2.fileSize = 2048
        statement2.documentType = "pdf"
        statement2.createdAt = Date()
        statement2.updatedAt = Date()
        
        // Should throw constraint violation error
        let error = #expect(throws: (any Error).self) { try context.save() }
        #expect(error is NSError)
        let nsError = error as! NSError
        #expect(nsError.domain.contains("SQLite") || nsError.code == 133) // Constraint violation
    }
    
    // MARK: - Data Integrity Tests
    
    func testTimestampAutomaticUpdates() throws {
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Timestamp Test Account"
        account.type = "checking"
        account.isActive = true
        
        let beforeSave = Date()
        account.createdAt = beforeSave
        account.updatedAt = beforeSave
        
        try context.save()
        
        // Verify timestamps are set
        XCTAssertNotNil(account.createdAt)
        XCTAssertNotNil(account.updatedAt)
        XCTAssertEqual(account.createdAt, beforeSave)
        XCTAssertEqual(account.updatedAt, beforeSave)
        
        // Update account
        let beforeUpdate = Date()
        account.name = "Updated Account Name"
        account.updatedAt = beforeUpdate
        
        try context.save()
        
        // Verify updatedAt changed but createdAt didn't
        XCTAssertEqual(account.createdAt, beforeSave)
        XCTAssertEqual(account.updatedAt, beforeUpdate)
    }
    
    func testDecimalPrecisionForAmounts() throws {
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Precision Test Account"
        account.type = "checking"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        // Test high precision decimal
        let preciseAmount = NSDecimalNumber(string: "123.456789")
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = "Precision Store"
        transaction.amount = preciseAmount
        transaction.currency = "USD"
        transaction.category = "Shopping"
        transaction.confidence = 0.95
        transaction.isManual = false
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.account = account
        
        try context.save()
        
        // Fetch and verify precision is maintained
        let fetchRequest = NSFetchRequest<Transaction>(entityName: "Transaction")
        fetchRequest.predicate = NSPredicate(format: "id == %@", transaction.id! as CVarArg)
        let fetchedTransactions = try context.fetch(fetchRequest)
        
        XCTAssertEqual(fetchedTransactions.count, 1)
        let fetchedTransaction = fetchedTransactions.first!
        XCTAssertEqual(fetchedTransaction.amount, preciseAmount)
        XCTAssertEqual(fetchedTransaction.amount?.stringValue, "123.456789")
    }
    
    // MARK: - Performance Tests
    
    func testBatchInsertPerformance() throws {
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Performance Test Account"
        account.type = "checking"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        try context.save()
        
        // Measure time to insert 1000 transactions
        // Note: Swift Testing doesn't have measure, so we'll just run the test
        do {
            for i in 0..<1000 {
                let transaction = Transaction(context: context)
                transaction.id = UUID()
                transaction.date = Date()
                transaction.merchant = "Store \(i)"
                transaction.amount = NSDecimalNumber(value: Double(i) * 1.99)
                transaction.currency = "USD"
                transaction.category = "Shopping"
                transaction.confidence = 0.95
                transaction.isManual = false
                transaction.createdAt = Date()
                transaction.updatedAt = Date()
                transaction.account = account
            }
            
            do {
                try context.save()
            } catch {
                Issue.record("Batch insert failed: \(error)")
            }
        }
    }
    
    func testLargeFetchPerformance() throws {
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Fetch Test Account"
        account.type = "checking"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        // Create 500 transactions
        for i in 0..<500 {
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.date = Date().addingTimeInterval(TimeInterval(-i * 3600)) // Spread over time
            transaction.merchant = "Store \(i)"
            transaction.amount = NSDecimalNumber(value: Double(i) * 2.50)
            transaction.currency = "USD"
            transaction.category = i % 2 == 0 ? "Shopping" : "Food"
            transaction.confidence = 0.95
            transaction.isManual = false
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
            transaction.account = account
        }
        
        try context.save()
        
        // Measure fetch performance
        // Note: Swift Testing doesn't have measure, so we'll just run the test
        let fetchRequest = NSFetchRequest<Transaction>(entityName: "Transaction")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            let transactions = try context.fetch(fetchRequest)
            #expect(transactions.count == 500)
        } catch {
            Issue.record("Fetch failed: \(error)")
        }
    }
}