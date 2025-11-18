# Performance Optimization Guide

## Overview

This document provides comprehensive performance testing results and optimization recommendations for ClariFi iOS. It covers app launch time, onboarding transitions, LLM queries, and category lookups.

## Performance Requirements (from Design)

| Metric | Target | Critical Threshold |
|--------|--------|-------------------|
| App Launch Time | < 2 seconds | < 3 seconds |
| Onboarding Step Transition | < 500ms | < 1 second |
| LLM Query Time | < 3 seconds | < 5 seconds |
| Category Lookup | < 10ms | < 50ms |
| Dependency Registration | < 100ms | < 200ms |

## Testing Methodology

### Running Performance Tests

```bash
# Run all performance tests
xcodebuild test -scheme ClariFi_iOS -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ClariFi_iOSTests/PerformanceTests

# Run specific performance test
xcodebuild test -scheme ClariFi_iOS -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ClariFi_iOSTests/PerformanceTests/testAppLaunchTime
```

### Using Performance Monitor

```swift
// Synchronous measurement
let result = PerformanceMonitor.shared.measure("operation_name") {
    // Your operation here
    return someValue
}

// Async measurement
let result = await PerformanceMonitor.shared.measureAsync("async_operation") {
    try await someAsyncOperation()
}

// Manual timing for complex flows
let timerId = PerformanceMonitor.shared.startMeasurement("complex_flow")
// ... do work ...
PerformanceMonitor.shared.endMeasurement("complex_flow", id: timerId)

// Get statistics
if let stats = PerformanceMonitor.shared.getStatistics(for: "operation_name") {
    print("Average: \(stats.averageMs)ms")
    print("Min: \(stats.minMs)ms")
    print("Max: \(stats.maxMs)ms")
    print("Count: \(stats.count)")
}

// Print summary of all measurements
PerformanceMonitor.shared.printSummary()
```

## Performance Test Results

### 1. App Launch Time

**Test:** `testAppLaunchTime()`

**Measures:**
- DI container initialization
- Core service registration
- Initial view setup

**Expected Results:**
- Average: < 2 seconds
- Max: < 3 seconds

**Optimization Tips:**
- Lazy load non-critical services
- Defer heavy initialization to background
- Use singleton pattern for shared resources
- Minimize work in app delegate

### 2. Onboarding Step Transitions

**Tests:**
- `testOnboardingStepTransitionTime()`
- `testOnboardingValidationTime()`
- `testCompleteOnboardingFlowTime()`

**Measures:**
- Step-to-step navigation time
- Validation logic execution
- Complete flow processing

**Expected Results:**
- Step transition: < 500ms
- Validation: < 10ms
- Complete flow: < 1 second (processing only)

**Optimization Tips:**
- Use `@Published` properties efficiently
- Avoid heavy computation in validation
- Preload next step content
- Use progressive disclosure

### 3. LLM Query Performance

**Tests:**
- `testLLMQueryTime()`
- `testLLMFallbackTime()`
- `testLLMMerchantNormalizationTime()`
- `testBulkLLMCategorizationTime()`

**Measures:**
- LLM categorization time
- Fallback to pattern matching
- Merchant name normalization
- Bulk transaction processing

**Expected Results:**
- Single query: < 3 seconds
- Fallback: < 100ms
- Normalization: < 1 second
- Bulk (10 transactions): < 30 seconds

**Optimization Tips:**
- Implement response caching
- Use request debouncing
- Optimize prompt length
- Batch similar queries
- Set reasonable timeouts (5 seconds)

**LLM Performance Monitoring:**

```swift
// Track query performance
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

// Get metrics
let avgTime = await LLMPerformanceMonitor.shared.getAverageQueryTime()
let successRate = await LLMPerformanceMonitor.shared.getLLMSuccessRate()
let fallbackRate = await LLMPerformanceMonitor.shared.getFallbackRate()

// Log summary
await LLMPerformanceMonitor.shared.logPerformanceSummary()
```

### 4. Category Lookup Performance

**Tests:**
- `testCategoryLookupTime()`
- `testGetAllCategoriesTime()`
- `testCategoryDisplayNameLookupTime()`
- `testBulkCategoryLookupTime()`
- `testCategoryMappingWithAliases()`

**Measures:**
- Single category lookup
- Getting all categories
- Display name resolution
- Bulk lookups
- Alias mapping

**Expected Results:**
- Single lookup: < 10ms
- Get all: < 10ms
- Display name: < 5ms
- Bulk (10 lookups): < 50ms

