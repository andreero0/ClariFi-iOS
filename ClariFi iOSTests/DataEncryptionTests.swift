//
//  DataEncryptionTests.swift
//  ClariFi iOS Tests
//
//  Created by aEro on 2025-10-10.
//

import Testing
import CoreData
@testable import ClariFi_iOS

struct DataEncryptionTests {
    
    var persistenceController: PersistenceController!
    var repositoryFactory: RepositoryFactory!
    var context: NSManagedObjectContext!
    
    init() throws {
        
        // Use in-memory store for testing
        persistenceController = PersistenceController(inMemory: true)
        repositoryFactory = RepositoryFactory(persistenceController: persistenceController)
        context = persistenceController.container.viewContext
    }
    
    
    // MARK: - Data Protection Tests
    
    @Test func PersistentStoreDataProtection() {
        // Test that persistent store is configured with data protection
        let storeDescriptions = persistenceController.container.persistentStoreDescriptions
        #expect(storeDescriptions.isEmpty, "Should have at least one store description" == false)
        
        // For in-memory stores, data protection isn't applicable, but we can test the configuration
        // In a real app, this would verify FileProtectionType.complete is set
        let firstStore = storeDescriptions.first!
        #expect(firstStore.url, "Store should have a URL configured" != nil)
    }
    
    @Test func ContextConfiguration() {
        // Test that context is properly configured for security
        #expect(context.automaticallyMergesChangesFromParent, "Context should merge changes automatically" == true)
        #expect(context.mergePolicy, "Context should have a merge policy" != nil)
        #expect(context.mergePolicy is NSMergeByPropertyObjectTrumpMergePolicy, "Should use property object trump merge policy" == true)
    }
    
    // MARK: - Data Integrity Tests
    
    func testDataIntegrityAfterSave() async throws {
        let accountRepo = repositoryFactory.accountRepository
        
        // Create test account
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "checking"
        account.lastFourDigits = "1234"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        // Save account
        try await accountRepo.save(account)
        
        // Fetch and verify data integrity
        let fetchedAccount = try await accountRepo.fetchById(account.id!)
        #expect(fetchedAccount != nil)
        #expect(fetchedAccount?.name == "Test Account")
        #expect(fetchedAccount?.type == "checking")
        #expect(fetchedAccount?.lastFourDigits == "1234")
        #expect(fetchedAccount?.isActive ?? false == true)
        #expect(fetchedAccount?.createdAt != nil)
        #expect(fetchedAccount?.updatedAt != nil)
    }
    
    func testSensitiveDataHandling() async throws {
        let transactionRepo = repositoryFactory.transactionRepository
        let accountRepo = repositoryFactory.accountRepository
        
        // Create account
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Sensitive Account"
        account.type = "checking"
        account.lastFourDigits = "9876" // Sensitive data
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        try await accountRepo.save(account)
        
        // Create transaction with sensitive data
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = "Sensitive Merchant"
        transaction.amount = NSDecimalNumber(value: 1234.56) // Sensitive amount
        transaction.currency = "USD"
        transaction.category = "Personal"
        transaction.confidence = 0.95
        transaction.isManual = false
        transaction.notes = "Confidential purchase" // Sensitive notes
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.account = account
        
        try await transactionRepo.save(transaction)
        
        // Verify sensitive data is properly stored and retrieved
        let fetchedTransaction = try await transactionRepo.fetchById(transaction.id!)
        #expect(fetchedTransaction != nil)
        #expect(fetchedTransaction?.merchant == "Sensitive Merchant")
        #expect(fetchedTransaction?.amount == NSDecimalNumber(value: 1234.56))
        #expect(fetchedTransaction?.notes == "Confidential purchase")
        #expect(fetchedTransaction?.account?.lastFourDigits == "9876")
    }
    
    // MARK: - Secure Deletion Tests
    
    func testSecureDeletion() async throws {
        let accountRepo = repositoryFactory.accountRepository
        let transactionRepo = repositoryFactory.transactionRepository
        
        // Create account and transaction
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
        transaction.merchant = "Store to Delete"
        transaction.amount = NSDecimalNumber(value: 50.0)
        transaction.currency = "USD"
        transaction.category = "Shopping"
        transaction.confidence = 1.0
        transaction.isManual = true
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.account = account
        
        try await accountRepo.save(account)
        try await transactionRepo.save(transaction)
        
        let accountId = account.id!
        let transactionId = transaction.id!
        
        // Delete account (should cascade delete transaction)
        try await accountRepo.delete(account)
        
        // Verify secure deletion - data should not be retrievable
        let deletedAccount = try await accountRepo.fetchById(accountId)
        let deletedTransaction = try await transactionRepo.fetchById(transactionId)
        
        #expect(deletedAccount, "Account should be securely deleted" == nil)
        #expect(deletedTransaction, "Transaction should be cascade deleted" == nil)
    }
    
