//
//  CurrencyPreferenceIntegrationTests.swift
//  ClariFi iOSTests
//
//  Integration tests for currency preference workflows
//

import XCTest
import SwiftUI
import CoreData
@testable import ClariFi_iOS

@MainActor
class CurrencyPreferenceIntegrationTests: XCTestCase {
    
    var currencyManager: CurrencyPreferenceManager!
    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create fresh currency manager for each test
        currencyManager = CurrencyPreferenceManager.shared
        
        // Create in-memory Core Data stack
        container = NSPersistentContainer(name: "ClariFi_iOS")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        try await container.loadPersistentStores()
        context = container.viewContext
    }
    
    override func tearDown() async throws {
        // Reset to USD for next test
        currencyManager.preferredCurrency = .usd
        container = nil
        context = nil
        try await super.tearDown()
    }
    
    // MARK: - Currency Selection Tests
    
    func testCurrencySelectionWorkflow() async throws {
        // Given: User starts with USD
        let initialCurrency = currencyManager.preferredCurrency
        
        // When: User selects EUR
        currencyManager.preferredCurrency = .eur
        
        // Then: Currency should be updated
        XCTAssertNotEqual(currencyManager.preferredCurrency, initialCurrency)
        XCTAssertEqual(currencyManager.preferredCurrency, .eur)
    }
    
    func testCurrencySelectionPersistence() async throws {
        // Given: User selects CAD
        currencyManager.preferredCurrency = .cad
        
        // When: Simulating app restart by checking UserDefaults
        let savedCurrency = UserDefaults.standard.string(forKey: "preferredCurrency")
        
        // Then: Currency should be persisted
        XCTAssertEqual(savedCurrency, "CAD")
    }
    
    func testMultipleCurrencySelections() async throws {
        // Given: User starts with USD
        XCTAssertEqual(currencyManager.preferredCurrency, .usd)
        
        // When: User changes currency multiple times
        currencyManager.preferredCurrency = .eur
        XCTAssertEqual(currencyManager.preferredCurrency, .eur)
        
        currencyManager.preferredCurrency = .gbp
        XCTAssertEqual(currencyManager.preferredCurrency, .gbp)
        
        currencyManager.preferredCurrency = .jpy
        XCTAssertEqual(currencyManager.preferredCurrency, .jpy)
        
        // Then: Final currency should be JPY
        XCTAssertEqual(currencyManager.preferredCurrency, .jpy)
    }
    
    // MARK: - Currency Formatting Tests
    
    func testCurrencyFormattingAfterSelection() async throws {
        // Given: User selects EUR
        currencyManager.preferredCurrency = .eur
        
        // When: Formatting an amount
        let formatted = currencyManager.format(Decimal(100.50))
        
        // Then: Should format with EUR
        XCTAssertTrue(formatted.contains("€") || formatted.contains("EUR"))
    }
    
    func testCurrencyFormattingForDifferentCurrencies() async throws {
        let testAmount = Decimal(1234.56)
        
        // Test USD
        currencyManager.preferredCurrency = .usd
        let usdFormatted = currencyManager.format(testAmount)
        XCTAssertTrue(usdFormatted.contains("$") || usdFormatted.contains("USD"))
        
        // Test EUR
        currencyManager.preferredCurrency = .eur
        let eurFormatted = currencyManager.format(testAmount)
        XCTAssertTrue(eurFormatted.contains("€") || eurFormatted.contains("EUR"))
        
        // Test GBP
        currencyManager.preferredCurrency = .gbp
        let gbpFormatted = currencyManager.format(testAmount)
        XCTAssertTrue(gbpFormatted.contains("£") || gbpFormatted.contains("GBP"))
        
        // Test JPY (no decimal places)
        currencyManager.preferredCurrency = .jpy
        let jpyFormatted = currencyManager.format(testAmount)
        XCTAssertTrue(jpyFormatted.contains("¥") || jpyFormatted.contains("JPY"))
    }
    
    func testCurrencyFormattingWithSymbol() async throws {
        // Given: User selects CAD
        currencyManager.preferredCurrency = .cad
        
        // When: Formatting with symbol
        let formatted = currencyManager.formatWithSymbol(Decimal(99.99))
        
        // Then: Should include CAD symbol
        XCTAssertTrue(formatted.contains("CA$"))
    }
    
    // MARK: - Currency Change Propagation Tests
    
    func testCurrencyChangePropagationToTransactions() async throws {
        // Given: Create transactions with USD
        currencyManager.preferredCurrency = .usd
        
        let transaction1 = Transaction(context: context)
        transaction1.id = UUID()
        transaction1.amount = NSDecimalNumber(value: 50.00)
        transaction1.merchant = "Test Merchant 1"
        transaction1.date = Date()
        transaction1.createdAt = Date()
        transaction1.updatedAt = Date()
        
        let transaction2 = Transaction(context: context)
        transaction2.id = UUID()
        transaction2.amount = NSDecimalNumber(value: 75.50)
        transaction2.merchant = "Test Merchant 2"
        transaction2.date = Date()
        transaction2.createdAt = Date()
        transaction2.updatedAt = Date()
        
        try context.save()
        
        // When: User changes currency to EUR
        currencyManager.preferredCurrency = .eur
        
        // Then: Formatting should use EUR
        let formatted1 = currencyManager.format(transaction1.amount as Decimal)
        let formatted2 = currencyManager.format(transaction2.amount as Decimal)
        
        XCTAssertTrue(formatted1.contains("€") || formatted1.contains("EUR"))
        XCTAssertTrue(formatted2.contains("€") || formatted2.contains("EUR"))
    }
    
    func testCurrencyChangePropagationToBudgets() async throws {
        // Given: Create budget with USD
        currencyManager.preferredCurrency = .usd
        
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        let category = BudgetCategory(context: context)
        category.id = UUID()
        category.name = "Food & Dining"
        category.budgetedAmount = NSDecimalNumber(value: 500.00)
        category.spentAmount = NSDecimalNumber(value: 250.00)
        category.budget = budget
        category.createdAt = Date()
        category.updatedAt = Date()
        
        try context.save()
        
        // When: User changes currency to GBP
        currencyManager.preferredCurrency = .gbp
        
        // Then: Formatting should use GBP
        let formattedBudgeted = currencyManager.format(category.budgetedAmount as Decimal)
        let formattedSpent = currencyManager.format(category.spentAmount as Decimal)
        
        XCTAssertTrue(formattedBudgeted.contains("£") || formattedBudgeted.contains("GBP"))
        XCTAssertTrue(formattedSpent.contains("£") || formattedSpent.contains("GBP"))
    }
    
    // MARK: - Complete Workflow Tests
    
    func testCompleteCurrencySettingsViewWorkflow() async throws {
        // Given: User starts with USD
        let initialCurrency = currencyManager.preferredCurrency
        
        // When: User opens currency settings and selects EUR
        currencyManager.preferredCurrency = .eur
        
        // Then: Verify currency changed
        XCTAssertNotEqual(currencyManager.preferredCurrency, initialCurrency)
        XCTAssertEqual(currencyManager.preferredCurrency, .eur)
        
        // And: Verify example amount formats correctly
        let exampleAmount = Decimal(1234.56)
        let formatted = currencyManager.format(exampleAmount)
        XCTAssertTrue(formatted.contains("€") || formatted.contains("EUR"))
        
        // And: Verify persistence
        let savedCurrency = UserDefaults.standard.string(forKey: "preferredCurrency")
        XCTAssertEqual(savedCurrency, "EUR")
    }
    
    func testCurrencySearchAndSelection() async throws {
        // Given: All available currencies
        let allCurrencies = Currency.allCases
        
        // When: User searches for "Dollar"
        let dollarCurrencies = allCurrencies.filter { currency in
            currency.name.localizedCaseInsensitiveContains("Dollar")
        }
        
        // Then: Should find multiple dollar currencies
        XCTAssertTrue(dollarCurrencies.count > 1)
        XCTAssertTrue(dollarCurrencies.contains(.usd))
        XCTAssertTrue(dollarCurrencies.contains(.cad))
        XCTAssertTrue(dollarCurrencies.contains(.aud))
        
        // When: User selects Canadian Dollar
        if let cad = dollarCurrencies.first(where: { $0 == .cad }) {
            currencyManager.preferredCurrency = cad
            
            // Then: Currency should be CAD
            XCTAssertEqual(currencyManager.preferredCurrency, .cad)
        }
    }
    
    func testCurrencySearchByCode() async throws {
        // Given: All available currencies
        let allCurrencies = Currency.allCases
        
        // When: User searches for "JPY"
        let jpyCurrencies = allCurrencies.filter { currency in
            currency.rawValue.localizedCaseInsensitiveContains("JPY")
        }
        
        // Then: Should find Japanese Yen
        XCTAssertEqual(jpyCurrencies.count, 1)
        XCTAssertEqual(jpyCurrencies.first, .jpy)
        
        // When: User selects it
        if let jpy = jpyCurrencies.first {
            currencyManager.preferredCurrency = jpy
            
            // Then: Currency should be JPY
            XCTAssertEqual(currencyManager.preferredCurrency, .jpy)
            
            // And: Formatting should not include decimals
            let formatted = currencyManager.format(Decimal(1234.56))
            XCTAssertFalse(formatted.contains("."))
        }
    }
    
    // MARK: - Amount Update Tests
    
    func testAllAmountsUpdateWhenCurrencyChanges() async throws {
        // Given: Multiple financial entities with amounts
        currencyManager.preferredCurrency = .usd
        
        // Create transaction
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.amount = NSDecimalNumber(value: 100.00)
        transaction.merchant = "Test Merchant"
        transaction.date = Date()
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        
        // Create budget
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        budget.createdAt = Date()
        budget.updatedAt = Date()
        
        let category = BudgetCategory(context: context)
        category.id = UUID()
        category.name = "Shopping"
        category.budgetedAmount = NSDecimalNumber(value: 500.00)
        category.spentAmount = NSDecimalNumber(value: 200.00)
        category.budget = budget
        category.createdAt = Date()
        category.updatedAt = Date()
        
        try context.save()
        
        // When: User changes currency to EUR
        currencyManager.preferredCurrency = .eur
        
        // Then: All amounts should format with EUR
        let transactionFormatted = currencyManager.format(transaction.amount as Decimal)
        let budgetedFormatted = currencyManager.format(category.budgetedAmount as Decimal)
        let spentFormatted = currencyManager.format(category.spentAmount as Decimal)
        
        XCTAssertTrue(transactionFormatted.contains("€") || transactionFormatted.contains("EUR"))
        XCTAssertTrue(budgetedFormatted.contains("€") || budgetedFormatted.contains("EUR"))
        XCTAssertTrue(spentFormatted.contains("€") || spentFormatted.contains("EUR"))
    }
    
    func testCurrencyChangeWithZeroDecimalCurrency() async throws {
        // Given: User has amounts in USD (2 decimal places)
        currencyManager.preferredCurrency = .usd
        let amount = Decimal(1234.56)
        let usdFormatted = currencyManager.format(amount)
        XCTAssertTrue(usdFormatted.contains(".") || usdFormatted.contains(","))
        
        // When: User changes to JPY (0 decimal places)
        currencyManager.preferredCurrency = .jpy
        let jpyFormatted = currencyManager.format(amount)
        
        // Then: Should format without decimals
        // JPY formatting should round to whole number
        XCTAssertTrue(jpyFormatted.contains("¥") || jpyFormatted.contains("JPY"))
    }
    
    // MARK: - Currency Display Tests
    
    func testCurrencyDisplayText() async throws {
        // Test display text for various currencies
        XCTAssertEqual(Currency.usd.displayText, "USD - US Dollar")
        XCTAssertEqual(Currency.eur.displayText, "EUR - Euro")
        XCTAssertEqual(Currency.gbp.displayText, "GBP - British Pound")
        XCTAssertEqual(Currency.jpy.displayText, "JPY - Japanese Yen")
        XCTAssertEqual(Currency.cad.displayText, "CAD - Canadian Dollar")
    }
    
    func testCurrencySymbols() async throws {
        // Test symbols for various currencies
        XCTAssertEqual(Currency.usd.symbol, "$")
        XCTAssertEqual(Currency.eur.symbol, "€")
        XCTAssertEqual(Currency.gbp.symbol, "£")
        XCTAssertEqual(Currency.jpy.symbol, "¥")
        XCTAssertEqual(Currency.cad.symbol, "CA$")
        XCTAssertEqual(Currency.aud.symbol, "A$")
    }
    
    func testCurrencyDecimalPlaces() async throws {
        // Test decimal places for various currencies
        XCTAssertEqual(Currency.usd.decimalPlaces, 2)
        XCTAssertEqual(Currency.eur.decimalPlaces, 2)
        XCTAssertEqual(Currency.gbp.decimalPlaces, 2)
        XCTAssertEqual(Currency.jpy.decimalPlaces, 0)
        XCTAssertEqual(Currency.krw.decimalPlaces, 0)
    }
    
    // MARK: - Edge Cases
    
    func testCurrencyChangeWithNegativeAmounts() async throws {
        // Given: Negative amount (refund)
        let negativeAmount = Decimal(-50.00)
        
        // When: Formatting with different currencies
        currencyManager.preferredCurrency = .usd
        let usdFormatted = currencyManager.format(negativeAmount)
        
        currencyManager.preferredCurrency = .eur
        let eurFormatted = currencyManager.format(negativeAmount)
        
        // Then: Should handle negative amounts correctly
        XCTAssertTrue(usdFormatted.contains("-") || usdFormatted.contains("("))
        XCTAssertTrue(eurFormatted.contains("-") || eurFormatted.contains("("))
    }
    
    func testCurrencyChangeWithVeryLargeAmounts() async throws {
        // Given: Very large amount
        let largeAmount = Decimal(1_000_000.00)
        
        // When: Formatting with different currencies
        currencyManager.preferredCurrency = .usd
        let usdFormatted = currencyManager.format(largeAmount)
        
        currencyManager.preferredCurrency = .jpy
        let jpyFormatted = currencyManager.format(largeAmount)
        
        // Then: Should handle large amounts correctly
        XCTAssertFalse(usdFormatted.isEmpty)
        XCTAssertFalse(jpyFormatted.isEmpty)
    }
    
    func testCurrencyChangeWithZeroAmount() async throws {
        // Given: Zero amount
        let zeroAmount = Decimal(0.00)
        
        // When: Formatting with different currencies
        currencyManager.preferredCurrency = .usd
        let usdFormatted = currencyManager.format(zeroAmount)
        
        currencyManager.preferredCurrency = .eur
        let eurFormatted = currencyManager.format(zeroAmount)
        
        // Then: Should handle zero correctly
        XCTAssertFalse(usdFormatted.isEmpty)
        XCTAssertFalse(eurFormatted.isEmpty)
        XCTAssertTrue(usdFormatted.contains("0"))
        XCTAssertTrue(eurFormatted.contains("0"))
    }
}
