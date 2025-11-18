# RepositoryFactory Usage Audit

**Date:** 2025-10-11  
**Status:** Complete  
**Total References Found:** 8 direct usages in production code

## Executive Summary

The codebase currently has **8 direct references** to `RepositoryFactory.shared` in production code (Views). The RepositoryFactory singleton pattern exists but is minimally used. Most ViewModels already follow dependency injection patterns, which is excellent news for the migration.

## Current State

### RepositoryFactory Implementation
- **Location:** `Repositories/RepositoryFactory.swift`
- **Pattern:** Singleton with lazy-loaded repository instances
- **Repositories Managed:** 6 core repositories
  - TransactionRepository
  - AccountRepository
  - BudgetRepository
  - BudgetCategoryRepository
  - StatementRepository
  - RecurringTransactionRepository

### Good News
✅ **ViewModels already use dependency injection** - All major ViewModels accept repositories via constructor  
✅ **Repository protocols are well-designed** - No changes needed to repository layer  
✅ **Limited singleton usage** - Only 8 references instead of the anticipated 39+  

## Detailed Usage Inventory

### 1. Views/MainTabView.swift
**Lines:** 38-40, 54-56  
**Context:** Creating BudgetViewModel and InsightsViewModel for tab views  
**Usage Count:** 6 references

```swift
// Line 38-40
BudgetView(viewModel: BudgetViewModel(
    budgetRepository: RepositoryFactory.shared.budgetRepository,
    budgetCategoryRepository: RepositoryFactory.shared.budgetCategoryRepository,
    transactionRepository: RepositoryFactory.shared.transactionRepository,
    context: viewContext
))

// Line 54-56
InsightsView(viewModel: InsightsViewModel(
    insightsEngine: InsightsEngine(context: viewContext),
    transactionRepository: RepositoryFactory.shared.transactionRepository,
    budgetRepository: RepositoryFactory.shared.budgetRepository,
    context: viewContext
))
```

**Migration Strategy:**
- Resolve ViewModels from DI container instead of manual instantiation
- Pattern: `container.resolve(BudgetViewModel.self)`

---

### 2. Views/DashboardView.swift
**Lines:** 78-80, 206-207  
**Context:** Creating TransactionEntryViewModel and InsightsViewModel in sheets/navigation  
**Usage Count:** 4 references

```swift
// Line 78-80
TransactionEntryView(viewModel: TransactionEntryViewModel(
    transactionRepository: RepositoryFactory.shared.transactionRepository,
    accountRepository: RepositoryFactory.shared.accountRepository,
    context: viewContext
))

// Line 206-207
NavigationLink(destination: InsightsView(viewModel: InsightsViewModel(
    insightsEngine: InsightsEngine(context: viewContext),
    transactionRepository: RepositoryFactory.shared.transactionRepository,
    budgetRepository: RepositoryFactory.shared.budgetRepository,
    context: viewContext
)))
```

**Migration Strategy:**
- Resolve ViewModels from DI container
- Pass resolved ViewModels to child views

---

### 3. Views/TransactionsListView.swift
**Lines:** 65-67  
**Context:** Creating TransactionEntryViewModel in sheet  
**Usage Count:** 2 references

```swift
// Line 65-67
TransactionEntryView(viewModel: TransactionEntryViewModel(
    transactionRepository: RepositoryFactory.shared.transactionRepository,
    accountRepository: RepositoryFactory.shared.accountRepository,
    context: viewContext
))
```

**Migration Strategy:**
- Resolve TransactionEntryViewModel from DI container
- Pass to TransactionEntryView

---

## Test File Usage

### Tests/UIIntegrationTests.swift
**Multiple references throughout test methods**  
**Context:** Integration tests creating ViewModels with repositories  
**Usage Count:** 12+ references

**Migration Strategy:**
- Create test DI container with mock repositories
- Use `DIContainer+Testing.swift` helper
- Replace all `RepositoryFactory.shared` with `testContainer.resolve()`

---

### Tests/IntegrationTests.swift
**References in test setup**  
**Context:** Repository integration tests  

**Migration Strategy:**
- Use test DI container
- Inject test-specific repository configurations

---

## ViewModels Already Using DI ✅

These ViewModels are **already properly designed** with constructor injection:

1. **BudgetViewModel** - Accepts 4 dependencies via constructor
2. **InsightsViewModel** - Accepts 4 dependencies via constructor
3. **StatementUploadViewModel** - Accepts 4 dependencies (with defaults for backward compatibility)
4. **TransactionEntryViewModel** - Accepts dependencies via constructor
5. **BudgetCreationViewModel** - Accepts dependencies via constructor
6. **BatchCategorizationViewModel** - Accepts dependencies via constructor

**Note:** StatementUploadViewModel has default parameters in its constructor, which should be removed during migration.

