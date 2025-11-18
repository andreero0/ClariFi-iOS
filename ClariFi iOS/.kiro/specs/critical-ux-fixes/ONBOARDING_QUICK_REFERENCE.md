# Enhanced Onboarding Flow - Quick Reference

## Overview
The enhanced onboarding flow guides users from welcome to their first action with account setup and quick start selection.

## Components

### 1. OnboardingCoordinator
**Location:** `ViewModels/OnboardingCoordinator.swift`

Central coordinator managing the entire onboarding flow.

```swift
// Usage in OnboardingView
@StateObject private var coordinator = OnboardingCoordinator()

// Access state
coordinator.currentStep          // Current step in flow
coordinator.createdAccounts      // Accounts created during setup
coordinator.selectedFirstAction  // User's chosen first action
coordinator.isComplete          // Whether onboarding is done

// Navigation
coordinator.advance()           // Move to next step
coordinator.goBack()           // Go to previous step
coordinator.canAdvance()       // Check if can proceed

// Account management
coordinator.addAccount(account)
coordinator.removeAccount(account)
coordinator.setDefaultAccount(account)
coordinator.createDefaultAccount()

// First action
coordinator.selectFirstAction(.uploadStatement)
```

### 2. AccountSetupData Model
**Location:** `Models/AccountSetupData.swift`

Model for account data during onboarding.

```swift
// Create account
let account = AccountSetupData(
    name: "Main Checking",
    type: .checking,
    initialBalance: 1500.00,
    isDefault: true
)

// Validate
if let error = account.validate() {
    print(error.errorDescription)
}

// Account types
AccountType.checking    // "Checking"
AccountType.savings     // "Savings"
AccountType.credit      // "Credit Card"
AccountType.cash        // "Cash"
AccountType.investment  // "Investment"
```

### 3. Onboarding Steps

#### Step 0: Welcome
- Existing welcome screen
- Shows app features and benefits

#### Step 1: Privacy
- Existing privacy selection
- Local-only vs cloud-enhanced

#### Step 2: Features
- Existing features overview
- Highlights key capabilities

#### Step 3: Account Setup (NEW)
**View:** `Views/Onboarding/AccountSetupStepView.swift`

- Add one or more accounts
- Edit/delete accounts
- Set default account
- Skip creates default Cash account

```swift
AccountSetupStepView(coordinator: coordinator)
```

#### Step 4: Biometric
- Existing biometric setup
- Optional security enhancement

#### Step 5: Quick Start (NEW)
**View:** `Views/Onboarding/QuickStartView.swift`

- Select first action:
  - Upload Statement
  - Add Transaction Manually
  - Create Budget
- Can skip to choose later

```swift
QuickStartView(coordinator: coordinator)
```

#### Step 6: First Action Guidance (NEW)
**View:** `Views/Onboarding/FirstActionGuidanceView.swift`

- Shows setup summary
- Provides step-by-step guidance
- Completes onboarding

```swift
FirstActionGuidanceView(
    coordinator: coordinator,
    isOnboardingPresented: $isPresented
)
```

## Integration

### In OnboardingView.swift

```swift
struct OnboardingView: View {
    @StateObject private var coordinator = OnboardingCoordinator()
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isPresented: Bool
    
    var body: some View {
        TabView(selection: $coordinator.currentStep) {
            WelcomePageView()
                .tag(OnboardingStep.welcome)
            
            PrivacyPageView(selectedMode: $coordinator.selectedProcessingMode)
                .tag(OnboardingStep.privacy)
            
            FeaturesPageView()
                .tag(OnboardingStep.features)
            
            AccountSetupStepView(coordinator: coordinator)
                .tag(OnboardingStep.accountSetup)
            
            BiometricSetupPageView(enableBiometric: $coordinator.enableBiometric)
                .tag(OnboardingStep.biometric)
            
            QuickStartView(coordinator: coordinator)
                .tag(OnboardingStep.quickStart)
            
            FirstActionGuidanceView(
                coordinator: coordinator,
                isOnboardingPresented: $isPresented
            )
                .tag(OnboardingStep.firstAction)
        }
        .onChange(of: coordinator.isComplete) { isComplete in
            if isComplete {
                Task {
                    await viewModel.completeOnboarding(
                        context: viewContext,
                        coordinator: coordinator
                    )
                    isPresented = false
                }
            }
        }
    }
}
```

### In OnboardingViewModel.swift

```swift
// Complete onboarding with coordinator data
await viewModel.completeOnboarding(
    context: context,
    coordinator: coordinator
)

// Retrieve first action later
if let firstAction = OnboardingViewModel.getFirstAction() {
    // Navigate to appropriate view
    switch firstAction {
    case .uploadStatement:
        // Show StatementUploadView
    case .manualEntry:
        // Show TransactionEntryView
    case .createBudget:
        // Show BudgetCreationView
    }
}
```

