//
//  BackgroundContextProviderTests.swift
//  ClariFi iOSTests
//
//  Tests for BackgroundContextProvider thread safety and correctness
//

import XCTest
import CoreData
@testable import ClariFi_iOS

@MainActor
class BackgroundContextProviderTests: XCTestCase {
    
    var container: NSPersistentContainer!
    var backgroundContextProvider: BackgroundContextProvider!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory Core Data stack
        container = NSPersistentContainer(name: "ClariFi_iOS")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        try await container.loadPersistentStores()
        backgroundContextProvider = BackgroundContextProvider(persistentContainer: container)
    }
    
    override func tearDown() async throws {
        container = nil
        backgroundContextProvider = nil
        try await super.tearDown()
    }
    
    // MARK: - Context Creation Tests
    
    func testBackgroundContextCreation() async throws {
        let context = backgroundContextProvider.createBackgroundContext()
        
        XCTAssertNotNil(context)
        XCTAssertEqual(context.concurrencyType, .privateQueueConcurrencyType)
        XCTAssertNil(context.undoManager)
        XCTAssertNotNil(context.mergePolicy)
    }
    
    func testMultipleBackgroundContextCreation() async throws {
        let contexts = (0..<10).map { _ in
            backgroundContextProvider.createBackgroundContext()
        }
        
        XCTAssertEqual(contexts.count, 10)
        
        // Verify all contexts are unique instances
        for i in 0..<contexts.count {
            for j in (i+1)..<contexts.count {
                XCTAssertFalse(contexts[i] === contexts[j])
            }
        }
    }
    
    // MARK: - Background Task Execution Tests
    
    func testBasicBackgroundTask() async throws {
        let result = try await backgroundContextProvider.performBackgroundTask { context in
            XCTAssertFalse(Thread.isMainThread)
            XCTAssertEqual(context.concurrencyType, .privateQueueConcurrencyType)
            return "test_result"
        }
        
        XCTAssertEqual(result, "test_result")
    }
    
    func testBackgroundTaskWithEntityCreation() async throws {
        let transactionId = UUID()
        
        let result = try await backgroundContextProvider.performBackgroundTask { context in
            XCTAssertFalse(Thread.isMainThread)
            
            let transaction = Transaction(context: context)
            transaction.id = transactionId
            transaction.amount = NSDecimalNumber(value: 100.0)
            transaction.merchant = "Background Merchant"
            transaction.date = Date()
            transaction.category = "Test"
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
            
            try context.save()
            return transaction.id
        }
        
        XCTAssertEqual(result, transactionId)
        
        // Verify entity was saved to persistent store
        let mainContext = container.viewContext
        let fetchRequest = NSFetchRequest<Transaction>(entityName: "Transaction")
        fetchRequest.predicate = NSPredicate(format: "id == %@", transactionId as CVarArg)
        
        let transactions = try await mainContext.perform {
            try mainContext.fetch(fetchRequest)
        }
        
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.first?.merchant, "Background Merchant")
    }
    
    func testBackgroundTaskWithError() async throws {
        do {
            let _ = try await backgroundContextProvider.performBackgroundTask { context in
                throw NSError(domain: "TestError", code: 1, userInfo: nil)
            }
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertEqual((error as NSError).domain, "TestError")
        }
    }
    
    // MARK: - Concurrent Background Tasks Tests
    
    func testConcurrentBackgroundTasks() async throws {
        let taskCount = 30
        var results: [String] = []
        
        await withTaskGroup(of: String.self) { group in
            for i in 0..<taskCount {
                group.addTask {
                    do {
                        return try await self.backgroundContextProvider.performBackgroundTask { context in
                            XCTAssertFalse(Thread.isMainThread)
                            
                            // Simulate some work
                            try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000...10_000_000))
                            
                            return "Task \(i) completed"
                        }
                    } catch {
                        XCTFail("Background task failed: \(error)")
                        return "Failed"
                    }
                }
            }
            
            for await result in group {
                results.append(result)
            }
        }
        
        XCTAssertEqual(results.count, taskCount)
        XCTAssertTrue(results.allSatisfy { $0.contains("completed") })
    }
    
    func testConcurrentEntityCreation() async throws {
        let entityCount = 40
        
        await withTaskGroup(of: UUID?.self) { group in
            for i in 0..<entityCount {
                group.addTask {
                    do {
                        return try await self.backgroundContextProvider.performBackgroundTask { context in
                            XCTAssertFalse(Thread.isMainThread)
                            
                            let transaction = Transaction(context: context)
                            transaction.id = UUID()
                            transaction.amount = NSDecimalNumber(value: Double(i * 10))
                            transaction.merchant = "Concurrent Merchant \(i)"
                            transaction.date = Date()
                            transaction.category = "Test"
                            transaction.createdAt = Date()
                            transaction.updatedAt = Date()
                            
                            try context.save()
                            return transaction.id
                        }
                    } catch {
                        XCTFail("Concurrent entity creation failed: \(error)")
                        return nil
                    }
                }
            }
            
            for await _ in group {
                // Wait for all tasks to complete
            }
        }
        
        // Verify all entities were created
        let mainContext = container.viewContext
        let fetchRequest = NSFetchRequest<Transaction>(entityName: "Transaction")
        
        let transactions = try await mainContext.perform {
            try mainContext.fetch(fetchRequest)
        }
        
        XCTAssertEqual(transactions.count, entityCount)
    }
    
    // MARK: - Context Isolation Tests
    
    func testContextIsolationBetweenThreads() async throws {
        let sharedId = UUID()
        
        // Create entity in background context
        try await backgroundContextProvider.performBackgroundTask { context in
            let transaction = Transaction(context: context)
            transaction.id = sharedId
            transaction.amount = NSDecimalNumber(value: 100.0)
            transaction.merchant = "Background Merchant"
            transaction.date = Date()
            transaction.category = "Test"
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
            
            try context.save()
        }
        
        // Verify entity is not in main context until refresh
        let mainContext = container.viewContext
        let fetchRequest = NSFetchRequest<Transaction>(entityName: "Transaction")
        fetchRequest.predicate = NSPredicate(format: "id == %@", sharedId as CVarArg)
        
        // Refresh main context to see changes
        await mainContext.perform {
            mainContext.refreshAllObjects()
        }
        
        let transactions = try await mainContext.perform {
            try mainContext.fetch(fetchRequest)
        }
        
        XCTAssertEqual(transactions.count, 1)
    }
    
    func testMultipleContextsDoNotInterfere() async throws {
        let context1Id = UUID()
        let context2Id = UUID()
        
        // Create entities in different background contexts concurrently
        async let task1: Void = backgroundContextProvider.performBackgroundTask { context in
            let transaction = Transaction(context: context)
            transaction.id = context1Id
            transaction.amount = NSDecimalNumber(value: 100.0)
            transaction.merchant = "Context 1 Merchant"
            transaction.date = Date()
            transaction.category = "Test"
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
            
            try context.save()
        }
        
        async let task2: Void = backgroundContextProvider.performBackgroundTask { context in
            let transaction = Transaction(context: context)
            transaction.id = context2Id
            transaction.amount = NSDecimalNumber(value: 200.0)
            transaction.merchant = "Context 2 Merchant"
            transaction.date = Date()
            transaction.category = "Test"
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
            
            try context.save()
        }
        
        try await task1
        try await task2
        
        // Verify both entities exist
        let mainContext = container.viewContext
        await mainContext.perform {
            mainContext.refreshAllObjects()
        }
        
        let fetchRequest = NSFetchRequest<Transaction>(entityName: "Transaction")
        let transactions = try await mainContext.perform {
            try mainContext.fetch(fetchRequest)
        }
        
        XCTAssertEqual(transactions.count, 2)
        XCTAssertTrue(transactions.contains { $0.id == context1Id })
        XCTAssertTrue(transactions.contains { $0.id == context2Id })
    }
    
    // MARK: - Context Save Tests
    
    func testContextSaveOperations() async throws {
        let saveCount = 20
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<saveCount {
                group.addTask {
                    do {
                        try await self.backgroundContextProvider.performBackgroundTask { context in
                            let transaction = Transaction(context: context)
                            transaction.id = UUID()
                            transaction.amount = NSDecimalNumber(value: Double(i * 10))
                            transaction.merchant = "Save Test \(i)"
                            transaction.date = Date()
                            transaction.category = "Test"
                            transaction.createdAt = Date()
                            transaction.updatedAt = Date()
                            
                            XCTAssertTrue(context.hasChanges)
                            try context.save()
                            XCTAssertFalse(context.hasChanges)
                        }
                    } catch {
                        XCTFail("Context save failed: \(error)")
                    }
                }
            }
        }
        
        // Verify all saves completed
        let mainContext = container.viewContext
        await mainContext.perform {
            mainContext.refreshAllObjects()
        }
        
        let fetchRequest = NSFetchRequest<Transaction>(entityName: "Transaction")
        let transactions = try await mainContext.perform {
            try mainContext.fetch(fetchRequest)
        }
        
        XCTAssertEqual(transactions.count, saveCount)
    }
    
    func testConcurrentSaveOperations() async throws {
        // Create a shared entity to update
        let sharedId = UUID()
        let mainContext = container.viewContext
        
        await mainContext.perform {
            let transaction = Transaction(context: mainContext)
            transaction.id = sharedId
            transaction.amount = NSDecimalNumber(value: 0)
            transaction.merchant = "Initial"
            transaction.date = Date()
            transaction.category = "Test"
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
            
            try? mainContext.save()
        }
        
        // Perform concurrent updates
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<15 {
                group.addTask {
                    do {
                        try await self.backgroundContextProvider.performBackgroundTask { context in
                            let fetchRequest = NSFetchRequest<Transaction>(entityName: "Transaction")
                            fetchRequest.predicate = NSPredicate(format: "id == %@", sharedId as CVarArg)
                            
                            if let transaction = try context.fetch(fetchRequest).first {
                                transaction.merchant = "Updated \(i)"
                                transaction.updatedAt = Date()
                                try context.save()
                            }
                        }
                    } catch {
                        // Some updates may conflict, which is expected
                        print("Update \(i) conflicted: \(error)")
                    }
                }
            }
        }
        
        // Verify entity still exists and has been updated
        await mainContext.perform {
            mainContext.refreshAllObjects()
        }
        
        let fetchRequest = NSFetchRequest<Transaction>(entityName: "Transaction")
        fetchRequest.predicate = NSPredicate(format: "id == %@", sharedId as CVarArg)
        
        let transactions = try await mainContext.perform {
            try mainContext.fetch(fetchRequest)
        }
        
        XCTAssertEqual(transactions.count, 1)
        XCTAssertTrue(transactions.first?.merchant?.starts(with: "Updated") ?? false)
    }
    
    // MARK: - DTO Conversion Tests
    
    func testDTOConversionInBackgroundContext() async throws {
        // Create entities in background
        let entityCount = 25
        
        for i in 0..<entityCount {
            try await backgroundContextProvider.performBackgroundTask { context in
                let transaction = Transaction(context: context)
                transaction.id = UUID()
                transaction.amount = NSDecimalNumber(value: Double(i * 10))
                transaction.merchant = "DTO Merchant \(i)"
                transaction.date = Date()
                transaction.category = "Test"
                transaction.createdAt = Date()
                transaction.updatedAt = Date()
                
                try context.save()
            }
        }
        
        // Fetch and convert to DTOs in background
        let dtos = try await backgroundContextProvider.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<Transaction>(entityName: "Transaction")
            let transactions = try context.fetch(fetchRequest)
            return transactions.map { TransactionDTO(from: $0) }
        }
        
        XCTAssertEqual(dtos.count, entityCount)
        for (index, dto) in dtos.enumerated() {
            XCTAssertTrue(dto.merchant.contains("DTO Merchant"))
        }
    }
    
    // MARK: - Performance Tests
    
    func testBackgroundContextPerformance() async throws {
        let operationCount = 100
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<operationCount {
                group.addTask {
                    do {
                        try await self.backgroundContextProvider.performBackgroundTask { context in
                            let transaction = Transaction(context: context)
                            transaction.id = UUID()
                            transaction.amount = NSDecimalNumber(value: Double(i))
                            transaction.merchant = "Performance Test \(i)"
                            transaction.date = Date()
                            transaction.category = "Test"
                            transaction.createdAt = Date()
                            transaction.updatedAt = Date()
                            
                            try context.save()
                        }
                    } catch {
                        XCTFail("Performance test failed: \(error)")
                    }
                }
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Verify performance is acceptable
        XCTAssertLessThan(executionTime, 10.0) // Should complete in under 10 seconds
        
        print("Background context performance: \(executionTime)s for \(operationCount) operations")
    }
    
    // MARK: - Error Recovery Tests
    
    func testErrorRecoveryInBackgroundContext() async throws {
        // Test that errors in one task don't affect others
        var successCount = 0
        var errorCount = 0
        
        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<20 {
                group.addTask {
                    do {
                        try await self.backgroundContextProvider.performBackgroundTask { context in
                            if i % 5 == 0 {
                                throw NSError(domain: "TestError", code: i, userInfo: nil)
                            }
                            
                            let transaction = Transaction(context: context)
                            transaction.id = UUID()
                            transaction.amount = NSDecimalNumber(value: Double(i))
                            transaction.merchant = "Error Test \(i)"
                            transaction.date = Date()
                            transaction.category = "Test"
                            transaction.createdAt = Date()
                            transaction.updatedAt = Date()
                            
                            try context.save()
                        }
                        return true
                    } catch {
                        return false
                    }
                }
            }
            
            for await success in group {
                if success {
                    successCount += 1
                } else {
                    errorCount += 1
                }
            }
        }
        
        XCTAssertEqual(successCount, 16) // 20 - 4 errors
        XCTAssertEqual(errorCount, 4) // Every 5th task fails
    }
}
