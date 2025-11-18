//
//  BudgetCreationViewModel.swift
//  ClariFi iOS
//
//  Created by Kiro on 2025-10-10.
//

import Foundation
import CoreData
import Combine

class BudgetCreationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var budgetName: String = ""
    @Published var selectedTemplate: BudgetTemplate?
    @Published var selectedPeriod: BudgetPeriod = .monthly
    @Published var startDate: Date = Date()
    @Published var rolloverEnabled: Bool = false
    @Published var totalBudgetAmount: String = ""
    @Published var categories: [BudgetCategoryInput] = []
    @Published var showingSuccess: Bool = false
    @Published var showSuccessAnimation: Bool = false
    
    // MARK: - Error Handling (from BaseViewModel)
    @Published var error: AppError?
    @Published var isLoading: Bool = false
    
    // Computed properties for testing
    var isFormValid: Bool {
        return !budgetName.isEmpty && !totalBudgetAmount.isEmpty && !categories.isEmpty
    }
    
    // MARK: - Dependencies
    private let budgetRepository: any BudgetRepository
    private let budgetCategoryRepository: any BudgetCategoryRepository
    private let templateService: BudgetTemplateService
    private let context: NSManagedObjectContext
    
    // MARK: - Computed Properties
    var availableTemplates: [BudgetTemplate] {
        templateService.getAllTemplates()
    }
    
    var totalAllocated: Decimal {
        categories.reduce(Decimal(0)) { $0 + ($1.amount ?? 0) }
    }
    
    var isValid: Bool {
        !budgetName.isEmpty &&
        !categories.isEmpty &&
        categories.allSatisfy { !$0.name.isEmpty && $0.amount != nil && $0.amount! > 0 }
    }
    
    // MARK: - Initialization
    init(
        budgetRepository: any BudgetRepository,
        budgetCategoryRepository: any BudgetCategoryRepository,
        templateService: BudgetTemplateService,
        context: NSManagedObjectContext
    ) {
        self.budgetRepository = budgetRepository
        self.budgetCategoryRepository = budgetCategoryRepository
        self.templateService = templateService
        self.context = context
    }
    
    // MARK: - Factory Method
    @MainActor
    static func create(
        budgetRepository: any BudgetRepository,
        budgetCategoryRepository: any BudgetCategoryRepository,
        templateService: BudgetTemplateService,
        context: NSManagedObjectContext
    ) -> BudgetCreationViewModel {
        return BudgetCreationViewModel(
            budgetRepository: budgetRepository,
            budgetCategoryRepository: budgetCategoryRepository,
            templateService: templateService,
            context: context
        )
    }
    
    // MARK: - Template Selection
    @MainActor
    func selectTemplate(_ template: BudgetTemplate) {
        selectedTemplate = template
        budgetName = template.name
        selectedPeriod = template.defaultPeriod
        rolloverEnabled = template.rolloverEnabled
        error = nil // Clear any previous errors
        
        Analytics.track(.budgetTemplateSelected, properties: [
            "template_name": template.name,
            "category_count": template.categories.count
        ])
        
        // If total budget is set, calculate amounts based on percentages
        if let totalAmount = Decimal(string: totalBudgetAmount), totalAmount > 0 {
            applyTemplateWithAmount(template, totalAmount: totalAmount)
        } else {
            // Use suggested amounts from template
            categories = template.categories.map { categoryTemplate in
                BudgetCategoryInput(
                    id: UUID(),
                    name: categoryTemplate.name,
                    amount: categoryTemplate.suggestedAmount,
                    alertThreshold: categoryTemplate.alertThreshold,
                    rolloverEnabled: template.rolloverEnabled,
                    color: categoryTemplate.color
                )
            }
        }
    }
    
    @MainActor
    func applyTemplateWithAmount(_ template: BudgetTemplate, totalAmount: Decimal) {
        categories = template.categories.map { categoryTemplate in
            let percentage = NSDecimalNumber(value: categoryTemplate.suggestedPercentage)
            let total = totalAmount as NSDecimalNumber
            let calculatedAmount = total.multiplying(by: percentage) as Decimal
            
            return BudgetCategoryInput(
                id: UUID(),
                name: categoryTemplate.name,
                amount: calculatedAmount,
                alertThreshold: categoryTemplate.alertThreshold,
                rolloverEnabled: template.rolloverEnabled,
                color: categoryTemplate.color
            )
        }
    }
    
    // MARK: - Custom Budget Creation
    @MainActor
    func startCustomBudget() {
        selectedTemplate = nil
        budgetName = "My Budget"
        categories = []
        addCategory()
    }
    
    // MARK: - Category Management
    @MainActor
    func addCategory() {
        let newCategory = BudgetCategoryInput(
            id: UUID(),
            name: "",
            amount: nil,
            alertThreshold: 0.8,
            rolloverEnabled: rolloverEnabled,
            color: nil
        )
        categories.append(newCategory)
    }
    
    @MainActor
    func removeCategory(at index: Int) {
        guard index < categories.count else { return }
        categories.remove(at: index)
    }
    
    @MainActor
    func updateCategory(at index: Int, name: String? = nil, amount: Decimal? = nil, alertThreshold: Float? = nil, rolloverEnabled: Bool? = nil) {
        guard index < categories.count else { return }
        
        if let name = name {
            categories[index].name = name
        }
        if let amount = amount {
            categories[index].amount = amount
        }
        if let alertThreshold = alertThreshold {
            categories[index].alertThreshold = alertThreshold
        }
        if let rolloverEnabled = rolloverEnabled {
            categories[index].rolloverEnabled = rolloverEnabled
        }
    }
    
    // MARK: - Budget Creation
    func createBudget() async {
        guard isValid else {
            handleError(AppError.validationError(message: "Please fill in all required fields"), context: ["operation": "validate_budget"])
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // Deactivate any existing active budgets
            if let existingBudget = try await budgetRepository.fetchActiveBudget() {
                try await budgetRepository.deactivateBudget(existingBudget)
            }
            
            // Create new budget
            let budget = Budget(context: context)
            budget.id = UUID()
            budget.name = budgetName
            budget.period = selectedPeriod.rawValue
            budget.startDate = startDate
            budget.isActive = true
            budget.rolloverEnabled = rolloverEnabled
            budget.createdAt = Date()
            budget.updatedAt = Date()
            
            // Create budget categories
            for categoryInput in categories {
                let category = BudgetCategory(context: context)
                category.id = UUID()
                category.name = categoryInput.name
                category.budgetedAmount = categoryInput.amount! as NSDecimalNumber
                category.spentAmount = NSDecimalNumber(value: 0)
                category.alertThreshold = categoryInput.alertThreshold
                category.rolloverEnabled = categoryInput.rolloverEnabled
                category.color = categoryInput.color
                category.createdAt = Date()
                category.updatedAt = Date()
                category.budget = budget
            }
            
            // Save budget
            try await budgetRepository.save(budget)
            
            Analytics.track(.budgetCreated, properties: [
                "template_used": selectedTemplate?.name ?? "custom",
                "period": selectedPeriod.rawValue,
                "category_count": categories.count,
                "total_amount": totalAllocated.description,
                "rollover_enabled": rolloverEnabled
            ])
            
            isLoading = false
            showSuccessAnimation = true
            
            // Small delay before showing success state
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            showingSuccess = true
            
            // Hide animation after delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            showSuccessAnimation = false
            
        } catch {
            isLoading = false
            handleError(error, context: ["component": "budget_creation", "operation": "create_budget"])
        }
    }
    
    // MARK: - Template Methods
    func loadTemplate() async {
        // Load template logic here
        // This is a placeholder for the actual implementation
    }
    
    func saveBudget() async {
        await createBudget()
    }
    
    // MARK: - Total Budget Amount Update
    @MainActor
    func updateTotalBudgetAmount(_ amountString: String) {
        totalBudgetAmount = amountString
        
        // If a template is selected and amount is valid, recalculate categories
        if let template = selectedTemplate,
           let amount = Decimal(string: amountString),
           amount > 0 {
            applyTemplateWithAmount(template, totalAmount: amount)
        }
    }
    
    // MARK: - Error Handling
    func handleError(_ error: Error, context: [String: Any] = [:]) {
        Task { @MainActor in
            // Convert to AppError if needed
            if let appError = error as? AppError {
                self.error = appError
            } else {
                // Map other error types to AppError
                self.error = mapToAppError(error)
            }
            
            // Log error for debugging
            print("BudgetCreationViewModel Error: \(error.localizedDescription)")
        }
    }
    
    private func mapToAppError(_ error: Error) -> AppError {
        // Check for common error types and map appropriately
        let nsError = error as NSError
        
        switch nsError.domain {
        case NSURLErrorDomain:
            return .networkError(underlying: error)
        case NSCocoaErrorDomain:
            return .storageError(underlying: error)
        default:
            return .unknownError
        }
    }
}

// MARK: - Budget Category Input Model
struct BudgetCategoryInput: Identifiable {
    let id: UUID
    var name: String
    var amount: Decimal?
    var alertThreshold: Float
    var rolloverEnabled: Bool
    var color: String?
}
