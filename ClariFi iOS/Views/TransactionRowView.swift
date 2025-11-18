//
//  TransactionRowView.swift
//  ClariFi iOS
//
//  Reusable transaction row component
//

import SwiftUI
import CoreData

struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant ?? "Unknown Merchant")
                    .font(.headline)
                Text((transaction.category ?? "Uncategorized").capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(transaction.amount?.decimalValue ?? 0))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let date = transaction.date {
                    Text(formatDate(date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(AccessibilityHints.transactionRow)
    }
    
    private var accessibilityLabel: String {
        let merchant = transaction.merchant ?? "Unknown Merchant"
        let category = transaction.category ?? "Uncategorized"
        let amount = (transaction.amount?.decimalValue ?? 0).accessibleCurrencyValue
        let date = transaction.date?.accessibleDateValue ?? "Unknown date"
        
        return "\(merchant), \(category), \(amount), \(date)"
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        return CurrencyPreferenceManager.shared.formatWithSymbol(amount)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
