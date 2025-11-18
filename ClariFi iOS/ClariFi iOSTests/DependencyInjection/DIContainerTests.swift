//
//  DIContainerTests.swift
//  ClariFi iOSTests
//
//  Tests for DI container deadlock fixes and thread safety
//

import XCTest
@testable import ClariFi_iOS

class DIContainerTests: XCTestCase {
    
    var container: AppDIContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        container = AppDIContainer()
    }
    
    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }
    
    // MARK: - Nested Dependency Resolution Tests
    
    func testNestedDependencyResolution() throws {
        // Test that nested resolve calls don't cause deadlocks
        container.registerSingleton(String.self) { _ in
            "Test String"
        }
        
        container.registerSingleton(Int.self) { _ in
            42
        }
        
        container.registerTransient(TestService.self) { container in
            let stringValue: String = container.resolve(String.self)
            let intValue: Int = container.resolve(Int.self)
            return TestService(stringValue: stringValue, intValue: intValue)
        }
        
        // This should not deadlock
        let service: TestService = container.resolve(TestService.self)
        XCTAssertEqual(service.stringValue, "Test String")
        XCTAssertEqual(service.intValue, 42)
    }
    
    func testCircularDependencyDetection() throws {
        // Test cycle detection
        container.registerSingleton(CircularServiceA.self) { container in
            let b: CircularServiceB = container.resolve(CircularServiceB.self)
            return CircularServiceA(serviceB: b)
        }
        
        container.registerSingleton(CircularServiceB.self) { container in
            let a: CircularServiceA = container.resolve(CircularServiceA.self)
            return CircularServiceB(serviceA: a)
        }
        
        // This should detect the circular dependency and fail gracefully
        XCTAssertThrowsError(try container.resolve(throwing: CircularServiceA.self)) { error in
            XCTAssertTrue(error.localizedDescription.contains("circular"))
        }
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentResolves() async throws {
        container.registerSingleton(String.self) { _ in
            "Concurrent Test"
        }
        
        // Test concurrent resolves
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    let value: String = self.container.resolve(String.self)
                    XCTAssertEqual(value, "Concurrent Test")
                }
            }
        }
    }
    
    func testSingletonCachingBehavior() throws {
        var creationCount = 0
        
        container.registerSingleton(TestService.self) { _ in
            creationCount += 1
            return TestService(stringValue: "Singleton", intValue: creationCount)
        }
        
        // Multiple resolves should return the same instance
        let service1: TestService = container.resolve(TestService.self)
        let service2: TestService = container.resolve(TestService.self)
        
        XCTAssertEqual(service1.intValue, service2.intValue)
        XCTAssertEqual(creationCount, 1) // Should only be created once
    }
    
    func testTransientBehavior() throws {
        var creationCount = 0
        
        container.registerTransient(TestService.self) { _ in
            creationCount += 1
            return TestService(stringValue: "Transient", intValue: creationCount)
        }
        
        // Multiple resolves should return different instances
        let service1: TestService = container.resolve(TestService.self)
        let service2: TestService = container.resolve(TestService.self)
        
        XCTAssertNotEqual(service1.intValue, service2.intValue)
        XCTAssertEqual(creationCount, 2) // Should be created twice
    }
}

// MARK: - Test Types

class TestService {
    let stringValue: String
    let intValue: Int
    
    init(stringValue: String, intValue: Int) {
        self.stringValue = stringValue
        self.intValue = intValue
    }
}

class CircularServiceA {
    let serviceB: CircularServiceB
    
    init(serviceB: CircularServiceB) {
        self.serviceB = serviceB
    }
}

class CircularServiceB {
    let serviceA: CircularServiceA
    
    init(serviceA: CircularServiceA) {
        self.serviceA = serviceA
    }
}
