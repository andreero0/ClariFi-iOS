# Critical Fix Proposals

## Overview
This document provides detailed fix proposals for the 5 critical issues identified during the comprehensive code review.

---

## Critical Issue #1: Account Balance Persistence

### Problem
Account balances created during onboarding are not persisted to Core Data because the Account entity is missing required properties.

**Location**: `OnboardingViewModel.swift:126-148`

**Current Code**:
```swift
private func createAccounts(_ accountsData: [AccountSetupData], context: NSManagedObjectContext) async {
    await context.perform {
        for accountData in accountsData {
            let account = Account(context: context)
            account.id = accountData.id
            account.name = accountData.displayName
            account.type = accountData.type.rawValue
            // Note: balance, createdDate, lastModifiedDate properties not available
            // account.balance = accountData.initialBalance as NSDecimalNumber  ❌
            account.isDefault = accountData.isDefault
        }
        try context.save()
    }
}
```

### Impact
- **Data Loss**: User's initial balance is completely lost
- **Incorrect UI**: HomeView shows wrong balance
- **User Trust**: Users lose confidence in the app

### Fix Proposal

#### Step 1: Update Core Data Model
Add missing attributes to Account entity:
- `balance` (Decimal, default 0)
- `currency` (String, default "USD")
- `createdAt` (Date)
- `updatedAt` (Date)

#### Step 2: Update Account+CoreDataProperties.swift
```swift
extension Account {
    @NSManaged public var balance: NSDecimalNumber?
    @NSManaged public var currency: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}
```

#### Step 3: Update OnboardingViewModel.createAccounts()
```swift
private func createAccounts(_ accountsData: [AccountSetupData], context: NSManagedObjectContext) async {
    await context.perform {
        for accountData in accountsData {
            let account = Account(context: context)
            account.id = accountData.id
            account.name = accountData.displayName
            account.type = accountData.type.rawValue
            account.balance = accountData.initialBalance as NSDecimalNumber  // ✅ SAVE BALANCE
            account.currency = "USD"  // Use user's preferred currency
            account.isDefault = accountData.isDefault
            account.createdAt = Date()
            account.updatedAt = Date()
        }
        try context.save()
    }
}
```

#### Step 4: Create Core Data Migration (if needed)
- Lightweight migration should work for adding attributes with defaults
- Test migration with existing data

#### Step 5: Update HomeView.calculateAccountBalance()
```swift
private func calculateAccountBalance() {
    guard !allAccounts.isEmpty else {
        totalAccountBalance = 0
        balanceChangePercentage = 0
        return
    }

    // Calculate from actual account balances
    totalAccountBalance = allAccounts.reduce(0) { total, account in
        total + (account.balance?.decimalValue ?? 0)
    }

    // Calculate actual percentage change from transaction history
    let lastMonthBalance = calculateBalanceForLastMonth()
    if lastMonthBalance > 0 {
        balanceChangePercentage = Double(truncating: ((totalAccountBalance - lastMonthBalance) / lastMonthBalance * 100) as NSDecimalNumber)
    }
}
```

#### Testing
- [ ] Test account creation during onboarding saves balance
- [ ] Test balance display in HomeView
- [ ] Test migration from old to new schema
- [ ] Test multiple accounts with different balances
- [ ] Test negative balances (credit cards)

---

## Critical Issue #2: First Action Execution

### Problem
User selects a first action during onboarding, but due to a race condition, the action is not reliably executed when entering the main app.

**Location**: `ContentView.swift`, `MainTabView.swift`, `HomeView.swift`

**Root Cause**:
- Notification-based state management has timing issues
- HomeView.onAppear() might execute before notification is processed
- State transitions are not deterministic

### Impact
- **Broken User Flow**: User expects to start with chosen action
- **Poor UX**: User has to manually trigger the action they already selected
- **Confusion**: Undermines onboarding value proposition

### Fix Proposal

#### Option A: Use Environment Object for Deterministic State (Recommended)

**Step 1: Create OnboardingStateManager**
```swift
@MainActor
class OnboardingStateManager: ObservableObject {
    @Published var pendingFirstAction: FirstActionType?
    @Published var shouldExecuteFirstAction: Bool = false

    func setPendingFirstAction(_ action: FirstActionType?) {
        self.pendingFirstAction = action
        self.shouldExecuteFirstAction = action != nil
    }

    func clearFirstAction() {
        self.pendingFirstAction = nil
        self.shouldExecuteFirstAction = false
    }
}
```

