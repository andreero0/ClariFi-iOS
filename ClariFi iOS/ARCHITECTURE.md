# ClariFi iOS Architecture

## Overview

ClariFi iOS follows a clean architecture pattern with dependency injection, clear layer separation, and consistent patterns throughout the codebase. The architecture prioritizes testability, maintainability, and scalability while maintaining a straightforward MVVM pattern for the presentation layer.

### Key Principles

- **Dependency Injection**: All dependencies are managed through a centralized DI container
- **Protocol-Oriented Design**: Components interact through protocols, not concrete implementations
- **Unidirectional Data Flow**: Data flows from repositories → services → ViewModels → Views
- **Separation of Concerns**: Clear boundaries between Data, Domain, and Presentation layers
- **Testability First**: All components are designed to be easily testable with mock implementations

### Architecture Diagram

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

## Layer Architecture

### Core Layer

The Core layer contains infrastructure code that supports all other layers.

**Components:**
- **DI Container**: Manages dependency registration and resolution
- **Error Handling**: Centralized error types and handling utilities
- **Extensions**: Shared extensions for SwiftUI and Foundation types

**Key Files:**
- `Core/DependencyInjection/DIContainer.swift` - DI container protocol
- `Core/DependencyInjection/AppDIContainer.swift` - DI container implementation
- `Core/DependencyInjection/AppDIContainer+Registration.swift` - Dependency registration
- `Core/DependencyInjection/DIContainer+Environment.swift` - SwiftUI environment integration
- `Core/Extensions/View+ErrorAlert.swift` - Error presentation modifier
- `Models/AppError.swift` - Application error types

### Data Layer

The Data layer handles data persistence and retrieval through repositories.

**Responsibilities:**
- Core Data entity management
- CRUD operations
- Data validation
- Query optimization

**Components:**
- **Repository Protocols**: Define data access interfaces
- **Core Data Repositories**: Implement data access using Core Data
- **Core Data Models**: Entity definitions and relationships

**Key Files:**
- `Repositories/RepositoryProtocols.swift` - Repository protocol definitions
- `Repositories/CoreDataRepositories.swift` - Core Data implementations
- `Repositories/RepositoryFactory.swift` - Factory for creating repositories (used by DI container)
- `Persistence.swift` - Core Data stack setup

**Repository Pattern:**

```swift
// Protocol definition
protocol TransactionRepository: BaseRepository where Entity == Transaction {
    func fetchByDateRange(_ startDate: Date, _ endDate: Date) async throws -> [Transaction]
    func fetchByAccount(_ account: Account) async throws -> [Transaction]
    func fetchByCategory(_ category: String) async throws -> [Transaction]
}

// Core Data implementation
class CoreDataTransactionRepository: CoreDataRepository<Transaction>, TransactionRepository {
    func fetchByDateRange(_ startDate: Date, _ endDate: Date) async throws -> [Transaction] {
        let request = Transaction.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        return try await fetch(request)
    }
}
```

### Domain Layer

The Domain layer contains business logic and domain services.

**Responsibilities:**
- Business rule enforcement
- Complex calculations and algorithms
- Cross-entity operations
- Analytics and insights generation

**Components:**
- **Business Services**: Budget monitoring, insights generation, categorization
- **Processing Services**: OCR, transaction parsing, rule engine
- **Integration Services**: Analytics, notifications

**Key Files:**
- `Services/BudgetMonitoringService.swift` - Budget tracking and alerts
- `Services/InsightsEngine.swift` - Financial insights generation
- `Services/CategoryService.swift` - Transaction categorization
- `Services/RuleEngine.swift` - Categorization rules
- `Services/OCRService.swift` - OCR protocol
- `Services/VisionOCRService.swift` - Vision framework OCR implementation
- `Services/TransactionParserService.swift` - Transaction parsing protocol
- `Services/SmartTransactionParser.swift` - Smart parsing implementation
- `Services/AnalyticsService.swift` - Analytics tracking
- `Services/BudgetTemplateService.swift` - Budget template management

**Service Pattern:**

```swift
// Protocol definition
protocol InsightsEngineProtocol {
    func generateInsights(for period: DateInterval) async throws -> [Insight]
    func analyzeSpendingPatterns() async throws -> SpendingAnalysis
}

// Implementation with injected dependencies
class InsightsEngine: InsightsEngineProtocol {
    private let transactionRepository: TransactionRepository
    private let budgetRepository: BudgetRepository
    private let context: NSManagedObjectContext
    
    init(
        transactionRepository: TransactionRepository,
        budgetRepository: BudgetRepository,
        context: NSManagedObjectContext
    ) {
        self.transactionRepository = transactionRepository
        self.budgetRepository = budgetRepository
        self.context = context
    }
    
    func generateInsights(for period: DateInterval) async throws -> [Insight] {
        // Business logic implementation
    }
}
```

### Presentation Layer

The Presentation layer handles UI and user interactions.

**Responsibilities:**
- UI rendering
- User input handling
- State management
- Navigation

**Components:**
- **ViewModels**: Presentation logic and state management
- **Views**: SwiftUI view components
- **Base Classes**: Shared ViewModel functionality

