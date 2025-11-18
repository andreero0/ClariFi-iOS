//
//  RecurringTransactionSetupView.swift
//  ClariFi iOS
//
//  Created by Kiro on 2025-10-10.
//

import SwiftUI

struct RecurringTransactionSetupView: View {
    @Environment(\.dismiss) private var dismiss
    // State Management: @ObservedObject is used because this View does NOT own the ViewModel.
    // The ViewModel is owned by the parent TransactionEntryView and shared with this child view.
    // This allows both views to observe and react to the same ViewModel state.
    @ObservedObject var viewModel: TransactionEntryViewModel
    
    @State private var frequency: RecurringFrequency = .monthly
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text(viewModel.merchant)
                        .font(.headline)
                    Text("$\(viewModel.amount)")
                        .font(.title2)
                        .foregroundColor(.primary)
                    Text(viewModel.selectedCategory)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Transaction Details")
                }
                
                Section {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                    
                    Toggle("Set End Date", isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: [.date])
                    }
                } header: {
                    Text("Schedule")
                } footer: {
                    Text(scheduleDescription)
                }
                
                Section {
                    Button("Save Recurring Transaction") {
                        saveRecurringTransaction()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Recurring Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var scheduleDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        var description = "This transaction will occur \(frequency.displayName.lowercased()) starting on \(formatter.string(from: startDate))"
        
        if hasEndDate {
            description += " and ending on \(formatter.string(from: endDate))"
        }
        
        description += "."
        return description
    }
    
    private func saveRecurringTransaction() {
        Task {
            await viewModel.saveRecurringTransaction(
                frequency: frequency,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil
            )
            dismiss()
        }
    }
}

// MARK: - Preview
#if DEBUG
struct RecurringTransactionSetupView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let transactionRepo = CoreDataTransactionRepository(context: context)
        let accountRepo = CoreDataAccountRepository(context: context)
        
        let viewModel = TransactionEntryViewModel(
            transactionRepository: transactionRepo,
            accountRepository: accountRepo,
            categoryMappingService: CategoryMappingService(),
            context: context,
            recurringService: CoreDataRecurringTransactionService(
                recurringRepository: CoreDataRecurringTransactionRepository(context: context),
                transactionRepository: transactionRepo,
                context: context
            )
        )
        viewModel.merchant = "Netflix"
        viewModel.amount = "15.99"
        viewModel.selectedCategory = "Entertainment"
        
        return RecurringTransactionSetupView(viewModel: viewModel)
    }
}
#endif
