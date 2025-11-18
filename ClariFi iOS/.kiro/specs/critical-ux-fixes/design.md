# Design Document

## Overview

This design addresses six critical issues preventing ClariFi from delivering the intended user experience:

1. **Broken Authentication Flow** - ContentView references non-existent AuthenticationView
2. **Category System Fragmentation** - Three different category systems with mismatched names
3. **Incomplete Onboarding Flow** - No bridge from onboarding to first action
4. **Missing Account Setup Integration** - Account creation is ad-hoc, not part of onboarding
5. **No Apple Foundation Model** - Missing privacy-first LLM integration
6. **Dependency Injection Issues** - ViewModels creating their own container instances

The design follows a phased approach: emergency fixes first, then architectural improvements, then enhanced features.

## Architecture

### High-Level System Design

```
┌─────────────────────────────────────────────────────────────┐
│                        App Launch                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              ContentView (Root Coordinator)                  │
│  - Manages app-level state                                   │
│  - Single DI Container instance                              │
│  - Determines which flow to show                             │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌──────────────┐         ┌──────────────────┐
│  Onboarding  │         │   Main App       │
│  Flow        │────────▶│   (MainTabView)  │
└──────────────┘         └──────────────────┘
        │
        ▼
┌──────────────────────────────────────────┐
│  Enhanced Onboarding Steps:              │
│  1. Welcome                               │
│  2. Privacy Setup                         │
│  3. Features Overview                     │
│  4. Account Setup (NEW)                   │
│  5. Biometric Setup                       │
│  6. Quick Start Choice (NEW)              │
│  7. First Action Guidance (NEW)           │
└──────────────────────────────────────────┘
```

### Category System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  CategoryDefinition (Single Source of Truth) │
│  - Canonical name (internal identifier)                      │
│  - Display name (user-facing)                                │
│  - Icon                                                       │
│  - Parent category (for hierarchy)                           │
│  - Budget template mappings                                  │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┬────────────────┐
        │                         │                │
        ▼                         ▼                ▼
┌──────────────┐         ┌──────────────┐  ┌──────────────┐
│  Budget      │         │ Transaction  │  │ Category     │
│  Templates   │         │ Entry        │  │ Service      │
│              │         │              │  │              │
│  Maps to     │         │  Uses        │  │  Returns     │
│  canonical   │         │  canonical   │  │  canonical   │
└──────────────┘         └──────────────┘  └──────────────┘
```

### Dependency Injection Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    ClariFi_iOSApp                            │
│  @main                                                        │
│  - Creates single AppDIContainer instance                    │
│  - Injects via .environment(\.diContainer, container)        │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                      ContentView                             │
│  @Environment(\.diContainer) var container                   │
│  - Passes container to child views                           │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌──────────────────┐      ┌──────────────────┐
│  View            │      │  ViewModel       │
│  @Environment    │─────▶│  init(container) │
│  var container   │      │  - Resolves deps │
└──────────────────┘      └──────────────────┘
```

## Components and Interfaces

### 1. Category System Components

#### CategoryDefinition Model

```swift
struct CategoryDefinition: Identifiable, Codable {
    let id: String  // Canonical identifier
    let canonicalName: String  // Internal name (e.g., "housing")
    let displayName: String  // User-facing name (e.g., "Housing & Rent")
    let icon: String  // SF Symbol name
    let parentCategory: String?  // For hierarchy (needs vs wants)
    let isEssential: Bool
    let budgetTemplateAliases: [String]  // Alternative names used in templates
    
    // Predefined categories
    static let housing = CategoryDefinition(
        id: "housing",
        canonicalName: "housing",
        displayName: "Housing & Rent",
        icon: "house.fill",
        parentCategory: "needs",
        isEssential: true,
        budgetTemplateAliases: ["Housing", "Housing & Rent", "Housing (BAH)", "Housing & Home Office"]
    )
    
    static let foodGroceries = CategoryDefinition(
        id: "food_groceries",
        canonicalName: "food_groceries",
        displayName: "Food & Groceries",
        icon: "cart.fill",
        parentCategory: "needs",
        isEssential: true,
        budgetTemplateAliases: ["Food & Groceries", "Groceries", "Food & Dining"]
    )
    
    // ... more categories
    
    static let allCategories: [CategoryDefinition] = [
        .housing,
        .foodGroceries,
        .dining,
        .transportation,
        .utilities,
        .healthcare,
        .education,
        .entertainment,
        .shopping,
        .subscriptions,
        .income,
        .transfer,
        .other
    ]
}
```

