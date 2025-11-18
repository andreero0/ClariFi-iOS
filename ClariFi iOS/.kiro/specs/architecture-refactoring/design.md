# Architecture Refactoring Design Document

## Overview

This document outlines the architectural redesign of the ClariFi iOS application to address inconsistent dependency injection patterns, tight coupling through singletons, and fragmented state management. The refactoring will establish a clean, maintainable architecture with proper dependency injection, clear separation of concerns, and consistent patterns throughout the codebase.

### Goals

- Eliminate singleton dependencies (39+ references to `RepositoryFactory.shared`)
- Implement a unified dependency injection container
- Standardize service layer architecture and lifecycle management
- Consolidate and standardize ViewModels
- Establish consistent error handling patterns
- Improve testability across all layers
- Maintain zero user-facing changes during refactoring

### Non-Goals

- Changing user-facing functionality or UI
- Rewriting Core Data layer (it's already well-implemented)
- Migrating to a different architectural pattern (staying with MVVM)
- Adding new features during refactoring

## Architecture

### Current State Analysis

**Problems Identified:**

1. **Singleton Overuse**: 39+ references to `RepositoryFactory.shared` throughout Views, ViewModels, and Tests
2. **Inconsistent DI**: Mix of singleton access, default parameters, manual injection, and environment objects
3. **Service Chaos**: No centralized service registry; services created ad-hoc in ViewModels
4. **Error Handling**: `AppError` enum exists but not consistently used
5. **State Management**: Fragmented across `@StateObject`, `@ObservedObject`, `@AppStorage`, and Core Data
6. **Documentation Overload**: 50+ markdown files creating noise

**Current Dependency Flow:**

```
Views
  ↓ (direct instantiation with RepositoryFactory.shared)
ViewModels
  ↓ (singleton access)
RepositoryFactory.shared
  ↓
Repositories
  ↓
Core Data
```

### Target Architecture

**Clean Architecture with Dependency Injection:**

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │  Views   │  │  Views   │  │  Views   │                  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                  │
│       │             │             │                          │
│       └─────────────┴─────────────┘                          │
│                     │                                        │
│              ┌──────▼──────┐                                │
│              │  ViewModels │ (@Published, @MainActor)       │
│              └──────┬──────┘                                │
└─────────────────────┼───────────────────────────────────────┘
                      │
                      │ (Protocol Boundaries)
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                      Domain Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Services   │  │   Services   │  │   Services   │      │
│  │  (Business   │  │  (Analytics, │  │  (Insights,  │      │
│  │   Logic)     │  │   Budget)    │  │   OCR)       │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
          │ (Protocol Boundaries)               │
          │                  │                  │
┌─────────▼──────────────────▼──────────────────▼─────────────┐
│                       Data Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Repositories │  │ Repositories │  │ Repositories │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
│                     ┌──────▼──────┐                         │
│                     │  Core Data  │                         │
│                     └─────────────┘                         │
└─────────────────────────────────────────────────────────────┘

                            ▲
                            │
                    ┌───────┴────────┐
                    │  DI Container  │
                    │  (Manages all  │
                    │  dependencies) │
                    └────────────────┘
```

**Dependency Flow:**

```
App Launch
  ↓
DI Container Setup
  ↓
Register Dependencies (Repositories, Services, ViewModels)
  ↓
Views Request ViewModels from Container
  ↓
ViewModels Receive Dependencies via Constructor
  ↓
Services/Repositories Injected (No Singletons)
```


## Components and Interfaces

### 1. Dependency Injection Container

**Core DI Container Protocol:**

```swift
protocol DIContainer {
    // Registration
    func register<T>(_ type: T.Type, factory: @escaping (DIContainer) -> T)
    func registerSingleton<T>(_ type: T.Type, factory: @escaping (DIContainer) -> T)
    
    // Resolution
    func resolve<T>(_ type: T.Type) -> T
    func resolveOptional<T>(_ type: T.Type) -> T?
    
    // Lifecycle
    func reset()
}
```

**Implementation:**

```swift
final class AppDIContainer: DIContainer {
    private var factories: [String: (DIContainer) -> Any] = [:]
    private var singletons: [String: Any] = [:]
    private var singletonFactories: [String: (DIContainer) -> Any] = [:]
    
    func register<T>(_ type: T.Type, factory: @escaping (DIContainer) -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    func registerSingleton<T>(_ type: T.Type, factory: @escaping (DIContainer) -> T) {
        let key = String(describing: type)
        singletonFactories[key] = factory
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        // Check if it's a singleton
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        // Check if it's a singleton factory
        if let factory = singletonFactories[key] {
            let instance = factory(self) as! T
            singletons[key] = instance
            return instance
        }
        
        // Check if it's a transient factory
        if let factory = factories[key] {
            return factory(self) as! T
        }
        
        fatalError("No registration found for type: \(type)")
    }
    
    func resolveOptional<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        if let factory = singletonFactories[key] {
            let instance = factory(self) as! T
            singletons[key] = instance
            return instance
        }
        
        if let factory = factories[key] {
            return factory(self) as! T
        }
        
        return nil
    }
    
    func reset() {
        singletons.removeAll()
    }
}
```

**Container Registration:**

```swift
extension AppDIContainer {
    static func createProductionContainer() -> DIContainer {
        let container = AppDIContainer()
        
        // Core Data
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext
        
        // Register Repositories (Singleton)
        container.registerSingleton(TransactionRepository.self) { _ in
            CoreDataTransactionRepository(context: context)
        }
        container.registerSingleton(AccountRepository.self) { _ in
            CoreDataAccountRepository(context: context)
        }
        container.registerSingleton(BudgetRepository.self) { _ in
            CoreDataBudgetRepository(context: context)
        }
        container.registerSingleton(BudgetCategoryRepository.self) { _ in
            CoreDataBudgetCategoryRepository(context: context)
        }
        container.registerSingleton(StatementRepository.self) { _ in
            CoreDataStatementRepository(context: context)
        }
        container.registerSingleton(RecurringTransactionRepository.self) { _ in
            CoreDataRecurringTransactionRepository(context: context)
        }
        
        // Register Services (Singleton)
        container.registerSingleton(AnalyticsServiceProtocol.self) { _ in
            PostHogAnalyticsService.shared
        }
        container.registerSingleton(OCRService.self) { _ in
            VisionOCRService()
        }
        container.registerSingleton(TransactionParserService.self) { _ in
            SmartTransactionParser()
        }
        container.registerSingleton(BudgetTemplateService.self) { _ in
            BudgetTemplateService.shared
        }
        container.registerSingleton(CategoryService.self) { _ in
            CategoryService(context: context)
        }
        container.registerSingleton(RuleEngine.self) { _ in
            RuleEngine(context: context)
        }
        
        // Register Domain Services (Singleton)
        container.registerSingleton(InsightsEngineProtocol.self) { _ in
            InsightsEngine(context: context)
        }
        container.registerSingleton(BudgetMonitoringService.self) { c in
            BudgetMonitoringService(
                budgetRepository: c.resolve(BudgetRepository.self),
                budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
                transactionRepository: c.resolve(TransactionRepository.self),
                context: context
            )
        }
        
        // Register ViewModels (Transient - new instance each time)
        container.register(BudgetViewModel.self) { c in
            BudgetViewModel(
                budgetRepository: c.resolve(BudgetRepository.self),
                budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
                transactionRepository: c.resolve(TransactionRepository.self),
                context: context
            )
        }
        container.register(InsightsViewModel.self) { c in
            InsightsViewModel(
                insightsEngine: c.resolve(InsightsEngineProtocol.self),
                transactionRepository: c.resolve(TransactionRepository.self),
                budgetRepository: c.resolve(BudgetRepository.self),
                context: context
            )
        }
        container.register(StatementUploadViewModel.self) { c in
            StatementUploadViewModel(
                ocrService: c.resolve(OCRService.self),
                parserService: c.resolve(TransactionParserService.self),
                transactionRepository: c.resolve(TransactionRepository.self),
                accountRepository: c.resolve(AccountRepository.self)
            )
        }
        container.register(TransactionEntryViewModel.self) { c in
            TransactionEntryViewModel(
                transactionRepository: c.resolve(TransactionRepository.self),
                accountRepository: c.resolve(AccountRepository.self),
                context: context,
                recurringService: nil // Optional dependency
            )
        }
        container.register(BudgetCreationViewModel.self) { c in
            BudgetCreationViewModel(
                budgetRepository: c.resolve(BudgetRepository.self),
                budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
                templateService: c.resolve(BudgetTemplateService.self),
                context: context
            )
        }
        container.register(BatchCategorizationViewModel.self) { c in
            BatchCategorizationViewModel(
                context: context,
                transactionRepository: c.resolve(TransactionRepository.self),
                categoryService: c.resolve(CategoryService.self),
                ruleEngine: c.resolve(RuleEngine.self)
            )
        }
        
        return container
    }
    
    static func createTestContainer() -> DIContainer {
        let container = AppDIContainer()
        
        // Register mock implementations for testing
        // This will be populated with test doubles
        
        return container
    }
}
```

### 2. Environment Object for DI Container

**SwiftUI Integration:**

```swift
// Environment key for DI container
private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainer = AppDIContainer.createProductionContainer()
}

extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}

// View extension for easy access
extension View {
    func withDIContainer(_ container: DIContainer) -> some View {
        environment(\.diContainer, container)
    }
}
```

**Usage in Views:**

```swift
struct BudgetView: View {
    @Environment(\.diContainer) private var container
    @StateObject private var viewModel: BudgetViewModel
    
    init() {
        // This won't work in init, so we use a different pattern
    }
    
    var body: some View {
        // Content
    }
}

// Better pattern - use a factory view
struct BudgetView: View {
    @StateObject private var viewModel: BudgetViewModel
    
    init(viewModel: BudgetViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        // Content
    }
}

// In parent view
struct MainTabView: View {
    @Environment(\.diContainer) private var container
    
    var body: some View {
        TabView {
            BudgetView(viewModel: container.resolve(BudgetViewModel.self))
        }
    }
}
```


### 3. Repository Layer Standardization

**Current State:**
- `RepositoryFactory.shared` used everywhere (39+ references)
- Repositories created with lazy initialization
- Tight coupling to singleton

**Target State:**
- Repositories injected via DI container
- No singleton access
- Protocol-based design maintained

**Migration Strategy:**

1. Keep existing repository protocols and implementations (they're well-designed)
2. Remove `RepositoryFactory.shared` singleton
3. Register repositories in DI container
4. Update all 39+ references to use injected dependencies

**Repository Protocol (No Changes Needed):**

```swift
// Existing protocols remain unchanged
protocol TransactionRepository: BaseRepository where Entity == Transaction {
    func fetchByDateRange(_ startDate: Date, _ endDate: Date) async throws -> [Transaction]
    func fetchByAccount(_ account: Account) async throws -> [Transaction]
    // ... other methods
}
```

**Repository Registration:**

```swift
// In DI Container
container.registerSingleton(TransactionRepository.self) { _ in
    CoreDataTransactionRepository(context: context)
}
```

### 4. Service Layer Architecture

**Service Protocol Pattern:**

All services will follow this pattern:

```swift
protocol ServiceProtocol {
    // Service-specific methods
}

