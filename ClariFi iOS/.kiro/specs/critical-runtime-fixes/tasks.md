# Implementation Plan

- [x] 1. Fix async currency formatter contract to enable project compilation
  - Add synchronous formatter method to FormatterCache actor
  - Update CurrencyPreferenceManager to use sync formatter
  - Fix Decimal+Currency extension to use sync method
  - Update ScenarioPlanningService to handle currency formatting correctly
  - Verify project builds without async/await errors
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [x] 1.1 Add formatterSync method to FormatterCache actor
  - Implement synchronous formatter method in Models/FormatterCache.swift
  - Ensure method returns cached formatter or creates new one without await
  - Maintain thread safety through actor isolation
  - _Requirements: 1.1, 1.5_

- [x] 1.2 Update CurrencyPreferenceManager to use sync formatter
  - Modify format method in Models/Currency.swift:242 to use formatterSync
  - Add async formatAsync method for future async contexts
  - Ensure both methods work correctly with FormatterCache
  - _Requirements: 1.2, 1.4_

- [x] 1.3 Fix Decimal+Currency extension
  - Update Core/Extensions/Decimal+Currency.swift:12 to use sync formatter
  - Ensure extension methods compile without async violations
  - Test currency formatting across different locales
  - _Requirements: 1.3, 1.4_

- [x] 1.4 Fix ScenarioPlanningService currency formatting
  - Update Services/ScenarioPlanningService.swift:315 to use sync formatter
  - Verify method signature supports sync or async as needed
  - Test scenario generation with currency formatting
  - _Requirements: 1.4, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [x] 1.5 Verify project compilation
  - Build entire project to confirm no async/await errors
  - Check for any remaining formatter-related compilation issues
  - Document any edge cases discovered
  - _Requirements: 1.6_

- [x] 2. Enhance DI container API to match test expectations
  - Add DIError enum for throwable error handling
  - Implement registerTransient method for transient lifecycle
  - Add throwable resolve method with cycle detection
  - Update existing cycle detection to throw errors instead of fatalError
  - Verify test suite compiles and passes
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 2.1 Add DIError enum to DI container
  - Create DIError enum in Core/DependencyInjection/AppDIContainer.swift
  - Define error cases: circularDependency, resolutionFailed, duplicateRegistration
  - Implement LocalizedError protocol for user-friendly messages
  - _Requirements: 2.2, 2.3_

- [x] 2.2 Implement registerTransient method
  - Add registerTransient method to AppDIContainer
  - Create transientFactories storage dictionary
  - Ensure transient instances are created fresh on each resolution
  - _Requirements: 2.1, 2.4_

- [x] 2.3 Add throwable resolve method with cycle detection
  - Implement resolve method that throws DIError
  - Add resolutionStack for tracking dependency resolution chain
  - Detect circular dependencies and throw appropriate error
  - Support singleton, transient, and regular factory resolution
  - _Requirements: 2.2, 2.3, 2.5_

- [x] 2.4 Update cycle detection to use throwable errors
  - Replace fatalError at Core/DependencyInjection/AppDIContainer.swift:57 with throw
  - Ensure all cycle detection paths throw DIError.circularDependency
  - Maintain backward compatibility with existing non-throwing methods
  - _Requirements: 2.2, 2.3, 2.6_

- [x] 2.5 Verify test suite compilation and execution
  - Build test target to confirm no compilation errors
  - Run ClariFi iOSTests/DependencyInjection/DIContainerTests.swift
  - Verify registerTransient and cycle detection tests pass
  - _Requirements: 2.5, 2.6_

- [x] 3. Normalize service instantiation patterns
  - Remove SecurityAuditService singleton pattern
  - Update views to use DI-injected SecurityAuditService
  - Remove unused AnalyticsService+Improved implementation
  - Verify single source of truth for all services
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] 3.1 Remove SecurityAuditService singleton
  - Remove static shared property from Services/SecurityAuditService.swift
  - Ensure service is only instantiated through DI container
  - Verify DI registration exists in AppDIContainer+Registration.swift:96
  - _Requirements: 3.1, 3.2_

- [x] 3.2 Update BiometricSettingsView to use DI
  - Modify Views/BiometricSettingsView.swift:196 to inject SecurityAuditService
  - Update view initialization to accept DI container
  - Pass audit service to view model through constructor injection
  - _Requirements: 3.2, 3.4_

- [x] 3.3 Update SecurityAuditView to use DI
  - Modify Views/SecurityAuditView.swift:348 to inject SecurityAuditService
  - Update view initialization to accept DI container
  - Pass audit service to view model through constructor injection
  - _Requirements: 3.2, 3.5_

- [x] 3.4 Audit and remove unused analytics implementation
  - Review Services/AnalyticsService+Improved.swift:1 for unique functionality
  - Extract any useful batching logic if needed
  - Delete AnalyticsService+Improved.swift file
  - Verify PostHogAnalyticsService is the only registered implementation
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] 3.5 Verify service consistency across codebase
  - Search for any remaining .shared singleton patterns
  - Ensure all service access goes through DI container
  - Verify audit data consistency across all components
  - _Requirements: 3.3, 3.6_

