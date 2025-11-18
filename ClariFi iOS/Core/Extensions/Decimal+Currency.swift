//
//  Decimal+Currency.swift
//  ClariFi_iOS
//
//  Currency formatting extensions for Decimal
//

import Foundation

extension Decimal {
    
    /// Format this decimal with the user's preferred currency (synchronous)
    var formattedAsCurrency: String {
        CurrencyPreferenceManager.shared.format(self)
    }
    
    /// Format this decimal with the user's preferred currency symbol (synchronous)
    var formattedWithCurrencySymbol: String {
        CurrencyPreferenceManager.shared.formatWithSymbol(self)
    }
    
    /// Format this decimal with a specific currency (synchronous)
    func formatted(as currency: Currency) -> String {
        CurrencyFormatter.shared.format(self, currency: currency)
    }
    
    /// Format this decimal with a specific currency symbol (synchronous)
    func formattedWithSymbol(as currency: Currency) -> String {
        CurrencyFormatter.shared.formatWithSymbol(self, currency: currency)
    }
    
    /// Format this decimal with the user's preferred currency (async version)
    func formattedAsCurrencyAsync() async -> String {
        await CurrencyPreferenceManager.shared.formatAsync(self)
    }
    
    /// Format this decimal with the user's preferred currency symbol (async version)
    func formattedWithCurrencySymbolAsync() async -> String {
        await CurrencyPreferenceManager.shared.formatWithSymbolAsync(self)
    }
    
    /// Format this decimal with a specific currency (async version)
    func formattedAsync(as currency: Currency) async -> String {
        await CurrencyFormatter.shared.formatAsync(self, currency: currency)
    }
    
    /// Format this decimal with a specific currency symbol (async version)
    func formattedWithSymbolAsync(as currency: Currency) async -> String {
        await CurrencyFormatter.shared.formatWithSymbolAsync(self, currency: currency)
    }
}

extension NSDecimalNumber {
    
    /// Format this NSDecimalNumber with the user's preferred currency
    var formattedAsCurrency: String {
        (self as Decimal).formattedAsCurrency
    }
    
    /// Format this NSDecimalNumber with the user's preferred currency symbol
    var formattedWithCurrencySymbol: String {
        (self as Decimal).formattedWithCurrencySymbol
    }
}