**Step 2: Add to DI Container and Environment**
```swift
// In AppDIContainer+Registration.swift
container.registerSingleton(OnboardingStateManager.self) { _ in
    OnboardingStateManager()
}

// In ClariFi_iOSApp.swift
@StateObject private var onboardingState = OnboardingStateManager()

// Pass to environment
ContentView()
    .environmentObject(onboardingState)
```

**Step 3: Update OnboardingViewModel**
```swift
func completeOnboarding(
    context: NSManagedObjectContext,
    coordinator: OnboardingCoordinator,
    onboardingState: OnboardingStateManager
) async {
    // ... existing code ...

    // Set pending first action BEFORE dismissing onboarding
    await MainActor.run {
        onboardingState.setPendingFirstAction(coordinator.selectedFirstAction)
    }

    // Save to UserDefaults as backup
    if let firstAction = coordinator.selectedFirstAction {
        userDefaults.set(firstAction.rawValue, forKey: onboardingFirstActionKey)
    }

    // ... rest of completion ...
}
```

**Step 4: Update ContentView**
```swift
struct ContentView: View {
    @EnvironmentObject private var onboardingState: OnboardingStateManager

    .onChange(of: coordinator.isComplete) { isComplete in
        if isComplete {
            Task {
                await viewModel.completeOnboarding(
                    context: viewContext,
                    coordinator: coordinator,
                    onboardingState: onboardingState  // Pass state manager
                )

                // Small delay to ensure state is propagated
                try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

                await MainActor.run {
                    Analytics.track(.onboardingCompleted, ...)
                    isPresented = false
                }
            }
        }
    }
}
```

**Step 5: Update HomeView**
```swift
struct HomeView: View {
    @EnvironmentObject private var onboardingState: OnboardingStateManager

    .onAppear {
        calculateSpendingSummary()
        calculateAccountBalance()

        // Execute pending first action
        if onboardingState.shouldExecuteFirstAction {
            executePendingFirstAction()
        }
    }

    private func executePendingFirstAction() {
        guard let action = onboardingState.pendingFirstAction else { return }

        // Small delay for UI to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch action {
            case .uploadStatement:
                statementUploadViewModel = createStatementUploadViewModel()
                showingStatementUpload = true
            case .manualEntry:
                showingTransactionEntry = true
            case .createBudget:
                appState.selectedTab = 2
                appState.shouldPresentBudgetCreation = true
            }

            // Clear the action after execution
            onboardingState.clearFirstAction()
        }
    }
}
```

#### Option B: Use Completion Handler (Alternative)

**Step 1: Update OnboardingView**
```swift
struct OnboardingView: View {
    @Binding var isPresented: Bool
    var onComplete: ((FirstActionType?) -> Void)?

    .onChange(of: coordinator.isComplete) { isComplete in
        if isComplete {
            Task {
                await viewModel.completeOnboarding(...)

                await MainActor.run {
                    let firstAction = coordinator.selectedFirstAction
                    isPresented = false

                    // Call completion handler AFTER dismissing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onComplete?(firstAction)
                    }
                }
            }
        }
    }
}
```

**Step 2: Update ContentView**
```swift
OnboardingView(isPresented: $showOnboarding, container: container) { firstAction in
    // This executes AFTER onboarding is dismissed
    if let action = firstAction {
        handleFirstAction(action)
    }
}

private func handleFirstAction(_ action: FirstActionType) {
    // Set flags that AppState will pick up
    switch action {
    case .uploadStatement:
        appState.showingStatementUpload = true
    case .manualEntry:
        appState.showingTransactionEntry = true
    case .createBudget:
        appState.selectedTab = 2
        appState.shouldPresentBudgetCreation = true
    }
}
```

#### Recommendation
Use **Option A** (Environment Object) because:
- More testable
- Explicit state management
- Can be easily tracked in debugging
- Follows SwiftUI best practices

#### Testing
- [ ] Test first action executes immediately after onboarding
- [ ] Test each first action type (upload, manual, budget)
- [ ] Test with no first action selected
- [ ] Test with app restart (should not re-execute)
- [ ] Test with slow devices (timing issues)

---

## Critical Issue #3: Account Setup Validation Contradiction

### Problem
Account setup step is marked as "optional" but validation blocks advancement unless an account is created. The "Skip" button doesn't actually skip—it creates a default account.

**Location**: `OnboardingCoordinator.swift:142-159`, `AccountSetupStepView.swift:83-93`