#### CategoryMappingService

```swift
protocol CategoryMappingServiceProtocol {
    func getCanonicalCategory(from templateName: String) -> CategoryDefinition?
    func getDisplayName(for canonicalName: String) -> String
    func getAllCategories() -> [CategoryDefinition]
    func getCategoriesForBudgetTemplate(_ templateId: String) -> [CategoryDefinition]
}

class CategoryMappingService: CategoryMappingServiceProtocol {
    private let definitions = CategoryDefinition.allCategories
    
    func getCanonicalCategory(from templateName: String) -> CategoryDefinition? {
        // Find category by matching template alias
        return definitions.first { category in
            category.budgetTemplateAliases.contains(templateName) ||
            category.displayName == templateName ||
            category.canonicalName == templateName
        }
    }
    
    func getDisplayName(for canonicalName: String) -> String {
        return definitions.first { $0.canonicalName == canonicalName }?.displayName ?? canonicalName
    }
    
    func getAllCategories() -> [CategoryDefinition] {
        return definitions
    }
    
    func getCategoriesForBudgetTemplate(_ templateId: String) -> [CategoryDefinition] {
        // Get template from BudgetTemplateService
        // Map template category names to canonical categories
        // Return matched CategoryDefinitions
    }
}
```

### 2. Enhanced Onboarding Components

#### OnboardingCoordinator

```swift
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case privacy = 1
    case features = 2
    case accountSetup = 3  // NEW
    case biometric = 4
    case quickStart = 5  // NEW
    case firstAction = 6  // NEW
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .privacy: return "Privacy"
        case .features: return "Features"
        case .accountSetup: return "Set Up Account"
        case .biometric: return "Security"
        case .quickStart: return "Quick Start"
        case .firstAction: return "Get Started"
        }
    }
}

@MainActor
class OnboardingCoordinator: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var selectedProcessingMode: ProcessingMode = .localOnly
    @Published var enableBiometric: Bool = false
    @Published var createdAccounts: [AccountSetupData] = []
    @Published var selectedFirstAction: FirstActionType?
    
    func advance() {
        if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            currentStep = nextStep
        }
    }
    
    func canAdvance() -> Bool {
        switch currentStep {
        case .accountSetup:
            return !createdAccounts.isEmpty
        case .quickStart:
            return selectedFirstAction != nil
        default:
            return true
        }
    }
}
```

#### AccountSetupData

```swift
struct AccountSetupData: Identifiable {
    let id = UUID()
    var name: String
    var type: AccountType
    var initialBalance: Decimal
    var isDefault: Bool
    
    enum AccountType: String, CaseIterable {
        case checking = "Checking"
        case savings = "Savings"
        case credit = "Credit Card"
        case cash = "Cash"
        case investment = "Investment"
    }
}
```

#### QuickStartView (NEW)

```swift
struct QuickStartView: View {
    @Binding var selectedAction: FirstActionType?
    
    enum FirstActionType {
        case uploadStatement
        case manualEntry
        case createBudget
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("How would you like to start?")
                .font(.title)
                .fontWeight(.bold)
            
            ActionCard(
                icon: "doc.text.viewfinder",
                title: "Upload a Statement",
                description: "Scan your bank statement to import transactions automatically",
                isSelected: selectedAction == .uploadStatement,
                action: { selectedAction = .uploadStatement }
            )
            
            ActionCard(
                icon: "plus.circle.fill",
                title: "Add Transaction Manually",
                description: "Enter your first transaction to start tracking",
                isSelected: selectedAction == .manualEntry,
                action: { selectedAction = .manualEntry }
            )
            
            ActionCard(
                icon: "target",
                title: "Create a Budget",
                description: "Set up your budget first, then add transactions",
                isSelected: selectedAction == .createBudget,
                action: { selectedAction = .createBudget }
            )
        }
    }
}
```

### 3. Apple Foundation Model Integration

#### LLMCategorizationService

