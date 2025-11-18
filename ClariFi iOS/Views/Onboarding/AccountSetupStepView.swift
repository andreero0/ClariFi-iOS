//
//  AccountSetupStepView.swift
//  ClariFi iOS
//
//  Account setup step for onboarding flow
//

import SwiftUI

struct AccountSetupStepView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var showingAddAccount = false
    @State private var editingAccount: AccountSetupData?
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue.gradient)
                    .accessibilityHidden(true)
                
                Text("Set Up Your Accounts")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Add your accounts to start tracking transactions")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Account List
            if coordinator.createdAccounts.isEmpty {
                EmptyAccountsView()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(coordinator.createdAccounts) { account in
                            AccountCard(
                                account: account,
                                onEdit: {
                                    editingAccount = account
                                    showingAddAccount = true
                                },
                                onDelete: {
                                    coordinator.removeAccount(account)
                                },
                                onSetDefault: {
                                    coordinator.setDefaultAccount(account)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    editingAccount = nil
                    showingAddAccount = true
                }) {
                    Label("Add Account", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .accessibilityLabel("Add new account")
                
                if coordinator.createdAccounts.isEmpty {
                    Button(action: {
                        coordinator.createDefaultAccount()
                        coordinator.advance()
                    }) {
                        Text("Skip - Use Default Cash Account")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("Skip account setup and use default cash account")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showingAddAccount) {
            AddAccountSheet(
                coordinator: coordinator,
                editingAccount: editingAccount,
                isPresented: $showingAddAccount
            )
        }
    }
}

// MARK: - Empty State
struct EmptyAccountsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No accounts yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Add your first account to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Account Card
struct AccountCard: View {
    let account: AccountSetupData
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSetDefault: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: account.type.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            // Account Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(account.displayName)
                        .font(.headline)
                    
                    if account.isDefault {
                        Text("DEFAULT")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                }
                
                Text(account.type.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(account.formattedBalance)
                    .font(.subheadline)
                    .foregroundColor(account.initialBalance >= 0 ? .green : .red)
            }
            
            Spacer()
            
            // Actions Menu
            Menu {
                if !account.isDefault {
                    Button(action: onSetDefault) {
                        Label("Set as Default", systemImage: "star")
                    }
                }
                
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Add Account Sheet
struct AddAccountSheet: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    let editingAccount: AccountSetupData?
    @Binding var isPresented: Bool
    
    @State private var accountName: String = ""
    @State private var selectedType: AccountType = .checking
    @State private var initialBalance: String = ""
    @State private var validationError: String?
    @State private var nameError: String?
    @State private var balanceError: String?
    @State private var hasAttemptedSave: Bool = false
    @State private var isSaving: Bool = false
    
    var isEditing: Bool {
        editingAccount != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account Details")) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Account Name", text: $accountName)
                            .accessibilityLabel("Account name")
                            .onChange(of: accountName) { _ in
                                if hasAttemptedSave {
                                    validateName()
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(nameError != nil ? Color.red : Color.clear, lineWidth: 1)
                            )
                        
                        if let error = nameError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Picker("Account Type", selection: $selectedType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .accessibilityLabel("Account type")
                    .onChange(of: selectedType) { _ in
                        if hasAttemptedSave {
                            validateBalance()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Initial Balance", text: $initialBalance)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Initial balance")
                            .onChange(of: initialBalance) { _ in
                                if hasAttemptedSave {
                                    validateBalance()
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(balanceError != nil ? Color.red : Color.clear, lineWidth: 1)
                            )
                        
                        if let error = balanceError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        } else {
                            Text(selectedType.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let error = validationError {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section {
                    Button(action: saveAccount) {
                        if isSaving {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Saving...")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Text(isEditing ? "Update Account" : "Add Account")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled((!isFormValid && hasAttemptedSave) || isSaving)
                    .accessibilityLabel(isEditing ? "Update account" : "Add account")
                }
            }
            .navigationTitle(isEditing ? "Edit Account" : "Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                if let account = editingAccount {
                    accountName = account.name
                    selectedType = account.type
                    initialBalance = String(describing: account.initialBalance)
                }
            }
        }
    }
    
    // MARK: - Validation
    private var isFormValid: Bool {
        return nameError == nil && balanceError == nil && !accountName.isEmpty
    }
    
    private func validateName() {
        let trimmedName = accountName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            nameError = "Account name cannot be empty"
        } else if trimmedName.count < 2 {
            nameError = "Account name must be at least 2 characters"
        } else if trimmedName.count > 50 {
            nameError = "Account name cannot exceed 50 characters"
        } else if coordinator.createdAccounts.contains(where: { $0.name == trimmedName && $0.id != editingAccount?.id }) {
            nameError = "An account with this name already exists"
        } else {
            nameError = nil
        }
    }
    
    private func validateBalance() {
        guard !initialBalance.isEmpty else {
            balanceError = nil
            return
        }
        
        if let balance = Decimal(string: initialBalance) {
            if balance < 0 && !selectedType.allowsNegativeBalance {
                balanceError = "Initial balance cannot be negative for \(selectedType.rawValue) accounts"
            } else {
                balanceError = nil
            }
        } else {
            balanceError = "Please enter a valid number"
        }
    }
    
    private func saveAccount() {
        // Mark that save has been attempted
        hasAttemptedSave = true
        
        // Clear previous errors
        validationError = nil
        
        // Validate all fields
        validateName()
        validateBalance()
        
        // Check if form is valid
        guard isFormValid else {
            validationError = "Please correct the errors above before saving"
            return
        }
        
        // Show loading state
        isSaving = true
        
        // Simulate async save with smooth transition
        Task {
            // Small delay for smooth UX
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                // Parse balance
                let balance = Decimal(string: initialBalance) ?? 0
                
                // Create account data
                let accountData: AccountSetupData
                if let editing = editingAccount {
                    accountData = AccountSetupData(
                        id: editing.id,
                        name: accountName.trimmingCharacters(in: .whitespacesAndNewlines),
                        type: selectedType,
                        initialBalance: balance,
                        isDefault: editing.isDefault
                    )
                } else {
                    accountData = AccountSetupData(
                        name: accountName.trimmingCharacters(in: .whitespacesAndNewlines),
                        type: selectedType,
                        initialBalance: balance,
                        isDefault: coordinator.createdAccounts.isEmpty
                    )
                }
                
                // Final validation
                if let error = accountData.validate() {
                    validationError = error.errorDescription
                    isSaving = false
                    return
                }
                
                // Check for duplicate names
                if coordinator.createdAccounts.contains(where: { $0.name == accountData.name && $0.id != accountData.id }) {
                    validationError = "An account with this name already exists"
                    isSaving = false
                    return
                }
                
                // Save
                if isEditing {
                    // Remove old and add updated
                    if let editing = editingAccount {
                        coordinator.removeAccount(editing)
                    }
                }
                coordinator.addAccount(accountData)
                
                isSaving = false
                
                // Close sheet with animation
                withAnimation {
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Account Setup Step - Empty") {
    AccountSetupStepView(coordinator: OnboardingCoordinator())
}

#Preview("Account Setup Step - With Accounts") {
    let coordinator = OnboardingCoordinator()
    coordinator.createdAccounts = AccountSetupData.samples
    return AccountSetupStepView(coordinator: coordinator)
}

#Preview("Add Account Sheet") {
    AddAccountSheet(
        coordinator: OnboardingCoordinator(),
        editingAccount: nil,
        isPresented: .constant(true)
    )
}
