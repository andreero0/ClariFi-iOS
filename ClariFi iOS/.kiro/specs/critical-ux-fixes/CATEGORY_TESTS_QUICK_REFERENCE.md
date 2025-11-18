# Category Consistency Tests - Quick Reference

## Test File Location
```
Tests/IntegrationTests/CategoryConsistencyTests.swift
```

## Running Tests

### Run All Category Consistency Tests
```bash
xcodebuild test -scheme "ClariFi iOS" \
  -only-testing:ClariFi_iOSTests/CategoryConsistencyTests
```

### Run Individual Test Methods

#### Budget Creation Tests
```bash
# Test budget templates use canonical categories
xcodebuild test -scheme "ClariFi iOS" \
  -only-testing:ClariFi_iOSTests/CategoryConsistencyTests/testBudgetCreationFromTemplate_UsesCanonicalCategories

# Test all templates have valid categories
xcodebuild test -scheme "ClariFi iOS" \
  -only-testing:ClariFi_iOSTests/CategoryConsistencyTests/testBudgetCreationFromTemplate_AllTemplatesHaveValidCategories

# Test budget creation consistency
xcodebuild test -scheme "ClariFi iOS" \
  -only-testing:ClariFi_iOSTests/CategoryConsistencyTests/testBudgetCreationFromTemplate_CreatesConsistentBudget
```

#### Transaction Entry Tests
```bash
# Test transaction entry uses canonical categories
xcodebuild test -scheme "ClariFi iOS" \
  -only-testing:ClariFi_iOSTests/CategoryConsistencyTests/testTransactionEntry_UsesCanonicalCategories

# Test transactions save canonical names
xcodebuild test -scheme "ClariFi iOS" \
  -only-testing:ClariFi_iOSTests/CategoryConsistencyTests/testTransactionEntry_SavesCanonicalCategoryName
```

#### Category Matching Tests
```bash
# Test budget and transaction categories align
xcodebuild test -scheme "ClariFi iOS" \
  -only-testing:ClariFi_iOSTests/CategoryConsistencyTests/testCategoryMatching_BudgetAndTransactionCategoriesAlign

# Test budget tracking uses canonical names
xcodebuild test -scheme "ClariFi iOS" \
  -only-testing:ClariFi_iOSTests/CategoryConsistencyTests/testCategoryMatching_BudgetTrackingUsesCanonicalNames
```

#### No Mismatches Tests
```bash
# Test all categories are canonical
xcodebuild test -scheme "ClariFi iOS" \
  -only-testing:ClariFi_iOSTests/CategoryConsistencyTests/testNoCategoryMismatches_AllCategoriesAreCanonical

# Test transaction categories match budget
xcodebuild test -scheme "ClariFi iOS" \
  -only-testing:ClariFi_iOSTests/CategoryConsistencyTests/testNoCategoryMismatches_TransactionCategoriesMatchBudget

# Test display names are consistent
xcodebuild test -scheme "ClariFi iOS" \
  -only-testing:ClariFi_iOSTests/CategoryConsistencyTests/testNoCategoryMismatches_DisplayNamesAreConsistent
```

#### End-to-End Tests
```bash
# Test complete workflow
xcodebuild test -scheme "ClariFi iOS" \
  -only-testing:ClariFi_iOSTests/CategoryConsistencyTests/testEndToEnd_BudgetCreationToTransactionTracking

# Test multiple templates
xcodebuild test -scheme "ClariFi iOS" \
  -only-testing:ClariFi_iOSTests/CategoryConsistencyTests/testEndToEnd_MultipleTemplatesNoConflicts
```

## Test Coverage Summary

| Test Category | Test Count | Requirements |
|--------------|------------|--------------|
| Budget Creation from Template | 3 | 2.1, 2.2 |
| Transaction Entry | 2 | 2.1, 2.2, 2.3 |
| Category Matching | 2 | 2.1, 2.2, 2.4 |
| No Mismatches | 3 | 2.1, 2.2, 2.4 |
| End-to-End | 2 | 2.1, 2.2, 2.4 |
| **Total** | **15** | **2.1, 2.2, 2.3, 2.4** |

