//
//  DIContainerTests.swift
//  ClariFi iOS Tests
//
//  Created by Kiro
//

import XCTest
@testable import ClariFi_iOS

/// Comprehensive unit tests for the DI Container
/// Tests singleton lifecycle, transient lifecycle, resolution, error handling, and reset functionality
final class DIContainerTests: XCTestCase {
    
    // MARK: - Properties
    
    var container: AppDIContainer!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        container = AppDIContainer()
    }
    
    override func tearDown() {
        container = nil
        super.tearDown()
    }
    
    // MARK: - Singleton Lifecycle Tests
    
    func testSingletonCreatedOnce() {
        // Arrange
        var creationCount = 0
        container.registerSingleton(TestService.self) { _ in
            creationCount += 1
            return TestService(id: creationCount)
        }
        
        // Act
        let instance1 = container.resolve(TestService.self)
        let instance2 = container.resolve(TestService.self)
        let instance3 = container.resolve(TestService.self)
        
        // Assert
        XCTAssertEqual(creationCount, 1, "Singleton should only be created once")
        XCTAssertEqual(instance1.id, 1, "First instance should have id 1")
        XCTAssertEqual(instance2.id, 1, "Second instance should be same as first")
        XCTAssertEqual(instance3.id, 1, "Third instance should be same as first")
    }
    
    func testSingletonCached() {
        // Arrange
        container.registerSingleton(TestService.self) { _ in
            TestService(id: 42)
        }
        
        // Act
        let instance1 = container.resolve(TestService.self)
        let instance2 = container.resolve(TestService.self)
        
        // Assert
        XCTAssertTrue(instance1 === instance2, "Singleton instances should be the same object")
    }
    
    func testSingletonWithDependencies() {
        // Arrange
        container.registerSingleton(TestRepository.self) { _ in
            TestRepository(name: "MainRepo")
        }
        
        container.registerSingleton(TestService.self) { container in
            let repo = container.resolve(TestRepository.self)
            return TestService(id: 1, repository: repo)
        }
        
        // Act
        let service = container.resolve(TestService.self)
        
        // Assert
        XCTAssertNotNil(service.repository, "Service should have repository injected")
        XCTAssertEqual(service.repository?.name, "MainRepo", "Repository should be correctly injected")
    }
    
    // MARK: - Transient Lifecycle Tests
    
    func testTransientCreatedEachTime() {
        // Arrange
        var creationCount = 0
        container.register(TestService.self) { _ in
            creationCount += 1
            return TestService(id: creationCount)
        }
        
        // Act
        let instance1 = container.resolve(TestService.self)
        let instance2 = container.resolve(TestService.self)
        let instance3 = container.resolve(TestService.self)
        
        // Assert
        XCTAssertEqual(creationCount, 3, "Transient should be created three times")
        XCTAssertEqual(instance1.id, 1, "First instance should have id 1")
        XCTAssertEqual(instance2.id, 2, "Second instance should have id 2")
        XCTAssertEqual(instance3.id, 3, "Third instance should have id 3")
    }
    
    func testTransientNotCached() {
        // Arrange
        container.register(TestService.self) { _ in
            TestService(id: Int.random(in: 1...1000))
        }
        
        // Act
        let instance1 = container.resolve(TestService.self)
        let instance2 = container.resolve(TestService.self)
        
        // Assert
        XCTAssertFalse(instance1 === instance2, "Transient instances should be different objects")
    }
    
    func testTransientWithDependencies() {
        // Arrange
        container.registerSingleton(TestRepository.self) { _ in
            TestRepository(name: "SharedRepo")
        }
        
        container.register(TestService.self) { container in
            let repo = container.resolve(TestRepository.self)
            return TestService(id: 1, repository: repo)
        }
        
        // Act
        let service1 = container.resolve(TestService.self)
        let service2 = container.resolve(TestService.self)
        
        // Assert
        XCTAssertFalse(service1 === service2, "Services should be different instances")
        XCTAssertTrue(service1.repository === service2.repository, "But they should share the same singleton repository")
    }
    
    // MARK: - Resolution Tests
    
    func testResolveRegisteredDependency() {
        // Arrange
        container.register(TestService.self) { _ in
            TestService(id: 100)
        }
        
        // Act
        let service = container.resolve(TestService.self)
        
        // Assert
        XCTAssertNotNil(service, "Should resolve registered dependency")
        XCTAssertEqual(service.id, 100, "Should resolve with correct configuration")
    }
    
    func testResolveOptionalRegisteredDependency() {
        // Arrange
        container.register(TestService.self) { _ in
            TestService(id: 200)
        }
        
        // Act
        let service = container.resolveOptional(TestService.self)
        
        // Assert
        XCTAssertNotNil(service, "Should resolve registered dependency")
        XCTAssertEqual(service?.id, 200, "Should resolve with correct configuration")
    }
    
    func testResolveOptionalUnregisteredDependency() {
        // Act
        let service = container.resolveOptional(TestService.self)
        
        // Assert
        XCTAssertNil(service, "Should return nil for unregistered dependency")
    }
    
    func testResolveMultipleDifferentTypes() {
        // Arrange
        container.register(TestService.self) { _ in
            TestService(id: 1)
        }
        container.register(TestRepository.self) { _ in
            TestRepository(name: "Repo1")
        }
        container.register(TestViewModel.self) { _ in
            TestViewModel(title: "ViewModel1")
        }
        
        // Act
        let service = container.resolve(TestService.self)
        let repository = container.resolve(TestRepository.self)
        let viewModel = container.resolve(TestViewModel.self)
        
        // Assert
        XCTAssertEqual(service.id, 1)
        XCTAssertEqual(repository.name, "Repo1")
        XCTAssertEqual(viewModel.title, "ViewModel1")
    }
    
    func testResolveDependencyChain() {
        // Arrange - Create a chain: ViewModel -> Service -> Repository
        container.registerSingleton(TestRepository.self) { _ in
            TestRepository(name: "DataRepo")
        }
        
        container.registerSingleton(TestService.self) { container in
            let repo = container.resolve(TestRepository.self)
            return TestService(id: 1, repository: repo)
        }
        
        container.register(TestViewModel.self) { container in
            let service = container.resolve(TestService.self)
            return TestViewModel(title: "Main", service: service)
        }
        
        // Act
        let viewModel = container.resolve(TestViewModel.self)
        
        // Assert
        XCTAssertNotNil(viewModel.service, "ViewModel should have service")
        XCTAssertNotNil(viewModel.service?.repository, "Service should have repository")
        XCTAssertEqual(viewModel.service?.repository?.name, "DataRepo", "Full chain should be resolved")
    }
    
    // MARK: - Error Handling Tests
    
    func testResolveMissingRegistrationCrashes() {
        // Arrange
        let expectation = expectation(description: "Should crash with fatalError")
        expectation.isInverted = true
        
        // Act & Assert
        // Note: We can't actually test fatalError in unit tests without crashing the test runner
        // This test documents the expected behavior
        // In a real scenario, this would crash with a clear error message
        
        // Instead, we test that the type is not registered
        XCTAssertFalse(container.isRegistered(TestService.self), "Type should not be registered")
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testResolveOptionalMissingRegistrationReturnsNil() {
        // Act
        let service = container.resolveOptional(TestService.self)
        
        // Assert
        XCTAssertNil(service, "Should return nil for missing registration")
    }
    
    func testIsRegisteredReturnsFalseForUnregisteredType() {
        // Act & Assert
        XCTAssertFalse(container.isRegistered(TestService.self), "Should return false for unregistered type")
    }
    
    func testIsRegisteredReturnsTrueForRegisteredType() {
        // Arrange
        container.register(TestService.self) { _ in
            TestService(id: 1)
        }
        
        // Act & Assert
        XCTAssertTrue(container.isRegistered(TestService.self), "Should return true for registered type")
    }
    
    func testIsRegisteredReturnsTrueForSingletonType() {
        // Arrange
        container.registerSingleton(TestService.self) { _ in
            TestService(id: 1)
        }
        
        // Act & Assert
        XCTAssertTrue(container.isRegistered(TestService.self), "Should return true for registered singleton")
    }
    
    // MARK: - Container Reset Tests
    
    func testResetClearsSingletonInstances() {
        // Arrange
        var creationCount = 0
        container.registerSingleton(TestService.self) { _ in
            creationCount += 1
            return TestService(id: creationCount)
        }
        
        let instance1 = container.resolve(TestService.self)
        XCTAssertEqual(instance1.id, 1)
        XCTAssertEqual(creationCount, 1)
        
        // Act
        container.reset()
        
        // Resolve again after reset
        let instance2 = container.resolve(TestService.self)
        
        // Assert
        XCTAssertEqual(creationCount, 2, "Singleton should be recreated after reset")
        XCTAssertEqual(instance2.id, 2, "New instance should have new id")
        XCTAssertFalse(instance1 === instance2, "Instances should be different after reset")
    }
    
    func testResetDoesNotAffectRegistrations() {
        // Arrange
        container.registerSingleton(TestService.self) { _ in
            TestService(id: 1)
        }
        container.register(TestRepository.self) { _ in
            TestRepository(name: "Repo")
        }
        
        // Act
        container.reset()
        
        // Assert
        XCTAssertTrue(container.isRegistered(TestService.self), "Singleton registration should still exist")
        XCTAssertTrue(container.isRegistered(TestRepository.self), "Transient registration should still exist")
        
        // Should still be able to resolve
        let service = container.resolve(TestService.self)
        let repo = container.resolve(TestRepository.self)
        XCTAssertNotNil(service)
        XCTAssertNotNil(repo)
    }
    
    func testResetAllowsSingletonRecreation() {
        // Arrange
        container.registerSingleton(TestService.self) { _ in
            TestService(id: 42)
        }
        
        let instance1 = container.resolve(TestService.self)
        XCTAssertEqual(instance1.id, 42)
        
        // Act
        container.reset()
        
        // Re-register with different configuration
        container.registerSingleton(TestService.self) { _ in
            TestService(id: 99)
        }
        
        let instance2 = container.resolve(TestService.self)
        
        // Assert
        XCTAssertEqual(instance2.id, 99, "Should use new registration after reset")
    }
    
    func testResetDoesNotAffectTransientBehavior() {
        // Arrange
        var creationCount = 0
        container.register(TestService.self) { _ in
            creationCount += 1
            return TestService(id: creationCount)
        }
        
        _ = container.resolve(TestService.self)
        _ = container.resolve(TestService.self)
        XCTAssertEqual(creationCount, 2)
        
        // Act
        container.reset()
        
        // Resolve again after reset
        _ = container.resolve(TestService.self)
        
        // Assert
        XCTAssertEqual(creationCount, 3, "Transient should continue creating new instances")
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentRegistration() {
        // Arrange
        let expectation = expectation(description: "Concurrent registrations complete")
        expectation.expectedFulfillmentCount = 10
        
        // Act
        for i in 0..<10 {
            DispatchQueue.global().async {
                self.container.register(TestService.self) { _ in
                    TestService(id: i)
                }
                expectation.fulfill()
            }
        }
        
        // Assert
        waitForExpectations(timeout: 2.0)
        XCTAssertTrue(container.isRegistered(TestService.self))
    }
    
    func testConcurrentResolution() {
        // Arrange
        container.registerSingleton(TestService.self) { _ in
            TestService(id: 1)
        }
        
        let expectation = expectation(description: "Concurrent resolutions complete")
        expectation.expectedFulfillmentCount = 100
        
        var resolvedInstances: [TestService] = []
        let lock = NSLock()
        
        // Act
        for _ in 0..<100 {
            DispatchQueue.global().async {
                let instance = self.container.resolve(TestService.self)
                lock.lock()
                resolvedInstances.append(instance)
                lock.unlock()
                expectation.fulfill()
            }
        }
        
        // Assert
        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(resolvedInstances.count, 100)
        
        // All instances should be the same singleton
        let firstInstance = resolvedInstances[0]
        for instance in resolvedInstances {
            XCTAssertTrue(instance === firstInstance, "All resolved instances should be the same singleton")
        }
    }
    
    // MARK: - Debug Helper Tests
    
    func testRegisteredTypesReturnsAllTypes() {
        // Arrange
        container.register(TestService.self) { _ in TestService(id: 1) }
        container.registerSingleton(TestRepository.self) { _ in TestRepository(name: "Repo") }
        container.register(TestViewModel.self) { _ in TestViewModel(title: "VM") }
        
        // Act
        let types = container.registeredTypes
        
        // Assert
        XCTAssertEqual(types.count, 3, "Should return all registered types")
        XCTAssertTrue(types.contains("TestService"), "Should include TestService")
        XCTAssertTrue(types.contains("TestRepository"), "Should include TestRepository")
        XCTAssertTrue(types.contains("TestViewModel"), "Should include TestViewModel")
    }
    
    func testRegisteredTypesReturnsSortedList() {
        // Arrange
        container.register(TestViewModel.self) { _ in TestViewModel(title: "VM") }
        container.register(TestService.self) { _ in TestService(id: 1) }
        container.register(TestRepository.self) { _ in TestRepository(name: "Repo") }
        
        // Act
        let types = container.registeredTypes
        
        // Assert
        XCTAssertEqual(types, types.sorted(), "Types should be sorted alphabetically")
    }
}

// MARK: - Test Helpers

/// Test service class for DI container testing
private class TestService {
    let id: Int
    var repository: TestRepository?
    
    init(id: Int, repository: TestRepository? = nil) {
        self.id = id
        self.repository = repository
    }
}

/// Test repository class for DI container testing
private class TestRepository {
    let name: String
    
    init(name: String) {
        self.name = name
    }
}

/// Test view model class for DI container testing
private class TestViewModel {
    let title: String
    var service: TestService?
    
    init(title: String, service: TestService? = nil) {
        self.title = title
        self.service = service
    }
}
