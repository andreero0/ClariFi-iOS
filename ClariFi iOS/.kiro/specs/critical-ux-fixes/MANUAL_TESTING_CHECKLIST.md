# Manual Testing Checklist

## Overview

This checklist covers manual testing scenarios that complement the automated integration tests. These tests focus on UI/UX aspects, device-specific behavior, and real-world usage scenarios.

**Related**: Task 7.8 - Final integration testing  
**Requirements**: 9.6

## Pre-Testing Setup

- [ ] Build app in Release configuration
- [ ] Clear all app data and preferences
- [ ] Test on clean simulator/device (no previous app data)
- [ ] Ensure good network connectivity (for any cloud features)
- [ ] Have test bank statements ready (PDF/images)

## Device Testing Matrix

### iPhone Models to Test

- [ ] iPhone SE (3rd gen) - Small screen (4.7")
- [ ] iPhone 15 - Standard size (6.1")
- [ ] iPhone 15 Pro Max - Large screen (6.7")
- [ ] iPhone 15 Plus - Large screen (6.7")

### iPad Models to Test (if supported)

- [ ] iPad (10th gen) - Standard size
- [ ] iPad Pro 12.9" - Large screen

### iOS Versions to Test

- [ ] iOS 17.0 (minimum supported)
- [ ] iOS 17.5 (current stable)
- [ ] iOS 18.0 beta (if available)

## 1. Complete User Journey Testing

### First Launch Experience

- [ ] App launches without crashes
- [ ] Splash screen displays correctly
- [ ] Onboarding starts automatically
- [ ] No authentication errors

### Onboarding Flow

#### Welcome Step
- [ ] Welcome message displays clearly
- [ ] App icon/branding visible
- [ ] "Get Started" button works
- [ ] Text readable on all device sizes

#### Privacy Step
- [ ] Privacy explanation clear and concise
- [ ] Local-only processing option available
- [ ] Privacy policy link works (if present)
- [ ] User can select processing mode

#### Features Step
- [ ] Feature highlights display correctly
- [ ] Icons and images load properly
- [ ] Text not truncated on small screens
- [ ] Animations smooth (if present)

#### Account Setup Step
- [ ] Account name field accepts input
- [ ] Account type picker shows all options
- [ ] Initial balance field accepts decimal input
- [ ] Keyboard type appropriate (decimal for amount)
- [ ] "Add Account" button works
- [ ] Multiple accounts can be added
- [ ] "Skip" creates default Cash account
- [ ] Validation errors display clearly
- [ ] Can delete added accounts before proceeding

#### Biometric Setup Step
- [ ] Biometric prompt displays correctly
- [ ] Face ID/Touch ID works (on supported devices)
- [ ] "Skip" option available
- [ ] Can enable later in settings

#### Quick Start Step
- [ ] Three action cards display clearly
- [ ] Icons visible and appropriate
- [ ] Descriptions clear and helpful
- [ ] Selection state visible
- [ ] Can change selection
- [ ] "Continue" button enabled when selected

#### First Action Guidance Step
- [ ] Guidance matches selected action
- [ ] Navigation to selected feature works
- [ ] Tips and hints helpful
- [ ] "Get Started" button works

### Onboarding Completion
- [ ] Success animation displays (if present)
- [ ] Completion message clear
- [ ] Transitions to main app smoothly
- [ ] Onboarding doesn't show again

**Time to Complete**: _____ minutes (target: < 5 minutes)

## 2. Budget Template Testing

### Template Selection

Test each of the 18 budget templates:

#### 1. 50/30/20 Budget
- [ ] Template loads correctly
- [ ] Categories display properly
- [ ] Percentages calculated correctly
- [ ] Can customize amounts
- [ ] Budget saves successfully

#### 2. Zero-Based Budget
- [ ] All income allocated
- [ ] Categories comprehensive
- [ ] Balance shows zero when complete

#### 3. Envelope Budget
- [ ] Envelope metaphor clear
- [ ] Categories appropriate
- [ ] Visual design intuitive

#### 4. Pay Yourself First
- [ ] Savings prioritized
- [ ] Remaining income allocated
- [ ] Percentages make sense

#### 5. 80/20 Budget
- [ ] Simple two-category split
- [ ] Easy to understand
- [ ] Quick to set up

#### 6. Reverse Budget
- [ ] Savings first approach
- [ ] Flexible spending clear
- [ ] Calculations correct

#### 7. Values-Based Budget
- [ ] Value categories meaningful
- [ ] Customization options available
- [ ] Aligns with user values

#### 8. Anti-Budget
- [ ] Minimal tracking approach
- [ ] Savings automated
- [ ] Spending flexible

#### 9. Military Budget (BAH)
- [ ] BAH category present
- [ ] Military-specific categories
- [ ] Appropriate for service members

#### 10. Student Budget
- [ ] Education categories present
- [ ] Student-relevant expenses
- [ ] Loan payments included

#### 11. Freelancer Budget
- [ ] Irregular income handling
- [ ] Business expense categories
- [ ] Tax savings included

#### 12. Retirement Budget
- [ ] Fixed income focus
- [ ] Healthcare prominent
- [ ] Leisure categories included

#### 13. Debt Payoff Budget
- [ ] Debt categories clear
- [ ] Payoff strategy evident
- [ ] Progress tracking available

#### 14. Emergency Fund Budget
- [ ] Emergency savings prioritized
- [ ] Goal setting available
- [ ] Progress visible

#### 15. Family Budget
- [ ] Family-specific categories
- [ ] Childcare included
- [ ] Education expenses present

#### 16. Single Income Budget
- [ ] Conservative allocations
- [ ] Emergency fund emphasized
- [ ] Appropriate for one income

#### 17. Dual Income Budget
- [ ] Higher income assumptions
- [ ] Investment categories
- [ ] Lifestyle categories included

#### 18. Minimalist Budget
- [ ] Minimal categories
- [ ] Essential focus
- [ ] Simple and clean

### Budget-Transaction Integration

For each template tested:
- [ ] Add transaction in budget category
- [ ] Transaction appears in budget tracking
- [ ] Spending updates correctly
- [ ] Remaining amount calculates properly
- [ ] Visual indicators (progress bars) update
- [ ] Overspending warnings appear (if applicable)

## 3. Transaction Entry Testing

### Manual Transaction Entry

#### Basic Entry
- [ ] Date picker works correctly
- [ ] Merchant name field accepts input
- [ ] Amount field accepts decimal input
- [ ] Category picker shows all categories
- [ ] Categories match active budget
- [ ] Notes field optional
- [ ] "Save" button works
- [ ] Transaction appears in list

#### Category Selection
- [ ] All canonical categories present
- [ ] Display names user-friendly
- [ ] Icons visible and appropriate
- [ ] Search/filter works (if present)
- [ ] Recently used categories highlighted (if present)

#### Validation
- [ ] Required fields marked clearly
- [ ] Empty amount shows error
- [ ] Invalid date shows error
- [ ] Error messages helpful
- [ ] Can correct errors without losing data

### Statement Upload

#### Upload Process
- [ ] Camera access requested properly
- [ ] Can select from photo library
- [ ] Can take new photo
- [ ] Image preview displays
- [ ] OCR processing starts
- [ ] Loading indicator shows progress
- [ ] Processing completes in < 30 seconds

#### OCR Results
- [ ] Transactions extracted correctly
- [ ] Merchant names readable
- [ ] Amounts accurate
- [ ] Dates parsed correctly
- [ ] Categories suggested appropriately

#### Review and Edit
- [ ] Can edit extracted transactions
- [ ] Can delete incorrect transactions
- [ ] Can add missing transactions
- [ ] Can change categories
- [ ] "Import All" button works
- [ ] Transactions save correctly

### Real Statement Testing

Test with actual bank statements:

#### Chase Bank Statement
- [ ] Transactions extracted
- [ ] Format recognized
- [ ] Data accurate

#### Bank of America Statement
- [ ] Transactions extracted
- [ ] Format recognized
- [ ] Data accurate

#### Wells Fargo Statement
- [ ] Transactions extracted
- [ ] Format recognized
- [ ] Data accurate

#### Credit Card Statement
- [ ] Transactions extracted
- [ ] Negative amounts handled
- [ ] Categories appropriate

## 4. LLM Categorization Testing

### Merchant Recognition

Test with real merchant names:

- [ ] `WHOLEFDS MKT #10234` → Food & Groceries
- [ ] `AMZN MKTP US*2X3Y4Z5A6` → Shopping
- [ ] `SQ *BLUE BOTTLE COFFEE` → Dining
- [ ] `SHELL OIL 12345678` → Transportation
- [ ] `NETFLIX.COM` → Entertainment
- [ ] `PAYPAL *SPOTIFY` → Entertainment
- [ ] `LANDLORD PROPERTY MGMT` → Housing
- [ ] `PG&E WEB ONLINE` → Utilities
- [ ] `WALGREENS #8765` → Healthcare
- [ ] `APPLE.COM/BILL` → Subscriptions

### Categorization Accuracy

- [ ] Common merchants categorized correctly
- [ ] Ambiguous merchants handled reasonably
- [ ] Unknown merchants default to "Other"
- [ ] User can override categories
- [ ] Overrides remembered for future

### Fallback Behavior

- [ ] Works when LLM unavailable
- [ ] Pattern matching kicks in
- [ ] No errors or crashes
- [ ] User experience consistent

## 5. Error Scenario Testing

### Network Errors (if applicable)
- [ ] Offline mode works
- [ ] Error messages clear
- [ ] Can retry failed operations
- [ ] Data not lost

### Data Validation Errors
- [ ] Invalid account ID handled
- [ ] Empty required fields caught
- [ ] Invalid amounts rejected
- [ ] Invalid dates rejected
- [ ] Error messages helpful

### System Errors
- [ ] Low memory handled gracefully
- [ ] Background app termination handled
- [ ] Data corruption prevented
- [ ] Recovery options available

### Edge Cases
- [ ] Very large amounts (> $1M)
- [ ] Very small amounts (< $0.01)
- [ ] Future dates
- [ ] Very old dates
- [ ] Special characters in merchant names
- [ ] Very long merchant names
- [ ] Emoji in notes

## 6. Device-Specific Testing

### Small Screen (iPhone SE)
- [ ] All text readable
- [ ] Buttons not too small
- [ ] No horizontal scrolling
- [ ] Keyboard doesn't hide inputs
- [ ] Navigation clear

### Large Screen (iPhone Pro Max)
- [ ] Layout uses space well
- [ ] No awkward stretching
- [ ] Text not too large
- [ ] Touch targets appropriate

### iPad (if supported)
- [ ] Layout optimized for tablet
- [ ] Split view works (if applicable)
- [ ] Landscape orientation works
- [ ] Multitasking works

### Accessibility

#### VoiceOver
- [ ] All elements have labels
- [ ] Navigation logical
- [ ] Hints helpful
- [ ] Can complete all tasks

#### Dynamic Type
- [ ] Text scales appropriately
- [ ] Layout adjusts
- [ ] No text truncation
- [ ] Readable at all sizes

#### Color Contrast
- [ ] Meets WCAG AA standards
- [ ] Readable in bright light
- [ ] Readable in dark mode
- [ ] Color not sole indicator

#### Reduce Motion
- [ ] Animations respect setting
- [ ] No motion sickness triggers
- [ ] Functionality preserved

## 7. Performance Testing

### App Launch
- [ ] Cold launch < 2 seconds
- [ ] Warm launch < 1 second
- [ ] No splash screen delay
- [ ] Responsive immediately

### Navigation
- [ ] Screen transitions smooth
- [ ] No lag or stuttering
- [ ] Back navigation instant
- [ ] Tab switching smooth

### Data Loading
- [ ] Transaction list loads quickly
- [ ] Budget view loads quickly
- [ ] Large datasets handled well
- [ ] Pagination works (if present)

### Memory Usage
- [ ] No memory warnings
- [ ] No crashes on low memory
- [ ] Background memory reasonable
- [ ] No memory leaks

### Battery Usage
- [ ] No excessive battery drain
- [ ] Background usage minimal
- [ ] Location services off (if not needed)
- [ ] Network usage reasonable

## 8. User Experience Testing

### First Impression
- [ ] App feels polished
- [ ] Design consistent
- [ ] Branding clear
- [ ] Professional appearance

### Ease of Use
- [ ] Intuitive navigation
- [ ] Clear labels
- [ ] Helpful hints
- [ ] Minimal learning curve

### Visual Design
- [ ] Colors pleasant
- [ ] Typography readable
- [ ] Icons clear
- [ ] Spacing appropriate
- [ ] Dark mode looks good

### Feedback
- [ ] Actions have feedback
- [ ] Loading states clear
- [ ] Success states satisfying
- [ ] Error states helpful

## 9. Regression Testing

### Previously Fixed Issues
- [ ] Authentication flow works
- [ ] Category consistency maintained
- [ ] DI container single instance
- [ ] No memory leaks
- [ ] All ViewModels use DI properly

### Core Functionality
- [ ] Accounts CRUD works
- [ ] Transactions CRUD works
- [ ] Budgets CRUD works
- [ ] Categories consistent
- [ ] Data persists correctly

## Test Results Summary

### Devices Tested
- Device 1: _________________ (iOS version: _____)
- Device 2: _________________ (iOS version: _____)
- Device 3: _________________ (iOS version: _____)

### Issues Found
1. ________________________________________________
2. ________________________________________________
3. ________________________________________________

### Critical Issues (Blockers)
- [ ] None found
- [ ] Issues listed above

### Time Metrics
- Time to first transaction: _____ minutes (target: < 5)
- Statement processing time: _____ seconds (target: < 30)
- App launch time: _____ seconds (target: < 2)

### Overall Assessment
- [ ] Ready for production
- [ ] Minor issues to fix
- [ ] Major issues to fix
- [ ] Not ready for release

### Tester Information
- Name: _______________________
- Date: _______________________
- Build: _______________________
- Notes: _______________________

## Conclusion

This manual testing checklist ensures comprehensive coverage of user-facing functionality that automated tests cannot verify. Complete this checklist before each production release.

**Next Steps After Testing**:
1. Document all issues found
2. Prioritize issues (critical, major, minor)
3. Create tickets for fixes
4. Retest after fixes
5. Sign off for release