```swift
protocol LLMCategorizationServiceProtocol {
    func categorizeWithLLM(merchant: String, amount: Decimal, context: String?) async throws -> CategorizationResult
    func normalizeMerchantName(_ merchant: String) async throws -> String
    func extractTransactionData(from text: String) async throws -> [TransactionData]
}

class AppleLLMCategorizationService: LLMCategorizationServiceProtocol {
    private let modelManager: AppleFoundationModelManager
    private let fallbackService: CategoryServiceProtocol
    
    init(modelManager: AppleFoundationModelManager, fallbackService: CategoryServiceProtocol) {
        self.modelManager = modelManager
        self.fallbackService = fallbackService
    }
    
    func categorizeWithLLM(merchant: String, amount: Decimal, context: String?) async throws -> CategorizationResult {
        // Check if Apple Foundation Model is available
        guard modelManager.isAvailable else {
            // Fallback to existing pattern matching
            return try await fallbackService.categorize(merchant: merchant, amount: amount)
        }
        
        // Construct prompt for LLM
        let prompt = buildCategorizationPrompt(merchant: merchant, amount: amount, context: context)
        
        // Query LLM
        let response = try await modelManager.query(prompt: prompt)
        
        // Parse response to extract category
        let category = parseCategorizationResponse(response)
        
        return CategorizationResult(
            category: category,
            confidence: 0.9,
            matchedPattern: nil,
            matchType: .llm
        )
    }
    
    func normalizeMerchantName(_ merchant: String) async throws -> String {
        guard modelManager.isAvailable else {
            return merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let prompt = """
        Normalize this merchant name to a standard format:
        "\(merchant)"
        
        Return only the normalized name, nothing else.
        """
        
        let response = try await modelManager.query(prompt: prompt)
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func extractTransactionData(from text: String) async throws -> [TransactionData] {
        guard modelManager.isAvailable else {
            // Fallback to regex-based extraction
            return try await fallbackService.extractTransactions(from: text)
        }
        
        let prompt = buildExtractionPrompt(text: text)
        let response = try await modelManager.query(prompt: prompt)
        return parseTransactionData(response)
    }
    
    private func buildCategorizationPrompt(merchant: String, amount: Decimal, context: String?) -> String {
        let categories = CategoryDefinition.allCategories.map { $0.displayName }.joined(separator: ", ")
        
        return """
        Categorize this transaction:
        Merchant: \(merchant)
        Amount: $\(amount)
        \(context.map { "Context: \($0)" } ?? "")
        
        Available categories: \(categories)
        
        Return only the category name that best matches this transaction.
        """
    }
    
    private func parseCategorizationResponse(_ response: String) -> String {
        // Extract category from LLM response
        // Match against CategoryDefinition.allCategories
        let normalized = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find matching category
        if let match = CategoryDefinition.allCategories.first(where: { category in
            category.displayName.lowercased() == normalized.lowercased() ||
            category.canonicalName.lowercased() == normalized.lowercased()
        }) {
            return match.canonicalName
        }
        
        return "other"
    }
}
```

#### AppleFoundationModelManager

```swift
import CoreML

class AppleFoundationModelManager {
    private var model: MLModel?
    
    var isAvailable: Bool {
        return model != nil
    }
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        // Attempt to load Apple Foundation Model
        // This is a placeholder - actual implementation depends on Apple's API
        do {
            // Try to load the model
            // model = try MLModel(contentsOf: modelURL)
        } catch {
            print("Apple Foundation Model not available: \(error)")
            model = nil
        }
    }
    
    func query(prompt: String) async throws -> String {
        guard let model = model else {
            throw LLMError.modelNotAvailable
        }
        
        // Query the model with the prompt
        // This is a placeholder - actual implementation depends on Apple's API
        // let prediction = try model.prediction(from: input)
        // return prediction.output
        
        throw LLMError.notImplemented
    }
}

enum LLMError: Error {
    case modelNotAvailable
    case notImplemented
    case invalidResponse
}
```

### 4. Fixed Dependency Injection

#### Environment Key for DI Container

```swift
import SwiftUI

// Define environment key
private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: AppDIContainer = AppDIContainer()
}

extension EnvironmentValues {
    var diContainer: AppDIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}
```

#### Updated App Entry Point

