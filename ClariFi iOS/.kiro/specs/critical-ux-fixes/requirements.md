# Requirements Document

## Introduction

This spec addresses critical user experience and architectural issues discovered during codebase analysis that prevent ClariFi from functioning as designed in the PRD. These issues block core user workflows and must be resolved before the app can be considered functional.

The analysis revealed six critical problems:
1. Broken authentication flow referencing non-existent views
2. Three conflicting category systems causing budget/transaction misalignment
3. Missing onboarding-to-first-action bridge
4. Ad-hoc account setup with no guided flow
5. Missing Apple Foundation Model integration for privacy-first LLM
6. Dependency injection anti-patterns causing state inconsistencies

## Requirements

### Requirement 1: Fix Broken Authentication Flow

**User Story:** As a new user, I want the app to launch without crashing so that I can start using ClariFi.

#### Acceptance Criteria

1. WHEN the app launches THEN the system SHALL NOT reference non-existent `AuthenticationView`
2. WHEN a user completes onboarding THEN the system SHALL navigate to the main interface without authentication errors
3. IF authentication is required in the future THEN the system SHALL have a proper authentication view implementation
4. WHEN the app is in development mode THEN the system SHALL provide a way to bypass authentication for testing

### Requirement 2: Unify Category System

**User Story:** As a user creating a budget, I want transaction categories to match my budget categories so that my spending tracking is accurate.

#### Acceptance Criteria

1. WHEN a user selects a budget template THEN the system SHALL use canonical category names
2. WHEN a user adds a transaction THEN the system SHALL show the same categories as their active budget
3. WHEN the system categorizes transactions THEN it SHALL use the same category names across all services
4. IF a budget has "Housing" category THEN the transaction entry SHALL also have "Housing" as an option
5. WHEN categories are displayed THEN the system SHALL use consistent naming (e.g., not "Food & Dining" vs "Food & Groceries" vs "Dining & Restaurants")
6. WHEN a user creates a custom category THEN it SHALL be available in both budgets and transactions

### Requirement 3: Complete Onboarding-to-Action Flow

**User Story:** As a new user, I want clear guidance after onboarding so that I know how to start tracking my finances.

#### Acceptance Criteria

1. WHEN a user completes onboarding THEN the system SHALL present a "Quick Start" screen
2. WHEN on the Quick Start screen THEN the system SHALL offer two clear options: "Upload Statement" or "Add Transaction Manually"
3. WHEN a user selects an option THEN the system SHALL guide them through that first action
4. WHEN a user completes their first action THEN the system SHALL show a success state with next steps
5. WHEN a user has no accounts THEN the system SHALL prompt account creation before transaction entry
6. IF a user skips the first action THEN the system SHALL provide easy access to start later

### Requirement 4: Integrate Account Setup into Onboarding

**User Story:** As a new user, I want to set up my accounts during onboarding so that I can immediately start tracking transactions.

#### Acceptance Criteria

1. WHEN a user progresses through onboarding THEN the system SHALL include an account setup step
2. WHEN on the account setup step THEN the system SHALL allow creating one or more accounts
3. WHEN a user creates an account THEN the system SHALL validate required fields (account name, type)
4. IF a user skips account setup THEN the system SHALL create a default "Cash" account automatically
5. WHEN account setup is complete THEN the system SHALL set the first account as the default for transactions
6. WHEN a user later adds transactions THEN the system SHALL remember their accounts from onboarding

### Requirement 5: Implement Apple Foundation Model Integration

**User Story:** As a privacy-conscious user, I want intelligent transaction parsing without cloud processing so that my financial data never leaves my device.

#### Acceptance Criteria

