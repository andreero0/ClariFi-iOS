//
//  AccountRepositoryThreadSafetyTests.swift
//  ClariFi iOSTests
//
//  Thread safety tests for AccountRepository
//

import XCTest
import CoreData
@testable import ClariFi_iOS

@MainActor
class AccountRepositoryThreadSafetyTests: XCTestCase {
    
    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!
    var backgroundContextProvider: BackgroundContextProvider!
    var accountRepository: CoreDataAccountRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory Core Data stack
        container = NSPersistentContainer(name: "ClariFi_iOS")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        try await container.loadPersistentStores()
        context = container.viewContext
        backgroundContextProvider = BackgroundContextProvider(persistentContainer: container)
        accountRepository = CoreDataAccountRepository(context: context, backgroundContextProvider: backgroundContextProvider)
    }
    
    override func tearDown() async throws {
        container = nil
        context = nil
        backgroundContextProvider = nil
        accountRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Concurrent Read Tests
    
    func testConcurrentAccountReads() async throws {
        // Create test accounts
        let accounts = createTestAccounts(count: 50)
        for account in accounts {
            try await accountRepository.save(account)
        }
        
        // Test concurrent reads
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<30 {
                group.addTask {
                    do {
                        let fetched = try await self.accountRepository.fetchAll()
                        XCTAssertEqual(fetched.count, 50)
                    } catch {
                        XCTFail("Concurrent read failed: \(error)")
                    }
                }
            }
        }
    }
    
    func testConcurrentActiveAccountReads() async throws {
        // Create mix of active and inactive accounts
        let accounts = createTestAccounts(count: 30)
        for (index, account) in accounts.enumerated() {
            account.isActive = index % 2 == 0
            try await accountRepository.save(account)
        }
        
        // Test concurrent active account reads
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    do {
                        let activeAccounts = try await self.accountRepository.fetchActiveAccounts()
                        XCTAssertEqual(activeAccounts.count, 15)
                    } catch {
                        XCTFail("Concurrent active account read failed: \(error)")
                    }
                }
            }
        }
    }
    
    func testConcurrentAccountTypeReads() async throws {
        // Create accounts with different types
        let types = ["checking", "savings", "credit"]
        for (index, type) in types.enumerated() {
            for i in 0..<10 {
                let account = Account(context: context)
                account.id = UUID()
                account.name = "\(type.capitalized) Account \(i)"
                account.type = type
                account.isActive = true
                account.createdAt = Date()
                account.updatedAt = Date()
                try await accountRepository.save(account)
            }
        }
        
        // Test concurrent type-specific reads
        await withTaskGroup(of: Void.self) { group in
            for type in types {
                for _ in 0..<10 {
                    group.addTask {
                        do {
                            let accounts = try await self.accountRepository.fetchByType(type)
                            XCTAssertEqual(accounts.count, 10)
                        } catch {
                            XCTFail("Concurrent type read failed: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Concurrent Write Tests
    
    func testConcurrentAccountCreation() async throws {
        // Test concurrent account creation
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<40 {
                group.addTask {
                    do {
                        let account = Account(context: self.context)
                        account.id = UUID()
                        account.name = "Concurrent Account \(i)"
                        account.type = "checking"
                        account.isActive = true
                        account.createdAt = Date()
                        account.updatedAt = Date()
                        
                        try await self.accountRepository.save(account)
                    } catch {
                        XCTFail("Concurrent account creation failed: \(error)")
                    }
                }
            }
        }
        
        // Verify all accounts were created
        let allAccounts = try await accountRepository.fetchAll()
        XCTAssertEqual(allAccounts.count, 40)
    }
    
    func testConcurrentAccountUpdates() async throws {
        // Create initial accounts
        let accounts = createTestAccounts(count: 20)
        for account in accounts {
            try await accountRepository.save(account)
        }
        
        // Test concurrent updates
        await withTaskGroup(of: Void.self) { group in
            for (index, account) in accounts.enumerated() {
                group.addTask {
                    do {
                        account.name = "Updated Account \(index)"
                        account.updatedAt = Date()
                        try await self.accountRepository.save(account)
                    } catch {
                        XCTFail("Concurrent account update failed: \(error)")
                    }
                }
            }
        }
        
        // Verify all updates completed
        let updatedAccounts = try await accountRepository.fetchAll()
        XCTAssertEqual(updatedAccounts.count, 20)
        for account in updatedAccounts {
            XCTAssertTrue(account.name?.starts(with: "Updated Account") ?? false)
        }
    }
    
    func testConcurrentAccountDeactivation() async throws {
        // Create active accounts
        let accounts = createTestAccounts(count: 25)
        for account in accounts {
            account.isActive = true
            try await accountRepository.save(account)
        }
        
        // Test concurrent deactivation
        await withTaskGroup(of: Void.self) { group in
            for account in accounts {
                group.addTask {
                    do {
                        try await self.accountRepository.deactivateAccount(account)
                    } catch {
                        XCTFail("Concurrent deactivation failed: \(error)")
                    }
                }
            }
        }
        
        // Verify all accounts are deactivated
        let activeAccounts = try await accountRepository.fetchActiveAccounts()
        XCTAssertEqual(activeAccounts.count, 0)
    }
    
    // MARK: - Mixed Read/Write Tests
    
    func testConcurrentReadsAndWrites() async throws {
        // Create initial accounts
        let initialAccounts = createTestAccounts(count: 15)
        for account in initialAccounts {
            try await accountRepository.save(account)
        }
        
        // Test concurrent reads and writes
        await withTaskGroup(of: Void.self) { group in
            // Add write tasks
            for i in 0..<15 {
                group.addTask {
                    do {
                        let account = Account(context: self.context)
                        account.id = UUID()
                        account.name = "Mixed Account \(i)"
                        account.type = "savings"
                        account.isActive = true
                        account.createdAt = Date()
                        account.updatedAt = Date()
                        
                        try await self.accountRepository.save(account)
                    } catch {
                        XCTFail("Concurrent write failed: \(error)")
                    }
                }
            }
            
            // Add read tasks
            for _ in 0..<15 {
                group.addTask {
                    do {
                        let accounts = try await self.accountRepository.fetchAll()
                        XCTAssertTrue(accounts.count >= 15)
                    } catch {
                        XCTFail("Concurrent read failed: \(error)")
                    }
                }
            }
        }
        
        // Verify final state
        let finalAccounts = try await accountRepository.fetchAll()
        XCTAssertEqual(finalAccounts.count, 30)
    }
    
    func testConcurrentReadsWritesAndUpdates() async throws {
        // Create initial accounts
        let accounts = createTestAccounts(count: 10)
        for account in accounts {
            try await accountRepository.save(account)
        }
        
        // Test concurrent reads, writes, and updates
        await withTaskGroup(of: Void.self) { group in
            // Add read tasks
            for _ in 0..<10 {
                group.addTask {
                    do {
                        let _ = try await self.accountRepository.fetchActiveAccounts()
                    } catch {
                        XCTFail("Concurrent read failed: \(error)")
                    }
                }
            }
            
            // Add write tasks
            for i in 0..<10 {
                group.addTask {
                    do {
                        let account = Account(context: self.context)
                        account.id = UUID()
                        account.name = "New Account \(i)"
                        account.type = "credit"
                        account.isActive = true
                        account.createdAt = Date()
                        account.updatedAt = Date()
                        
                        try await self.accountRepository.save(account)
                    } catch {
                        XCTFail("Concurrent write failed: \(error)")
                    }
                }
            }
            
            // Add update tasks
            for account in accounts {
                group.addTask {
                    do {
                        account.name = "Updated \(account.name ?? "")"
                        try await self.accountRepository.save(account)
                    } catch {
                        XCTFail("Concurrent update failed: \(error)")
                    }
                }
            }
        }
        
        // Verify final state
        let finalAccounts = try await accountRepository.fetchAll()
        XCTAssertEqual(finalAccounts.count, 20)
    }
    
    // MARK: - Transaction Count Tests
    
    func testConcurrentTransactionCountQueries() async throws {
        // Create account with transactions
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "checking"
        account.isActive = true
        account.createdAt = Date()
        account.updatedAt = Date()
        try await accountRepository.save(account)
        
        // Create transactions for the account
        for i in 0..<50 {
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.amount = NSDecimalNumber(value: Double(i * 10))
            transaction.merchant = "Merchant \(i)"
            transaction.date = Date()
            transaction.category = "Test"
            transaction.account = account
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
        }
        try context.save()
        
        // Test concurrent transaction count queries
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    do {
                        let count = try await self.accountRepository.getTransactionCount(for: account)
                        XCTAssertEqual(count, 50)
                    } catch {
                        XCTFail("Concurrent transaction count query failed: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Default Account Tests
    
    func testConcurrentDefaultAccountAccess() async throws {
        // Test concurrent access to default account
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    do {
                        let defaultAccount = try await self.accountRepository.getOrCreateDefaultAccount()
                        XCTAssertNotNil(defaultAccount)
                        XCTAssertTrue(defaultAccount.isDefault)
                    } catch {
                        XCTFail("Concurrent default account access failed: \(error)")
                    }
                }
            }
        }
        
        // Verify only one default account was created
        let allAccounts = try await accountRepository.fetchAll()
        let defaultAccounts = allAccounts.filter { $0.isDefault }
        XCTAssertEqual(defaultAccounts.count, 1)
    }
    
    // MARK: - Data Integrity Tests
    
    func testNoDataCorruptionUnderConcurrency() async throws {
        // Create accounts with specific data
        let accountIds = (0..<30).map { _ in UUID() }
        
        await withTaskGroup(of: Void.self) { group in
            for (index, id) in accountIds.enumerated() {
                group.addTask {
                    do {
                        let account = Account(context: self.context)
                        account.id = id
                        account.name = "Account \(index)"
                        account.type = "checking"
                        account.isActive = true
                        account.createdAt = Date()
                        account.updatedAt = Date()
                        
                        try await self.accountRepository.save(account)
                    } catch {
                        XCTFail("Account creation failed: \(error)")
                    }
                }
            }
        }
        
        // Verify all accounts exist with correct data
        let allAccounts = try await accountRepository.fetchAll()
        XCTAssertEqual(allAccounts.count, 30)
        
        for (index, id) in accountIds.enumerated() {
            let account = allAccounts.first { $0.id == id }
            XCTAssertNotNil(account, "Account with ID \(id) not found")
            XCTAssertEqual(account?.name, "Account \(index)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestAccounts(count: Int) -> [Account] {
        var accounts: [Account] = []
        
        for i in 0..<count {
            let account = Account(context: context)
            account.id = UUID()
            account.name = "Test Account \(i)"
            account.type = i % 3 == 0 ? "checking" : (i % 3 == 1 ? "savings" : "credit")
            account.isActive = true
            account.createdAt = Date()
            account.updatedAt = Date()
            accounts.append(account)
        }
        
        return accounts
    }
}
