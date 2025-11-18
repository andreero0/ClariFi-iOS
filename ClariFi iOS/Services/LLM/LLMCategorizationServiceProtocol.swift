//
//  LLMCategorizationServiceProtocol.swift
//  ClariFi
//
//  Protocol for LLM-based transaction categorization and data extraction
//

import Foundation

// MARK: - Categorization Method
// Note: CategorizationMethod is defined in Models/Transaction+Extensions.swift

// MARK: - Transaction Data

/// Represents extracted transaction data from text
struct TransactionData: Identifiable {
    let id = UUID()
    let date: Date?
    let merchant: String
    let normalizedMerchant: String?
    let amount: Decimal
    let category: String?
    let confidence: Float
    let rawText: String
}

// MARK: - LLM Categorization Result

/// Extended categorization result with LLM-specific information
struct LLMCategorizationResult {
    let category: String
    let confidence: Float
    let normalizedMerchant: String?
    let method: CategorizationMethod
    var reasoning: String?
}

// MARK: - Protocol

/// Service protocol for LLM-based categorization and data extraction
protocol LLMCategorizationServiceProtocol {
    
    /// Categorizes a transaction using LLM with fallback to pattern matching
    /// - Parameters:
    ///   - merchant: The merchant name
    ///   - amount: The transaction amount
    ///   - context: Optional additional context (e.g., transaction description)
    /// - Returns: Categorization result with method used
    func categorizeWithLLM(
        merchant: String,
        amount: Decimal,
        context: String?
    ) async throws -> LLMCategorizationResult
    
    /// Normalizes a merchant name using LLM
    /// - Parameter merchant: The raw merchant name
    /// - Returns: Normalized merchant name
    func normalizeMerchantName(_ merchant: String) async throws -> String
    
    /// Extracts transaction data from text using LLM
    /// - Parameter text: Raw text containing transaction information
    /// - Returns: Array of extracted transaction data
    func extractTransactionData(from text: String) async throws -> [TransactionData]
}
