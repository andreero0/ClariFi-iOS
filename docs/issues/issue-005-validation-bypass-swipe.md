# Issue #005: Users Can Bypass Validation by Swiping in Onboarding

## Labels
`bug`, `ux`, `onboarding`, `validation`, `navigation`

## Priority
🟠 **HIGH**

## Description

Users can swipe between onboarding steps in the TabView, bypassing validation logic. This allows users to skip required steps without meeting validation requirements.

## Impact

- **Severity**: HIGH
- **User Impact**: MEDIUM - Can skip required steps
- **Frequency**: Variable (only if users swipe instead of using buttons)
- **Data Integrity**: Compromised

### User Journey

1. User is on Account Setup step
2. User hasn't created any accounts
3. Validation blocks the "Continue" button
4. **User swipes left to go to next step anyway**
5. User bypasses validation and reaches Biometric Setup
6. User can complete onboarding without required data
7. App may crash or behave incorrectly due to missing data

## Root Cause

**Location**: `OnboardingView.swift:30-54`

### Current Code

```swift
TabView(selection: stepBinding) {
    WelcomePageView()
        .tag(OnboardingStep.welcome)

    PrivacyPageView(selectedMode: $coordinator.selectedProcessingMode)
        .tag(OnboardingStep.privacy)

    // ... 5 more steps ...
}
.tabViewStyle(.page(indexDisplayMode: .always))  // ⚠️ ALLOWS SWIPING
```

### The Problem

```swift
// OnboardingCoordinator.swift
func requestStepChange(to newStep: OnboardingStep) {
    guard newStep != currentStep else { return }

    if newStep.rawValue > currentStep.rawValue {
        let validation = validate(currentStep)
        guard validation.allowsAdvance(for: currentStep) else {
            // Tries to block, but TabView already changed!
            return  // ⚠️ TOO LATE
        }
    }

    setCurrentStep(newStep)
}
```

**Timeline**:
1. User swipes left
2. TabView binding changes immediately
3. `requestStepChange` is called
4. Validation check runs
5. **But page has already changed visually**
6. User sees next step even though validation failed

## Solution

Replace TabView paging with custom navigation buttons.

### 1. Disable TabView Swiping

```swift
// OnboardingView.swift
TabView(selection: stepBinding) {
    // ... steps ...
}
.tabViewStyle(.page(indexDisplayMode: .never))  // ✅ Disable indicators
.gesture(DragGesture().onChanged { _ in })  // ✅ Disable swipe gesture
```

### 2. Create Custom Navigation Bar

```swift
struct OnboardingNavigationBar: View {
    @ObservedObject var coordinator: OnboardingCoordinator

    var body: some View {
        HStack(spacing: 16) {
            // Back button
            if coordinator.currentStepIndex > 0 {
                Button(action: {
                    HapticFeedback.impact(.medium).trigger()
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
                        .accessibilityLabel("Step \(step.rawValue + 1)")
                        .accessibilityAddTraits(step.rawValue <= coordinator.currentStepIndex ? [.isSelected] : [])
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Progress: Step \(coordinator.currentStepIndex + 1) of \(coordinator.totalSteps)")

            Spacer()

            // Next/Continue button
            Button(action: {
                HapticFeedback.impact(.medium).trigger()
                coordinator.advance()
            }) {
                HStack {
                    Text(coordinator.currentStep == .firstAction ? "Complete" : "Continue")
                    if coordinator.currentStep != .firstAction {
                        Image(systemName: "chevron.right")
                    }
                }
                .frame(minWidth: 100)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!coordinator.canAdvance())
            .accessibilityLabel(coordinator.currentStep == .firstAction ? "Complete onboarding" : "Continue to next step")
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
```

### 3. Add to OnboardingView

```swift
struct OnboardingView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: stepBinding) {
                // ... steps ...
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .gesture(DragGesture().onChanged { _ in })

            // Custom navigation bar
            OnboardingNavigationBar(coordinator: coordinator)
                .padding(.bottom, 20)
        }
    }
}
```

### 4. Add Validation Feedback

```swift
struct OnboardingView: View {
    @State private var showValidationError = false
    @State private var validationMessage = ""

    var body: some View {
        ZStack {
            // ... existing TabView and navigation bar ...

            // Validation error banner
            if showValidationError {
                VStack {
                    Spacer()

                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)

                        Text(validationMessage)
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 100)  // Above navigation bar
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: showValidationError)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Error: \(validationMessage)")
            }
        }
    }
}
```

### 5. Update OnboardingCoordinator

```swift
@Published var shouldShowValidationError = false
@Published var validationMessage = ""

func advance() {
    let validation = validate(currentStep)

    guard validation.allowsAdvance(for: currentStep) else {
        // Show validation error
        if let message = validation.message {
            validationMessage = message
            shouldShowValidationError = true

            // Hide after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                shouldShowValidationError = false
            }
        }
        return
    }

    // ... existing advance logic ...
}
```

### 6. Remove TabView Page Indicators

Individual step views should no longer show "Swipe to continue" text since swiping is disabled.

## Testing Requirements

- [ ] Test cannot swipe forward when validation fails
- [ ] Test can still go back freely
- [ ] Test navigation buttons work correctly
- [ ] Test validation error banner appears
- [ ] Test validation error dismisses after 3 seconds
- [ ] Test progress indicator updates correctly
- [ ] Test Continue button is disabled when validation fails
- [ ] Test accessibility navigation
- [ ] Test VoiceOver support for custom buttons
- [ ] Test haptic feedback triggers

## Acceptance Criteria

- [ ] Cannot bypass validation by swiping
- [ ] Navigation buttons provide clear forward/back controls
- [ ] Progress indicator shows current position
- [ ] Validation errors appear in user-friendly banner
- [ ] Continue button disabled when validation fails
- [ ] Accessibility fully supported
- [ ] All existing tests pass
- [ ] New tests cover navigation behavior

## Related Issues

None

## Files to Modify

1. `Views/OnboardingView.swift:30-54` - Disable swiping, add custom navigation
2. Create `Views/Onboarding/OnboardingNavigationBar.swift`
3. `ViewModels/OnboardingCoordinator.swift` - Add validation feedback
4. `Views/Onboarding/WelcomePageView.swift` - Remove "Swipe to continue" text
5. `Views/Onboarding/FeaturesPageView.swift` - Remove "Swipe to continue" text
6. `ClariFi iOSTests/UITests/OnboardingFlowTests.swift` - Add swipe prevention tests

## Estimated Time

**3-4 hours**

## Assignee

Unassigned

## References

- Fix Proposal: `docs/fixes/CRITICAL_FIX_PROPOSALS.md#critical-issue-5`
- Code Review: Comprehensive Code Review Report
- Apple HIG: Multi-step flows should use buttons, not swipes
