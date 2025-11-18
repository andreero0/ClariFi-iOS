# Critical Runtime Fixes Design

## Overview

This design document outlines the systematic approach to resolving critical build-breaking and runtime issues in the ClariFi iOS codebase. These issues prevent compilation, cause test failures, and create data inconsistencies. The fixes must be implemented before any organizational cleanup can proceed, as they address fundamental architectural mismatches introduced by recent changes to currency formatting, dependency injection, and concurrency patterns.

## Architecture

### Current State Analysis

**Critical Issues Identified:**

1. **Async Formatter Contract Mismatch** (BLOCKING BUILD)
   - Models/Currency.swift:115 changed formatter to async
   - All consumers still call synchronously
   - CurrencyPreferenceManager.format (Models/Currency.swift:242) incompatible
   - Core/Extensions/Decimal+Currency.swift:12 incompatible
   - Services/ScenarioPlanningService.swift:315 incompatible

2. **DI Container API Mismatch** (BLOCKING TESTS)
   - Tests reference registerTransient (ClariFi iOSTests/DependencyInjection/DIContainerTests.swift:37, :70)
   - Container only exposes register/registerSingleton
   - Cycle detection uses fatalError instead of throwable errors
   - Core/DependencyInjection/AppDIContainer.swift:57 needs error handling

3. **Singleton vs DI Conflicts** (DATA INCONSISTENCY)
   - SecurityAuditService instantiated via DI (Core/DependencyInjection/AppDIContainer+Registration.swift:96)
   - Also accessed via SecurityAuditService.shared (Views/BiometricSettingsView.swift:196, Views/SecurityAuditView.swift:348)
   - Audit data diverges between instances

4. **Analytics Implementation Confusion** (UNUSED CODE)
   - DI resolves PostHogAnalyticsService (Core/DependencyInjection/AppDIContainer+Registration.swift:60)
   - Services/AnalyticsService+Improved.swift:1 implements batching but unused
   - Duplicate implementations cause confusion

5. **Concurrency Violations** (PERFORMANCE ISSUES)
   - InsightsViewModel.swift:43 runs heavy work on main actor
   - Contradicts concurrency tests
   - Risks UI hitching for large datasets

### Target Architecture

**Fixed Architecture Principles:**

1. **Consistent Async/Sync Boundaries**
   - Clear separation between async and sync code paths
   - Explicit formatSync method for synchronous contexts
   - Async methods used only in async contexts

2. **Single Source of Truth**
   - All services accessed through DI container
   - No singleton patterns alongside DI
   - Consistent service lifecycle management

3. **Proper Concurrency Isolation**
   - Heavy computation on background threads
   - Main actor only for UI updates
   - Actor-based caching for thread safety

4. **Testable Error Handling**
   - Throwable errors instead of fatalError
   - Recoverable error conditions
   - Test-friendly DI container API

## Components and Interfaces

### 1. Currency Formatter Resolution

**Problem**: Async formatter called from sync contexts throughout codebase

**Solution**: Dual API with clear usage patterns

```swift
// Models/Currency.swift
actor FormatterCache {
    // Existing async method for async contexts
    func formatter(for currency: Currency) async -> NumberFormatter { ... }
    
    // NEW: Synchronous method for sync contexts
    func formatterSync(for currency: Currency) -> NumberFormatter {
        // Return cached formatter or create new one synchronously
        // No await needed - safe for sync contexts
    }
}

// CurrencyPreferenceManager
class CurrencyPreferenceManager {
    // Update to use sync formatter
    func format(_ amount: Decimal) -> String {
        let formatter = FormatterCache.shared.formatterSync(for: selectedCurrency)
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
    
    // NEW: Async version for async contexts
    func formatAsync(_ amount: Decimal) async -> String {
        let formatter = await FormatterCache.shared.formatter(for: selectedCurrency)
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}
```

**Migration Strategy**:
1. Add formatterSync to FormatterCache actor
2. Update all sync callers to use formatterSync
3. Keep async formatter for future async contexts
4. Update Decimal+Currency extension to use sync method
5. Fix ScenarioPlanningService to use appropriate method

### 2. DI Container API Enhancement

**Problem**: Tests expect registerTransient and throwable cycle detection

**Solution**: Extend DI container with missing API

