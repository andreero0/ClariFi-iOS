# Issue #002: First Action Not Executing After Onboarding

## Labels
`critical`, `bug`, `onboarding`, `ux`, `state-management`

## Priority
🔴 **CRITICAL**

## Description

Users select a "first action" during onboarding (Upload Statement, Manual Entry, or Create Budget), but due to a race condition in state management, the action does not reliably execute when entering the main app.

## Impact

- **Severity**: CRITICAL
- **User Impact**: HIGH - Broken user flow
- **Frequency**: Variable (timing-dependent)
- **UX**: Poor - Undermines value of onboarding

### User Journey

1. User completes onboarding flow
2. User selects "Upload Statement" as first action
3. User sees "Let's Go!" button and taps it
4. Onboarding dismisses, main app appears
5. **Nothing happens - statement upload screen doesn't appear**
6. User has to manually tap "Upload Statement" button
7. User is confused and frustrated

## Root Cause

**Location**: `ContentView.swift`, `MainTabView.swift`, `HomeView.swift`

### The Race Condition

```swift
// ContentView.swift:85-101
.onChange(of: coordinator.isComplete) { isComplete in
    if isComplete {
        Task {
            await viewModel.completeOnboarding(...)
            // Sends notification with firstAction
            isPresented = false  // ⚠️ DISMISSES IMMEDIATELY
        }
    }
}
```

**Timeline of Events**:
1. `coordinator.isComplete = true`
2. `completeOnboarding()` posts `NotificationCenter` notification
3. `isPresented = false` dismisses onboarding
4. ContentView transitions to MainTabView
5. AppState's observer receives notification (maybe)
6. HomeView's `onAppear` executes (maybe before notification)
7. **Race condition**: Order is non-deterministic

```swift
// MainTabView.swift:91-108
private func handleOnboardingCompletion(_ notification: Notification) {
    guard let actionRaw = notification.userInfo?["firstAction"] as? String,
          let action = FirstActionType(rawValue: actionRaw) else {
        return
    }

    // Sets flags, but HomeView might already be loaded
    switch action {
    case .uploadStatement:
        showingStatementUpload = true
    // ...
    }
}
```

```swift
// HomeView.swift:83-96
.onAppear {
    // This might execute BEFORE notification is received
    if appState.showingStatementUpload {
        showingStatementUpload = true
        appState.showingStatementUpload = false
    }
}
```

## Solution

Replace notification-based state management with deterministic `@EnvironmentObject` approach.

### 1. Create OnboardingStateManager

```swift
// New file: ViewModels/OnboardingStateManager.swift
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

### 2. Register in DI Container

```swift
// AppDIContainer+Registration.swift
container.registerSingleton(OnboardingStateManager.self) { _ in
    OnboardingStateManager()
}
```

### 3. Update OnboardingViewModel

```swift
func completeOnboarding(
    context: NSManagedObjectContext,
    coordinator: OnboardingCoordinator,
    onboardingState: OnboardingStateManager  // ✅ NEW PARAMETER
) async {
    // ... existing code ...

    // Set pending first action BEFORE dismissing
    await MainActor.run {
        onboardingState.setPendingFirstAction(coordinator.selectedFirstAction)
    }

    // ... rest of completion ...
}
```

### 4. Update ContentView

```swift
@EnvironmentObject private var onboardingState: OnboardingStateManager

.onChange(of: coordinator.isComplete) { isComplete in
    if isComplete {
        Task {
            await viewModel.completeOnboarding(
                context: viewContext,
                coordinator: coordinator,
                onboardingState: onboardingState  // ✅ PASS STATE
            )

            // Small delay to ensure propagation
            try? await Task.sleep(nanoseconds: 100_000_000)

            await MainActor.run {
                isPresented = false
            }
        }
    }
}
```

### 5. Update HomeView

```swift
@EnvironmentObject private var onboardingState: OnboardingStateManager

.onAppear {
    calculateSpendingSummary()
    calculateAccountBalance()

    // Execute pending first action deterministically
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

        // Clear after execution
        onboardingState.clearFirstAction()
    }
}
```

## Testing Requirements

- [ ] Test uploadStatement action executes immediately after onboarding
- [ ] Test manualEntry action executes correctly
- [ ] Test createBudget action executes and switches tabs
- [ ] Test with no first action selected (should not crash)
- [ ] Test first action only executes once (not on subsequent app launches)
- [ ] Test on slow devices/simulators (timing issues)
- [ ] Test with app restart after onboarding
- [ ] Test execution is cleared after first run

## Acceptance Criteria

- [ ] First action executes 100% of the time after onboarding
- [ ] Correct sheet/view appears based on selected action
- [ ] Action only executes once (not on every app launch)
- [ ] No race conditions or timing issues
- [ ] Works on all devices and iOS versions
- [ ] All existing tests pass
- [ ] New integration tests cover first action flow

## Related Issues

None

## Files to Modify

1. Create `ViewModels/OnboardingStateManager.swift`
2. `Core/DependencyInjection/AppDIContainer+Registration.swift`
3. `ViewModels/OnboardingViewModel.swift`
4. `ContentView.swift`
5. `Views/HomeView.swift`
6. `ClariFi_iOSApp.swift` - Add @StateObject
7. `ClariFi iOSTests/IntegrationTests/` - Add new test file

## Estimated Time

**2-3 hours**

## Assignee

Unassigned

## References

- Fix Proposal: `docs/fixes/CRITICAL_FIX_PROPOSALS.md#critical-issue-2`
- Code Review: Comprehensive Code Review Report
