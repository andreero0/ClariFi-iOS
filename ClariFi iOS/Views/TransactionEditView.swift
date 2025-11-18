//
//  TransactionEditView.swift
//  ClariFi iOS
//
//  View for editing transaction details
//

import SwiftUI

struct TransactionEditView: View {
    @Binding var transaction: TransactionEditData
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var isLoading = false
    @State private var showingCategoryPicker = false
    @State private var amountText: String = ""
    @State private var showValidationErrors = false
    
    private var validationErrors: [String] {
        transaction.validationErrors
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Transaction Details Section
                Section("Transaction Details") {
                    // Date picker
                    DatePicker(
                        "Date",
                        selection: $transaction.date,
                        displayedComponents: .date
                    )
                    .accessibilityLabel("Transaction date")
                    
                    // Merchant name
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Merchant name", text: $transaction.merchant)
                            .textInputAutocapitalization(.words)
                            .accessibilityLabel("Merchant name")
                            .accessibilityHint("Enter the name of the merchant")
                        
                        if showValidationErrors && transaction.merchant.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text("Merchant name is required")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Amount
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Amount")
                            Spacer()
                            TextField("0.00", text: $amountText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 150)
                                .onChange(of: amountText) { _, newValue in
                                    // Parse decimal from text
                                    if let decimal = Decimal(string: newValue) {
                                        transaction.amount = decimal
                                    }
                                }
                                .accessibilityLabel("Transaction amount")
                                .accessibilityHint("Enter the transaction amount")
                        }
                        
                        if showValidationErrors && transaction.amount == 0 {
                            Text("Amount must be greater than zero")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Category picker
                    VStack(alignment: .leading, spacing: 4) {
                        Button(action: {
                            showingCategoryPicker = true
                        }) {
                            HStack {
                                Text("Category")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(getCategoryDisplayName(transaction.category))
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .accessibilityLabel("Category: \(getCategoryDisplayName(transaction.category))")
                        .accessibilityHint("Tap to change category")
                        
                        if showValidationErrors && transaction.category.isEmpty {
                            Text("Please select a category")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Notes Section
                Section("Notes") {
                    TextField(
                        "Add notes (optional)",
                        text: $transaction.notes,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .accessibilityLabel("Transaction notes")
                    .accessibilityHint("Optional notes about this transaction")
                }
                
                // Preview Section
                Section {
                    HStack {
                        Text("Preview")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(CurrencyPreferenceManager.shared.formatWithSymbol(transaction.amount))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
                .accessibilityLabel("Amount preview: \(CurrencyPreferenceManager.shared.formatWithSymbol(transaction.amount))")
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Save") {
                            if transaction.isValid {
                                onSave()
                            } else {
                                showValidationErrors = true
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $transaction.category)
            }
            .onAppear {
                // Initialize amount text from transaction
                amountText = String(describing: transaction.amount)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCategoryDisplayName(_ canonicalName: String) -> String {
        return CategoryDefinition.allCategories
            .first { $0.canonicalName == canonicalName }?
            .displayName ?? canonicalName
    }
}

// MARK: - Preview

#Preview {
    TransactionEditView(
        transaction: .constant(TransactionEditData()),
        onSave: {},
        onCancel: {}
    )
}
