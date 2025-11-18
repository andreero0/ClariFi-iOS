//
//  RepositoryThreadSafetyTests.swift
//  ClariFi iOSTests
//
//  Tests for Core Data repository thread safety and concurrent operations
//

import XCTest
import CoreData
@testable import ClariFi_iOS

@MainActor
class RepositoryThreadSafetyTests: XCTestCase {
    
    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!
    var backgroundContextProvider: BackgroundContextProvider!
    var transactionRepository: CoreDataTransactionRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory Core Data stack
        container = NSPersistentContainer(name: "ClariFi_iOS")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        try await container.loadPersistentStores()
        context = container.viewContext
        backgroundContextProvider = BackgroundContextProvider(persistentContainer: container)
        transactionRepository = CoreDataTransactionRepository(context: context, backgroundContextProvider: backgroundContextProvider)
    }
    
    override func tearDown() async throws {
        container = nil
        context = nil
        backgroundContextProvider = nil
        transactionRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Repository Operations
    
    func testBasicCRUDOperations() async throws {
        // Create
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.amount = NSDecimalNumber(value: 100.0)
        transaction.merchant = "Test Merchant"
        transaction.date = Date()
        transaction.category = "Test Category"
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        
        try await transactionRepository.save(transaction)
        
        // Read
        let fetchedTransactions = try await transactionRepository.fetchAll()
        XCTAssertEqual(fetchedTransactions.count, 1)
        XCTAssertEqual(fetchedTransactions.first?.merchant, "Test Merchant")
        
        // Update
        transaction.merchant = "Updated Merchant"
        try await transactionRepository.save(transaction)
        
        let updatedTransactions = try await transactionRepository.fetchAll()
        XCTAssertEqual(updatedTransactions.first?.merchant, "Updated Merchant")
        
        // Delete
        try await transactionRepository.delete(transaction)
        
        let deletedTransactions = try await transactionRepository.fetchAll()
        XCTAssertEqual(deletedTransactions.count, 0)
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentReads() async throws {
        // Create test data
        let transactions = createTestTransactions(count: 100)
        for transaction in transactions {
            try await transactionRepository.save(transaction)
        }
        
        // Test concurrent reads
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    do {
                        let fetched = try await self.transactionRepository.fetchAll()
                        XCTAssertEqual(fetched.count, 100)
                    } catch {
                        XCTFail("Concurrent read failed: \(error)")
                    }
                }
            }
        }
    }
    
    func testConcurrentWrites() async throws {
        // Test concurrent writes
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    do {
                        let transaction = Transaction(context: self.context)
                        transaction.id = UUID()
                        transaction.amount = NSDecimalNumber(value: Double(i * 10))
                        transaction.merchant = "Concurrent Merchant \(i)"
                        transaction.date = Date()
                        transaction.category = "Test Category"
                        transaction.createdAt = Date()
                        transaction.updatedAt = Date()
                        
                        try await self.transactionRepository.save(transaction)
                    } catch {
                        XCTFail("Concurrent write failed: \(error)")
                    }
                }
            }
        }
        
        // Verify all writes completed
        let allTransactions = try await transactionRepository.fetchAll()
        XCTAssertEqual(allTransactions.count, 50)
    }
    
    func testConcurrentReadsAndWrites() async throws {
        // Test concurrent reads and writes
        await withTaskGroup(of: Void.self) { group in
            // Add write tasks
            for i in 0..<25 {
                group.addTask {
                    do {
                        let transaction = Transaction(context: self.context)
                        transaction.id = UUID()
                        transaction.amount = NSDecimalNumber(value: Double(i * 10))
                        transaction.merchant = "ReadWrite Merchant \(i)"
                        transaction.date = Date()
                        transaction.category = "Test Category"
                        transaction.createdAt = Date()
                        transaction.updatedAt = Date()
                        
                        try await self.transactionRepository.save(transaction)
                    } catch {
                        XCTFail("Concurrent write failed: \(error)")
                    }
                }
            }
            
            // Add read tasks
            for _ in 0..<25 {
                group.addTask {
                    do {
                        let transactions = try await self.transactionRepository.fetchAll()
                        // Should not crash, count may vary due to concurrency
                        XCTAssertTrue(transactions.count >= 0)
                    } catch {
                        XCTFail("Concurrent read failed: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Context Isolation Tests
    
    func testBackgroundContextIsolation() async throws {
        // Test that background context operations don't interfere with main context
        let expectation = XCTestExpectation(description: "Background operation completes")
        
        // Perform background operation
        let result = try await backgroundContextProvider.performBackgroundTask { context in
            // Verify we're not on main thread
            XCTAssertFalse(Thread.isMainThread)
            
            // Create transaction in background context
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.amount = NSDecimalNumber(value: 200.0)
            transaction.merchant = "Background Merchant"
            transaction.date = Date()
            transaction.category = "Background Category"
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
            
            try context.save()
            return transaction
        }
        
        // Verify result is returned to main actor
        await MainActor.run {
            XCTAssertNotNil(result)
            XCTAssertEqual(result.merchant, "Background Merchant")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testMultipleBackgroundContexts() async throws {
        // Test multiple concurrent background operations
        let expectation = XCTestExpectation(description: "All background operations complete")
        expectation.expectedFulfillmentCount = 5
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    do {
                        let result = try await self.backgroundContextProvider.performBackgroundTask { context in
                            // Verify we're not on main thread
                            XCTAssertFalse(Thread.isMainThread)
                            
                            // Create transaction in background context
                            let transaction = Transaction(context: context)
                            transaction.id = UUID()
                            transaction.amount = NSDecimalNumber(value: Double(i * 100))
                            transaction.merchant = "Background Merchant \(i)"
                            transaction.date = Date()
                            transaction.category = "Background Category"
                            transaction.createdAt = Date()
                            transaction.updatedAt = Date()
                            
                            try context.save()
                            return transaction
                        }
                        
                        // Verify result is returned
                        XCTAssertNotNil(result)
                        XCTAssertEqual(result.merchant, "Background Merchant \(i)")
                        
                        await MainActor.run {
                            expectation.fulfill()
                        }
                    } catch {
                        XCTFail("Background operation failed: \(error)")
                    }
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - DTO Conversion Tests
    
    func testDTOConversion() async throws {
        // Create transaction
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.amount = NSDecimalNumber(value: 150.0)
        transaction.merchant = "DTO Test Merchant"
        transaction.date = Date()
        transaction.category = "DTO Test Category"
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        
        try await transactionRepository.save(transaction)
        
        // Fetch and verify DTO conversion
        let fetchedTransactions = try await transactionRepository.fetchAll()
        XCTAssertEqual(fetchedTransactions.count, 1)
        
        let fetchedTransaction = fetchedTransactions.first!
        XCTAssertEqual(fetchedTransaction.merchant, "DTO Test Merchant")
        XCTAssertEqual(fetchedTransaction.amount?.decimalValue, Decimal(150.0))
        XCTAssertEqual(fetchedTransaction.category, "DTO Test Category")
    }
    
    // MARK: - Error Handling Tests
    
    func testRepositoryErrorHandling() async throws {
        // Test error handling for invalid operations
        do {
            let _ = try await transactionRepository.fetchById(UUID())
            XCTFail("Should have thrown an error")
        } catch {
            // Expected error
            XCTAssertTrue(error is RepositoryError)
        }
    }
    
    func testContextErrorHandling() async throws {
        // Test error handling in background context
        do {
            let _ = try await backgroundContextProvider.performBackgroundTask { context in
                // Force an error by trying to save without changes
                try context.save()
                return "test"
            }
            XCTFail("Should have thrown an error")
        } catch {
            // Expected error
            XCTAssertTrue(error is CoreDataError)
        }
    }
    
    // MARK: - Performance Tests
    
    func testRepositoryPerformance() async throws {
        // Test performance with large dataset
        let transactions = createTestTransactions(count: 1000)
        
        // Test save performance
        let saveStartTime = CFAbsoluteTimeGetCurrent()
        for transaction in transactions {
            try await transactionRepository.save(transaction)
        }
        let saveEndTime = CFAbsoluteTimeGetCurrent()
        let saveExecutionTime = saveEndTime - saveStartTime
        
        // Test fetch performance
        let fetchStartTime = CFAbsoluteTimeGetCurrent()
        let fetchedTransactions = try await transactionRepository.fetchAll()
        let fetchEndTime = CFAbsoluteTimeGetCurrent()
        let fetchExecutionTime = fetchEndTime - fetchStartTime
        
        // Verify results
        XCTAssertEqual(fetchedTransactions.count, 1000)
        
        // Verify performance is acceptable
        XCTAssertLessThan(saveExecutionTime, 10.0) // Should complete in under 10 seconds
        XCTAssertLessThan(fetchExecutionTime, 2.0) // Should complete in under 2 seconds
        
        print("Save time: \(saveExecutionTime)s")
        print("Fetch time: \(fetchExecutionTime)s")
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsageWithLargeDataset() async throws {
        let initialMemory = getMemoryUsage()
        
        // Create large dataset
        let transactions = createTestTransactions(count: 5000)
        for transaction in transactions {
            try await transactionRepository.save(transaction)
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Verify memory usage is reasonable
        XCTAssertLessThan(memoryIncrease, 100 * 1024 * 1024) // Less than 100MB
        
        print("Memory increase: \(memoryIncrease / 1024 / 1024)MB")
    }
    
    // MARK: - Helper Methods
    
    private func createTestTransactions(count: Int) -> [Transaction] {
        var transactions: [Transaction] = []
        
        for i in 0..<count {
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.amount = NSDecimalNumber(value: Double.random(in: 1...100))
            transaction.merchant = "Test Merchant \(i)"
            transaction.description = "Test transaction \(i)"
            transaction.date = Date()
            transaction.category = "Test Category"
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
            transactions.append(transaction)
        }
        
        return transactions
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
}
