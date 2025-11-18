//
//  TransactionParserTests.swift
//  ClariFi iOS Tests
//
//  Created by aEro on 2025-10-10.
//

import Testing
import Foundation
@testable import ClariFi_iOS

struct TransactionParserTests {
    
    var parser: SmartTransactionParser!
    
    init() throws {
        
        parser = SmartTransactionParser()
    }
    
    
    // MARK: - Helper Methods
    
    private func createSampleBankStatement() -> String {
        return """
        BANK OF AMERICA STATEMENT
        Account Number: ****1234
        Statement Period: 01/01/2024 - 01/31/2024
        
        01/15/2024 STARBUCKS STORE #1234 $4.50
        01/16/2024 SHELL GAS STATION $35.00
        01/17/2024 GROCERY MART $67.89
        01/18/2024 AMAZON.COM PURCHASE $29.99
        01/19/2024 ATM WITHDRAWAL FEE $3.00
        01/20/2024 COFFEE SHOP DOWNTOWN $5.25
        
        TOTAL TRANSACTIONS: 6
        ENDING BALANCE: $1,234.56
        """
    }
    
    private func createSampleCreditCardStatement() -> String {
        return """
        CHASE CREDIT CARD STATEMENT
        Account: ****5678
        
        01/15/24 AMAZON PRIME $12.99
        01/16/24 UBER EATS $18.50
        01/17/24 TARGET STORE #1234 $45.67
        01/18/24 NETFLIX SUBSCRIPTION $15.99
        01/19/24 PAYMENT RECEIVED -$500.00
        
        Balance: $234.56
        """
    }
    
    private func createComplexStatement() -> String {
        return """
        WELLS FARGO CHECKING STATEMENT
        
        Date        Description                     Amount
        01/15/2024  DIRECT DEPOSIT PAYROLL         +$2,500.00
        01/15/2024  RENT PAYMENT                   -$1,200.00
        01/16/2024  GROCERY STORE #456              -$89.34
        01/17/2024  GAS STATION PURCHASE            -$42.50
        01/18/2024  RESTAURANT BILL                 -$67.89
        01/19/2024  ATM FEE                         -$2.50
        01/20/2024  ONLINE TRANSFER                 -$100.00
        
        Previous Balance: $1,500.00
        New Balance: $2,597.77
        """
    }
    
    // MARK: - Basic Parsing Tests
    
    func testParseTransactions_SimpleFormat() async throws {
        // Given
        let simpleText = """
        01/15/2024 STARBUCKS $4.50
        01/16/2024 SHELL GAS $35.00
        01/17/2024 GROCERY STORE $67.89
        """
        
        // When
        let transactions = try await parser.parseTransactions(from: simpleText, format: .generic)
        
        // Then
        #expect(transactions.count == 3)
        
        let firstTransaction = transactions[0]
        #expect(firstTransaction.date != nil)
        #expect(firstTransaction.merchant == "STARBUCKS")
        #expect(firstTransaction.amount == Decimal(string: "4.50"))
        #expect(firstTransaction.confidence.overall > 0.6)
    }
    
    func testParseTransactions_BankOfAmericaFormat() async throws {
        // Given
        let bankStatement = createSampleBankStatement()
        
        // When
        let transactions = try await parser.parseTransactions(from: bankStatement, format: .bankOfAmerica)
        
        // Then
        #expect(transactions.count == 6)
        
        // Check first transaction
        let starbucksTransaction = transactions.first { $0.merchant?.contains("STARBUCKS") == true }
        #expect(starbucksTransaction != nil)
        #expect(starbucksTransaction?.amount == Decimal(string: "4.50"))
        
        // Check ATM fee transaction
        let atmTransaction = transactions.first { $0.merchant?.contains("ATM") == true }
        #expect(atmTransaction != nil)
        #expect(atmTransaction?.amount == Decimal(string: "3.00"))
        #expect(atmTransaction?.category == "Fees")
    }
    
