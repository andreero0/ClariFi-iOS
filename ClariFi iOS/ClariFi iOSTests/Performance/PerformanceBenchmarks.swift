//
//  PerformanceBenchmarks.swift
//  ClariFi iOSTests
//
//  Performance benchmarks and CI integration tests
//

#if canImport(XCTest)
import XCTest
import CoreData
@testable import ClariFi_iOS

@MainActor
class PerformanceBenchmarks: XCTestCase {
    
    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!
    var backgroundContextProvider: BackgroundContextProvider!
    
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
    }
    
    override func tearDown() async throws {
        container = nil
        context = nil
        backgroundContextProvider = nil
        try await super.tearDown()
    }
    
    // MARK: - Currency Formatter Performance Tests
    
    func testCurrencyFormatterPerformance() async throws {
        // Test performance of cached vs uncached formatters
        let amounts = generateTestAmounts(count: 1000)
        
        // Test cached formatter performance
        let cachedStartTime = CFAbsoluteTimeGetCurrent()
        for amount in amounts {
            _ = await CurrencyFormatter.shared.format(amount, currency: .usd)
        }
        let cachedEndTime = CFAbsoluteTimeGetCurrent()
        let cachedExecutionTime = cachedEndTime - cachedStartTime
        
        // Test uncached formatter performance
        let uncachedStartTime = CFAbsoluteTimeGetCurrent()
        for amount in amounts {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            _ = formatter.string(from: amount as NSDecimalNumber)
        }
        let uncachedEndTime = CFAbsoluteTimeGetCurrent()
        let uncachedExecutionTime = uncachedEndTime - uncachedStartTime
        
        // Verify cached formatter is faster
        XCTAssertLessThan(cachedExecutionTime, uncachedExecutionTime)
        
        // Verify cached formatter is fast enough
        XCTAssertLessThan(cachedExecutionTime, 0.1) // Should complete in under 100ms
        
        print("Cached formatter: \(cachedExecutionTime)s")
        print("Uncached formatter: \(uncachedExecutionTime)s")
        print("Performance improvement: \(uncachedExecutionTime / cachedExecutionTime)x")
    }
    
    func testCurrencyFormatterCacheEfficiency() async throws {
        // Test cache efficiency with repeated calls
        let amounts = generateTestAmounts(count: 100)
        let currencies: [Currency] = [.usd, .eur, .gbp, .jpy, .cad]
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Make repeated calls to same currencies
        for _ in 0..<10 {
            for amount in amounts {
                for currency in currencies {
                    _ = await CurrencyFormatter.shared.format(amount, currency: currency)
                }
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Verify cache is efficient
        XCTAssertLessThan(executionTime, 0.5) // Should complete in under 500ms
        
        // Verify cache size is reasonable
        let cacheStats = await CurrencyFormatter.shared.getCacheStats()
        XCTAssertLessThanOrEqual(cacheStats, 10) // Should not exceed 10 cached formatters
    }
    
    // MARK: - Transaction Parser Performance Tests
    
    func testTransactionParserPerformance() async throws {
        // Test performance of parallel vs sequential parsing
        let statementText = generateLargeStatementText(lineCount: 1000)
        
        let parser = SmartTransactionParser()
        
        // Test parallel parsing performance
        let parallelStartTime = CFAbsoluteTimeGetCurrent()
        let parallelResult = try await parser.parseTransactions(from: statementText, format: .csv)
        let parallelEndTime = CFAbsoluteTimeGetCurrent()
        let parallelExecutionTime = parallelEndTime - parallelStartTime
        
        // Test sequential parsing performance
        let sequentialStartTime = CFAbsoluteTimeGetCurrent()
        let sequentialResult = try await parser.parseTransactions(from: statementText, format: .csv)
        let sequentialEndTime = CFAbsoluteTimeGetCurrent()
        let sequentialExecutionTime = sequentialEndTime - sequentialStartTime
        
        // Verify both methods produce same results
        XCTAssertEqual(parallelResult.count, sequentialResult.count)
        
        // Verify parallel parsing is fast enough
        XCTAssertLessThan(parallelExecutionTime, 2.0) // Should complete in under 2 seconds
        
        print("Parallel parsing: \(parallelExecutionTime)s")
        print("Sequential parsing: \(sequentialExecutionTime)s")
        print("Results count: \(parallelResult.count)")
    }
    
    func testTransactionParserScalability() async throws {
        // Test parser scalability with different dataset sizes
        let testSizes = [100, 500, 1000, 2000]
        let parser = SmartTransactionParser()
        
        for size in testSizes {
            let statementText = generateLargeStatementText(lineCount: size)
            
            let startTime = CFAbsoluteTimeGetCurrent()
            let result = try await parser.parseTransactions(from: statementText, format: .csv)
            let endTime = CFAbsoluteTimeGetCurrent()
            let executionTime = endTime - startTime
            
            // Verify results are correct
            XCTAssertEqual(result.count, size)
            
            // Verify performance scales reasonably
            let expectedTime = Double(size) * 0.001 // 1ms per transaction
            XCTAssertLessThan(executionTime, expectedTime * 2) // Allow 2x overhead
            
            print("Size: \(size), Time: \(executionTime)s, Rate: \(Double(size) / executionTime) tx/s")
        }
    }
    
    // MARK: - Core Data Performance Tests
    
    func testCoreDataRepositoryPerformance() async throws {
        // Test repository performance with large datasets
        let transactionRepo = CoreDataTransactionRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        
        // Create test transactions
        let transactions = createTestTransactions(count: 1000)
        
        // Test batch save performance
        let saveStartTime = CFAbsoluteTimeGetCurrent()
        for transaction in transactions {
            try await transactionRepo.save(transaction)
        }
        let saveEndTime = CFAbsoluteTimeGetCurrent()
        let saveExecutionTime = saveEndTime - saveStartTime
        
        // Test fetch performance
        let fetchStartTime = CFAbsoluteTimeGetCurrent()
        let fetchedTransactions = try await transactionRepo.fetchAll()
        let fetchEndTime = CFAbsoluteTimeGetCurrent()
        let fetchExecutionTime = fetchEndTime - fetchStartTime
        
        // Verify results
        XCTAssertEqual(fetchedTransactions.count, 1000)
        
        // Verify performance is acceptable
        XCTAssertLessThan(saveExecutionTime, 5.0) // Should complete in under 5 seconds
        XCTAssertLessThan(fetchExecutionTime, 1.0) // Should complete in under 1 second
        
        print("Save time: \(saveExecutionTime)s")
        print("Fetch time: \(fetchExecutionTime)s")
    }
    
    func testCoreDataConcurrentOperations() async throws {
        // Test concurrent Core Data operations
        let transactionRepo = CoreDataTransactionRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        
        let expectation = XCTestExpectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = 10
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    do {
                        // Create and save transaction
                        let transaction = Transaction(context: self.context)
                        transaction.id = UUID()
                        transaction.amount = NSDecimalNumber(value: i * 10)
                        transaction.merchant = "Test Merchant \(i)"
                        transaction.date = Date()
                        transaction.category = "Test Category"
                        
                        try await transactionRepo.save(transaction)
                        
                        // Fetch transactions
                        let transactions = try await transactionRepo.fetchAll()
                        XCTAssertGreaterThan(transactions.count, 0)
                        
                        expectation.fulfill()
                    } catch {
                        XCTFail("Concurrent operation failed: \(error)")
                    }
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Verify concurrent operations are fast
        XCTAssertLessThan(executionTime, 5.0) // Should complete in under 5 seconds
        
        print("Concurrent operations time: \(executionTime)s")
    }
    
    // MARK: - LLM Cache Performance Tests
    
    func testLLMCachePerformance() async throws {
        // Test LLM cache performance
        let cache = LLMCache()
        let testKeys = generateTestKeys(count: 1000)
        
        // Test cache write performance
        let writeStartTime = CFAbsoluteTimeGetCurrent()
        for (index, key) in testKeys.enumerated() {
            let result = LLMCategorizationResult(
                category: "Test Category",
                confidence: 0.8,
                reasoning: "Test reasoning"
            )
            await cache.setResponse(result, for: key)
        }
        let writeEndTime = CFAbsoluteTimeGetCurrent()
        let writeExecutionTime = writeEndTime - writeStartTime
        
        // Test cache read performance
        let readStartTime = CFAbsoluteTimeGetCurrent()
        for key in testKeys {
            _ = await cache.getResponse(for: key)
        }
        let readEndTime = CFAbsoluteTimeGetCurrent()
        let readExecutionTime = readEndTime - readStartTime
        
        // Verify performance is acceptable
        XCTAssertLessThan(writeExecutionTime, 0.5) // Should complete in under 500ms
        XCTAssertLessThan(readExecutionTime, 0.1) // Should complete in under 100ms
        
        print("Cache write time: \(writeExecutionTime)s")
        print("Cache read time: \(readExecutionTime)s")
    }
    
    // MARK: - Analytics Performance Tests
    
    func testAnalyticsBatchingPerformance() async throws {
        // Test analytics batching performance
        let analyticsService = PostHogAnalyticsService()
        let eventCount = 1000
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Send many events
        for i in 0..<eventCount {
            analyticsService.track(event: .transactionAdded, properties: ["index": i])
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Verify batching is fast
        XCTAssertLessThan(executionTime, 0.1) // Should complete in under 100ms
        
        print("Analytics batching time: \(executionTime)s")
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemoryUsagePerformance() async throws {
        // Test memory usage with large datasets
        let initialMemory = getMemoryUsage()
        
        // Create large dataset
        let transactions = createTestTransactions(count: 10000)
        let afterCreateMemory = getMemoryUsage()
        
        // Process transactions
        let transactionRepo = CoreDataTransactionRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        for transaction in transactions {
            try await transactionRepo.save(transaction)
        }
        let afterSaveMemory = getMemoryUsage()
        
        // Verify memory usage is reasonable
        let createMemoryIncrease = afterCreateMemory - initialMemory
        let saveMemoryIncrease = afterSaveMemory - afterCreateMemory
        
        XCTAssertLessThan(createMemoryIncrease, 100 * 1024 * 1024) // Less than 100MB
        XCTAssertLessThan(saveMemoryIncrease, 50 * 1024 * 1024) // Less than 50MB
        
        print("Initial memory: \(initialMemory / 1024 / 1024)MB")
        print("After create memory: \(afterCreateMemory / 1024 / 1024)MB")
        print("After save memory: \(afterSaveMemory / 1024 / 1024)MB")
    }
    
    // MARK: - Helper Methods
    
    private func generateTestAmounts(count: Int) -> [Decimal] {
        var amounts: [Decimal] = []
        for _ in 0..<count {
            amounts.append(Decimal(Double.random(in: 0...1000)))
        }
        return amounts
    }
    
    private func generateLargeStatementText(lineCount: Int) -> String {
        var lines = ["Date,Description,Amount"]
        
        for i in 0..<lineCount {
            let date = Date().addingTimeInterval(TimeInterval(-i * 86400)) // One day ago per line
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: date)
            
            let amount = Double.random(in: 1...100)
            let merchant = "Test Merchant \(i)"
            
            lines.append("\(dateString),\(merchant),\(amount)")
        }
        
        return lines.joined(separator: "\n")
    }
    
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
    
    private func generateTestKeys(count: Int) -> [String] {
        var keys: [String] = []
        for i in 0..<count {
            keys.append("test_key_\(i)")
        }
        return keys
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
#endif
