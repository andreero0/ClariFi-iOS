//
//  CategorizationRulesView.swift
//  ClariFi_iOS
//
//  UI for managing categorization rules
//

import SwiftUI
import CoreData

struct CategorizationRulesView: View {
    // State Management: @StateObject is used because this View owns the ViewModel lifecycle.
    // The ViewModel is injected via the initializer. While this currently creates the ViewModel
    // in init, it could be refactored to accept a pre-built ViewModel from the DI container
    // for better consistency with the architecture pattern.
    @StateObject private var viewModel: CategorizationRulesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddRule = false
    @State private var editingRule: CategorizationRule?
    
    init(viewModel: CategorizationRulesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // Legacy init for backward compatibility - should be deprecated
    init(context: NSManagedObjectContext, categoryService: CategoryService, ruleEngine: RuleEngine) {
        _viewModel = StateObject(wrappedValue: CategorizationRulesViewModel(
            context: context,
            categoryService: categoryService,
            ruleEngine: ruleEngine
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.rules.isEmpty {
                    emptyStateView
                } else {
                    rulesList
                }
                
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .navigationTitle("Categorization Rules")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddRule = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRule) {
                RuleEditorView(
                    viewModel: viewModel,
                    rule: nil,
                    onSave: { name, pattern, category, matchType, priority, minAmount, maxAmount in
                        await viewModel.createRule(
                            name: name,
                            merchantPattern: pattern,
                            category: category,
                            matchType: matchType,
                            priority: priority,
                            minAmount: minAmount,
                            maxAmount: maxAmount
                        )
                        showingAddRule = false
                    }
                )
            }
            .sheet(item: $editingRule) { rule in
                RuleEditorView(
                    viewModel: viewModel,
                    rule: rule,
                    onSave: { name, pattern, category, matchType, priority, minAmount, maxAmount in
                        await viewModel.updateRule(
                            rule,
                            name: name,
                            merchantPattern: pattern,
                            category: category,
                            matchType: matchType,
                            priority: priority,
                            minAmount: minAmount,
                            maxAmount: maxAmount
                        )
                        editingRule = nil
                    }
                )
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
            .task {
                await viewModel.loadRules()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Rules Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create rules to automatically categorize transactions based on merchant names")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { showingAddRule = true }) {
                Label("Create First Rule", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
    }
    
    private var rulesList: some View {
        List {
            ForEach(viewModel.rules, id: \.id) { rule in
                RuleRowView(rule: rule)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingRule = rule
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteRule(rule)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            Task {
                                await viewModel.toggleRuleActive(rule)
                            }
                        } label: {
                            Label(
                                rule.isActive ? "Disable" : "Enable",
                                systemImage: rule.isActive ? "pause.circle" : "play.circle"
                            )
                        }
                        .tint(rule.isActive ? .orange : .green)
                    }
            }
            .onMove { from, to in
                Task {
                    await viewModel.reorderRules(from: from, to: to)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Rule Row View

struct RuleRowView: View {
    let rule: CategorizationRule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rule.name ?? "Unnamed Rule")
                    .font(.headline)
                
                Spacer()
                
                if !rule.isActive {
                    Text("Disabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            HStack {
                Label(rule.merchantPattern ?? "", systemImage: "tag")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(rule.category ?? "")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text(matchTypeDisplay)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if rule.applicationCount > 0 {
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(rule.applicationCount) applied")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("Priority: \(rule.priority)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var matchTypeDisplay: String {
        guard let matchType = rule.matchType else { return "Unknown" }
        return RuleMatchType(rawValue: matchType)?.displayName ?? matchType
    }
}

// MARK: - Rule Editor View

struct RuleEditorView: View {
    // State Management: @ObservedObject is used because this View does NOT own the ViewModel.
    // The ViewModel is owned by the parent CategorizationRulesView and shared with this editor,
    // allowing the editor to access categories and other shared state without owning the lifecycle.
    @ObservedObject var viewModel: CategorizationRulesViewModel
    let rule: CategorizationRule?
    let onSave: (String, String, String, RuleMatchType, Int16, Decimal?, Decimal?) async -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var merchantPattern: String
    @State private var selectedCategory: String
    @State private var matchType: RuleMatchType
    @State private var priority: Int16
    @State private var minAmount: String
    @State private var maxAmount: String
    @State private var hasMinAmount: Bool
    @State private var hasMaxAmount: Bool
    
    init(
        viewModel: CategorizationRulesViewModel,
        rule: CategorizationRule?,
        onSave: @escaping (String, String, String, RuleMatchType, Int16, Decimal?, Decimal?) async -> Void
    ) {
        self.viewModel = viewModel
        self.rule = rule
        self.onSave = onSave
        
        _name = State(initialValue: rule?.name ?? "")
        _merchantPattern = State(initialValue: rule?.merchantPattern ?? "")
        _selectedCategory = State(initialValue: rule?.category ?? CategoryDefinition.other.canonicalName)
        _matchType = State(initialValue: RuleMatchType(rawValue: rule?.matchType ?? "contains") ?? .contains)
        _priority = State(initialValue: rule?.priority ?? 0)
        
        let hasMin = rule?.minAmount != nil
        let hasMax = rule?.maxAmount != nil
        _hasMinAmount = State(initialValue: hasMin)
        _hasMaxAmount = State(initialValue: hasMax)
        _minAmount = State(initialValue: hasMin ? String(describing: rule?.minAmount ?? 0) : "")
        _maxAmount = State(initialValue: hasMax ? String(describing: rule?.maxAmount ?? 0) : "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Rule Details") {
                    TextField("Rule Name", text: $name)
                    
                    TextField("Merchant Pattern", text: $merchantPattern)
                        .autocapitalization(.none)
                    
                    Picker("Match Type", selection: $matchType) {
                        ForEach(RuleMatchType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    Text(matchType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(CategoryDefinition.allCategories, id: \.canonicalName) { def in
                            Label(def.displayName, systemImage: def.icon)
                                .tag(def.canonicalName)
                        }
                    }
                }
                
                Section("Amount Constraints") {
                    Toggle("Minimum Amount", isOn: $hasMinAmount)
                    
                    if hasMinAmount {
                        TextField("Min Amount", text: $minAmount)
                            .keyboardType(.decimalPad)
                    }
                    
                    Toggle("Maximum Amount", isOn: $hasMaxAmount)
                    
                    if hasMaxAmount {
                        TextField("Max Amount", text: $maxAmount)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Priority") {
                    Stepper("Priority: \(priority)", value: $priority, in: 0...100)
                    
                    Text("Higher priority rules are applied first")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(rule == nil ? "New Rule" : "Edit Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let min = hasMinAmount ? Decimal(string: minAmount) : nil
                            let max = hasMaxAmount ? Decimal(string: maxAmount) : nil
                            
                            await onSave(
                                name,
                                merchantPattern,
                                selectedCategory,
                                matchType,
                                priority,
                                min,
                                max
                            )
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && !merchantPattern.isEmpty && !selectedCategory.isEmpty
    }
}

