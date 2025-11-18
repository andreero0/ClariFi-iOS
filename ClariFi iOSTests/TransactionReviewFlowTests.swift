//
//  TransactionReviewFlowTests.swift
//  ClariFi iOS Tests
//
//  Created by aEro on 2025-10-10.
//

import Testing
import Foundation
@testable import ClariFi_iOS

/// Tests for the transaction review and correction interface
struct TransactionReviewFlowTests {
    
    var viewModel: TransactionReviewViewModel!
    var mockParserService: MockParserService!
    
    init() async throws {
        
        
        mockParserService = MockParserService()
        viewModel = TransactionReviewViewModel(parserService: mockParserService)
    }
    
    
    // MARK: - Transaction Loading Tests
    
    func testSetTransactions_LoadsTransactions() async {
        // Given
        let transactions = createMockTransactions()
        
        // When
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        // Then
        await MainActor.run {
            #expect(viewModel.transactions.count == 3)
            #expect(viewModel.editedTransactions.isEmpty == true)
        }
    }
    
    func testSetTransactions_ClearsEditedTransactions() async {
        // Given
        let initialTransactions = createMockTransactions()
        await MainActor.run {
            viewModel.setTransactions(initialTransactions)
            viewModel.editedTransactions["test"] = initialTransactions[0]
        }
        
        // When
        let newTransactions = createMockTransactions(count: 2)
        await MainActor.run {
            viewModel.setTransactions(newTransactions)
        }
        
        // Then
        await MainActor.run {
            #expect(viewModel.transactions.count == 2)
            #expect(viewModel.editedTransactions.isEmpty == true)
        }
    }
    
    // MARK: - Transaction Update Tests
    
    func testUpdateTransaction_StoresEdit() async {
        // Given
        let transactions = createMockTransactions()
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        let original = transactions[0]
        let updated = ParsedTransaction(
            date: original.date,
            merchant: "UPDATED MERCHANT",
            amount: Decimal(99.99),
            confidence: TransactionConfidence(date: 1.0, merchant: 1.0, amount: 1.0),
            rawText: original.rawText,
            lineNumber: original.lineNumber,
            category: "Updated Category",
            transactionType: original.transactionType
        )
        
        // When
        await MainActor.run {
            viewModel.updateTransaction(original, with: updated)
        }
        
        // Then
        await MainActor.run {
            #expect(viewModel.editedTransactions.isEmpty == false)
        }
        #expect(mockParserService.improveAccuracyCalled == true)
    }
    
