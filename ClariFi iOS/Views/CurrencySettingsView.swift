//
//  CurrencySettingsView.swift
//  ClariFi_iOS
//
//  Currency selection settings view
//

import SwiftUI

struct CurrencySettingsView: View {
    
    @StateObject private var currencyManager = CurrencyPreferenceManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var showingConfirmation = false
    
    var filteredCurrencies: [Currency] {
        if searchText.isEmpty {
            return Currency.allCases
        }
        return Currency.allCases.filter { currency in
            currency.name.localizedCaseInsensitiveContains(searchText) ||
            currency.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("Current Currency")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(currencyManager.preferredCurrency.displayText)
                            .font(.headline)
                    }
                    
                    HStack {
                        Text("Example Amount")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(currencyManager.format(1234.56))
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                } header: {
                    Text("Current Selection")
                } footer: {
                    Text("This currency will be used for all transactions and budgets.")
                }
                
                Section {
                    ForEach(filteredCurrencies, id: \.rawValue) { currency in
                        CurrencyRow(
                            currency: currency,
                            isSelected: currency == currencyManager.preferredCurrency
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectCurrency(currency)
                        }
                    }
                } header: {
                    Text("Available Currencies")
                } footer: {
                    Text("Select your preferred currency. All amounts will be displayed in this currency.")
                }
            }
            .searchable(text: $searchText, prompt: "Search currencies")
            .navigationTitle("Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Currency Changed", isPresented: $showingConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your currency has been changed to \(currencyManager.preferredCurrency.name). All amounts will now be displayed in \(currencyManager.preferredCurrency.rawValue).")
            }
        }
    }
    
    private func selectCurrency(_ currency: Currency) {
        let previousCurrency = currencyManager.preferredCurrency
        
        withAnimation {
            currencyManager.preferredCurrency = currency
        }
        
        if previousCurrency != currency {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Show confirmation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingConfirmation = true
            }
        }
    }
}

struct CurrencyRow: View {
    let currency: Currency
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(currency.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text(currency.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(currency.symbol)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Example amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyFormatter.shared.formatWithSymbol(100, currency: currency))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct CurrencySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        CurrencySettingsView()
    }
}