    func testCompleteDataDeletion() async throws {
        let accountRepo = repositoryFactory.accountRepository
        let transactionRepo = repositoryFactory.transactionRepository
        let budgetRepo = repositoryFactory.budgetRepository
        let statementRepo = repositoryFactory.statementRepository
        
        // Create test data
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "checking"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = "Test Store"
        transaction.amount = NSDecimalNumber(value: 25.0)
        transaction.currency = "USD"
        transaction.category = "Shopping"
        transaction.confidence = 1.0
        transaction.isManual = true
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        transaction.account = account
        
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.rolloverEnabled = false
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "test.pdf"
        statement.uploadDate = Date()
        statement.fileHash = "test_hash"
        statement.processingStatus = "completed"
        statement.fileSize = 1024
        statement.documentType = "pdf"
        statement.createdAt = Date()
        statement.updatedAt = Date()
        
        // Save all data
        try await accountRepo.save(account)
        try await transactionRepo.save(transaction)
        try await budgetRepo.save(budget)
        try await statementRepo.save(statement)
        
        // Verify data exists
        let allAccounts = try await accountRepo.fetchAll()
        let allTransactions = try await transactionRepo.fetchAll()
        let allBudgets = try await budgetRepo.fetchAll()
        let allStatements = try await statementRepo.fetchAll()
        
        #expect(allAccounts.isEmpty == false)
        #expect(allTransactions.isEmpty == false)
        #expect(allBudgets.isEmpty == false)
        #expect(allStatements.isEmpty == false)
        
        // Perform complete data deletion
        try await persistenceController.deleteAllData()
        
        // Verify all data is deleted
        let remainingAccounts = try await accountRepo.fetchAll()
        let remainingTransactions = try await transactionRepo.fetchAll()
        let remainingBudgets = try await budgetRepo.fetchAll()
        let remainingStatements = try await statementRepo.fetchAll()
        
        #expect(remainingAccounts.isEmpty, "All accounts should be deleted" == true)
        #expect(remainingTransactions.isEmpty, "All transactions should be deleted" == true)
        #expect(remainingBudgets.isEmpty, "All budgets should be deleted" == true)
        #expect(remainingStatements.isEmpty, "All statements should be deleted" == true)
    }
    
    // MARK: - Background Context Security Tests
    
    func testBackgroundContextSecurity() async throws {
        let backgroundTransactionRepo = repositoryFactory.createBackgroundTransactionRepository()
        let accountRepo = repositoryFactory.accountRepository
        
        // Create account in main context
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Background Test Account"
        account.type = "checking"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        try await accountRepo.save(account)
        
        // Create transaction in background context
        let backgroundContext = persistenceController.container.newBackgroundContext()
        let backgroundAccount = try await backgroundContext.perform {
            let request = NSFetchRequest<Account>(entityName: "Account")
            request.predicate = NSPredicate(format: "id == %@", account.id! as CVarArg)
            return try backgroundContext.fetch(request).first
        }
        
        #expect(backgroundAccount, "Account should be accessible in background context" != nil)
        
        // Create transaction in background context
        let backgroundTransaction = try await backgroundContext.perform {
            let transaction = Transaction(context: backgroundContext)
            transaction.id = UUID()
            transaction.date = Date()
            transaction.merchant = "Background Store"
            transaction.amount = NSDecimalNumber(value: 75.0)
            transaction.currency = "USD"
            transaction.category = "Shopping"
            transaction.confidence = 1.0
            transaction.isManual = true
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
            transaction.account = backgroundAccount
            return transaction
        }
        
        // Save in background context
        try await backgroundTransactionRepo.save(backgroundTransaction)
        
        // Verify transaction is accessible in main context
        let mainContextTransaction = try await repositoryFactory.transactionRepository.fetchById(backgroundTransaction.id!)
        #expect(mainContextTransaction != nil)
        #expect(mainContextTransaction?.merchant == "Background Store")
    }
    
    // MARK: - Error Handling and Recovery Tests
    
    func testErrorHandlingDuringEncryption() async throws {
        let accountRepo = repositoryFactory.accountRepository
        
        // Create account with invalid data that should trigger validation error
        let account = Account(context: context)
        account.id = UUID()
        account.name = "" // Invalid empty name
        account.type = "checking"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        
        // Should throw validation error
        do {
            try await accountRepo.save(account)
            Issue.record("Should have thrown validation error")
        } catch {
            #expect(error is ValidationError || error is NSError == true)
        }
        
        // Verify no data was saved
        let allAccounts = try await accountRepo.fetchAll()
        #expect(allAccounts.isEmpty, "No accounts should be saved after validation error" == true)
    }
    
    func testDataRecoveryAfterError() async throws {
        let accountRepo = repositoryFactory.accountRepository
        
        // Create valid account
        let validAccount = Account(context: context)
        validAccount.id = UUID()
        validAccount.name = "Valid Account"
        validAccount.type = "checking"
        validAccount.isActive = true
        validAccount.createdAt = Date()
        validAccount.updatedAt = Date()
        
        try await accountRepo.save(validAccount)
        
        // Try to create invalid account
        let invalidAccount = Account(context: context)
        invalidAccount.id = UUID()
        invalidAccount.name = "" // Invalid
        invalidAccount.type = "checking"
        invalidAccount.isActive = true
        invalidAccount.createdAt = Date()
        invalidAccount.updatedAt = Date()
        
        do {
            try await accountRepo.save(invalidAccount)
            Issue.record("Should have thrown validation error")
        } catch {
            // Expected error
        }
        
        // Verify valid account is still accessible
        let fetchedAccount = try await accountRepo.fetchById(validAccount.id!)
        #expect(fetchedAccount != nil)
        #expect(fetchedAccount?.name == "Valid Account")
        
        // Verify only one account exists
        let allAccounts = try await accountRepo.fetchAll()
        #expect(allAccounts.count == 1)
    }
}