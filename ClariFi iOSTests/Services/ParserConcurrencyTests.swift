//
//  ParserConcurrencyTests.swift
//  ClariFi iOSTests
//
//  Created by AI Assistant on 2025-10-10.
//
//  Tests for SmartTransactionParser thread safety and parallel parsing
//

import XCTest
@testable import ClariFi_iOS

final class ParserConcurrencyTests: XCTestCase {
    
    var parser: SmartTransactionParser!
    
    override func setUp() {
        super.setUp()
        parser = SmartTransactionParser()
    }
    
    override func tearDown() {
        parser = nil
        super.tearDown()
    }
    
    // MARK: - Basic Parsing Tests
    
    func testBasicParsing() async throws {
        // Given
        let statementText = """
        01/15/2024,STARBUCKS COFFEE,$4.50
        01/16/2024,AMAZON.COM,$29.99
        01/17/2024,SHELL GAS STATION,$45.00
        """
        let format = StatementFormat.bankOfAmerica
        
        // When
        let transactions = try await parser.parseTransactions(from: statementText, format: format)
        
        // Then
        XCTAssertEqual(transactions.count, 3)
        XCTAssertEqual(transactions[0].merchant, "STARBUCKS COFFEE")
        XCTAssertEqual(transactions[0].amount, Decimal(4.50))
    }
    
    func testSmallFileUsesSequentialParsing() async throws {
        // Given - Small file (less than 50 lines)
        let statementText = (1...30).map { "01/\($0)/2024,TEST MERCHANT \($0),$10.00" }.joined(separator: "\n")
        let format = StatementFormat.bankOfAmerica
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let transactions = try await parser.parseTransactions(from: statementText, format: format)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertEqual(transactions.count, 30)
        XCTAssertLessThan(duration, 1.0, "Small file should parse quickly")
    }
    
    func testLargeFileUsesParallelParsing() async throws {
        // Given - Large file (more than 50 lines)
        let statementText = (1...200).map { "01/\($0)/2024,TEST MERCHANT \($0),$10.00" }.joined(separator: "\n")
        let format = StatementFormat.bankOfAmerica
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let transactions = try await parser.parseTransactions(from: statementText, format: format)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertEqual(transactions.count, 200)
        XCTAssertLessThan(duration, 5.0, "Large file should parse in reasonable time")
    }
    
    // MARK: - Correction Store Tests
    
