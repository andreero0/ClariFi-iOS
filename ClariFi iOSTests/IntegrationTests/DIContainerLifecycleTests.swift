//
//  DIContainerLifecycleTests.swift
//  ClariFi iOSTests
//
//  Integration tests for DI container lifecycle management
//  Tests Requirements: 6.1, 6.3, 6.4, 6.6
//

import XCTest
import CoreData
@testable import ClariFi_iOS

/// Tests the DI container lifecycle to ensure:
/// - Single container instance throughout app
/// - Shared repository state across resolutions
/// - No memory leaks
/// - Container reset functionality
class DIContainerLifecycleTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory persistence controller for testing
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
    }
    
    override func tearDown() async throws {
        // Clean up
        persistenceController = nil
        viewContext = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Single Container Instance Tests
    
    /// Test Requirement 6.1: Single DependencyContainer instance throughout app
    func testSingleContainerInstance_ProductionContainer() throws {
        // Given: Multiple calls to create production container
        let container1 = AppDIContainer.createProductionContainer()
        let container2 = AppDIContainer.createProductionContainer()
        
        // When: Resolving the same singleton service from both containers
        let service1 = container1.resolve(CategoryMappingServiceProtocol.self)
        let service2 = container2.resolve(CategoryMappingServiceProtocol.self)
        
        // Then: Services should be different instances (different containers)
        // This test verifies that each container creates its own instances
        XCTAssertFalse(service1 === service2 as AnyObject, 
                      "Different containers should create different service instances")
        
        // Note: In production, the app should only create ONE container instance
        // This is enforced at the app level in ClariFi_iOSApp.swift
    }
    
    /// Test Requirement 6.1: Verify singleton behavior within a single container
    func testSingletonBehavior_WithinContainer() throws {
        // Given: A single container instance
        let container = AppDIContainer.createTestContainer(inMemoryContext: viewContext)
        
        // When: Resolving the same singleton service multiple times
        let repository1 = container.resolve(TransactionRepository.self)
        let repository2 = container.resolve(TransactionRepository.self)
        let repository3 = container.resolve(TransactionRepository.self)
        
        // Then: All resolutions should return the same instance
        XCTAssertTrue(repository1 === repository2 as AnyObject,
                     "Singleton should return same instance on second resolution")
        XCTAssertTrue(repository2 === repository3 as AnyObject,
                     "Singleton should return same instance on third resolution")
        XCTAssertTrue(repository1 === repository3 as AnyObject,
                     "Singleton should return same instance across all resolutions")
    }
    
    /// Test Requirement 6.1: Verify transient behavior for non-singleton registrations
    func testTransientBehavior_NewInstanceEachTime() throws {
        // Given: A container with transient registration
        let container = AppDIContainer()
        
        // Register a transient service (new instance each time)
        container.register(CategoryMappingServiceProtocol.self) { _ in
            CategoryMappingService()
        }
        
        // When: Resolving the service multiple times
        let service1 = container.resolve(CategoryMappingServiceProtocol.self)
        let service2 = container.resolve(CategoryMappingServiceProtocol.self)
        
        // Then: Each resolution should return a different instance
        XCTAssertFalse(service1 === service2 as AnyObject,
                      "Transient registration should create new instance each time")
    }
    
    // MARK: - Shared Repository State Tests
    
    /// Test Requirement 6.3: Shared repository state across the application
    func testSharedRepositoryState_DataPersistence() async throws {
        // Given: A single container with singleton repositories
        let container = AppDIContainer.createTestContainer(inMemoryContext: viewContext)
        
        // When: Resolving repository and saving data
        let repository1 = container.resolve(TransactionRepository.self)
        
        let transaction = Transaction(context: viewContext)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = "Test Merchant"
        transaction.amount = NSDecimalNumber(value: 50.00)
        transaction.category = "Shopping"
        transaction.isManual = true
        
        let account = Account(context: viewContext)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "checking"
        transaction.account = account
        
        try viewContext.save()
        
        // Then: Resolving the same repository again should see the saved data
        let repository2 = container.resolve(TransactionRepository.self)
        let transactions = try await repository2.fetchAll()
        
        XCTAssertGreaterThanOrEqual(transactions.count, 1, "Repository should see saved data")
        XCTAssertTrue(repository1 === repository2 as AnyObject,
                     "Should be the same repository instance")
        
        let savedTransaction = transactions.first { $0.merchant == "Test Merchant" }
        XCTAssertNotNil(savedTransaction, "Saved transaction should be accessible")
        XCTAssertEqual(savedTransaction?.amount as Decimal?, 50.00)
    }
    
    /// Test Requirement 6.3: Shared state across multiple service resolutions
    func testSharedState_AcrossMultipleServices() async throws {
        // Given: A container with multiple services sharing repositories
        let container = AppDIContainer.createTestContainer(inMemoryContext: viewContext)
        
        // When: Creating data through one service
        let budgetRepository = container.resolve(BudgetRepository.self)
        
        let budget = Budget(context: viewContext)
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.period = "monthly"
        budget.startDate = Date()
        budget.isActive = true
        
        try viewContext.save()
        
        // Then: Another service using the same repository should see the data
        let budgetRepository2 = container.resolve(BudgetRepository.self)
        let budgets = try await budgetRepository2.fetchAll()
        
        XCTAssertTrue(budgetRepository === budgetRepository2 as AnyObject,
                     "Should resolve to same repository instance")
        XCTAssertGreaterThanOrEqual(budgets.count, 1, "Should see budget created by first service")
        
        let savedBudget = budgets.first { $0.name == "Test Budget" }
        XCTAssertNotNil(savedBudget, "Budget should be accessible through shared repository")
    }
    
    /// Test Requirement 6.4: Verify services maintain state through container
    func testServiceState_MaintainedThroughContainer() throws {
        // Given: A container with stateful services
        let container = AppDIContainer.createTestContainer(inMemoryContext: viewContext)
        
        // When: Resolving a service that maintains state
        let categoryService1 = container.resolve(CategoryService.self)
        let categoryService2 = container.resolve(CategoryService.self)
        
        // Then: Should be the same instance (singleton)
        XCTAssertTrue(categoryService1 === categoryService2 as AnyObject,
                     "Service should be singleton and maintain state")
    }
    
    // MARK: - Memory Leak Tests
    
    /// Test Requirement 6.6: Verify no memory leaks from container
    func testNoMemoryLeaks_ContainerLifecycle() throws {
        // Given: A container that will be deallocated
        weak var weakContainer: AppDIContainer?
        
        autoreleasepool {
            let container = AppDIContainer()
            weakContainer = container
            
            // Register some services
            container.registerSingleton(CategoryMappingServiceProtocol.self) { _ in
                CategoryMappingService()
            }
            
            // Resolve services
            _ = container.resolve(CategoryMappingServiceProtocol.self)
        }
        
        // Then: Container should be deallocated
        XCTAssertNil(weakContainer, "Container should be deallocated when no longer referenced")
    }
    
    /// Test Requirement 6.6: Verify no memory leaks from singleton services
    func testNoMemoryLeaks_SingletonServices() throws {
        // Given: A container with singleton services
        weak var weakService: AnyObject?
        
        autoreleasepool {
            let container = AppDIContainer()
            
            container.registerSingleton(CategoryMappingServiceProtocol.self) { _ in
                CategoryMappingService()
            }
            
            let service = container.resolve(CategoryMappingServiceProtocol.self)
            weakService = service as AnyObject
            
            // Service is still referenced by container
            XCTAssertNotNil(weakService, "Service should exist while container exists")
        }
        
        // Then: Service should be deallocated with container
        XCTAssertNil(weakService, "Service should be deallocated when container is deallocated")
    }
    
    /// Test Requirement 6.6: Verify no retain cycles in dependency graph
    func testNoRetainCycles_DependencyGraph() throws {
        // Given: A container with services that depend on each other
        weak var weakContainer: AppDIContainer?
        weak var weakRepository: AnyObject?
        weak var weakService: AnyObject?
        
        autoreleasepool {
            let container = AppDIContainer.createTestContainer(inMemoryContext: viewContext)
            weakContainer = container
            
            // Resolve services with dependencies
            let repository = container.resolve(TransactionRepository.self)
            let categoryService = container.resolve(CategoryService.self)
            
            weakRepository = repository as AnyObject
            weakService = categoryService as AnyObject
            
            XCTAssertNotNil(weakRepository, "Repository should exist")
            XCTAssertNotNil(weakService, "Service should exist")
        }
        
        // Then: All objects should be deallocated
        XCTAssertNil(weakContainer, "Container should be deallocated")
        XCTAssertNil(weakRepository, "Repository should be deallocated")
        XCTAssertNil(weakService, "Service should be deallocated")
    }
    
    // MARK: - Container Reset Tests
    
    /// Test Requirement 6.4: Container reset functionality
    func testContainerReset_ClearsSingletons() throws {
        // Given: A container with resolved singletons
        let container = AppDIContainer.createTestContainer(inMemoryContext: viewContext)
        
        // Resolve a singleton
        let repository1 = container.resolve(TransactionRepository.self)
        let service1 = container.resolve(CategoryService.self)
        
        // When: Resetting the container
        container.reset()
        
        // Then: Next resolution should create new instances
        let repository2 = container.resolve(TransactionRepository.self)
        let service2 = container.resolve(CategoryService.self)
        
        XCTAssertFalse(repository1 === repository2 as AnyObject,
                      "Reset should create new repository instance")
        XCTAssertFalse(service1 === service2 as AnyObject,
                      "Reset should create new service instance")
    }
    
    /// Test Requirement 6.4: Reset clears cached state
    func testContainerReset_ClearsCachedState() async throws {
        // Given: A container with data in repositories
        let container = AppDIContainer.createTestContainer(inMemoryContext: viewContext)
        
        let repository1 = container.resolve(TransactionRepository.self)
        
        // Create test data
        let transaction = Transaction(context: viewContext)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = "Before Reset"
        transaction.amount = NSDecimalNumber(value: 100.00)
        transaction.category = "Shopping"
        transaction.isManual = true
        
        let account = Account(context: viewContext)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "checking"
        transaction.account = account
        
        try viewContext.save()
        
        // Verify data exists
        let transactionsBefore = try await repository1.fetchAll()
        XCTAssertGreaterThanOrEqual(transactionsBefore.count, 1, "Should have data before reset")
        
        // When: Resetting container and clearing Core Data
        container.reset()
        
        // Clear Core Data
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Transaction.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try viewContext.execute(deleteRequest)
        try viewContext.save()
        
        // Then: New repository instance should see empty state
        let repository2 = container.resolve(TransactionRepository.self)
        let transactionsAfter = try await repository2.fetchAll()
        
        XCTAssertEqual(transactionsAfter.count, 0, "Should have no data after reset and clear")
        XCTAssertFalse(repository1 === repository2 as AnyObject,
                      "Should be different repository instance after reset")
    }
    
    /// Test Requirement 6.4: Reset doesn't affect registrations
    func testContainerReset_PreservesRegistrations() throws {
        // Given: A container with registrations
        let container = AppDIContainer.createTestContainer(inMemoryContext: viewContext)
        
        // Verify service is registered
        XCTAssertTrue(container.isRegistered(TransactionRepository.self),
                     "Service should be registered")
        
        // Resolve to create singleton instance
        _ = container.resolve(TransactionRepository.self)
        
        // When: Resetting the container
        container.reset()
        
        // Then: Registration should still exist
        XCTAssertTrue(container.isRegistered(TransactionRepository.self),
                     "Registration should persist after reset")
        
        // And: Should be able to resolve again
        let repository = container.resolve(TransactionRepository.self)
        XCTAssertNotNil(repository, "Should be able to resolve after reset")
    }
    
    // MARK: - Thread Safety Tests
    
    /// Test Requirement 6.3: Container is thread-safe
    func testThreadSafety_ConcurrentResolution() throws {
        // Given: A container with singleton services
        let container = AppDIContainer.createTestContainer(inMemoryContext: viewContext)
        
        let expectation = XCTestExpectation(description: "Concurrent resolutions complete")
        expectation.expectedFulfillmentCount = 10
        
        var resolvedServices: [CategoryService] = []
        let lock = NSLock()
        
        // When: Resolving services concurrently from multiple threads
        for _ in 0..<10 {
            DispatchQueue.global().async {
                let service = container.resolve(CategoryService.self)
                
                lock.lock()
                resolvedServices.append(service)
                lock.unlock()
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Then: All resolutions should return the same singleton instance
        XCTAssertEqual(resolvedServices.count, 10, "Should have 10 resolved services")
        
        let firstService = resolvedServices.first!
        for service in resolvedServices {
            XCTAssertTrue(firstService === service as AnyObject,
                         "All concurrent resolutions should return same singleton instance")
        }
    }
    
    /// Test Requirement 6.3: Container reset is thread-safe
    func testThreadSafety_ConcurrentResetAndResolve() throws {
        // Given: A container with singleton services
        let container = AppDIContainer.createTestContainer(inMemoryContext: viewContext)
        
        let expectation = XCTestExpectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = 20
        
        // When: Performing concurrent resets and resolutions
        for i in 0..<20 {
            DispatchQueue.global().async {
                if i % 2 == 0 {
                    // Reset on even iterations
                    container.reset()
                } else {
                    // Resolve on odd iterations
                    _ = container.resolve(CategoryService.self)
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Then: Container should still be functional
        let service = container.resolve(CategoryService.self)
        XCTAssertNotNil(service, "Container should still work after concurrent operations")
    }
    
    // MARK: - Registration Tests
    
    /// Test Requirement 6.1: Verify all required services are registered
    func testServiceRegistration_AllRequiredServicesPresent() throws {
        // Given: A production container
        let container = AppDIContainer.createProductionContainer()
        
        // Then: All required services should be registered
        XCTAssertTrue(container.isRegistered(TransactionRepository.self),
                     "TransactionRepository should be registered")
        XCTAssertTrue(container.isRegistered(AccountRepository.self),
                     "AccountRepository should be registered")
        XCTAssertTrue(container.isRegistered(BudgetRepository.self),
                     "BudgetRepository should be registered")
        XCTAssertTrue(container.isRegistered(CategoryMappingServiceProtocol.self),
                     "CategoryMappingService should be registered")
        XCTAssertTrue(container.isRegistered(CategoryServiceProtocol.self),
                     "CategoryService should be registered")
        XCTAssertTrue(container.isRegistered(BudgetTemplateService.self),
                     "BudgetTemplateService should be registered")
        XCTAssertTrue(container.isRegistered(InsightsEngineProtocol.self),
                     "InsightsEngine should be registered")
        XCTAssertTrue(container.isRegistered(BudgetMonitoringServiceProtocol.self),
                     "BudgetMonitoringService should be registered")
    }
    
    /// Test Requirement 6.1: Verify test container has all required services
    func testServiceRegistration_TestContainerComplete() throws {
        // Given: A test container
        let container = AppDIContainer.createTestContainer(inMemoryContext: viewContext)
        
        // Then: All required services should be registered
        XCTAssertTrue(container.isRegistered(TransactionRepository.self),
                     "TransactionRepository should be registered in test container")
        XCTAssertTrue(container.isRegistered(AccountRepository.self),
                     "AccountRepository should be registered in test container")
        XCTAssertTrue(container.isRegistered(BudgetRepository.self),
                     "BudgetRepository should be registered in test container")
        XCTAssertTrue(container.isRegistered(CategoryMappingServiceProtocol.self),
                     "CategoryMappingService should be registered in test container")
    }
    
    /// Test Requirement 6.2: Verify optional resolution works correctly
    func testOptionalResolution_RegisteredService() throws {
        // Given: A container with registered service
        let container = AppDIContainer.createTestContainer(inMemoryContext: viewContext)
        
        // When: Resolving with optional
        let service = container.resolveOptional(CategoryMappingServiceProtocol.self)
        
        // Then: Should return the service
        XCTAssertNotNil(service, "Optional resolution should return registered service")
    }
    
    /// Test Requirement 6.2: Verify optional resolution returns nil for unregistered
    func testOptionalResolution_UnregisteredService() throws {
        // Given: A container without a specific service
        let container = AppDIContainer()
        
        // When: Resolving unregistered service with optional
        let service = container.resolveOptional(CategoryMappingServiceProtocol.self)
        
        // Then: Should return nil
        XCTAssertNil(service, "Optional resolution should return nil for unregistered service")
    }
    
    // MARK: - Integration Tests
    
    /// Test Requirements 6.1, 6.3, 6.4: Full lifecycle integration test
    func testFullLifecycle_CreateResolveResetResolve() async throws {
        // Given: A fresh container
        let container = AppDIContainer.createTestContainer(inMemoryContext: viewContext)
        
        // When: Resolving services and creating data
        let repository1 = container.resolve(TransactionRepository.self)
        
        let transaction = Transaction(context: viewContext)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.merchant = "Lifecycle Test"
        transaction.amount = NSDecimalNumber(value: 75.00)
        transaction.category = "Testing"
        transaction.isManual = true
        
        let account = Account(context: viewContext)
        account.id = UUID()
        account.name = "Test Account"
        account.type = "checking"
        transaction.account = account
        
        try viewContext.save()
        
        // Verify data exists
        let transactions1 = try await repository1.fetchAll()
        XCTAssertGreaterThanOrEqual(transactions1.count, 1, "Should have data")
        
        // When: Resetting container
        container.reset()
        
        // Then: New repository instance should still see data (Core Data persists)
        let repository2 = container.resolve(TransactionRepository.self)
        let transactions2 = try await repository2.fetchAll()
        
        XCTAssertFalse(repository1 === repository2 as AnyObject,
                      "Should be different repository instance")
        XCTAssertGreaterThanOrEqual(transactions2.count, 1,
                                   "Data should persist in Core Data after container reset")
    }
}