## What Each Test Validates

### Budget Creation Tests
1. **UsesCanonicalCategories**: Budget templates map to canonical categories
2. **AllTemplatesHaveValidCategories**: All 18 templates use valid categories
3. **CreatesConsistentBudget**: Budget creation uses canonical names

### Transaction Entry Tests
1. **UsesCanonicalCategories**: Transaction entry loads canonical categories
2. **SavesCanonicalCategoryName**: Transactions persist with canonical names

### Category Matching Tests
1. **BudgetAndTransactionCategoriesAlign**: Categories match between budgets and transactions
2. **BudgetTrackingUsesCanonicalNames**: Budget tracking correctly uses canonical names

### No Mismatches Tests
1. **AllCategoriesAreCanonical**: All budget categories are canonical
2. **TransactionCategoriesMatchBudget**: Transactions only use budget categories
3. **DisplayNamesAreConsistent**: Display names are consistent across app

### End-to-End Tests
1. **BudgetCreationToTransactionTracking**: Complete workflow maintains consistency
2. **MultipleTemplatesNoConflicts**: Multiple templates don't create conflicts

## Expected Test Results

All tests should **PASS** ✅ if:
- CategoryDefinition model is properly implemented
- CategoryMappingService correctly maps template names
- BudgetTemplateService uses canonical names
- TransactionEntryViewModel uses CategoryMappingService
- BudgetViewModel uses CategoryMappingService
- All data models store canonical category names

## Troubleshooting

### Test Failures

#### "Category not found in mapping"
- Check CategoryDefinition.allCategories includes the category
- Verify budgetTemplateAliases includes the template name
- Update CategoryMappingService.getCanonicalCategory logic

#### "Transaction category doesn't exist in budget"
- Verify budget was created with correct categories
- Check transaction is using canonical category name
- Ensure CategoryMappingService is injected correctly

#### "Display name inconsistent"
- Check CategoryDefinition.displayName matches expected value
- Verify CategoryMappingService.getDisplayName returns correct value
- Update category definition if needed

### Common Issues

1. **Missing CategoryMappingService in DI Container**
   - Solution: Ensure DIContainer+Testing.swift registers CategoryMappingServiceProtocol

2. **ViewModel Initialization Errors**
   - Solution: Check ViewModel constructors match DI container registrations

3. **Core Data Context Issues**
   - Solution: Verify in-memory context is properly initialized in setUp()

## Integration with CI/CD

### Add to Test Pipeline
```yaml
# Example GitHub Actions
- name: Run Category Consistency Tests
  run: |
    xcodebuild test \
      -scheme "ClariFi iOS" \
      -only-testing:ClariFi_iOSTests/CategoryConsistencyTests \
      -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test Reporting
- Tests generate standard XCTest output
- Can be integrated with test reporting tools
- Failures will block CI/CD pipeline

## Maintenance

### When to Update Tests

1. **Adding New Budget Templates**
   - Tests will automatically validate new templates
   - No test changes needed if using canonical categories

2. **Adding New Categories**
   - Add to CategoryDefinition.allCategories
   - Tests will validate new category is properly mapped

3. **Changing Category Names**
   - Update CategoryDefinition
   - Update budgetTemplateAliases if needed
   - Tests will catch any inconsistencies

4. **Modifying ViewModels**
   - Update DI container registrations if constructor changes
   - Tests will fail if dependencies are incorrect

## Related Documentation

- [Task 2.8 Completion Summary](.kiro/specs/critical-ux-fixes/TASK_2.8_COMPLETION_SUMMARY.md)
- [Phase 2 Completion Summary](.kiro/specs/critical-ux-fixes/PHASE_2_COMPLETION_SUMMARY.md)
- [Category Migration README](../../../Utilities/CategoryMigrationREADME.md)
- [Design Document](.kiro/specs/critical-ux-fixes/design.md)
- [Requirements Document](.kiro/specs/critical-ux-fixes/requirements.md)
