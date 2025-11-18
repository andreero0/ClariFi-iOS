# Task 15: Update ViewModels to Use Injected Services - COMPLETE

## Overview
Successfully updated ViewModels to receive services via constructor injection instead of creating them directly, following the dependency injection pattern established in the architecture refactoring.

## Changes Made

### 1. BudgetViewModel
**Before:**
- Created `BudgetMonitoringService` instance directly in `setupMonitoringService()` method
- Used optional `monitoringService` property
- Had to pass all repository dependencies to create the service

**After:**
- Receives `BudgetMonitoringServiceProtocol` via constructor injection
- Non-optional `monitoringService` property (guaranteed to exist)
- Removed direct service instantiation
- Simplified `setupMonitoringService()` to only subscribe to alerts

**Files Modified:**
- `ViewModels/BudgetViewModel.swift`
  - Updated constructor to accept `monitoringService: BudgetMonitoringServiceProtocol`
  - Changed property from `var monitoringService: BudgetMonitoringService?` to `let monitoringService: BudgetMonitoringServiceProtocol`
  - Removed service instantiation code
  - Removed optional chaining (`?.`) from service method calls

- `Core/DependencyInjection/AppDIContainer+Registration.swift`
  - Updated `BudgetViewModel` registration to inject `BudgetMonitoringServiceProtocol`

### 2. InsightsViewModel
**Status:** ✅ Already Correct
- Already receiving `InsightsEngineProtocol` via constructor injection
- No direct service instantiation found
- No changes needed

### 3. StatementUploadViewModel
**Before:**
- Already receiving `OCRService` and `TransactionParserService` via constructor ✅
- BUT: Using `PersistenceController.shared.container.viewContext` directly ❌
- Missing `statementRepository` and `context` parameters

**After:**
- Added `statementRepository: any StatementRepository` parameter
- Added `context: NSManagedObjectContext` parameter
- Replaced `PersistenceController.shared.container.viewContext` with injected `context`
- Now fully using dependency injection for all dependencies

**Files Modified:**
- `ViewModels/StatementUploadViewModel.swift`
  - Added `statementRepository` and `context` properties
  - Updated constructor to accept both new parameters
  - Replaced `PersistenceController.shared.container.viewContext` with `context`

- `Core/DependencyInjection/AppDIContainer+Registration.swift`
  - Updated `StatementUploadViewModel` registration to inject `context`

## Verification

### No Direct Service Instantiation
Verified that the three target ViewModels have no:
- Direct service instantiation (e.g., `Service()`)
- Singleton access (e.g., `.shared`)
- Direct Core Data access (e.g., `PersistenceController.shared`)

### All Services Injected
✅ **InsightsViewModel:**
- `insightsEngine: InsightsEngineProtocol` ✓
- `transactionRepository: any TransactionRepository` ✓
- `budgetRepository: any BudgetRepository` ✓
- `context: NSManagedObjectContext` ✓

✅ **BudgetViewModel:**
- `budgetRepository: any BudgetRepository` ✓
- `budgetCategoryRepository: any BudgetCategoryRepository` ✓
- `transactionRepository: any TransactionRepository` ✓
- `monitoringService: BudgetMonitoringServiceProtocol` ✓
- `context: NSManagedObjectContext` ✓

✅ **StatementUploadViewModel:**
- `ocrService: OCRService` ✓
- `parserService: TransactionParserService` ✓
- `transactionRepository: any TransactionRepository` ✓
- `accountRepository: any AccountRepository` ✓
- `statementRepository: any StatementRepository` ✓
- `context: NSManagedObjectContext` ✓

### Compilation Status
All modified files compile without errors:
- ✅ ViewModels/BudgetViewModel.swift
- ✅ ViewModels/InsightsViewModel.swift
- ✅ ViewModels/StatementUploadViewModel.swift
- ✅ Core/DependencyInjection/AppDIContainer+Registration.swift

## Benefits Achieved

1. **Improved Testability**: ViewModels can now be tested with mock services
2. **Loose Coupling**: ViewModels depend on protocols, not concrete implementations
3. **Consistent Pattern**: All ViewModels follow the same dependency injection pattern
4. **No Singletons**: Eliminated direct singleton access from ViewModels
5. **Clear Dependencies**: Constructor signatures clearly show all dependencies

## Requirements Satisfied

✅ **Requirement 2.2**: Services initialized through DI container
✅ **Requirement 4.4**: ViewModels interact with services through protocol boundaries

## Next Steps

The next task in the implementation plan is:
- **Task 16**: Write service layer tests with mocks (optional)
- **Task 17**: Create BaseViewModel with common patterns

## Notes

- `SubscriptionViewModel` still has a convenience initializer that creates a service directly, but it was not part of the three ViewModels specified in this task
- `OnboardingViewModel` still uses `.shared` singleton access, but it was not part of this task
- These can be addressed in future refactoring tasks if needed