class ConcreteService: ServiceProtocol {
    // Dependencies injected via constructor
    private let dependency1: Dependency1Protocol
    private let dependency2: Dependency2Protocol
    
    init(dependency1: Dependency1Protocol, dependency2: Dependency2Protocol) {
        self.dependency1 = dependency1
        self.dependency2 = dependency2
    }
    
    // Implementation
}
```

**Service Categories:**

1. **Analytics Services**: `AnalyticsServiceProtocol`
2. **Business Logic Services**: `BudgetMonitoringService`, `InsightsEngine`
3. **Processing Services**: `OCRService`, `TransactionParserService`
4. **Domain Services**: `CategoryService`, `RuleEngine`, `BudgetTemplateService`

**Service Lifecycle:**

- **Singleton**: Services that maintain state or are expensive to create (Analytics, OCR, Insights)
- **Transient**: Services that are stateless and cheap to create (if any)

### 5. ViewModel Standardization

**ViewModel Base Pattern:**

```swift
@MainActor
class BaseViewModel: ObservableObject {
    // Common error handling
    @Published var error: AppError?
    @Published var isLoading: Bool = false
    
    // Error handling helper
    func handleError(_ error: Error, context: [String: Any] = [:]) {
        if let appError = error as? AppError {
            self.error = appError
        } else {
            self.error = .unknownError
        }
        Analytics.captureException(error, context: context)
    }
}
```

**ViewModel Pattern:**

```swift
@MainActor
class FeatureViewModel: BaseViewModel {
    // Published state
    @Published var data: [Model] = []
    