```swift
// Core/DependencyInjection/AppDIContainer.swift

enum DIError: Error, LocalizedError {
    case circularDependency(String)
    case resolutionFailed(String)
    case duplicateRegistration(String)
    
    var errorDescription: String? {
        switch self {
        case .circularDependency(let type):
            return "Circular dependency detected for type: \(type)"
        case .resolutionFailed(let type):
            return "Failed to resolve dependency: \(type)"
        case .duplicateRegistration(let type):
            return "Duplicate registration for type: \(type)"
        }
    }
}

class AppDIContainer {
    enum Lifecycle {
        case singleton
        case transient
    }
    
    // Existing methods remain
    func register<T>(_ type: T.Type, factory: @escaping (AppDIContainer) -> T) { ... }
    func registerSingleton<T>(_ type: T.Type, factory: @escaping (AppDIContainer) -> T) { ... }
    
    // NEW: Transient registration
    func registerTransient<T>(_ type: T.Type, factory: @escaping (AppDIContainer) -> T) {
        let key = String(describing: type)
        transientFactories[key] = { container in
            factory(container as! AppDIContainer)
        }
    }
    
    // NEW: Throwable resolution with cycle detection
    func resolve<T>(_ type: T.Type) throws -> T {
        let key = String(describing: type)
        
        // Check for circular dependency
        if resolutionStack.contains(key) {
            throw DIError.circularDependency(key)
        }
        
        resolutionStack.append(key)
        defer { resolutionStack.removeLast() }
        
        // Try singleton first
        if let instance = singletons[key] as? T {
            return instance
        }
        
        // Try transient
        if let factory = transientFactories[key] {
            guard let instance = factory(self) as? T else {
                throw DIError.resolutionFailed(key)
            }
            return instance
        }
        
        // Try regular factory
        if let factory = factories[key] {
            guard let instance = factory(self) as? T else {
                throw DIError.resolutionFailed(key)
            }
            return instance
        }
        
        throw DIError.resolutionFailed(key)
    }
    
    private var transientFactories: [String: (Any) -> Any] = [:]
    private var resolutionStack: [String] = []
}
```

**Migration Strategy**:
1. Add DIError enum for throwable errors
2. Implement registerTransient method
3. Add throwable resolve method
4. Update cycle detection to throw instead of fatalError
5. Keep existing non-throwing methods for backward compatibility
6. Update tests to use new API

### 3. Security Audit Service Normalization

**Problem**: Dual instantiation via DI and singleton pattern

**Solution**: Remove singleton, use DI exclusively

```swift
// Services/SecurityAuditService.swift
class SecurityAuditService {
    // REMOVE: static let shared = SecurityAuditService()
    
    // Keep existing implementation
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // Existing methods remain unchanged
}

// Views/BiometricSettingsView.swift
struct BiometricSettingsView: View {
    @StateObject private var viewModel: BiometricSettingsViewModel
    
    init(container: AppDIContainer) {
        let auditService = container.resolve(SecurityAuditService.self)
        _viewModel = StateObject(wrappedValue: BiometricSettingsViewModel(
            auditService: auditService
        ))
    }
}

// Views/SecurityAuditView.swift
struct SecurityAuditView: View {
    @StateObject private var viewModel: SecurityAuditViewModel
    
    init(container: AppDIContainer) {
        let auditService = container.resolve(SecurityAuditService.self)
        _viewModel = StateObject(wrappedValue: SecurityAuditViewModel(
            auditService: auditService
        ))
    }
}
```

**Migration Strategy**:
1. Remove SecurityAuditService.shared static property
2. Update BiometricSettingsView to use DI
3. Update SecurityAuditView to use DI
4. Verify all other usages go through DI
5. Update documentation to reflect DI-only pattern

### 4. Analytics Service Consolidation

**Problem**: Multiple analytics implementations, only one registered

**Solution**: Remove unused implementation, document the active one

**Decision Matrix**:
- PostHogAnalyticsService: Currently registered in DI
- AnalyticsService+Improved: Implements batching and caching but unused

**Recommended Action**: Remove AnalyticsService+Improved.swift

```swift
// Keep: Core/DependencyInjection/AppDIContainer+Registration.swift:60
container.registerSingleton(AnalyticsService.self) { _ in
    PostHogAnalyticsService()
}

// Remove: Services/AnalyticsService+Improved.swift
// Extract any useful batching logic if needed, then delete file
```

