# Issue #001: Account Balances Not Persisted During Onboarding

## Labels
`critical`, `bug`, `data-loss`, `onboarding`, `core-data`

## Priority
🔴 **CRITICAL**

## Description

Account balances entered by users during onboarding are not saved to Core Data due to missing properties in the Account entity schema. This results in complete data loss of the user's initial account balances.

## Impact

- **Severity**: CRITICAL
- **User Impact**: HIGH - Complete data loss
- **Frequency**: 100% of onboarding flows
- **Data Integrity**: Compromised

### User Journey

1. User goes through onboarding
2. User creates "Main Checking" account with $1,500 initial balance
3. User completes onboarding
4. User sees account in HomeView with $0 or undefined balance
5. **User's financial data is incorrect from the start**

## Root Cause

**Location**: `OnboardingViewModel.swift:126-148`

The `Account` Core Data entity is missing the following required attributes:
- `balance` (Decimal)
- `currency` (String)
- `createdAt` (Date)
- `updatedAt` (Date)

Current code has commented-out lines attempting to set these properties:

```swift
private func createAccounts(_ accountsData: [AccountSetupData], context: NSManagedObjectContext) async {
    await context.perform {
        for accountData in accountsData {
            let account = Account(context: context)
            account.id = accountData.id
            account.name = accountData.displayName
            account.type = accountData.type.rawValue
            // Note: balance, createdDate, lastModifiedDate properties not available in Account entity
            // account.balance = accountData.initialBalance as NSDecimalNumber  ❌ COMMENTED OUT
            account.isDefault = accountData.isDefault
            // account.createdDate = Date()  ❌ COMMENTED OUT
            // account.lastModifiedDate = Date()  ❌ COMMENTED OUT
        }

        do {
            try context.save()
        } catch {
            print("Error saving accounts: \(error)")
        }
    }
}
```

## Solution

### 1. Update Core Data Model

Add the following attributes to the `Account` entity in `ClariFi_iOS.xcdatamodeld`:

| Attribute | Type | Optional | Default |
|-----------|------|----------|---------|
| `balance` | Decimal | No | 0 |
| `currency` | String | No | "USD" |
| `createdAt` | Date | No | - |
| `updatedAt` | Date | No | - |

### 2. Regenerate NSManagedObject Subclass

Update `Account+CoreDataProperties.swift`:

```swift
extension Account {
    @NSManaged public var balance: NSDecimalNumber?
    @NSManaged public var currency: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}
```

### 3. Update OnboardingViewModel

Uncomment and implement the persistence code:

```swift
private func createAccounts(_ accountsData: [AccountSetupData], context: NSManagedObjectContext) async {
    await context.perform {
        for accountData in accountsData {
            let account = Account(context: context)
            account.id = accountData.id
            account.name = accountData.displayName
            account.type = accountData.type.rawValue
            account.balance = accountData.initialBalance as NSDecimalNumber  // ✅ SAVE BALANCE
            account.currency = "USD"  // TODO: Use user's preferred currency
            account.isDefault = accountData.isDefault
            account.createdAt = Date()
            account.updatedAt = Date()
        }

        do {
            try context.save()
        } catch {
            print("Error saving accounts: \(error)")
            // TODO: Handle error properly (show alert to user)
        }
    }
}
```

### 4. Handle Core Data Migration

Since we're adding new attributes:
- Test lightweight migration with default values
- If migration fails, implement custom migration policy
- Ensure existing users don't lose data

## Testing Requirements

- [ ] Test account creation during onboarding saves all fields
- [ ] Test balance is correctly retrieved and displayed
- [ ] Test multiple accounts with different balances
- [ ] Test negative balances (credit cards)
- [ ] Test currency is saved correctly
- [ ] Test timestamps are set
- [ ] Test Core Data migration from old schema
- [ ] Test existing accounts are preserved during migration

## Acceptance Criteria

- [ ] Account balance is persisted to Core Data during onboarding
- [ ] Account balance is displayed correctly in HomeView
- [ ] Created/updated timestamps are saved
- [ ] Currency is saved (default USD)
- [ ] Core Data migration works without data loss
- [ ] All existing tests pass
- [ ] New tests cover balance persistence

## Related Issues

- #004 - Real Balance Calculation (depends on this fix)

## Files to Modify

1. `ClariFi_iOS.xcdatamodeld/ClariFi_iOS.xcdatamodel` - Add attributes
2. `Account+CoreDataProperties.swift` - Add NSManaged properties
3. `OnboardingViewModel.swift:126-148` - Uncomment and implement persistence
4. `OnboardingFlowTests.swift` - Add tests for balance persistence

## Estimated Time

**2-3 hours**

## Assignee

Unassigned

## References

- Fix Proposal: `docs/fixes/CRITICAL_FIX_PROPOSALS.md#critical-issue-1`
- Code Review: Comprehensive Code Review Report