## Data Flow

```
User Input → OnboardingCoordinator → OnboardingViewModel → Core Data
                    ↓
            State Updates
                    ↓
              UI Updates
```

### What Gets Saved

1. **Accounts** → Core Data Account entities
2. **Privacy Mode** → PrivacyManager
3. **Biometric** → BiometricAuthService
4. **First Action** → UserDefaults
5. **Completion Status** → UserDefaults

## Validation Rules

### Account Name
- ✅ Must not be empty
- ✅ Minimum 2 characters
- ✅ Maximum 50 characters

### Account Balance
- ✅ Non-negative for checking, savings, cash, investment
- ✅ Can be negative for credit cards

### Step Progression
- ✅ Welcome → Always can advance
- ✅ Privacy → Always can advance (defaults to local-only)
- ✅ Features → Always can advance
- ✅ Account Setup → Can advance if accounts exist OR skip
- ✅ Biometric → Always can advance (optional)
- ✅ Quick Start → Can advance if action selected OR skip
- ✅ First Action → Always can complete

## Skip Functionality

### Account Setup
```swift
// Skip button creates default account
coordinator.createDefaultAccount()
coordinator.advance()

// Creates:
AccountSetupData(
    name: "Cash",
    type: .cash,
    initialBalance: 0,
    isDefault: true
)
```

### Quick Start
```swift
// Skip button clears selection and advances
coordinator.selectedFirstAction = nil
coordinator.advance()
```

## Analytics Tracking

```swift
// Onboarding started
Analytics.track(.onboardingStarted)

// Step viewed
Analytics.track(.screenViewed, properties: [
    "screen_name": "onboarding_account_setup",
    "step_number": 3
])

// Onboarding completed
Analytics.track(.onboardingCompleted, properties: [
    "processing_mode": "local",
    "biometric_enabled": true,
    "accounts_created": 2,
    "first_action": "uploadStatement"
])
```

## Accessibility

All views include:
- ✅ VoiceOver labels
- ✅ Accessibility hints
- ✅ Proper traits (button, selected, etc.)
- ✅ Combined elements where appropriate

```swift
// Example
Button(action: onSelect) {
    // Content
}
.accessibilityLabel("Upload a Statement")
.accessibilityHint("Scan your bank statement to import transactions")
.accessibilityAddTraits(.isButton)
```

## Common Patterns

### Adding a New Step

1. Add case to `OnboardingStep` enum
2. Create view file in `Views/Onboarding/`
3. Add to TabView in `OnboardingView`
4. Update validation in `canAdvance()`
5. Add analytics tracking

### Accessing Coordinator State

```swift
// In any child view
@ObservedObject var coordinator: OnboardingCoordinator

// Read state
let accounts = coordinator.createdAccounts
let action = coordinator.selectedFirstAction

// Update state
coordinator.addAccount(newAccount)
coordinator.selectFirstAction(.manualEntry)
```

### Custom Validation

```swift
func validateCurrentStep() -> ValidationResult {
    switch currentStep {
    case .accountSetup:
        if createdAccounts.isEmpty {
            return .warning("No accounts created")
        }
        return .valid
    // ... other cases
    }
}
```

## Testing

### Preview Support

```swift
#Preview("Account Setup - Empty") {
    AccountSetupStepView(coordinator: OnboardingCoordinator())
}

#Preview("Account Setup - With Accounts") {
    let coordinator = OnboardingCoordinator()
    coordinator.createdAccounts = AccountSetupData.samples
    return AccountSetupStepView(coordinator: coordinator)
}
```

### Manual Testing Checklist

- [ ] Complete full onboarding flow
- [ ] Skip account setup
- [ ] Add multiple accounts
- [ ] Edit account
- [ ] Delete account
- [ ] Set different account as default
- [ ] Select each first action type
- [ ] Skip quick start
- [ ] Test back navigation
- [ ] Verify accounts saved to Core Data
- [ ] Verify first action saved
- [ ] Test with VoiceOver enabled

## Troubleshooting

### Accounts not saving
- Check Core Data context is passed correctly
- Verify `completeOnboarding()` is called
- Check for save errors in console

### Navigation not working
- Ensure `isOnboardingPresented` binding is correct
- Verify `coordinator.isComplete` triggers onChange
- Check TabView selection binding

### Validation errors
- Review `AccountSetupData.validate()` logic
- Check error messages in `ValidationError`
- Verify field constraints

## Future Enhancements

- [ ] Add UI tests (task 3.9)
- [ ] Wire up first action navigation
- [ ] Add confetti animation to success view
- [ ] Add progress indicator
- [ ] Support editing onboarding preferences later
- [ ] Add onboarding tutorial videos

---

**Quick Start**: Just add `@StateObject private var coordinator = OnboardingCoordinator()` to your OnboardingView and pass it to the new step views!