**Migration Strategy**:
1. Audit AnalyticsService+Improved for unique functionality
2. If batching is needed, integrate into PostHogAnalyticsService
3. Delete AnalyticsService+Improved.swift
4. Update documentation to reference PostHogAnalyticsService only
5. Verify no imports reference the removed file

### 5. Scenario Planning Async Fix

**Problem**: Non-async method calling async formatter

**Solution**: Use sync formatter or make method async

```swift
// Services/ScenarioPlanningService.swift:315

// Option 1: Use sync formatter (RECOMMENDED for immediate fix)
func generateScenario(...) -> Scenario {
    let formattedAmount = CurrencyPreferenceManager.shared.format(amount)
    // Rest of implementation
}

// Option 2: Make method async (if callers can support it)
func generateScenario(...) async -> Scenario {
    let formattedAmount = await CurrencyPreferenceManager.shared.formatAsync(amount)
    // Rest of implementation
}
```

**Migration Strategy**:
1. Check if generateScenario callers are in async context
2. If callers are sync, use Option 1 (sync formatter)
3. If callers are async, use Option 2 (async method)
4. Update method signature accordingly
5. Verify compilation succeeds

### 6. Statement Upload Persistence

**Problem**: Deduplication relies on in-memory + UserDefaults, lost on reinstall

**Solution**: Persist upload hashes in Core Data statement entity

```swift
// Models/Statement+CoreData.swift
extension Statement {
    @NSManaged public var uploadHash: String?
    @NSManaged public var uploadedAt: Date?
}

// ViewModels/StatementUploadViewModel.swift
class StatementUploadViewModel: ObservableObject {
    // REMOVE: private var uploadedStatements: Set<String> = []
    // REMOVE: UserDefaults persistence
    
    func checkDuplicate(fileHash: String) async -> Bool {
        // Query Core Data for existing statement with this hash
        let request = Statement.fetchRequest()
        request.predicate = NSPredicate(format: "uploadHash == %@", fileHash)
        request.fetchLimit = 1
        
        let results = try? await repository.fetch(request)
        return !(results?.isEmpty ?? true)
    }
    
    func markUploaded(statement: Statement, fileHash: String) async {
        statement.uploadHash = fileHash
        statement.uploadedAt = Date()
        try? await repository.save(statement)
    }
}
```

**Migration Strategy**:
1. Add uploadHash and uploadedAt to Statement entity
2. Update Core Data model and generate migration
3. Remove in-memory uploadedStatements set
4. Remove UserDefaults persistence code
5. Implement Core Data-based duplicate checking
6. Test with app reinstall scenario

### 7. Insights Background Processing

**Problem**: Heavy work on main actor blocks UI

**Solution**: Move generation to background, publish results on main actor

```swift
// ViewModels/InsightsViewModel.swift:43
@MainActor
class InsightsViewModel: ObservableObject {
    @Published var insights: [Insight] = []
    @Published var isLoading = false
    
    func loadInsights() async {
        isLoading = true
        
        // Move heavy work off main actor
        let generatedInsights = await Task.detached {
            // Heavy computation here
            await self.insightsEngine.generateInsights()
        }.value
        
        // Publish results on main actor
        insights = generatedInsights
        isLoading = false
    }
}

// Services/InsightsEngine.swift:38
actor InsightsEngine {
    func generateInsights() async -> [Insight] {
        // Heavy data aggregation and processing
        // Runs on background thread via actor isolation
        let transactions = await fetchTransactions()
        let budgets = await fetchBudgets()
        return analyzeData(transactions: transactions, budgets: budgets)
    }
}
```

**Migration Strategy**:
1. Make InsightsEngine an actor for background isolation
2. Update loadInsights to use Task.detached for heavy work
3. Ensure results published on main actor
4. Update concurrency tests to validate background processing
5. Test with large datasets to verify UI responsiveness

### 8. Widget Implementation Status

**Problem**: Widgets documented as shipped but contain placeholder code

**Solution**: Mark as "Coming Soon" or implement with real data

