//
//  TransactionDetailView.swift
//  ClariFi iOS
//
//  Detailed view for a single transaction
//

import SwiftUI
import CoreData

struct TransactionDetailView: View {
    let transaction: Transaction
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.diContainer) private var container
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    @State private var editData = TransactionEditData()
    @State private var isUpdating = false
    @State private var showSuccessToast = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            Section("Transaction Details") {
                DetailRow(label: "Merchant", value: transaction.merchant ?? "Unknown")
                DetailRow(label: "Amount", value: formatCurrency(transaction.amount?.decimalValue ?? 0))
                DetailRow(label: "Category", value: (transaction.category ?? "Uncategorized").capitalized)
                DetailRow(label: "Date", value: transaction.date?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                DetailRow(label: "Account", value: transaction.account?.name ?? "Unknown")
            }
            
            Section("Metadata") {
                DetailRow(label: "Confidence", value: String(format: "%.1f%%", transaction.confidence * 100))
                DetailRow(label: "Manual Entry", value: transaction.isManual ? "Yes" : "No")
                if let notes = transaction.notes, !notes.isEmpty {
                    DetailRow(label: "Notes", value: notes)
                }
            }
            
            Section {
                Button {
                    editData = TransactionEditData(from: transaction)
                    showingEditSheet = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Edit Transaction")
                        Spacer()
                    }
                }
                .disabled(isUpdating)
                
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Transaction")
                        Spacer()
                    }
                }
                .disabled(isUpdating)
            }
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            TransactionEditView(
                transaction: $editData,
                onSave: {
                    Task {
                        await updateTransaction()
                    }
                },
                onCancel: {
                    showingEditSheet = false
                }
            )
        }
        .alert("Delete Transaction", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTransaction()
            }
        } message: {
            Text("Are you sure you want to delete this transaction? This action cannot be undone.")
        }
        .successToast(isShowing: $showSuccessToast, message: "Transaction updated successfully")
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
            Button("Retry") {
                Task {
                    await updateTransaction()
                }
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    @MainActor
    private func updateTransaction() async {
        isUpdating = true
        defer { isUpdating = false }
        
        do {
            // Get the repository from DI container
            guard let repository = container.resolveOptional(TransactionRepository.self) else {
                print("Failed to resolve TransactionRepository")
                errorMessage = "Unable to access data storage. Please restart the app."
                showErrorAlert = true
                return
            }
            
            // Get only the changed values
            let changes = editData.changes(from: transaction)
            
            // Update the transaction
            _ = try await repository.updateTransaction(
                transaction,
                date: changes.date,
                merchant: changes.merchant,
                amount: changes.amount,
                category: changes.category,
                notes: changes.notes
            )
            
            showingEditSheet = false
            
            // Show success toast
            withAnimation {
                showSuccessToast = true
            }
            
        } catch {
            print("Failed to update transaction: \(error)")
            errorMessage = "Failed to save changes. Please try again."
            showErrorAlert = true
        }
    }
    
    private func deleteTransaction() {
        viewContext.delete(transaction)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Delete error: \(error)")
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        return CurrencyPreferenceManager.shared.formatWithSymbol(amount)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}
