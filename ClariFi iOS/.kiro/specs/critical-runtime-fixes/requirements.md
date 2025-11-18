# Requirements Document

## Introduction

The ClariFi iOS codebase has critical runtime issues that prevent the application from building and running correctly. These issues stem from recent architectural changes including async currency formatter implementation, DI container API mismatches, and inconsistent service instantiation patterns. This specification addresses build-breaking bugs, test compilation failures, and data consistency issues that must be resolved before any organizational cleanup can proceed.

## Glossary

- **ClariFi_System**: The complete iOS financial management application
- **Currency_Formatter**: The async currency formatting system with actor-based caching in Models/Currency.swift
- **DI_Container**: The dependency injection container in Core/DependencyInjection/AppDIContainer.swift
- **Security_Audit_Service**: The security audit logging service with dual instantiation patterns
- **Analytics_Service**: The analytics tracking service with multiple implementations
- **Formatter_Cache**: The actor-based cache for currency formatters in Models/FormatterCache.swift
- **Test_Suite**: The unit and integration tests in ClariFi iOSTests directory
- **Widget_System**: The iOS widget and app intents implementation
- **Statement_Upload_System**: The statement processing and deduplication system
- **Insights_Engine**: The analytics and insights generation system

## Requirements

### Requirement 1: Fix Async Currency Formatter Contract

**User Story:** As a developer, I want the currency formatter API to be consistently async or sync so that the application compiles and runs without errors.

#### Acceptance Criteria

1. WHEN the Currency_Formatter formats amounts THEN it SHALL provide a consistent API contract (async or sync)
2. WHEN CurrencyPreferenceManager.format is called THEN it SHALL match the Currency_Formatter API signature
3. WHEN Decimal+Currency.swift extension formats values THEN it SHALL use the correct formatter method
4. WHEN Services call currency formatting THEN they SHALL use async context or formatSync appropriately
5. WHEN the formatter cache is accessed THEN it SHALL maintain thread safety through actor isolation
6. WHEN the application builds THEN it SHALL compile without async/await mismatches

### Requirement 2: Align DI Container API with Test Expectations

**User Story:** As a developer, I want the DI container API to match what tests expect so that the test suite compiles and runs successfully.

#### Acceptance Criteria

1. WHEN tests call registerTransient THEN the DI_Container SHALL provide this method
2. WHEN tests check for circular dependencies THEN the DI_Container SHALL throw errors instead of using fatalError
3. WHEN the DI_Container detects cycles THEN it SHALL provide recoverable error handling
4. WHEN tests verify lifecycle management THEN the DI_Container SHALL support transient registration
5. WHEN the test suite builds THEN it SHALL compile without missing method errors
6. WHEN DI tests run THEN they SHALL validate container behavior without crashes

### Requirement 3: Normalize Security Audit Service Instantiation

**User Story:** As a developer, I want a single source of truth for SecurityAuditService so that audit data is consistent across the application.

#### Acceptance Criteria

1. WHEN SecurityAuditService is needed THEN the ClariFi_System SHALL use DI injection exclusively
2. WHEN views access audit functionality THEN they SHALL NOT use SecurityAuditService.shared
3. WHEN audit events are logged THEN they SHALL go to a single service instance
4. WHEN BiometricSettingsView logs events THEN it SHALL use DI-injected service
5. WHEN SecurityAuditView displays logs THEN it SHALL use DI-injected service
6. WHEN the application runs THEN audit data SHALL be consistent across all components

### Requirement 4: Consolidate Analytics Service Implementation

**User Story:** As a developer, I want a single analytics implementation so that tracking is consistent and the codebase is maintainable.

#### Acceptance Criteria

1. WHEN analytics events are tracked THEN the ClariFi_System SHALL use one analytics implementation
2. WHEN the DI_Container resolves analytics THEN it SHALL register the active implementation only
3. WHEN AnalyticsService+Improved.swift exists THEN it SHALL either be used or removed
4. WHEN PostHogAnalyticsService is registered THEN it SHALL be the sole analytics provider
5. WHEN documentation references analytics THEN it SHALL describe the actual implementation
6. WHEN the codebase is audited THEN it SHALL contain no unused analytics implementations

### Requirement 5: Fix Scenario Planning Async Context

**User Story:** As a developer, I want scenario planning to correctly handle async currency formatting so that the service compiles and functions properly.

#### Acceptance Criteria

1. WHEN ScenarioPlanningService formats currency THEN it SHALL use async context or formatSync
2. WHEN scenario calculations run THEN they SHALL handle currency formatting without compilation errors
3. WHEN the service method signature is defined THEN it SHALL support async operations if needed
4. WHEN scenarios are generated THEN they SHALL format currency values correctly
5. WHEN the service builds THEN it SHALL compile without async/await violations
6. WHEN scenarios are displayed THEN they SHALL show properly formatted currency

### Requirement 6: Implement Statement Upload Persistence

