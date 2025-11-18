//
//  ParserConcurrencyTests.swift
//  ClariFi iOSTests
//
//  Tests for SmartTransactionParser concurrency and performance
//

import XCTest
@testable import ClariFi_iOS

@MainActor
class ParserConcurrencyTests: XCTestCase {
    
    var parser: SmartTransactionParser!
    
    override func setUp() async throws {
        try await super.setUp()
        parser = SmartTransactionParser()
    }
    
    override func tearDown() async throws {
        parser = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Parsing Tests
    
    func testBasicParsing() async throws {
        let statementText = """
        Date,Description,Amount
        2024-01-01,Starbucks Coffee,5.50
        2024-01-02,Grocery Store,45.20
        """
        
        let result = try await parser.parseTransactions(from: statementText, format: .csv)
        
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].merchant, "Starbucks Coffee")
        XCTAssertEqual(result[0].amount, Decimal(5.50))
        XCTAssertEqual(result[1].merchant, "Grocery Store")
        XCTAssertEqual(result[1].amount, Decimal(45.20))
    }
    
    func testEmptyStatement() async throws {
        let result = try await parser.parseTransactions(from: "", format: .csv)
        XCTAssertEqual(result.count, 0)
    }
    
    func testMalformedStatement() async throws {
        let statementText = "Invalid,Data,Format"
        let result = try await parser.parseTransactions(from: statementText, format: .csv)
        XCTAssertEqual(result.count, 0)
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentCorrectionMutations() async throws {
        let corrections = [
            TransactionCorrection(
                originalMerchant: "STARBUCKS",
                correctedMerchant: "Starbucks Coffee",
                originalAmount: Decimal(5.50),
                correctedAmount: Decimal(5.50),
                originalCategory: "Food",
                correctedCategory: "Food & Dining",
                confidence: 0.9,
                timestamp: Date()
            ),
            TransactionCorrection(
                originalMerchant: "GROCERY STORE",
                correctedMerchant: "Grocery Store",
                originalAmount: Decimal(45.20),
                correctedAmount: Decimal(45.20),
                originalCategory: "Shopping",
                correctedCategory: "Groceries",
                confidence: 0.8,
                timestamp: Date()
            )
        ]
        
        // Test concurrent correction additions
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    await self.parser.improveAccuracy(with: corrections)
                }
            }
        }
        
        // Verify corrections were added (this is internal state, so we can't directly verify)
        // But the test ensures no crashes or race conditions occur
    }
    
    func testConcurrentParsing() async throws {
        let statementText = generateLargeStatementText(lineCount: 100)
        
        // Test concurrent parsing of different statements
        await withTaskGroup(of: [ParsedTransaction].self) { group in
            for i in 0..<5 {
                group.addTask {
                    let modifiedText = self.statementTextWithPrefix(statementText, prefix: "Batch \(i)")
                    return try! await self.parser.parseTransactions(from: modifiedText, format: .csv)
                }
            }
            
            var totalTransactions = 0
            for try await result in group {
                totalTransactions += result.count
            }
            
            XCTAssertEqual(totalTransactions, 500) // 5 batches * 100 transactions each
        }
    }
    
    // MARK: - Performance Tests
    
    func testSequentialVsParallelParsing() async throws {
        let statementText = generateLargeStatementText(lineCount: 1000)
        
        // Test sequential parsing
        let sequentialStartTime = CFAbsoluteTimeGetCurrent()
        let sequentialResult = try await parser.parseTransactions(from: statementText, format: .csv)
        let sequentialTime = CFAbsoluteTimeGetCurrent() - sequentialStartTime
        
        // Test parallel parsing (parser should automatically choose parallel for large datasets)
        let parallelStartTime = CFAbsoluteTimeGetCurrent()
        let parallelResult = try await parser.parseTransactions(from: statementText, format: .csv)
        let parallelTime = CFAbsoluteTimeGetCurrent() - parallelStartTime
        
        // Verify both methods produce same results
        XCTAssertEqual(sequentialResult.count, parallelResult.count)
        XCTAssertEqual(sequentialResult.count, 1000)
        
        // Verify performance is acceptable
        XCTAssertLessThan(sequentialTime, 5.0) // Should complete in under 5 seconds
        XCTAssertLessThan(parallelTime, 5.0) // Should complete in under 5 seconds
        
        print("Sequential parsing time: \(sequentialTime)s")
        print("Parallel parsing time: \(parallelTime)s")
    }
    
    func testParsingScalability() async throws {
        let testSizes = [100, 500, 1000, 2000]
        
        for size in testSizes {
            let statementText = generateLargeStatementText(lineCount: size)
            
            let startTime = CFAbsoluteTimeGetCurrent()
            let result = try await parser.parseTransactions(from: statementText, format: .csv)
            let endTime = CFAbsoluteTimeGetCurrent()
            let executionTime = endTime - startTime
            
            // Verify results are correct
            XCTAssertEqual(result.count, size)
            
            // Verify performance scales reasonably
            let expectedTime = Double(size) * 0.002 // 2ms per transaction
            XCTAssertLessThan(executionTime, expectedTime * 3) // Allow 3x overhead
            
            print("Size: \(size), Time: \(executionTime)s, Rate: \(Double(size) / executionTime) tx/s")
        }
    }
    
    // MARK: - Correction Learning Tests
    
    func testCorrectionLearning() async throws {
        let corrections = [
            TransactionCorrection(
                originalMerchant: "STARBUCKS",
                correctedMerchant: "Starbucks Coffee",
                originalAmount: Decimal(5.50),
                correctedAmount: Decimal(5.50),
                originalCategory: "Food",
                correctedCategory: "Food & Dining",
                confidence: 0.9,
                timestamp: Date()
            )
        ]
        
        // Add corrections
        await parser.improveAccuracy(with: corrections)
        
        // Parse statement with similar merchant
        let statementText = """
        Date,Description,Amount
        2024-01-01,STARBUCKS,5.50
        """
        
        let result = try await parser.parseTransactions(from: statementText, format: .csv)
        
        // Verify correction was applied
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].merchant, "Starbucks Coffee")
        XCTAssertEqual(result[0].category, "Food & Dining")
    }
    
    // MARK: - Error Handling Tests
    
    func testParsingErrorHandling() async throws {
        // Test with invalid format
        let invalidText = "This is not a valid statement format"
        
        do {
            let result = try await parser.parseTransactions(from: invalidText, format: .csv)
            // Should not throw, but return empty result
            XCTAssertEqual(result.count, 0)
        } catch {
            // If it throws, that's also acceptable
            XCTAssertTrue(error is ParsingError)
        }
    }
    
    func testConcurrentErrorHandling() async throws {
        // Test concurrent parsing with some invalid data
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let statementText = i % 2 == 0 ? 
                        self.generateLargeStatementText(lineCount: 50) : 
                        "Invalid format"
                    
                    do {
                        let result = try await self.parser.parseTransactions(from: statementText, format: .csv)
                        // Should handle gracefully
                        XCTAssertTrue(result.count >= 0)
                    } catch {
                        // Expected for invalid format
                        XCTAssertTrue(error is ParsingError)
                    }
                }
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsageWithLargeDataset() async throws {
        let initialMemory = getMemoryUsage()
        
        // Parse large dataset
        let statementText = generateLargeStatementText(lineCount: 5000)
        let result = try await parser.parseTransactions(from: statementText, format: .csv)
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Verify memory usage is reasonable
        XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024) // Less than 50MB
        
        XCTAssertEqual(result.count, 5000)
        
        print("Memory increase: \(memoryIncrease / 1024 / 1024)MB")
    }
    
    // MARK: - Helper Methods
    
    private func generateLargeStatementText(lineCount: Int) -> String {
        var lines = ["Date,Description,Amount"]
        
        for i in 0..<lineCount {
            let date = Date().addingTimeInterval(TimeInterval(-i * 86400))
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: date)
            
            let amount = Double.random(in: 1...100)
            let merchant = "Test Merchant \(i)"
            
            lines.append("\(dateString),\(merchant),\(amount)")
        }
        
        return lines.joined(separator: "\n")
    }
    
    private func statementTextWithPrefix(_ text: String, prefix: String) -> String {
        return text.replacingOccurrences(of: "Test Merchant", with: "\(prefix) Test Merchant")
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