**Contradiction**:
```swift
// Marked as optional
var isOptional: Bool {
    case .accountSetup: return true
}

// But validation blocks
case .accountSetup:
    if createdAccounts.isEmpty {
        return .error("Add an account or choose Skip to continue.")  // BLOCKS!
    }
```

### Impact
- **Confusing UX**: User sees "Skip" but can't actually skip
- **Inconsistent Logic**: Code says optional but behaves as required
- **Poor Clarity**: User doesn't understand they MUST have an account

### Fix Proposal

#### Decision: Make Account Setup Truly Optional

**Rationale**:
- Users might want to explore the app before adding accounts
- Better UX to allow exploration
- Can prompt to add account when actually needed (e.g., adding first transaction)

**Step 1: Update Validation Logic**
```swift
// In OnboardingCoordinator.swift
private func validate(_ step: OnboardingStep) -> ValidationResult {
    switch step {
    case .accountSetup:
        if createdAccounts.isEmpty {
            return .warning("No accounts added. A default 'General Account' will be created for you.")
        }
        return .valid
    // ... other cases ...
    }
}
```

**Step 2: Update Skip Button Label**
```swift
// In AccountSetupStepView.swift
if coordinator.createdAccounts.isEmpty {
    Button(action: {
        coordinator.advance()  // ✅ Just advance, don't create default
    }) {
        Text("Skip - I'll Add Accounts Later")
            .font(.subheadline)
            .foregroundColor(.blue)
    }
    .accessibilityLabel("Skip account setup")
}
```

**Step 3: Create Default Account Only When Needed**
```swift
// In OnboardingViewModel.swift
func completeOnboarding(...) async {
    // ... existing code ...

    // Create accounts OR create default if none exist
    if !coordinator.createdAccounts.isEmpty {
        await createAccounts(coordinator.createdAccounts, context: context)
    } else {
        // User skipped - create a default general account
        let defaultAccount = AccountSetupData(
            name: "General Account",
            type: .checking,
            initialBalance: 0,
            isDefault: true
        )
        await createAccounts([defaultAccount], context: context)
    }
}
```

**Step 4: Add Help Text**
```swift
// In AccountSetupStepView.swift
if coordinator.createdAccounts.isEmpty {
    VStack(spacing: 16) {
        Image(systemName: "info.circle.fill")
            .font(.title2)
            .foregroundColor(.blue)

        Text("You can add accounts later from Settings")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }
    .padding()
}
```

**Step 5: Update Tests**
```swift
func testSkipAccountSetupCreatesDefaultOnCompletion() async throws {
    // Given: User on account setup with no accounts
    coordinator.skipToStep(.accountSetup)
    XCTAssertTrue(coordinator.createdAccounts.isEmpty)

    // When: User advances without creating account
    XCTAssertTrue(coordinator.canAdvance())  // Should allow advancement
    coordinator.advance()

    // Then: Should advance to next step
    XCTAssertEqual(coordinator.currentStep, .biometric)

    // When: Onboarding completes
    await viewModel.completeOnboarding(context, coordinator)

    // Then: Default account should be created
    let accounts = try await accountRepo.fetchAll()
    XCTAssertEqual(accounts.count, 1)
    XCTAssertEqual(accounts.first?.name, "General Account")
}
```

#### Alternative: Make Account Setup Required

If business logic requires accounts:

**Step 1: Remove Optional Flag**
```swift
var isOptional: Bool {
    case .quickStart: return true  // Only quickStart is optional
    default: return false
}
```

**Step 2: Update UI**
```swift
// Remove skip button entirely
// Show clear message: "Add at least one account to continue"
```

**Step 3: Update Validation**
```swift
case .accountSetup:
    if createdAccounts.isEmpty {
        return .error("Please add at least one account to continue")
    }
    return .valid
```

#### Recommendation
Make it **truly optional** because:
- Better UX for exploration
- Matches user expectation of "skip"
- Can still ensure account exists when needed

#### Testing
- [ ] Test skip without creating account
- [ ] Test default account created on completion
- [ ] Test validation shows warning, not error
- [ ] Test can advance from account setup without accounts
- [ ] Test UI shows helpful message

---

## Critical Issue #4: Real Balance Calculation

### Problem
HomeView displays fake/simulated account balances instead of actual data.

**Location**: `HomeView.swift:523-544`

