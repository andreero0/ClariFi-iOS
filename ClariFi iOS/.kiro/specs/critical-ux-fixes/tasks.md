# Implementation Plan

## Overview

This implementation plan breaks down the critical UX fixes into discrete, manageable tasks. Tasks are organized by phase and priority, with each task building incrementally on previous work.

## Task List

- [x] 1. Phase 1: Emergency Fixes (Critical - Week 1)
  - Fix broken authentication flow and immediate blockers
  - _Requirements: 1.1, 1.2, 6.1, 6.2_

- [x] 1.1 Remove broken AuthenticationView reference from ContentView
  - Update ContentView.swift to remove non-existent AuthenticationView
  - Temporarily skip authentication check (set isAuthenticated = true)
  - Add TODO comment for future authentication implementation
  - Test app launches without crashes
  - _Requirements: 1.1, 1.2_

- [x] 1.2 Create CategoryDefinition model
  - Create Models/CategoryDefinition.swift with struct definition
  - Define all canonical categories (housing, food_groceries, dining, etc.)
  - Add displayName, icon, parentCategory, isEssential properties
  - Add budgetTemplateAliases array for mapping template names
  - Create static allCategories array with all predefined categories
  - _Requirements: 2.1, 2.2, 7.1, 7.2_

- [x] 1.3 Create CategoryMappingService
  - Create Services/CategoryMappingService.swift
  - Implement getCanonicalCategory(from:) method
  - Implement getDisplayName(for:) method
  - Implement getAllCategories() method
  - Implement getCategoriesForBudgetTemplate(_:) method
  - Add unit tests for category mapping logic
  - _Requirements: 2.1, 2.2, 7.3, 7.4_

- [x] 1.4 Fix DI container environment key
  - Create Core/DependencyInjection/DIContainerEnvironmentKey.swift
  - Define DIContainerKey as EnvironmentKey
  - Extend EnvironmentValues with diContainer property
  - Update ClariFi_iOSApp.swift to inject container via environment
  - _Requirements: 6.1, 6.2, 6.3_

- [x] 1.5 Update ClariFi_iOSApp to register dependencies
  - Create single AppDIContainer instance in app init
  - Implement registerDependencies() method
  - Register all repositories as singletons
  - Register CategoryMappingService as singleton
  - Register CategoryService with proper dependencies
  - Inject container via .environment(\.diContainer, container)
  - _Requirements: 6.1, 6.2, 6.4_

- [x] 2. Phase 2: Category System Unification (High Priority - Week 2)
  - Unify all category systems to use canonical names
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 2.1 Update TransactionCategory enum to use CategoryDefinition
  - Modify Services/CategoryService.swift
  - Replace TransactionCategory enum with CategoryDefinition references
  - Update categorize() method to return canonical names
  - Update all pattern matching to use canonical names
  - Ensure backward compatibility with existing data
  - _Requirements: 2.1, 2.3, 7.3_

- [x] 2.2 Update BudgetTemplateService to use canonical categories
  - Modify Services/BudgetTemplateService.swift
  - Update all template category names to use CategoryDefinition
  - Add mapping from template-specific names to canonical names
  - Update createBudgetFromTemplate() to use canonical names
  - Test all 18 budget templates map correctly
  - _Requirements: 2.1, 2.2, 7.2_

- [x] 2.3 Update TransactionEntryViewModel to use CategoryMappingService
  - Modify ViewModels/TransactionEntryViewModel.swift
  - Replace hardcoded availableCategories array
  - Inject CategoryMappingService via DI container
  - Use categoryMappingService.getAllCategories() for dropdown
  - Display category.displayName in UI
  - Store category.canonicalName in transaction
  - _Requirements: 2.1, 2.2, 2.3, 6.2_

- [x] 2.4 Update BudgetViewModel to use canonical categories
  - Modify ViewModels/BudgetViewModel.swift
  - Inject CategoryMappingService via DI container
  - Use canonical names for budget category tracking
  - Display mapped display names in UI
  - Ensure budget vs transaction category matching
  - _Requirements: 2.1, 2.2, 2.4_

- [x] 2.5 Update Transaction model to store canonical categories
  - Modify Models/Transaction.swift (or Core Data entity)
  - Add canonicalCategory field
  - Add displayCategory field (computed or stored)
  - Add categorizationMethod enum field
  - Update all transaction creation to use canonical names
  - _Requirements: 2.3, 7.6_

- [x] 2.6 Update Budget model to store canonical categories
  - Modify Models/Budget.swift (or Core Data entity)
  - Update BudgetCategory to use canonicalName
  - Add displayName field
  - Add templateId field to track source template
  - Update all budget creation to use canonical names
  - _Requirements: 2.1, 2.2, 7.6_

