# Issue #004: HomeView Displays Fake Account Balances

## Labels
`critical`, `bug`, `ui`, `home-view`, `balance`

## Priority
🔴 **CRITICAL**

## Description

The HomeView displays simulated/fake account balances instead of actual data, making the core feature of the personal finance app non-functional.

## Impact

- **Severity**: CRITICAL
- **User Impact**: HIGH - Core feature broken
- **Frequency**: 100% of users
- **Trust**: App appears broken or dishonest

### User Journey

1. User creates account with $1,500 balance during onboarding
2. User adds transactions totaling $200
3. User opens HomeView
4. **User sees fake balance**: $1,000 (or $2,000 if 2 accounts)
5. User loses trust in app
6. User cannot use app for actual financial tracking

## Root Cause

**Location**: `HomeView.swift:523-544`

### Current Code

```swift
private func calculateAccountBalance() {
    // Calculate total balance from all accounts
    // For now, we'll simulate this since accounts don't have balance fields  ❌
    // In a real app, you'd calculate this from account balances or transaction history

    if allAccounts.isEmpty {
        totalAccountBalance = 0
        balanceChangePercentage = 0
        return
    }

    // Simulate account balance calculation
    let baseBalance: Decimal = 1000 // Starting balance for demo  ❌ HARDCODED
    let accountCount = allAccounts.count
    totalAccountBalance = baseBalance * Decimal(accountCount)  // ❌ FAKE DATA

    // Calculate percentage change from last month
    let lastMonthBalance = totalAccountBalance * 0.976  // ❌ SIMULATED
    balanceChangePercentage = Double(...)
}
```

## Solution

Calculate real balances from account data and transaction history.

### Prerequisites

- **Depends on**: Issue #001 (Account Balance Persistence)
- Account entity must have `balance` attribute

### 1. Update calculateAccountBalance()

```swift
private func calculateAccountBalance() {
    guard !allAccounts.isEmpty else {
        totalAccountBalance = 0
        balanceChangePercentage = 0
        return
    }

    // Calculate total from actual account balances
    totalAccountBalance = allAccounts.reduce(0) { total, account in
        total + (account.balance?.decimalValue ?? 0)
    }

    // Calculate actual percentage change
    calculateBalanceChangePercentage()
}
```

### 2. Implement Real Percentage Change

```swift
private func calculateBalanceChangePercentage() {
    let calendar = Calendar.current
    let now = Date()

    guard let startOfThisMonth = calendar.dateInterval(of: .month, for: now)?.start else {
        balanceChangePercentage = 0
        return
    }

    // Calculate balance at start of month
    let balanceLastMonth = calculateBalanceAtDate(startOfThisMonth)

    guard balanceLastMonth > 0 else {
        balanceChangePercentage = 0
        return
    }

    // Calculate percentage change
    let change = totalAccountBalance - balanceLastMonth
    balanceChangePercentage = Double(truncating: (change / balanceLastMonth * 100) as NSDecimalNumber)
}

private func calculateBalanceAtDate(_ date: Date) -> Decimal {
    // Start with current balances
    var balanceAtDate = totalAccountBalance

    // Subtract transactions that occurred after the target date
    let transactionsAfterDate = allTransactions.filter { transaction in
        guard let transactionDate = transaction.date else { return false }
        return transactionDate >= date
    }

    for transaction in transactionsAfterDate {
        let amount = transaction.amount?.decimalValue ?? 0
        balanceAtDate -= amount
    }

    return balanceAtDate
}
```

### 3. Create AccountBalanceService

For keeping account balances in sync with transactions:

```swift
// New file: Services/AccountBalanceService.swift
@MainActor
class AccountBalanceService {
    private let accountRepository: any AccountRepository
    private let transactionRepository: any TransactionRepository
    private let context: NSManagedObjectContext

    init(
        accountRepository: any AccountRepository,
        transactionRepository: any TransactionRepository,
        context: NSManagedObjectContext
    ) {
        self.accountRepository = accountRepository
        self.transactionRepository = transactionRepository
        self.context = context
    }

    /// Update account balance after transaction changes
    func updateAccountBalance(for accountId: UUID) async throws {
        guard let account = try await accountRepository.fetchById(accountId) else {
            throw AccountBalanceError.accountNotFound
        }

        // Get all transactions for this account
        let transactions = try await transactionRepository.fetchAll()
        let accountTransactions = transactions.filter { $0.account?.id == accountId }

        // Calculate balance from transactions
        let transactionTotal = accountTransactions.reduce(Decimal(0)) { total, transaction in
            total + (transaction.amount?.decimalValue ?? 0)
        }

        await context.perform {
            account.balance = transactionTotal as NSDecimalNumber
            account.updatedAt = Date()
        }

        try await accountRepository.update(account)
    }

    /// Recalculate all account balances
    func recalculateAllBalances() async throws {
        let accounts = try await accountRepository.fetchAll()

        for account in accounts {
            guard let accountId = account.id else { continue }
            try await updateAccountBalance(for: accountId)
        }
    }
}

enum AccountBalanceError: Error {
    case accountNotFound
}
```

### 4. Update Transactions to Trigger Balance Updates

```swift
// In TransactionEntryViewModel.swift
func saveTransaction() async {
    // ... create transaction ...

    try await transactionRepository.save(transaction)

    // Update account balance
    if let accountId = selectedAccount?.id {
        let balanceService = container.resolve(AccountBalanceService.self)
        try? await balanceService.updateAccountBalance(for: accountId)
    }
}
```

### 5. Register Service in DI Container

```swift
// In AppDIContainer+Registration.swift
container.register(AccountBalanceService.self) { container in
    let accountRepo = container.resolve(AccountRepository.self)
    let transactionRepo = container.resolve(TransactionRepository.self)
    let context = container.resolve(NSManagedObjectContext.self)

    return AccountBalanceService(
        accountRepository: accountRepo,
        transactionRepository: transactionRepo,
        context: context
    )
}
```

## Testing Requirements

- [ ] Test balance calculation with single account
- [ ] Test balance calculation with multiple accounts
- [ ] Test percentage change calculation
- [ ] Test historical balance at specific date
- [ ] Test balance updates when transaction added
- [ ] Test balance updates when transaction deleted
- [ ] Test balance updates when transaction modified
- [ ] Test with no transactions (should show initial balance)
- [ ] Test with negative balances (credit cards)
- [ ] Test with zero balance accounts

## Acceptance Criteria

- [ ] HomeView displays actual account balances
- [ ] Balance updates when transactions change
- [ ] Percentage change is calculated from real data
- [ ] No hardcoded or simulated values
- [ ] Performance is acceptable (< 1 second)
- [ ] All existing tests pass
- [ ] New tests cover balance calculations

## Related Issues

- **Depends on**: #001 - Account Balance Persistence

## Files to Modify

1. `Views/HomeView.swift:523-544` - Replace fake calculation
2. Create `Services/AccountBalanceService.swift`
3. `ViewModels/TransactionEntryViewModel.swift` - Trigger balance updates
4. `Core/DependencyInjection/AppDIContainer+Registration.swift` - Register service
5. `ClariFi iOSTests/UnitTests/` - Add AccountBalanceServiceTests.swift

## Estimated Time

**2 hours** (after Issue #001 is completed)

## Assignee

Unassigned

## References

- Fix Proposal: `docs/fixes/CRITICAL_FIX_PROPOSALS.md#critical-issue-4`
- Code Review: Comprehensive Code Review Report