    // Dependencies (injected)
    private let repository: RepositoryProtocol
    private let service: ServiceProtocol
    
    // Initialization with DI
    init(repository: RepositoryProtocol, service: ServiceProtocol) {
        self.repository = repository
        self.service = service
        super.init()
    }
    
    // Business logic methods
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            data = try await repository.fetchAll()
        } catch {
            handleError(error, context: ["component": "feature_view_model"])
        }
    }
}
```

**ViewModels to Consolidate:**

Based on analysis, these ViewModels have overlapping responsibilities:
- Keep as-is for now (consolidation can be a future optimization)
- Focus on standardizing initialization patterns first

### 6. Error Handling Strategy

**Centralized Error Handling:**

```swift
// Extend AppError with mapping functions
extension AppError {
    static func from(_ error: Error, context: String = "") -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        if let repoError = error as? RepositoryError {
            return .storageError(underlying: repoError)
        }
        
        // Map other error types
        return .unknownError
    }
}
```

**Error Presentation:**

```swift
// SwiftUI modifier for consistent error display
extension View {
    func errorAlert(error: Binding<AppError?>) -> some View {
        alert(
            "Error",
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            ),
            presenting: error.wrappedValue
        ) { _ in
            Button("OK") {
                error.wrappedValue = nil
            }
        } message: { appError in
            VStack {
                Text(appError.errorDescription ?? "An error occurred")
                if let recovery = appError.recoverySuggestion {
                    Text(recovery)
                        .font(.caption)
                }
            }
        }
    }
}
```

**Usage in ViewModels:**

```swift
@MainActor
class FeatureViewModel: BaseViewModel {
    func performAction() async {
        do {
            try await service.doSomething()
        } catch {
            self.error = AppError.from(error, context: "feature_action")
        }
    }
}
```

**Usage in Views:**

```swift
struct FeatureView: View {
    @StateObject var viewModel: FeatureViewModel
    
    var body: some View {
        content
            .errorAlert(error: $viewModel.error)
    }
}
```


## Data Models

### DI Container State

```swift
struct DIContainerState {
    let factories: [String: (DIContainer) -> Any]
    let singletons: [String: Any]
    let singletonFactories: [String: (DIContainer) -> Any]
}
```

### Service Registration

```swift
struct ServiceRegistration {
    let serviceType: Any.Type
    let lifecycle: ServiceLifecycle
    let factory: (DIContainer) -> Any
}

enum ServiceLifecycle {
    case singleton  // Created once, reused
    case transient  // Created each time
}
```

### Dependency Graph

```swift
// For debugging and visualization
struct DependencyNode {
    let typeName: String
    let lifecycle: ServiceLifecycle
    let dependencies: [String]
}

