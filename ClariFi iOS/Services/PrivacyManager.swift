//
//  PrivacyManager.swift
//  ClariFi iOS
//
//  Privacy management service for data control and transparency
//

import Foundation
import CoreData

enum ProcessingMode: String, Codable {
    case localOnly
    case cloudOptIn
    
    var displayName: String {
        switch self {
        case .localOnly: return "Local-Only Processing"
        case .cloudOptIn: return "Cloud Processing (Opt-In)"
        }
    }
    
    var description: String {
        switch self {
        case .localOnly:
            return "All data processing happens on your device. No data is sent to external servers."
        case .cloudOptIn:
            return "Enhanced features use encrypted cloud processing. Data is end-to-end encrypted and automatically deleted after processing."
        }
    }
}

struct DataSummary {
    let totalTransactions: Int
    let totalStatements: Int
    let totalBudgets: Int
    let storageSize: Int64
    let oldestTransaction: Date?
    let newestTransaction: Date?
    
    var formattedStorageSize: String {
        ByteCountFormatter.string(fromByteCount: storageSize, countStyle: .file)
    }
    
    var dateRange: String {
        guard let oldest = oldestTransaction, let newest = newestTransaction else {
            return "No data"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: oldest)) - \(formatter.string(from: newest))"
    }
}

struct FeatureConsent: Codable {
    var insightsEnabled: Bool = true
    var notificationsEnabled: Bool = false
    var budgetAlertsEnabled: Bool = true
    var categoryLearningEnabled: Bool = true
}

protocol PrivacyManagerProtocol {
    var processingMode: ProcessingMode { get set }
    var featureConsent: FeatureConsent { get set }
    
    func getDataSummary() async throws -> DataSummary
    func exportUserData() async throws -> URL
    func deleteAllUserData() async throws
}

class PrivacyManager: ObservableObject, PrivacyManagerProtocol {
    @Published var processingMode: ProcessingMode {
        didSet {
            saveProcessingMode()
        }
    }
    
    @Published var featureConsent: FeatureConsent {
        didSet {
            saveFeatureConsent()
        }
    }
    
    private let viewContext: NSManagedObjectContext
    private let userDefaults = UserDefaults.standard
    
    private let processingModeKey = "processingMode"
    private let featureConsentKey = "featureConsent"
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        
        // Load saved processing mode
        if let savedMode = userDefaults.string(forKey: processingModeKey),
           let mode = ProcessingMode(rawValue: savedMode) {
            self.processingMode = mode
        } else {
            self.processingMode = .localOnly // Default to local-only
        }
        