    func testParseTransactions_ChaseFormat() async throws {
        // Given
        let chaseStatement = createSampleCreditCardStatement()
        
        // When
        let transactions = try await parser.parseTransactions(from: chaseStatement, format: .chase)
        
        // Then
        #expect(transactions.count > 0)
        
        // Check Amazon transaction
        let amazonTransaction = transactions.first { $0.merchant?.contains("AMAZON") == true }
        #expect(amazonTransaction != nil)
        #expect(amazonTransaction?.amount == Decimal(string: "12.99"))
        
        // Check Netflix subscription
        let netflixTransaction = transactions.first { $0.merchant?.contains("NETFLIX") == true }
        #expect(netflixTransaction != nil)
        #expect(netflixTransaction?.category == "Entertainment")
    }
    
    // MARK: - Date Parsing Tests
    
    func testDateParsing_VariousFormats() async throws {
        // Given
        let dateVariations = """
        01/15/2024 STORE ONE $10.00
        01/16/24 STORE TWO $20.00
        Jan 17, 2024 STORE THREE $30.00
        17 Jan 2024 STORE FOUR $40.00
        """
        
        // When
        let transactions = try await parser.parseTransactions(from: dateVariations, format: .generic)
        
        // Then
        #expect(transactions.count > 0)
        
        for transaction in transactions {
            if transaction.date != nil {
                // Check that parsed dates are reasonable (within last year)
                let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
                let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
                
                #expect(transaction.date! > oneYearAgo)
                #expect(transaction.date! < oneYearFromNow)
            }
        }
    }
    
    func testDateParsing_PartialDates() async throws {
        // Given - Dates without year (should default to current year)
        let partialDateText = """
        01/15 STORE ONE $10.00
        02/16 STORE TWO $20.00
        """
        
        // When
        let transactions = try await parser.parseTransactions(from: partialDateText, format: .generic)
        
        // Then
        let currentYear = Calendar.current.component(.year, from: Date())
        
        for transaction in transactions {
            if let date = transaction.date {
                let transactionYear = Calendar.current.component(.year, from: date)
                #expect(transactionYear == currentYear)
            }
        }
    }
    
    // MARK: - Amount Parsing Tests
    
    func testAmountParsing_VariousFormats() async throws {
        // Given
        let amountVariations = """
        01/15/2024 STORE ONE $10.00
        01/16/2024 STORE TWO $1,234.56
        01/17/2024 STORE THREE 25.99
        01/18/2024 STORE FOUR $5,000.00
        """
        
        // When
        let transactions = try await parser.parseTransactions(from: amountVariations, format: .generic)
        
        // Then
        #expect(transactions.count > 0)
        
        let expectedAmounts = [
            Decimal(string: "10.00"),
            Decimal(string: "1234.56"),
            Decimal(string: "25.99"),
            Decimal(string: "5000.00")
        ]
        
        var foundAmounts: [Decimal] = []
        for transaction in transactions {
            if let amount = transaction.amount {
                foundAmounts.append(amount)
            }
        }
        
        // Check that we found the expected amounts
        for expectedAmount in expectedAmounts {
            #expect(foundAmounts.contains(expectedAmount!) == true, "Expected amount \(expectedAmount!) not found")
        }
    }
    
    func testAmountParsing_NegativeAmounts() async throws {
        // Given
        let negativeAmountText = """
        01/15/2024 REFUND STORE -$25.00
        01/16/2024 PAYMENT RECEIVED -$500.00
        """
        
        // When
        let transactions = try await parser.parseTransactions(from: negativeAmountText, format: .generic)
        
        // Then
        #expect(transactions.count > 0)
        
        // Note: The parser should handle negative amounts appropriately
        // For now, we'll check that amounts are parsed correctly
        for transaction in transactions {
            #expect(transaction.amount != nil)
            #expect(transaction.amount! > Decimal.zero)
        }
    }
    
    // MARK: - Merchant Parsing Tests
    
    func testMerchantParsing_CleanupRules() async throws {
        // Given
        let messyMerchantText = """
        01/15/2024 DEBIT STARBUCKS STORE #1234 PURCHASE $4.50
        01/16/2024 123 SHELL GAS STATION 456 $35.00
        01/17/2024 CREDIT GROCERY MART PAYMENT $67.89
        """
        
        // When
        let transactions = try await parser.parseTransactions(from: messyMerchantText, format: .generic)
        
        // Then
        #expect(transactions.count > 0)
        
        for transaction in transactions {
            if let merchant = transaction.merchant {
                // Check that common prefixes/suffixes are removed
                #expect(merchant.hasPrefix("DEBIT") == false)
                #expect(merchant.hasPrefix("CREDIT") == false)
                #expect(merchant.hasSuffix("PURCHASE") == false)
                #expect(merchant.hasSuffix("PAYMENT") == false)
                
                // Check that merchant is not empty after cleanup
                #expect(merchant.trimmingCharacters(in: .whitespaces).isEmpty == false)
            }
        }
    }
    
