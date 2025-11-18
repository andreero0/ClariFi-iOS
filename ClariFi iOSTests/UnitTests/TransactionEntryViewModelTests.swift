//
//  TransactionEntryViewModelTests.swift
//  ClariFi_iOS Tests
//
//  Unit tests for TransactionEntryViewModel using DI container and mocks
//

import XCTest
import CoreData
@testable import ClariFi_iOS

@MainActor
final class TransactionEntryViewModelTests: XCTestCase {
    
    var container: DIContainer!
    var viewModel: TransactionEntryViewModel!
    var mockTransactionRepository: MockTransactionRepository!
    var mockAccountRepository: MockAccountRepository!
    var context: NSManagedObjectContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory Core Data context
        let persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
        
        // Create mock repositories
        mockTransactionRepository = MockTransactionRepository()
        mockAccountRepository = MockAccountRepository()
        
        // Create test container with mocks
        container = AppDIContainer()
        container.registerSingleton(TransactionRepository.self) { _ in
            self.mockTransactionRepository
        }
        container.registerSingleton(AccountRepository.self) { _ in
            self.mockAccountRepository
        }
        
        // Create ViewModel with injected dependencies
        viewModel = TransactionEntryViewModel(
            transactionRepository: mockTransactionRepository,
            accountRepository: mockAccountRepository,
            context: context,
            recurringService: nil
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockTransactionRepository = nil
        mockAccountRepository = nil
        container = nil
        context = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.merchant, "")
        XCTAssertEqual(viewModel.amount, "")
        XCTAssertEqual(viewModel.selectedCategory, "")
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertFalse(viewModel.isRecurring)
        XCTAssertFalse(viewModel.isSaving)
        XCTAssertFalse(viewModel.showSuccessMessage)
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Load Accounts Tests
    
    func testLoadAccountsSuccess() async {
        // Arrange
        let account1 = Account(context: context)
        account1.id = UUID()
        account1.name = "Checking"
        account1.isActive = true
        
        let account2 = Account(context: context)
        account2.id = UUID()
        account2.name = "Savings"
        account2.isActive = true
        
        mockAccountRepository.mockAccounts = [account1, account2]
        
        // Act
        await viewModel.loadAccounts()
        
        // Assert
        XCTAssertTrue(mockAccountRepository.fetchActiveAccountsCalled)
        XCTAssertEqual(viewModel.accounts.count, 2)
        XCTAssertNotNil(viewModel.selectedAccount)
        XCTAssertEqual(viewModel.selectedAccount?.name, "Checking")
    }
    
    func testLoadAccountsError() async {
        // Arrange
        mockAccountRepository.shouldThrowError = true
        
        // Act
        await viewModel.loadAccounts()
        
        // Assert
        XCTAssertTrue(mockAccountRepository.fetchActiveAccountsCalled)
        XCTAssertTrue(viewModel.accounts.isEmpty)
        XCTAssertNotNil(viewModel.error)
    }
    
    // MARK: - Validation Tests
    
    func testValidateFormSuccess() {
        // Arrange
        viewModel.merchant = "Test Merchant"
        viewModel.amount = "100.50"
        viewModel.selectedCategory = "Food"
        
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Checking"
        viewModel.selectedAccount = account
        
        // Act
        let isValid = viewModel.validateForm()
        
        // Assert
        XCTAssertTrue(isValid)
        XCTAssertNil(viewModel.merchantError)
        XCTAssertNil(viewModel.amountError)
        XCTAssertNil(viewModel.categoryError)
        XCTAssertNil(viewModel.accountError)
    }
    
    func testValidateFormEmptyMerchant() {
        // Arrange
        viewModel.merchant = ""
        viewModel.amount = "100"
        viewModel.selectedCategory = "Food"
        
        let account = Account(context: context)
        account.id = UUID()
        viewModel.selectedAccount = account
        
        // Act
        let isValid = viewModel.validateForm()
        
        // Assert
        XCTAssertFalse(isValid)
        XCTAssertNotNil(viewModel.merchantError)
    }
    
    func testValidateFormEmptyAmount() {
        // Arrange
        viewModel.merchant = "Test Merchant"
        viewModel.amount = ""
        viewModel.selectedCategory = "Food"
        
        let account = Account(context: context)
        account.id = UUID()
        viewModel.selectedAccount = account
        
        // Act
        let isValid = viewModel.validateForm()
        
        // Assert
        XCTAssertFalse(isValid)
        XCTAssertNotNil(viewModel.amountError)
    }
    
    func testValidateFormInvalidAmount() {
        // Arrange
        viewModel.merchant = "Test Merchant"
        viewModel.amount = "invalid"
        viewModel.selectedCategory = "Food"
        
        let account = Account(context: context)
        account.id = UUID()
        viewModel.selectedAccount = account
        
        // Act
        let isValid = viewModel.validateForm()
        
        // Assert
        XCTAssertFalse(isValid)
        XCTAssertNotNil(viewModel.amountError)
    }
    
    func testValidateFormNegativeAmount() {
        // Arrange
        viewModel.merchant = "Test Merchant"
        viewModel.amount = "-50"
        viewModel.selectedCategory = "Food"
        
        let account = Account(context: context)
        account.id = UUID()
        viewModel.selectedAccount = account
        
        // Act
        let isValid = viewModel.validateForm()
        
        // Assert
        XCTAssertFalse(isValid)
        XCTAssertNotNil(viewModel.amountError)
    }
    