**User Story:** As a user, I want statement deduplication to persist across app reinstalls so that I don't accidentally upload the same statement twice.

#### Acceptance Criteria

1. WHEN statements are uploaded THEN the Statement_Upload_System SHALL persist deduplication hashes
2. WHEN the app is reinstalled THEN the Statement_Upload_System SHALL retain upload history
3. WHEN checking for duplicates THEN the Statement_Upload_System SHALL query Core Data statements
4. WHEN a duplicate is detected THEN the Statement_Upload_System SHALL prevent re-upload
5. WHEN UserDefaults is used THEN it SHALL be replaced with Core Data persistence
6. WHEN upload history is needed THEN it SHALL be available from the statement entity

### Requirement 7: Move Insights Generation Off Main Actor

**User Story:** As a user, I want insights to load smoothly without UI freezing so that the app remains responsive during data processing.

#### Acceptance Criteria

1. WHEN insights are generated THEN the Insights_Engine SHALL perform heavy work on background threads
2. WHEN InsightsViewModel loads data THEN it SHALL not block the main actor
3. WHEN large datasets are processed THEN the ClariFi_System SHALL maintain UI responsiveness
4. WHEN insights complete THEN results SHALL be published on the main actor
5. WHEN concurrency tests run THEN they SHALL validate background processing
6. WHEN users view insights THEN the UI SHALL remain interactive during loading

### Requirement 8: Update Widget and AppIntent Implementation Status

**User Story:** As a developer, I want widgets and app intents to accurately reflect their implementation status so that users and QA have correct expectations.

#### Acceptance Criteria

1. WHEN widgets display data THEN they SHALL either use real data or be marked "Coming Soon"
2. WHEN ClariFiWidget.swift contains sample data THEN it SHALL be clearly marked as placeholder
3. WHEN ClariFiAppIntents.swift uses hardcoded values THEN it SHALL be documented as demo code
4. WHEN widgets format currency THEN they SHALL use the user's preference not hardcoded USD
5. WHEN documentation describes widgets THEN it SHALL accurately reflect implementation status
6. WHEN premium gating is needed THEN widgets SHALL check subscription status appropriately

### Requirement 9: Align Concurrency Tests with Production Code

**User Story:** As a developer, I want concurrency tests to validate actual production behavior so that tests provide meaningful verification.

#### Acceptance Criteria

1. WHEN MainActorIsolationTests run THEN they SHALL test actual production concurrency patterns
2. WHEN tests assume background snapshots THEN production code SHALL implement them or tests SHALL be updated
3. WHEN tests verify async formatting THEN production code SHALL use async formatting consistently
4. WHEN concurrency tests pass THEN they SHALL validate real application behavior
5. WHEN production code changes THEN tests SHALL be updated to match
6. WHEN the test suite runs THEN it SHALL accurately verify thread safety

### Requirement 10: Expand Repository Thread Safety Test Coverage

**User Story:** As a developer, I want comprehensive thread safety tests for all repositories so that concurrent access is safe across the application.

#### Acceptance Criteria

1. WHEN repository tests run THEN they SHALL cover all repository types not just transactions
2. WHEN AccountRepository is accessed concurrently THEN tests SHALL verify thread safety
3. WHEN BudgetRepository is accessed concurrently THEN tests SHALL verify thread safety
4. WHEN StatementRepository is accessed concurrently THEN tests SHALL verify thread safety
5. WHEN background context provider is used THEN tests SHALL validate its correctness
6. WHEN concurrent operations execute THEN repositories SHALL handle them safely

### Requirement 11: Update Documentation to Reflect Current Implementation

**User Story:** As a developer, I want documentation to accurately describe the current codebase so that I can understand and work with the actual implementation.

#### Acceptance Criteria

1. WHEN README is read THEN it SHALL describe current concurrency patterns
2. WHEN ARCHITECTURE.md is consulted THEN it SHALL document FormatterCache and async formatters
3. WHEN currency guides are referenced THEN they SHALL explain actor-based caching
4. WHEN test coverage docs are reviewed THEN they SHALL reflect current test suite
5. WHEN security docs are read THEN they SHALL accurately describe audit storage (UserDefaults vs Core Data)
6. WHEN widget docs are consulted THEN they SHALL match actual implementation status

### Requirement 12: Add Integration Tests for Critical Workflows

**User Story:** As a developer, I want integration tests for premium gating and currency preferences so that critical user workflows are validated.

#### Acceptance Criteria

1. WHEN premium features are accessed THEN integration tests SHALL verify gating behavior
2. WHEN SubscriptionViewModel.requirePremium is called THEN tests SHALL validate the flow
3. WHEN currency preferences change THEN integration tests SHALL verify UI updates
4. WHEN CurrencySettingsView is used THEN tests SHALL validate the complete workflow
5. WHEN critical paths are modified THEN integration tests SHALL catch regressions
6. WHEN the test suite runs THEN it SHALL cover end-to-end user scenarios
