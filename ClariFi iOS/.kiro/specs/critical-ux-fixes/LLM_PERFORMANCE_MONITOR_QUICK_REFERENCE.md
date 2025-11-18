# LLM Performance Monitor - Quick Reference

## Overview

The `LLMPerformanceMonitor` provides comprehensive tracking of LLM service performance, including query times, fallback frequency, and categorization accuracy.

## Implementation Summary

### Files Created/Modified

1. **Created: `Utilities/LLMPerformanceMonitor.swift`**
   - Singleton performance monitor
   - Tracks query times, fallback frequency, and accuracy
   - Provides logging and metrics export

2. **Modified: `Services/LLM/AppleLLMCategorizationService.swift`**
   - Integrated performance monitoring into categorization flow
   - Tracks query start/end times
   - Records errors and fallbacks

3. **Created: `Tests/UnitTests/LLMPerformanceMonitorTests.swift`**
   - Comprehensive test coverage
   - Tests query tracking, accuracy tracking, and edge cases

## Key Features

### 1. Query Time Tracking

```swift
// Start tracking
let queryId = performanceMonitor.startQuery()

// End tracking with success
performanceMonitor.endQuery(queryId: queryId, method: .llm, category: "food_groceries")

// End tracking with error
performanceMonitor.endQueryWithError(queryId: queryId, error: error)
```

### 2. Fallback Frequency Tracking

The monitor automatically tracks when LLM falls back to pattern matching or rule-based categorization:

- **LLM Success**: When `method == .llm`
- **Fallback**: When `method == .pattern` or `method == .rule`

### 3. Categorization Accuracy Tracking

```swift
// Record when user confirms or corrects a category
performanceMonitor.recordAccuracy(
    predicted: "dining",
    actual: "food_groceries",
    method: .llm
)
```

### 4. Metrics Retrieval

```swift
// Get current metrics
let metrics = performanceMonitor.getMetrics()

// Get calculated metrics
let avgTime = performanceMonitor.getAverageQueryTime()
let llmSuccessRate = performanceMonitor.getLLMSuccessRate()
let fallbackRate = performanceMonitor.getFallbackRate()
let overallAccuracy = performanceMonitor.getOverallAccuracy()
let llmAccuracy = performanceMonitor.getLLMAccuracy()
let patternAccuracy = performanceMonitor.getPatternAccuracy()
```

### 5. Logging & Debugging

```swift
// Log performance summary to console
performanceMonitor.logPerformanceSummary()

// Export metrics for analytics
let metricsDict = performanceMonitor.exportMetrics()
```

## Performance Metrics Structure

```swift
struct PerformanceMetrics {
    // Query tracking
    var totalQueries: Int
    var llmSuccessCount: Int
    var fallbackCount: Int
    var errorCount: Int
    var queryTimes: [TimeInterval]
    
    // Accuracy tracking
    var totalCategorizations: Int
    var correctCategorizations: Int
    
    // Method-specific accuracy
    var llmCategorizations: Int
    var llmCorrectCategorizations: Int
    var patternCategorizations: Int
    var patternCorrectCategorizations: Int
    var ruleCategorizations: Int
    var ruleCorrectCategorizations: Int
}
```

## Integration with LLM Service

The performance monitor is automatically integrated into `AppleLLMCategorizationService`:

1. **Query Start**: Tracked at the beginning of `categorizeWithLLM()`
2. **Query End**: Tracked when categorization completes successfully
3. **Error Tracking**: Tracked when LLM query fails
4. **Fallback Tracking**: Tracked when falling back to pattern matching

## Usage Examples

### Example 1: Basic Query Tracking

```swift
let monitor = LLMPerformanceMonitor.shared
let queryId = monitor.startQuery()

// Perform LLM query
let result = try await llmService.categorizeWithLLM(
    merchant: "Starbucks",
    amount: 5.50,
    context: nil
)

monitor.endQuery(queryId: queryId, method: result.method, category: result.category)
```

### Example 2: Accuracy Tracking

```swift
// User confirms or corrects category
func userConfirmedCategory(predicted: String, actual: String, method: CategorizationMethod) {
    LLMPerformanceMonitor.shared.recordAccuracy(
        predicted: predicted,
        actual: actual,
        method: method
    )
}
```

### Example 3: Performance Summary

```swift
// Log performance summary
LLMPerformanceMonitor.shared.logPerformanceSummary()

// Output:
// === LLM Performance Summary ===
// Total Queries: 150
// LLM Success: 120 (80.0%)
// Fallbacks: 30 (20.0%)
// Errors: 5
// Avg Query Time: 0.234s
//
// Categorization Accuracy:
// - Overall: 85.5% (128/150)
// - LLM: 88.3% (106/120)
// - Pattern: 73.3% (22/30)
// ==============================
```

## Key Design Decisions

### 1. Singleton Pattern
- Single shared instance ensures consistent metrics across the app
- Thread-safe with `@MainActor` annotation

### 2. Query Time Limit
- Keeps only last 100 query times to prevent unbounded memory growth
- Total query count is still tracked accurately

### 3. Method-Specific Tracking
- Separate accuracy tracking for LLM, pattern, and rule-based methods
- Allows comparison of different categorization approaches

### 4. Graceful Error Handling
- Invalid query IDs are logged but don't crash
- Zero-division safety for all calculated metrics

### 5. Logging Integration
- Uses `os.log` for structured logging
- Different log levels for different events (info, debug, warning, error)

## Testing

The test suite covers:

1. **Query Tracking**: Start/end queries, timing accuracy
2. **Error Tracking**: Query failures and error counting
3. **Fallback Tracking**: Pattern and rule-based fallbacks
4. **Accuracy Tracking**: Overall and method-specific accuracy
5. **Metrics Export**: Dictionary export for analytics
6. **Edge Cases**: Invalid query IDs, zero division, query limit

Run tests:
```bash
xcodebuild test -scheme ClariFi_iOS -only-testing:ClariFi_iOSTests/LLMPerformanceMonitorTests
```

## Future Enhancements

Potential improvements for future iterations:

1. **Persistence**: Save metrics to disk for historical analysis
2. **Analytics Integration**: Send metrics to analytics service
3. **Performance Alerts**: Notify when metrics fall below thresholds
4. **Visualization**: Add SwiftUI views to display metrics
5. **A/B Testing**: Compare different LLM models or prompts
6. **Cost Tracking**: Track token usage and estimated costs

## Requirements Satisfied

✅ **Requirement 5.1**: Track LLM query times with millisecond precision
✅ **Requirement 5.5**: Track fallback frequency to pattern matching
✅ **Requirement 5.5**: Track categorization accuracy by method
✅ **Requirement 5.5**: Add comprehensive logging for debugging
✅ **Requirement 5.5**: Export metrics for analytics

## Related Files

- `Services/LLM/AppleLLMCategorizationService.swift` - LLM service with monitoring
- `Services/LLM/LLMCategorizationServiceProtocol.swift` - Protocol definitions
- `Services/LLM/AppleFoundationModelManager.swift` - Model manager
- `Tests/UnitTests/LLMCategorizationServiceTests.swift` - LLM service tests