        // Load saved feature consent
        if let savedConsent = userDefaults.data(forKey: featureConsentKey),
           let consent = try? JSONDecoder().decode(FeatureConsent.self, from: savedConsent) {
            self.featureConsent = consent
        } else {
            self.featureConsent = FeatureConsent()
        }
    }
    
    private func saveProcessingMode() {
        userDefaults.set(processingMode.rawValue, forKey: processingModeKey)
    }
    
    private func saveFeatureConsent() {
        if let encoded = try? JSONEncoder().encode(featureConsent) {
            userDefaults.set(encoded, forKey: featureConsentKey)
        }
    }
    
    func getDataSummary() async throws -> DataSummary {
        return try await viewContext.perform {
            // Count transactions
            let transactionFetch = NSFetchRequest<Transaction>(entityName: "Transaction")
            let transactionCount = try self.viewContext.count(for: transactionFetch)
            
            // Count statements
            let statementFetch = NSFetchRequest<Statement>(entityName: "Statement")
            let statementCount = try self.viewContext.count(for: statementFetch)
            
            // Count budgets
            let budgetFetch = NSFetchRequest<Budget>(entityName: "Budget")
            let budgetCount = try self.viewContext.count(for: budgetFetch)
            
            // Get date range
            let dateFetch = NSFetchRequest<Transaction>(entityName: "Transaction")
            dateFetch.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: true)]
            dateFetch.fetchLimit = 1
            let oldestTransactions = try self.viewContext.fetch(dateFetch)
            let oldestDate = oldestTransactions.first?.date
            
            dateFetch.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
            let newestTransactions = try self.viewContext.fetch(dateFetch)
            let newestDate = newestTransactions.first?.date
            
            // Calculate storage size (approximate)
            let storageSize = self.calculateStorageSize()
            
            return DataSummary(
                totalTransactions: transactionCount,
                totalStatements: statementCount,
                totalBudgets: budgetCount,
                storageSize: storageSize,
                oldestTransaction: oldestDate,
                newestTransaction: newestDate
            )
        }
    }
    
    func exportUserData() async throws -> URL {
        return try await viewContext.perform {
            // Fetch all data
            let transactions = try self.fetchAllTransactions()
            let budgets = try self.fetchAllBudgets()
            let statements = try self.fetchAllStatements()
            
            // Create export data structure
            let exportData: [String: Any] = [
                "exportDate": ISO8601DateFormatter().string(from: Date()),
                "processingMode": self.processingMode.rawValue,
                "featureConsent": [
                    "insightsEnabled": self.featureConsent.insightsEnabled,
                    "notificationsEnabled": self.featureConsent.notificationsEnabled,
                    "budgetAlertsEnabled": self.featureConsent.budgetAlertsEnabled,
                    "categoryLearningEnabled": self.featureConsent.categoryLearningEnabled
                ],
                "transactions": transactions.map { self.transactionToDict($0) },
                "budgets": budgets.map { self.budgetToDict($0) },
                "statements": statements.map { self.statementToDict($0) }
            ]
            
            // Convert to JSON
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            
            // Save to temporary file
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "ClariFi_Export_\(Date().timeIntervalSince1970).json"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try jsonData.write(to: fileURL)
            
            return fileURL
        }
    }
    
    func deleteAllUserData() async throws {
        try await viewContext.perform {
            // Delete all transactions
            let transactionFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Transaction")
            let transactionDelete = NSBatchDeleteRequest(fetchRequest: transactionFetch)
            try self.viewContext.execute(transactionDelete)
            
            // Delete all statements
            let statementFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Statement")
            let statementDelete = NSBatchDeleteRequest(fetchRequest: statementFetch)
            try self.viewContext.execute(statementDelete)
            
            // Delete all budgets
            let budgetFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Budget")
            let budgetDelete = NSBatchDeleteRequest(fetchRequest: budgetFetch)
            try self.viewContext.execute(budgetDelete)
            
            // Delete all budget categories
            let categoryFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "BudgetCategory")
            let categoryDelete = NSBatchDeleteRequest(fetchRequest: categoryFetch)
            try self.viewContext.execute(categoryDelete)
            
            // Delete all accounts
            let accountFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Account")
            let accountDelete = NSBatchDeleteRequest(fetchRequest: accountFetch)
            try self.viewContext.execute(accountDelete)
            
            // Delete all recurring transactions
            let recurringFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "RecurringTransaction")
            let recurringDelete = NSBatchDeleteRequest(fetchRequest: recurringFetch)
            try self.viewContext.execute(recurringDelete)
            
            // Delete all categorization rules
            let ruleFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "CategorizationRule")
            let ruleDelete = NSBatchDeleteRequest(fetchRequest: ruleFetch)
            try self.viewContext.execute(ruleDelete)
            
            // Save context
            try self.viewContext.save()
            
            // Reset user defaults
            self.userDefaults.removeObject(forKey: self.processingModeKey)
            self.userDefaults.removeObject(forKey: self.featureConsentKey)
            
            // Reset to defaults
            self.processingMode = .localOnly
            self.featureConsent = FeatureConsent()
        }
    }
    
    // MARK: - Private Helpers
    
    private func calculateStorageSize() -> Int64 {
        guard let storeURL = viewContext.persistentStoreCoordinator?.persistentStores.first?.url else {
            return 0
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: storeURL.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    private func fetchAllTransactions() throws -> [Transaction] {
        let fetch = NSFetchRequest<Transaction>(entityName: "Transaction")
        fetch.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        return try viewContext.fetch(fetch)
    }
    
    private func fetchAllBudgets() throws -> [Budget] {
        let fetch = NSFetchRequest<Budget>(entityName: "Budget")
        return try viewContext.fetch(fetch)
    }
    
    private func fetchAllStatements() throws -> [Statement] {
        let fetch = NSFetchRequest<Statement>(entityName: "Statement")
        return try viewContext.fetch(fetch)
    }
    
    private func transactionToDict(_ transaction: Transaction) -> [String: Any] {
        var dict: [String: Any] = [
            "id": transaction.id?.uuidString ?? "",
            "date": ISO8601DateFormatter().string(from: transaction.date ?? Date()),
            "merchant": transaction.merchant ?? "",
            "amount": NSDecimalNumber(decimal: transaction.amount?.decimalValue ?? 0).doubleValue,
            "category": transaction.category ?? "",
            "isManual": transaction.isManual,
            "confidence": transaction.confidence
        ]
        
        if let notes = transaction.notes {
            dict["notes"] = notes
        }
        
        return dict
    }
    
    private func budgetToDict(_ budget: Budget) -> [String: Any] {
        return [
            "id": budget.id?.uuidString ?? "",
            "name": budget.name ?? "",
            "period": budget.period ?? "",
            "startDate": ISO8601DateFormatter().string(from: budget.startDate ?? Date()),
            "categories": (budget.categories as? Set<BudgetCategory>)?.map { category in
                [
                    "name": category.name ?? "",
                    "budgetedAmount": NSDecimalNumber(decimal: category.budgetedAmount?.decimalValue ?? 0).doubleValue,
                    "alertThreshold": category.alertThreshold
                ]
            } ?? []
        ]
    }
    
    private func statementToDict(_ statement: Statement) -> [String: Any] {
        return [
            "id": statement.id?.uuidString ?? "",
            "fileName": statement.fileName ?? "",
            "uploadDate": ISO8601DateFormatter().string(from: statement.uploadDate ?? Date()),
            "processingStatus": statement.processingStatus ?? ""
        ]
    }
    
    // MARK: - Temporary File Management
    
    func cleanupTemporaryFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: tempDir,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            // Delete ClariFi export files older than 24 hours
            let cutoffDate = Date().addingTimeInterval(-24 * 60 * 60)
            
            for fileURL in contents {
                guard fileURL.lastPathComponent.hasPrefix("ClariFi_Export_") else { continue }
                
                if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   creationDate < cutoffDate {
                    try? FileManager.default.removeItem(at: fileURL)
                }
            }
        } catch {
            // Silently fail - cleanup is best effort
        }
    }
}