- [x] 2.7 Create data migration script for existing categories
  - Create Utilities/CategoryMigration.swift
  - Implement migration logic to convert old category names
  - Map existing transaction categories to canonical names
  - Map existing budget categories to canonical names
  - Add migration version tracking
  - Test migration with sample data
  - _Requirements: 2.5_

- [x] 2.8 Write integration tests for category consistency
  - Create Tests/IntegrationTests/CategoryConsistencyTests.swift
  - Test budget creation from template
  - Test transaction entry with budget categories
  - Test category matching across budget and transactions
  - Verify no category name mismatches
  - _Requirements: 2.1, 2.2, 2.4_

- [x] 3. Phase 3: Enhanced Onboarding Flow (High Priority - Week 2-3)
  - Add account setup and quick start guidance to onboarding
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 3.1 Create OnboardingCoordinator
  - Create ViewModels/OnboardingCoordinator.swift
  - Define OnboardingStep enum with all steps
  - Add @Published properties for state management
  - Implement advance() and canAdvance() methods
  - Add validation logic for each step
  - _Requirements: 3.1, 8.1, 8.2_

- [x] 3.2 Create AccountSetupData model
  - Create Models/AccountSetupData.swift
  - Define struct with name, type, initialBalance, isDefault
  - Define AccountType enum
  - Add validation methods
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 3.3 Create AccountSetupStepView for onboarding
  - Create Views/Onboarding/AccountSetupStepView.swift
  - Design UI for adding accounts during onboarding
  - Allow adding multiple accounts
  - Mark first account as default
  - Add "Skip" option that creates default Cash account
  - Integrate with OnboardingCoordinator
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 3.4 Create QuickStartView
  - Create Views/Onboarding/QuickStartView.swift
  - Define FirstActionType enum (uploadStatement, manualEntry, createBudget)
  - Design UI with three action cards
  - Add selection state management
  - Add clear descriptions for each option
  - _Requirements: 3.1, 3.2, 9.1_

- [x] 3.5 Create FirstActionGuidanceView
  - Create Views/Onboarding/FirstActionGuidanceView.swift
  - Show different guidance based on selected action
  - For uploadStatement: Navigate to StatementUploadView
  - For manualEntry: Navigate to TransactionEntryView
  - For createBudget: Navigate to BudgetCreationView
  - Add contextual hints and tips
  - _Requirements: 3.3, 3.4, 9.2, 9.3_

- [x] 3.6 Update OnboardingView to include new steps
  - Modify Views/OnboardingView.swift
  - Add AccountSetupStepView as step 4
  - Add QuickStartView as step 6
  - Add FirstActionGuidanceView as step 7
  - Update TabView to include all steps
  - Update step progression logic
  - _Requirements: 3.1, 3.5, 8.1_

- [x] 3.7 Update OnboardingViewModel to use OnboardingCoordinator
  - Modify ViewModels/OnboardingViewModel.swift
  - Integrate OnboardingCoordinator
  - Add account creation logic
  - Add first action tracking
  - Update completeOnboarding() to save accounts
  - _Requirements: 3.6, 4.6, 9.1_

- [x] 3.8 Create success celebration view
  - Create Views/Onboarding/OnboardingSuccessView.swift
  - Show celebration animation/icon
  - Display "What's Next" guidance
  - Show summary of setup (accounts created, action selected)
  - Add "Get Started" button to complete onboarding
  - _Requirements: 3.4, 9.3, 9.4_

- [x] 3.9 Write UI tests for onboarding flow
  - Create Tests/UITests/OnboardingFlowTests.swift
  - Test complete onboarding flow from start to finish
  - Test account creation step
  - Test quick start selection
  - Test skip functionality
  - Test back navigation
  - _Requirements: 3.1, 3.2, 3.3, 8.1_

- [x] 4. Phase 4: Apple Foundation Model Integration (Medium Priority - Week 3-4)
  - Add privacy-first LLM for intelligent categorization
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_

- [x] 4.1 Create AppleFoundationModelManager
  - Create Services/LLM/AppleFoundationModelManager.swift
  - Implement model loading logic
  - Add isAvailable property
  - Implement query(prompt:) method
  - Add error handling for model unavailability
  - Add timeout logic (5 seconds)
  - _Requirements: 5.1, 5.6_

- [x] 4.2 Create LLMCategorizationService protocol
  - Create Services/LLM/LLMCategorizationServiceProtocol.swift
  - Define categorizeWithLLM method
  - Define normalizeMerchantName method
  - Define extractTransactionData method
  - Add CategorizationMethod enum
  - _Requirements: 5.2, 5.3, 5.4_