    func testValidateFormEmptyCategory() {
        // Arrange
        viewModel.merchant = "Test Merchant"
        viewModel.amount = "100"
        viewModel.selectedCategory = ""
        
        let account = Account(context: context)
        account.id = UUID()
        viewModel.selectedAccount = account
        
        // Act
        let isValid = viewModel.validateForm()
        
        // Assert
        XCTAssertFalse(isValid)
        XCTAssertNotNil(viewModel.categoryError)
    }
    
    func testValidateFormNoAccount() {
        // Arrange
        viewModel.merchant = "Test Merchant"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Food"
        viewModel.selectedAccount = nil
        
        // Act
        let isValid = viewModel.validateForm()
        
        // Assert
        XCTAssertFalse(isValid)
        XCTAssertNotNil(viewModel.accountError)
    }
    
    // MARK: - Save Transaction Tests
    
    func testSaveTransactionSuccess() async {
        // Arrange
        viewModel.merchant = "Test Merchant"
        viewModel.amount = "100.50"
        viewModel.selectedCategory = "Food"
        viewModel.notes = "Test notes"
        
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Checking"
        viewModel.selectedAccount = account
        
        // Act
        await viewModel.saveTransaction()
        
        // Wait for async completion
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Assert
        XCTAssertTrue(mockTransactionRepository.saveCalled)
        XCTAssertEqual(mockTransactionRepository.saveCallCount, 1)
        XCTAssertNotNil(mockTransactionRepository.lastSavedTransaction)
        XCTAssertEqual(mockTransactionRepository.lastSavedTransaction?.merchant, "Test Merchant")
        XCTAssertEqual(mockTransactionRepository.lastSavedTransaction?.amount?.decimalValue, Decimal(string: "100.50"))
        XCTAssertEqual(mockTransactionRepository.lastSavedTransaction?.category, "Food")
        XCTAssertTrue(mockTransactionRepository.lastSavedTransaction?.isManual ?? false)
        XCTAssertEqual(mockTransactionRepository.lastSavedTransaction?.confidence, 1.0)
    }
    
    func testSaveTransactionValidationFailure() async {
        // Arrange - Invalid form (empty merchant)
        viewModel.merchant = ""
        viewModel.amount = "100"
        viewModel.selectedCategory = "Food"
        
        let account = Account(context: context)
        account.id = UUID()
        viewModel.selectedAccount = account
        
        // Act
        await viewModel.saveTransaction()
        
        // Assert
        XCTAssertFalse(mockTransactionRepository.saveCalled)
        XCTAssertNotNil(viewModel.merchantError)
    }
    
    func testSaveTransactionError() async {
        // Arrange
        viewModel.merchant = "Test Merchant"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Food"
        
        let account = Account(context: context)
        account.id = UUID()
        viewModel.selectedAccount = account
        
        mockTransactionRepository.shouldThrowError = true
        
        // Act
        await viewModel.saveTransaction()
        
        // Assert
        XCTAssertTrue(mockTransactionRepository.saveCalled)
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isSaving)
    }
    
    // MARK: - Reset Form Tests
    
    func testResetForm() {
        // Arrange
        viewModel.merchant = "Test Merchant"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Food"
        viewModel.notes = "Test notes"
        viewModel.merchantError = "Error"
        viewModel.amountError = "Error"
        
        // Act
        viewModel.resetForm()
        
        // Assert
        XCTAssertEqual(viewModel.merchant, "")
        XCTAssertEqual(viewModel.amount, "")
        XCTAssertEqual(viewModel.selectedCategory, "")
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertFalse(viewModel.isRecurring)
        XCTAssertNil(viewModel.merchantError)
        XCTAssertNil(viewModel.amountError)
        XCTAssertNil(viewModel.categoryError)
        XCTAssertNil(viewModel.accountError)
    }
    
    // MARK: - Category Tests
    
    func testGetDefaultCategories() {
        // Act
        let categories = viewModel.getDefaultCategories()
        
        // Assert
        XCTAssertFalse(categories.isEmpty)
        XCTAssertTrue(categories.contains("Food & Dining"))
        XCTAssertTrue(categories.contains("Groceries"))
        XCTAssertTrue(categories.contains("Transportation"))
    }
    
    func testGetAllCategories() {
        // Arrange
        viewModel.merchantHistory = [
            "starbucks": "Coffee",
            "walmart": "Groceries"
        ]
        
        // Act
        let categories = viewModel.getAllCategories()
        
        // Assert
        XCTAssertFalse(categories.isEmpty)
        XCTAssertTrue(categories.contains("Coffee"))
        XCTAssertTrue(categories.contains("Groceries"))
        XCTAssertTrue(categories.contains("Food & Dining"))
    }
    
    // MARK: - Merchant Suggestions Tests
    
    func testMerchantSuggestionsWithHistory() async {
        // Arrange
        let transaction1 = Transaction(context: context)
        transaction1.id = UUID()
        transaction1.merchant = "Starbucks"
        transaction1.category = "Coffee"
        
        let transaction2 = Transaction(context: context)
        transaction2.id = UUID()
        transaction2.merchant = "Starbucks Downtown"
        transaction2.category = "Coffee"
        
        mockTransactionRepository.mockTransactions = [transaction1, transaction2]
        
        // Load merchant history
        await viewModel.loadAccounts()
        
        // Wait for history to load
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Act - Simulate typing "star"
        viewModel.merchant = "star"
        
        // Wait for debounce
        try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
        
        // Assert
        XCTAssertTrue(viewModel.merchantSuggestions.count > 0 || viewModel.merchantHistory.keys.contains("starbucks"))
    }
}