- [x] 4. Move insights generation to background threads
  - Convert InsightsEngine to actor for background isolation
  - Update InsightsViewModel to use Task.detached for heavy work
  - Ensure results are published on main actor
  - Update concurrency tests to validate background processing
  - Verify UI responsiveness with large datasets
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [x] 4.1 Convert InsightsEngine to actor
  - Add actor keyword to Services/InsightsEngine.swift:38
  - Ensure all methods support async operations
  - Verify thread safety through actor isolation
  - _Requirements: 7.1, 7.2_

- [x] 4.2 Update InsightsViewModel for background processing
  - Modify ViewModels/InsightsViewModel.swift:43 to use Task.detached
  - Move heavy computation off main actor
  - Publish results on main actor after completion
  - Add loading state management
  - _Requirements: 7.2, 7.3, 7.4_

- [x] 4.3 Update concurrency tests
  - Modify ClariFi iOSTests/Concurrency/MainActorIsolationTests.swift:17
  - Add tests for background insights generation
  - Verify main actor is not blocked during processing
  - Test with large datasets to ensure performance
  - _Requirements: 7.5, 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [x] 4.4 Verify UI responsiveness
  - Test insights loading with 1000+ transactions
  - Ensure UI remains interactive during generation
  - Measure and document performance improvements
  - _Requirements: 7.6_

- [x] 5. Implement statement upload persistence
  - Add uploadHash and uploadedAt attributes to Statement entity
  - Update Core Data model and generate migration
  - Implement Core Data-based deduplication in StatementUploadViewModel
  - Remove in-memory and UserDefaults persistence
  - Test deduplication across app reinstalls
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 5.1 Update Statement Core Data entity
  - Add uploadHash (String, optional) to Statement entity
  - Add uploadedAt (Date, optional) to Statement entity
  - Add uploadSource (String, optional) for tracking upload method
  - Generate Core Data model migration
  - _Requirements: 6.1, 6.2_

- [x] 5.2 Implement Core Data-based deduplication
  - Add checkDuplicate method to ViewModels/StatementUploadViewModel.swift:56
  - Query Core Data for existing statements with matching uploadHash
  - Add markUploaded method to persist hash after successful upload
  - _Requirements: 6.3, 6.4_

- [x] 5.3 Remove legacy persistence mechanisms
  - Remove in-memory uploadedStatements set from StatementUploadViewModel
  - Remove UserDefaults-based persistence code
  - Clean up any related helper methods
  - _Requirements: 6.5_

- [x] 5.4 Test deduplication persistence
  - Test duplicate detection with existing statements
  - Test app reinstall scenario to verify persistence
  - Verify upload history is maintained correctly
  - _Requirements: 6.2, 6.6_

- [x] 6. Update widget and app intent implementation status
  - Decide on widget implementation approach (Coming Soon vs full implementation)
  - Update widget code to reflect accurate status
  - Remove hardcoded sample data and USD formatting
  - Connect to repositories if implementing fully
  - Update documentation to match implementation
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

- [x] 6.1 Audit current widget implementation
  - Review Widgets/ClariFiWidget.swift:27 for placeholder code
  - Review Services/ClariFiAppIntents.swift:46 for hardcoded values
  - Document what needs to be implemented vs marked as coming soon
  - _Requirements: 8.1, 8.2, 8.3_

- [x] 6.2 Update widget implementation
  - Either add "Coming Soon" badge or implement with real data
  - If implementing: connect to repositories via DI container
  - Remove hardcoded sample data from widget provider
  - Implement currency preference support (not hardcoded USD)
  - _Requirements: 8.1, 8.4, 8.5_

- [x] 6.3 Update app intents implementation
  - Remove hardcoded values from ClariFiAppIntents.swift
  - Implement premium gating if needed
  - Connect to actual data sources
  - _Requirements: 8.3, 8.6_

- [x] 6.4 Update widget documentation
  - Modify USER_GUIDE_UX_FEATURES.md:1 to reflect actual status
  - Document widget as "Coming Soon" or describe real functionality
  - Update any other docs referencing widgets
  - _Requirements: 8.5_

- [x] 7. Expand repository thread safety test coverage
  - Add thread safety tests for AccountRepository
  - Add thread safety tests for BudgetRepository
  - Add thread safety tests for StatementRepository
  - Verify background context provider correctness
  - Test concurrent operations across all repositories
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_

- [x] 7.1 Add AccountRepository thread safety tests
  - Create tests in ClariFi iOSTests/Repositories/
  - Test concurrent read operations
  - Test concurrent write operations
  - Test mixed read/write scenarios
  - _Requirements: 10.2, 10.6_