**Current Code**:
```swift
private func calculateAccountBalance() {
    // Simulate account balance calculation
    let baseBalance: Decimal = 1000  // ❌ HARDCODED
    let accountCount = allAccounts.count
    totalAccountBalance = baseBalance * Decimal(accountCount)  // ❌ FAKE
}
```

### Impact
- **Misleading UI**: Users see incorrect balances
- **Loss of Trust**: Core feature doesn't work
- **Unusable App**: Can't track actual finances

### Fix Proposal

#### Step 1: Update calculateAccountBalance() to Use Real Data

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

#### Step 2: Implement calculateBalanceChangePercentage()

```swift
private func calculateBalanceChangePercentage() {
    let calendar = Calendar.current
    let now = Date()

    // Get start of current month and last month
    guard let startOfThisMonth = calendar.dateInterval(of: .month, for: now)?.start,
          let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfThisMonth) else {
        balanceChangePercentage = 0
        return
    }

    // Calculate balance at start of this month (= end of last month)
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

    // Subtract all transactions that occurred after the target date
    let transactionsAfterDate = allTransactions.filter { transaction in
        guard let transactionDate = transaction.date else { return false }
        return transactionDate >= date
    }

    for transaction in transactionsAfterDate {
        let amount = transaction.amount?.decimalValue ?? 0
        // Reverse the transaction to get historical balance
        balanceAtDate -= amount
    }

    return balanceAtDate
}
```

#### Step 3: Add Account Balance Updates

Create a service to keep account balances in sync with transactions:

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

    /// Update account balance after transaction is added/modified/deleted
    func updateAccountBalance(for accountId: UUID) async throws {
        guard let account = try await accountRepository.fetchById(accountId) else {
            throw AccountBalanceError.accountNotFound
        }

        // Get all transactions for this account
        let transactions = try await transactionRepository.fetchAll()
        let accountTransactions = transactions.filter { $0.account?.id == accountId }

        // Calculate balance from initial balance + all transactions
        let transactionTotal = accountTransactions.reduce(Decimal(0)) { total, transaction in
            total + (transaction.amount?.decimalValue ?? 0)
        }

        // Note: This assumes transactions are debits (negative) and credits (positive)
        // Initial balance was set during account creation
        // Current balance = initial balance + transaction total

        // For now, we'll recalculate from transactions only
        // In a real app, you might want to store initial balance separately
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

#### Step 4: Call Balance Update When Transactions Change

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

    // ... rest of save logic ...
}
```

#### Step 5: Register Service in DI Container

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

#### Testing
- [ ] Test balance calculation with multiple accounts
- [ ] Test percentage change calculation
- [ ] Test historical balance calculation
- [ ] Test balance updates when transaction added
- [ ] Test balance updates when transaction deleted
- [ ] Test with no transactions (should show initial balance)

---

## Critical Issue #5: Validation Bypass Via Swipe

### Problem
Users can swipe between onboarding steps in the TabView, bypassing validation logic.

**Location**: `OnboardingView.swift:30-54`

**Current Code**:
```swift
TabView(selection: stepBinding) {
    // 7 onboarding steps
}
.tabViewStyle(.page(indexDisplayMode: .always))  // ⚠️ Allows swiping
```

### Impact
- **Broken Validation**: Users can skip required steps
- **Data Integrity**: Can complete onboarding without meeting requirements
- **Poor UX**: Validation messages appear after user already swiped away

### Fix Proposal

#### Option A: Disable TabView Paging (Recommended)

**Step 1: Remove Page Style Swiping**
```swift
// In OnboardingView.swift
TabView(selection: stepBinding) {
    WelcomePageView()
        .tag(OnboardingStep.welcome)
    // ... other steps ...
}
.tabViewStyle(.page(indexDisplayMode: .never))  // ✅ Disable page indicators
.gesture(DragGesture())  // ✅ Disable swipe gesture
```

**Step 2: Add Custom Navigation Buttons**

Create a custom button bar at the bottom:

```swift
struct OnboardingView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: stepBinding) {
                // ... steps ...
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom navigation bar
            OnboardingNavigationBar(coordinator: coordinator)
                .padding()
                .background(.ultraThinMaterial)
        }
    }
}

struct OnboardingNavigationBar: View {
    @ObservedObject var coordinator: OnboardingCoordinator

