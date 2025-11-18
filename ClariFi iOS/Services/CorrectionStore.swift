//
//  CorrectionStore.swift
//  ClariFi iOS
//
//  Created by AI Assistant on 2025-10-10.
//
//  Thread-safe store for transaction corrections using Swift actors
//

import Foundation

/// Thread-safe store for transaction corrections
actor CorrectionStore {
    
    // MARK: - Properties
    
    private var corrections: [TransactionCorrection] = []
    private let maxCorrections = 1000 // Prevent unlimited growth
    
    // MARK: - Public Methods
    
    /// Add new corrections to the store
    func add(_ newCorrections: [TransactionCorrection]) {
        corrections.append(contentsOf: newCorrections)
        
        // Limit size to prevent memory issues
        if corrections.count > maxCorrections {
            // Remove oldest corrections (simple FIFO)
            let excessCount = corrections.count - maxCorrections
            corrections.removeFirst(excessCount)
        }
    }
    
    /// Get all corrections
    func getAll() -> [TransactionCorrection] {
        return corrections
    }
    
    /// Get corrections for a specific merchant
    func getForMerchant(_ merchant: String) -> [TransactionCorrection] {
        return corrections.filter { correction in
            correction.correctedMerchant?.lowercased() == merchant.lowercased()
        }
    }

    /// Get corrections for a specific amount range
    func getForAmountRange(_ minAmount: Decimal, _ maxAmount: Decimal) -> [TransactionCorrection] {
        return corrections.filter { correction in
            guard let amount = correction.correctedAmount else { return false }
            return amount >= minAmount && amount <= maxAmount
        }
    }
    
    /// Clear all corrections
    func clear() {
        corrections.removeAll()
    }
    
    /// Get the number of stored corrections
    var count: Int {
        return corrections.count
    }
    
    /// Check if store is empty
    var isEmpty: Bool {
        return corrections.isEmpty
    }
}
