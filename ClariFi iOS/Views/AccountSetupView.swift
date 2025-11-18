//
//  AccountSetupView.swift
//  ClariFi iOS
//
//  Quick account setup for new users
//

import SwiftUI
import CoreData

struct AccountSetupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var accountName = ""
    @State private var accountType = "checking"
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let accountTypes = ["checking", "savings", "credit", "debit", "cash", "investment"]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Account Name", text: $accountName)
                        .accessibilityLabel("Account name")
                        .accessibilityHint("Enter a name for your account")
                } header: {
                    Text("Account Details")
                }
                
                Section {
                    Picker("Account Type", selection: $accountType) {
                        ForEach(accountTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    .accessibilityLabel("Account type")
                    .accessibilityHint("Select the type of account")
                } header: {
                    Text("Account Type")
                }
                
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAccount()
                    }
                    .disabled(accountName.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveAccount() {
        guard !accountName.isEmpty else { return }
        
        let account = Account(context: viewContext)
        account.id = UUID()
        account.name = accountName
        account.type = accountType
        account.createdAt = Date()
        account.updatedAt = Date()
        account.isActive = true
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save account: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    AccountSetupView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
