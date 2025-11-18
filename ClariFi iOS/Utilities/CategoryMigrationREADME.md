# Category Migration System

## Overview

The Category Migration system provides a robust solution for migrating legacy category names to canonical category names across all entities in the ClariFi iOS app. This ensures consistency between budgets, transactions, and all other category-related data.

## Problem Statement

Before the migration system, ClariFi had three different category naming systems:
1. Budget templates used names like "Housing & Rent", "Food & Groceries"
2. Transaction categorization used names like "Housing", "Dining Out"
3. User-entered categories could be anything

This caused mismatches where budget categories wouldn't match transaction categories, breaking the core budget tracking functionality.

## Solution

The migration system introduces:
1. **Canonical Category Names**: Single source of truth (e.g., `housing`, `food_groceries`)
2. **Legacy Mappings**: Comprehensive mapping of old names to canonical names
3. **Automatic Migration**: One-time migration of all existing data
4. **Version Tracking**: Ensures migration only runs once
5. **Validation**: Verifies all categories are canonical after migration

## Architecture

```
CategoryDefinition (Models/CategoryDefinition.swift)
    ↓
    Defines canonical categories with aliases
    
CategoryMigration (Utilities/CategoryMigration.swift)
    ↓
    Maps legacy names → canonical names
    ↓
    Migrates all entities in Core Data
    ↓
    Validates migration success
```

## Components

### 1. CategoryMigration.swift

Main migration utility with the following capabilities:

- **Migration Version Tracking**: Uses UserDefaults to track migration version
- **Legacy Mappings**: Comprehensive dictionary of old → new category names
- **Entity Migration**: Migrates all category-related entities:
  - Transactions
  - BudgetCategories
  - RecurringTransactions
  - CategorizationRules
  - MerchantPatterns
- **Validation**: Verifies all categories are canonical after migration

### 2. CategoryMigrationTests.swift

Comprehensive test suite covering:
- Category name mapping (exact match, variations, case-insensitive)
- Transaction migration
- Budget category migration
- Validation logic
- Edge cases (empty database, already migrated data)

### 3. CategoryMigrationExample.swift

Integration examples showing:
- How to run migration on app launch
- How to validate categories before saving
- How to trigger manual migration
- Integration points in the app

## Usage

### Automatic Migration on App Launch

Add to `ClariFi_iOSApp.swift`:

```swift
@main
struct ClariFi_iOSApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Run migration on app launch
        let context = persistenceController.container.viewContext
        Task {
            if CategoryMigration.isMigrationNeeded() {
                do {
                    let result = try await CategoryMigration.performMigration(context: context)
                    print("Migration completed: \(result.totalMigrated) items migrated")
                } catch {
                    print("Migration error: \(error)")
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
```

### Migrate Single Category Name

```swift
let legacyCategory = "Housing & Rent"
let canonicalCategory = CategoryMigration.migrateCategory(legacyCategory)
// Returns: "housing"
```

### Validate Categories

```swift
let result = try await CategoryMigration.validateMigration(context: context)
if result.isValid {
    print("All categories are canonical")
} else {
    print("Found \(result.totalInvalid) invalid categories")
}
```

## Migration Mappings

The system includes comprehensive mappings for all category variations:

### Housing
- "Housing" → `housing`
- "Housing & Rent" → `housing`
- "Housing (BAH)" → `housing`
- "Rent/Mortgage" → `housing`
- "Rent" → `housing`
- "Mortgage" → `housing`

### Food & Groceries
- "Food & Groceries" → `food_groceries`
- "Groceries" → `food_groceries`
- "Food" → `food_groceries`
- "Food & Dining" → `food_groceries`

### Dining
- "Dining & Restaurants" → `dining`
- "Dining Out" → `dining`
- "Restaurants" → `dining`
- "Eating Out" → `dining`

