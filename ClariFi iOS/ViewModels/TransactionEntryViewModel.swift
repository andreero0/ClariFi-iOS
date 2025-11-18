//
//  TransactionEntryViewModel.swift
//  ClariFi iOS
//
//  Created by Kiro on 2025-10-10.
//

import Foundation
import SwiftUI
import Combine
import CoreData

@MainActor
class TransactionEntryViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var date: Date = Date()
    @Published var merchant: String = ""
    @Published var amount: String = ""
    @Published var selectedCategory: String = "other"
    @Published var selectedAccount: Account?
    @Published var notes: String = ""
    @Published var isRecurring: Bool = false
    
    // Available categories - now loaded from CategoryMappingService
    @Published var availableCategories: [CategoryDefinition] = []
    
    // Autocomplete
    @Published var merchantSuggestions: [String] = []
    @Published var categorySuggestions: [String] = []
    @Published var showMerchantSuggestions: Bool = false
    
    // Validation
    @Published var merchantError: String?
    
    // Computed properties for testing
    var isFormValid: Bool {
        return !merchant.isEmpty && !amount.isEmpty && !selectedCategory.isEmpty
    }
    
    var parsedAmount: Decimal? {
        return Decimal(string: amount)
    }
    @Published var amountError: String?
    @Published var categoryError: String?
    @Published var accountError: String?
    
    // State
    @Published var isSaving: Bool = false
    @Published var showSuccessMessage: Bool = false
    @Published var showSuccessAnimation: Bool = false
    @Published var accounts: [Account] = []
    
    // MARK: - Dependencies
    private let transactionRepository: any TransactionRepository
    private let accountRepository: any AccountRepository
    private let recurringService: RecurringTransactionService?
    private let categoryMappingService: CategoryMappingServiceProtocol
    private let context: NSManagedObjectContext
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    var merchantHistory: [String: String] = [:] // merchant -> category mapping
    
    // MARK: - Initialization
    init(
        transactionRepository: any TransactionRepository,
        accountRepository: any AccountRepository,
        categoryMappingService: CategoryMappingServiceProtocol,
        context: NSManagedObjectContext,
        recurringService: RecurringTransactionService?
    ) {
        self.transactionRepository = transactionRepository
        self.accountRepository = accountRepository
        self.categoryMappingService = categoryMappingService
        self.recurringService = recurringService
        self.context = context
        
        super.init()
        loadCategories()
        setupObservers()
        Task {
            await loadAccounts()
            await loadMerchantHistory()
        }
    }
    
    // MARK: - Category Loading
    private func loadCategories() {
        availableCategories = categoryMappingService.getAllCategories()
    }
    
    // MARK: - Setup
    private func setupObservers() {
        // Merchant autocomplete
        $merchant
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.updateMerchantSuggestions(query: query)
            }
            .store(in: &cancellables)
        
        // Auto-suggest category based on merchant
        $merchant
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] merchant in
                self?.suggestCategoryForMerchant(merchant)
            }
            .store(in: &cancellables)
        
        // Real-time validation for merchant
        $merchant
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self else { return }
                if !value.isEmpty && self.merchantError != nil {
                    self.validateMerchantField()
                }
            }
            .store(in: &cancellables)
        
        // Real-time validation for amount
        $amount
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self else { return }
                if !value.isEmpty && self.amountError != nil {
                    self.validateAmountField()
                }
            }
            .store(in: &cancellables)
        
        // Real-time validation for category
        $selectedCategory
            .sink { [weak self] value in
                guard let self = self else { return }
                if !value.isEmpty && self.categoryError != nil {
                    self.categoryError = nil
                }
            }
            .store(in: &cancellables)
        
        // Real-time validation for account
        $selectedAccount
            .sink { [weak self] value in
                guard let self = self else { return }
                if value != nil && self.accountError != nil {
                    self.accountError = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Field Validation
    private func validateMerchantField() {
        if merchant.trimmingCharacters(in: .whitespaces).isEmpty {
            merchantError = "Merchant name is required"
        } else {
            merchantError = nil
        }
    }
    
    private func validateAmountField() {
        let trimmed = amount.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            amountError = "Amount is required"
        } else if let decimalAmount = Decimal(string: trimmed), decimalAmount <= 0 {
            amountError = "Amount must be greater than zero"
        } else if Decimal(string: trimmed) == nil {
            amountError = "Invalid amount format"
        } else {
            amountError = nil
        }
    }
    
    // MARK: - Data Loading
    func loadAccounts() async {
        do {
            accounts = try await accountRepository.fetchActiveAccounts()
            if selectedAccount == nil && !accounts.isEmpty {
                selectedAccount = accounts.first
            }
        } catch {
            handleError(error, context: ["operation": "load_accounts"])
        }
    }
    
    private func loadMerchantHistory() async {
        do {
            let transactions = try await transactionRepository.fetchAll()
            
            // Build merchant -> category mapping from historical data
            for transaction in transactions {
                let merchantName = transaction.merchant?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
                let category = transaction.category ?? ""
                
                if !merchantName.isEmpty && !category.isEmpty {
                    merchantHistory[merchantName] = category
                }
            }
        } catch {
            print("Failed to load merchant history: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Autocomplete
    private func updateMerchantSuggestions(query: String) {
        guard !query.isEmpty else {
            merchantSuggestions = []
            showMerchantSuggestions = false
            return
        }
        
        let lowercaseQuery = query.lowercased()
        let uniqueMerchants = Set(merchantHistory.keys)
        
        merchantSuggestions = uniqueMerchants
            .filter { $0.contains(lowercaseQuery) }
            .sorted()
            .prefix(5)
            .map { $0.capitalized }
        
        showMerchantSuggestions = !merchantSuggestions.isEmpty
    }
    
    private func suggestCategoryForMerchant(_ merchant: String) {
        guard !merchant.isEmpty else { return }
        
        let lowercaseMerchant = merchant.trimmingCharacters(in: .whitespaces).lowercased()
        
        // If we have a category for this merchant and user hasn't selected one yet
        if selectedCategory.isEmpty, let suggestedCategory = merchantHistory[lowercaseMerchant] {
            selectedCategory = suggestedCategory
        }
    }
    
    func selectMerchantSuggestion(_ suggestion: String) {
        merchant = suggestion
        showMerchantSuggestions = false
    }
    
    // MARK: - Validation
    func validateForm() -> Bool {
        var isValid = true
        
        // Reset errors
        merchantError = nil
        amountError = nil
        categoryError = nil
        accountError = nil
        
        // Validate merchant
        if merchant.trimmingCharacters(in: .whitespaces).isEmpty {
            merchantError = "Merchant name is required"
            isValid = false
        }
        
        // Validate amount
        if amount.trimmingCharacters(in: .whitespaces).isEmpty {
            amountError = "Amount is required"
            isValid = false
        } else if let decimalAmount = Decimal(string: amount), decimalAmount <= 0 {
            amountError = "Amount must be greater than zero"
            isValid = false
        } else if Decimal(string: amount) == nil {
            amountError = "Invalid amount format"
            isValid = false
        }
        
        // Validate category
        if selectedCategory.trimmingCharacters(in: .whitespaces).isEmpty {
            categoryError = "Category is required"
            isValid = false
        } else {
            // Verify category exists in available categories
            let categoryExists = availableCategories.contains { category in
                category.canonicalName == selectedCategory ||
                category.displayName == selectedCategory
            }
            
            if !categoryExists {
                print("Invalid category selected: '\(selectedCategory)'")
                print("   Defaulting to 'Other' category")
                
                // Auto-correct to "other" category
                if let otherCategory = availableCategories.first(where: { $0.canonicalName == "other" }) {
                    selectedCategory = otherCategory.canonicalName
                    categoryError = "Category was invalid and has been set to 'Other'. Please select a valid category."
                    isValid = false
                } else {
                    categoryError = "Invalid category selected"
                    isValid = false
                }
            }
        }
        
        // Validate account
        if selectedAccount == nil {
            accountError = "Account is required"
            isValid = false
        }
        
        return isValid
    }
    
    // MARK: - Save Transaction
    func saveTransaction() async {
        guard validateForm() else { return }
        
        isSaving = true
        error = nil
        
        do {
            // Create new transaction
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.date = date
            transaction.merchant = merchant.trimmingCharacters(in: .whitespaces)
            transaction.amount = NSDecimalNumber(string: amount)
            transaction.currency = "USD"
            // Store canonical category name with validation
            transaction.category = ensureValidCategory(selectedCategory)
            transaction.setCategorizationMethod(.manual)
            transaction.confidence = 1.0 // Manual entry has 100% confidence
            transaction.isManual = true
            transaction.notes = notes.isEmpty ? nil : notes
            transaction.account = selectedAccount
            transaction.statement = nil
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
            
            // Save to repository
            try await transactionRepository.save(transaction)
            
            Analytics.track(.transactionAdded, properties: [
                "source": "manual",
                "has_notes": !notes.isEmpty,
                "category": selectedCategory,
                "autocomplete_used": merchantHistory[merchant.lowercased()] != nil
            ])
            
            // Update merchant history
            let merchantKey = merchant.trimmingCharacters(in: .whitespaces).lowercased()
            merchantHistory[merchantKey] = selectedCategory
            
            // Show success animation
            showSuccessAnimation = true
            
            // Small delay before resetting form
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Show success message and reset form
            showSuccessMessage = true
            resetForm()
            
            // Hide success animation after delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            showSuccessAnimation = false
            showSuccessMessage = false
            isSaving = false
            
        } catch {
            isSaving = false
            handleError(error, context: ["operation": "save_transaction"])
        }
    }
    
    // MARK: - Form Management
    func resetForm() {
        date = Date()
        merchant = ""
        amount = ""
        selectedCategory = "other"  // Use valid default category instead of empty string
        notes = ""
        isRecurring = false
        merchantError = nil
        amountError = nil
        categoryError = nil
        accountError = nil
        merchantSuggestions = []
        showMerchantSuggestions = false
    }
    
    // MARK: - Category Management
    func getDisplayName(for canonicalName: String) -> String {
        return categoryMappingService.getDisplayName(for: canonicalName)
    }
    
    /// Safely get or create a valid category, with fallback to "other"
    func ensureValidCategory(_ categoryName: String) -> String {
        // Check if it's already a valid canonical name
        if availableCategories.contains(where: { $0.canonicalName == categoryName }) {
            return categoryName
        }
        
        // Try to map it
        if let category = categoryMappingService.getCanonicalCategory(from: categoryName) {
            return category.canonicalName
        }
        
        // Log the failure and return "other"
        print("Category mapping failed for: '\(categoryName)'")
        print("   Using 'Other' category as fallback")
        
        return "other"
    }
    
    // MARK: - Recurring Transaction Support
    func saveRecurringTransaction(
        frequency: RecurringFrequency,
        startDate: Date,
        endDate: Date?
    ) async {
        guard validateForm() else { return }
        guard let recurringService = recurringService else {
            handleError(AppError.validationError(message: "Recurring transaction service not available"), context: ["operation": "save_recurring_transaction"])
            return
        }
        
        isSaving = true
        error = nil
        
        do {
            guard let account = selectedAccount else {
                throw RepositoryError.validationFailed("Account is required")
            }
            
            guard let amountDecimal = Decimal(string: amount) else {
                throw RepositoryError.validationFailed("Invalid amount")
            }
            
            _ = try await recurringService.createRecurringTransaction(
                merchant: merchant.trimmingCharacters(in: .whitespaces),
                amount: amountDecimal,
                category: selectedCategory,  // Already canonical name
                account: account,
                frequency: frequency,
                startDate: startDate,
                endDate: endDate,
                notes: notes.isEmpty ? nil : notes
            )
            
            // Update merchant history
            let merchantKey = merchant.trimmingCharacters(in: .whitespaces).lowercased()
            merchantHistory[merchantKey] = selectedCategory
            
            // Show success and reset form
            showSuccessMessage = true
            resetForm()
            
            // Hide success message after delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            showSuccessMessage = false
            isSaving = false
            
        } catch {
            isSaving = false
            handleError(error, context: ["operation": "save_recurring_transaction"])
        }
    }
}