**Optimization Tips:**
- Use in-memory cache for CategoryDefinition
- Implement O(1) dictionary lookup
- Lazy load category mappings
- Avoid repeated array iterations

**Current Implementation:**

```swift
// CategoryMappingService uses efficient lookup
class CategoryMappingService {
    private let definitions = CategoryDefinition.allCategories
    
    // O(1) lookup with dictionary (can be optimized)
    func getCanonicalCategory(from templateName: String) -> CategoryDefinition? {
        return definitions.first { category in
            category.budgetTemplateAliases.contains(templateName) ||
            category.displayName == templateName ||
            category.canonicalName == templateName
        }
    }
}
```

**Optimization Opportunity:**

```swift
// Optimized version with dictionary cache
class CategoryMappingService {
    private let definitions = CategoryDefinition.allCategories
    private lazy var aliasCache: [String: CategoryDefinition] = {
        var cache: [String: CategoryDefinition] = [:]
        for category in definitions {
            // Add canonical name
            cache[category.canonicalName.lowercased()] = category
            // Add display name
            cache[category.displayName.lowercased()] = category
            // Add all aliases
            for alias in category.budgetTemplateAliases {
                cache[alias.lowercased()] = category
            }
        }
        return cache
    }()
    
    func getCanonicalCategory(from templateName: String) -> CategoryDefinition? {
        return aliasCache[templateName.lowercased()]
    }
}
```

## Optimization Strategies

### 1. Lazy Loading

**What:** Defer initialization of non-critical components until needed.

**Where to Apply:**
- Apple Foundation Model (load only when first LLM query is made)
- Category alias cache (build on first lookup)
- Analytics services (initialize in background)

**Example:**

```swift
class AppleFoundationModelManager {
    private var model: MLModel?
    private var isLoaded = false
    
    var isAvailable: Bool {
        if !isLoaded {
            loadModel()
        }
        return model != nil
    }
    
    private func loadModel() {
        guard !isLoaded else { return }
        isLoaded = true
        // Load model...
    }
}
```

### 2. Caching

**What:** Store computed results to avoid repeated calculations.

**Where to Apply:**
- LLM responses for identical queries
- Category lookups by alias
- Normalized merchant names

**Example:**

```swift
class AppleLLMCategorizationService {
    private var responseCache: [String: CategorizationResult] = [:]
    
    func categorizeWithLLM(merchant: String, amount: Decimal, context: String?) async throws -> CategorizationResult {
        let cacheKey = "\(merchant)_\(amount)"
        
        if let cached = responseCache[cacheKey] {
            return cached
        }
        
        let result = try await performLLMQuery(merchant: merchant, amount: amount, context: context)
        responseCache[cacheKey] = result
        
        return result
    }
}
```

### 3. Background Processing

**What:** Move heavy operations off the main thread.

**Where to Apply:**
- Statement parsing
- Bulk transaction categorization
- Analytics data collection

**Example:**

```swift
func processStatement(_ data: Data) async throws -> [Transaction] {
    return try await Task.detached(priority: .userInitiated) {
        // Heavy OCR and parsing work
        let text = try await self.ocrService.extractText(from: data)
        let transactions = try await self.parseTransactions(from: text)
        return transactions
    }.value
}
```

### 4. Request Debouncing

**What:** Delay execution until user stops making rapid changes.

**Where to Apply:**
- Search/filter inputs
- Real-time validation
- Auto-save operations

**Example:**

```swift
class TransactionEntryViewModel: ObservableObject {
    @Published var merchantName: String = "" {
        didSet {
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                self?.validateMerchant()
            }
        }
    }
    
    private var debounceTimer: Timer?
}
```

### 5. Batch Operations

**What:** Group multiple operations together to reduce overhead.

**Where to Apply:**
- Multiple transaction categorizations
- Bulk data saves
- Multiple category lookups

**Example:**

```swift
func categorizeTransactions(_ transactions: [Transaction]) async throws -> [CategorizationResult] {
    // Batch LLM queries instead of individual calls
    let merchants = transactions.map { $0.merchant }
    return try await llmService.categorizeBatch(merchants: merchants)
}
```

## Performance Monitoring in Production

### Key Metrics to Track

1. **App Launch Time**
   - Track in app delegate
   - Log to analytics
   - Alert if > 3 seconds

2. **LLM Performance**
   - Query times
   - Success/fallback rates
   - Accuracy metrics