```swift
@main
struct ClariFi_iOSApp: App {
    let persistenceController = PersistenceController.shared
    let container = AppDIContainer()  // Single instance
    
    init() {
        // Register all dependencies
        registerDependencies()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.diContainer, container)  // Inject container
        }
    }
    
    private func registerDependencies() {
        let context = persistenceController.container.viewContext
        
        // Register repositories as singletons
        container.registerSingleton(TransactionRepository.self) { _ in
            CoreDataTransactionRepository(context: context)
        }
        
        container.registerSingleton(AccountRepository.self) { _ in
            CoreDataAccountRepository(context: context)
        }
        
        container.registerSingleton(BudgetRepository.self) { _ in
            CoreDataBudgetRepository(context: context)
        }
        
        // Register services
        container.registerSingleton(CategoryMappingServiceProtocol.self) { _ in
            CategoryMappingService()
        }
        
        container.registerSingleton(CategoryServiceProtocol.self) { container in
            CategoryService(
                context: context,
                transactionRepository: container.resolve(TransactionRepository.self)
            )
        }
        
        container.registerSingleton(BudgetTemplateService.self) { _ in
            BudgetTemplateService()
        }
        
        // Register LLM service with fallback
        container.registerSingleton(LLMCategorizationServiceProtocol.self) { container in
            AppleLLMCategorizationService(
                modelManager: AppleFoundationModelManager(),
                fallbackService: container.resolve(CategoryServiceProtocol.self)
            )
        }
    }
}
```

#### Updated ViewModel Pattern

```swift
// OLD (BROKEN) Pattern:
class TransactionEntryViewModel: ObservableObject {
    init() {
        // ❌ Creates new container instance
        let container = DependencyContainer()
        self.transactionRepository = container.transactionRepository
    }
}

// NEW (FIXED) Pattern:
class TransactionEntryViewModel: ObservableObject {
    private let transactionRepository: TransactionRepository
    private let categoryService: CategoryServiceProtocol
    
    init(container: AppDIContainer) {
        self.transactionRepository = container.resolve(TransactionRepository.self)
        self.categoryService = container.resolve(CategoryServiceProtocol.self)
    }
}

// Usage in View:
struct TransactionEntryView: View {
    @Environment(\.diContainer) var container
    @StateObject private var viewModel: TransactionEntryViewModel
    
    init() {
        // Temporary initialization - will be configured in onAppear
        self._viewModel = StateObject(wrappedValue: TransactionEntryViewModel(container: AppDIContainer()))
    }
    
    var body: some View {
        // View content
        .onAppear {
            // Configure with actual container
            if viewModel.needsConfiguration {
                viewModel.configure(with: container)
            }
        }
    }
}
```

## Data Models

### Enhanced Budget Model

```swift
struct Budget: Identifiable, Codable {
    let id: String
    let name: String
    let monthlyIncome: Decimal
    let categories: [BudgetCategory]
    let templateId: String?  // NEW: Track which template was used
    let createdDate: Date
    let isActive: Bool
}

struct BudgetCategory: Identifiable, Codable {
    let id = UUID()
    let canonicalName: String  // NEW: Use canonical category name
    let displayName: String  // NEW: User-facing name
    let budgetedAmount: Decimal
    let spentAmount: Decimal
    let isEssential: Bool
    
    var remainingAmount: Decimal {
        budgetedAmount - spentAmount
    }
}
```

### Enhanced Transaction Model

```swift
struct Transaction: Identifiable, Codable {
    let id: String
    let accountId: String
    let date: Date
    let merchant: String
    let normalizedMerchant: String?  // NEW: LLM-normalized name
    let amount: Decimal
    let canonicalCategory: String  // NEW: Use canonical category name
    let displayCategory: String  // NEW: User-facing category name
    let notes: String?
    let isRecurring: Bool
    let recurringFrequency: RecurringFrequency?
    let categorizationMethod: CategorizationMethod  // NEW: Track how it was categorized
}

enum CategorizationMethod: String, Codable {
    case manual
    case llm
    case learned
    case pattern
    case rule
}
```

## Error Handling

### Category Mapping Errors

```swift
enum CategoryMappingError: Error, LocalizedError {
    case categoryNotFound(templateName: String)
    case ambiguousMapping(templateName: String, matches: [String])
    case invalidCanonicalName(name: String)
    
    var errorDescription: String? {
        switch self {
        case .categoryNotFound(let name):
            return "Category '\(name)' not found in mapping"
        case .ambiguousMapping(let name, let matches):
            return "Category '\(name)' matches multiple categories: \(matches.joined(separator: ", "))"
        case .invalidCanonicalName(let name):
            return "Invalid canonical category name: '\(name)'"
        }
    }
}
```

### Onboarding Errors