### Transportation
- "Transportation" → `transportation`
- "Car Payment" → `transportation`
- "Gas & Fuel" → `transportation`
- "Public Transit" → `transportation`
- "Vehicle Expenses" → `transportation`

...and many more (see `CategoryMigration.swift` for complete list)

## Migration Process

1. **Check Version**: Verify if migration is needed
2. **Migrate Transactions**: Update all transaction categories
3. **Migrate Budget Categories**: Update all budget category names
4. **Migrate Recurring Transactions**: Update recurring transaction categories
5. **Migrate Categorization Rules**: Update rule categories
6. **Migrate Merchant Patterns**: Update pattern categories
7. **Save Changes**: Persist all changes to Core Data
8. **Mark Complete**: Update migration version
9. **Validate**: Verify all categories are canonical

## Migration Results

The migration returns a `MigrationResult` with:

```swift
struct MigrationResult {
    let transactionsMigrated: Int
    let budgetCategoriesMigrated: Int
    let recurringTransactionsMigrated: Int
    let categorizationRulesMigrated: Int
    let merchantPatternsMigrated: Int
    var errors: [Error]
    
    var totalMigrated: Int
    var isSuccessful: Bool
}
```

## Validation

After migration, validate that all categories are canonical:

```swift
struct ValidationResult {
    var isValid: Bool
    var invalidTransactions: [String]
    var invalidBudgetCategories: [String]
    var invalidRecurringTransactions: [String]
    var invalidCategorizationRules: [String]
    var invalidMerchantPatterns: [String]
    
    var totalInvalid: Int
}
```

## Error Handling

The migration system handles errors gracefully:

- **Unknown Categories**: Default to "other" category
- **Case Sensitivity**: Performs case-insensitive matching
- **Already Migrated**: Skips categories that are already canonical
- **Empty Database**: Handles empty database without errors
- **Core Data Errors**: Catches and reports Core Data errors

## Testing

Run the test suite:

```bash
# Run all migration tests
xcodebuild test -scheme ClariFi_iOS -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ClariFi_iOSTests/CategoryMigrationTests

# Run specific test
xcodebuild test -scheme ClariFi_iOS -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ClariFi_iOSTests/CategoryMigrationTests/testMigrateCategoryWithExactMatch
```

## Performance Considerations

- **One-Time Operation**: Migration only runs once per installation
- **Batch Processing**: Processes all entities in single Core Data context
- **Efficient Lookups**: Uses dictionary for O(1) category lookups
- **Minimal Updates**: Only updates categories that actually changed

## Future Enhancements

Potential improvements for future versions:

1. **Progress Reporting**: Add progress callbacks for large migrations
2. **Rollback Support**: Add ability to rollback failed migrations
3. **Migration History**: Track detailed migration history
4. **Custom Mappings**: Allow users to define custom category mappings
5. **Incremental Migration**: Support multiple migration versions

## Troubleshooting

### Migration Not Running

Check if migration is needed:
```swift
if CategoryMigration.isMigrationNeeded() {
    print("Migration needed")
} else {
    print("Already migrated")
}
```

### Force Re-Migration

Clear migration version (for testing only):
```swift
UserDefaults.standard.removeObject(forKey: "CategoryMigrationVersion")
```

### Validation Failures

If validation fails after migration:
1. Check the `ValidationResult` for specific invalid categories
2. Review the legacy mappings in `CategoryMigration.swift`
3. Add missing mappings if needed
4. Re-run migration

## Related Files

- `Models/CategoryDefinition.swift` - Canonical category definitions
- `Services/CategoryMappingService.swift` - Category mapping service
- `Services/CategoryService.swift` - Category service using canonical names
- `Services/BudgetTemplateService.swift` - Budget templates using canonical names

## Requirements

Implements requirement 2.5 from the Critical UX Fixes spec:
- Map existing transaction categories to canonical names
- Map existing budget categories to canonical names
- Add migration version tracking
- Test migration with sample data