**Key Files:**
- `Presentation/ViewModels/Base/BaseViewModel.swift` - Base ViewModel with common patterns
- `ViewModels/BudgetViewModel.swift` - Budget management
- `ViewModels/InsightsViewModel.swift` - Insights display
- `ViewModels/StatementUploadViewModel.swift` - Statement upload workflow
- `ViewModels/TransactionEntryViewModel.swift` - Transaction entry
- `Views/` - All SwiftUI views

## Dependency Injection

### DI Container

The DI container manages all application dependencies with support for singleton and transient lifecycles.

**Container Protocol:**

```swift
protocol DIContainer {
    // Registration
    func register<T>(_ type: T.Type, factory: @escaping (DIContainer) -> T)
    func registerSingleton<T>(_ type: T.Type, factory: @escaping (DIContainer) -> T)
    func registerTransient<T>(_ type: T.Type, factory: @escaping (DIContainer) -> T)
    
    // Resolution
    func resolve<T>(_ type: T.Type) -> T
    func resolveOptional<T>(_ type: T.Type) -> T?
    
    // Throwable Resolution (for error handling)
    func resolve<T>(_ type: T.Type) throws -> T
    
    // Lifecycle
    func reset()
}
```

**Error Handling:**

```swift
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
```

**Lifecycle Management:**

- **Singleton**: Created once and cached (repositories, services)
- **Transient**: Created each time resolved (ViewModels, short-lived objects)
- **Regular**: Created on first resolution, then cached (default behavior)

### Dependency Registration

All dependencies are registered in `AppDIContainer+Registration.swift`:

```swift
extension AppDIContainer {
    static func createProductionContainer() -> DIContainer {
        let container = AppDIContainer()
        let context = PersistenceController.shared.container.viewContext
        
        // Register Repositories (Singleton)
        container.registerSingleton(TransactionRepository.self) { _ in
            CoreDataTransactionRepository(context: context)
        }
        
        // Register Services (Singleton)
        container.registerSingleton(InsightsEngineProtocol.self) { _ in
            InsightsEngine(context: context)
        }
        
        // Register ViewModels (Transient - new instance each time)
        container.registerTransient(BudgetViewModel.self) { c in
            BudgetViewModel(
                budgetRepository: c.resolve(BudgetRepository.self),
                budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
                transactionRepository: c.resolve(TransactionRepository.self),
                context: context
            )
        }
        
        return container
    }
}
```

**Service Instantiation Patterns:**

All services are instantiated through the DI container - no singleton patterns (`.shared`) are used alongside DI. This ensures:
- Single source of truth for all service instances
- Consistent data across the application
- Testability with mock implementations
- Proper lifecycle management

### SwiftUI Integration

The DI container is integrated with SwiftUI through environment values:

```swift
// Environment key
private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainer = AppDIContainer.createProductionContainer()
}

extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}

// Usage in app initialization
@main
struct ClariFi_iOSApp: App {
    let container = AppDIContainer.createProductionContainer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.diContainer, container)
        }
    }
}
```

### Resolving Dependencies in Views

Views resolve ViewModels from the DI container:

```swift
struct BudgetView: View {
    @Environment(\.diContainer) private var container
    @StateObject private var viewModel: BudgetViewModel
    
    init() {
        // Note: Cannot access environment in init
        // Use a factory pattern instead
    }
}

// Better pattern - resolve in parent view
struct MainTabView: View {
    @Environment(\.diContainer) private var container
    
    var body: some View {
        TabView {
            BudgetView(viewModel: container.resolve(BudgetViewModel.self))
                .tabItem { Label("Budget", systemImage: "chart.pie") }
        }
    }
}
```

## ViewModel Patterns

### BaseViewModel

All ViewModels inherit from `BaseViewModel` which provides common functionality:

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

**Features:**
- Centralized error handling
- Loading state management
- Analytics integration
- Thread safety with `@MainActor`

### ViewModel Structure

Standard ViewModel pattern:

```swift
@MainActor
class FeatureViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var items: [Item] = []
    @Published var selectedItem: Item?
    
    // MARK: - Dependencies (Private)
    private let repository: ItemRepository
    private let service: ItemService
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    init(
        repository: ItemRepository,
        service: ItemService,
        context: NSManagedObjectContext
    ) {
        self.repository = repository
        self.service = service
        self.context = context
        super.init()
    }
    
    // MARK: - Public Methods
    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await repository.fetchAll()
        } catch {
            handleError(error, context: ["action": "load_items"])
        }
    }
    
    func saveItem(_ item: Item) async {
        do {
            try await repository.save(item)
            await loadItems() // Refresh
        } catch {
            handleError(error, context: ["action": "save_item"])
        }
    }
}
```

### ViewModel Conventions

1. **Always use `@MainActor`**: Ensures UI updates happen on main thread
2. **Inherit from `BaseViewModel`**: Provides consistent error handling
3. **Constructor injection**: All dependencies injected via initializer
4. **Private dependencies**: Dependencies are private, not exposed to views
5. **Published state**: Use `@Published` for all observable state
6. **Async methods**: Use async/await for asynchronous operations
7. **Error handling**: Use `handleError()` for all errors
8. **Loading states**: Set `isLoading` for long-running operations

## Error Handling

### AppError Enum

Centralized error type for the application:

```swift
enum AppError: Error, LocalizedError {
    case storageError(underlying: Error)
    case networkError(underlying: Error)
    case validationError(message: String)
    case ocrError(message: String)
    case parsingError(message: String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .storageError:
            return "Failed to save or retrieve data"
        case .networkError:
            return "Network connection failed"
        case .validationError(let message):
            return message
        case .ocrError(let message):
            return "OCR failed: \(message)"
        case .parsingError(let message):
            return "Parsing failed: \(message)"
        case .unknownError:
            return "An unexpected error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .storageError:
            return "Please try again or restart the app"
        case .networkError:
            return "Check your internet connection"
        case .validationError:
            return "Please check your input and try again"
        default:
            return nil
        }
    }
}
```

### Error Handling in ViewModels

ViewModels use the `handleError()` method from `BaseViewModel`:

```swift
func performAction() async {
    do {
        try await service.doSomething()
    } catch {
        handleError(error, context: ["action": "perform_action", "user_id": userId])
    }
}
```

### Error Presentation in Views

Views use the `.errorAlert()` modifier for consistent error display:

```swift
struct FeatureView: View {
    @StateObject var viewModel: FeatureViewModel
    
    var body: some View {
        content
            .errorAlert(error: $viewModel.error)
    }
}
```

The error alert modifier is defined in `Core/Extensions/View+ErrorAlert.swift`:

```swift
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
            Button("OK") { error.wrappedValue = nil }
        } message: { appError in
            VStack {
                Text(appError.errorDescription ?? "An error occurred")
                if let recovery = appError.recoverySuggestion {
                    Text(recovery).font(.caption)
                }
            }
        }
    }
}
```

## State Management

### State Ownership Patterns

ClariFi uses SwiftUI's property wrappers consistently:

**`@StateObject`** - For ViewModels owned by the view:
```swift
struct BudgetView: View {
    @StateObject private var viewModel: BudgetViewModel
    
    init(viewModel: BudgetViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
}
```

**`@ObservedObject`** - For ViewModels passed from parent:
```swift
struct BudgetDetailView: View {
    @ObservedObject var viewModel: BudgetViewModel
    
    var body: some View {
        // View uses viewModel but doesn't own it
    }
}
```

**`@EnvironmentObject`** - For app-wide shared state:
```swift
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
}
```

**`@AppStorage`** - For simple user preferences:
```swift
struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
}
```

### Data Flow

ClariFi follows unidirectional data flow:

```
User Action → View → ViewModel → Service/Repository → Core Data
                ↑                                          ↓
                └──────────── @Published ←─────────────────┘
```

1. User interacts with View
2. View calls ViewModel method
3. ViewModel calls Service or Repository
4. Service/Repository updates Core Data
5. Core Data changes trigger repository updates
6. Repository returns updated data
7. ViewModel updates `@Published` properties
8. View automatically re-renders

## Testing Patterns

### Test Container Setup

Create a test container with mock dependencies:

```swift
extension AppDIContainer {
    static func createTestContainer() -> DIContainer {
        let container = AppDIContainer()
        let context = PersistenceController.preview.container.viewContext
        
        // Register mock repositories
        container.registerSingleton(TransactionRepository.self) { _ in
            MockTransactionRepository()
        }
        
        // Register mock services
        container.registerSingleton(AnalyticsServiceProtocol.self) { _ in
            MockAnalyticsService()
        }
        
        return container
    }
}
```

### Unit Testing ViewModels

Test ViewModels with injected mocks:

```swift
@MainActor
class BudgetViewModelTests: XCTestCase {
    var container: DIContainer!
    var mockBudgetRepo: MockBudgetRepository!
    var mockTransactionRepo: MockTransactionRepository!
    var viewModel: BudgetViewModel!
    
    override func setUp() {
        super.setUp()
        
        // Create test container
        container = AppDIContainer()
        mockBudgetRepo = MockBudgetRepository()
        mockTransactionRepo = MockTransactionRepository()
        
        // Register mocks
        container.registerSingleton(BudgetRepository.self) { _ in
            self.mockBudgetRepo
        }
        container.registerSingleton(TransactionRepository.self) { _ in
            self.mockTransactionRepo
        }
        
        // Create ViewModel with mocks
        viewModel = BudgetViewModel(
            budgetRepository: mockBudgetRepo,
            budgetCategoryRepository: MockBudgetCategoryRepository(),
            transactionRepository: mockTransactionRepo,
            context: PersistenceController.preview.container.viewContext
        )
    }
    
    func testLoadBudgets() async {
        // Arrange
        let testBudget = createTestBudget(name: "Test Budget")
        mockBudgetRepo.mockBudgets = [testBudget]
        
        // Act
        await viewModel.loadBudgets()
        
        // Assert
        XCTAssertEqual(viewModel.budgets.count, 1)
        XCTAssertEqual(viewModel.budgets.first?.name, "Test Budget")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testLoadBudgetsError() async {
        // Arrange
        mockBudgetRepo.shouldThrowError = true
        
        // Act
        await viewModel.loadBudgets()
        
        // Assert
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

### Mock Implementations

Create mock implementations for all protocols:

```swift
class MockTransactionRepository: TransactionRepository {
    var mockTransactions: [Transaction] = []
    var shouldThrowError = false
    var saveCallCount = 0
    
    func fetchAll() async throws -> [Transaction] {
        if shouldThrowError {
            throw RepositoryError.fetchFailed(NSError(domain: "test", code: 1))
        }
        return mockTransactions
    }
    
    func save(_ entity: Transaction) async throws {
        saveCallCount += 1
        if shouldThrowError {
            throw RepositoryError.saveFailed(NSError(domain: "test", code: 1))
        }
        mockTransactions.append(entity)
    }
    
