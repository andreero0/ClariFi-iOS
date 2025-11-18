//
//  DataValidationTests.swift
//  ClariFi iOS Tests
//
//  Created by aEro on 2025-10-10.
//

import Testing
import CoreData
@testable import ClariFi_iOS

struct DataValidationTests {
    
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    
    init() throws {
        
        // Use in-memory store for testing
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
    }
    
    
    // MARK: - Helper Methods
    
    private func createValidAccount() -> Account {
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Valid Account"
        account.type = "checking"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        return account
    }
    
    // MARK: - Transaction Validation Tests
    
    func testTransactionValidation_ValidTransaction() throws {
        let account = createValidAccount()
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = "Valid Store"
        transaction.amount = NSDecimalNumber(value: 25.99)
        transaction.currency = "USD"
        transaction.category = "Shopping"
        transaction.confidence = 0.95
        transaction.isManual = false
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.account = account
        
        // Should not throw any validation errors
        XCTAssertNoThrow(try transaction.validateForInsert())
        XCTAssertNoThrow(try context.save())
    }
    
    func testTransactionValidation_EmptyMerchant() {
        let account = createValidAccount()
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = "" // Invalid empty merchant
        transaction.amount = NSDecimalNumber(value: 25.99)
        transaction.currency = "USD"
        transaction.category = "Shopping"
        transaction.confidence = 0.95
        transaction.isManual = false
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.account = account
        
        XCTAssertThrowsError(try transaction.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.invalidMerchant)
            }
        }
    }
    
    func testTransactionValidation_WhitespaceOnlyMerchant() {
        let account = createValidAccount()
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = "   \n\t   " // Only whitespace
        transaction.amount = NSDecimalNumber(value: 25.99)
        transaction.currency = "USD"
        transaction.category = "Shopping"
        transaction.confidence = 0.95
        transaction.isManual = false
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.account = account
        
        XCTAssertThrowsError(try transaction.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.invalidMerchant)
            }
        }
    }
    
    func testTransactionValidation_ZeroAmount() {
        let account = createValidAccount()
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = "Valid Store"
        transaction.amount = NSDecimalNumber.zero // Invalid zero amount
        transaction.currency = "USD"
        transaction.category = "Shopping"
        transaction.confidence = 0.95
        transaction.isManual = false
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.account = account
        
        XCTAssertThrowsError(try transaction.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.invalidAmount)
            }
        }
    }
    
    func testTransactionValidation_NegativeAmount() {
        let account = createValidAccount()
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = "Valid Store"
        transaction.amount = NSDecimalNumber(value: -25.99) // Negative amount should be valid for refunds
        transaction.currency = "USD"
        transaction.category = "Shopping"
        transaction.confidence = 0.95
        transaction.isManual = false
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.account = account
        
        // Negative amounts should be allowed (for refunds, returns, etc.)
        XCTAssertNoThrow(try transaction.validateForInsert())
    }
    
    func testTransactionValidation_InvalidConfidenceScore() {
        let account = createValidAccount()
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = "Valid Store"
        transaction.amount = NSDecimalNumber(value: 25.99)
        transaction.currency = "USD"
        transaction.category = "Shopping"
        transaction.confidence = 1.5 // Invalid confidence > 1.0
        transaction.isManual = false
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.account = account
        
        XCTAssertThrowsError(try transaction.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.invalidConfidence)
            }
        }
    }
    
    func testTransactionValidation_FutureDate() {
        let account = createValidAccount()
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date().addingTimeInterval(2 * 24 * 60 * 60) // 2 days in future
        transaction.merchant = "Valid Store"
        transaction.amount = NSDecimalNumber(value: 25.99)
        transaction.currency = "USD"
        transaction.category = "Shopping"
        transaction.confidence = 0.95
        transaction.isManual = false
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.account = account
        
        XCTAssertThrowsError(try transaction.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.futureDate)
            }
        }
    }
    
    func testTransactionValidation_MerchantTooLong() {
        let account = createValidAccount()
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = String(repeating: "A", count: 101) // 101 characters, exceeds 100 limit
        transaction.amount = NSDecimalNumber(value: 25.99)
        transaction.currency = "USD"
        transaction.category = "Shopping"
        transaction.confidence = 0.95
        transaction.isManual = false
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.account = account
        
        XCTAssertThrowsError(try transaction.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.merchantTooLong)
            }
        }
    }
    
    func testTransactionValidation_NotesTooLong() {
        let account = createValidAccount()
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = "Valid Store"
        transaction.amount = NSDecimalNumber(value: 25.99)
        transaction.currency = "USD"
        transaction.category = "Shopping"
        transaction.confidence = 0.95
        transaction.isManual = false
        transaction.notes = String(repeating: "N", count: 501) // 501 characters, exceeds 500 limit
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.account = account
        
        XCTAssertThrowsError(try transaction.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.notesTooLong)
            }
        }
    }
    
    // MARK: - Account Validation Tests
    
    func testAccountValidation_ValidAccount() throws {
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Valid Account"
        account.type = "checking"
        account.lastFourDigits = "1234"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        XCTAssertNoThrow(try account.validateForInsert())
        XCTAssertNoThrow(try context.save())
    }
    
    func testAccountValidation_EmptyName() {
        let account = Account(context: context)
        account.id = UUID()
        account.name = "" // Invalid empty name
        account.type = "checking"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        XCTAssertThrowsError(try account.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.invalidAccountName)
            }
        }
    }
    
    func testAccountValidation_InvalidType() {
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Valid Account"
        account.type = "invalid_type" // Invalid account type
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        XCTAssertThrowsError(try account.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.invalidAccountType)
            }
        }
    }
    
    func testAccountValidation_ValidAccountTypes() throws {
        let validTypes = ["checking", "savings", "credit", "debit", "cash", "investment"]
        
        for accountType in validTypes {
            let account = Account(context: context)
            account.id = UUID()
            account.name = "Valid \(accountType.capitalized) Account"
            account.type = accountType
            account.isActive = true
            account.createdAt = Date()
            account.updatedAt = Date()
            
            XCTAssertNoThrow(try account.validateForInsert(), "Account type '\(accountType)' should be valid")
        }
    }
    
    func testAccountValidation_InvalidLastFourDigits() {
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Valid Account"
        account.type = "checking"
        account.lastFourDigits = "12A4" // Invalid - contains letter
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        XCTAssertThrowsError(try account.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.invalidLastFourDigits)
            }
        }
    }
    
    func testAccountValidation_LastFourDigitsTooShort() {
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Valid Account"
        account.type = "checking"
        account.lastFourDigits = "123" // Invalid - only 3 digits
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        XCTAssertThrowsError(try account.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.invalidLastFourDigits)
            }
        }
    }
    
    // MARK: - Budget Validation Tests
    
    func testBudgetValidation_ValidBudget() throws {
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Valid Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        XCTAssertNoThrow(try budget.validateForInsert())
        XCTAssertNoThrow(try context.save())
    }
    
    func testBudgetValidation_EmptyName() {
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "" // Invalid empty name
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        XCTAssertThrowsError(try budget.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.invalidBudgetName)
            }
        }
    }
    
    func testBudgetValidation_InvalidPeriod() {
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Valid Budget"
        budget.period = "invalid_period" // Invalid period
        budget.startDate = Date()
        budget.isActive = true
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        XCTAssertThrowsError(try budget.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.invalidBudgetPeriod)
            }
        }
    }
    
    func testBudgetValidation_ValidPeriods() throws {
        let validPeriods = ["weekly", "monthly", "yearly"]
        
        for period in validPeriods {
            let budget = Budget(context: context)
            budget.id = UUID()
            budget.name = "Valid \(period.capitalized) Budget"
            budget.period = period
            budget.startDate = Date()
            budget.isActive = true
            budget.rolloverEnabled = false
            budget.createdAt = Date()
            budget.updatedAt = Date()
            
            XCTAssertNoThrow(try budget.validateForInsert(), "Budget period '\(period)' should be valid")
        }
    }
    
    func testBudgetValidation_StartDateTooFarInFuture() {
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Valid Budget"
        budget.period = "monthly"
        budget.startDate = Date().addingTimeInterval(2 * 365 * 24 * 60 * 60) // 2 years in future
        budget.isActive = true
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        XCTAssertThrowsError(try budget.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.startDateTooFarInFuture)
            }
        }
    }
    
    // MARK: - Budget Category Validation Tests
    
    func testBudgetCategoryValidation_ValidCategory() throws {
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        let category = BudgetCategory(context: context)
        category.id = UUID()
        category.name = "Valid Category"
        category.budgetedAmount = NSDecimalNumber(value: 500.0)
        category.spentAmount = NSDecimalNumber(value: 0.0)
        category.rolloverEnabled = false
        category.alertThreshold = 0.8
        category.createdAt = Date()
        category.updatedAt = Date()
        category.budget = budget
        
        XCTAssertNoThrow(try category.validateForInsert())
        XCTAssertNoThrow(try context.save())
    }
    
    func testBudgetCategoryValidation_InvalidBudgetedAmount() {
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        let category = BudgetCategory(context: context)
        category.id = UUID()
        category.name = "Valid Category"
        category.budgetedAmount = NSDecimalNumber.zero // Invalid - must be > 0
        category.spentAmount = NSDecimalNumber(value: 0.0)
        category.rolloverEnabled = false
        category.alertThreshold = 0.8
        category.createdAt = Date()
        category.updatedAt = Date()
        category.budget = budget
        
        XCTAssertThrowsError(try category.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.invalidBudgetedAmount)
            }
        }
    }
    
    func testBudgetCategoryValidation_NegativeSpentAmount() {
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        let category = BudgetCategory(context: context)
        category.id = UUID()
        category.name = "Valid Category"
        category.budgetedAmount = NSDecimalNumber(value: 500.0)
        category.spentAmount = NSDecimalNumber(value: -10.0) // Invalid negative spent amount
        category.rolloverEnabled = false
        category.alertThreshold = 0.8
        category.createdAt = Date()
        category.updatedAt = Date()
        category.budget = budget
        
        XCTAssertThrowsError(try category.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.invalidSpentAmount)
            }
        }
    }
    
    func testBudgetCategoryValidation_InvalidAlertThreshold() {
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        let category = BudgetCategory(context: context)
        category.id = UUID()
        category.name = "Valid Category"
        category.budgetedAmount = NSDecimalNumber(value: 500.0)
        category.spentAmount = NSDecimalNumber(value: 0.0)
        category.rolloverEnabled = false
        category.alertThreshold = 1.5 // Invalid - must be <= 1.0
        category.createdAt = Date()
        category.updatedAt = Date()
        category.budget = budget
        
        XCTAssertThrowsError(try category.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.invalidAlertThreshold)
            }
        }
    }
    
    // MARK: - Statement Validation Tests
    
    func testStatementValidation_ValidStatement() throws {
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "valid_statement.pdf"
        statement.uploadDate = Date()
        statement.fileHash = "valid_hash_123"
        statement.processingStatus = "completed"
        statement.fileSize = 2048
        statement.documentType = "pdf"
        statement.createdAt = Date()
        statement.updatedAt = Date()
        
        XCTAssertNoThrow(try statement.validateForInsert())
        XCTAssertNoThrow(try context.save())
    }
    
    func testStatementValidation_EmptyFileName() {
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "" // Invalid empty filename
        statement.uploadDate = Date()
        statement.fileHash = "valid_hash_123"
        statement.processingStatus = "completed"
        statement.fileSize = 2048
        statement.documentType = "pdf"
        statement.createdAt = Date()
        statement.updatedAt = Date()
        
        XCTAssertThrowsError(try statement.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.invalidFileName)
            }
        }
    }
    
    func testStatementValidation_InvalidProcessingStatus() {
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "valid_statement.pdf"
        statement.uploadDate = Date()
        statement.fileHash = "valid_hash_123"
        statement.processingStatus = "invalid_status" // Invalid status
        statement.fileSize = 2048
        statement.documentType = "pdf"
        statement.createdAt = Date()
        statement.updatedAt = Date()
        
        XCTAssertThrowsError(try statement.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.invalidProcessingStatus)
            }
        }
    }
    
    func testStatementValidation_ValidProcessingStatuses() throws {
        let validStatuses = ["pending", "processing", "completed", "failed", "cancelled"]
        
        for status in validStatuses {
            let statement = Statement(context: context)
            statement.id = UUID()
            statement.fileName = "statement_\(status).pdf"
            statement.uploadDate = Date()
            statement.fileHash = "hash_\(status)_123"
            statement.processingStatus = status
            statement.fileSize = 2048
            statement.documentType = "pdf"
            statement.createdAt = Date()
            statement.updatedAt = Date()
            
            XCTAssertNoThrow(try statement.validateForInsert(), "Processing status '\(status)' should be valid")
        }
    }
    
    func testStatementValidation_InvalidDocumentType() {
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "valid_statement.txt"
        statement.uploadDate = Date()
        statement.fileHash = "valid_hash_123"
        statement.processingStatus = "completed"
        statement.fileSize = 2048
        statement.documentType = "txt" // Invalid document type
        statement.createdAt = Date()
        statement.updatedAt = Date()
        
        XCTAssertThrowsError(try statement.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.invalidDocumentType)
            }
        }
    }
    
    func testStatementValidation_ValidDocumentTypes() throws {
        let validTypes = ["pdf", "jpg", "jpeg", "png", "heic"]
        
        for docType in validTypes {
            let statement = Statement(context: context)
            statement.id = UUID()
            statement.fileName = "statement.\(docType)"
            statement.uploadDate = Date()
            statement.fileHash = "hash_\(docType)_123"
            statement.processingStatus = "completed"
            statement.fileSize = 2048
            statement.documentType = docType
            statement.createdAt = Date()
            statement.updatedAt = Date()
            
            XCTAssertNoThrow(try statement.validateForInsert(), "Document type '\(docType)' should be valid")
        }
    }
    
    func testStatementValidation_FutureUploadDate() {
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "valid_statement.pdf"
        statement.uploadDate = Date().addingTimeInterval(2 * 60 * 60) // 2 hours in future
        statement.fileHash = "valid_hash_123"
        statement.processingStatus = "completed"
        statement.fileSize = 2048
        statement.documentType = "pdf"
        statement.createdAt = Date()
        statement.updatedAt = Date()
        
        XCTAssertThrowsError(try statement.validateForInsert()) { error in
            #expect(error is ValidationError == true)
            if let validationError = error as? ValidationError {
                #expect(validationError == ValidationError.futureUploadDate)
            }
        }
    }
}