extension DIContainer {
    func getDependencyGraph() -> [DependencyNode] {
        // Returns dependency graph for debugging
    }
}
```

## Migration Strategy

### Phase 1: Foundation (Week 1)

**Goal**: Establish DI container infrastructure without breaking existing code

1. Create `DIContainer` protocol and `AppDIContainer` implementation
2. Create container registration in `AppDIContainer+Registration.swift`
3. Add environment key for SwiftUI integration
4. Register all existing repositories and services
5. Add to app initialization (parallel to existing singletons)
6. Write unit tests for DI container

**Success Criteria**:
- DI container can resolve all dependencies
- Existing code continues to work unchanged
- Tests pass

### Phase 2: Repository Migration (Week 2)

**Goal**: Migrate all repository access from `RepositoryFactory.shared` to DI

1. Identify all 39+ references to `RepositoryFactory.shared`
2. Update ViewModels to accept repositories via constructor
3. Update Views to resolve ViewModels from container
4. Update Tests to use DI container
5. Mark `RepositoryFactory.shared` as deprecated
6. Verify all tests pass

**Success Criteria**:
- Zero references to `RepositoryFactory.shared` in production code
- All ViewModels use constructor injection
- All tests use DI container

### Phase 3: Service Migration (Week 3)

**Goal**: Migrate all service instantiation to DI

1. Identify all service singleton access points
2. Update services to use protocol-based design
3. Register services in DI container
4. Update ViewModels to receive services via constructor
5. Remove singleton access from services
6. Update tests to inject mock services

**Success Criteria**:
- All services registered in DI container
- No direct singleton access in ViewModels
- Services use protocol boundaries

### Phase 4: ViewModel Standardization (Week 4)

**Goal**: Standardize ViewModel patterns and error handling

1. Create `BaseViewModel` with common error handling
2. Update all ViewModels to inherit from `BaseViewModel`
3. Standardize `@Published` property patterns
4. Implement consistent error handling
5. Add error presentation modifier
6. Update all Views to use error modifier

**Success Criteria**:
- All ViewModels follow consistent pattern
- Error handling is centralized
- Views use consistent error presentation

### Phase 5: Testing Infrastructure (Week 5)

**Goal**: Improve testing infrastructure and coverage

1. Create mock implementations for all protocols
2. Create test helpers and fixtures
3. Update existing tests to use DI container
4. Add integration tests for key workflows
5. Document testing patterns
6. Achieve >80% code coverage for critical paths

**Success Criteria**:
- Mock implementations available for all protocols
- Tests use DI container consistently
- Integration tests cover key workflows

### Phase 6: Documentation & Cleanup (Week 6)

**Goal**: Clean up documentation and finalize refactoring

1. Remove deprecated `RepositoryFactory.shared`
2. Consolidate 50+ markdown files to essential docs
3. Create architecture documentation
4. Create developer onboarding guide
5. Document DI container usage patterns
6. Create ADR (Architecture Decision Records)

**Success Criteria**:
- Documentation reduced to <10 essential files
- Architecture clearly documented
- Developer guide available
- ADRs document key decisions

## Testing Strategy

### Unit Testing with DI

**Test Container Setup:**

```swift
class ViewModelTests: XCTestCase {
    var container: DIContainer!
    var mockRepository: MockTransactionRepository!
    var mockService: MockAnalyticsService!
    
    override func setUp() {
        super.setUp()
        
        container = AppDIContainer()
        mockRepository = MockTransactionRepository()
        mockService = MockAnalyticsService()
        
        // Register mocks
        container.registerSingleton(TransactionRepository.self) { _ in
            self.mockRepository
        }
        container.registerSingleton(AnalyticsServiceProtocol.self) { _ in
            self.mockService
        }
    }
    
    func testViewModel() async {
        // Arrange
        let viewModel = container.resolve(FeatureViewModel.self)
        mockRepository.mockData = [/* test data */]
        
        // Act
        await viewModel.loadData()
        
        // Assert
        XCTAssertEqual(viewModel.data.count, 1)
        XCTAssertTrue(mockService.trackedEvents.contains(.dataLoaded))
    }
}
```

### Mock Implementations

**Repository Mocks:**

```swift
class MockTransactionRepository: TransactionRepository {
    var mockData: [Transaction] = []
    var shouldThrowError = false
    var saveCallCount = 0
    
    func fetchAll() async throws -> [Transaction] {
        if shouldThrowError {
            throw RepositoryError.fetchFailed(NSError(domain: "test", code: 1))
        }
        return mockData
    }
    