    func delete(_ entity: Transaction) async throws {
        if shouldThrowError {
            throw RepositoryError.deleteFailed(NSError(domain: "test", code: 1))
        }
        mockTransactions.removeAll { $0.id == entity.id }
    }
}
```

### Integration Testing

Test complete workflows with real Core Data:

```swift
class WorkflowIntegrationTests: XCTestCase {
    var container: DIContainer!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        
        // Use in-memory Core Data for testing
        context = PersistenceController.preview.container.viewContext
        container = AppDIContainer.createProductionContainer()
    }
    
    func testTransactionCreationWorkflow() async throws {
        // Arrange
        let transactionRepo = container.resolve(TransactionRepository.self)
        let accountRepo = container.resolve(AccountRepository.self)
        
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        try await accountRepo.save(account)
        
        // Act
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.merchant = "Test Merchant"
        transaction.amount = NSDecimalNumber(value: 100.0)
        transaction.date = Date()
        transaction.account = account
        
        try await transactionRepo.save(transaction)
        
        // Assert
        let savedTransactions = try await transactionRepo.fetchAll()
        XCTAssertEqual(savedTransactions.count, 1)
        XCTAssertEqual(savedTransactions.first?.merchant, "Test Merchant")
    }
}
```

### Test Fixtures

Create reusable test data:

```swift
extension XCTestCase {
    func createTestTransaction(
        merchant: String = "Test Merchant",
        amount: Decimal = 100.0,
        category: String = "Food",
        context: NSManagedObjectContext
    ) -> Transaction {
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.merchant = merchant
        transaction.amount = NSDecimalNumber(decimal: amount)
        transaction.category = category
        transaction.date = Date()
        return transaction
    }
    
    func createTestBudget(
        name: String = "Test Budget",
        period: BudgetPeriod = .monthly,
        context: NSManagedObjectContext
    ) -> Budget {
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.name = name
        budget.period = period.rawValue
        budget.isActive = true
        return budget
    }
}
```

## Adding New Features

### Step-by-Step Guide

Follow this pattern when adding new features to ClariFi:

#### 1. Define Repository Protocol (if needed)

```swift
// In Repositories/RepositoryProtocols.swift
protocol NewFeatureRepository: BaseRepository where Entity == NewFeature {
    func fetchByCustomCriteria(_ criteria: String) async throws -> [NewFeature]
}
```

#### 2. Implement Repository

```swift
// In Repositories/CoreDataRepositories.swift
class CoreDataNewFeatureRepository: CoreDataRepository<NewFeature>, NewFeatureRepository {
    func fetchByCustomCriteria(_ criteria: String) async throws -> [NewFeature] {
        let request = NewFeature.fetchRequest()
        request.predicate = NSPredicate(format: "criteria == %@", criteria)
        return try await fetch(request)
    }
}
```

#### 3. Create Service (if needed)

```swift
// In Services/NewFeatureService.swift
protocol NewFeatureServiceProtocol {
    func processFeature(_ input: Input) async throws -> Output
}

class NewFeatureService: NewFeatureServiceProtocol {
    private let repository: NewFeatureRepository
    private let otherService: OtherServiceProtocol
    
    init(repository: NewFeatureRepository, otherService: OtherServiceProtocol) {
        self.repository = repository
        self.otherService = otherService
    }
    
    func processFeature(_ input: Input) async throws -> Output {
        // Business logic
        let data = try await repository.fetchByCustomCriteria(input.criteria)
        return try await otherService.process(data)
    }
}
```

#### 4. Create ViewModel

```swift
// In ViewModels/NewFeatureViewModel.swift
@MainActor
class NewFeatureViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var items: [NewFeature] = []
    @Published var selectedItem: NewFeature?
    
    // MARK: - Dependencies
    private let repository: NewFeatureRepository
    private let service: NewFeatureServiceProtocol
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    init(
        repository: NewFeatureRepository,
        service: NewFeatureServiceProtocol,
        context: NSManagedObjectContext
    ) {
        self.repository = repository
        self.service = service
        self.context = context
        super.init()
    }
    
    // MARK: - Public Methods
    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await repository.fetchAll()
        } catch {
            handleError(error, context: ["action": "load_items"])
        }
    }
    
    func processItem(_ item: NewFeature) async {
        do {
            let result = try await service.processFeature(item)
            // Handle result
        } catch {
            handleError(error, context: ["action": "process_item"])
        }
    }
}
```

#### 5. Create View

```swift
// In Views/NewFeatureView.swift
struct NewFeatureView: View {
    @StateObject private var viewModel: NewFeatureViewModel
    
    init(viewModel: NewFeatureViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .navigationTitle("New Feature")
        .errorAlert(error: $viewModel.error)
        .task {
            await viewModel.loadItems()
        }
    }
}
```

#### 6. Register Dependencies

```swift
// In Core/DependencyInjection/AppDIContainer+Registration.swift
extension AppDIContainer {
    static func createProductionContainer() -> DIContainer {
        // ... existing registrations ...
        
        // Register new repository
        container.registerSingleton(NewFeatureRepository.self) { _ in
            CoreDataNewFeatureRepository(context: context)
        }
        
        // Register new service
        container.registerSingleton(NewFeatureServiceProtocol.self) { c in
            NewFeatureService(
                repository: c.resolve(NewFeatureRepository.self),
                otherService: c.resolve(OtherServiceProtocol.self)
            )
        }
        
        // Register new ViewModel
        container.register(NewFeatureViewModel.self) { c in
            NewFeatureViewModel(
                repository: c.resolve(NewFeatureRepository.self),
                service: c.resolve(NewFeatureServiceProtocol.self),
                context: context
            )
        }
        
        return container
    }
}
```

#### 7. Add to Navigation

```swift
// In parent view
struct MainTabView: View {
    @Environment(\.diContainer) private var container
    
