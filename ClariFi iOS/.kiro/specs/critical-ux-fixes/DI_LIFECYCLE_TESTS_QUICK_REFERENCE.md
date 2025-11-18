# DI Container Lifecycle Tests - Quick Reference

## Overview
Comprehensive integration tests for DI container lifecycle management, ensuring single instance behavior, shared state, memory safety, and reset functionality.

## Test File Location
```
Tests/IntegrationTests/DIContainerLifecycleTests.swift
```

## Running Tests

### Run All DI Lifecycle Tests
```bash
./run_di_lifecycle_tests.sh
```

### Run Specific Test Category
```bash
# Single instance tests
xcodebuild test -only-testing:ClariFi_iOSTests/DIContainerLifecycleTests/testSingletonBehavior_WithinContainer

# Memory leak tests
xcodebuild test -only-testing:ClariFi_iOSTests/DIContainerLifecycleTests/testNoMemoryLeaks_ContainerLifecycle

# Thread safety tests
xcodebuild test -only-testing:ClariFi_iOSTests/DIContainerLifecycleTests/testThreadSafety_ConcurrentResolution

# Reset tests
xcodebuild test -only-testing:ClariFi_iOSTests/DIContainerLifecycleTests/testContainerReset_ClearsSingletons
```

## Test Categories

### 1. Single Container Instance Tests
**Purpose**: Verify singleton and transient behavior

```swift
// Singleton behavior - same instance returned
let repo1 = container.resolve(TransactionRepository.self)
let repo2 = container.resolve(TransactionRepository.self)
XCTAssertTrue(repo1 === repo2 as AnyObject)

// Transient behavior - new instance each time
container.register(Service.self) { _ in Service() }
let service1 = container.resolve(Service.self)
let service2 = container.resolve(Service.self)
XCTAssertFalse(service1 === service2 as AnyObject)
```

**Tests**:
- `testSingleContainerInstance_ProductionContainer`
- `testSingletonBehavior_WithinContainer`
- `testTransientBehavior_NewInstanceEachTime`

### 2. Shared Repository State Tests
**Purpose**: Verify data persists across resolutions

```swift
// Create data with first resolution
let repo1 = container.resolve(TransactionRepository.self)
// Save transaction...

// Verify data accessible with second resolution
let repo2 = container.resolve(TransactionRepository.self)
let transactions = try await repo2.fetchAll()
XCTAssertGreaterThan(transactions.count, 0)
```

**Tests**:
- `testSharedRepositoryState_DataPersistence`
- `testSharedState_AcrossMultipleServices`
- `testServiceState_MaintainedThroughContainer`

### 3. Memory Leak Tests
**Purpose**: Verify no memory leaks or retain cycles

```swift
// Use weak reference to verify deallocation
weak var weakContainer: AppDIContainer?

autoreleasepool {
    let container = AppDIContainer()
    weakContainer = container
    // Use container...
}

XCTAssertNil(weakContainer, "Should be deallocated")
```

**Tests**:
- `testNoMemoryLeaks_ContainerLifecycle`
- `testNoMemoryLeaks_SingletonServices`
- `testNoRetainCycles_DependencyGraph`

### 4. Container Reset Tests
**Purpose**: Verify reset clears singletons but preserves registrations

```swift
// Resolve singleton
let service1 = container.resolve(CategoryService.self)

// Reset container
container.reset()

// Next resolution creates new instance
let service2 = container.resolve(CategoryService.self)
XCTAssertFalse(service1 === service2 as AnyObject)

// But registration still exists
XCTAssertTrue(container.isRegistered(CategoryService.self))
```

**Tests**:
- `testContainerReset_ClearsSingletons`
- `testContainerReset_ClearsCachedState`
- `testContainerReset_PreservesRegistrations`

### 5. Thread Safety Tests
**Purpose**: Verify thread-safe concurrent operations

```swift
// Concurrent resolutions
let expectation = XCTestExpectation(description: "Concurrent")
expectation.expectedFulfillmentCount = 10

for _ in 0..<10 {
    DispatchQueue.global().async {
        let service = container.resolve(CategoryService.self)
        // All should return same singleton instance
        expectation.fulfill()
    }
}

wait(for: [expectation], timeout: 5.0)
```

**Tests**:
- `testThreadSafety_ConcurrentResolution`
- `testThreadSafety_ConcurrentResetAndResolve`

### 6. Registration Tests
**Purpose**: Verify all required services are registered

```swift
// Check if service is registered
XCTAssertTrue(container.isRegistered(TransactionRepository.self))

// Optional resolution
let service = container.resolveOptional(CategoryService.self)
XCTAssertNotNil(service)

// Unregistered service
let missing = container.resolveOptional(UnregisteredService.self)
XCTAssertNil(missing)
```

**Tests**:
- `testServiceRegistration_AllRequiredServicesPresent`
- `testServiceRegistration_TestContainerComplete`
- `testOptionalResolution_RegisteredService`
- `testOptionalResolution_UnregisteredService`

## Common Test Patterns

### Pattern 1: Verify Singleton Behavior
```swift
let instance1 = container.resolve(ServiceType.self)
let instance2 = container.resolve(ServiceType.self)
XCTAssertTrue(instance1 === instance2 as AnyObject,
             "Singleton should return same instance")
```