1. WHEN the system processes a statement THEN it SHALL use Apple Foundation Model for on-device LLM processing
2. WHEN extracting transaction data THEN the system SHALL use LLM for merchant name normalization
3. WHEN categorizing transactions THEN the system SHALL use LLM for intelligent category prediction
4. WHEN parsing amounts and dates THEN the system SHALL use LLM with contextual understanding
5. IF Apple Foundation Model is unavailable THEN the system SHALL fall back to regex pattern matching
6. WHEN processing any financial data THEN the system SHALL NOT make network calls to external LLM services
7. WHEN using the LLM THEN the system SHALL maintain privacy guarantees per the PRD

### Requirement 6: Fix Dependency Injection Architecture

**User Story:** As a developer, I want consistent dependency injection so that the app has predictable behavior and shared state.

#### Acceptance Criteria

1. WHEN the app launches THEN the system SHALL create a single `DependencyContainer` instance
2. WHEN ViewModels are initialized THEN they SHALL receive dependencies from the shared container
3. WHEN multiple views access repositories THEN they SHALL use the same repository instances
4. WHEN services maintain state THEN that state SHALL be shared across the application
5. IF a ViewModel needs dependencies THEN it SHALL NOT create new `DependencyContainer` instances
6. WHEN the app is running THEN there SHALL be no memory leaks from multiple container instances

### Requirement 7: Category System Architecture

**User Story:** As a developer, I want a single source of truth for categories so that all features use consistent category definitions.

#### Acceptance Criteria

1. WHEN the system defines categories THEN it SHALL use a canonical `CategoryDefinition` model
2. WHEN budget templates define categories THEN they SHALL map to canonical category names
3. WHEN the transaction entry shows categories THEN it SHALL use canonical category names
4. WHEN the categorization service predicts categories THEN it SHALL return canonical category names
5. IF a category has multiple display names THEN the system SHALL maintain a mapping to the canonical name
6. WHEN categories are persisted THEN the system SHALL store canonical names only
7. WHEN displaying categories to users THEN the system SHALL use appropriate display names for context

### Requirement 8: Progressive Disclosure in Onboarding

**User Story:** As a new user, I want a streamlined onboarding experience so that I can start using the app quickly without feeling overwhelmed.

#### Acceptance Criteria

1. WHEN a user starts onboarding THEN the system SHALL show 4 welcome screens maximum
2. WHEN explaining features THEN the system SHALL use simple, clear language
3. WHEN collecting user information THEN the system SHALL only ask for essential data
4. IF advanced features exist THEN the system SHALL introduce them progressively after first use
5. WHEN a user wants to skip onboarding THEN the system SHALL allow it with a clear skip option
6. WHEN onboarding is complete THEN the system SHALL remember completion status

### Requirement 9: First-Time User Experience

**User Story:** As a new user, I want to complete my first transaction within 5 minutes so that I can quickly see the value of ClariFi.

#### Acceptance Criteria

1. WHEN a user completes onboarding THEN they SHALL be able to add their first transaction within 5 minutes
2. WHEN adding the first transaction THEN the system SHALL provide helpful hints and guidance
3. WHEN the first transaction is saved THEN the system SHALL show a celebration/success state
4. WHEN viewing the first transaction THEN the system SHALL suggest next actions (e.g., "Add a budget")
5. IF a user uploads a statement first THEN the system SHALL process it and show results within 30 seconds
6. WHEN the first action is complete THEN the system SHALL provide clear navigation to other features

### Requirement 10: Error Recovery and Validation

**User Story:** As a user, I want clear error messages and validation so that I can correct mistakes easily.

#### Acceptance Criteria

1. WHEN a user enters invalid data THEN the system SHALL show specific, actionable error messages
2. WHEN a required field is empty THEN the system SHALL indicate which field needs attention
3. WHEN a validation error occurs THEN the system SHALL NOT lose user-entered data
4. IF a system error occurs THEN the system SHALL provide a user-friendly explanation
5. WHEN an error is recoverable THEN the system SHALL suggest how to fix it
6. WHEN a critical error occurs THEN the system SHALL log details for debugging while showing a simple message to users
