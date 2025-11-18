import SwiftUI

struct TransactionReviewView: View {
    let transactions: [ParsedTransaction]
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    // State Management: @StateObject is used because this View owns the ViewModel lifecycle.
    // The ViewModel is injected via the initializer from the DI container, ensuring proper
    // dependency injection and shared state across the application.
    @StateObject private var viewModel: TransactionReviewViewModel
    @State private var selectedTransactions: Set<Int> = []
    @State private var showingBatchEdit = false
    @State private var editingTransaction: ParsedTransaction?
    
    init(transactions: [ParsedTransaction], onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void, viewModel: TransactionReviewViewModel) {
        self.transactions = transactions
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Transaction list
            List {
                ForEach(Array(transactions.enumerated()), id: \.offset) { index, transaction in
                    TransactionReviewRow(
                        transaction: transaction,
                        isSelected: selectedTransactions.contains(index),
                        onToggleSelection: { toggleSelection(index) },
                        onEdit: { editingTransaction = transaction }
                    )
                }
            }
            .listStyle(PlainListStyle())
            
            // Bottom actions
            bottomActionsView
        }
        .navigationTitle("Review Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(selectedTransactions.isEmpty ? "Select All" : "Deselect All") {
                    if selectedTransactions.isEmpty {
                        selectedTransactions = Set(0..<transactions.count)
                    } else {
                        selectedTransactions.removeAll()
                    }
                }
            }
        }
        .sheet(item: $editingTransaction) { transaction in
            ParsedTransactionEditView(
                transaction: transaction,
                onSave: { updatedTransaction in
                    viewModel.updateTransaction(transaction, with: updatedTransaction)
                    editingTransaction = nil
                }
            )
        }
        .sheet(isPresented: $showingBatchEdit) {
            BatchEditView(
                selectedCount: selectedTransactions.count,
                onApplyChanges: { changes in
                    applyBatchChanges(changes)
                    showingBatchEdit = false
                }
            )
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(transactions.count) Transactions Found")
                        .font(.headline)
                    
                    let lowConfidenceCount = transactions.filter { $0.confidence.overall < 0.8 }.count
                    if lowConfidenceCount > 0 {
                        Text("\(lowConfidenceCount) need review")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    let totalAmount = transactions.compactMap { $0.amount }.reduce(0, +)
                    Text(CurrencyPreferenceManager.shared.formatWithSymbol(totalAmount))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Total Amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !selectedTransactions.isEmpty {
                HStack {
                    Text("\(selectedTransactions.count) selected")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Button("Batch Edit") {
                        showingBatchEdit = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var bottomActionsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                }
                .font(.headline)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                
                Button("Confirm & Save") {
                    onConfirm()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            Text("Review and correct any transactions before saving")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
    }
    
    private func toggleSelection(_ index: Int) {
        if selectedTransactions.contains(index) {
            selectedTransactions.remove(index)
        } else {
            selectedTransactions.insert(index)
        }
    }
    
    private func applyBatchChanges(_ changes: BatchEditChanges) {
        let selectedIndices = Array(selectedTransactions)
        for index in selectedIndices {
            let transaction = transactions[index]
            viewModel.applyBatchChanges(to: transaction, changes: changes)
        }
        selectedTransactions.removeAll()
    }
}

// MARK: - Transaction Review Row

struct TransactionReviewRow: View {
    let transaction: ParsedTransaction
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Button(action: onToggleSelection) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
            }
            
            // Transaction content
            VStack(alignment: .leading, spacing: 8) {
                // Main transaction info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transaction.merchant ?? "Unknown Merchant")
                            .font(.headline)
                            .foregroundColor(transaction.confidence.merchant < 0.8 ? .orange : .primary)
                        
                        if let category = transaction.category {
                            Text(category.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if let amount = transaction.amount {
                            Text(CurrencyPreferenceManager.shared.formatWithSymbol(amount))
                                .font(.headline)
                                .foregroundColor(transaction.confidence.amount < 0.8 ? .orange : .primary)
                        }
                        
                        if let date = transaction.date {
                            Text(dateFormatter.string(from: date))
                                .font(.caption)
                                .foregroundColor(transaction.confidence.date < 0.8 ? .orange : .secondary)
                        }
                    }
                }
                
                // Confidence indicators
                ConfidenceIndicatorView(confidence: transaction.confidence)
                
                // Raw text (for low confidence transactions)
                if transaction.confidence.overall < 0.8 {
                    Text("Raw: \(transaction.rawText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            
            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    transaction.confidence.overall < 0.7 ? Color.orange :
                    transaction.confidence.overall < 0.8 ? Color.yellow :
                    Color.clear,
                    lineWidth: 2
                )
        )
    }
}

// MARK: - Confidence Indicator

struct ConfidenceIndicatorView: View {
    let confidence: TransactionConfidence
    
    var body: some View {
        HStack(spacing: 8) {
            ConfidenceBar(label: "Date", confidence: confidence.date)
            ConfidenceBar(label: "Merchant", confidence: confidence.merchant)
            ConfidenceBar(label: "Amount", confidence: confidence.amount)
            
            Spacer()
            
            Text("Overall: \(Int(confidence.overall * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(confidenceColor(confidence.overall))
        }
    }
    
    private func confidenceColor(_ confidence: Float) -> Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.6 { return .orange }
        return .red
    }
}

struct ConfidenceBar: View {
    let label: String
    let confidence: Float
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 4)
                
                Rectangle()
                    .fill(confidenceColor)
                    .frame(width: 40 * CGFloat(confidence), height: 4)
            }
            .cornerRadius(2)
        }
    }
    
    private var confidenceColor: Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.6 { return .orange }
        return .red
    }
}