- [x] 4.3 Implement AppleLLMCategorizationService
  - Create Services/LLM/AppleLLMCategorizationService.swift
  - Implement categorizeWithLLM with fallback logic
  - Implement normalizeMerchantName with fallback
  - Implement extractTransactionData with fallback
  - Add prompt construction methods
  - Add response parsing methods
  - Ensure no network calls are made
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [x] 4.4 Update CategoryService to use LLM service
  - Modify Services/CategoryService.swift
  - Inject LLMCategorizationService via DI
  - Update categorize() to try LLM first
  - Fall back to pattern matching if LLM unavailable
  - Track categorization method in result
  - _Requirements: 5.1, 5.5_

- [x] 4.5 Register LLM service in DI container
  - Update ClariFi_iOSApp.swift registerDependencies()
  - Register AppleFoundationModelManager as singleton
  - Register LLMCategorizationService with dependencies
  - Ensure proper fallback chain
  - _Requirements: 5.1, 6.2_

- [x] 4.6 Add LLM categorization to statement upload flow
  - Update StatementUploadViewModel
  - Use LLM for merchant name normalization
  - Use LLM for transaction data extraction
  - Use LLM for category prediction
  - Show confidence scores in UI
  - _Requirements: 5.2, 5.3, 5.4_

- [x] 4.7 Write unit tests for LLM service
  - Create Tests/UnitTests/LLMCategorizationServiceTests.swift
  - Test fallback behavior when LLM unavailable
  - Test prompt construction
  - Test response parsing
  - Test error handling
  - Test timeout behavior
  - _Requirements: 5.5, 5.6_

- [x] 4.8 Add performance monitoring for LLM
  - Create Utilities/LLMPerformanceMonitor.swift
  - Track LLM query times
  - Track fallback frequency
  - Track categorization accuracy
  - Add logging for debugging
  - _Requirements: 5.1, 5.5_

- [x] 5. Phase 5: Fix Remaining ViewModels DI (Medium Priority - Week 3)
  - Update all ViewModels to use injected dependencies
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 5.1 Update BudgetCreationViewModel DI
  - Modify ViewModels/BudgetCreationViewModel.swift
  - Add init(container:) method
  - Resolve dependencies from container
  - Remove direct DependencyContainer instantiation
  - Update BudgetCreationView to inject container
  - _Requirements: 6.2, 6.3_

- [x] 5.2 Update StatementUploadViewModel DI
  - Modify ViewModels/StatementUploadViewModel.swift
  - Add init(container:) method
  - Resolve dependencies from container
  - Remove direct DependencyContainer instantiation
  - Update StatementUploadView to inject container
  - _Requirements: 6.2, 6.3_

- [x] 5.3 Update InsightsViewModel DI
  - Modify ViewModels/InsightsViewModel.swift
  - Add init(container:) method
  - Resolve dependencies from container
  - Remove direct DependencyContainer instantiation
  - Update InsightsView to inject container
  - _Requirements: 6.2, 6.3_

- [x] 5.4 Update PrivacyDashboardViewModel DI
  - Modify ViewModels/PrivacyDashboardViewModel.swift
  - Add init(container:) method
  - Resolve dependencies from container
  - Remove direct DependencyContainer instantiation
  - Update PrivacyDashboardView to inject container
  - _Requirements: 6.2, 6.3_

- [x] 5.5 Update TransactionReviewViewModel DI
  - Modify ViewModels/TransactionReviewViewModel.swift
  - Add init(container:) method
  - Resolve dependencies from container
  - Remove direct DependencyContainer instantiation
  - Update TransactionReviewView to inject container
  - _Requirements: 6.2, 6.3_

- [x] 5.6 Audit all ViewModels for DI compliance
  - Create script to scan all ViewModels
  - Verify no direct DependencyContainer() instantiation
  - Verify all use init(container:) pattern
  - Create report of any remaining issues
  - _Requirements: 6.1, 6.2, 6.5_

- [x] 5.7 Write integration test for DI container lifecycle
  - Create Tests/IntegrationTests/DIContainerLifecycleTests.swift
  - Verify single container instance throughout app
  - Verify shared repository state
  - Verify no memory leaks
  - Test container reset functionality
  - _Requirements: 6.1, 6.3, 6.4, 6.6_

- [x] 6. Phase 6: Error Handling & Validation (Low Priority - Week 4)
  - Add proper error handling and user feedback
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_

- [x] 6.1 Create CategoryMappingError enum
  - Create Models/Errors/CategoryMappingError.swift
  - Define error cases (categoryNotFound, ambiguousMapping, etc.)
  - Implement LocalizedError protocol
  - Add user-friendly error messages
  - _Requirements: 10.1, 10.4_

