//
//  BudgetRepositoryThreadSafetyTests.swift
//  ClariFi iOSTests
//
//  Thread safety tests for BudgetRepository
//

import XCTest
import CoreData
@testable import ClariFi_iOS

@MainActor
class BudgetRepositoryThreadSafetyTests: XCTestCase {
    
    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!
    var backgroundContextProvider: BackgroundContextProvider!
    var budgetRepository: CoreDataBudgetRepository!
    
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
        budgetRepository = CoreDataBudgetRepository(context: context, backgroundContextProvider: backgroundContextProvider)
    }
    
    override func tearDown() async throws {
        container = nil
        context = nil
        backgroundContextProvider = nil
        budgetRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Concurrent Read Tests
    
    func testConcurrentBudgetReads() async throws {
        // Create test budgets
        let budgets = createTestBudgets(count: 40)
        for budget in budgets {
            try await budgetRepository.save(budget)
        }
        
        // Test concurrent reads
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<25 {
                group.addTask {
                    do {
                        let fetched = try await self.budgetRepository.fetchAll()
                        XCTAssertEqual(fetched.count, 40)
                    } catch {
                        XCTFail("Concurrent read failed: \(error)")
                    }
                }
            }
        }
    }
    
    func testConcurrentActiveBudgetReads() async throws {
        // Create mix of active and inactive budgets
        let budgets = createTestBudgets(count: 20)
        for (index, budget) in budgets.enumerated() {
            budget.isActive = index == 0 // Only first one is active
            try await budgetRepository.save(budget)
        }
        
        // Test concurrent active budget reads
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    do {
                        let activeBudget = try await self.budgetRepository.fetchActiveBudget()
                        XCTAssertNotNil(activeBudget)
                        XCTAssertTrue(activeBudget?.isActive ?? false)
                    } catch {
                        XCTFail("Concurrent active budget read failed: \(error)")
                    }
                }
            }
        }
    }
    
    func testConcurrentBudgetPeriodReads() async throws {
        // Create budgets with different periods
        let periods = ["monthly", "weekly", "yearly"]
        for (index, period) in periods.enumerated() {
            for i in 0..<8 {
                let budget = Budget(context: context)
                budget.id = UUID()
                budget.name = "\(period.capitalized) Budget \(i)"
                budget.period = period
                budget.totalAmount = NSDecimalNumber(value: 1000 * (index + 1))
                budget.isActive = i == 0
                budget.startDate = Date()
                budget.endDate = Date().addingTimeInterval(86400 * 30)
                budget.createdAt = Date()
                budget.updatedAt = Date()
                try await budgetRepository.save(budget)
            }
        }
        
        // Test concurrent period-specific reads
        await withTaskGroup(of: Void.self) { group in
            for period in periods {
                for _ in 0..<10 {
                    group.addTask {
                        do {
                            let budgets = try await self.budgetRepository.fetchByPeriod(period)
                            XCTAssertEqual(budgets.count, 8)
                        } catch {
                            XCTFail("Concurrent period read failed: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Concurrent Write Tests
    
    func testConcurrentBudgetCreation() async throws {
        // Test concurrent budget creation
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<35 {
                group.addTask {
                    do {
                        let budget = Budget(context: self.context)
                        budget.id = UUID()
                        budget.name = "Concurrent Budget \(i)"
                        budget.period = "monthly"
                        budget.totalAmount = NSDecimalNumber(value: Double(i * 100))
                        budget.isActive = false
                        budget.startDate = Date()
                        budget.endDate = Date().addingTimeInterval(86400 * 30)
                        budget.createdAt = Date()
                        budget.updatedAt = Date()
                        
                        try await self.budgetRepository.save(budget)
                    } catch {
                        XCTFail("Concurrent budget creation failed: \(error)")
                    }
                }
            }
        }
        
        // Verify all budgets were created
        let allBudgets = try await budgetRepository.fetchAll()
        XCTAssertEqual(allBudgets.count, 35)
    }
    
    func testConcurrentBudgetUpdates() async throws {
        // Create initial budgets
        let budgets = createTestBudgets(count: 20)
        for budget in budgets {
            try await budgetRepository.save(budget)
        }
        
        // Test concurrent updates
        await withTaskGroup(of: Void.self) { group in
            for (index, budget) in budgets.enumerated() {
                group.addTask {
                    do {
                        budget.name = "Updated Budget \(index)"
                        budget.totalAmount = NSDecimalNumber(value: Double(index * 200))
                        budget.updatedAt = Date()
                        try await self.budgetRepository.save(budget)
                    } catch {
                        XCTFail("Concurrent budget update failed: \(error)")
                    }
                }
            }
        }
        
        // Verify all updates completed
        let updatedBudgets = try await budgetRepository.fetchAll()
        XCTAssertEqual(updatedBudgets.count, 20)
        for budget in updatedBudgets {
            XCTAssertTrue(budget.name?.starts(with: "Updated Budget") ?? false)
        }
    }
    
    func testConcurrentBudgetDeactivation() async throws {
        // Create active budgets
        let budgets = createTestBudgets(count: 25)
        for budget in budgets {
            budget.isActive = true
            try await budgetRepository.save(budget)
        }
        
        // Test concurrent deactivation
        await withTaskGroup(of: Void.self) { group in
            for budget in budgets {
                group.addTask {
                    do {
                        try await self.budgetRepository.deactivateBudget(budget)
                    } catch {
                        XCTFail("Concurrent deactivation failed: \(error)")
                    }
                }
            }
        }
        
        // Verify all budgets are deactivated
        let activeBudget = try await budgetRepository.fetchActiveBudget()
        XCTAssertNil(activeBudget)
    }
    
    // MARK: - Mixed Read/Write Tests
    
    func testConcurrentReadsAndWrites() async throws {
        // Create initial budgets
        let initialBudgets = createTestBudgets(count: 12)
        for budget in initialBudgets {
            try await budgetRepository.save(budget)
        }
        
        // Test concurrent reads and writes
        await withTaskGroup(of: Void.self) { group in
            // Add write tasks
            for i in 0..<12 {
                group.addTask {
                    do {
                        let budget = Budget(context: self.context)
                        budget.id = UUID()
                        budget.name = "Mixed Budget \(i)"
                        budget.period = "weekly"
                        budget.totalAmount = NSDecimalNumber(value: 500)
                        budget.isActive = false
                        budget.startDate = Date()
                        budget.endDate = Date().addingTimeInterval(86400 * 7)
                        budget.createdAt = Date()
                        budget.updatedAt = Date()
                        
                        try await self.budgetRepository.save(budget)
                    } catch {
                        XCTFail("Concurrent write failed: \(error)")
                    }
                }
            }
            
            // Add read tasks
            for _ in 0..<12 {
                group.addTask {
                    do {
                        let budgets = try await self.budgetRepository.fetchAll()
                        XCTAssertTrue(budgets.count >= 12)
                    } catch {
                        XCTFail("Concurrent read failed: \(error)")
                    }
                }
            }
        }
        
        // Verify final state
        let finalBudgets = try await budgetRepository.fetchAll()
        XCTAssertEqual(finalBudgets.count, 24)
    }
    
    func testConcurrentReadsWritesAndUpdates() async throws {
        // Create initial budgets
        let budgets = createTestBudgets(count: 10)
        for budget in budgets {
            try await budgetRepository.save(budget)
        }
        
        // Test concurrent reads, writes, and updates
        await withTaskGroup(of: Void.self) { group in
            // Add read tasks
            for _ in 0..<10 {
                group.addTask {
                    do {
                        let _ = try await self.budgetRepository.fetchByPeriod("monthly")
                    } catch {
                        XCTFail("Concurrent read failed: \(error)")
                    }
                }
            }
            
            // Add write tasks
            for i in 0..<10 {
                group.addTask {
                    do {
                        let budget = Budget(context: self.context)
                        budget.id = UUID()
                        budget.name = "New Budget \(i)"
                        budget.period = "yearly"
                        budget.totalAmount = NSDecimalNumber(value: 12000)
                        budget.isActive = false
                        budget.startDate = Date()
                        budget.endDate = Date().addingTimeInterval(86400 * 365)
                        budget.createdAt = Date()
                        budget.updatedAt = Date()
                        
                        try await self.budgetRepository.save(budget)
                    } catch {
                        XCTFail("Concurrent write failed: \(error)")
                    }
                }
            }
            
            // Add update tasks
            for budget in budgets {
                group.addTask {
                    do {
                        budget.name = "Updated \(budget.name ?? "")"
                        try await self.budgetRepository.save(budget)
                    } catch {
                        XCTFail("Concurrent update failed: \(error)")
                    }
                }
            }
        }
        
        // Verify final state
        let finalBudgets = try await budgetRepository.fetchAll()
        XCTAssertEqual(finalBudgets.count, 20)
    }
    
    // MARK: - Budget with Categories Tests
    
    func testConcurrentBudgetWithCategoriesQueries() async throws {
        // Create budget with categories
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.totalAmount = NSDecimalNumber(value: 3000)
        budget.isActive = true
        budget.startDate = Date()
        budget.endDate = Date().addingTimeInterval(86400 * 30)
        budget.createdAt = Date()
        budget.updatedAt = Date()
        try await budgetRepository.save(budget)
        
        // Create categories for the budget
        for i in 0..<15 {
            let category = BudgetCategory(context: context)
            category.id = UUID()
            category.name = "Category \(i)"
            category.budgetedAmount = NSDecimalNumber(value: 200)
            category.spentAmount = NSDecimalNumber(value: Double(i * 10))
            category.budget = budget
            category.createdAt = Date()
            category.updatedAt = Date()
        }
        try context.save()
        
        // Test concurrent queries with categories
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    do {
                        let fetchedBudget = try await self.budgetRepository.fetchBudgetWithCategories(budget.id!)
                        XCTAssertNotNil(fetchedBudget)
                        XCTAssertEqual(fetchedBudget?.categories?.count, 15)
                    } catch {
                        XCTFail("Concurrent budget with categories query failed: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Data Integrity Tests
    
    func testNoDataCorruptionUnderConcurrency() async throws {
        // Create budgets with specific data
        let budgetIds = (0..<30).map { _ in UUID() }
        
        await withTaskGroup(of: Void.self) { group in
            for (index, id) in budgetIds.enumerated() {
                group.addTask {
                    do {
                        let budget = Budget(context: self.context)
                        budget.id = id
                        budget.name = "Budget \(index)"
                        budget.period = "monthly"
                        budget.totalAmount = NSDecimalNumber(value: Double(index * 100))
                        budget.isActive = index == 0
                        budget.startDate = Date()
                        budget.endDate = Date().addingTimeInterval(86400 * 30)
                        budget.createdAt = Date()
                        budget.updatedAt = Date()
                        
                        try await self.budgetRepository.save(budget)
                    } catch {
                        XCTFail("Budget creation failed: \(error)")
                    }
                }
            }
        }
        
        // Verify all budgets exist with correct data
        let allBudgets = try await budgetRepository.fetchAll()
        XCTAssertEqual(allBudgets.count, 30)
        
        for (index, id) in budgetIds.enumerated() {
            let budget = allBudgets.first { $0.id == id }
            XCTAssertNotNil(budget, "Budget with ID \(id) not found")
            XCTAssertEqual(budget?.name, "Budget \(index)")
            XCTAssertEqual(budget?.totalAmount?.decimalValue, Decimal(index * 100))
        }
    }
    
    func testConcurrentBudgetAmountUpdates() async throws {
        // Create a budget
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = "Amount Test Budget"
        budget.period = "monthly"
        budget.totalAmount = NSDecimalNumber(value: 1000)
        budget.isActive = true
        budget.startDate = Date()
        budget.endDate = Date().addingTimeInterval(86400 * 30)
        budget.createdAt = Date()
        budget.updatedAt = Date()
        try await budgetRepository.save(budget)
        
        // Test concurrent amount updates
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<20 {
                group.addTask {
                    do {
                        budget.totalAmount = NSDecimalNumber(value: 1000 + Double(i * 50))
                        try await self.budgetRepository.save(budget)
                    } catch {
                        XCTFail("Concurrent amount update failed: \(error)")
                    }
                }
            }
        }
        
        // Verify budget still exists and has a valid amount
        let updatedBudget = try await budgetRepository.fetchById(budget.id!)
        XCTAssertNotNil(updatedBudget)
        XCTAssertGreaterThanOrEqual(updatedBudget?.totalAmount?.doubleValue ?? 0, 1000)
    }
    
    // MARK: - Helper Methods
    
    private func createTestBudgets(count: Int) -> [Budget] {
        var budgets: [Budget] = []
        
        for i in 0..<count {
            let budget = Budget(context: context)
            budget.id = UUID()
            budget.name = "Test Budget \(i)"
            budget.period = i % 3 == 0 ? "monthly" : (i % 3 == 1 ? "weekly" : "yearly")
            budget.totalAmount = NSDecimalNumber(value: Double.random(in: 500...5000))
            budget.isActive = false
            budget.startDate = Date()
            budget.endDate = Date().addingTimeInterval(86400 * 30)
            budget.createdAt = Date()
            budget.updatedAt = Date()
            budgets.append(budget)
        }
        
        return budgets
    }
}