    func testUpdateTransaction_SubmitsCorrection() async {
        // Given
        let transactions = createMockTransactions()
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        let original = transactions[0]
        let updated = ParsedTransaction(
            date: Date().addingTimeInterval(86400), // Different date
            merchant: original.merchant,
            amount: original.amount,
            confidence: TransactionConfidence(date: 1.0, merchant: 1.0, amount: 1.0),
            rawText: original.rawText,
            lineNumber: original.lineNumber,
            category: original.category,
            transactionType: original.transactionType
        )
        
        // When
        await MainActor.run {
            viewModel.updateTransaction(original, with: updated)
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        #expect(mockParserService.improveAccuracyCalled == true)
        #expect(mockParserService.corrections.count == 1)
    }
    
    func testUpdateTransaction_MerchantChange_CorrectFeedback() async {
        // Given
        let transactions = createMockTransactions()
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        let original = transactions[0]
        let updated = ParsedTransaction(
            date: original.date,
            merchant: "CORRECTED MERCHANT",
            amount: original.amount,
            confidence: original.confidence,
            rawText: original.rawText,
            lineNumber: original.lineNumber,
            category: original.category,
            transactionType: original.transactionType
        )
        
        // When
        await MainActor.run {
            viewModel.updateTransaction(original, with: updated)
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        #expect(mockParserService.improveAccuracyCalled == true)
        if let correction = mockParserService.corrections.first {
            #expect(correction.feedback == .merchantWrong)
        }
    }
    
    func testUpdateTransaction_AmountChange_CorrectFeedback() async {
        // Given
        let transactions = createMockTransactions()
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        let original = transactions[0]
        let updated = ParsedTransaction(
            date: original.date,
            merchant: original.merchant,
            amount: Decimal(999.99),
            confidence: original.confidence,
            rawText: original.rawText,
            lineNumber: original.lineNumber,
            category: original.category,
            transactionType: original.transactionType
        )
        
        // When
        await MainActor.run {
            viewModel.updateTransaction(original, with: updated)
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        if let correction = mockParserService.corrections.first {
            #expect(correction.feedback == .amountWrong)
        }
    }
    
    // MARK: - Batch Edit Tests
    
    func testApplyBatchChanges_UpdatesCategory() async {
        // Given
        let transactions = createMockTransactions()
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        let changes = BatchEditChanges(category: "New Category")
        
        // When
        await MainActor.run {
            viewModel.applyBatchChanges(to: transactions[0], changes: changes)
        }
        
        // Then
        await MainActor.run {
            #expect(viewModel.editedTransactions.isEmpty == false)
        }
        
        let finalTransactions = await MainActor.run {
            viewModel.getFinalTransactions()
        }
        #expect(finalTransactions[0].category == "New Category")
    }
    
    func testApplyBatchChanges_MultipleTransactions() async {
        // Given
        let transactions = createMockTransactions()
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        let changes = BatchEditChanges(category: "Batch Category")
        
        // When
        await MainActor.run {
            for transaction in transactions {
                viewModel.applyBatchChanges(to: transaction, changes: changes)
            }
        }
        
        // Then
        let finalTransactions = await MainActor.run {
            viewModel.getFinalTransactions()
        }
        
        for transaction in finalTransactions {
            #expect(transaction.category == "Batch Category")
        }
    }
    
    // MARK: - Final Transactions Tests
    
    func testGetFinalTransactions_NoEdits_ReturnsOriginal() async {
        // Given
        let transactions = createMockTransactions()
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        // When
        let finalTransactions = await MainActor.run {
            viewModel.getFinalTransactions()
        }
        
        // Then
        #expect(finalTransactions.count == transactions.count)
        for (index, transaction) in finalTransactions.enumerated() {
            #expect(transaction.merchant == transactions[index].merchant)
            #expect(transaction.amount == transactions[index].amount)
        }
    }
    
    func testGetFinalTransactions_WithEdits_ReturnsEdited() async {
        // Given
        let transactions = createMockTransactions()
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        let updated = ParsedTransaction(
            date: transactions[0].date,
            merchant: "EDITED MERCHANT",
            amount: Decimal(123.45),
            confidence: TransactionConfidence(date: 1.0, merchant: 1.0, amount: 1.0),
            rawText: transactions[0].rawText,
            lineNumber: transactions[0].lineNumber,
            category: "Edited Category",
            transactionType: transactions[0].transactionType
        )
        
        await MainActor.run {
            viewModel.updateTransaction(transactions[0], with: updated)
        }
        
        // When
        let finalTransactions = await MainActor.run {
            viewModel.getFinalTransactions()
        }
        
        // Then
        #expect(finalTransactions[0].merchant == "EDITED MERCHANT")
        #expect(finalTransactions[0].amount == Decimal(123.45))
        #expect(finalTransactions[0].category == "Edited Category")
    }
    
    // MARK: - Transaction Stats Tests
    
    func testGetTransactionStats_CalculatesCorrectly() async {
        // Given
        let transactions = createMockTransactions()
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        // When
        let stats = await MainActor.run {
            viewModel.getTransactionStats()
        }
        
        // Then
        #expect(stats.totalCount == 3)
        #expect(stats.totalAmount == Decimal(107.39)) // 4.50 + 35.00 + 67.89
        #expect(stats.editedCount == 0)
    }
    
    func testGetTransactionStats_CountsLowConfidence() async {
        // Given
        let transactions = [
            createLowConfidenceTransaction(),
            createHighConfidenceTransaction(),
            createLowConfidenceTransaction()
        ]
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        // When
        let stats = await MainActor.run {
            viewModel.getTransactionStats()
        }
        
        // Then
        #expect(stats.lowConfidenceCount == 2)
    }
    
    func testGetTransactionStats_CountsEdits() async {
        // Given
        let transactions = createMockTransactions()
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        // Edit one transaction
        let updated = ParsedTransaction(
            date: transactions[0].date,
            merchant: "EDITED",
            amount: transactions[0].amount,
            confidence: transactions[0].confidence,
            rawText: transactions[0].rawText,
            lineNumber: transactions[0].lineNumber,
            category: transactions[0].category,
            transactionType: transactions[0].transactionType
        )
        
        await MainActor.run {
            viewModel.updateTransaction(transactions[0], with: updated)
        }
        
        // When
        let stats = await MainActor.run {
            viewModel.getTransactionStats()
        }
        
        // Then
        #expect(stats.editedCount == 1)
    }
    
    func testGetTransactionStats_CalculatesAverage() async {
        // Given
        let transactions = createMockTransactions()
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        // When
        let stats = await MainActor.run {
            viewModel.getTransactionStats()
        }
        
        // Then
        let expectedAverage = Decimal(107.39) / Decimal(3)
        #expect(stats.averageAmount == expectedAverage)
    }
    
    // MARK: - Validation Tests
    
    func testValidateTransactions_NoErrors() async {
        // Given
        let transactions = createMockTransactions()
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        // When
        let errors = await MainActor.run {
            viewModel.validateTransactions()
        }
        
        // Then
        #expect(errors.isEmpty == true)
    }
    
    func testValidateTransactions_MissingDate() async {
        // Given
        let transactions = [
            ParsedTransaction(
                date: nil,
                merchant: "TEST MERCHANT",
                amount: Decimal(10.00),
                confidence: TransactionConfidence(date: 0.5, merchant: 0.9, amount: 0.9),
                rawText: "TEST",
                lineNumber: 1,
                category: "Test",
                transactionType: .debit
            )
        ]
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        // When
        let errors = await MainActor.run {
            viewModel.validateTransactions()
        }
        
        // Then
        #expect(errors.count == 1)
        if case .missingDate(let index) = errors[0] {
            #expect(index == 0)
        } else {
            Issue.record("Expected missingDate error")
        }
    }
    
    func testValidateTransactions_MissingMerchant() async {
        // Given
        let transactions = [
            ParsedTransaction(
                date: Date(),
                merchant: nil,
                amount: Decimal(10.00),
                confidence: TransactionConfidence(date: 0.9, merchant: 0.5, amount: 0.9),
                rawText: "TEST",
                lineNumber: 1,
                category: "Test",
                transactionType: .debit
            )
        ]
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        // When
        let errors = await MainActor.run {
            viewModel.validateTransactions()
        }
        
        // Then
        XCTAssertTrue(errors.contains { error in
            if case .missingMerchant = error { return true }
            return false
        })
    }
    
    func testValidateTransactions_MissingAmount() async {
        // Given
        let transactions = [
            ParsedTransaction(
                date: Date(),
                merchant: "TEST MERCHANT",
                amount: nil,
                confidence: TransactionConfidence(date: 0.9, merchant: 0.9, amount: 0.5),
                rawText: "TEST",
                lineNumber: 1,
                category: "Test",
                transactionType: .debit
            )
        ]
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        // When
        let errors = await MainActor.run {
            viewModel.validateTransactions()
        }
        
        // Then
        XCTAssertTrue(errors.contains { error in
            if case .missingAmount = error { return true }
            return false
        })
    }
    
    func testValidateTransactions_NegativeAmount() async {
        // Given
        let transactions = [
            ParsedTransaction(
                date: Date(),
                merchant: "TEST MERCHANT",
                amount: Decimal(-10.00),
                confidence: TransactionConfidence(date: 0.9, merchant: 0.9, amount: 0.9),
                rawText: "TEST",
                lineNumber: 1,
                category: "Test",
                transactionType: .debit
            )
        ]
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        // When
        let errors = await MainActor.run {
            viewModel.validateTransactions()
        }
        
        // Then
        XCTAssertTrue(errors.contains { error in
            if case .negativeAmount = error { return true }
            return false
        })
    }
    
    func testValidateTransactions_UnusuallyLargeAmount() async {
        // Given
        let transactions = [
            ParsedTransaction(
                date: Date(),
                merchant: "TEST MERCHANT",
                amount: Decimal(15000.00),
                confidence: TransactionConfidence(date: 0.9, merchant: 0.9, amount: 0.9),
                rawText: "TEST",
                lineNumber: 1,
                category: "Test",
                transactionType: .debit
            )
        ]
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        // When
        let errors = await MainActor.run {
            viewModel.validateTransactions()
        }
        
        // Then
        XCTAssertTrue(errors.contains { error in
            if case .unusuallyLargeAmount = error { return true }
            return false
        })
    }
    
    func testValidateTransactions_MultipleErrors() async {
        // Given
        let transactions = [
            ParsedTransaction(
                date: nil,
                merchant: nil,
                amount: nil,
                confidence: TransactionConfidence(date: 0.5, merchant: 0.5, amount: 0.5),
                rawText: "TEST",
                lineNumber: 1,
                category: "Test",
                transactionType: .debit
            )
        ]
        await MainActor.run {
            viewModel.setTransactions(transactions)
        }
        
        // When
        let errors = await MainActor.run {
            viewModel.validateTransactions()
        }
        
        // Then
        #expect(errors.count == 3) // Missing date, merchant, and amount
    }
    
    // MARK: - Helper Methods
    
    private func createMockTransactions(count: Int = 3) -> [ParsedTransaction] {
        let baseTransactions = [
            ParsedTransaction(
                date: Date(),
                merchant: "STARBUCKS",
                amount: Decimal(4.50),
                confidence: TransactionConfidence(date: 0.95, merchant: 0.90, amount: 0.95),
                rawText: "01/15/2024 STARBUCKS $4.50",
                lineNumber: 1,
                category: "Dining",
                transactionType: .debit
            ),
            ParsedTransaction(
                date: Date(),
                merchant: "SHELL GAS",
                amount: Decimal(35.00),
                confidence: TransactionConfidence(date: 0.90, merchant: 0.85, amount: 0.92),
                rawText: "01/16/2024 SHELL GAS $35.00",
                lineNumber: 2,
                category: "Gas",
                transactionType: .debit
            ),
            ParsedTransaction(
                date: Date(),
                merchant: "GROCERY MART",
                amount: Decimal(67.89),
                confidence: TransactionConfidence(date: 0.93, merchant: 0.88, amount: 0.94),
                rawText: "01/17/2024 GROCERY MART $67.89",
                lineNumber: 3,
                category: "Groceries",
                transactionType: .debit
            )
        ]
        
        return Array(baseTransactions.prefix(count))
    }
    
    private func createLowConfidenceTransaction() -> ParsedTransaction {
        return ParsedTransaction(
            date: Date(),
            merchant: "LOW CONFIDENCE",
            amount: Decimal(10.00),
            confidence: TransactionConfidence(date: 0.6, merchant: 0.5, amount: 0.7),
            rawText: "LOW CONFIDENCE TEXT",
            lineNumber: 1,
            category: "Unknown",
            transactionType: .debit
        )
    }
    
    private func createHighConfidenceTransaction() -> ParsedTransaction {
        return ParsedTransaction(
            date: Date(),
            merchant: "HIGH CONFIDENCE",
            amount: Decimal(20.00),
            confidence: TransactionConfidence(date: 0.95, merchant: 0.92, amount: 0.98),
            rawText: "HIGH CONFIDENCE TEXT",
            lineNumber: 2,
            category: "Test",
            transactionType: .debit
        )
    }
}

// MARK: - Mock Parser Service

class MockParserService: TransactionParserService {
    var improveAccuracyCalled = false
    var corrections: [TransactionCorrection] = []
    
    func parseTransactions(from text: String, format: StatementFormat) async throws -> [ParsedTransaction] {
        return []
    }
    
    func improveAccuracy(with userCorrections: [TransactionCorrection]) async {
        improveAccuracyCalled = true
        corrections.append(contentsOf: userCorrections)
    }
}