```swift
enum OnboardingError: Error, LocalizedError {
    case accountCreationFailed
    case biometricSetupFailed
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .accountCreationFailed:
            return "Failed to create account. Please try again."
        case .biometricSetupFailed:
            return "Failed to enable biometric authentication. You can enable it later in Settings."
        case .invalidConfiguration:
            return "Invalid onboarding configuration. Please restart the app."
        }
    }
}
```

## Testing Strategy

### Unit Tests

1. **CategoryMappingService Tests**
   - Test canonical name lookup
   - Test template alias mapping
   - Test ambiguous name handling
   - Test all predefined categories

2. **OnboardingCoordinator Tests**
   - Test step progression
   - Test validation logic
   - Test account creation
   - Test completion state

3. **LLM Service Tests**
   - Test fallback behavior when LLM unavailable
   - Test prompt construction
   - Test response parsing
   - Test error handling

### Integration Tests

1. **End-to-End Onboarding Flow**
   - Complete onboarding from start to finish
   - Verify account creation
   - Verify first action guidance
   - Verify transition to main app

2. **Category Consistency Test**
   - Create budget from template
   - Add transaction
   - Verify category names match
   - Verify budget tracking works

3. **Dependency Injection Test**
   - Verify single container instance
   - Verify shared repository state
   - Verify no memory leaks

### UI Tests

1. **Onboarding Flow UI Test**
   - Navigate through all steps
   - Test skip functionality
   - Test back navigation
   - Test completion

2. **First Transaction Flow**
   - Complete onboarding
   - Select "Add Transaction"
   - Verify categories match budget
   - Complete transaction entry

## Performance Considerations

### LLM Performance

- **Lazy Loading**: Load Apple Foundation Model only when needed
- **Caching**: Cache LLM responses for repeated queries
- **Timeout**: Set reasonable timeout for LLM queries (5 seconds)
- **Fallback**: Always have regex-based fallback ready

### Category Mapping Performance

- **In-Memory Cache**: Keep CategoryDefinition.allCategories in memory
- **Fast Lookup**: Use dictionary for O(1) lookup by canonical name
- **Lazy Evaluation**: Only map categories when needed

### Onboarding Performance

- **Progressive Loading**: Load each step's content on-demand
- **Background Saving**: Save onboarding progress in background
- **Quick Start**: Minimize time to first action (< 5 minutes)

## Security Considerations

### Privacy-First LLM

- **On-Device Only**: All LLM processing happens locally
- **No Network Calls**: Never send financial data to external services
- **Data Minimization**: Only process necessary data
- **Secure Storage**: Encrypted storage for learned patterns

### Account Setup Security

- **No Sensitive Data**: Don't require account numbers or passwords
- **Optional Fields**: Make all fields except name optional
- **Biometric Protection**: Encourage biometric authentication
- **Secure Defaults**: Default to most secure options

## Migration Strategy

### Phase 1: Emergency Fixes (Week 1)

1. Remove broken AuthenticationView reference
2. Create CategoryMappingService with basic mappings
3. Fix DI container anti-pattern in critical ViewModels
4. Add basic account setup to onboarding

### Phase 2: Category System Unification (Week 2)

1. Implement CategoryDefinition model
2. Update BudgetTemplateService to use canonical names
3. Update CategoryService to return canonical names
4. Update all views to use CategoryMappingService
5. Migrate existing data to canonical names

### Phase 3: Enhanced Onboarding (Week 3)

1. Implement OnboardingCoordinator
2. Add QuickStartView
3. Add FirstActionGuidanceView
4. Integrate account setup into onboarding
5. Add success states and celebrations

### Phase 4: LLM Integration (Week 4)

1. Implement AppleFoundationModelManager
2. Implement AppleLLMCategorizationService
3. Add fallback logic
4. Test with real statements
5. Optimize performance

## Success Metrics

### Technical Metrics

- Zero crashes related to authentication flow
- 100% category name consistency across app
- Single DI container instance throughout lifecycle
- LLM categorization accuracy > 85% (when available)

### User Experience Metrics

- Time to first transaction < 5 minutes
- Onboarding completion rate > 80%
- First action completion rate > 60%
- Category confusion incidents = 0

### Performance Metrics

- App launch time < 2 seconds
- Onboarding step transition < 500ms
- LLM categorization response < 3 seconds
- Category lookup < 10ms