3. **User Flow Times**
   - Time to first transaction
   - Onboarding completion time
   - Statement upload processing time

### Monitoring Code

```swift
// In ClariFi_iOSApp.swift
@main
struct ClariFi_iOSApp: App {
    init() {
        let launchTimerId = PerformanceMonitor.shared.startMeasurement("app_launch")
        
        registerDependencies()
        
        PerformanceMonitor.shared.endMeasurement("app_launch", id: launchTimerId)
        
        // Log to analytics
        if let stats = PerformanceMonitor.shared.getStatistics(for: "app_launch") {
            AnalyticsService.shared.logEvent("app_launch_time", parameters: [
                "duration_ms": stats.averageMs
            ])
        }
    }
}
```

## Bottleneck Identification

### Common Bottlenecks

1. **Synchronous Core Data Operations**
   - **Symptom:** UI freezes during data operations
   - **Solution:** Use background contexts and async/await

2. **Repeated Category Lookups**
   - **Symptom:** Slow list rendering with many transactions
   - **Solution:** Cache category definitions, use dictionary lookup

3. **LLM Timeout Issues**
   - **Symptom:** Long waits with no feedback
   - **Solution:** Implement 5-second timeout, show progress indicator

4. **Heavy View Hierarchies**
   - **Symptom:** Slow onboarding transitions
   - **Solution:** Lazy load views, use progressive disclosure

### Profiling Tools

1. **Instruments (Time Profiler)**
   ```bash
   # Profile app launch
   instruments -t "Time Profiler" -D trace.trace -l 10000 YourApp.app
   ```

2. **Xcode Performance Tests**
   ```swift
   func testPerformanceExample() throws {
       measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
           // Code to measure
       }
   }
   ```

3. **Custom Performance Monitor**
   ```swift
   PerformanceMonitor.shared.printSummary()
   ```

## Optimization Checklist

### Before Release

- [ ] Run all performance tests
- [ ] Verify app launch < 2 seconds
- [ ] Verify onboarding transitions < 500ms
- [ ] Verify LLM queries < 3 seconds (or fallback < 100ms)
- [ ] Verify category lookups < 10ms
- [ ] Profile with Instruments
- [ ] Test on older devices (iPhone 12 or earlier)
- [ ] Test with large datasets (1000+ transactions)
- [ ] Verify no memory leaks
- [ ] Check battery impact

### Continuous Monitoring

- [ ] Track app launch time in analytics
- [ ] Monitor LLM performance metrics
- [ ] Track user flow completion times
- [ ] Set up alerts for performance regressions
- [ ] Review performance data weekly

## Performance Regression Prevention

### CI/CD Integration

```yaml
# .github/workflows/performance.yml
name: Performance Tests

on: [pull_request]

jobs:
  performance:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Performance Tests
        run: |
          xcodebuild test \
            -scheme ClariFi_iOS \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -only-testing:ClariFi_iOSTests/PerformanceTests
      - name: Check Performance Thresholds
        run: |
          # Parse test results and fail if thresholds exceeded
          ./scripts/check_performance_thresholds.sh
```

### Code Review Guidelines

1. **Review Performance Impact**
   - Does this change affect app launch?
   - Does this add synchronous operations on main thread?
   - Does this increase memory usage?

2. **Require Performance Tests**
   - New features should include performance tests
   - Changes to critical paths must verify no regression

3. **Benchmark Before/After**
   - Run performance tests before changes
   - Run again after changes
   - Compare results

## Conclusion

Performance optimization is an ongoing process. Use the tools and tests provided to:

1. **Measure** - Use PerformanceMonitor and LLMPerformanceMonitor
2. **Analyze** - Identify bottlenecks with profiling tools
3. **Optimize** - Apply strategies from this guide
4. **Verify** - Run performance tests to confirm improvements
5. **Monitor** - Track metrics in production

Remember: **Premature optimization is the root of all evil, but measured optimization is the path to great UX.**

## References

- [Apple Performance Best Practices](https://developer.apple.com/documentation/xcode/improving-your-app-s-performance)
- [Swift Concurrency Performance](https://developer.apple.com/documentation/swift/swift_standard_library/concurrency)
- [Core Data Performance](https://developer.apple.com/documentation/coredata/optimizing_core_data_performance)
- Design Document: `.kiro/specs/critical-ux-fixes/design.md`
- Requirements: `.kiro/specs/critical-ux-fixes/requirements.md`