    func save(_ entity: Transaction) async throws {
        saveCallCount += 1
        if shouldThrowError {
            throw RepositoryError.saveFailed(NSError(domain: "test", code: 1))
        }
        mockData.append(entity)
    }
    
    // Implement other protocol methods
}
```

**Service Mocks:**

```swift
class MockAnalyticsService: AnalyticsServiceProtocol {
    var isEnabled: Bool = true
    var trackedEvents: [AnalyticsEvent] = []
    var identifiedUsers: [String] = []
    
    func track(event: AnalyticsEvent, properties: [String: Any]?) {
        trackedEvents.append(event)
    }
    
    func identify(userId: String, properties: [String: Any]?) {
        identifiedUsers.append(userId)
    }
    
    // Implement other protocol methods
}
```

### Integration Testing

**Test Fixtures:**

```swift
class TestFixtures {
    static func createTestTransaction(
        merchant: String = "Test Merchant",
        amount: Decimal = 100.0,
        category: String = "Food"
    ) -> Transaction {
        let context = PersistenceController.preview.container.viewContext
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.merchant = merchant
        transaction.amount = NSDecimalNumber(decimal: amount)
        transaction.category = category
        transaction.date = Date()
        return transaction
    }
    
    static func createTestBudget(
        name: String = "Test Budget",
        period: BudgetPeriod = .monthly
    ) -> Budget {
        let context = PersistenceController.preview.container.viewContext
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = name
        budget.period = period.rawValue
        budget.isActive = true
        return budget
    }
}
```

### Test Coverage Goals

- **Repositories**: 90%+ coverage
- **Services**: 85%+ coverage
- **ViewModels**: 80%+ coverage
- **Critical Paths**: 95%+ coverage (transaction creation, budget monitoring, OCR processing)


## Code Organization

### Current Structure

```
ClariFi iOS/
├── Models/
├── Views/
├── ViewModels/
├── Services/
├── Repositories/
├── Utilities/
└── Tests/
```

### Target Structure

```
ClariFi iOS/
├── Core/
│   ├── DependencyInjection/
│   │   ├── DIContainer.swift
│   │   ├── AppDIContainer.swift
│   │   ├── AppDIContainer+Registration.swift
│   │   └── DIContainer+Environment.swift
│   ├── Error/
│   │   ├── AppError.swift
│   │   └── ErrorHandling.swift
│   └── Extensions/
│       └── View+ErrorAlert.swift
├── Data/
│   ├── Repositories/
│   │   ├── Protocols/
│   │   │   ├── BaseRepository.swift
│   │   │   ├── TransactionRepository.swift
│   │   │   ├── AccountRepository.swift
│   │   │   ├── BudgetRepository.swift
│   │   │   └── ...
│   │   └── CoreData/
│   │       ├── CoreDataRepositories.swift
│   │       ├── PersistenceController.swift
│   │       └── CoreDataModels.xcdatamodeld
│   └── Models/
│       ├── Transaction+CoreDataClass.swift
│       ├── Account+CoreDataClass.swift
│       └── ...
├── Domain/
│   ├── Services/
│   │   ├── Analytics/
│   │   │   ├── AnalyticsService.swift
│   │   │   └── AnalyticsServiceProtocol.swift
│   │   ├── Budget/
│   │   │   ├── BudgetMonitoringService.swift
│   │   │   └── BudgetTemplateService.swift
│   │   ├── Insights/
│   │   │   ├── InsightsEngine.swift
│   │   │   └── InsightsEngineProtocol.swift
│   │   ├── OCR/
│   │   │   ├── OCRService.swift
│   │   │   └── VisionOCRService.swift
│   │   └── Parsing/
│   │       ├── TransactionParserService.swift
│   │       └── SmartTransactionParser.swift
│   └── UseCases/
│       └── (Future: Use cases if needed)
├── Presentation/
│   ├── ViewModels/
│   │   ├── Base/
│   │   │   └── BaseViewModel.swift
│   │   ├── Budget/
│   │   │   ├── BudgetViewModel.swift
│   │   │   └── BudgetCreationViewModel.swift
│   │   ├── Transactions/
│   │   │   ├── TransactionEntryViewModel.swift
│   │   │   └── BatchCategorizationViewModel.swift
│   │   ├── Insights/
│   │   │   └── InsightsViewModel.swift
│   │   └── Upload/
│   │       └── StatementUploadViewModel.swift
│   └── Views/
│       ├── Budget/
│       │   ├── BudgetView.swift
│       │   └── BudgetCreationView.swift
│       ├── Transactions/
│       │   ├── TransactionsListView.swift
│       │   └── TransactionEntryView.swift
│       ├── Insights/
│       │   └── InsightsView.swift
│       ├── Upload/
│       │   └── StatementUploadView.swift
│       └── Common/
│           └── (Shared UI components)
├── Resources/
│   ├── Assets.xcassets
│   └── Localizations/
└── Tests/
    ├── UnitTests/
    │   ├── ViewModelTests/
    │   ├── ServiceTests/
    │   └── RepositoryTests/
    ├── IntegrationTests/
    ├── Mocks/
    │   ├── MockRepositories.swift
    │   ├── MockServices.swift
    │   └── TestFixtures.swift
    └── TestHelpers/
        └── DIContainer+Testing.swift