```swift
// Widgets/ClariFiWidget.swift
struct ClariFiWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ClariFi", provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                ClariFiWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
                    .overlay(alignment: .topTrailing) {
                        // NEW: Coming Soon badge
                        Text("Coming Soon")
                            .font(.caption2)
                            .padding(4)
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
            }
        }
        .configurationDisplayName("ClariFi")
        .description("Quick view of your financial status")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// OR: Implement with real data
struct Provider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // NEW: Fetch real data from repositories
        let container = AppDIContainer.shared
        let repository = container.resolve(TransactionRepository.self)
        
        Task {
            let transactions = try? await repository.fetchRecent(limit: 5)
            let entry = Entry(date: Date(), transactions: transactions ?? [])
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}
```

**Migration Strategy**:
1. Decide: Mark as "Coming Soon" or implement fully
2. If "Coming Soon": Add visual badge and update docs
3. If implementing: Connect to repositories via DI
4. Remove hardcoded sample data
5. Implement currency preference support
6. Update USER_GUIDE_UX_FEATURES.md to match reality

## Data Models

### Enhanced Statement Entity

```swift
// Core Data Model Update
entity Statement {
    // Existing attributes
    attribute id: UUID
    attribute date: Date
    attribute amount: Decimal
    attribute merchant: String
    
    // NEW: Upload tracking
    attribute uploadHash: String?
    attribute uploadedAt: Date?
    attribute uploadSource: String? // "manual", "ocr", "import"
}
```

### DI Container State

```swift
struct DIContainerState {
    var singletons: [String: Any]
    var factories: [String: (Any) -> Any]
    var transientFactories: [String: (Any) -> Any] // NEW
    var resolutionStack: [String] // NEW: For cycle detection
}
```

## Error Handling

### Compilation Error Resolution

**Priority 1: Build-Breaking Errors**
1. Async formatter mismatches → Add formatterSync method
2. Missing DI methods → Add registerTransient
3. Scenario planning async violation → Use sync formatter

**Priority 2: Test Compilation Errors**
1. Missing registerTransient → Implement method
2. fatalError in tests → Add throwable resolve
3. Cycle detection → Implement DIError

**Priority 3: Runtime Errors**
1. Singleton conflicts → Remove shared instances
2. Main actor blocking → Move to background
3. Data inconsistencies → Normalize service access

### Error Recovery Strategy

```swift
// Graceful degradation for formatter issues
func formatCurrency(_ amount: Decimal) -> String {
    do {
        return try CurrencyPreferenceManager.shared.format(amount)
    } catch {
        // Fallback to USD if formatter fails
        return "$\(amount)"
    }
}

// DI resolution with fallback
func resolveService<T>(_ type: T.Type, fallback: T) -> T {
    do {
        return try container.resolve(type)
    } catch {
        logger.error("Failed to resolve \(type): \(error)")
        return fallback
    }
}
```

## Testing Strategy

### Validation Approach

**Phase 1: Compilation Verification**
1. Fix async formatter → Verify project builds
2. Add DI methods → Verify tests compile
3. Update service access → Verify no singleton conflicts

**Phase 2: Test Suite Execution**
1. Run DI container tests → Verify lifecycle management
2. Run concurrency tests → Verify background processing
3. Run repository tests → Verify thread safety

**Phase 3: Integration Testing**
1. Test currency formatting across app
2. Test statement upload deduplication
3. Test insights loading performance
4. Test widget functionality

### Test Updates Required

```swift
// ClariFi iOSTests/DependencyInjection/DIContainerTests.swift
func testTransientRegistration() throws {
    // Now works with new API
    container.registerTransient(TestService.self) { _ in TestService() }
    let instance1 = try container.resolve(TestService.self)
    let instance2 = try container.resolve(TestService.self)
    XCTAssertFalse(instance1 === instance2)
}

func testCircularDependencyDetection() {
    // Now throws instead of crashing
    XCTAssertThrowsError(try container.resolve(CircularService.self)) { error in
        XCTAssertTrue(error is DIError)
    }
}

// ClariFi iOSTests/Concurrency/MainActorIsolationTests.swift
func testInsightsBackgroundProcessing() async {
    let viewModel = InsightsViewModel(container: container)
    await viewModel.loadInsights()
    // Verify insights loaded without blocking main thread
    XCTAssertFalse(viewModel.insights.isEmpty)
}
```

## Implementation Phases

### Phase 1: Critical Build Fixes (IMMEDIATE)
**Duration**: 2-3 hours
**Risk**: Low
**Blocking**: Yes

