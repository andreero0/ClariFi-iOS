# Dependency Injection Pattern - Quick Reference

## Overview
This guide provides a quick reference for the dependency injection pattern used throughout the ClariFi iOS application after Phase 5 completion.

---

## Standard ViewModel Pattern

### ViewModel Implementation
```swift
@MainActor
class MyViewModel: BaseViewModel {
    // MARK: - Dependencies
    private let repository: MyRepository
    private let service: MyService
    
    // MARK: - Initialization
    init(
        repository: MyRepository,
        service: MyService
    ) {
        self.repository = repository
        self.service = service
        super.init()
    }
    
    // ViewModel logic...
}
```

**Key Points:**
- ✅ Accept all dependencies through init
- ✅ No default parameters
- ✅ No direct creation of dependencies
- ✅ Inherit from BaseViewModel

---

## Standard View Pattern

### View Implementation
```swift
struct MyView: View {
    @StateObject private var viewModel: MyViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: MyViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        // View content...
    }
}
```

**Key Points:**
- ✅ Accept ViewModel as parameter
- ✅ Use @StateObject for ViewModel
- ✅ Initialize with StateObject(wrappedValue:)

---

## Parent View Pattern

### Creating ViewModels in Parent Views
```swift
struct ParentView: View {
    @Environment(\.diContainer) private var container
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationLink(destination: MyView(viewModel: createMyViewModel())) {
            Text("Go to My View")
        }
    }
    
    private func createMyViewModel() -> MyViewModel {
        // Resolve dependencies from container
        guard let repository: MyRepository = container.resolveOptional(MyRepository.self),
              let service: MyService = container.resolveOptional(MyService.self) else {
            // Fallback for preview/testing
            let mockRepository = MockMyRepository(context: viewContext)
            let mockService = MockMyService()
            return MyViewModel(repository: mockRepository, service: mockService)
        }
        
        return MyViewModel(repository: repository, service: service)
    }
}
```

**Key Points:**
- ✅ Access DI container via @Environment
- ✅ Resolve dependencies using container.resolveOptional()
- ✅ Provide fallback for preview scenarios
- ✅ Create ViewModel with resolved dependencies

---

## Preview Pattern

### SwiftUI Previews
```swift
#Preview {
    let context = PersistenceController.preview.container.viewContext
    let repository = CoreDataMyRepository(context: context)
    let service = MyService()
    let viewModel = MyViewModel(repository: repository, service: service)
    
    return MyView(viewModel: viewModel)
        .environment(\.managedObjectContext, context)
}
```

**Key Points:**
- ✅ Create dependencies explicitly for preview
- ✅ Use PersistenceController.preview for Core Data
- ✅ Pass ViewModel to view
- ✅ Inject necessary environment values

---

## DI Container Registration

### Registering Services (in AppDIContainer+Registration.swift)
```swift
// Singleton registration (shared instance)
container.registerSingleton(MyService.self) { _ in
    MyService()
}

// Singleton with dependencies
container.registerSingleton(MyRepository.self) { c in
    CoreDataMyRepository(
        context: context,
        service: c.resolve(MyService.self)
    )
}

// Transient registration (new instance each time)
container.register(MyTransientService.self) { _ in
    MyTransientService()
}
```

**Key Points:**
- ✅ Use registerSingleton for shared state
- ✅ Use register for transient instances
- ✅ Resolve dependencies within factory closure
- ✅ Register in AppDIContainer+Registration.swift

---

## Common Patterns

### Pattern 1: Repository with Context
```swift
container.registerSingleton(TransactionRepository.self) { _ in
    CoreDataTransactionRepository(context: context)
}
```

### Pattern 2: Service with Dependencies
```swift
container.registerSingleton(CategoryServiceProtocol.self) { c in
    CategoryService(
        context: context,
        transactionRepository: c.resolve(TransactionRepository.self),
        llmService: c.resolve(LLMCategorizationServiceProtocol.self)
    )
}
```

### Pattern 3: Optional Dependencies
```swift
let llmService: LLMCategorizationServiceProtocol? = container.resolveOptional(LLMCategorizationServiceProtocol.self)
```

---

## Anti-Patterns to Avoid

### ❌ Creating Dependencies in ViewModel
```swift
// DON'T DO THIS
class MyViewModel: BaseViewModel {
    init() {
        let container = DependencyContainer()  // ❌ Anti-pattern
        self.repository = container.repository
    }
}
```

### ❌ Default Parameters in Init
```swift
// DON'T DO THIS
init(service: MyService = MyService()) {  // ❌ Anti-pattern
    self.service = service
}
```

### ❌ Creating ViewModel in View Init
```swift
// DON'T DO THIS
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()  // ❌ Anti-pattern
}
```

### ❌ Direct PersistenceController Access
```swift
// DON'T DO THIS
init() {
    let context = PersistenceController.shared.container.viewContext  // ❌ Anti-pattern
    self.repository = CoreDataRepository(context: context)
}
```

---

## Correct Patterns

### ✅ Inject Dependencies
```swift
class MyViewModel: BaseViewModel {
    init(repository: MyRepository, service: MyService) {
        self.repository = repository
        self.service = service
        super.init()
    }
}
```

### ✅ No Default Parameters
```swift
init(service: MyService) {  // ✅ Correct
    self.service = service
}
```

