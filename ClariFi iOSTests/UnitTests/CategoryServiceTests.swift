//
//  CategoryServiceTests.swift
//  ClariFi_iOS Tests
//
//  Tests for CategoryService with mock dependencies
//

import XCTest
import CoreData
@testable import ClariFi_iOS

@MainActor
final class CategoryServiceTests: XCTestCase {
    
    var sut: CategoryService!
    var context: NSManagedObjectContext!
    var mockTransactionRepository: MockTransactionRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory Core Data stack for testing
        let persistenceController = PersistenceController.preview
        context = persistenceController.container.viewContext
        
        mockTransactionRepository = MockTransactionRepository()
        sut = CategoryService(context: context, transactionRepository: mockTransactionRepository)
    }
    
    override func tearDown() async throws {
        sut = nil
        context = nil
        mockTransactionRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Categorization Tests
    
    func testCategorize_WithKnownMerchant_ReturnsCorrectCategory() async throws {
        // Arrange
        let merchant = "Starbucks Coffee"
        let amount = Decimal(5.50)
        
        // Act
        let result = try await sut.categorize(merchant: merchant, amount: amount)
        
        // Assert
        XCTAssertEqual(result.category, "Dining & Restaurants")
        XCTAssertGreaterThan(result.confidence, 0.7)
        XCTAssertEqual(result.matchType, .patternMatch)
    }
    
    func testCategorize_WithUnknownMerchant_ReturnsOtherCategory() async throws {
        // Arrange
        let merchant = "Unknown Merchant XYZ"
        let amount = Decimal(100)
        
        // Act
        let result = try await sut.categorize(merchant: merchant, amount: amount)
        
        // Assert
        XCTAssertEqual(result.category, "Other")
        XCTAssertLessThan(result.confidence, 0.5)
        XCTAssertEqual(result.matchType, .default_)
    }
    
    func testCategorize_WithGroceryStore_ReturnsGroceriesCategory() async throws {
        // Arrange
        let merchants = ["Walmart", "Target", "Whole Foods", "Trader Joe's"]
        
        for merchant in merchants {
            // Act
            let result = try await sut.categorize(merchant: merchant, amount: 50)
            
            // Assert
            XCTAssertEqual(result.category, "Groceries", "Failed for merchant: \(merchant)")
            XCTAssertGreaterThan(result.confidence, 0.7)
        }
    }
    
    func testCategorize_WithTransportation_ReturnsTransportationCategory() async throws {
        // Arrange
        let merchants = ["Uber", "Lyft", "Shell Gas", "Chevron"]
        
        for merchant in merchants {
            // Act
            let result = try await sut.categorize(merchant: merchant, amount: 25)
            
            // Assert
            XCTAssertEqual(result.category, "Transportation", "Failed for merchant: \(merchant)")
        }
    }
    
    func testCategorize_WithSubscription_ReturnsEntertainmentCategory() async throws {
        // Arrange
        let merchants = ["Netflix", "Spotify", "Hulu", "Disney Plus"]
        
        for merchant in merchants {
            // Act
            let result = try await sut.categorize(merchant: merchant, amount: 15)
            
            // Assert
            XCTAssertEqual(result.category, "Entertainment", "Failed for merchant: \(merchant)")
        }
    }
    
    // MARK: - Learning Tests
    
    func testLearnFromCorrection_CreatesNewPattern() async throws {
        // Arrange
        let merchant = "Local Coffee Shop"
        let category = "Dining & Restaurants"
        
        // Act
        try await sut.learnFromCorrection(merchant: merchant, category: category)
        
        // Verify pattern was created
        let result = try await sut.categorize(merchant: merchant, amount: 5)
        
        // Assert
        XCTAssertEqual(result.category, category)
        XCTAssertEqual(result.matchType, .learned)
        XCTAssertGreaterThan(result.confidence, 0.6)
    }
    
    func testLearnFromCorrection_UpdatesExistingPattern() async throws {
        // Arrange
        let merchant = "Test Merchant"
        let initialCategory = "Shopping"
        let updatedCategory = "Groceries"
        
        // Create initial pattern
        try await sut.learnFromCorrection(merchant: merchant, category: initialCategory)
        
        // Act - Update with new category
        try await sut.learnFromCorrection(merchant: merchant, category: updatedCategory)
        
        // Verify pattern was updated
        let result = try await sut.categorize(merchant: merchant, amount: 50)
        
        // Assert
        XCTAssertEqual(result.category, updatedCategory)
    }
    
    func testLearnFromCorrection_IncreasesConfidenceWithRepetition() async throws {
        // Arrange
        let merchant = "Repeated Merchant"
        let category = "Food"
        
        // Act - Learn multiple times
        try await sut.learnFromCorrection(merchant: merchant, category: category)
        let firstResult = try await sut.categorize(merchant: merchant, amount: 10)
        
        try await sut.learnFromCorrection(merchant: merchant, category: category)
        let secondResult = try await sut.categorize(merchant: merchant, amount: 10)
        
        // Assert
        XCTAssertGreaterThan(secondResult.confidence, firstResult.confidence)
    }
    
    // MARK: - Suggested Categories Tests
    
    func testGetSuggestedCategories_WithLearnedPattern_ReturnsLearned() async throws {
        // Arrange
        let merchant = "Coffee Shop"
        let category = "Dining & Restaurants"
        try await sut.learnFromCorrection(merchant: merchant, category: category)
        
        // Act
        let suggestions = try await sut.getSuggestedCategories(for: merchant)
        
        // Assert
        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.contains { $0.category == category })
    }
    
    func testGetSuggestedCategories_WithBuiltInPattern_ReturnsPattern() async throws {
        // Arrange
        let merchant = "Starbucks"
        
        // Act
        let suggestions = try await sut.getSuggestedCategories(for: merchant)
        
        // Assert
        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.contains { $0.category == "Dining & Restaurants" })
    }
    
    func testGetSuggestedCategories_ReturnsTopThree() async throws {
        // Arrange
        let merchant = "Test Merchant"
        
        // Create multiple learned patterns with similar names
        try await sut.learnFromCorrection(merchant: "Test Merchant A", category: "Food")
        try await sut.learnFromCorrection(merchant: "Test Merchant B", category: "Shopping")
        try await sut.learnFromCorrection(merchant: "Test Merchant C", category: "Entertainment")
        try await sut.learnFromCorrection(merchant: "Test Merchant D", category: "Transportation")
        
        // Act
        let suggestions = try await sut.getSuggestedCategories(for: merchant)
        
        // Assert
        XCTAssertLessThanOrEqual(suggestions.count, 3)
    }
    
    // MARK: - Merchant History Tests
    
    func testGetMerchantHistory_WithTransactions_ReturnsCategoryCounts() async throws {
        // Arrange
        let merchant = "Test Store"
        let transactions = [
            createTestTransaction(merchant: merchant, category: "Food"),
            createTestTransaction(merchant: merchant, category: "Food"),
            createTestTransaction(merchant: merchant, category: "Shopping"),
        ]
        mockTransactionRepository.mockTransactions = transactions
        
        // Act
        let history = try await sut.getMerchantHistory(for: merchant)
        
        // Assert
        XCTAssertEqual(history["Food"], 2)
        XCTAssertEqual(history["Shopping"], 1)
    }
    
    func testGetMerchantHistory_WithNoTransactions_ReturnsEmpty() async throws {
        // Arrange
        let merchant = "Unknown Merchant"
        mockTransactionRepository.mockTransactions = []
        
        // Act
        let history = try await sut.getMerchantHistory(for: merchant)
        
        // Assert
        XCTAssertTrue(history.isEmpty)
    }
    
    func testGetMerchantHistory_WithNoRepository_ReturnsEmpty() async throws {
        // Arrange
        let sutWithoutRepo = CategoryService(context: context, transactionRepository: nil)
        
        // Act
        let history = try await sutWithoutRepo.getMerchantHistory(for: "Any Merchant")
        
        // Assert
        XCTAssertTrue(history.isEmpty)
    }
    
    // MARK: - Edge Cases
    
    func testCategorize_WithEmptyMerchant_ReturnsOther() async throws {
        // Arrange
        let merchant = ""
        
        // Act
        let result = try await sut.categorize(merchant: merchant, amount: 10)
        
        // Assert
        XCTAssertEqual(result.category, "Other")
    }
    
    func testCategorize_WithSpecialCharacters_NormalizesCorrectly() async throws {
        // Arrange
        let merchant = "Starbucks #1234 - Downtown!!!"
        
        // Act
        let result = try await sut.categorize(merchant: merchant, amount: 5)
        
        // Assert
        XCTAssertEqual(result.category, "Dining & Restaurants")
    }
    
    func testCategorize_CaseInsensitive() async throws {
        // Arrange
        let merchants = ["WALMART", "walmart", "WalMart", "wAlMaRt"]
        
        for merchant in merchants {
            // Act
            let result = try await sut.categorize(merchant: merchant, amount: 50)
            
            // Assert
            XCTAssertEqual(result.category, "Groceries", "Failed for merchant: \(merchant)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestTransaction(merchant: String, category: String) -> Transaction {
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.merchant = merchant
        transaction.category = category
        transaction.amount = NSDecimalNumber(decimal: 10)
        transaction.date = Date()
        return transaction
    }
}

// MARK: - Mock Transaction Repository

@MainActor
class MockTransactionRepository: TransactionRepository {
    var mockTransactions: [Transaction] = []
    var shouldThrowError = false
    
    func fetchAll() async throws -> [Transaction] {
        if shouldThrowError {
            throw RepositoryError.fetchFailed(NSError(domain: "test", code: 1))
        }
        return mockTransactions
    }
    
    func fetchById(_ id: UUID) async throws -> Transaction? {
        return mockTransactions.first { $0.id == id }
    }
    
    func save(_ entity: Transaction) async throws {
        if shouldThrowError {
            throw RepositoryError.saveFailed(NSError(domain: "test", code: 1))
        }
        mockTransactions.append(entity)
    }
    
    func delete(_ entity: Transaction) async throws {
        if shouldThrowError {
            throw RepositoryError.deleteFailed(NSError(domain: "test", code: 1))
        }
        mockTransactions.removeAll { $0.id == entity.id }
    }
    
    func fetchByDateRange(_ startDate: Date, _ endDate: Date) async throws -> [Transaction] {
        return mockTransactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return date >= startDate && date <= endDate
        }
    }
    
    func fetchByAccount(_ account: Account) async throws -> [Transaction] {
        return mockTransactions.filter { $0.account == account }
    }
    
    func fetchByCategory(_ category: String) async throws -> [Transaction] {
        return mockTransactions.filter { $0.category == category }
    }
    
    func fetchUncategorized() async throws -> [Transaction] {
        return mockTransactions.filter { $0.category == nil || $0.category == "Uncategorized" }
    }
}