**Tasks**:
1. Add formatterSync to FormatterCache
2. Update CurrencyPreferenceManager to use sync formatter
3. Fix Decimal+Currency extension
4. Fix ScenarioPlanningService
5. Verify project builds

**Success Criteria**: Project compiles without errors

### Phase 2: DI Container Enhancement (HIGH PRIORITY)
**Duration**: 3-4 hours
**Risk**: Medium
**Blocking**: Test suite

**Tasks**:
1. Add DIError enum
2. Implement registerTransient
3. Add throwable resolve method
4. Update cycle detection
5. Verify tests compile and pass

**Success Criteria**: Test suite compiles and runs

### Phase 3: Service Normalization (HIGH PRIORITY)
**Duration**: 2-3 hours
**Risk**: Low
**Blocking**: Data consistency

**Tasks**:
1. Remove SecurityAuditService.shared
2. Update BiometricSettingsView
3. Update SecurityAuditView
4. Remove AnalyticsService+Improved
5. Verify single source of truth

**Success Criteria**: No singleton conflicts, consistent data

### Phase 4: Concurrency Improvements (MEDIUM PRIORITY)
**Duration**: 4-5 hours
**Risk**: Medium
**Blocking**: Performance

**Tasks**:
1. Make InsightsEngine an actor
2. Move heavy work to background
3. Update concurrency tests
4. Verify UI responsiveness

**Success Criteria**: Insights load without UI blocking

### Phase 5: Persistence and Integration (MEDIUM PRIORITY)
**Duration**: 3-4 hours
**Risk**: Medium
**Blocking**: User experience

**Tasks**:
1. Add uploadHash to Statement entity
2. Implement Core Data deduplication
3. Update widget status or implementation
4. Add integration tests

**Success Criteria**: Deduplication persists, widgets accurate

### Phase 6: Documentation Updates (LOW PRIORITY)
**Duration**: 2-3 hours
**Risk**: Low
**Blocking**: Developer experience

**Tasks**:
1. Update README with concurrency patterns
2. Update ARCHITECTURE.md with formatter cache
3. Update currency guides
4. Update test coverage docs
5. Update security/widget docs

**Success Criteria**: Documentation matches implementation

## Risk Mitigation

### High-Risk Changes

**1. Currency Formatter API Changes**
- **Risk**: Breaking existing formatting throughout app
- **Mitigation**: Add new method, don't remove old one initially
- **Rollback**: Keep async method, add sync alongside

**2. DI Container API Extension**
- **Risk**: Breaking existing registrations
- **Mitigation**: Add new methods, keep existing ones unchanged
- **Rollback**: New methods are additive, can be removed

**3. Service Singleton Removal**
- **Risk**: Breaking views that use .shared
- **Mitigation**: Update all usages before removing singleton
- **Rollback**: Re-add singleton if needed temporarily

### Validation Checkpoints

**After Each Phase**:
1. Full project compilation
2. Test suite execution
3. Manual smoke testing of affected features
4. Git commit with detailed description

**Rollback Triggers**:
- Compilation failures after 30 minutes
- Test failures exceeding 10% of suite
- Critical functionality broken
- Performance degradation > 50%

## Success Metrics

### Quantitative Targets

**Build Health**:
- Project compiles: 0 errors (currently failing)
- Test suite compiles: 0 errors (currently failing)
- Test pass rate: > 95%

**Code Quality**:
- Singleton patterns: 0 (remove SecurityAuditService.shared)
- Unused implementations: 0 (remove AnalyticsService+Improved)
- Async violations: 0 (fix all formatter calls)

**Performance**:
- Insights load time: < 2 seconds for 1000 transactions
- UI responsiveness: No main thread blocking > 100ms
- Widget load time: < 1 second

### Qualitative Targets

**Developer Experience**:
- Clear async/sync boundaries
- Consistent DI patterns
- Testable error handling
- Accurate documentation

**User Experience**:
- Smooth insights loading
- Reliable statement deduplication
- Accurate widget status
- Consistent currency formatting

## Conclusion

These critical runtime fixes address fundamental architectural issues that prevent the application from building and running correctly. The phased approach ensures that build-breaking issues are resolved first, followed by test compilation, service normalization, and performance improvements. Each phase includes validation checkpoints and rollback strategies to minimize risk.

Once these fixes are complete, the codebase will be in a stable state ready for the comprehensive organizational cleanup outlined in the separate cleanup spec.
