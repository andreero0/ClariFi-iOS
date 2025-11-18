//
//  TransactionEntryView.swift
//  ClariFi iOS
//
//  Created by Kiro on 2025-10-10.
//

import SwiftUI

struct TransactionEntryView: View {
    @ObservedObject var viewModel: TransactionEntryViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var showingRecurringSetup = false
    @State private var showingAccountSetup = false
    
    enum Field {
        case merchant, amount, category, description
    }
    
    var body: some View {
        NavigationView {
            Form {
                dateSection
                accountSection
                merchantSection
                amountSection
                categorySection
                descriptionSection
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarItems
            }
            .overlay {
                successOverlay
            }
            .errorAlert(error: $viewModel.error)
            .sheet(isPresented: $showingRecurringSetup) {
                RecurringTransactionSetupView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAccountSetup) {
                AccountSetupView()
            }
        }
    }
    
    // MARK: - Form Sections
    
    private var dateSection: some View {
        Section {
            DatePicker("Date", selection: $viewModel.date, displayedComponents: [.date])
        } header: {
            Text("Transaction Date")
        }
    }
    
    private var accountSection: some View {
        Section {
            if viewModel.accounts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No accounts available")
                        .foregroundColor(.secondary)
                    
                    Button("Set up your first account") {
                        showingAccountSetup = true
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Set up your first account")
                    .accessibilityHint("Create an account to track your transactions")
                }
            } else {
                Picker("Account", selection: $viewModel.selectedAccount) {
                    ForEach(viewModel.accounts, id: \.id) { account in
                        Text(account.name ?? "Unknown Account")
                            .tag(account as Account?)
                    }
                }
                .accessibilityLabel("Select account")
                .accessibilityHint("Choose which account this transaction belongs to")
            }
            
            if let error = viewModel.accountError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        } header: {
            Text("Account")
        }
    }
    
    private var merchantSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Merchant name", text: $viewModel.merchant)
                    .focused($focusedField, equals: .merchant)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Merchant name")
                    .accessibilityHint("Enter the name of the merchant or business")
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(viewModel.merchantError != nil ? Color.red : Color.clear, lineWidth: 1)
                    )
                
                if let error = viewModel.merchantError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                if viewModel.showMerchantSuggestions && !viewModel.merchantSuggestions.isEmpty {
                    merchantSuggestionsView
                }
            }
        } header: {
            Text("Merchant")
        }
    }
    
    private var merchantSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 40)
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.merchantSuggestions, id: \.self) { suggestion in
                    Button(action: {
                        viewModel.selectMerchantSuggestion(suggestion)
                        focusedField = nil
                    }) {
                        Text(suggestion)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(radius: 2)
        }
    }
    
    private var amountSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("$")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    
                    TextField("0.00", text: $viewModel.amount)
                        .focused($focusedField, equals: .amount)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                        .accessibilityLabel("Transaction amount")
                        .accessibilityHint("Enter the transaction amount in dollars")
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(viewModel.amountError != nil ? Color.red : Color.clear, lineWidth: 1)
                )
                
                if let error = viewModel.amountError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        } header: {
            Text("Amount")
        }
    }
    
    private var categorySection: some View {
        Section {
            Picker("Category", selection: $viewModel.selectedCategory) {
                ForEach(viewModel.availableCategories, id: \.canonicalName) { category in
                    Text(category.displayName).tag(category.canonicalName)
                }
            }
            .accessibilityLabel("Transaction category")
            .accessibilityHint("Select the category for this transaction")
            
            if let error = viewModel.categoryError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        } header: {
            Text("Category")
        }
    }
    
    private var descriptionSection: some View {
        Section {
            TextField("Optional description", text: $viewModel.notes, axis: .vertical)
                .focused($focusedField, equals: .description)
                .lineLimit(3...6)
                .accessibilityLabel("Transaction description")
                .accessibilityHint("Enter an optional description for this transaction")
        } header: {
            Text("Description")
        }
    }
    
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(viewModel.isRecurring ? "Next" : "Save") {
                if viewModel.isRecurring {
                    if viewModel.validateForm() {
                        showingRecurringSetup = true
                    }
                } else {
                    Task {
                        await viewModel.saveTransaction()
                        if viewModel.error == nil {
                            dismiss()
                        }
                    }
                }
            }
            .disabled(viewModel.isSaving)
        }
        
        ToolbarItem(placement: .keyboard) {
            HStack {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }
    
    // MARK: - Overlays
    
    private var successOverlay: some View {
        Group {
            if viewModel.showSuccessMessage {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Transaction saved successfully")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 10)
                    .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: viewModel.showSuccessMessage)
            }
        }
    }
}

// MARK: - Error Alert Extension

extension View {
    func errorAlert(error: Binding<Error?>) -> some View {
        alert("Error", isPresented: .constant(error.wrappedValue != nil)) {
            Button("OK") {
                error.wrappedValue = nil
            }
        } message: {
            Text(error.wrappedValue?.localizedDescription ?? "An unknown error occurred")
        }
    }
}

// MARK: - Preview

#if DEBUG
struct TransactionEntryView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let transactionRepo = CoreDataTransactionRepository(context: context)
        let accountRepo = CoreDataAccountRepository(context: context)
        
        let recurringRepo = CoreDataRecurringTransactionRepository(context: context)
        let recurringService = CoreDataRecurringTransactionService(
            recurringRepository: recurringRepo,
            transactionRepository: transactionRepo,
            context: context
        )
        let viewModel = TransactionEntryViewModel(
            transactionRepository: transactionRepo,
            accountRepository: accountRepo,
            categoryMappingService: CategoryMappingService(),
            context: context,
            recurringService: recurringService
        )
        
        return TransactionEntryView(viewModel: viewModel)
    }
}
#endif