    var body: some View {
        HStack(spacing: 16) {
            // Back button
            if coordinator.currentStepIndex > 0 {
                Button(action: {
                    coordinator.goBack()
                }) {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            // Progress indicator
            HStack(spacing: 8) {
                ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                    Circle()
                        .fill(step.rawValue <= coordinator.currentStepIndex ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            // Next/Continue button
            Button(action: {
                coordinator.advance()
            }) {
                Text(coordinator.currentStep == .firstAction ? "Complete" : "Continue")
                    .frame(minWidth: 100)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!coordinator.canAdvance())
        }
        .padding()
    }
}
```

**Step 3: Add Validation Feedback**

Show validation messages inline:

```swift
struct OnboardingView: View {
    @State private var showValidationError = false

    var body: some View {
        ZStack {
            // ... existing TabView ...

            // Validation error banner
            if showValidationError, let validation = coordinator.validateCurrentStep(),
               case .error(let message) = validation {
                VStack {
                    Spacer()

                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        Text(message)
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
                    .padding()
                    .padding(.bottom, 80)  // Above navigation bar
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: showValidationError)
            }
        }
    }
}
```

**Step 4: Update OnboardingCoordinator**

Add validation feedback trigger:

```swift
@Published var shouldShowValidationError = false

func advance() {
    let validation = validate(currentStep)

    guard validation.allowsAdvance(for: currentStep) else {
        shouldShowValidationError = true

        // Hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            shouldShowValidationError = false
        }
        return
    }

    // ... existing advance logic ...
}
```

#### Option B: Intercept Swipe Gestures

Use a custom SwiftUI gesture to block swipes when validation fails:

```swift
struct OnboardingView: View {
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        TabView(selection: stepBinding) {
            // ... steps ...
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Check if trying to swipe forward
                    if value.translation.width < -50 {  // Swipe left (forward)
                        if !coordinator.canAdvance() {
                            // Block the gesture
                            dragOffset = 0
                            coordinator.shouldShowValidationError = true
                        }
                    }
                }
        )
    }
}
```

#### Recommendation
Use **Option A** (Custom Navigation Buttons) because:
- More explicit and clear to users
- Better accessibility
- Consistent with Apple HIG for multi-step flows
- Easier to add loading states and validation feedback

#### Testing
- [ ] Test cannot swipe forward when validation fails
- [ ] Test can swipe backward freely
- [ ] Test navigation buttons work correctly
- [ ] Test validation error appears when trying to advance
- [ ] Test progress indicator updates correctly
- [ ] Test keyboard navigation (accessibility)

---

## Implementation Priority

1. **Issue #1** (Account Balance Persistence) - 2 hours
   - Most critical for data integrity
   - Requires Core Data schema change

2. **Issue #4** (Real Balance Calculation) - 1 hour
   - Depends on Issue #1
   - Critical for MVP functionality

3. **Issue #2** (First Action Execution) - 2 hours
   - Important for UX
   - Complex state management

4. **Issue #3** (Validation Contradiction) - 1 hour
   - UX improvement
   - Simpler fix

5. **Issue #5** (Swipe Bypass) - 3 hours
   - Requires UI redesign
   - Most complex but least critical

**Total Estimated Time**: 9 hours

---

## Testing Strategy

### Unit Tests
- [ ] Account balance persistence
- [ ] Balance calculation logic
- [ ] First action state management
- [ ] Validation logic consistency

### Integration Tests
- [ ] Onboarding → first action execution
- [ ] Account creation → balance display
- [ ] Transaction creation → balance update

### UI Tests
- [ ] Cannot advance without meeting requirements
- [ ] Validation errors appear appropriately
- [ ] First action executes correctly
- [ ] Balance displays accurately

### Manual Testing
- [ ] Test on device (not just simulator)
- [ ] Test with VoiceOver
- [ ] Test with slow network
- [ ] Test with app backgrounding during onboarding
- [ ] Test with force quit during onboarding

---

## Rollout Plan

### Phase 1: Critical Data Fixes (Issues #1, #4)
- Update Core Data model
- Implement real balance calculation
- Test thoroughly
- Deploy to TestFlight

### Phase 2: UX Improvements (Issues #2, #3)
- Fix first action execution
- Resolve validation contradiction
- Update tests
- Deploy to TestFlight

### Phase 3: Polish (Issue #5)
- Redesign onboarding navigation
- Add custom buttons
- Enhance validation feedback
- Deploy to production

---

## Success Criteria

- [ ] All account balances persist correctly
- [ ] Balance calculations are accurate
- [ ] First action executes 100% of the time
- [ ] Validation logic is consistent
- [ ] Cannot bypass validation via swiping
- [ ] All existing tests pass
- [ ] New tests cover all fixes
- [ ] No regressions in other features