### ✅ Accept ViewModel as Parameter
```swift
struct MyView: View {
    @StateObject private var viewModel: MyViewModel
    
    init(viewModel: MyViewModel) {  // ✅ Correct
        _viewModel = StateObject(wrappedValue: viewModel)
    }
}
```

### ✅ Resolve from Container
```swift
private func createViewModel() -> MyViewModel {
    let repository = container.resolve(MyRepository.self)  // ✅ Correct
    let service = container.resolve(MyService.self)
    return MyViewModel(repository: repository, service: service)
}
```

---

## Testing Pattern

### Unit Test Setup
```swift
class MyViewModelTests: XCTestCase {
    var sut: MyViewModel!
    var mockRepository: MockMyRepository!
    var mockService: MockMyService!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockMyRepository()
        mockService = MockMyService()
        sut = MyViewModel(
            repository: mockRepository,
            service: mockService
        )
    }
    
    func testSomething() {
        // Test with injected mocks
    }
}
```

**Key Points:**
- ✅ Create mock dependencies
- ✅ Inject mocks into ViewModel
- ✅ Test behavior with controlled dependencies

---

## Environment Access

### Accessing DI Container
```swift
@Environment(\.diContainer) private var container
```

### Accessing Core Data Context
```swift
@Environment(\.managedObjectContext) private var viewContext
```

### Accessing Dismiss Action
```swift
@Environment(\.dismiss) private var dismiss
```

---

## Complete Example

### ViewModel
```swift
@MainActor
class TransactionEntryViewModel: BaseViewModel {
    private let transactionRepository: TransactionRepository
    private let accountRepository: AccountRepository
    private let categoryMappingService: CategoryMappingServiceProtocol
    private let context: NSManagedObjectContext
    
    init(
        transactionRepository: TransactionRepository,
        accountRepository: AccountRepository,
        categoryMappingService: CategoryMappingServiceProtocol,
        context: NSManagedObjectContext
    ) {
        self.transactionRepository = transactionRepository
        self.accountRepository = accountRepository
        self.categoryMappingService = categoryMappingService
        self.context = context
        super.init()
    }
}
```

### View
```swift
struct TransactionEntryView: View {
    @StateObject private var viewModel: TransactionEntryViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: TransactionEntryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        Form {
            // Form content...
        }
    }
}
```

### Parent View
```swift
struct HomeView: View {
    @Environment(\.diContainer) private var container
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingTransactionEntry = false
    
    var body: some View {
        Button("Add Transaction") {
            showingTransactionEntry = true
        }
        .sheet(isPresented: $showingTransactionEntry) {
            TransactionEntryView(viewModel: createTransactionEntryViewModel())
        }
    }
    
    private func createTransactionEntryViewModel() -> TransactionEntryViewModel {
        guard let transactionRepo: TransactionRepository = container.resolveOptional(TransactionRepository.self),
              let accountRepo: AccountRepository = container.resolveOptional(AccountRepository.self),
              let categoryService: CategoryMappingServiceProtocol = container.resolveOptional(CategoryMappingServiceProtocol.self) else {
            // Fallback
            let mockTransactionRepo = CoreDataTransactionRepository(context: viewContext)
            let mockAccountRepo = CoreDataAccountRepository(context: viewContext)
            let mockCategoryService = CategoryMappingService()
            
            return TransactionEntryViewModel(
                transactionRepository: mockTransactionRepo,
                accountRepository: mockAccountRepo,
                categoryMappingService: mockCategoryService,
                context: viewContext
            )
        }
        
        return TransactionEntryViewModel(
            transactionRepository: transactionRepo,
            accountRepository: accountRepo,
            categoryMappingService: categoryService,
            context: viewContext
        )
    }
}
```

---

## Checklist for New ViewModels

When creating a new ViewModel, ensure:

- [ ] Inherits from BaseViewModel
- [ ] All dependencies passed through init
- [ ] No default parameters in init
- [ ] No direct dependency creation
- [ ] Marked with @MainActor
- [ ] View accepts ViewModel as parameter
- [ ] Parent view resolves dependencies from container
- [ ] Preview creates ViewModel with dependencies
- [ ] Tests inject mock dependencies

---

## Benefits of This Pattern

1. **Testability**: Easy to inject mock dependencies for testing
2. **Consistency**: All ViewModels follow the same pattern
3. **Maintainability**: Clear dependency graph
4. **Single Source of Truth**: All dependencies from DI container
5. **Shared State**: Singleton services maintain consistent state
6. **No Anti-Patterns**: Eliminated direct dependency creation
7. **Scalability**: Easy to add new dependencies
8. **Flexibility**: Easy to swap implementations

---

## Reference Implementation

See these files for reference implementations:
- `ViewModels/TransactionEntryViewModel.swift`
- `ViewModels/BudgetViewModel.swift`
- `ViewModels/InsightsViewModel.swift`
- `Views/HomeView.swift`
- `Views/PlanningView.swift`
- `Core/DependencyInjection/AppDIContainer+Registration.swift`

---

## Questions?

If you're unsure about the pattern:
1. Check existing ViewModels for reference
2. Review this quick reference guide
3. Consult the Phase 5 completion summary
4. Follow the checklist above

**Remember**: Consistency is key. Follow the established patterns for maintainable code.
