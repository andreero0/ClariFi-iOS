# Onboarding Flow Tests - Quick Reference

## Test File Location
```
Tests/UITests/OnboardingFlowTests.swift
```

## Running Tests

### Run All Onboarding Tests
```bash
xcodebuild test -scheme ClariFi_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/OnboardingFlowTests
```

### Run Specific Test Category

**Complete Flow Tests:**
```bash
xcodebuild test -scheme ClariFi_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/OnboardingFlowTests/testCompleteOnboardingFlowWithAllSteps
```

**Account Creation Tests:**
```bash
xcodebuild test -scheme ClariFi_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/OnboardingFlowTests/testAccountCreationWithValidData
```

**Quick Start Tests:**
```bash
xcodebuild test -scheme ClariFi_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/OnboardingFlowTests/testQuickStartActionSelection
```

**Back Navigation Tests:**
```bash
xcodebuild test -scheme ClariFi_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/OnboardingFlowTests/testBackNavigationPreservesState
```

## Test Categories

### 1. Complete Flow (3 tests)
- `testCompleteOnboardingFlowWithAllSteps` - Full journey
- `testCompleteOnboardingFlowWithSkips` - With optional steps skipped
- `testOnboardingProgressTracking` - Progress calculation

### 2. Account Creation (7 tests)
- `testAccountCreationWithValidData` - Single account
- `testMultipleAccountCreation` - Multiple accounts
- `testAccountRemoval` - Removing accounts
- `testSetDefaultAccount` - Changing default
- `testDefaultAccountCreation` - Skip functionality
- `testAccountSetupValidation` - Validation logic

### 3. Quick Start (6 tests)
- `testQuickStartActionSelection` - Selecting action
- `testQuickStartActionChange` - Changing selection
- `testQuickStartAllActionTypes` - All action types
- `testQuickStartValidation` - Validation
- `testQuickStartSkipFunctionality` - Skip behavior

### 4. Skip Functionality (5 tests)
- `testSkipAccountSetup` - Skip account creation
- `testSkipBiometricSetup` - Skip biometric
- `testSkipQuickStart` - Skip action selection
- `testOptionalStepsIdentification` - Optional flags

### 5. Back Navigation (5 tests)
- `testBackNavigationFromPrivacy` - From step 2
- `testBackNavigationFromAccountSetup` - With data
- `testBackNavigationFromQuickStart` - With selection
- `testBackNavigationFromFirstStep` - Boundary
- `testBackNavigationPreservesState` - State preservation

### 6. View Integration (5 tests)
- `testOnboardingViewCreation` - Main view
- `testAccountSetupStepViewCreation` - Account setup
- `testQuickStartViewCreation` - Quick start
- `testFirstActionGuidanceViewCreation` - Guidance
- `testOnboardingSuccessViewCreation` - Success

### 7. Validation (2 tests)
- `testValidationForAllSteps` - All step validation
- `testCanAdvanceLogic` - Advance logic

### 8. Edge Cases (7 tests)
- `testEmptyAccountName` - Empty validation
- `testNegativeBalanceForNonCreditAccount` - Invalid negative
- `testNegativeBalanceForCreditAccount` - Valid negative
- `testAccountNameTooLong` - Length validation
- `testAccountNameTooShort` - Minimum length
- `testMultipleDefaultAccounts` - Default logic
- `testSkipToInvalidStep` - Boundary

### 9. Accessibility (3 tests)
- `testOnboardingStepTitles` - Step titles
- `testAccountTypeAccessibility` - Account types
- `testFirstActionTypeAccessibility` - Action types

## Quick Test Commands

### Test Complete Flow Only
```bash
xcodebuild test -scheme ClariFi_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/OnboardingFlowTests/testCompleteOnboardingFlowWithAllSteps \
  -only-testing:ClariFi_iOSTests/OnboardingFlowTests/testCompleteOnboardingFlowWithSkips
```

### Test All Account Creation
```bash
xcodebuild test -scheme ClariFi_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/OnboardingFlowTests/testAccountCreationWithValidData \
  -only-testing:ClariFi_iOSTests/OnboardingFlowTests/testMultipleAccountCreation \
  -only-testing:ClariFi_iOSTests/OnboardingFlowTests/testAccountRemoval
```

### Test All Navigation
```bash
xcodebuild test -scheme ClariFi_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/OnboardingFlowTests/testBackNavigationFromPrivacy \
  -only-testing:ClariFi_iOSTests/OnboardingFlowTests/testBackNavigationFromAccountSetup \
  -only-testing:ClariFi_iOSTests/OnboardingFlowTests/testBackNavigationPreservesState
```

## Expected Results

### Success Output
```
Test Suite 'OnboardingFlowTests' passed
Executed 40 tests, with 0 failures (0 unexpected)
```

### Test Execution Time
- Individual tests: < 0.1 seconds
- Full suite: < 10 seconds

## Debugging Failed Tests

### Common Issues

**Issue: Coordinator state not reset**
```swift
// Solution: Check setUp() method
override func setUp() async throws {
    coordinator = OnboardingCoordinator() // Fresh instance
}
```

**Issue: Async state updates**
```swift
// Solution: Tests use @MainActor
@MainActor
class OnboardingFlowTests: XCTestCase {
    // All tests run on main actor
}
```

**Issue: View creation fails**
```swift
// Solution: Check view initializers match
let view = AccountSetupStepView(coordinator: coordinator)
XCTAssertNotNil(view)
```

## Test Coverage Report

Generate coverage report:
```bash
xcodebuild test -scheme ClariFi_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES \
  -only-testing:ClariFi_iOSTests/OnboardingFlowTests
```

View coverage:
```bash
xcrun xccov view --report \
  ~/Library/Developer/Xcode/DerivedData/*/Logs/Test/*.xcresult
```

## Integration with CI/CD

### GitHub Actions Example
```yaml
- name: Run Onboarding Tests
  run: |
    xcodebuild test \
      -scheme ClariFi_iOS \
      -destination 'platform=iOS Simulator,name=iPhone 15' \
      -only-testing:ClariFi_iOSTests/OnboardingFlowTests
```

### Fastlane Example
```ruby
lane :test_onboarding do
  run_tests(
    scheme: "ClariFi_iOS",
    devices: ["iPhone 15"],
    only_testing: ["ClariFi_iOSTests/OnboardingFlowTests"]
  )
end
```

## Requirements Verified

✅ **Requirement 3.1**: Complete Onboarding-to-Action Flow
- Tests verify full journey from welcome to first action

✅ **Requirement 3.2**: Quick Start Screen  
- Tests verify action selection and skip functionality

✅ **Requirement 3.3**: First Action Guidance
- Tests verify guidance view and navigation

✅ **Requirement 8.1**: Progressive Disclosure
- Tests verify 7-step flow and optional steps

## Next Steps

After running tests:
1. ✅ Verify all tests pass
2. ✅ Check code coverage (target: >90%)
3. ✅ Review any failures
4. ✅ Update tests if requirements change
5. ✅ Add to CI/CD pipeline

## Related Files

- **Implementation**: `ViewModels/OnboardingCoordinator.swift`
- **Views**: `Views/Onboarding/*.swift`
- **Models**: `Models/AccountSetupData.swift`
- **Tests**: `Tests/UITests/OnboardingFlowTests.swift`
- **Summary**: `.kiro/specs/critical-ux-fixes/TASK_3.9_TEST_SUMMARY.md`