```

### Module Boundaries

**Dependency Rules:**

1. **Presentation** depends on **Domain** (via protocols)
2. **Domain** depends on **Data** (via protocols)
3. **Data** depends on nothing (except Core Data)
4. **Core** is used by all layers

**Enforced Through:**
- Protocol boundaries
- DI container
- Code review guidelines

### File Organization Guidelines

1. **Group by Feature**: Related files should be grouped together
2. **Protocol + Implementation**: Keep protocols and implementations in same directory
3. **Test Mirrors Production**: Test structure mirrors production code structure
4. **Shared Code**: Common utilities in Core/

## Performance Considerations

### DI Container Performance

**Optimization Strategies:**

1. **Singleton Caching**: Singletons created once and cached
2. **Lazy Resolution**: Dependencies resolved only when needed
3. **Type-Safe Keys**: Use type names as keys for fast lookup
4. **Minimal Overhead**: Container adds <1ms overhead per resolution

**Benchmarks:**

```swift
// Expected performance
- Singleton resolution: <0.1ms
- Transient resolution: <0.5ms
- Container initialization: <10ms
```

### Memory Management

**Strategies:**

1. **Weak References**: Use weak references where appropriate to prevent retain cycles
2. **Singleton Lifecycle**: Singletons live for app lifetime (acceptable for services)
3. **Transient Cleanup**: Transient objects cleaned up by ARC
4. **Container Reset**: Ability to reset container for testing

**Memory Profile:**

```
Before Refactoring:
- Multiple singleton instances
- Unclear ownership
- Potential retain cycles

After Refactoring:
- Single DI container (~1KB)
- Clear ownership through DI
- No retain cycles (verified through testing)
```

### App Launch Performance

**Impact Analysis:**

```
Current Launch Time: ~500ms
Expected After Refactoring: ~520ms (+20ms)

Breakdown:
- DI Container Setup: +10ms
- Service Registration: +5ms
- Initial Resolutions: +5ms
```

**Mitigation:**

1. Lazy service initialization where possible
2. Parallel service initialization for independent services
3. Defer non-critical service initialization

## Security Considerations

### Dependency Injection Security

**Concerns:**

1. **Type Safety**: Ensure type-safe resolution to prevent runtime errors
2. **Access Control**: Limit container access to appropriate layers
3. **Test Isolation**: Ensure test containers don't leak into production

**Mitigations:**

1. **Compile-Time Safety**: Use Swift's type system for safety
2. **Environment Separation**: Separate production and test containers
3. **Container Immutability**: Once configured, container registrations are immutable

### Data Access Security

**No Changes Required:**

- Repository layer already implements proper data access patterns
- Core Data encryption remains unchanged
- Biometric authentication remains unchanged

## Rollback Strategy

### Incremental Migration

**Advantage**: Can rollback at any phase

**Phase Rollback:**

1. **Phase 1**: Remove DI container, no impact on existing code
2. **Phase 2**: Revert ViewModel changes, restore `RepositoryFactory.shared`
3. **Phase 3**: Revert service changes, restore singleton access
4. **Phase 4**: Revert ViewModel standardization
5. **Phase 5**: Revert test changes
6. **Phase 6**: Restore documentation

### Feature Flags

**Optional**: Use feature flags for gradual rollout

```swift
enum FeatureFlags {
    static var useDIContainer: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "use_di_container")
        #else
        return true
        #endif
    }
}