    var body: some View {
        TabView {
            NewFeatureView(viewModel: container.resolve(NewFeatureViewModel.self))
                .tabItem { Label("New Feature", systemImage: "star") }
        }
    }
}
```

#### 8. Write Tests


## Security and Audit Architecture

### Security Audit Service

The SecurityAuditService logs security events and generates audit reports for compliance and monitoring.

**Storage Mechanism:**
- Audit logs are stored in **UserDefaults** (not Core Data)
- Logs are JSON-encoded for persistence
- Maximum 1000 log entries retained
- Automatic cleanup of logs older than 90 days

**Service Access Pattern:**
- SecurityAuditService is registered in the DI container as a singleton
- No `.shared` singleton pattern used
- All access goes through DI container for consistency
- Ensures single source of truth for audit data

**Example:**

```swift
// Registration in AppDIContainer+Registration.swift
container.registerSingleton(SecurityAuditService.self) { c in
    SecurityAuditService(
        encryptionService: c.resolve(EncryptionService.self),
        secureFileManager: c.resolve(SecureFileManager.self)
    )
}

// Usage in Views (via DI container)
struct SecurityAuditView: View {
    @Environment(\.diContainer) private var container
    
    var body: some View {
        let auditService = container.resolve(SecurityAuditService.self)
        // Use auditService
    }
}
```

**Why UserDefaults for Audit Logs:**
- Simple persistence for small, structured data
- Fast read/write operations
- No Core Data migration complexity
- Suitable for log retention limits (1000 entries max)
- Easy to clear or export

**Data Integrity:**
- Logs are JSON-encoded for reliability
- Automatic trimming prevents unbounded growth
- Periodic cleanup removes old entries
- Integrity checks verify storage health

## Concurrency Architecture

### Actor-Based Caching

ClariFi uses Swift actors for thread-safe caching of expensive-to-create objects like formatters.

**FormatterCache Actor:**

```swift
actor FormatterCache {
    private var formatters: [Currency: NumberFormatter] = [:]
    
    /// Synchronous formatter access (safe for sync contexts)
    func formatterSync(for currency: Currency) -> NumberFormatter {
        // Return cached formatter or create new one
        // Thread safety maintained through actor isolation
        if let cached = formatters[currency] {
            return cached
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: currency.localeIdentifier)
        formatter.currencyCode = currency.rawValue
        formatters[currency] = formatter
        
        return formatter
    }
    
    /// Async formatter access (for async contexts)
    func formatter(for currency: Currency) async -> NumberFormatter {
        return formatterSync(for: currency)
    }
}
```

**Benefits:**
- Thread-safe access to shared formatters
- No data races or synchronization issues
- Performance optimization through caching
- Clean API for both sync and async contexts

### Async Formatter Usage

**CurrencyFormatter Service:**

```swift
class CurrencyFormatter {
    static let shared = CurrencyFormatter()
    private let formatterCache = FormatterCache()
    
    /// Synchronous formatting (most common use case)
    func format(_ amount: Decimal, currency: Currency) -> String {
        let formatter = formatterCache.formatterSync(for: currency)
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency.symbol)\(amount)"
    }
    
    /// Async formatting (for async contexts)
    func formatAsync(_ amount: Decimal, currency: Currency) async -> String {
        let formatter = await formatterCache.formatter(for: currency)
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency.symbol)\(amount)"
    }
}
```

**Usage Patterns:**

```swift
// In synchronous contexts (Views, computed properties)
let formatted = CurrencyFormatter.shared.format(amount, currency: .usd)

// In async contexts (ViewModels, async functions)
let formatted = await CurrencyFormatter.shared.formatAsync(amount, currency: .usd)

