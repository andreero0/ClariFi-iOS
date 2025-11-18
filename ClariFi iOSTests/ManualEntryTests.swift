//
//  ManualEntryTests.swift
//  ClariFi_iOSTests
//
//  Created by Kiro on 2025-10-10.
//

import Testing
import CoreData
@testable import ClariFi_iOS

struct ManualEntryTests {
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    var transactionRepository: CoreDataTransactionRepository!
    var accountRepository: CoreDataAccountRepository!
    var recurringRepository: CoreDataRecurringTransactionRepository!
    var recurringService: CoreDataRecurringTransactionService!
    var testAccount: Account!
    
    init() throws {
        
        
        // Use in-memory store for testing
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
        
        // Initialize repositories
        transactionRepository = CoreDataTransactionRepository(context: context)
        accountRepository = CoreDataAccountRepository(context: context)
        recurringRepository = CoreDataRecurringTransactionRepository(context: context)
        
        // Initialize recurring service
        recurringService = CoreDataRecurringTransactionService(
            recurringRepository: recurringRepository,
            transactionRepository: transactionRepository,
            context: context
        )
        
        // Create test account
        testAccount = Account(context: context)
        testAccount.id = UUID()
        testAccount.name = "Test Account"
        testAccount.type = "debit"
        testAccount.lastFourDigits = "1234"
        testAccount.isActive = true
        testAccount.createdAt = Date()
        testAccount.updatedAt = Date()
        try? context.save()
    }
    
    
    // MARK: - Helper Methods
    
    private func createViewModel() -> TransactionEntryViewModel {
        return TransactionEntryViewModel(
            transactionRepository: transactionRepository,
            accountRepository: accountRepository,
            context: context,
            recurringService: recurringService
        )
    }
    
    private func createTestTransactionHistory() {
        let merchants = [
            ("Starbucks", "Food & Dining"),
            ("Target", "Shopping"),
            ("Shell Gas", "Transportation"),
            ("Amazon", "Shopping")
        ]
        
        for (merchant, category) in merchants {
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.merchant = merchant
            transaction.category = category
            transaction.amount = NSDecimalNumber(value: 10.0)
            transaction.date = Date()
            transaction.account = testAccount
            transaction.isManual = true
            transaction.confidence = 1.0
            transaction.currency = "USD"
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
        }
        
        try? context.save()
    }
    
    // MARK: - Form Validation Tests
    