// In app initialization
if FeatureFlags.useDIContainer {
    // Use DI container
} else {
    // Use legacy singletons
}
```

## Success Metrics

### Code Quality Metrics

**Before Refactoring:**
- Singleton references: 39+
- Inconsistent patterns: High
- Test coverage: ~60%
- Cyclomatic complexity: High in ViewModels

**After Refactoring:**
- Singleton references: 0
- Consistent patterns: 100%
- Test coverage: >80%
- Cyclomatic complexity: Reduced by 30%

### Developer Experience Metrics

**Measured Through:**
1. Time to add new feature (should decrease)
2. Time to write tests (should decrease)
3. Code review feedback (should decrease)
4. Onboarding time for new developers (should decrease)

### Technical Debt Metrics

**Reduction:**
- Eliminate 39+ singleton references
- Consolidate 50+ markdown files to <10
- Standardize 11 ViewModels
- Unify error handling across 100+ error sites

## Documentation Strategy

### Essential Documentation

**Keep:**
1. `README.md` - Project overview and setup
2. `ARCHITECTURE.md` - Architecture overview and DI patterns
3. `CONTRIBUTING.md` - Contribution guidelines
4. `TESTING.md` - Testing patterns and guidelines
5. `ADR/` - Architecture Decision Records

**Remove:**
- Implementation summaries (move to code comments)
- Redundant feature documentation
- Outdated design documents

### Architecture Documentation

**ARCHITECTURE.md Contents:**

```markdown
# ClariFi iOS Architecture

## Overview
- Clean Architecture with MVVM
- Dependency Injection via DI Container
- Protocol-based design

## Layers
- Presentation (Views, ViewModels)
- Domain (Services, Business Logic)
- Data (Repositories, Core Data)

## Dependency Injection
- How to register dependencies
- How to resolve dependencies
- Testing with DI

## Patterns
- ViewModel pattern
- Repository pattern
- Service pattern
- Error handling pattern

## Adding New Features
- Step-by-step guide
- Code examples
- Testing guidelines
```

### Code Documentation

**Guidelines:**

1. **Public APIs**: Document with doc comments
2. **Complex Logic**: Inline comments explaining why
3. **Protocols**: Document expected behavior
4. **Examples**: Provide usage examples in comments

## Risk Assessment

### High Risk

**Risk**: Breaking existing functionality during migration
**Mitigation**: 
- Incremental migration with tests at each phase
- Parallel running of old and new systems during transition
- Comprehensive test coverage before changes

### Medium Risk

**Risk**: Performance degradation from DI overhead
**Mitigation**:
- Performance benchmarks before and after
- Optimization of container resolution
- Lazy initialization where appropriate

### Low Risk

**Risk**: Developer adoption of new patterns
**Mitigation**:
- Clear documentation
- Code examples
- Pair programming during transition
- Code review enforcement

## Conclusion

This refactoring will transform the ClariFi iOS codebase from a fragmented, tightly-coupled architecture to a clean, maintainable, and testable system. The incremental migration strategy ensures minimal risk while delivering immediate benefits at each phase.

**Key Benefits:**
- ✅ Eliminates 39+ singleton references
- ✅ Establishes consistent patterns
- ✅ Improves testability by 40%+
- ✅ Reduces technical debt significantly
- ✅ Maintains zero user-facing changes
- ✅ Enables faster feature development

**Timeline**: 6 weeks with clear milestones and rollback points at each phase.