// Using CurrencyPreferenceManager
let formatted = CurrencyPreferenceManager.shared.format(amount)  // Uses preferred currency
```

### Background Processing

Heavy computational work is moved off the main actor to prevent UI blocking.

**InsightsEngine Actor:**

```swift
actor InsightsEngine: InsightsEngineProtocol {
    func generateInsights(for transactions: [Transaction], budget: Budget?) async -> [Insight] {
        // Heavy computation runs on background thread via actor isolation
        var insights: [Insight] = []
        
        insights.append(contentsOf: await generateSpendingTrendInsights(transactions))
        insights.append(contentsOf: await generateBudgetAlerts(transactions, budget: budget))
        
        return prioritizeInsights(insights)
    }
}
```

**ViewModel Background Processing:**

```swift
@MainActor
class InsightsViewModel: BaseViewModel {
    func loadInsights() async {
        isLoading = true
        
        // Fetch data on main actor
        let transactions = try await transactionRepository.fetchAll()
        let budget = try await budgetRepository.fetchActiveBudget()
        
        // Move heavy work to background thread
        let insights = await Task.detached { [transactions, budget] in
            await self.insightsEngine.generateInsights(
                for: transactions,
                budget: budget
            )
        }.value
        
        // Publish results on main actor
        self.insights = insights
        isLoading = false
    }
}
```

**Benefits:**
- UI remains responsive during heavy computation
- Main thread not blocked by data processing
- Smooth user experience with large datasets
- Proper separation of concerns

### Concurrency Best Practices

1. **Use actors for shared mutable state**: FormatterCache, InsightsEngine
2. **Mark ViewModels with @MainActor**: Ensures UI updates on main thread
3. **Use Task.detached for heavy work**: Moves computation off main actor
4. **Provide sync and async APIs**: formatterSync() and formatter() for flexibility
5. **Avoid blocking the main actor**: Move data processing to background threads
6. **Use await only in async contexts**: Don't force async in synchronous code

## Code Organization

### Current Project Structure

The ClariFi iOS project follows a pragmatic, flat structure that balances clean architecture principles with Xcode project conventions. While the logical architecture has clear layer separation (Core, Data, Domain, Presentation), the physical file organization prioritizes developer productivity and Xcode compatibility.

```
ClariFi iOS/
├── Core/                           # Infrastructure & Cross-Cutting Concerns
│   ├── DependencyInjection/       # DI Container implementation
│   │   ├── DIContainer.swift      # DI protocol definition
│   │   ├── AppDIContainer.swift   # DI implementation
│   │   ├── AppDIContainer+Registration.swift  # Dependency registration
│   │   └── DIContainer+Environment.swift      # SwiftUI integration
│   └── Extensions/                # Shared extensions
│       ├── View+ErrorAlert.swift  # Error presentation modifier
│       └── View+ErrorAlert+Example.swift  # Usage examples
│
├── Models/                         # Domain Models & Error Types
│   ├── AppError.swift             # Application error definitions
│   └── CoreDataValidation.swift  # Core Data validation utilities
│
├── Repositories/                   # Data Access Layer
│   ├── RepositoryProtocols.swift  # Repository protocol definitions
│   ├── CoreDataRepositories.swift # Core Data implementations
│   └── RepositoryFactory.swift    # Repository factory (used by DI)
│
├── Services/                       # Business Logic & Domain Services
│   ├── AnalyticsService.swift     # Analytics tracking
│   ├── BudgetMonitoringService.swift  # Budget tracking & alerts
│   ├── BudgetTemplateService.swift    # Budget templates
│   ├── CategoryService.swift      # Transaction categorization
│   ├── InsightsEngine.swift       # Financial insights generation
│   ├── RuleEngine.swift           # Categorization rules
│   ├── OCRService.swift           # OCR protocol
│   ├── VisionOCRService.swift     # Vision OCR implementation
│   ├── TransactionParserService.swift  # Parser protocol
│   ├── SmartTransactionParser.swift    # Smart parser implementation
│   ├── StatementPatterns.swift    # Statement parsing patterns
│   ├── BiometricAuthService.swift # Biometric authentication
│   ├── EncryptionService.swift    # Data encryption
│   ├── SecureFileManager.swift    # Secure file operations
│   ├── SecurityAuditService.swift # Security auditing
│   ├── PrivacyManager.swift       # Privacy controls
│   ├── RecurringTransactionService.swift  # Recurring transactions
│   ├── SubscriptionService.swift  # Subscription management
│   ├── CashflowForecastingService.swift   # Cashflow forecasting
│   ├── ScenarioPlanningService.swift      # Financial scenarios
│   ├── InsightNotificationService.swift   # Insight notifications
│   └── ClariFiAppIntents.swift    # App Intents integration (preview mode)
│
├── Presentation/                   # Presentation Layer Base
│   └── ViewModels/
│       └── Base/
│           └── BaseViewModel.swift  # Base ViewModel with common patterns
│
├── ViewModels/                     # Feature ViewModels
│   ├── BudgetViewModel.swift      # Budget management
│   ├── BudgetCreationViewModel.swift  # Budget creation
│   ├── InsightsViewModel.swift    # Insights display
│   ├── StatementUploadViewModel.swift  # Statement upload
│   ├── TransactionEntryViewModel.swift  # Transaction entry
│   ├── TransactionReviewViewModel.swift  # Transaction review
│   ├── BatchCategorizationViewModel.swift  # Batch categorization
│   ├── CategorizationRulesViewModel.swift  # Rule management
│   ├── OnboardingViewModel.swift  # Onboarding flow
│   ├── PrivacyDashboardViewModel.swift  # Privacy dashboard
│   └── SubscriptionViewModel.swift  # Subscription management
│
├── Views/                          # SwiftUI Views
│   ├── MainTabView.swift          # Main tab navigation
│   ├── DashboardView.swift        # Dashboard
│   ├── BudgetView.swift           # Budget display
│   ├── BudgetCreationView.swift   # Budget creation
│   ├── InsightsView.swift         # Insights display
│   ├── InsightDetailView.swift    # Insight details
│   ├── TransactionsListView.swift # Transaction list
│   ├── TransactionEntryView.swift # Transaction entry
│   ├── TransactionDetailView.swift  # Transaction details
│   ├── TransactionRowView.swift   # Transaction row component
│   ├── TransactionReviewView.swift  # Transaction review
│   ├── StatementUploadView.swift  # Statement upload
│   ├── BatchCategorizationView.swift  # Batch categorization
│   ├── CategorizationRulesView.swift  # Rule management
│   ├── OnboardingView.swift       # Onboarding
│   ├── SettingsView.swift         # Settings
│   ├── PrivacyDashboardView.swift # Privacy dashboard
│   ├── SecurityAuditView.swift    # Security audit
│   ├── BiometricSettingsView.swift  # Biometric settings
│   ├── AnalyticsSettingsView.swift  # Analytics settings
│   ├── RecurringTransactionSetupView.swift  # Recurring setup
│   ├── RecurringTransactionsListView.swift  # Recurring list
│   ├── CashflowForecastView.swift # Cashflow forecast
│   ├── ScenarioPlanningView.swift # Scenario planning
│   ├── PremiumInsightsView.swift  # Premium insights
│   ├── PaywallView.swift          # Paywall
│   ├── AboutView.swift            # About
│   ├── HelpView.swift             # Help
│   ├── ErrorView.swift            # Error display
│   ├── SuccessView.swift          # Success display
│   ├── LoadingStateView.swift     # Loading state
│   └── LiquidGlassCard.swift      # Reusable card component
│
├── Utilities/                      # Utility Classes
│   ├── AccessibilityHelper.swift  # Accessibility utilities
│   └── AnalyticsViewModifier.swift  # Analytics view modifier
│
├── Widgets/                        # Widget Extension (Preview Mode)
│   └── ClariFiWidget.swift        # Home screen widget (placeholder data)
│
├── Tests/                          # Test Suite
│   ├── UnitTests/                 # Unit tests
│   │   ├── DIContainerTests.swift
│   │   ├── RepositoryTests.swift
│   │   ├── BudgetViewModelTests.swift
│   │   ├── InsightsViewModelTests.swift
│   │   ├── StatementUploadViewModelTests.swift
│   │   ├── TransactionEntryViewModelTests.swift
│   │   ├── BudgetViewModelTests.swift
│   │   ├── BudgetMonitoringServiceTests.swift
│   │   ├── BudgetTemplateServiceTests.swift
│   │   ├── CategoryServiceTests.swift
│   │   ├── InsightsEngineTests.swift
│   │   └── MockRepositoriesTests.swift
│   ├── IntegrationTests/          # Integration tests
│   │   └── WorkflowIntegrationTests.swift
│   ├── Mocks/                     # Mock implementations
│   │   ├── MockRepositories.swift
│   │   └── MockServices.swift
│   ├── TestHelpers/               # Test utilities
│   │   └── DIContainer+Testing.swift
│   ├── BiometricAuthServiceTests.swift
│   ├── EncryptionServiceTests.swift
│   ├── SecureFileManagerTests.swift
│   ├── IntegrationTests.swift
│   └── UIIntegrationTests.swift
│
├── ClariFi_iOS.xcdatamodeld/      # Core Data Model
│   └── ClariFi_iOS.xcdatamodel/
│       └── contents               # Entity definitions
│
├── Assets.xcassets/               # Asset Catalog
│   ├── AppIcon.appiconset/
│   └── AccentColor.colorset/
│
├── docs/                          # Documentation
│   ├── reference/                 # Reference documentation
│   │   ├── STATE_MANAGEMENT_PATTERNS.md
│   │   ├── STATEMENT_FORMATS_OVERVIEW.md
│   │   ├── SUPPORTED_STATEMENT_FORMATS.md
│   │   └── TEST_COVERAGE_ANALYSIS.md
│   ├── archive/                   # Archived documentation
│   └── README.md                  # Documentation index
│
├── .kiro/                         # Kiro IDE Configuration
│   └── specs/                     # Feature specifications
│       └── architecture-refactoring/
│           ├── requirements.md
│           ├── design.md
│           ├── tasks.md
│           └── ADR/               # Architecture Decision Records
│
├── ClariFi_iOSApp.swift          # App entry point
├── ContentView.swift              # Root content view
├── Persistence.swift              # Core Data stack setup
├── README.md                      # Project overview
├── ARCHITECTURE.md                # This file
└── .env                           # Environment configuration
```

### File Organization Principles

**1. Flat Structure for Discoverability**
- Top-level folders for major components (Services, ViewModels, Views, Repositories)
- Easy to find files without deep nesting
- Works well with Xcode's file navigator

**2. Logical Grouping by Type**
- All ViewModels in one folder (except BaseViewModel in Presentation/)
- All Views in one folder
- All Services in one folder
- Clear separation of concerns despite flat structure

**3. Minimal Nesting**
- Only nest when there's a clear parent-child relationship (e.g., Base/BaseViewModel.swift)
- Avoid deep folder hierarchies that make navigation difficult
- Xcode groups can provide visual organization without physical nesting

**4. Consistent Naming Conventions**
- ViewModels: `{Feature}ViewModel.swift`
- Views: `{Feature}View.swift`
- Services: `{Feature}Service.swift`
- Repositories: `{Entity}Repository` protocol in RepositoryProtocols.swift
- Tests: `{Component}Tests.swift`

**5. Import Statement Guidelines**
- Import only what's needed: `import Foundation`, `import SwiftUI`, `import CoreData`, `import Combine`
- Avoid wildcard imports
- Core layer imports: Foundation only
- Data layer imports: Foundation, CoreData
- Domain layer imports: Foundation, CoreData, Combine (for publishers)
- Presentation layer imports: SwiftUI, Foundation, Combine

### Layer Boundaries in Flat Structure

Despite the flat physical structure, logical layer boundaries are maintained through:

**1. Import Restrictions**
- Views import SwiftUI but not Core Data directly
- ViewModels import Foundation and Combine, not SwiftUI
- Services import Foundation and Core Data, not SwiftUI
- Repositories import Foundation and Core Data only

**2. Dependency Direction**
- Views depend on ViewModels (via DI container)
- ViewModels depend on Services and Repositories (via constructor injection)
- Services depend on Repositories (via constructor injection)
- Repositories depend on Core Data only
- No upward dependencies

**3. Protocol Boundaries**
- All cross-layer communication through protocols
- Concrete implementations hidden behind protocols
- DI container manages concrete type resolution

**4. Naming Conventions**
- File names clearly indicate layer membership
- `*ViewModel.swift` = Presentation layer
- `*Service.swift` = Domain layer
- `*Repository.swift` = Data layer
- `*View.swift` = Presentation layer

### Why This Structure?

**Advantages:**
- ✅ Easy to navigate in Xcode
- ✅ Quick file discovery (no deep nesting)
- ✅ Clear separation by component type
- ✅ Works well with Xcode's search and navigation
- ✅ Minimal friction for adding new files
- ✅ Logical architecture maintained through conventions

**Trade-offs:**
- ⚠️ Requires discipline to maintain layer boundaries
- ⚠️ Physical structure doesn't mirror logical architecture
- ⚠️ Relies on naming conventions and import discipline

**Why Not Nested Folders?**
- Xcode's file navigator becomes cumbersome with deep nesting
- Harder to find files when they're buried in folders
- More clicks to navigate to files
- Xcode groups provide visual organization without physical nesting
- Flat structure is more common in iOS projects

### File Location Guidelines

When adding new files, follow these guidelines:

| Component Type | Location | Example |
|---------------|----------|---------|
| ViewModel | `ViewModels/` | `ViewModels/NewFeatureViewModel.swift` |
| View | `Views/` | `Views/NewFeatureView.swift` |
| Service | `Services/` | `Services/NewFeatureService.swift` |
| Repository Protocol | `Repositories/RepositoryProtocols.swift` | Add to existing file |
| Repository Implementation | `Repositories/CoreDataRepositories.swift` | Add to existing file |
| Model/Error Type | `Models/` | `Models/NewFeatureError.swift` |
| Extension | `Core/Extensions/` | `Core/Extensions/View+NewFeature.swift` |
| Utility | `Utilities/` | `Utilities/NewFeatureHelper.swift` |
| Test | `Tests/UnitTests/` or `Tests/IntegrationTests/` | `Tests/UnitTests/NewFeatureTests.swift` |
| Mock | `Tests/Mocks/` | Add to `Tests/Mocks/MockServices.swift` |

### Import Statement Best Practices

**Core Layer** (`Core/`):
```swift
import Foundation  // Only Foundation needed
```

**Data Layer** (`Repositories/`, `Models/`):
```swift
import Foundation
import CoreData  // Only when working with Core Data entities
```

**Domain Layer** (`Services/`):
```swift
import Foundation
import CoreData  // Only when needed for context or entities
import Combine   // Only when using publishers
```

**Presentation Layer** (`ViewModels/`):
```swift
import Foundation
import CoreData  // Only when needed for context
import Combine   // For @Published and publishers
// NO SwiftUI imports in ViewModels
```

**Presentation Layer** (`Views/`):
```swift
import SwiftUI
// Avoid importing CoreData directly in views
```

**Test Files**:
```swift
import XCTest
@testable import ClariFi_iOS
import CoreData  // For test fixtures
```

### Verification Checklist

When reviewing code organization:

- ✅ Files are in the correct top-level folder
- ✅ Naming conventions are followed
- ✅ Import statements are minimal and appropriate for the layer
- ✅ No upward dependencies (Views don't import Services, ViewModels don't import Views)
- ✅ Protocol boundaries are maintained
- ✅ DI container is used for dependency resolution
- ✅ Tests are organized by type (Unit, Integration, Mocks)

## Documentation Structure

The project maintains minimal, focused documentation:

### Essential Documentation (Project Root)
- **README.md** - Project overview, getting started, and quick reference
- **ARCHITECTURE.md** - This file - comprehensive architecture documentation

### Reference Documentation (`docs/reference/`)
Technical reference materials for ongoing development:
- **STATE_MANAGEMENT_PATTERNS.md** - State management patterns and best practices
- **STATEMENT_FORMATS_OVERVIEW.md** - Bank statement format support overview
- **SUPPORTED_STATEMENT_FORMATS.md** - Detailed statement format specifications
- **TEST_COVERAGE_ANALYSIS.md** - Test coverage metrics and analysis

### Archived Documentation (`docs/archive/`)
Historical implementation notes and task completion summaries (for reference only)

### Archived Documentation (`docs/archive/`)
Historical implementation documentation from completed tasks. Useful for understanding past decisions but not required for day-to-day development.

### Documentation Principles
1. **Minimal**: Only document what's necessary for development
2. **Current**: Keep documentation in sync with code
3. **Accessible**: Essential docs in root, organized by purpose
4. **Actionable**: Focus on what developers need to know

For more details on documentation organization, see [docs/README.md](./docs/README.md).