    func testValidateForm_WithValidData_ReturnsTrue() async {
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = "Starbucks"
            viewModel.amount = "4.50"
            viewModel.selectedCategory = "Food & Dining"
            viewModel.selectedAccount = testAccount
            
            let isValid = viewModel.validateForm()
            
            #expect(isValid == true)
            #expect(viewModel.merchantError == nil)
            #expect(viewModel.amountError == nil)
            #expect(viewModel.categoryError == nil)
            #expect(viewModel.accountError == nil)
        }
    }
    
    func testValidateForm_WithEmptyMerchant_ReturnsFalse() async {
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = ""
            viewModel.amount = "10.00"
            viewModel.selectedCategory = "Shopping"
            viewModel.selectedAccount = testAccount
            
            let isValid = viewModel.validateForm()
            
            #expect(isValid == false)
            #expect(viewModel.merchantError == "Merchant name is required")
        }
    }
    
    func testValidateForm_WithWhitespaceMerchant_ReturnsFalse() async {
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = "   "
            viewModel.amount = "10.00"
            viewModel.selectedCategory = "Shopping"
            viewModel.selectedAccount = testAccount
            
            let isValid = viewModel.validateForm()
            
            #expect(isValid == false)
            #expect(viewModel.merchantError == "Merchant name is required")
        }
    }
    
    func testValidateForm_WithEmptyAmount_ReturnsFalse() async {
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = "Target"
            viewModel.amount = ""
            viewModel.selectedCategory = "Shopping"
            viewModel.selectedAccount = testAccount
            
            let isValid = viewModel.validateForm()
            
            #expect(isValid == false)
            #expect(viewModel.amountError == "Amount is required")
        }
    }
    
    func testValidateForm_WithInvalidAmountFormat_ReturnsFalse() async {
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = "Target"
            viewModel.amount = "abc"
            viewModel.selectedCategory = "Shopping"
            viewModel.selectedAccount = testAccount
            
            let isValid = viewModel.validateForm()
            
            #expect(isValid == false)
            #expect(viewModel.amountError == "Invalid amount format")
        }
    }
    
    func testValidateForm_WithNegativeAmount_ReturnsFalse() async {
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = "Target"
            viewModel.amount = "-10.00"
            viewModel.selectedCategory = "Shopping"
            viewModel.selectedAccount = testAccount
            
            let isValid = viewModel.validateForm()
            
            #expect(isValid == false)
            #expect(viewModel.amountError == "Amount must be greater than zero")
        }
    }
    
    func testValidateForm_WithZeroAmount_ReturnsFalse() async {
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = "Target"
            viewModel.amount = "0"
            viewModel.selectedCategory = "Shopping"
            viewModel.selectedAccount = testAccount
            
            let isValid = viewModel.validateForm()
            
            #expect(isValid == false)
            #expect(viewModel.amountError == "Amount must be greater than zero")
        }
    }
    
    func testValidateForm_WithEmptyCategory_ReturnsFalse() async {
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = "Target"
            viewModel.amount = "25.00"
            viewModel.selectedCategory = ""
            viewModel.selectedAccount = testAccount
            
            let isValid = viewModel.validateForm()
            
            #expect(isValid == false)
            #expect(viewModel.categoryError == "Category is required")
        }
    }
    
    func testValidateForm_WithNoAccount_ReturnsFalse() async {
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = "Target"
            viewModel.amount = "25.00"
            viewModel.selectedCategory = "Shopping"
            viewModel.selectedAccount = nil
            
            let isValid = viewModel.validateForm()
            
            #expect(isValid == false)
            #expect(viewModel.accountError == "Account is required")
        }
    }
    
    func testValidateForm_WithMultipleErrors_SetsAllErrors() async {
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = ""
            viewModel.amount = "invalid"
            viewModel.selectedCategory = ""
            viewModel.selectedAccount = nil
            
            let isValid = viewModel.validateForm()
            
            #expect(isValid == false)
            #expect(viewModel.merchantError != nil)
            #expect(viewModel.amountError != nil)
            #expect(viewModel.categoryError != nil)
            #expect(viewModel.accountError != nil)
        }
    }
    
    func testValidateForm_ResetsErrorsOnValidInput() async {
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            // First set some errors
            viewModel.merchant = ""
            viewModel.amount = ""
            _ = viewModel.validateForm()
            #expect(viewModel.merchantError != nil)
            #expect(viewModel.amountError != nil)
            
            // Then provide valid input
            viewModel.merchant = "Starbucks"
            viewModel.amount = "5.00"
            viewModel.selectedCategory = "Food & Dining"
            viewModel.selectedAccount = testAccount
            let isValid = viewModel.validateForm()
            
            #expect(isValid == true)
            #expect(viewModel.merchantError == nil)
            #expect(viewModel.amountError == nil)
        }
    }
    
    // MARK: - Merchant Autocomplete Tests
    
    func testMerchantAutocomplete_WithEmptyQuery_ReturnsNoSuggestions() async {
        createTestTransactionHistory()
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = ""
        }
        
        // Wait for debounce
        try? await Task.sleep(nanoseconds: 400_000_000)
        
        await MainActor.run {
            #expect(viewModel.merchantSuggestions.isEmpty == true)
            #expect(viewModel.showMerchantSuggestions == false)
        }
    }
    
    func testMerchantAutocomplete_WithMatchingQuery_ReturnsSuggestions() async {
        createTestTransactionHistory()
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = "star"
        }
        
        // Wait for debounce
        try? await Task.sleep(nanoseconds: 400_000_000)
        
        await MainActor.run {
            #expect(viewModel.merchantSuggestions.isEmpty == false)
            #expect(viewModel.showMerchantSuggestions == true)
            #expect(viewModel.merchantSuggestions.contains { $0.lowercased().contains("starbucks") })
        }
    }
    
    func testMerchantAutocomplete_WithNonMatchingQuery_ReturnsNoSuggestions() async {
        createTestTransactionHistory()
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = "xyz123"
        }
        
        // Wait for debounce
        try? await Task.sleep(nanoseconds: 400_000_000)
        
        await MainActor.run {
            #expect(viewModel.merchantSuggestions.isEmpty == true)
            #expect(viewModel.showMerchantSuggestions == false)
        }
    }
    
    func testMerchantAutocomplete_LimitsToFiveSuggestions() async {
        // Create more than 5 merchants with similar names
        for i in 1...10 {
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.merchant = "Store\(i)"
            transaction.category = "Shopping"
            transaction.amount = NSDecimalNumber(value: 10.0)
            transaction.date = Date()
            transaction.account = testAccount
            transaction.isManual = true
            transaction.confidence = 1.0
            transaction.currency = "USD"
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
        }
        try? context.save()
        
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = "store"
        }
        
        // Wait for debounce
        try? await Task.sleep(nanoseconds: 400_000_000)
        
        await MainActor.run {
            #expect(viewModel.merchantSuggestions.count <= 5)
        }
    }
    
    func testSelectMerchantSuggestion_UpdatesMerchantAndHidesSuggestions() async {
        createTestTransactionHistory()
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = "star"
        }
        
        try? await Task.sleep(nanoseconds: 400_000_000)
        
        await MainActor.run {
            #expect(viewModel.showMerchantSuggestions == true)
            
            viewModel.selectMerchantSuggestion("Starbucks")
            
            #expect(viewModel.merchant == "Starbucks")
            #expect(viewModel.showMerchantSuggestions == false)
        }
    }
    
    func testMerchantAutocomplete_SuggestsCategoryFromHistory() async {
        createTestTransactionHistory()
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.selectedCategory = "" // Ensure category is empty
            viewModel.merchant = "Starbucks"
        }
        
        // Wait for debounce
        try? await Task.sleep(nanoseconds: 600_000_000)
        
        await MainActor.run {
            #expect(viewModel.selectedCategory == "Food & Dining")
        }
    }
    
    func testMerchantAutocomplete_DoesNotOverrideExistingCategory() async {
        createTestTransactionHistory()
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.selectedCategory = "Entertainment" // Pre-selected category
            viewModel.merchant = "Starbucks"
        }
        
        // Wait for debounce
        try? await Task.sleep(nanoseconds: 600_000_000)
        
        await MainActor.run {
            #expect(viewModel.selectedCategory == "Entertainment") // Should not change
        }
    }
    
    // MARK: - Save Transaction Tests
    
    func testSaveTransaction_WithValidData_SavesSuccessfully() async {
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = "Whole Foods"
            viewModel.amount = "45.67"
            viewModel.selectedCategory = "Groceries"
            viewModel.selectedAccount = testAccount
            viewModel.notes = "Weekly groceries"
        }
        
        await viewModel.saveTransaction()
        
        await MainActor.run {
            #expect(viewModel.isSaving == false)
            #expect(viewModel.errorMessage == nil)
        }
        
        // Verify transaction was saved
        let transactions = try? await transactionRepository.fetchAll()
        #expect(transactions?.count == 1)
        #expect(transactions?.first?.merchant == "Whole Foods")
        #expect(transactions?.first?.amount == NSDecimalNumber(string: "45.67"))
        #expect(transactions?.first?.category == "Groceries")
        #expect(transactions?.first?.isManual ?? false == true)
        #expect(transactions?.first?.confidence == 1.0)
    }
    
    func testSaveTransaction_UpdatesMerchantHistory() async {
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = "New Merchant"
            viewModel.amount = "20.00"
            viewModel.selectedCategory = "Shopping"
            viewModel.selectedAccount = testAccount
        }
        
        await viewModel.saveTransaction()
        
        await MainActor.run {
            #expect(viewModel.merchantHistory["new merchant"] == "Shopping")
        }
    }
    
    func testSaveTransaction_ResetsFormAfterSuccess() async {
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = "Test Merchant"
            viewModel.amount = "10.00"
            viewModel.selectedCategory = "Other"
            viewModel.selectedAccount = testAccount
            viewModel.notes = "Test note"
        }
        
        await viewModel.saveTransaction()
        
        await MainActor.run {
            #expect(viewModel.merchant == "")
            #expect(viewModel.amount == "")
            #expect(viewModel.selectedCategory == "")
            #expect(viewModel.notes == "")
            #expect(viewModel.isRecurring == false)
        }
    }
    
    func testSaveTransaction_WithInvalidData_DoesNotSave() async {
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = ""
            viewModel.amount = "invalid"
            viewModel.selectedCategory = ""
        }
        
        await viewModel.saveTransaction()
        
        let transactions = try? await transactionRepository.fetchAll()
        #expect(transactions?.count == 0)
    }
    
    // MARK: - Recurring Transaction Tests
    
    func testSaveRecurringTransaction_WithValidData_CreatesRecurringTransaction() async {
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate)
        
        await MainActor.run {
            viewModel.merchant = "Netflix"
            viewModel.amount = "15.99"
            viewModel.selectedCategory = "Entertainment"
            viewModel.selectedAccount = testAccount
            viewModel.notes = "Monthly subscription"
        }
        
        await viewModel.saveRecurringTransaction(
            frequency: .monthly,
            startDate: startDate,
            endDate: endDate
        )
        
        await MainActor.run {
            #expect(viewModel.isSaving == false)
            #expect(viewModel.errorMessage == nil)
        }
        
        // Verify recurring transaction was created
        let recurring = try? await recurringRepository.fetchActiveRecurring()
        #expect(recurring?.count == 1)
        #expect(recurring?.first?.merchant == "Netflix")
        #expect(recurring?.first?.amount == NSDecimalNumber(string: "15.99"))
        #expect(recurring?.first?.category == "Entertainment")
        #expect(recurring?.first?.frequency == "Monthly")
    }
    
    func testSaveRecurringTransaction_WithInvalidData_DoesNotCreate() async {
        let viewModel = createViewModel()
        await viewModel.loadAccounts()
        
        await MainActor.run {
            viewModel.merchant = ""
            viewModel.amount = "invalid"
            viewModel.selectedCategory = ""
        }
        
        await viewModel.saveRecurringTransaction(
            frequency: .monthly,
            startDate: Date(),
            endDate: nil
        )
        
        let recurring = try? await recurringRepository.fetchActiveRecurring()
        #expect(recurring?.count == 0)
    }
    
    func testRecurringFrequency_NextOccurrence_Daily() {
        let frequency = RecurringFrequency.daily
        let startDate = Date()
        
        let nextDate = frequency.nextOccurrence(from: startDate)
        
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: startDate, to: nextDate).day
        #expect(daysDifference == 1)
    }
    
    func testRecurringFrequency_NextOccurrence_Weekly() {
        let frequency = RecurringFrequency.weekly
        let startDate = Date()
        
        let nextDate = frequency.nextOccurrence(from: startDate)
        
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: startDate, to: nextDate).day
        #expect(daysDifference == 7)
    }
    
    func testRecurringFrequency_NextOccurrence_Monthly() {
        let frequency = RecurringFrequency.monthly
        let startDate = Date()
        
        let nextDate = frequency.nextOccurrence(from: startDate)
        
        let calendar = Calendar.current
        let monthsDifference = calendar.dateComponents([.month], from: startDate, to: nextDate).month
        #expect(monthsDifference == 1)
    }
    
    func testProcessRecurringTransactions_CreatesDueTransactions() async throws {
        let recurring = RecurringTransaction(context: context)
        recurring.id = UUID()
        recurring.merchant = "Spotify"
        recurring.amount = NSDecimalNumber(string: "9.99")
        recurring.currency = "USD"
        recurring.category = "Entertainment"
        recurring.frequency = RecurringFrequency.monthly.rawValue
        recurring.startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        recurring.nextOccurrence = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        recurring.isActive = true
        recurring.account = testAccount
        recurring.createdAt = Date()
        recurring.updatedAt = Date()
        try context.save()
        
        let createdTransactions = try await recurringService.processRecurringTransactions()
        
        #expect(createdTransactions.count == 1)
        #expect(createdTransactions.first?.merchant == "Spotify")
        #expect(createdTransactions.first?.amount == NSDecimalNumber(string: "9.99"))
        #expect(createdTransactions.first?.isManual ?? false == true)
    }
    
    func testProcessRecurringTransactions_UpdatesNextOccurrence() async throws {
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let recurring = RecurringTransaction(context: context)
        recurring.id = UUID()
        recurring.merchant = "Gym Membership"
        recurring.amount = NSDecimalNumber(string: "50.00")
        recurring.currency = "USD"
        recurring.category = "Healthcare"
        recurring.frequency = RecurringFrequency.monthly.rawValue
        recurring.startDate = startDate
        recurring.nextOccurrence = startDate
        recurring.isActive = true
        recurring.account = testAccount
        recurring.createdAt = Date()
        recurring.updatedAt = Date()
        try context.save()
        
        _ = try await recurringService.processRecurringTransactions()
        
        context.refresh(recurring, mergeChanges: true)
        #expect(recurring.nextOccurrence != nil)
        #expect(recurring.nextOccurrence! > startDate)
    }
    
    func testProcessRecurringTransactions_DeactivatesExpiredRecurring() async throws {
        let endDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let recurring = RecurringTransaction(context: context)
        recurring.id = UUID()
        recurring.merchant = "Expired Service"
        recurring.amount = NSDecimalNumber(string: "10.00")
        recurring.currency = "USD"
        recurring.category = "Other"
        recurring.frequency = RecurringFrequency.monthly.rawValue
        recurring.startDate = Calendar.current.date(byAdding: .month, value: -2, to: Date())
        recurring.nextOccurrence = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        recurring.endDate = endDate
        recurring.isActive = true
        recurring.account = testAccount
        recurring.createdAt = Date()
        recurring.updatedAt = Date()
        try context.save()
        
        _ = try await recurringService.processRecurringTransactions()
        
        context.refresh(recurring, mergeChanges: true)
        #expect(recurring.isActive == false)
    }
}