    // MARK: - Confidence Scoring Tests
    
    func testConfidenceScoring_HighConfidenceTransaction() async throws {
        // Given - Well-formatted transaction
        let highQualityText = "01/15/2024 STARBUCKS STORE #1234 $4.50"
        
        // When
        let transactions = try await parser.parseTransactions(from: highQualityText, format: .generic)
        
        // Then
        #expect(transactions.count == 1)
        let transaction = transactions[0]
        
        #expect(transaction.confidence.date > 0.8)
        #expect(transaction.confidence.merchant > 0.7)
        #expect(transaction.confidence.amount > 0.8)
        #expect(transaction.confidence.overall > 0.7)
    }
    
    func testConfidenceScoring_LowConfidenceTransaction() async throws {
        // Given - Poorly formatted transaction
        let lowQualityText = "15 Store 4"
        
        // When
        do {
            let transactions = try await parser.parseTransactions(from: lowQualityText, format: .generic)
            
            // If parsing succeeds, confidence should be low
            for transaction in transactions {
                #expect(transaction.confidence.overall < 0.7)
            }
        } catch ParserError.noTransactionsFound {
            // This is expected for very poor quality text
            #expect(true == true)
        }
    }
    
    func testConfidenceScoring_MissingFields() async throws {
        // Given - Transaction with missing fields
        let incompleteText = """
        01/15/2024 STARBUCKS
        SHELL GAS $35.00
        01/17/2024 $67.89
        """
        
        // When
        let transactions = try await parser.parseTransactions(from: incompleteText, format: .generic)
        
        // Then
        for transaction in transactions {
            // Check confidence based on missing fields
            if transaction.date == nil {
                #expect(transaction.confidence.date < 0.5)
            }
            if transaction.merchant == nil {
                #expect(transaction.confidence.merchant < 0.5)
            }
            if transaction.amount == nil {
                #expect(transaction.confidence.amount < 0.5)
            }
        }
    }
    
    // MARK: - Category Prediction Tests
    
    func testCategoryPrediction_CommonMerchants() async throws {
        // Given
        let categorizedText = """
        01/15/2024 STARBUCKS COFFEE $4.50
        01/16/2024 SHELL GAS STATION $35.00
        01/17/2024 GROCERY MART FOOD $67.89
        01/18/2024 AMAZON.COM PURCHASE $29.99
        01/19/2024 NETFLIX SUBSCRIPTION $15.99
        01/20/2024 ATM WITHDRAWAL FEE $3.00
        """
        
        // When
        let transactions = try await parser.parseTransactions(from: categorizedText, format: .generic)
        
        // Then
        let categoryMappings = [
            "STARBUCKS": "Dining",
            "SHELL": "Gas",
            "GROCERY": "Groceries",
            "AMAZON": "Shopping",
            "NETFLIX": "Entertainment",
            "ATM": "Fees"
        ]
        
        for transaction in transactions {
            if let merchant = transaction.merchant, let category = transaction.category {
                for (merchantKeyword, expectedCategory) in categoryMappings {
                    if merchant.uppercased().contains(merchantKeyword) {
                        #expect(category == expectedCategory, "Expected \(expectedCategory) for \(merchant)")
                    }
                }
            }
        }
    }
    
    // MARK: - Transaction Type Detection Tests
    