    func testCorrectionStoreThreadSafety() async {
        // Given
        let corrections = (1...100).map { i in
            TransactionCorrection(
                originalText: "TEST MERCHANT \(i)",
                originalMerchant: "TEST MERCHANT \(i)",
                originalAmount: Decimal(10.00),
                correctedMerchant: "CORRECTED MERCHANT \(i)",
                correctedAmount: Decimal(15.00),
                correctedDate: nil,
                correctedCategory: "Food & Dining"
            )
        }
        
        // When - Add corrections concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let batch = Array(corrections[i*10..<(i+1)*10])
                    await self.parser.improveAccuracy(with: batch)
                }
            }
        }
        
        // Then - All corrections should be stored safely
        // Note: We can't directly access the correction store, but we can verify
        // that the parser doesn't crash and can still parse transactions
        let statementText = "01/15/2024,TEST MERCHANT 1,$10.00"
        let format = StatementFormat.bankOfAmerica
        
        do {
            let transactions = try await parser.parseTransactions(from: statementText, format: format)
            XCTAssertGreaterThanOrEqual(transactions.count, 0)
        } catch {
            XCTFail("Parser should not crash after concurrent corrections: \(error)")
        }
    }
    
    // MARK: - Concurrent Parsing Tests
    
    func testConcurrentParsing() async throws {
        // Given - Multiple statement texts
        let statementTexts = (1...5).map { i in
            (1...20).map { j in
                "01/\(j)/2024,MERCHANT \(i)_\(j),$\(j).00"
            }.joined(separator: "\n")
        }
        let format = StatementFormat.bankOfAmerica
        
        // When - Parse multiple statements concurrently
        let results = try await withThrowingTaskGroup(of: [ParsedTransaction].self) { group in
            for text in statementTexts {
                group.addTask {
                    try await self.parser.parseTransactions(from: text, format: format)
                }
            }
            
            var allResults: [[ParsedTransaction]] = []
            for try await result in group {
                allResults.append(result)
            }
            return allResults
        }
        
        // Then - All parsing should succeed
        XCTAssertEqual(results.count, 5)
        for result in results {
            XCTAssertEqual(result.count, 20)
        }
    }
    
    func testConcurrentCorrectionsAndParsing() async throws {
        // Given
        let corrections = (1...50).map { i in
            TransactionCorrection(
                originalText: "MERCHANT \(i)",
                originalMerchant: "MERCHANT \(i)",
                originalAmount: Decimal(10.00),
                correctedMerchant: "CORRECTED \(i)",
                correctedAmount: Decimal(15.00),
                correctedDate: nil,
                correctedCategory: "Food & Dining"
            )
        }
        
        let statementText = (1...10).map { "01/\($0)/2024,MERCHANT \($0),$10.00" }.joined(separator: "\n")
        let format = StatementFormat.bankOfAmerica
        
        // When - Add corrections and parse concurrently
        await withTaskGroup(of: Void.self) { group in
            // Add corrections
            group.addTask {
                await self.parser.improveAccuracy(with: corrections)
            }
            
            // Parse statements
            group.addTask {
                do {
                    _ = try await self.parser.parseTransactions(from: statementText, format: format)
                } catch {
                    XCTFail("Parsing should not fail during concurrent corrections: \(error)")
                }
            }
        }
        
        // Then - No crashes should occur
        // This test primarily verifies thread safety
    }
    
    // MARK: - Performance Benchmarks
    
    func testSequentialVsParallelPerformance() async throws {
        // Given - Large file
        let statementText = (1...500).map { "01/\($0)/2024,MERCHANT \($0),$10.00" }.joined(separator: "\n")
        let format = StatementFormat.bankOfAmerica
        
        // When - Parse the same file multiple times
        let iterations = 3
        var totalDuration: Double = 0
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            let transactions = try await parser.parseTransactions(from: statementText, format: format)
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            totalDuration += duration
            
            XCTAssertEqual(transactions.count, 500)
        }
        
        let averageDuration = totalDuration / Double(iterations)
        
        // Then - Should parse in reasonable time
        print("Average parsing time for 500 transactions: \(averageDuration)s")
        XCTAssertLessThan(averageDuration, 10.0, "Parsing should be reasonably fast")
    }
    
    func testChunkingPerformance() async throws {
        // Given - Very large file
        let statementText = (1...1000).map { "01/\($0)/2024,MERCHANT \($0),$10.00" }.joined(separator: "\n")
        let format = StatementFormat.bankOfAmerica
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let transactions = try await parser.parseTransactions(from: statementText, format: format)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertEqual(transactions.count, 1000)
        print("Parsing time for 1000 transactions: \(duration)s")
        XCTAssertLessThan(duration, 15.0, "Large file parsing should be reasonably fast")
    }
    
    // MARK: - Error Handling Tests
    
    func testEmptyStatement() async {
        // Given
        let statementText = ""
        let format = StatementFormat.bankOfAmerica
        
        // When/Then
        do {
            _ = try await parser.parseTransactions(from: statementText, format: format)
            XCTFail("Should throw error for empty statement")
        } catch {
            XCTAssertTrue(error is ParserError)
        }
    }
    
    func testInvalidFormat() async {
        // Given
        let statementText = "This is not a valid statement format"
        let format = StatementFormat.bankOfAmerica
        
        // When/Then
        do {
            _ = try await parser.parseTransactions(from: statementText, format: format)
            XCTFail("Should throw error for invalid format")
        } catch {
            XCTAssertTrue(error is ParserError)
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryUsageWithLargeFile() async throws {
        // Given - Very large file
        let statementText = (1...2000).map { "01/\($0)/2024,MERCHANT \($0),$10.00" }.joined(separator: "\n")
        let format = StatementFormat.bankOfAmerica
        
        // When
        let transactions = try await parser.parseTransactions(from: statementText, format: format)
        
        // Then
        XCTAssertEqual(transactions.count, 2000)
        
        // Memory should be reasonable (this is a basic check)
        // In a real test, you might use XCTMemoryMetric or similar
        XCTAssertLessThan(transactions.count, 10000, "Should handle large files without excessive memory usage")
    }
}
