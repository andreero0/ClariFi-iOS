//
//  ClariFiAppIntents.swift
//  ClariFi iOS
//
//  Modern AppIntents integration for iOS 19+
//
//  NOTE: This implementation currently returns placeholder data only.
//  Full integration with Core Data and DI container is coming soon.
//

import Foundation
import AppIntents
import CoreData
import CoreSpotlight

// MARK: - Transaction Entity for AppIntents
struct TransactionEntity: AppEntity, IndexedEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Transaction"
    )
    
    var id: String
    var amount: Decimal
    var merchant: String
    var date: Date
    var category: String?
    
    var displayRepresentation: DisplayRepresentation {
        // NOTE: Hardcoded USD - should use user's currency preference
        DisplayRepresentation(
            title: "\(merchant)",
            subtitle: "\(amount.formatted(.currency(code: "USD"))) • \(date.formatted(date: .abbreviated, time: .omitted))",
            image: .init(systemName: "creditcard")
        )
    }
    
    static var defaultQuery: TransactionQuery = TransactionQuery()
    
    var searchableAttributes: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet()
        attributes.title = merchant
        attributes.contentDescription = "Transaction for \(amount.formatted(.currency(code: "USD")))"
        attributes.keywords = [category ?? "Uncategorized", "Transaction"]
        attributes.contentCreationDate = date
        return attributes
    }
    
    struct TransactionQuery: EntityQuery {
        func entities(for identifiers: [String]) async throws -> [TransactionEntity] {
            // TODO: Integrate with DI container and TransactionRepository
            // let container = AppDIContainer.shared
            // let repository = container.resolve(TransactionRepository.self)
            // return await repository.fetchByIds(identifiers)
            return []
        }
        
        func suggestedEntities() async throws -> [TransactionEntity] {
            // TODO: Integrate with DI container and TransactionRepository
            // let container = AppDIContainer.shared
            // let repository = container.resolve(TransactionRepository.self)
            // return await repository.fetchRecent(limit: 5)
            return []
        }
    }
}

// MARK: - Find Recent Transactions Intent
struct FindRecentTransactionsIntent: AppIntent {
    static let title: LocalizedStringResource = "Find Recent Transactions"
    static let description = IntentDescription("Find your recent financial transactions")
    
    @Parameter(title: "Days", description: "Number of days to look back", default: 7)
    var days: Int
    
    func perform() async throws -> some ReturnsValue<[TransactionEntity]> & ProvidesDialog {
        // TODO: Integrate with DI container and TransactionRepository
        // let container = AppDIContainer.shared
        // let repository = container.resolve(TransactionRepository.self)
        // let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        // let transactions = await repository.fetchTransactions(from: startDate, to: Date())
        // let entities = transactions.map { TransactionEntity(from: $0) }
        
        // PLACEHOLDER: Return sample data until full implementation
        let sampleTransactions = [
            TransactionEntity(
                id: "sample-1",
                amount: 25.99,
                merchant: "Sample Transaction",
                date: Date().addingTimeInterval(-86400),
                category: "Food & Dining"
            ),
            TransactionEntity(
                id: "sample-2", 
                amount: 150.00,
                merchant: "Sample Transaction",
                date: Date().addingTimeInterval(-172800),
                category: "Transportation"
            )
        ]
        
        return .result(
            value: sampleTransactions,
            dialog: "Preview: Found \(sampleTransactions.count) sample transactions. Full functionality coming soon."
        )
    }
}

// MARK: - Add Transaction Intent
struct AddTransactionIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Transaction"
    static let description = IntentDescription("Add a new financial transaction")
    
    @Parameter(title: "Amount", description: "Transaction amount")
    var amount: Double
    
    @Parameter(title: "Merchant", description: "Merchant name")
    var merchant: String
    
    @Parameter(title: "Category", description: "Transaction category")
    var category: String?
    
    func perform() async throws -> some ReturnsValue<TransactionEntity> & ProvidesDialog {
        // TODO: Integrate with DI container and TransactionRepository
        // TODO: Add premium gating if required
        // let container = AppDIContainer.shared
        // let subscriptionService = container.resolve(SubscriptionService.self)
        // guard await subscriptionService.hasActiveSubscription else {
        //     throw IntentError.message("Premium subscription required")
        // }
        // let repository = container.resolve(TransactionRepository.self)
        // let transaction = Transaction(amount: Decimal(amount), merchant: merchant, ...)
        // await repository.save(transaction)
        
        // PLACEHOLDER: Create entity but don't save to Core Data
        let transaction = TransactionEntity(
            id: UUID().uuidString,
            amount: Decimal(amount),
            merchant: merchant,
            date: Date(),
            category: category ?? "Uncategorized"
        )
        
        // NOTE: Hardcoded USD - should use user's currency preference
        return .result(
            value: transaction,
            dialog: "Preview mode: Transaction not saved. Full functionality coming soon."
        )
    }
}

// MARK: - App Shortcuts Provider
struct ClariFiAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: FindRecentTransactionsIntent(),
                phrases: [
                    "Show my recent transactions in \(.applicationName)",
                    "Find transactions in \(.applicationName)"
                ],
                shortTitle: "Show Transactions",
                systemImageName: "creditcard"
            ),
            
            AppShortcut(
                intent: AddTransactionIntent(),
                phrases: [
                    "Add a transaction in \(.applicationName)",
                    "Log a purchase in \(.applicationName)"
                ],
                shortTitle: "Add Transaction",
                systemImageName: "plus.circle"
            )
        ]
    }
}

// MARK: - App Intents Package
struct ClariFiAppIntentsPackage: AppIntentsPackage {
    // This package will be automatically discovered by the system
}
