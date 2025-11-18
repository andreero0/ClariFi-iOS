# Requirements Document

## Introduction

ClariFi is a privacy-first personal finance app that helps users take control of their spending without connecting live bank accounts. The app allows users to upload bank/card statements or enter transactions manually, using a privacy-first OCR/LLM pipeline to parse, categorize, and surface actionable insights. The core system is designed for gig workers, students, families, and busy professionals, offering customizable budgets, dual input modes, and optional premium insight tiers while maintaining complete data ownership and privacy.

## Requirements

### Requirement 1: Statement Upload and Processing

**User Story:** As a user, I want to upload bank/card statements (PDF, images) and have them parsed locally on my device, so that I can import my transaction data without compromising privacy.

#### Acceptance Criteria

1. WHEN a user selects a PDF, JPG, PNG, or HEIC file THEN the system SHALL accept the file and begin local OCR processing
2. WHEN the OCR processing completes THEN the system SHALL extract transaction data with confidence scores for each field
3. WHEN confidence scores are below 90% for any field THEN the system SHALL flag those fields for user review
4. WHEN duplicate statements are detected THEN the system SHALL warn the user and prevent duplicate imports
5. WHEN a password-protected PDF is uploaded THEN the system SHALL prompt for password and process after authentication
6. WHEN OCR processing fails THEN the system SHALL provide manual entry fallback options

### Requirement 2: Manual Transaction Entry

**User Story:** As a user, I want to manually enter transactions with smart autocomplete and categorization, so that I can track cash purchases and have complete control over my data.

#### Acceptance Criteria

1. WHEN a user opens the manual entry form THEN the system SHALL provide fields for date, merchant, amount, and category
2. WHEN a user types a merchant name THEN the system SHALL suggest previously entered merchants from local storage only
3. WHEN a user enters an amount THEN the system SHALL validate it as a valid currency amount
4. WHEN a user selects a category THEN the system SHALL save this preference for future merchant suggestions
5. WHEN a user enables recurring transaction THEN the system SHALL create a rule for automatic future categorization
6. WHEN a user saves a transaction THEN the system SHALL store it locally with encryption

### Requirement 3: Budget Creation and Management

**User Story:** As a user, I want to create and customize budgets with templates and categories, so that I can track my spending against my financial goals.

#### Acceptance Criteria

1. WHEN a user creates their first budget THEN the system SHALL offer starter templates (student, gig worker, family, professional)
2. WHEN a user selects a template THEN the system SHALL pre-populate categories with suggested amounts based on the template
3. WHEN a user customizes categories THEN the system SHALL allow adding, removing, and modifying category budgets
4. WHEN a user sets budget periods THEN the system SHALL support monthly and weekly cycles with rollover options
5. WHEN spending exceeds a category budget THEN the system SHALL provide visual indicators and optional notifications
6. WHEN a budget period ends THEN the system SHALL roll over unused amounts if enabled by user

### Requirement 4: Privacy Controls and Data Ownership

**User Story:** As a privacy-conscious user, I want complete control over my data processing and storage, so that I can use the app while maintaining my privacy preferences.

#### Acceptance Criteria

1. WHEN a user first launches the app THEN the system SHALL offer local-only processing as the default option
2. WHEN a user chooses local-only mode THEN the system SHALL process all data on-device without network requests
3. WHEN a user accesses the privacy dashboard THEN the system SHALL show current processing mode, data size, and consent status
4. WHEN a user requests data export THEN the system SHALL generate a complete export file locally
5. WHEN a user requests data deletion THEN the system SHALL permanently delete all local data with confirmation
6. WHEN a user opts into cloud processing THEN the system SHALL use end-to-end encryption and ephemeral processing
7. IF a user enables cloud processing THEN the system SHALL clearly explain benefits and risks before activation

### Requirement 5: Transaction Categorization and Rules

**User Story:** As a user, I want automatic transaction categorization with the ability to create custom rules, so that I can minimize manual work while maintaining accuracy.

#### Acceptance Criteria

1. WHEN a transaction is processed THEN the system SHALL attempt automatic categorization based on merchant and amount patterns
2. WHEN a user corrects a category THEN the system SHALL learn from this correction for future similar transactions
3. WHEN a user creates a custom rule THEN the system SHALL apply it to matching future transactions automatically
4. WHEN multiple rules could apply THEN the system SHALL use the most specific rule and flag conflicts for user review
5. WHEN a user batch-edits categories THEN the system SHALL apply changes to all selected transactions and update rules
6. WHEN categorization confidence is low THEN the system SHALL flag transactions for manual review

### Requirement 6: Insights and Recommendations

**User Story:** As a user, I want actionable insights about my spending patterns, so that I can make informed decisions to improve my financial health.

#### Acceptance Criteria

1. WHEN sufficient transaction data exists THEN the system SHALL generate spending trend insights
2. WHEN spending patterns change significantly THEN the system SHALL highlight these changes with explanations
3. WHEN budget thresholds are approached THEN the system SHALL provide proactive notifications if enabled
4. WHEN an insight is displayed THEN the system SHALL explain how it was calculated and what data was used
5. WHEN a user views an insight THEN the system SHALL provide actionable recommendations with specific steps
6. WHEN insights are generated THEN the system SHALL prioritize the most impactful recommendations first

### Requirement 7: Premium Features and Subscription

**User Story:** As a user interested in advanced features, I want access to forecasting and scenario planning capabilities, so that I can make better long-term financial decisions.

#### Acceptance Criteria

1. WHEN a user accesses premium features THEN the system SHALL show a clear paywall with feature previews
2. WHEN a user subscribes THEN the system SHALL validate the purchase through app store receipts
3. WHEN premium features are active THEN the system SHALL provide cashflow forecasting with confidence intervals
4. WHEN a user runs scenario planning THEN the system SHALL show impact of spending changes on future budgets
5. WHEN subscription expires THEN the system SHALL gracefully downgrade to free features without data loss
6. WHEN a user restores purchases THEN the system SHALL verify and reactivate premium features

### Requirement 8: Data Security and Offline Operation

**User Story:** As a user, I want the app to work completely offline while keeping my data secure, so that I can manage my finances regardless of connectivity.

#### Acceptance Criteria

1. WHEN the app is offline THEN the system SHALL provide full functionality for local-only processing
2. WHEN data is stored locally THEN the system SHALL encrypt it using device hardware security where available
3. WHEN the app starts THEN the system SHALL verify data integrity and handle corruption gracefully
4. WHEN storage space is low THEN the system SHALL warn users and provide cleanup options
5. WHEN the device is locked THEN the system SHALL require authentication to access financial data
6. WHEN the app is backgrounded THEN the system SHALL complete ongoing processing tasks safely