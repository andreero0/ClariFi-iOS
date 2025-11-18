//
//  DIContainerTests.swift
//  ClariFi iOSTests
//
//  Created by AI Assistant on 2025-10-10.
//
//  Tests for DI Container deadlock fixes, cycle detection, and thread safety
//

import XCTest
@testable import ClariFi_iOS

final class DIContainerTests: XCTestCase {
    
    var container: AppDIContainer!
    
    override func setUp() {
        super.setUp()
        container = AppDIContainer()
    }
    
    override func tearDown() {
        container = nil
        super.tearDown()
    }
    
    // MARK: - Basic Resolution Tests
    
    func testBasicSingletonResolution() {
        // Given
        container.registerSingleton(TestService.self) { _ in
            TestService()
        }
        
        // When
        let service1 = container.resolve(TestService.self)
        let service2 = container.resolve(TestService.self)
        
        // Then
        XCTAssertIdentical(service1, service2, "Singleton should return same instance")
    }
    
    func testBasicTransientResolution() {
        // Given
        container.register(TestService.self) { _ in
            TestService()
        }
        
        // When
        let service1 = container.resolve(TestService.self)
        let service2 = container.resolve(TestService.self)
        
        // Then
        XCTAssertNotIdentical(service1, service2, "Transient should return different instances")
    }
    
    // MARK: - Nested Dependency Resolution Tests (Deadlock Fix)
    
    func testNestedDependencyResolution() {
        // Given - ServiceA depends on ServiceB, ServiceB depends on ServiceC
        container.registerSingleton(TestServiceC.self) { _ in
            TestServiceC()
        }
        
        container.registerSingleton(TestServiceB.self) { container in
            let serviceC = container.resolve(TestServiceC.self)
            return TestServiceB(serviceC: serviceC)
        }
        
        container.registerSingleton(TestServiceA.self) { container in
            let serviceB = container.resolve(TestServiceB.self)
            return TestServiceA(serviceB: serviceB)
        }
        
        // When
        let serviceA = container.resolve(TestServiceA.self)
        
        // Then
        XCTAssertNotNil(serviceA.serviceB)
        XCTAssertNotNil(serviceA.serviceB.serviceC)
        XCTAssertIdentical(serviceA.serviceB.serviceC, container.resolve(TestServiceC.self))
    }
    
    func testComplexNestedResolution() {
        // Given - Simulate BudgetCreationViewModel scenario
        container.registerSingleton(TestRepository.self) { _ in
            TestRepository()
        }
        
        container.registerSingleton(TestService.self) { container in
            let repo = container.resolve(TestRepository.self)
            return TestService(repository: repo)
        }
        
        container.register(TestViewModel.self) { container in
            let service = container.resolve(TestService.self)
            let repo = container.resolve(TestRepository.self)
            return TestViewModel(service: service, repository: repo)
        }
        
        // When
        let viewModel1 = container.resolve(TestViewModel.self)
        let viewModel2 = container.resolve(TestViewModel.self)
        
        // Then
        XCTAssertNotNil(viewModel1.service)
        XCTAssertNotNil(viewModel1.repository)
        XCTAssertIdentical(viewModel1.service, viewModel2.service, "Service should be singleton")
        XCTAssertIdentical(viewModel1.repository, viewModel2.repository, "Repository should be singleton")
        XCTAssertNotIdentical(viewModel1, viewModel2, "ViewModel should be transient")
    }
    
    // MARK: - Cycle Detection Tests
    
    func testCircularDependencyDetection() {
        // Given - ServiceA depends on ServiceB, ServiceB depends on ServiceA
        container.registerSingleton(TestServiceA.self) { container in
            let serviceB = container.resolve(TestServiceB.self)
            return TestServiceA(serviceB: serviceB)
        }
        
        container.registerSingleton(TestServiceB.self) { container in
            let serviceA = container.resolve(TestServiceA.self)
            return TestServiceB(serviceA: serviceA)
        }
        
        // When/Then
        XCTAssertThrowsError(try {
            _ = container.resolve(TestServiceA.self)
        }(), "Should detect circular dependency") { error in
            XCTAssertTrue(error.localizedDescription.contains("Circular dependency detected"))
        }
    }
    
    func testOptionalResolveWithCycle() {
        // Given - Circular dependency
        container.registerSingleton(TestServiceA.self) { container in
            let serviceB = container.resolveOptional(TestServiceB.self)
            return TestServiceA(serviceB: serviceB)
        }
        
        container.registerSingleton(TestServiceB.self) { container in
            let serviceA = container.resolveOptional(TestServiceA.self)
            return TestServiceB(serviceA: serviceA)
        }
        
        // When
        let serviceA = container.resolveOptional(TestServiceA.self)
        
        // Then - Should return nil instead of crashing
        XCTAssertNil(serviceA, "Optional resolve should return nil for circular dependency")
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentResolution() {
        // Given
        container.registerSingleton(TestService.self) { _ in
            TestService()
        }
        
        // When - Resolve from multiple threads
        let expectation = XCTestExpectation(description: "Concurrent resolution")
        expectation.expectedFulfillmentCount = 10
        
        for _ in 0..<10 {
            DispatchQueue.global().async {
                let service = self.container.resolve(TestService.self)
                XCTAssertNotNil(service)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConcurrentRegistrationAndResolution() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 20
        
        // When - Register and resolve concurrently
        for i in 0..<10 {
            DispatchQueue.global().async {
                self.container.register(TestService.self) { _ in
                    TestService()
                }
                expectation.fulfill()
            }
            
            DispatchQueue.global().async {
                let service = self.container.resolveOptional(TestService.self)
                XCTAssertNotNil(service)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testUnregisteredTypeError() {
        // When/Then
        XCTAssertThrowsError(try {
            _ = container.resolve(TestService.self)
        }(), "Should throw error for unregistered type") { error in
            XCTAssertTrue(error.localizedDescription.contains("No registration found"))
        }
    }
    
    func testOptionalResolveUnregisteredType() {
        // When
        let service = container.resolveOptional(TestService.self)
        
        // Then
        XCTAssertNil(service, "Optional resolve should return nil for unregistered type")
    }
    
    // MARK: - Reset Tests
    
    func testResetClearsSingletons() {
        // Given
        container.registerSingleton(TestService.self) { _ in
            TestService()
        }
        
        let service1 = container.resolve(TestService.self)
        
        // When
        container.reset()
        let service2 = container.resolve(TestService.self)
        
        // Then
        XCTAssertNotIdentical(service1, service2, "Reset should clear singleton cache")
    }
}

// MARK: - Test Types

private class TestService {
    let repository: TestRepository?
    
    init(repository: TestRepository? = nil) {
        self.repository = repository
    }
}

private class TestRepository {
    init() {}
}

private class TestServiceA {
    let serviceB: TestServiceB?
    
    init(serviceB: TestServiceB? = nil) {
        self.serviceB = serviceB
    }
}

private class TestServiceB {
    let serviceA: TestServiceA?
    let serviceC: TestServiceC?
    
    init(serviceA: TestServiceA? = nil, serviceC: TestServiceC? = nil) {
        self.serviceA = serviceA
        self.serviceC = serviceC
    }
}

private class TestServiceC {
    init() {}
}

private class TestViewModel {
    let service: TestService
    let repository: TestRepository
    
    init(service: TestService, repository: TestRepository) {
        self.service = service
        self.repository = repository
    }
}
