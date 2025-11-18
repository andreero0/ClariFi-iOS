import Foundation
import SwiftUI

@MainActor
class TransactionReviewViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var transactions: [ParsedTransaction] = []
    @Published var editedTransactions: [String: ParsedTransaction] = [:]
    
    // MARK: - Private Properties
    private let parserService: TransactionParserService
    
    // MARK: - Initialization
    init(parserService: TransactionParserService) {
        self.parserService = parserService
        super.init()
    }
    
    // MARK: - Public Methods
    
    func setTransactions(_ transactions: [ParsedTransaction]) {
        self.transactions = transactions
        self.editedTransactions.removeAll()
    }
    
    func updateTransaction(_ original: ParsedTransaction, with updated: ParsedTransaction) {
        let key = transactionKey(original)
        editedTransactions[key] = updated
        
        // Create correction for learning
        let correction = TransactionCorrection(
            originalText: original.rawText,
            correctedDate: updated.date != original.date ? updated.date : nil,
            correctedMerchant: updated.merchant != original.merchant ? updated.merchant : nil,
            correctedAmount: updated.amount != original.amount ? updated.amount : nil,
            feedback: determineFeedback(original: original, updated: updated)
        )
        
        // Submit correction for learning
        Task {
            await parserService.improveAccuracy(with: [correction])
        }
    }
    
    func applyBatchChanges(to transaction: ParsedTransaction, changes: BatchEditChanges) {
        let key = transactionKey(transaction)
        
        var updatedTransaction = editedTransactions[key] ?? transaction
        
        if let newCategory = changes.category {
            updatedTransaction = ParsedTransaction(
                date: updatedTransaction.date,
                merchant: updatedTransaction.merchant,
                amount: updatedTransaction.amount,
                confidence: updatedTransaction.confidence,
                rawText: updatedTransaction.rawText,
                lineNumber: updatedTransaction.lineNumber,
                category: newCategory,
                transactionType: updatedTransaction.transactionType
            )
        }
        
        editedTransactions[key] = updatedTransaction
    }
    
    func getFinalTransactions() -> [ParsedTransaction] {
        return transactions.map { transaction in
            let key = transactionKey(transaction)
            return editedTransactions[key] ?? transaction
        }
    }
    
    func getTransactionStats() -> TransactionStats {
        let finalTransactions = getFinalTransactions()
        
        let totalAmount = finalTransactions.compactMap { $0.amount }.reduce(0, +)
        let lowConfidenceCount = finalTransactions.filter { $0.confidence.overall < 0.8 }.count
        let editedCount = editedTransactions.count
        
        return TransactionStats(
            totalCount: finalTransactions.count,
            totalAmount: totalAmount,
            lowConfidenceCount: lowConfidenceCount,
            editedCount: editedCount
        )
    }
    
    func validateTransactions() -> [ValidationError] {
        let finalTransactions = getFinalTransactions()
        var errors: [ValidationError] = []
        
        for (index, transaction) in finalTransactions.enumerated() {
            // Check for missing required fields
            if transaction.date == nil {
                errors.append(.missingDate(index: index))
            }
            
            if transaction.merchant?.isEmpty != false {
                errors.append(.missingMerchant(index: index))
            }
            
            if transaction.amount == nil || transaction.amount == 0 {
                errors.append(.missingAmount(index: index))
            }
            
            // Check for suspicious amounts
            if let amount = transaction.amount, amount < 0 {
                errors.append(.negativeAmount(index: index))
            }
            
            if let amount = transaction.amount, amount > 10000 {
                errors.append(.unusuallyLargeAmount(index: index, amount: amount))
            }
        }
        
        return errors
    }
    
    // MARK: - Private Methods
    
    private func transactionKey(_ transaction: ParsedTransaction) -> String {
        return "\(transaction.lineNumber)_\(transaction.rawText.hashValue)"
    }
    
    private func determineFeedback(original: ParsedTransaction, updated: ParsedTransaction) -> CorrectionFeedback {
        if updated.date != original.date {
            return .dateWrong
        } else if updated.merchant != original.merchant {
            return .merchantWrong
        } else if updated.amount != original.amount {
            return .amountWrong
        } else {
            return .dateWrong // Default fallback
        }
    }
}

// MARK: - Supporting Types

struct TransactionStats {
    let totalCount: Int
    let totalAmount: Decimal
    let lowConfidenceCount: Int
    let editedCount: Int
    
    var averageAmount: Decimal {
        guard totalCount > 0 else { return 0 }
        return totalAmount / Decimal(totalCount)
    }
    
    var needsReviewPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(lowConfidenceCount) / Double(totalCount) * 100
    }
}

enum ValidationError: LocalizedError, Identifiable {
    case missingDate(index: Int)
    case missingMerchant(index: Int)
    case missingAmount(index: Int)
    case negativeAmount(index: Int)
    case unusuallyLargeAmount(index: Int, amount: Decimal)
    
    var id: String {
        switch self {
        case .missingDate(let index):
            return "missing_date_\(index)"
        case .missingMerchant(let index):
            return "missing_merchant_\(index)"
        case .missingAmount(let index):
            return "missing_amount_\(index)"
        case .negativeAmount(let index):
            return "negative_amount_\(index)"
        case .unusuallyLargeAmount(let index, _):
            return "large_amount_\(index)"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .missingDate(let index):
            return "Transaction \(index + 1): Missing date"
        case .missingMerchant(let index):
            return "Transaction \(index + 1): Missing merchant name"
        case .missingAmount(let index):
            return "Transaction \(index + 1): Missing or invalid amount"
        case .negativeAmount(let index):
            return "Transaction \(index + 1): Amount cannot be negative"
        case .unusuallyLargeAmount(let index, let amount):
            return "Transaction \(index + 1): Unusually large amount (\(amount)). Please verify."
        }
    }
    
    var transactionIndex: Int {
        switch self {
        case .missingDate(let index),
             .missingMerchant(let index),
             .missingAmount(let index),
             .negativeAmount(let index),
             .unusuallyLargeAmount(let index, _):
            return index
        }
    }
}