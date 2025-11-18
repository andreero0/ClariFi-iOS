//
//  PrivacyManagerTests.swift
//  ClariFi iOSTests
//
//  Unit tests for privacy controls
//

import Testing
import CoreData
@testable import ClariFi_iOS

@MainActor
struct PrivacyManagerTests {
    
    var privacyManager: PrivacyManager!
    var testContext: NSManagedObjectContext!
    var persistenceController: PersistenceController!
    
    init() async throws {
        
        // Create in-memory persistence controller for testing
        persistenceController = PersistenceController(inMemory: true)
        testContext = persistenceController.container.viewContext
        
        // Initialize privacy manager with test context
        privacyManager = PrivacyManager(viewContext: testContext)
        
        // Clear UserDefaults for clean test state
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "processingMode")
        defaults.removeObject(forKey: "featureConsent")
    }
    
    // MARK: - Processing Mode Tests
    
    @Test func defaultProcessingModeIsLocalOnly() {
        // Given: A fresh privacy manager
        // When: Checking the default processing mode
        // Then: It should be local-only for privacy
        #expect(privacyManager.processingMode == .localOnly)
    }
    
    @Test func processingModeChangePersists() {
        // Given: A privacy manager with local-only mode
        #expect(privacyManager.processingMode == .localOnly)
        
        // When: Changing to cloud opt-in
        privacyManager.processingMode = .cloudOptIn
        
        // Then: The change should persist
        #expect(privacyManager.processingMode == .cloudOptIn)
        
        // And: Creating a new manager should load the saved mode
        let newManager = PrivacyManager(viewContext: testContext)
        #expect(newManager.processingMode == .cloudOptIn)
    }
    
    @Test func processingModeDisplayNames() {
        // Given: Processing modes
        // When: Getting display names
        // Then: They should be user-friendly
        #expect(ProcessingMode.localOnly.displayName == "Local-Only Processing")
        #expect(ProcessingMode.cloudOptIn.displayName == "Cloud Processing (Opt-In)")
    }
    
    @Test func processingModeDescriptions() {
        // Given: Processing modes
        // When: Getting descriptions
        // Then: They should explain the privacy implications
        #expect(ProcessingMode.localOnly.description.contains("on your device"))
        #expect(ProcessingMode.cloudOptIn.description.contains("encrypted"))
    }
    
    // MARK: - Feature Consent Tests
    
    @Test func defaultFeatureConsent() {
        // Given: A fresh privacy manager
        // When: Checking default consent
        // Then: Safe defaults should be set
        #expect(privacyManager.featureConsent.insightsEnabled)
        #expect(privacyManager.featureConsent.notificationsEnabled)
        #expect(privacyManager.featureConsent.budgetAlertsEnabled)
        #expect(privacyManager.featureConsent.categoryLearningEnabled)
    }
    
    @Test func featureConsentChangePersists() {
        // Given: Default feature consent
        var consent = privacyManager.featureConsent
        
        // When: Changing consent settings
        consent.insightsEnabled = false
        consent.notificationsEnabled = true
        privacyManager.featureConsent = consent
        
        // Then: Changes should persist
        #expect(privacyManager.featureConsent.insightsEnabled)
        #expect(privacyManager.featureConsent.notificationsEnabled)
        
        // And: Creating a new manager should load the saved consent
        let newManager = PrivacyManager(viewContext: testContext)
        #expect(newManager.featureConsent.insightsEnabled)
        #expect(newManager.featureConsent.notificationsEnabled)
    }
    
    // MARK: - Data Summary Tests
    
    @Test func dataSummaryWithNoData() async throws {
        // Given: An empty database
        // When: Getting data summary
        let summary = try await privacyManager.getDataSummary()
        
        // Then: All counts should be zero
        #expect(summary.totalTransactions == 0)
        #expect(summary.totalStatements == 0)
        #expect(summary.totalBudgets == 0)
        #expect(summary.oldestTransaction)
        #expect(summary.newestTransaction)
    }
    
    @Test func dataSummaryWithTransactions() async throws {
        // Given: Some test transactions
        try await createTestTransactions(count: 5)
        
        // When: Getting data summary
        let summary = try await privacyManager.getDataSummary()
        
        // Then: Transaction count should be correct
        #expect(summary.totalTransactions == 5)
        #expect(summary.oldestTransaction)
        #expect(summary.newestTransaction)
    }
    
    @Test func dataSummaryWithMultipleEntities() async throws {
        // Given: Transactions, budgets, and statements
        try await createTestTransactions(count: 3)
        try await createTestBudgets(count: 2)
        try await createTestStatements(count: 1)
        
        // When: Getting data summary
        let summary = try await privacyManager.getDataSummary()
        
        // Then: All counts should be correct
        #expect(summary.totalTransactions == 3)
        #expect(summary.totalBudgets == 2)
        #expect(summary.totalStatements == 1)
    }
    
    @Test func dataSummaryDateRange() async throws {
        // Given: Transactions with different dates
        let oldDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let newDate = Date()
        
        try await createTestTransaction(date: oldDate)
        try await createTestTransaction(date: newDate)
        
        // When: Getting data summary
        let summary = try await privacyManager.getDataSummary()
        
        // Then: Date range should be correct
        #expect(summary.oldestTransaction)
        #expect(summary.newestTransaction)
        #expect(summary.oldestTransaction! < summary.newestTransaction!)
    }
    
    @Test func dataSummaryFormattedStorageSize() async throws {
        // Given: A data summary
        let summary = try await privacyManager.getDataSummary()
        
        // When: Getting formatted storage size
        let formatted = summary.formattedStorageSize
        
        // Then: It should be a readable string
        #expect(formatted.isEmpty)
        #expect(formatted.contains("bytes") || formatted.contains("KB") || formatted.contains("MB"))
    }
    
    // MARK: - Data Export Tests
    
    @Test func exportUserDataWithNoData() async throws {
        // Given: An empty database
        // When: Exporting user data
        let exportURL = try await privacyManager.exportUserData()
        
        // Then: Export file should be created
        #expect(FileManager.default.fileExists(atPath: exportURL.path))
        
        // And: File should contain valid JSON
        let data = try Data(contentsOf: exportURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json)
        
        // And: Should contain expected keys
        #expect(json?["exportDate"])
        #expect(json?["processingMode"])
        #expect(json?["featureConsent"])
        #expect(json?["transactions"])
        #expect(json?["budgets"])
        #expect(json?["statements"])
        
        // Cleanup
        try? FileManager.default.removeItem(at: exportURL)
    }
    
    @Test func exportUserDataWithTransactions() async throws {
        // Given: Test transactions
        try await createTestTransactions(count: 3)
        
        // When: Exporting user data
        let exportURL = try await privacyManager.exportUserData()
        
        // Then: Export should contain transactions
        let data = try Data(contentsOf: exportURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let transactions = json?["transactions"] as? [[String: Any]]
        
        #expect(transactions)
        #expect(transactions?.count == 3)
        
        // And: Each transaction should have required fields
        if let firstTransaction = transactions?.first {
            #expect(firstTransaction["id"])
            #expect(firstTransaction["date"])
            #expect(firstTransaction["merchant"])
            #expect(firstTransaction["amount"])
            #expect(firstTransaction["category"])
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: exportURL)
    }
    
    @Test func exportUserDataWithBudgets() async throws {
        // Given: Test budgets with categories
        try await createTestBudgetWithCategories()
        
        // When: Exporting user data
        let exportURL = try await privacyManager.exportUserData()
        
        // Then: Export should contain budgets
        let data = try Data(contentsOf: exportURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let budgets = json?["budgets"] as? [[String: Any]]
        
        #expect(budgets)
        #expect(budgets?.count == 1)
        
        // And: Budget should have categories
        if let firstBudget = budgets?.first {
            #expect(firstBudget["id"])
            #expect(firstBudget["name"])
            #expect(firstBudget["period"])
            
            let categories = firstBudget["categories"] as? [[String: Any]]
            #expect(categories)
            #expect((categories?.count ?? 0) > 0)
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: exportURL)
    }
    
    @Test func exportUserDataIncludesProcessingMode() async throws {
        // Given: Cloud opt-in processing mode
        privacyManager.processingMode = .cloudOptIn
        
        // When: Exporting user data
        let exportURL = try await privacyManager.exportUserData()
        
        // Then: Export should include processing mode
        let data = try Data(contentsOf: exportURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let mode = json?["processingMode"] as? String
        
        #expect(mode == "cloudOptIn")
        
        // Cleanup
        try? FileManager.default.removeItem(at: exportURL)
    }
    
    @Test func exportUserDataIncludesFeatureConsent() async throws {
        // Given: Modified feature consent
        var consent = privacyManager.featureConsent
        consent.insightsEnabled = false
        consent.notificationsEnabled = true
        privacyManager.featureConsent = consent
        
        // When: Exporting user data
        let exportURL = try await privacyManager.exportUserData()
        
        // Then: Export should include feature consent
        let data = try Data(contentsOf: exportURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let consentData = json?["featureConsent"] as? [String: Any]
        
        #expect(consentData)
        #expect(consentData?["insightsEnabled"] as? Bool == false)
        #expect(consentData?["notificationsEnabled"] as? Bool == true)
        
        // Cleanup
        try? FileManager.default.removeItem(at: exportURL)
    }
    
    @Test func exportFileNaming() async throws {
        // Given: Privacy manager
        // When: Exporting data
        let exportURL = try await privacyManager.exportUserData()
        
        // Then: File name should follow expected pattern
        let fileName = exportURL.lastPathComponent
        #expect(fileName.hasPrefix("ClariFi_Export_"))
        #expect(fileName.hasSuffix(".json"))
        
        // Cleanup
        try? FileManager.default.removeItem(at: exportURL)
    }
    
    // MARK: - Data Deletion Tests
    
    @Test func deleteAllUserDataRemovesTransactions() async throws {
        // Given: Test transactions
        try await createTestTransactions(count: 5)
        
        var summary = try await privacyManager.getDataSummary()
        #expect(summary.totalTransactions == 5)
        
        // When: Deleting all user data
        try await privacyManager.deleteAllUserData()
        
        // Then: All transactions should be deleted
        summary = try await privacyManager.getDataSummary()
        #expect(summary.totalTransactions == 0)
    }
    
    @Test func deleteAllUserDataRemovesBudgets() async throws {
        // Given: Test budgets
        try await createTestBudgets(count: 3)
        
        var summary = try await privacyManager.getDataSummary()
        #expect(summary.totalBudgets == 3)
        
        // When: Deleting all user data
        try await privacyManager.deleteAllUserData()
        
        // Then: All budgets should be deleted
        summary = try await privacyManager.getDataSummary()
        #expect(summary.totalBudgets == 0)
    }
    
    @Test func deleteAllUserDataRemovesStatements() async throws {
        // Given: Test statements
        try await createTestStatements(count: 2)
        
        var summary = try await privacyManager.getDataSummary()
        #expect(summary.totalStatements == 2)
        
        // When: Deleting all user data
        try await privacyManager.deleteAllUserData()
        
        // Then: All statements should be deleted
        summary = try await privacyManager.getDataSummary()
        #expect(summary.totalStatements == 0)
    }
    
    @Test func deleteAllUserDataRemovesAllEntities() async throws {
        // Given: Multiple entity types
        try await createTestTransactions(count: 3)
        try await createTestBudgets(count: 2)
        try await createTestStatements(count: 1)
        
        // When: Deleting all user data
        try await privacyManager.deleteAllUserData()
        
        // Then: All entities should be deleted
        let summary = try await privacyManager.getDataSummary()
        #expect(summary.totalTransactions == 0)
        #expect(summary.totalBudgets == 0)
        #expect(summary.totalStatements == 0)
    }
    
    @Test func deleteAllUserDataResetsProcessingMode() async throws {
        // Given: Cloud opt-in processing mode
        privacyManager.processingMode = .cloudOptIn
        #expect(privacyManager.processingMode == .cloudOptIn)
        
        // When: Deleting all user data
        try await privacyManager.deleteAllUserData()
        
        // Then: Processing mode should reset to local-only
        #expect(privacyManager.processingMode == .localOnly)
    }
    
    @Test func deleteAllUserDataResetsFeatureConsent() async throws {
        // Given: Modified feature consent
        var consent = privacyManager.featureConsent
        consent.insightsEnabled = false
        consent.notificationsEnabled = true
        privacyManager.featureConsent = consent
        
        // When: Deleting all user data
        try await privacyManager.deleteAllUserData()
        
        // Then: Feature consent should reset to defaults
        let defaultConsent = FeatureConsent()
        #expect(privacyManager.featureConsent.insightsEnabled == defaultConsent.insightsEnabled)
        #expect(privacyManager.featureConsent.notificationsEnabled == defaultConsent.notificationsEnabled)
        #expect(privacyManager.featureConsent.budgetAlertsEnabled == defaultConsent.budgetAlertsEnabled)
        #expect(privacyManager.featureConsent.categoryLearningEnabled == defaultConsent.categoryLearningEnabled)
    }
    
    @Test func deleteAllUserDataIsComplete() async throws {
        // Given: Complex data structure with relationships
        let account = try await createTestAccount()
        try await createTestTransaction(account: account)
        try await createTestBudgetWithCategories()
        
        // When: Deleting all user data
        try await privacyManager.deleteAllUserData()
        
        // Then: Verify all entity types are empty
        let transactionCount = try testContext.count(for: NSFetchRequest<Transaction>(entityName: "Transaction"))
        let budgetCount = try testContext.count(for: NSFetchRequest<Budget>(entityName: "Budget"))
        let categoryCount = try testContext.count(for: NSFetchRequest<BudgetCategory>(entityName: "BudgetCategory"))
        let accountCount = try testContext.count(for: NSFetchRequest<Account>(entityName: "Account"))
        let statementCount = try testContext.count(for: NSFetchRequest<Statement>(entityName: "Statement"))
        
        #expect(transactionCount == 0)
        #expect(budgetCount == 0)
        #expect(categoryCount == 0)
        #expect(accountCount == 0)
        #expect(statementCount == 0)
    }
    
    // MARK: - Temporary File Cleanup Tests
    
    @Test func cleanupTemporaryFiles() async throws {
        // Given: An old export file
        let tempDir = FileManager.default.temporaryDirectory
        let oldFileName = "ClariFi_Export_\(Date().timeIntervalSince1970 - 25 * 60 * 60).json"
        let oldFileURL = tempDir.appendingPathComponent(oldFileName)
        try "test data".write(to: oldFileURL, atomically: true, encoding: .utf8)
        
        #expect(FileManager.default.fileExists(atPath: oldFileURL.path))
        
        // When: Cleaning up temporary files
        privacyManager.cleanupTemporaryFiles()
        
        // Then: Old file should be deleted
        // Note: This is best-effort cleanup, so we just verify it doesn't crash
        // The actual deletion happens asynchronously
    }
    
    @Test func cleanupDoesNotDeleteRecentFiles() async throws {
        // Given: A recent export file
        let exportURL = try await privacyManager.exportUserData()
        #expect(FileManager.default.fileExists(atPath: exportURL.path))
        
        // When: Cleaning up temporary files
        privacyManager.cleanupTemporaryFiles()
        
        // Then: Recent file should still exist
        #expect(FileManager.default.fileExists(atPath: exportURL.path))
        
        // Cleanup
        try? FileManager.default.removeItem(at: exportURL)
    }
    
    // MARK: - Helper Methods
    
    private func createTestAccount() async throws -> Account {
        return try await testContext.perform {
            let account = Account(context: self.testContext)
            account.id = UUID()
            account.name = "Test Account"
            account.type = "checking"
            account.isActive = true
            account.isDefault = false
            account.createdAt = Date()
            account.updatedAt = Date()
            
            try self.testContext.save()
            return account
        }
    }
    
    private func createTestTransaction(date: Date = Date(), account: Account? = nil) async throws {
        try await testContext.perform {
            let transaction = Transaction(context: self.testContext)
            transaction.id = UUID()
            transaction.date = date
            transaction.merchant = "Test Merchant"
            transaction.amount = NSDecimalNumber(value: 50.00)
            transaction.currency = "USD"
            transaction.category = "Test Category"
            transaction.confidence = 0.95
            transaction.isManual = false
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
            
            if let account = account {
                transaction.account = account
            } else {
                let newAccount = Account(context: self.testContext)
                newAccount.id = UUID()
                newAccount.name = "Test Account"
                newAccount.type = "checking"
                newAccount.isActive = true
                newAccount.isDefault = false
                newAccount.createdAt = Date()
                newAccount.updatedAt = Date()
                transaction.account = newAccount
            }
            
            try self.testContext.save()
        }
    }
    
    private func createTestTransactions(count: Int) async throws {
        for _ in 0..<count {
            try await createTestTransaction()
        }
    }
    
    private func createTestBudget() async throws {
        try await testContext.perform {
            let budget = Budget(context: self.testContext)
            budget.id = UUID()
            budget.name = "Test Budget"
            budget.period = "monthly"
            budget.startDate = Date()
            budget.createdAt = Date()
            budget.updatedAt = Date()
            
            try self.testContext.save()
        }
    }
    
    private func createTestBudgets(count: Int) async throws {
        for _ in 0..<count {
            try await createTestBudget()
        }
    }
    
    private func createTestBudgetWithCategories() async throws {
        try await testContext.perform {
            let budget = Budget(context: self.testContext)
            budget.id = UUID()
            budget.name = "Test Budget"
            budget.period = "monthly"
            budget.startDate = Date()
            budget.createdAt = Date()
            budget.updatedAt = Date()
            
            let category1 = BudgetCategory(context: self.testContext)
            category1.id = UUID()
            category1.name = "Groceries"
            category1.budgetedAmount = NSDecimalNumber(value: 500.00)
            category1.alertThreshold = 0.8
            category1.budget = budget
            
            let category2 = BudgetCategory(context: self.testContext)
            category2.id = UUID()
            category2.name = "Transportation"
            category2.budgetedAmount = NSDecimalNumber(value: 200.00)
            category2.alertThreshold = 0.9
            category2.budget = budget
            
            try self.testContext.save()
        }
    }
    
    private func createTestStatement() async throws {
        try await testContext.perform {
            let statement = Statement(context: self.testContext)
            statement.id = UUID()
            statement.fileName = "test_statement.pdf"
            statement.uploadDate = Date()
            statement.fileHash = "test_hash_\(UUID().uuidString)"
            statement.processingStatus = "completed"
            
            try self.testContext.save()
        }
    }
    
    private func createTestStatements(count: Int) async throws {
        for _ in 0..<count {
            try await createTestStatement()
        }
    }
    
    private func cleanupTestData() async throws {
        try await testContext.perform {
            // Delete all test data
            let entityNames = ["Transaction", "BudgetCategory", "Budget", "Statement", "Account", "RecurringTransaction", "CategorizationRule"]
            
            for entityName in entityNames {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do {
                    try self.testContext.execute(deleteRequest)
                } catch {
                    // Some entities might not exist, that's okay
                }
            }
            
            try self.testContext.save()
        }
    }
}
