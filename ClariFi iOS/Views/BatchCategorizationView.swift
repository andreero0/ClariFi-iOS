//
//  BatchCategorizationView.swift
//  ClariFi_iOS
//
//  UI for batch categorization of transactions
//

import SwiftUI
import CoreData

struct BatchCategorizationView: View {
    // State Management: @StateObject is used because this View owns the ViewModel lifecycle.
    // The ViewModel is injected via the initializer from the DI container, following the
    // dependency injection pattern. This ensures testability and proper separation of concerns.
    @StateObject private var viewModel: BatchCategorizationViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: BatchCategorizationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isProcessing {
                    processingView
                } else if viewModel.result != nil {
                    resultView
                } else {
                    selectionView
                }
            }
            .navigationTitle("Batch Categorization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadUncategorizedTransactions()
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    private var selectionView: some View {
        VStack(spacing: 20) {
            if viewModel.uncategorizedTransactions.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        statsCard
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Options")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Toggle("Apply to uncategorized only", isOn: $viewModel.uncategorizedOnly)
                                .padding(.horizontal)
                            
                            Toggle("Show conflicts", isOn: $viewModel.showConflicts)
                                .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        Button(action: {
                            Task {
                                await viewModel.applyRules()
                            }
                        }) {
                            Label("Apply Rules", systemImage: "wand.and.stars")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
        }
    }
    
    private var statsCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Uncategorized")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.uncategorizedTransactions.count)")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Active Rules")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.activeRulesCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            
            Divider()
            
            Text("Apply your categorization rules to automatically categorize transactions")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("All Caught Up!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("All transactions are categorized")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Applying Rules...")
                .font(.headline)
            
            Text("Processing \(viewModel.uncategorizedTransactions.count) transactions")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var resultView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let result = viewModel.result {
                    resultSummaryCard(result: result)
                    
                    if !result.conflicts.isEmpty {
                        conflictsSection(conflicts: result.conflicts)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    private func resultSummaryCard(result: RuleApplicationResult) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("Rules Applied")
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(spacing: 40) {
                VStack {
                    Text("\(result.appliedCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Applied")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(result.skippedCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Skipped")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !result.conflicts.isEmpty {
                    VStack {
                        Text("\(result.conflicts.count)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text("Conflicts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private func conflictsSection(conflicts: [RuleConflict]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Conflicts Detected")
                .font(.headline)
                .padding(.horizontal)
            
            Text("Multiple rules matched these transactions. The highest priority rule was applied.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ForEach(Array(conflicts.enumerated()), id: \.offset) { index, conflict in
                ConflictRowView(conflict: conflict)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Conflict Row View

struct ConflictRowView: View {
    let conflict: RuleConflict
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(conflict.transaction.merchant ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(conflict.transaction.amount ?? NSDecimalNumber(value: 0), formatter: currencyFormatter)
                    .font(.subheadline)
            }
            
            Text("Matched \(conflict.conflictingRules.count) rules")
                .font(.caption)
                .foregroundColor(.orange)
            
            if let resolution = conflict.suggestedResolution {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("Applied: \(resolution.category ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
}
