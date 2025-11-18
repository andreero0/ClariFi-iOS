//
//  RecurringTransactionsListView.swift
//  ClariFi iOS
//
//  Created by Kiro on 2025-10-10.
//

import SwiftUI

struct RecurringTransactionsListView: View {
    // State Management: @StateObject is used because this View owns the ViewModel lifecycle.
    // The ViewModel is injected via the initializer from the DI container, following the
    // established dependency injection pattern for proper testability and separation of concerns.
    @StateObject private var viewModel: RecurringTransactionsViewModel
    @State private var showingEditSheet = false
    @State private var selectedRecurring: RecurringTransaction?
    
    init(viewModel: RecurringTransactionsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if viewModel.recurringTransactions.isEmpty {
                    emptyStateView
                } else {
                    listView
                }
            }
            .navigationTitle("Recurring Transactions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.processRecurringTransactions()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isProcessing)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .sheet(item: $selectedRecurring) { recurring in
                RecurringTransactionDetailView(
                    recurring: recurring,
                    viewModel: viewModel
                )
            }
        }
        .task {
            await viewModel.loadRecurringTransactions()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "repeat.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Recurring Transactions")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Set up recurring transactions when adding a new transaction")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    private var listView: some View {
        List {
            ForEach(viewModel.recurringTransactions, id: \.id) { recurring in
                RecurringTransactionRow(recurring: recurring)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRecurring = recurring
                    }
            }
            .onDelete { indexSet in
                Task {
                    await viewModel.deleteRecurringTransactions(at: indexSet)
                }
            }
        }
    }
}

struct RecurringTransactionRow: View {
    let recurring: RecurringTransaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recurring.merchant ?? "Unknown")
                    .font(.headline)
                
                Spacer()
                
                Text(formatAmount(recurring.amount))
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            HStack {
                Label(recurring.frequency ?? "Unknown", systemImage: "repeat")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let nextDate = recurring.nextOccurrence {
                    Text("Next: \(formatDate(nextDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(recurring.category ?? "Uncategorized")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
    
    private func formatAmount(_ amount: NSDecimalNumber?) -> String {
        guard let amount = amount else { return "$0.00" }
        return CurrencyPreferenceManager.shared.formatWithSymbol(amount as Decimal)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct RecurringTransactionDetailView: View {
    let recurring: RecurringTransaction
    // State Management: @ObservedObject is used because this View does NOT own the ViewModel.
    // The ViewModel is owned by the parent RecurringTransactionsListView and shared with this
    // detail view, allowing both to observe and react to the same state.
    @ObservedObject var viewModel: RecurringTransactionsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    LabeledContent("Merchant", value: recurring.merchant ?? "Unknown")
                    LabeledContent("Amount", value: formatAmount(recurring.amount))
                    LabeledContent("Category", value: recurring.category ?? "Uncategorized")
                    LabeledContent("Account", value: recurring.account?.name ?? "Unknown")
                } header: {
                    Text("Details")
                }
                
                Section {
                    LabeledContent("Frequency", value: recurring.frequency ?? "Unknown")
                    LabeledContent("Start Date", value: formatDate(recurring.startDate))
                    
                    if let endDate = recurring.endDate {
                        LabeledContent("End Date", value: formatDate(endDate))
                    }
                    
                    if let nextDate = recurring.nextOccurrence {
                        LabeledContent("Next Occurrence", value: formatDate(nextDate))
                    }
                } header: {
                    Text("Schedule")
                }
                
                if let notes = recurring.notes, !notes.isEmpty {
                    Section {
                        Text(notes)
                    } header: {
                        Text("Notes")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Recurring Transaction")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Recurring Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Delete Recurring Transaction",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteRecurringTransaction(recurring)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will stop future automatic transactions. Existing transactions will not be affected.")
            }
        }
    }
    
    private func formatAmount(_ amount: NSDecimalNumber?) -> String {
        guard let amount = amount else { return "$0.00" }
        return CurrencyPreferenceManager.shared.formatWithSymbol(amount as Decimal)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - ViewModel
@MainActor
class RecurringTransactionsViewModel: ObservableObject {
    @Published var recurringTransactions: [RecurringTransaction] = []
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private let recurringService: RecurringTransactionService
    
    init(recurringService: RecurringTransactionService) {
        self.recurringService = recurringService
    }
    
    func loadRecurringTransactions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            recurringTransactions = try await recurringService.fetchActiveRecurringTransactions()
        } catch {
            errorMessage = "Failed to load recurring transactions: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func processRecurringTransactions() async {
        isProcessing = true
        errorMessage = nil
        
        do {
            let created = try await recurringService.processRecurringTransactions(upToDate: Date())
            if !created.isEmpty {
                await loadRecurringTransactions()
            }
        } catch {
            errorMessage = "Failed to process recurring transactions: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
    
    func deleteRecurringTransaction(_ recurring: RecurringTransaction) async {
        errorMessage = nil
        
        do {
            try await recurringService.deleteRecurringTransaction(recurring)
            await loadRecurringTransactions()
        } catch {
            errorMessage = "Failed to delete recurring transaction: \(error.localizedDescription)"
        }
    }
    
    func deleteRecurringTransactions(at indexSet: IndexSet) async {
        for index in indexSet {
            let recurring = recurringTransactions[index]
            await deleteRecurringTransaction(recurring)
        }
    }
}

// MARK: - Preview
#if DEBUG
struct RecurringTransactionsListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let recurringRepo = CoreDataRecurringTransactionRepository(context: context)
        let transactionRepo = CoreDataTransactionRepository(context: context)
        let recurringService = CoreDataRecurringTransactionService(
            recurringRepository: recurringRepo,
            transactionRepository: transactionRepo,
            context: context
        )
        
        let viewModel = RecurringTransactionsViewModel(recurringService: recurringService)
        
        return RecurringTransactionsListView(viewModel: viewModel)
    }
}
#endif