// MARK: - Parsed Transaction Edit View

struct ParsedTransactionEditView: View {
    let transaction: ParsedTransaction
    let onSave: (ParsedTransaction) -> Void
    
    @State private var editedDate: Date
    @State private var editedMerchant: String
    @State private var editedAmount: String
    @State private var editedCategory: String
    @Environment(\.dismiss) private var dismiss
    
    init(transaction: ParsedTransaction, onSave: @escaping (ParsedTransaction) -> Void) {
        self.transaction = transaction
        self.onSave = onSave
        
        _editedDate = State(initialValue: transaction.date ?? Date())
        _editedMerchant = State(initialValue: transaction.merchant ?? "")
        _editedAmount = State(initialValue: transaction.amount?.description ?? "")
        _editedCategory = State(initialValue: transaction.category ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Transaction Details") {
                    DatePicker("Date", selection: $editedDate, displayedComponents: .date)
                    
                    TextField("Merchant", text: $editedMerchant)
                    
                    TextField("Amount", text: $editedAmount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Category", text: $editedCategory)
                }
                
                Section("Original Text") {
                    Text(transaction.rawText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Confidence Scores") {
                    HStack {
                        Text("Date")
                        Spacer()
                        Text("\(Int(transaction.confidence.date * 100))%")
                            .foregroundColor(transaction.confidence.date >= 0.8 ? .green : .orange)
                    }
                    
                    HStack {
                        Text("Merchant")
                        Spacer()
                        Text("\(Int(transaction.confidence.merchant * 100))%")
                            .foregroundColor(transaction.confidence.merchant >= 0.8 ? .green : .orange)
                    }
                    
                    HStack {
                        Text("Amount")
                        Spacer()
                        Text("\(Int(transaction.confidence.amount * 100))%")
                            .foregroundColor(transaction.confidence.amount >= 0.8 ? .green : .orange)
                    }
                }
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveChanges() {
        let amount = Decimal(string: editedAmount) ?? transaction.amount
        
        let updatedTransaction = ParsedTransaction(
            date: editedDate,
            merchant: editedMerchant.isEmpty ? nil : editedMerchant,
            amount: amount,
            confidence: TransactionConfidence(
                date: 1.0, // User corrected, so high confidence
                merchant: 1.0,
                amount: 1.0
            ),
            rawText: transaction.rawText,
            lineNumber: transaction.lineNumber,
            category: editedCategory.isEmpty ? nil : editedCategory,
            transactionType: transaction.transactionType
        )
        
        onSave(updatedTransaction)
        dismiss()
    }
}

// MARK: - Batch Edit View

struct BatchEditView: View {
    let selectedCount: Int
    let onApplyChanges: (BatchEditChanges) -> Void
    
    @State private var categoryChange: String = ""
    @State private var shouldChangeCategory = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Editing \(selectedCount) transactions")
                        .font(.headline)
                } header: {
                    Text("Batch Edit")
                }
                
                Section("Category") {
                    Toggle("Change Category", isOn: $shouldChangeCategory)
                    
                    if shouldChangeCategory {
                        TextField("New Category", text: $categoryChange)
                    }
                }
            }
            .navigationTitle("Batch Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func applyChanges() {
        let changes = BatchEditChanges(
            category: shouldChangeCategory ? categoryChange : nil
        )
        onApplyChanges(changes)
        dismiss()
    }
}

// MARK: - Supporting Types

struct BatchEditChanges {
    let category: String?
}

// MARK: - Formatters

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return formatter
}()

#Preview {
    let sampleTransactions = [
        ParsedTransaction(
            date: Date(),
            merchant: "Starbucks",
            amount: Decimal(4.50),
            confidence: TransactionConfidence(date: 0.95, merchant: 0.90, amount: 0.95),
            rawText: "01/15/2024 STARBUCKS $4.50",
            lineNumber: 1,
            category: "Dining",
            transactionType: .debit
        ),
        ParsedTransaction(
            date: Date(),
            merchant: "Gas Station",
            amount: Decimal(45.00),
            confidence: TransactionConfidence(date: 0.60, merchant: 0.70, amount: 0.85),
            rawText: "01/14/2024 GAS STATION $45.00",
            lineNumber: 2,
            category: "Gas",
            transactionType: .debit
        )
    ]
    
    let parserService = SmartTransactionParser()
    let viewModel = TransactionReviewViewModel(parserService: parserService)
    
    return TransactionReviewView(
        transactions: sampleTransactions,
        onConfirm: {},
        onCancel: {},
        viewModel: viewModel
    )
}