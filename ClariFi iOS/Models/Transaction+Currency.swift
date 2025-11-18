//
//  Transaction+Currency.swift
//  ClariFi_iOS
//
//  Currency support extensions for Transaction
//

import Foundation
import CoreData

extension Transaction {
    
    /// Get the currency for this transaction, defaulting to user's preferred currency
    var effectiveCurrency: Currency {
        if let currencyString = currency,
           let currency = Currency(rawValue: currencyString) {
            return currency
        }
        return CurrencyPreferenceManager.shared.preferredCurrency
    }
    
    /// Format the transaction amount with its currency
    var formattedAmount: String {
        guard let amount = amount else { return "0.00" }
        let decimal = amount.decimalValue
        return CurrencyFormatter.shared.format(decimal, currency: effectiveCurrency)
    }
    
    /// Format the transaction amount with symbol
    var formattedAmountWithSymbol: String {
        guard let amount = amount else { return "0.00" }
        let decimal = amount.decimalValue
        return CurrencyFormatter.shared.formatWithSymbol(decimal, currency: effectiveCurrency)
    }
    
    /// Set currency to user's preferred currency
    func setPreferredCurrency() {
        self.currency = CurrencyPreferenceManager.shared.preferredCurrency.rawValue
    }
    
    /// Create a new transaction with preferred currency
    static func create(
        in context: NSManagedObjectContext,
        date: Date,
        merchant: String,
        amount: Decimal,
        category: String,
        account: Account?,
        notes: String? = nil
    ) -> Transaction {
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = date
        transaction.merchant = merchant
        transaction.amount = NSDecimalNumber(decimal: amount)
        transaction.currency = CurrencyPreferenceManager.shared.preferredCurrency.rawValue
        transaction.category = category
        transaction.account = account
        transaction.notes = notes
        transaction.isManual = true
        transaction.confidence = 1.0
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        
        return transaction
    }
}

extension RecurringTransaction {
    
    /// Get the currency for this recurring transaction
    var effectiveCurrency: Currency {
        if let currencyString = currency,
           let currency = Currency(rawValue: currencyString) {
            return currency
        }
        return CurrencyPreferenceManager.shared.preferredCurrency
    }
    
    /// Format the recurring transaction amount with its currency
    var formattedAmount: String {
        guard let amount = amount else { return "0.00" }
        let decimal = amount.decimalValue
        return CurrencyFormatter.shared.format(decimal, currency: effectiveCurrency)
    }
    
    /// Set currency to user's preferred currency
    func setPreferredCurrency() {
        self.currency = CurrencyPreferenceManager.shared.preferredCurrency.rawValue
    }
}