### Pattern 2: Verify Memory Deallocation
```swift
weak var weakRef: AnyObject?

autoreleasepool {
    let object = createObject()
    weakRef = object as AnyObject
}

XCTAssertNil(weakRef, "Object should be deallocated")
```

### Pattern 3: Verify Thread Safety
```swift
let expectation = XCTestExpectation(description: "Concurrent ops")
expectation.expectedFulfillmentCount = N

for _ in 0..<N {
    DispatchQueue.global().async {
        // Perform operation
        expectation.fulfill()
    }
}

wait(for: [expectation], timeout: 5.0)
```

### Pattern 4: Verify Reset Behavior
```swift
let before = container.resolve(ServiceType.self)
container.reset()
let after = container.resolve(ServiceType.self)

XCTAssertFalse(before === after as AnyObject,
              "Reset should create new instance")
```

## Requirements Coverage

| Requirement | Description | Tests |
|------------|-------------|-------|
| 6.1 | Single container instance | 3 tests |
| 6.3 | Shared repository state | 3 tests |
| 6.4 | Service state management | 4 tests |
| 6.6 | No memory leaks | 3 tests |

## Test Execution Time
- **Individual Test**: ~0.1-0.5 seconds
- **Full Suite**: ~5-10 seconds
- **Thread Safety Tests**: ~2-3 seconds (due to concurrent operations)

## Debugging Failed Tests

### If Singleton Test Fails
```swift
// Check if service is registered as singleton
XCTAssertTrue(container.isRegistered(ServiceType.self))

// Verify registration type
// Should use registerSingleton, not register
```

### If Memory Leak Test Fails
```swift
// Check for retain cycles
// Use Instruments > Leaks to identify cycle
// Look for strong reference cycles in closures
```

### If Thread Safety Test Fails
```swift
// Check for race conditions
// Verify NSLock usage in container
// Use Thread Sanitizer to detect issues
```

### If Reset Test Fails
```swift
// Verify reset() clears singletons dictionary
// Check that registrations are preserved
// Ensure new instances are created after reset
```

## Integration with CI/CD

### Add to Test Suite
```yaml
# .github/workflows/tests.yml
- name: Run DI Lifecycle Tests
  run: ./run_di_lifecycle_tests.sh
```

### Test Coverage Requirements
- Minimum 80% code coverage for DIContainer
- All public methods must have tests
- All error paths must be tested

## Related Files

### Implementation
- `Core/DependencyInjection/DIContainer.swift` - Protocol definition
- `Core/DependencyInjection/AppDIContainer.swift` - Implementation
- `Core/DependencyInjection/AppDIContainer+Registration.swift` - Service registration
- `Core/DependencyInjection/DIContainer+Environment.swift` - SwiftUI integration

### Test Helpers
- `Tests/TestHelpers/DIContainer+Testing.swift` - Test container setup
- `Tests/Mocks/MockRepositories.swift` - Mock implementations

### Documentation
- [DI Pattern Quick Reference](DI_PATTERN_QUICK_REFERENCE.md)
- [Task 5.7 Completion Summary](TASK_5.7_DI_LIFECYCLE_TESTS_SUMMARY.md)
- [Phase 5 Completion Summary](PHASE_5_COMPLETION_SUMMARY.md)

## Best Practices

### 1. Always Use Test Container
```swift
// ✅ Good
let container = AppDIContainer.createTestContainer(inMemoryContext: viewContext)

// ❌ Bad
let container = AppDIContainer.createProductionContainer()
```

### 2. Clean Up After Tests
```swift
override func tearDown() async throws {
    container = nil
    persistenceController = nil
    viewContext = nil
    try await super.tearDown()
}
```

### 3. Use Weak References for Leak Tests
```swift
weak var weakRef: AnyObject?
autoreleasepool {
    // Create and use object
}
XCTAssertNil(weakRef)
```

### 4. Test Thread Safety with Multiple Threads
```swift
// Use at least 10 concurrent operations
for _ in 0..<10 {
    DispatchQueue.global().async {
        // Test operation
    }
}
```

## Troubleshooting

### Test Timeout
- Increase timeout for thread safety tests
- Check for deadlocks in container
- Verify async operations complete

### Flaky Tests
- Ensure proper cleanup in tearDown
- Use in-memory Core Data for isolation
- Avoid shared state between tests

### Memory Leak False Positives
- Ensure autoreleasepool is used
- Check for strong references in test code
- Verify weak references are properly set

## Quick Commands

```bash
# Run all DI tests
./run_di_lifecycle_tests.sh

# Run with verbose output
xcodebuild test -only-testing:ClariFi_iOSTests/DIContainerLifecycleTests -verbose

# Run specific test
xcodebuild test -only-testing:ClariFi_iOSTests/DIContainerLifecycleTests/testSingletonBehavior_WithinContainer

# Run with code coverage
xcodebuild test -enableCodeCoverage YES -only-testing:ClariFi_iOSTests/DIContainerLifecycleTests
```

## Summary

The DI container lifecycle tests provide comprehensive coverage of:
- ✅ Single instance behavior
- ✅ Shared state management
- ✅ Memory safety
- ✅ Thread safety
- ✅ Reset functionality
- ✅ Service registration

These tests ensure the DI container works correctly and prevents regressions in the dependency injection architecture.