- [x] 6.2 Create OnboardingError enum
  - Create Models/Errors/OnboardingError.swift
  - Define error cases (accountCreationFailed, etc.)
  - Implement LocalizedError protocol
  - Add user-friendly error messages
  - _Requirements: 10.1, 10.4_

- [x] 6.3 Add validation to AccountSetupStepView
  - Add real-time validation for account name
  - Show error messages for invalid input
  - Prevent advancing with invalid data
  - Preserve user input on validation errors
  - _Requirements: 10.1, 10.2, 10.3_

- [x] 6.4 Add validation to TransactionEntryView
  - Add real-time validation for required fields
  - Show specific error messages
  - Highlight invalid fields
  - Preserve user input on validation errors
  - _Requirements: 10.1, 10.2, 10.3_

- [x] 6.5 Add error recovery for LLM failures
  - Add user-friendly error messages for LLM failures
  - Show fallback categorization in UI
  - Allow manual category override
  - Log errors for debugging
  - _Requirements: 10.4, 10.5, 10.6_

- [x] 6.6 Add error recovery for category mapping failures
  - Handle missing category mappings gracefully
  - Default to "Other" category with warning
  - Allow user to correct category
  - Log mapping failures for improvement
  - _Requirements: 10.4, 10.5_

- [x] 7. Phase 7: Polish & Optimization (Low Priority - Week 4)
  - Performance optimization and final polish
  - _Requirements: 8.3, 8.4, 8.5, 9.5, 9.6_

- [x] 7.1 Add loading states to onboarding
  - Show loading indicators during account creation
  - Show loading indicators during LLM queries
  - Add skeleton screens for better UX
  - Ensure smooth transitions
  - _Requirements: 8.3, 9.5_

- [x] 7.2 Add success animations
  - Add celebration animation on onboarding completion
  - Add success animation on first transaction
  - Add success animation on budget creation
  - Use SF Symbols animations
  - _Requirements: 9.3, 9.4_

- [x] 7.3 Optimize category lookup performance
  - Create in-memory cache for CategoryDefinition
  - Use dictionary for O(1) canonical name lookup
  - Lazy load category mappings
  - Measure and optimize lookup times
  - _Requirements: 8.4_

- [x] 7.4 Optimize LLM performance
  - Implement response caching for repeated queries
  - Add request debouncing
  - Optimize prompt length
  - Measure and optimize query times
  - _Requirements: 5.1, 9.5_

- [x] 7.5 Add analytics for onboarding flow
  - Track onboarding step completion rates
  - Track time spent on each step
  - Track first action selection distribution
  - Track onboarding abandonment points
  - _Requirements: 8.5, 9.1_

- [x] 7.6 Add accessibility improvements
  - Add VoiceOver labels to all onboarding steps
  - Add VoiceOver hints for actions
  - Test with VoiceOver enabled
  - Add Dynamic Type support
  - Ensure color contrast meets WCAG standards
  - _Requirements: 8.3_

- [x] 7.7 Performance testing and optimization
  - Measure app launch time
  - Measure onboarding step transition times
  - Measure LLM query times
  - Measure category lookup times
  - Optimize any bottlenecks
  - _Requirements: 9.5_

- [x] 7.8 Final integration testing
  - Test complete user journey from install to first transaction
  - Test all budget templates with transactions
  - Test LLM categorization with real statements
  - Test error scenarios
  - Test on multiple device sizes
  - _Requirements: 9.6_

## Task Execution Notes

### Priority Levels
- **Phase 1**: Critical - Must be completed first (app is broken without these)
- **Phase 2-3**: High Priority - Core functionality improvements
- **Phase 4**: Medium Priority - Enhanced features (LLM)
- **Phase 5-7**: Medium-Low Priority - Polish and optimization

### Dependencies
- Phase 2 depends on Phase 1 (CategoryDefinition must exist)
- Phase 3 can be done in parallel with Phase 2
- Phase 4 depends on Phase 2 (needs CategoryDefinition)
- Phase 5 depends on Phase 1 (needs DI container fix)
- Phase 6-7 can be done after core functionality is complete

### Testing Strategy
- Unit tests marked with * are optional but recommended
- Integration tests should be run after each phase
- UI tests should be run before final release
- Manual testing required for onboarding flow

### Success Criteria
- App launches without crashes ✓
- Categories are consistent across budget and transactions ✓
- Onboarding guides user to first action ✓
- Time to first transaction < 5 minutes ✓
- LLM categorization works or falls back gracefully ✓
- Single DI container instance throughout app ✓