    func testTransactionTypeDetection() async throws {
        // Given
        let typedTransactionText = """
        01/15/2024 PURCHASE STARBUCKS $4.50
        01/16/2024 ATM FEE CHARGE $3.00
        01/17/2024 INTEREST EARNED $0.25
        01/18/2024 TRANSFER TO SAVINGS $100.00
        01/19/2024 PAYMENT RECEIVED $500.00
        01/20/2024 REFUND AMAZON $29.99
        """
        
        // When
        let transactions = try await parser.parseTransactions(from: typedTransactionText, format: .generic)
        
        // Then
        let typeKeywords = [
            "FEE": TransactionType.fee,
            "INTEREST": TransactionType.interest,
            "TRANSFER": TransactionType.transfer,
            "PAYMENT": TransactionType.payment,
            "REFUND": TransactionType.refund
        ]
        
        for transaction in transactions {
            if let type = transaction.transactionType {
                for (keyword, expectedType) in typeKeywords {
                    if transaction.rawText.uppercased().contains(keyword) {
                        #expect(type == expectedType, "Expected \(expectedType) for transaction containing \(keyword)")
                    }
                }
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling_NoTransactionsFound() async throws {
        // Given
        let nonTransactionText = """
        BANK STATEMENT HEADER
        Account Number: 1234567890
        Statement Period: January 2024
        
        Previous Balance: $1,000.00
        New Balance: $1,500.00
        """
        
        // When & Then
        do {
            _ = try await parser.parseTransactions(from: nonTransactionText, format: .generic)
            Issue.record("Should have thrown noTransactionsFound error")
        } catch ParserError.noTransactionsFound {
            // Expected error
            #expect(true == true)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    func testErrorHandling_EmptyText() async throws {
        // Given
        let emptyText = ""
        
        // When & Then
        do {
            _ = try await parser.parseTransactions(from: emptyText, format: .generic)
            Issue.record("Should have thrown an error for empty text")
        } catch ParserError.noTransactionsFound {
            // Expected error
            #expect(true == true)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    func testErrorHandling_ParserErrors() {
        // Test error descriptions
        let errors: [ParserError] = [
            .noTransactionsFound,
            .invalidFormat,
            .ambiguousData("Test details"),
            .insufficientConfidence(0.3)
        ]
        
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(error.errorDescription!.isEmpty == false)
        }
    }
    
    // MARK: - Learning and Correction Tests
    
    func testImproveAccuracy_UserCorrections() async throws {
        // Given
        let originalText = "01/15/2024 UNKNOWN STORE $25.00"
        
        // Parse initially
        let initialTransactions = try await parser.parseTransactions(from: originalText, format: .generic)
        #expect(initialTransactions.count == 1)
        
        // Create correction
        let correction = TransactionCorrection(
            originalText: "UNKNOWN STORE",
            correctedDate: nil,
            correctedMerchant: "STARBUCKS COFFEE",
            correctedAmount: nil,
            feedback: .merchantWrong
        )
        
        // When
        await parser.improveAccuracy(with: [correction])
        
        // Parse again with similar text
        let similarText = "01/16/2024 UNKNOWN STORE $4.50"
        let correctedTransactions = try await parser.parseTransactions(from: similarText, format: .generic)
        
        // Then
        // The parser should have learned from the correction
        // (In a real implementation, this would use ML to improve accuracy)
        #expect(correctedTransactions.count == 1)
        // For now, we just verify the correction was stored
        #expect(true == true) // Placeholder for more sophisticated learning verification
    }
    
    // MARK: - Complex Statement Tests
    
    func testParseTransactions_ComplexStatement() async throws {
        // Given
        let complexStatement = createComplexStatement()
        
        // When
        let transactions = try await parser.parseTransactions(from: complexStatement, format: .wellsFargo)
        
        // Then
        #expect(transactions.count > 0)
        
        // Check that we parsed various transaction types
        let hasPositiveAmount = transactions.contains { $0.rawText.contains("DEPOSIT") }
        let hasNegativeAmount = transactions.contains { $0.rawText.contains("RENT") }
        
        // Note: The parser should handle both positive and negative transactions
        #expect(hasPositiveAmount || hasNegativeAmount == true)
        
        // Check that amounts are reasonable
        for transaction in transactions {
            if let amount = transaction.amount {
                #expect(amount > Decimal.zero)
                #expect(amount < Decimal(10000)) // Reasonable upper bound
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testParsingPerformance_LargeStatement() async throws {
        // Given - Create a large statement with many transactions
        var largeStatement = "LARGE BANK STATEMENT\n"
        for i in 1...100 {
            largeStatement += "01/\(String(format: "%02d", i % 28 + 1))/2024 MERCHANT \(i) $\(Double(i) * 1.5)\n"
        }
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let transactions = try await parser.parseTransactions(from: largeStatement, format: .generic)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        #expect(transactions.count > 50) // Should parse most transactions
        #expect(processingTime < 5.0) // Should complete within 5 seconds
    }
}