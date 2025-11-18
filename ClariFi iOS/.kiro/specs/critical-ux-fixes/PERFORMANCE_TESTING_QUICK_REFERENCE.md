# Performance Testing Quick Reference

## Quick Start

### Run All Performance Tests
```bash
./run_performance_tests.sh
```

### Run Specific Test
```bash
# App launch
xcodebuild test -scheme ClariFi_iOS -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/PerformanceTests/testAppLaunchTime

# Onboarding
xcodebuild test -scheme ClariFi_iOS -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/PerformanceTests/testOnboardingStepTransitionTime

# LLM
xcodebuild test -scheme ClariFi_iOS -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/PerformanceTests/testLLMQueryTime

# Category lookup
xcodebuild test -scheme ClariFi_iOS -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/PerformanceTests/testCategoryLookupTime
```

## Performance Targets

| Metric | Target | Critical |
|--------|--------|----------|
| App Launch | < 2s | < 3s |
| Onboarding Transition | < 500ms | < 1s |
| LLM Query | < 3s | < 5s |
| Category Lookup | < 10ms | < 50ms |

## Measuring Performance

### Synchronous Operation
```swift
let result = PerformanceMonitor.shared.measure("operation_name") {
    // Your operation
    return someValue
}
```

### Async Operation
```swift
let result = await PerformanceMonitor.shared.measureAsync("async_op") {
    try await someAsyncOperation()
}
```

### Manual Timing
```swift
let timerId = PerformanceMonitor.shared.startMeasurement("complex_flow")
// ... do work ...
PerformanceMonitor.shared.endMeasurement("complex_flow", id: timerId)
```

### Get Statistics
```swift
if let stats = PerformanceMonitor.shared.getStatistics(for: "operation_name") {
    print("Average: \(stats.averageMs)ms")
    print("Min: \(stats.minMs)ms")
    print("Max: \(stats.maxMs)ms")
    print("Count: \(stats.count)")
}
```

### Print Summary
```swift
PerformanceMonitor.shared.printSummary()
```

## LLM Performance Monitoring

### Track Query
```swift
let queryId = await LLMPerformanceMonitor.shared.startQuery()

let result = try await llmService.categorizeWithLLM(
    merchant: merchant,
    amount: amount,
    context: context
)

await LLMPerformanceMonitor.shared.endQuery(
    queryId: queryId,
    method: result.matchType,
    category: result.category
)
```

### Get Metrics
```swift
let avgTime = await LLMPerformanceMonitor.shared.getAverageQueryTime()
let successRate = await LLMPerformanceMonitor.shared.getLLMSuccessRate()
let fallbackRate = await LLMPerformanceMonitor.shared.getFallbackRate()
let accuracy = await LLMPerformanceMonitor.shared.getOverallAccuracy()
```

### Log Summary
```swift
await LLMPerformanceMonitor.shared.logPerformanceSummary()
```

## Test Coverage

### App Launch (2 tests)
- `testAppLaunchTime()` - Complete initialization
- `testDependencyRegistrationTime()` - DI setup

### Onboarding (3 tests)
- `testOnboardingStepTransitionTime()` - Step navigation
- `testOnboardingValidationTime()` - Validation logic
- `testCompleteOnboardingFlowTime()` - Full flow

### LLM (5 tests)
- `testLLMQueryTime()` - Single query
- `testLLMFallbackTime()` - Fallback performance
- `testLLMMerchantNormalizationTime()` - Normalization
- `testBulkLLMCategorizationTime()` - Batch processing
- `testLLMResponseCaching()` - Cache verification

### Category Lookup (5 tests)
- `testCategoryLookupTime()` - Single lookup
- `testGetAllCategoriesTime()` - Get all
- `testCategoryDisplayNameLookupTime()` - Display name
- `testBulkCategoryLookupTime()` - Batch lookups
- `testCategoryMappingWithAliases()` - Alias mapping

### Optimization (3 tests)
- `testCategoryLookupOptimization()` - O(1) verification
- `testMemoryUsageDuringOnboarding()` - Memory check
- `testNoPerformanceRegression()` - Baseline check

## Optimization Strategies

### 1. Lazy Loading
Load resources only when needed:
```swift
private lazy var expensiveResource: Resource = {
    return Resource()
}()
```

### 2. Caching
Store computed results:
```swift
private var cache: [String: Result] = [:]

func getResult(for key: String) -> Result {
    if let cached = cache[key] {
        return cached
    }
    let result = computeResult(for: key)
    cache[key] = result
    return result
}
```

### 3. Background Processing
Move heavy work off main thread:
```swift
Task.detached(priority: .userInitiated) {
    let result = await heavyOperation()
    await MainActor.run {
        self.updateUI(with: result)
    }
}
```

### 4. Request Debouncing
Delay execution until user stops:
```swift
private var debounceTimer: Timer?

func onInputChange() {
    debounceTimer?.invalidate()
    debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
        self.performSearch()
    }
}
```

### 5. Batch Operations
Group multiple operations:
```swift
func processMultiple(_ items: [Item]) async throws -> [Result] {
    return try await withThrowingTaskGroup(of: Result.self) { group in
        for item in items {
            group.addTask { try await self.process(item) }
        }
        return try await group.reduce(into: []) { $0.append($1) }
    }
}
```

## Common Bottlenecks

### 1. Synchronous Core Data
**Problem:** UI freezes during data operations
**Solution:** Use background contexts and async/await

### 2. Repeated Lookups
**Problem:** Slow list rendering
**Solution:** Cache results, use dictionary lookup

### 3. LLM Timeouts
**Problem:** Long waits with no feedback
**Solution:** 5-second timeout, show progress

### 4. Heavy View Hierarchies
**Problem:** Slow transitions
**Solution:** Lazy load views, progressive disclosure

## Files

### Tests
- `Tests/IntegrationTests/PerformanceTests.swift` - Test suite

### Monitoring
- `Utilities/PerformanceMonitor.swift` - General monitoring
- `Utilities/LLMPerformanceMonitor.swift` - LLM monitoring

### Scripts
- `run_performance_tests.sh` - Automated test runner

### Documentation
- `.kiro/specs/critical-ux-fixes/PERFORMANCE_OPTIMIZATION_GUIDE.md` - Full guide
- `.kiro/specs/critical-ux-fixes/TASK_7.7_PERFORMANCE_TESTING_SUMMARY.md` - Summary

## Troubleshooting

### Tests Failing
1. Check simulator is running
2. Verify scheme is correct
3. Check test target membership
4. Review error messages in report

### Slow Performance
1. Run performance tests to identify bottleneck
2. Check PerformanceMonitor summary
3. Review optimization guide
4. Profile with Instruments

### Memory Issues
1. Run memory tests
2. Check for retain cycles
3. Verify caches have size limits
4. Profile with Instruments (Leaks)

## Next Steps

After running tests:
1. Review `performance_report.txt`
2. Check for failed tests
3. Identify bottlenecks
4. Apply optimizations from guide
5. Re-run tests to verify improvements