---

## Views Creating Repositories Directly

Some views create repositories directly without using RepositoryFactory:

1. **RecurringTransactionSetupView** - Creates CoreDataTransactionRepository directly
2. **TransactionEntryView** (Preview) - Creates repositories for preview
3. **BudgetCreationView** (Preview) - Creates repositories for preview
4. **BudgetView** (Preview) - Creates repositories for preview

**Migration Strategy:**
- These are mostly in preview code, which is acceptable
- Production code should use DI container

---

## Migration Checklist

### Phase 1: Update Views to Use DI Container
- [ ] **MainTabView.swift**
  - [ ] Inject DI container via environment
  - [ ] Resolve BudgetViewModel from container (Line 38)
  - [ ] Resolve InsightsViewModel from container (Line 54)
  - [ ] Remove 6 RepositoryFactory.shared references

- [ ] **DashboardView.swift**
  - [ ] Inject DI container via environment
  - [ ] Resolve TransactionEntryViewModel from container (Line 78)
  - [ ] Resolve InsightsViewModel from container (Line 206)
  - [ ] Remove 4 RepositoryFactory.shared references

- [ ] **TransactionsListView.swift**
  - [ ] Inject DI container via environment
  - [ ] Resolve TransactionEntryViewModel from container (Line 65)
  - [ ] Remove 2 RepositoryFactory.shared references

### Phase 2: Update ViewModels
- [ ] **StatementUploadViewModel.swift**
  - [ ] Remove default parameters from constructor
  - [ ] Force dependency injection (no defaults)

### Phase 3: Update Tests
- [ ] **UIIntegrationTests.swift**
  - [ ] Create test DI container
  - [ ] Replace all RepositoryFactory.shared with container.resolve()
  - [ ] Use mock repositories from test container

- [ ] **IntegrationTests.swift**
  - [ ] Create test DI container
  - [ ] Replace RepositoryFactory.shared with container.resolve()

### Phase 4: Deprecate and Remove
- [ ] **RepositoryFactory.swift**
  - [ ] Mark `shared` property as deprecated with warning message
  - [ ] Add migration guide in deprecation comment
  - [ ] Verify zero references remain
  - [ ] Remove `shared` property entirely
  - [ ] Keep RepositoryFactory class for DI container to instantiate

---

## Migration Patterns

### Before (Current Pattern)
```swift
struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        BudgetView(viewModel: BudgetViewModel(
            budgetRepository: RepositoryFactory.shared.budgetRepository,
            budgetCategoryRepository: RepositoryFactory.shared.budgetCategoryRepository,
            transactionRepository: RepositoryFactory.shared.transactionRepository,
            context: viewContext
        ))
    }
}
```

### After (DI Container Pattern)
```swift
struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.diContainer) private var container
    
    var body: some View {
        BudgetView(viewModel: container.resolve(BudgetViewModel.self))
    }
}
```

---

## Risk Assessment

### Low Risk ✅
- Limited number of references (8 in production code)
- ViewModels already follow DI patterns
- Repository protocols are stable and well-designed
- Changes are isolated to View layer

### Medium Risk ⚠️
- Test files have multiple references that need updating
- Preview code may need adjustments
- Need to ensure DI container is properly initialized before Views

### Mitigation Strategies
1. **Incremental Migration:** Update one View at a time
2. **Parallel Running:** Keep RepositoryFactory.shared working during migration
3. **Comprehensive Testing:** Run full test suite after each View migration
4. **Rollback Plan:** Git branches for each phase

---

## Success Criteria

✅ Zero references to `RepositoryFactory.shared` in production Views  
✅ All ViewModels resolved from DI container  
✅ All tests use test DI container  
✅ RepositoryFactory.shared property removed  
✅ All existing tests pass  
✅ No user-facing functionality changes  

---

## Timeline Estimate

- **View Migration:** 2-3 hours (3 files, straightforward changes)
- **ViewModel Updates:** 1 hour (remove default parameters)
- **Test Migration:** 3-4 hours (multiple test files)
- **Verification & Testing:** 2 hours
- **Total:** ~8-10 hours

---

## Notes

1. The original estimate of "39+ references" appears to have been based on documentation or a different codebase state
2. Current codebase is in much better shape than anticipated
3. Most of the architectural work (DI in ViewModels) is already done
4. Migration is primarily a View-layer refactoring
5. StatementUploadViewModel has default parameters that should be removed for consistency

---

## Next Steps

1. ✅ Complete this audit (DONE)
2. Begin Task 7: Update ViewModels to remove default parameters
3. Begin Task 8: Update Views to resolve ViewModels from container
4. Begin Task 9: Update Tests to use DI container
5. Complete Task 10: Deprecate and remove RepositoryFactory singleton
