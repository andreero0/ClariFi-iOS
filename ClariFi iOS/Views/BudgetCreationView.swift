//
//  BudgetCreationView.swift
//  ClariFi iOS
//
//  Created by Kiro on 2025-10-10.
//

import SwiftUI

struct BudgetCreationView: View {
    // State Management: @StateObject is used because this View owns the ViewModel lifecycle.
    // The ViewModel is injected via the initializer from the DI container, providing access
    // to budget repositories and template service through dependency injection.
    @StateObject private var viewModel: BudgetCreationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingTemplateSelection = true
    
    init(viewModel: BudgetCreationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            Group {
                if showingTemplateSelection {
                    templateSelectionView
                } else {
                    budgetConfigurationView
                }
            }
            .navigationTitle(showingTemplateSelection ? "Choose Template" : "Create Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if !showingTemplateSelection {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Create") {
                            Task {
                                await viewModel.createBudget()
                            }
                        }
                        .disabled(!viewModel.isValid || viewModel.isLoading)
                    }
                }
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
            .alert("Success", isPresented: $viewModel.showingSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your budget has been created successfully!")
            }
        }
    }
    
    // MARK: - Template Selection View
    private var templateSelectionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Choose a budget template to get started, or create your own from scratch.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                ForEach(viewModel.availableTemplates, id: \.id) { template in
                    TemplateCard(template: template) {
                        viewModel.selectTemplate(template)
                        showingTemplateSelection = false
                    }
                }
                
                Button(action: {
                    viewModel.startCustomBudget()
                    showingTemplateSelection = false
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Custom Budget")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Budget Configuration View
    private var budgetConfigurationView: some View {
        Form {
            Section(header: Text("Budget Details")) {
                TextField("Budget Name", text: $viewModel.budgetName)
                
                Picker("Period", selection: $viewModel.selectedPeriod) {
                    ForEach(BudgetPeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                
                DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                
                Toggle("Enable Rollover", isOn: $viewModel.rolloverEnabled)
            }
            
            Section(header: Text("Total Budget (Optional)")) {
                TextField("Total Amount", text: $viewModel.totalBudgetAmount)
                    .keyboardType(.decimalPad)
                    .onChange(of: viewModel.totalBudgetAmount) { _, newValue in
                        viewModel.updateTotalBudgetAmount(newValue)
                    }
                
                if viewModel.totalAllocated > 0 {
                    HStack {
                        Text("Total Allocated")
                        Spacer()
                        Text(formatCurrency(viewModel.totalAllocated))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: 
                HStack {
                    Text("Categories")
                    Spacer()
                    Button(action: { viewModel.addCategory() }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            ) {
                ForEach(Array(viewModel.categories.enumerated()), id: \.element.id) { index, category in
                    CategoryInputRow(
                        category: category,
                        onUpdate: { name, amount, threshold in
                            viewModel.updateCategory(
                                at: index,
                                name: name,
                                amount: amount,
                                alertThreshold: threshold
                            )
                        },
                        onDelete: {
                            viewModel.removeCategory(at: index)
                        }
                    )
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
    }
    
    // MARK: - Helper Methods
    private func formatCurrency(_ amount: Decimal) -> String {
        return CurrencyPreferenceManager.shared.formatWithSymbol(amount)
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: BudgetTemplate
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(template.name)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                
                Text(template.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                Text(template.targetAudience)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                HStack {
                    Label("\(template.categories.count) categories", systemImage: "list.bullet")
                    Spacer()
                    Label(template.defaultPeriod.displayName, systemImage: "calendar")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

// MARK: - Category Input Row
struct CategoryInputRow: View {
    let category: BudgetCategoryInput
    let onUpdate: (String?, Decimal?, Float?) -> Void
    let onDelete: () -> Void
    
    @State private var nameText: String
    @State private var amountText: String
    @State private var showingThresholdPicker = false
    
    init(category: BudgetCategoryInput, onUpdate: @escaping (String?, Decimal?, Float?) -> Void, onDelete: @escaping () -> Void) {
        self.category = category
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _nameText = State(initialValue: category.name)
        _amountText = State(initialValue: category.amount != nil ? "\(category.amount!)" : "")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Category Name", text: $nameText)
                    .onChange(of: nameText) { newValue in
                        onUpdate(newValue, nil, nil)
                    }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            HStack {
                Text("$")
                TextField("Amount", text: $amountText)
                    .keyboardType(.decimalPad)
                    .onChange(of: amountText) { newValue in
                        if let amount = Decimal(string: newValue) {
                            onUpdate(nil, amount, nil)
                        }
                    }
            }
            
            HStack {
                Text("Alert at \(Int(category.alertThreshold * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Change") {
                    showingThresholdPicker.toggle()
                }
                .font(.caption)
            }
            
            if showingThresholdPicker {
                Slider(value: Binding(
                    get: { Double(category.alertThreshold) },
                    set: { onUpdate(nil, nil, Float($0)) }
                ), in: 0.5...1.0, step: 0.05)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct BudgetCreationView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let budgetRepo = CoreDataBudgetRepository(context: context)
        let categoryRepo = CoreDataBudgetCategoryRepository(context: context)
        let templateService = BudgetTemplateService()
        let viewModel = BudgetCreationViewModel(
            budgetRepository: budgetRepo,
            budgetCategoryRepository: categoryRepo,
            templateService: templateService,
            context: context
        )
        
        return BudgetCreationView(viewModel: viewModel)
    }
}