- [x] 7.2 Add BudgetRepository thread safety tests
  - Create tests in ClariFi iOSTests/Repositories/
  - Test concurrent budget creation and updates
  - Test concurrent budget queries
  - Verify no data corruption under concurrent access
  - _Requirements: 10.3, 10.6_

- [x] 7.3 Add StatementRepository thread safety tests
  - Create tests in ClariFi iOSTests/Repositories/
  - Test concurrent statement uploads
  - Test concurrent statement queries
  - Verify deduplication works under concurrent access
  - _Requirements: 10.4, 10.6_

- [x] 7.4 Verify background context provider
  - Test background context creation and lifecycle
  - Verify context isolation between threads
  - Test context save operations under concurrency
  - _Requirements: 10.5_

- [x] 7.5 Run comprehensive repository test suite
  - Execute all repository thread safety tests
  - Verify no race conditions or data corruption
  - Document any issues discovered
  - _Requirements: 10.1, 10.6_

- [x] 8. Add integration tests for critical workflows
  - Create premium gating integration tests
  - Create currency preference workflow tests
  - Test SubscriptionViewModel.requirePremium flow
  - Test CurrencySettingsView complete workflow
  - Verify end-to-end user scenarios
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6_

- [x] 8.1 Create premium gating integration tests
  - Test premium feature access for subscribed users
  - Test upgrade prompts for free users
  - Test subscription status changes
  - Verify ViewModels/SubscriptionViewModel.swift:27 requirePremium flow
  - _Requirements: 12.1, 12.2_

- [x] 8.2 Create currency preference integration tests
  - Test currency selection workflow
  - Test currency change propagation across views
  - Test Views/CurrencySettingsView.swift:120 complete flow
  - Verify all amounts update when currency changes
  - _Requirements: 12.3, 12.4_

- [x] 8.3 Verify critical path coverage
  - Review integration test coverage for main user flows
  - Add tests for any gaps in critical workflows
  - Document test scenarios and expected outcomes
  - _Requirements: 12.5, 12.6_

- [x] 9. Update documentation to reflect current implementation
  - Update README with concurrency patterns
  - Update ARCHITECTURE.md with FormatterCache and async formatters
  - Update currency guides with actor-based caching details
  - Update test coverage documentation
  - Update security documentation with accurate audit storage info
  - Update widget documentation to match implementation
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6_

- [x] 9.1 Update README with concurrency patterns
  - Document async/sync formatter usage patterns
  - Describe actor-based caching approach
  - Add examples of proper async/await usage
  - _Requirements: 11.1_

- [x] 9.2 Update ARCHITECTURE.md
  - Document FormatterCache actor implementation
  - Describe async formatter architecture
  - Update DI container documentation with new API
  - Document service instantiation patterns
  - _Requirements: 11.2_

- [x] 9.3 Update currency support guides
  - Modify docs/CURRENCY_SUPPORT_GUIDE.md:1 with actor caching details
  - Update HOW_TO_CHANGE_CURRENCY.md:1 with new formatter usage
  - Document sync vs async formatter methods
  - _Requirements: 11.3_

- [x] 9.4 Update test coverage documentation
  - Modify docs/reference/TEST_COVERAGE_ANALYSIS.md:1
  - Document new DI container tests
  - Document concurrency and thread safety tests
  - Document integration test coverage
  - _Requirements: 11.4_

- [x] 9.5 Update security and audit documentation
  - Correct ARCHITECTURE.md:109 regarding audit storage
  - Document actual UserDefaults usage vs Core Data
  - Describe DI-based service access pattern
  - _Requirements: 11.5_

- [x] 9.6 Update widget documentation
  - Modify USER_GUIDE_UX_FEATURES.md:1 to match widget status
  - Document actual widget implementation or "Coming Soon" status
  - Remove references to shipped features that are still stubbed
  - _Requirements: 11.6_

- [x] 10. Final validation and performance verification
  - Run complete test suite to verify all fixes
  - Perform manual smoke testing of critical features
  - Measure and document performance improvements
  - Create completion report with before/after metrics
  - _Requirements: 1.6, 2.6, 3.6, 7.6, 9.6, 12.6_

- [x] 10.1 Execute comprehensive test suite
  - Run all unit tests and verify pass rate > 95%
  - Run all integration tests
  - Run concurrency and thread safety tests
  - Document any remaining issues
  - _Requirements: 2.6, 9.6_

- [x] 10.2 Perform manual smoke testing
  - Test currency formatting across all views
  - Test statement upload and deduplication
  - Test insights loading with large datasets
  - Test premium gating workflows
  - _Requirements: 1.6, 7.6_

- [x] 10.3 Measure performance improvements
  - Benchmark insights loading time
  - Measure UI responsiveness during heavy operations
  - Compare before/after compilation times
  - Document performance metrics
  - _Requirements: 7.6_

- [x] 10.4 Create completion report
  - Document all fixes implemented
  - Create before/after comparison
  - List any remaining known issues
  - Provide recommendations for next steps
  - _Requirements: 3.6, 12.6_
