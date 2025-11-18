# Transaction Categorization and Rules Engine Implementation

## Overview
Implemented a comprehensive transaction categorization system with automatic pattern matching, user-defined rules, and batch processing capabilities.

## Components Implemented

### 1. Core Data Models
Added two new entities to the Core Data model:

#### CategorizationRule Entity
- Stores user-defined categorization rules
- Supports multiple match types (exact, contains, startsWith, regex)
- Includes priority system for conflict resolution
- Tracks application count and usage statistics
- Supports amount constraints (min/max)

#### MerchantPattern Entity
- Stores learned merchant patterns from user corrections
- Tracks confidence scores that improve with usage
- Maintains occurrence count and last used date
- Enables machine learning from user behavior

### 2. CategoryService (Services/CategoryService.swift)
Automatic transaction categorization service with:

**Features:**
- Built-in merchant patterns for common merchants (groceries, dining, transportation, etc.)
- Automatic categorization based on merchant names
- Confidence scoring for categorization decisions
- Learning from user corrections
- Pattern matching with similarity detection
- Merchant history tracking

**Key Methods:**
- `categorize(merchant:amount:)` - Categorizes a transaction
- `learnFromCorrection(merchant:category:)` - Learns from user corrections
- `getSuggestedCategories(for:)` - Returns multiple category suggestions
- `getMerchantHistory(for:)` - Returns category usage history for a merchant

**Categorization Priority:**
1. User-defined rules (highest priority)
2. Learned patterns from corrections
3. Built-in merchant patterns
4. Default to "Other" category

### 3. RuleEngine (Services/RuleEngine.swift)
User-defined rule management system with:

**Features:**
- CRUD operations for categorization rules
- Multiple match types (exact, contains, startsWith, regex)
- Priority-based rule ordering
- Amount constraints (min/max)
- Conflict detection and resolution
- Batch rule application
- Rule reordering

**Key Methods:**
- `createRule(...)` - Creates a new categorization rule
- `updateRule(...)` - Updates an existing rule
- `deleteRule(...)` - Deletes a rule
- `applyRulesToTransaction(...)` - Applies rules to a single transaction
- `applyRulesToTransactions(...)` - Batch applies rules with conflict detection
- `detectConflicts(for:)` - Detects conflicting rules for a transaction
- `reorderRules(...)` - Reorders rules by priority

**Conflict Resolution:**
- Detects when multiple rules match a transaction
- Applies highest priority rule automatically
- Reports conflicts for user review

### 4. CategorizationRulesView (Views/CategorizationRulesView.swift)
UI for managing categorization rules with:

**Features:**
- List view of all rules with status indicators
- Swipe actions for quick enable/disable/delete
- Drag-to-reorder for priority management
- Empty state with helpful guidance
- Rule editor with validation

**RuleEditorView:**
- Form-based rule creation/editing
- Match type selection with descriptions
- Category picker with icons
- Amount constraint toggles
- Priority stepper
- Input validation

### 5. CategorizationRulesViewModel (ViewModels/CategorizationRulesViewModel.swift)
ViewModel managing rule operations:

**Features:**
- Rule loading and caching
- CRUD operations with error handling
- Rule reordering
- Active/inactive toggle

### 6. BatchCategorizationView (Views/BatchCategorizationView.swift)
UI for batch categorization with:

**Features:**
- Statistics dashboard showing uncategorized count
- Options for uncategorized-only processing
- Conflict display toggle
- Processing progress indicator
- Results summary with detailed statistics
- Conflict resolution display

**Result Display:**
- Applied count
- Skipped count
- Conflict count
- Detailed conflict information

### 7. BatchCategorizationViewModel (ViewModels/BatchCategorizationViewModel.swift)
ViewModel managing batch operations:

**Features:**
- Uncategorized transaction loading
- Active rules count tracking
- Batch rule application
- Result management
- Error handling

## Transaction Categories

Predefined categories with icons:
- Groceries
- Dining & Restaurants
- Transportation
- Utilities
- Entertainment
- Shopping
- Healthcare
- Housing & Rent
- Education
- Travel
- Subscriptions
- Income
- Transfer
- Other

## Built-in Merchant Patterns

The system includes 30+ built-in patterns for common merchants:
- Grocery stores (Walmart, Target, Kroger, Safeway, Whole Foods, etc.)
- Restaurants (Starbucks, McDonald's, Chipotle, Subway, etc.)
- Gas stations (Shell, Chevron, Exxon, BP)
- Streaming services (Netflix, Spotify, Hulu, Disney+, HBO)
- Pharmacies (CVS, Walgreens)
- And many more...

## Match Types

Four match types for flexible pattern matching:

1. **Exact Match**: Merchant name must match exactly
2. **Contains**: Merchant name contains the pattern
3. **Starts With**: Merchant name starts with the pattern
4. **Regular Expression**: Advanced pattern matching with regex

## Learning System

The categorization engine learns from user corrections:
- Creates merchant patterns when users correct categories
- Increases confidence with each occurrence (up to 0.95)
- Tracks usage statistics
- Uses similarity matching to suggest categories for similar merchants

## Confidence Scoring

Confidence levels by source:
- User-defined rules: 0.95 (highest)
- Learned patterns: 0.7-0.95 (improves with usage)
- Built-in patterns: 0.8
- Default category: 0.3 (lowest)

## Integration Points

The categorization system integrates with:
- Transaction entry (manual and OCR)
- Transaction review flow
- Budget tracking
- Insights generation

## Usage Examples

### Creating a Rule
```swift
let rule = try await ruleEngine.createRule(
    name: "Coffee Shops",
    merchantPattern: "coffee",
    category: "Dining & Restaurants",
    matchType: .contains,
    priority: 10,
    minAmount: nil,
    maxAmount: 20.00
)
```

### Categorizing a Transaction
```swift
let result = try await categoryService.categorize(
    merchant: "Starbucks #1234",
    amount: 5.50
)
// Returns: CategorizationResult with category and confidence
```

### Learning from Correction
```swift
try await categoryService.learnFromCorrection(
    merchant: "Local Coffee Shop",
    category: "Dining & Restaurants"
)
```

### Batch Application
```swift
let result = try await ruleEngine.applyRulesToTransactions(transactions)
print("Applied: \(result.appliedCount)")
print("Conflicts: \(result.conflicts.count)")
```

## Requirements Satisfied

✅ **Requirement 5.1**: Automatic categorization based on merchant patterns
✅ **Requirement 5.2**: Learning from user corrections
✅ **Requirement 5.3**: Custom rule creation and management
✅ **Requirement 5.4**: Rule priority and conflict resolution
✅ **Requirement 5.5**: Batch categorization and rule application
✅ **Requirement 5.6**: Low confidence flagging for manual review

## Testing Recommendations

1. Test built-in pattern matching with common merchants
2. Test custom rule creation with all match types
3. Test rule priority and conflict resolution
4. Test learning system with repeated corrections
5. Test batch categorization with large transaction sets
6. Test amount constraints in rules
7. Test regex patterns for advanced matching
8. Test rule reordering and priority changes

## Future Enhancements

Potential improvements for future iterations:
- Import/export rules for sharing
- Rule templates for common scenarios
- Category suggestions based on amount ranges
- Time-based rules (e.g., weekday vs weekend)
- Location-based categorization (if location data available)
- Multi-merchant rules (e.g., all gas stations)
- Category hierarchies and subcategories
