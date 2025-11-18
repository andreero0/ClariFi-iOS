//
//  TransactionEditData.swift
//  ClariFi iOS
//
//  Data model for transaction editing with validation
//

import Foundation

/// Data structure for editing transaction information with built-in validation.
///
/// This model provides a mutable representation of transaction data for editing purposes,
/// separate from the Core Data `Transaction` entity. It includes validation logic and
/// change detection to support efficient updates.
///
/// ## Usage
/// ```swift
/// // Initialize from existing transaction
/// var editData = TransactionEditData(from: transaction)
///
/// // Modify fields
/// editData.merchant = "New Merchant"
/// editData.amount = 50.00
///
/// // Validate before saving
/// if editData.isValid {
///     // Save changes
/// } else {
///     // Show validation errors
///     print(editData.validationErrors)
/// }
/// ```
struct TransactionEditData {
    var id: UUID
    var date: Date
    var merchant: String
    var amount: Decimal
    var category: String
    var notes: String
    
    /// Initialize from an existing Core Data transaction entity.
    ///
    /// - Parameter transaction: The Core Data transaction to copy data from
    init(from transaction: Transaction) {
        self.id = transaction.id ?? UUID()
        self.date = transaction.date ?? Date()
        self.merchant = transaction.merchant ?? ""
        self.amount = transaction.amount?.decimalValue ?? 0
        self.category = transaction.category ?? ""
        self.notes = transaction.notes ?? ""
    }
    
    /// Initialize with default values for creating a new transaction.
    init() {
        self.id = UUID()
        self.date = Date()
        self.merchant = ""
        self.amount = 0
        self.category = ""
        self.notes = ""
    }
    
    /// Validates all transaction fields.
    ///
    /// - Returns: `true` if all required fields are valid, `false` otherwise
    var isValid: Bool {
        return !merchant.trimmingCharacters(in: .whitespaces).isEmpty &&
               amount != 0 &&
               !category.isEmpty
    }
    
    /// Returns a list of validation error messages for invalid fields.
    ///
    /// - Returns: Array of human-readable error messages, empty if all fields are valid
    var validationErrors: [String] {
        var errors: [String] = []
        
        if merchant.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Merchant name is required")
        }
        
        if amount == 0 {
            errors.append("Amount must be greater than zero")
        }
        
        if category.isEmpty {
            errors.append("Please select a category")
        }
        
        return errors
    }
    
    /// Compares this edit data with the original transaction to detect changes.
    ///
    /// This method is useful for efficient updates, allowing you to update only
    /// the fields that have actually changed.
    ///
    /// - Parameter original: The original transaction to compare against
    /// - Returns: A `TransactionChanges` struct containing only the modified fields
    func changes(from original: Transaction) -> TransactionChanges {
        let originalDate = original.date ?? Date()
        let originalMerchant = original.merchant ?? ""
        let originalAmount = original.amount?.decimalValue ?? 0
        let originalCategory = original.category ?? ""
        let originalNotes = original.notes ?? ""
        
        return TransactionChanges(
            date: date != originalDate ? date : nil,
            merchant: merchant != originalMerchant ? merchant : nil,
            amount: amount != originalAmount ? amount : nil,
            category: category != originalCategory ? category : nil,
            notes: notes != originalNotes ? notes : nil
        )
    }
}

/// Represents only the fields that have changed in a transaction edit operation.
///
/// Each property is optional - a `nil` value indicates that field hasn't changed.
/// This allows for efficient partial updates to the database.
struct TransactionChanges {
    let date: Date?
    let merchant: String?
    let amount: Decimal?
    let category: String?
    let notes: String?
}
