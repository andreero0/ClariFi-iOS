# Critical Currency Fix Plan

## Problem Identified

**Root Cause**: Hardcoded `currencyCode = "USD"` in 11+ view files causes:
1. "US $" prefix display (unprofessional)
2. Ignores user's currency preference
3. Inconsistent formatting across app

## Files with Hardcoded USD

1. `Views/HomeView.swift` (3 locations)
2. `Views/BudgetView.swift` (2 locations)
3. `Views/TransactionRowView.swift` (1 location)
4. `Views/TransactionDetailView.swift` (1 location)
5. `Views/TransactionsListView.swift` (1 location)
6. `Views/BudgetCreationView.swift` (1 location)
7. `Views/RecurringTransactionsListView.swift` (2 locations)
8. `Views/ScenarioPlanningView.swift` (1 location)
9. `Views/CashflowForecastView.swift` (1 location)
10. `Views/TransactionReviewView.swift` (1 location)

**Total**: 14+ hardcoded formatters to fix

## Solution

Replace all hardcoded formatters with:

```swift
// OLD (wrong)
let formatter = NumberFormatter()
formatter.numberStyle = .currency
formatter.currencyCode = "USD"
return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"

// NEW (correct)
return amount.formattedAsCurrency
// or
return CurrencyPreferenceManager.shared.format(amount)
```

## Implementation Strategy

### Phase 1: Create Helper Extension (Already Done)
- ✅ `Core/Extensions/Decimal+Currency.swift` exists
- ✅ Provides `.formattedAsCurrency` property

### Phase 2: Replace All Hardcoded Formatters
For each file:
1. Find all `currencyCode = "USD"` instances
2. Replace with `.formattedAsCurrency` or `CurrencyPreferenceManager.shared.format()`
3. Remove local formatter code
4. Test display

### Phase 3: Verify
- Check all views display correctly
- Verify currency preference is respected
- Test with different currencies

## Priority Order

1. **HomeView.swift** (3 fixes) - Most visible
2. **TransactionRowView.swift** (1 fix) - Shown frequently
3. **BudgetView.swift** (2 fixes) - Core feature
4. **TransactionDetailView.swift** (1 fix) - User interaction
5. **TransactionsListView.swift** (1 fix) - Core feature
6. **BudgetCreationView.swift** (1 fix) - Core feature
7. **RecurringTransactionsListView.swift** (2 fixes)
8. **TransactionReviewView.swift** (1 fix)
9. **ScenarioPlanningView.swift** (1 fix)
10. **CashflowForecastView.swift** (1 fix)

## Testing Checklist

After each fix:
- [ ] View compiles
- [ ] Amount displays correctly
- [ ] No "US $" prefix
- [ ] Respects currency preference
- [ ] Handles nil/zero amounts

## Estimated Time

- Per file: 5-10 minutes
- Total: 1-2 hours for all files
- Testing: 30 minutes

## Risk Mitigation

1. **Backup**: Changes are in version control
2. **Incremental**: Fix one file at a time
3. **Test**: Verify each fix before moving on
4. **Rollback**: Can revert if issues arise

## Success Criteria

- [ ] No hardcoded "USD" in any view
- [ ] All amounts use currency preference
- [ ] Clean display (no "US $")
- [ ] Currency selection works
- [ ] All views compile and run

---

**Status**: Ready to implement  
**Priority**: CRITICAL  
**Impact**: HIGH - Affects entire app
