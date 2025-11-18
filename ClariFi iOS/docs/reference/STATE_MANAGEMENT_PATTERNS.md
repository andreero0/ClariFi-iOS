# State Management Patterns Guide

## Overview
This document provides comprehensive guidelines for state management in ClariFi iOS, specifically focusing on the correct usage of `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, and other SwiftUI property wrappers.

## Core Principles

### 1. Ownership Determines the Property Wrapper
- **@StateObject**: Use when the View **owns** and is responsible for the ViewModel's lifecycle
- **@ObservedObject**: Use when the View **observes** a ViewModel owned by another View
- **@EnvironmentObject**: Use for app-wide shared state passed down the view hierarchy

### 2. Dependency Injection Pattern
All ViewModels should be injected through the DI container when possible, ensuring:
- Testability through mock injection
- Consistent dependency management
- Clear separation of concerns

## Property Wrapper Reference

### @StateObject

**When to Use:**
- The View creates and owns the ViewModel
- The ViewModel's lifecycle should match the View's lifecycle
- You want SwiftUI to manage the ViewModel's memory

**Pattern 1: DI-Injected ViewModel (Preferred)**
```swift
struct MyView: View {
    // ✅ CORRECT: View owns the ViewModel, injected via DI
    @StateObject private var viewModel: MyViewModel
    
    init(viewModel: MyViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        // View implementation
    }
}

// Usage in parent:
MyView(viewModel: container.resolve(MyViewModel.self))
```

**Pattern 2: Directly Created ViewModel**
```swift
struct MyView: View {
    // ✅ CORRECT: View owns and creates the ViewModel
    // Use when ViewModel has no dependencies or simple dependencies
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        // View implementation
    }
}
```

**Examples in Codebase:**
- `BudgetView` - Injected from DI container
- `InsightsView` - Injected from DI container
- `TransactionEntryView` - Injected from DI container
- `OnboardingView` - Created directly (no dependencies)
- `MainTabView` - Creates AppState and SubscriptionViewModel

### @ObservedObject

**When to Use:**
- The View does NOT own the ViewModel
- The ViewModel is passed from a parent View
- Multiple Views need to share the same ViewModel instance

**Pattern: Shared ViewModel**
```swift
struct ChildView: View {
    // ✅ CORRECT: ViewModel is owned by parent, shared with child
    @ObservedObject var viewModel: ParentViewModel
    
    var body: some View {
        // View implementation using parent's ViewModel
    }
}

// Usage in parent:
struct ParentView: View {
    @StateObject private var viewModel = ParentViewModel()
    
    var body: some View {
        ChildView(viewModel: viewModel)
    }
}
```

**Examples in Codebase:**
- `RecurringTransactionDetailView` - Shares ViewModel with RecurringTransactionsListView
- `RecurringTransactionSetupView` - Shares ViewModel with TransactionEntryView
- `RuleEditorView` - Shares ViewModel with CategorizationRulesView

### @EnvironmentObject

**When to Use:**
- App-wide shared state
- State needs to be accessible by many views at different levels
- Avoiding prop drilling through multiple view layers

**Pattern: App-Wide State**
```swift
// In root view (e.g., MainTabView):
struct MainTabView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        TabView {
            DashboardView()
                .environmentObject(appState)
        }
    }
}

// In child views:
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        // Access appState properties
    }
}
```

**Examples in Codebase:**
- `AppState` - Shared across all tab views
- `SubscriptionViewModel` - Shared for premium feature access

### @State

**When to Use:**
- Simple value types (Bool, String, Int, etc.)
- View-local state that doesn't need to be shared
- UI state like showing/hiding sheets or alerts

**Pattern: View-Local State**
```swift
struct MyView: View {
    @State private var isShowingSheet = false
    @State private var selectedItem: Item?
    @State private var searchText = ""
    
    var body: some View {
        // View implementation
    }
}
```

### @Binding

**When to Use:**
- Two-way data flow between parent and child
- Child needs to modify parent's state
- Form inputs and controls

**Pattern: Two-Way Binding**
```swift
struct ChildView: View {
    @Binding var isEnabled: Bool
    
    var body: some View {
        Toggle("Enable Feature", isOn: $isEnabled)
    }
}

// Usage in parent:
struct ParentView: View {
    @State private var isEnabled = false
    
    var body: some View {
        ChildView(isEnabled: $isEnabled)
    }
}
```

## Common Patterns in ClariFi

### Pattern 1: Tab-Level Views with DI
```swift
struct BudgetView: View {
    @Environment(\.diContainer) private var container
    @StateObject private var viewModel: BudgetViewModel
    
    init(viewModel: BudgetViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        // Implementation
    }
}

