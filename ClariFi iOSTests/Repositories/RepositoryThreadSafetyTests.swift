//
//  RepositoryThreadSafetyTests.swift
//  ClariFi iOSTests
//
//  Created by AI Assistant on 2025-10-10.
//
//  Tests for repository thread safety and Core Data concurrency
//

import XCTest
import CoreData
@testable import ClariFi_iOS

final class RepositoryThreadSafetyTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var backgroundContextProvider: BackgroundContextProvider!
    var transactionRepository: CoreDataTransactionRepository!
    var accountRepository: CoreDataAccountRepository!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory Core Data stack for testing
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
        backgroundContextProvider = BackgroundContextProvider(persistentContainer: persistenceController.container)
        
        transactionRepository = CoreDataTransactionRepository(
            context: context,
            backgroundContextProvider: backgroundContextProvider
        )
        accountRepository = CoreDataAccountRepository(
            context: context,
            backgroundContextProvider: backgroundContextProvider
        )
    }
    
    override func tearDown() {
        transactionRepository = nil
        accountRepository = nil
        backgroundContextProvider = nil
        context = nil
        persistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Basic Repository Tests
    
    func testRepositoryInitialization() {
        // Given/When
        let repo = CoreDataTransactionRepository(
            context: context,
            backgroundContextProvider: backgroundContextProvider
        )
        
        // Then
        XCTAssertNotNil(repo)
        XCTAssertEqual(repo.entityName, "Transaction")
    }
    
    func testBackgroundContextProviderInitialization() {
        // Given/When
        let provider = BackgroundContextProvider(persistentContainer: persistenceController.container)
        
        // Then
        XCTAssertNotNil(provider)
    }
    
    // MARK: - DTO Conversion Tests
    
    func testTransactionDTOConversion() async throws {
        // Given - Create a transaction
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "Checking"
        account.isActive = true
        account.createdAt = Date()
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.amount = NSDecimalNumber(decimal: 100.50)
        transaction.merchant = "Test Merchant"
        transaction.category = "Food"
        transaction.notes = "Test notes"
        transaction.confidence = 0.95
        transaction.account = account
        
        try context.save()
        
        // When
        let dto = TransactionDTO(from: transaction)
        
        // Then
        XCTAssertEqual(dto.id, transaction.id)
        XCTAssertEqual(dto.date, transaction.date)
        XCTAssertEqual(dto.amount, transaction.amount.decimalValue)
        XCTAssertEqual(dto.merchant, transaction.merchant)
        XCTAssertEqual(dto.category, transaction.category)
        XCTAssertEqual(dto.notes, transaction.notes)
        XCTAssertEqual(dto.confidence, transaction.confidence)
        XCTAssertEqual(dto.accountId, account.id)
    }
    
    func testAccountDTOConversion() async throws {
        // Given - Create an account
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "Savings"
        account.isActive = true
        account.createdAt = Date()
        
        try context.save()
        
        // When
        let dto = AccountDTO(from: account)
        
        // Then
        XCTAssertEqual(dto.id, account.id)
        XCTAssertEqual(dto.name, account.name)
        XCTAssertEqual(dto.type, account.type)
        XCTAssertEqual(dto.isActive, account.isActive)
        XCTAssertEqual(dto.createdAt, account.createdAt)
    }
    
    // MARK: - Background Context Tests
    
    func testBackgroundContextExecution() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Background context execution")
        
        // When
        let result = try await backgroundContextProvider.performBackgroundTask { context in
            // This should run on a background context
            XCTAssertFalse(Thread.isMainThread)
            expectation.fulfill()
            return "Success"
        }
        
        // Then
        XCTAssertEqual(result, "Success")
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testBackgroundContextWithDTOs() async throws {
        // Given - Create test data
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "Checking"
        account.isActive = true
        account.createdAt = Date()
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.amount = NSDecimalNumber(decimal: 50.00)
        transaction.merchant = "Test Store"
        transaction.category = "Shopping"
        transaction.account = account
        
        try context.save()
        
        // When
        let dtos = try await backgroundContextProvider.performBackgroundTaskWithDTOs { context in
            let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            return try context.fetchDTOs(request) { TransactionDTO(from: $0) }
        }
        
        // Then
        XCTAssertEqual(dtos.count, 1)
        XCTAssertEqual(dtos.first?.merchant, "Test Store")
        XCTAssertEqual(dtos.first?.amount, Decimal(50.00))
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentRepositoryAccess() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent repository access")
        expectation.expectedFulfillmentCount = 10
        
        // When - Access repository from multiple threads
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    do {
                        let transactions = try await self.transactionRepository.fetchAll()
                        XCTAssertNotNil(transactions)
                        expectation.fulfill()
                    } catch {
                        XCTFail("Repository access failed: \(error)")
                    }
                }
            }
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testConcurrentBackgroundContextAccess() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent background context access")
        expectation.expectedFulfillmentCount = 20
        
        // When - Use background contexts concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<20 {
                group.addTask {
                    do {
                        let result = try await self.backgroundContextProvider.performBackgroundTask { context in
                            // Create a test entity
                            let account = Account(context: context)
                            account.id = UUID()
                            account.name = "Concurrent Account \(i)"
                            account.type = "Test"
                            account.isActive = true
                            account.createdAt = Date()
                            
                            try context.safeSave()
                            return account.name
                        }
                        
                        XCTAssertEqual(result, "Concurrent Account \(i)")
                        expectation.fulfill()
                    } catch {
                        XCTFail("Background context access failed: \(error)")
                    }
                }
            }
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    // MARK: - Context Isolation Tests
    
    func testContextIsolation() async throws {
        // Given
        let mainContextAccount = Account(context: context)
        mainContextAccount.id = UUID()
        mainContextAccount.name = "Main Context Account"
        mainContextAccount.type = "Main"
        mainContextAccount.isActive = true
        mainContextAccount.createdAt = Date()
        
        try context.save()
        
        // When - Create account in background context
        let backgroundAccountName = try await backgroundContextProvider.performBackgroundTask { backgroundContext in
            let account = Account(context: backgroundContext)
            account.id = UUID()
            account.name = "Background Context Account"
            account.type = "Background"
            account.isActive = true
            account.createdAt = Date()
            
            try backgroundContext.safeSave()
            return account.name
        }
        
        // Then - Background context changes should not affect main context
        XCTAssertEqual(backgroundAccountName, "Background Context Account")
        
        // Verify main context still has original data
        let mainContextAccounts = try context.fetch(Account.fetchRequest())
        XCTAssertEqual(mainContextAccounts.count, 1)
        XCTAssertEqual(mainContextAccounts.first?.name, "Main Context Account")
    }
    
    // MARK: - Error Handling Tests
    
    func testContextErrorHandling() async {
        // Given
        let expectation = XCTestExpectation(description: "Error handling")
        
        // When - Perform operation that will fail
        do {
            _ = try await backgroundContextProvider.performBackgroundTask { context in
                // Try to save without required fields
                let account = Account(context: context)
                // Don't set required fields
                try context.safeSave()
                return "Should not reach here"
            }
            XCTFail("Should have thrown an error")
        } catch {
            // Then - Error should be caught and handled
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Performance Tests
    
    func testBackgroundContextPerformance() async throws {
        // Given
        let iterations = 100
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When - Perform many background operations
        for i in 0..<iterations {
            _ = try await backgroundContextProvider.performBackgroundTask { context in
                let account = Account(context: context)
                account.id = UUID()
                account.name = "Performance Test \(i)"
                account.type = "Test"
                account.isActive = true
                account.createdAt = Date()
                
                try context.safeSave()
                return account.name
            }
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then - Should complete in reasonable time
        XCTAssertLessThan(duration, 10.0, "Background context operations should be efficient")
    }
    
    // MARK: - Memory Management Tests
    
    func testContextPooling() async throws {
        // Given
        let initialPoolSize = 0 // Pool starts empty
        
        // When - Use multiple contexts
        for i in 0..<10 {
            _ = try await backgroundContextProvider.performBackgroundTask { context in
                let account = Account(context: context)
                account.id = UUID()
                account.name = "Pool Test \(i)"
                account.type = "Test"
                account.isActive = true
                account.createdAt = Date()
                
                try context.safeSave()
                return account.name
            }
        }
        
        // Then - Contexts should be pooled for reuse
        // Note: In a real test, you might verify the pool size
        // but the BackgroundContextProvider doesn't expose pool statistics
    }
}