// Usage in MainTabView:
BudgetView(viewModel: container.resolve(BudgetViewModel.self))
```

### Pattern 2: Modal/Sheet Views with DI
```swift
struct TransactionEntryView: View {
    @StateObject private var viewModel: TransactionEntryViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: TransactionEntryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        // Implementation
    }
}

// Usage:
.sheet(isPresented: $showingEntry) {
    TransactionEntryView(viewModel: container.resolve(TransactionEntryViewModel.self))
}
```

### Pattern 3: Detail Views Sharing Parent ViewModel
```swift
struct DetailView: View {
    @ObservedObject var viewModel: ParentViewModel
    let item: Item
    
    var body: some View {
        // Implementation using shared ViewModel
    }
}

// Usage in parent:
struct ListView: View {
    @StateObject private var viewModel = ParentViewModel()
    
    var body: some View {
        List(viewModel.items) { item in
            NavigationLink {
                DetailView(viewModel: viewModel, item: item)
            } label: {
                Text(item.name)
            }
        }
    }
}
```

## Anti-Patterns to Avoid

### ❌ Using @StateObject for Singletons
```swift
// ❌ WRONG: Don't use @StateObject for singletons
struct MyView: View {
    @StateObject private var service = MyService.shared
}

// ✅ CORRECT: Use direct property access
struct MyView: View {
    private let service = MyService.shared
}
```

### ❌ Using @ObservedObject for Owned ViewModels
```swift
// ❌ WRONG: View owns the ViewModel but uses @ObservedObject
struct MyView: View {
    @ObservedObject var viewModel = MyViewModel()
}

// ✅ CORRECT: Use @StateObject for owned ViewModels
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
}
```

### ❌ Creating ViewModels Without DI
```swift
// ❌ WRONG: Creating ViewModel with direct dependencies
struct MyView: View {
    @StateObject private var viewModel = MyViewModel(
        repository: RepositoryFactory.shared.transactionRepository
    )
}

// ✅ CORRECT: Inject ViewModel from DI container
struct MyView: View {
    @StateObject private var viewModel: MyViewModel
    
    init(viewModel: MyViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
}
```

## Testing Considerations

### Testing Views with @StateObject
```swift
func testMyView() {
    // Create mock ViewModel
    let mockViewModel = MockMyViewModel()
    
    // Inject into View
    let view = MyView(viewModel: mockViewModel)
    
    // Test view behavior
    // ...
}
```

### Testing Views with @ObservedObject
```swift
func testChildView() {
    // Create parent ViewModel
    let parentViewModel = ParentViewModel()
    
    // Inject into child View
    let childView = ChildView(viewModel: parentViewModel)
    
    // Test child behavior with shared state
    // ...
}
```

## Migration Checklist

When updating a View's state management:

1. ✅ Identify if the View owns the ViewModel or receives it
2. ✅ Choose the correct property wrapper (@StateObject vs @ObservedObject)
3. ✅ Update the initializer to accept ViewModel from DI if owned
4. ✅ Update parent Views to resolve ViewModel from DI container
5. ✅ Add inline documentation explaining the choice
6. ✅ Update tests to inject mock ViewModels
7. ✅ Verify the View still functions correctly

## Documentation Template

Add this comment above your property wrapper:

```swift
// State Management: @StateObject is used because this View owns the ViewModel lifecycle.
// The ViewModel is injected via the initializer from the DI container, ensuring proper
// dependency injection and testability. SwiftUI manages the lifecycle automatically.
@StateObject private var viewModel: MyViewModel
```

Or for @ObservedObject:

```swift
// State Management: @ObservedObject is used because this View does NOT own the ViewModel.
// The ViewModel is owned by the parent [ParentView] and shared with this child view,
// allowing both to observe and react to the same state.
@ObservedObject var viewModel: ParentViewModel
```

## Quick Reference

| Property Wrapper | Ownership | Lifecycle | Use Case |
|-----------------|-----------|-----------|----------|
| @StateObject | View owns | Managed by SwiftUI | ViewModel created/injected by this View |
| @ObservedObject | External | Managed elsewhere | ViewModel passed from parent |
| @EnvironmentObject | App-wide | Managed by root | Shared app state |
| @State | View owns | Managed by SwiftUI | Simple value types, UI state |
| @Binding | Parent owns | Managed by parent | Two-way data flow |

## Additional Resources

- [SwiftUI Property Wrappers Documentation](https://developer.apple.com/documentation/swiftui/state-and-data-flow)
- [WWDC: Data Essentials in SwiftUI](https://developer.apple.com/videos/play/wwdc2020/10040/)
- ClariFi Architecture Documentation: `ARCHITECTURE.md`
- Dependency Injection Guide: `.kiro/specs/architecture-refactoring/design.md`

---
**Last Updated**: 2025-10-11
**Maintained By**: ClariFi Development Team
