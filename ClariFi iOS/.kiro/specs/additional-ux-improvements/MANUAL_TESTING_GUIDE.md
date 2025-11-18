# Manual Testing Guide - Additional UX Improvements

## Overview

This guide provides step-by-step instructions for manually testing all the UX improvements implemented in this spec. Complete each section and check off items as you verify them.

---

## 15.1 Transaction Editing Flow

### Prerequisites
- App is running in simulator or on device
- At least one transaction exists in the app

### Test Cases

#### TC1: Edit Transaction - Happy Path
1. Navigate to Activity tab
2. Tap on any transaction to open detail view
3. Tap "Edit" button in toolbar
4. Verify edit sheet opens with current transaction data pre-filled
5. Modify merchant name
6. Modify amount
7. Change category using category picker
8. Add/modify notes
9. Tap "Save"
10. Verify loading indicator appears briefly
11. Verify success toast appears
12. Verify detail view updates with new data
13. Verify changes persist after closing and reopening

**Expected**: All changes save successfully and persist

#### TC2: Edit Transaction - Validation
1. Open transaction edit sheet
2. Clear merchant name field
3. Verify inline error appears: "Merchant name is required"
4. Verify Save button is disabled
5. Enter merchant name
6. Verify error clears
7. Clear amount field
8. Verify inline error appears: "Amount is required"
9. Enter "0" as amount
10. Verify inline error appears: "Amount must be greater than 0"
11. Enter valid amount
12. Verify error clears and Save button enables

**Expected**: Validation prevents invalid data from being saved

#### TC3: Edit Transaction - Cancel
1. Open transaction edit sheet
2. Modify several fields
3. Tap "Cancel"
4. Verify sheet dismisses
5. Verify no changes were saved
6. Reopen transaction detail
7. Verify original data is still present

**Expected**: Cancel discards all changes

#### TC4: Edit Transaction - Error Handling
1. Turn on Airplane Mode (to simulate network/save failure)
2. Open transaction edit sheet
3. Make changes
4. Tap Save
5. Verify error alert appears with appropriate message
6. Verify "Retry" and "Cancel" options are available
7. Turn off Airplane Mode
8. Tap "Retry"
9. Verify save succeeds

**Expected**: Errors are handled gracefully with retry option

---

## 15.2 Navigation Flows

### Test Cases

#### TC5: "See All" Navigation from Home
1. Navigate to Home tab
2. Scroll to Insights section
3. Tap "See All" button
4. Verify app switches to Activity tab
5. Verify Activity tab shows transaction list
6. Navigate back to Home tab
7. Verify Home tab state is preserved

**Expected**: Navigation switches tabs correctly and preserves state

#### TC6: Tab Switching
1. Navigate to Home tab
2. Tap Activity tab
3. Tap Planning tab
4. Tap Home tab again
5. Verify each tab loads correctly
6. Verify no crashes or UI glitches

**Expected**: Smooth tab switching with no issues

#### TC7: Deep Navigation State
1. Home tab → Tap transaction → Open detail
2. Switch to Activity tab
3. Switch back to Home tab
4. Verify you're back at Home root (not still in detail)

**Expected**: Tab switching resets navigation stack appropriately

---

## 15.3 Premium Features

### Test Cases

#### TC8: Free User Experience
1. Ensure you're logged in as free user (or not subscribed)
2. Navigate to Planning tab
3. Verify PremiumUpsellView is displayed
4. Verify upsell shows:
   - Premium icon
   - "Upgrade to Premium" title
   - List of benefits
   - "Upgrade to Premium" button
5. Tap "Upgrade to Premium" button
6. Verify paywall/subscription screen appears

**Expected**: Free users see upsell and can access upgrade flow

#### TC9: Premium User Experience
1. Ensure you have active premium subscription
2. Navigate to Planning tab
3. Verify full planning features are visible (no upsell)
4. Verify "Manage Subscription" button appears in settings
5. Tap "Manage Subscription"
6. Verify App Store subscription management opens

**Expected**: Premium users see full features and can manage subscription

#### TC10: Upgrade Flow
1. As free user, tap "Upgrade to Premium"
2. Complete subscription purchase (or use test account)
3. Verify app recognizes premium status
4. Navigate to Planning tab
5. Verify upsell is replaced with full features

**Expected**: Upgrade flow works and app updates immediately

---

## 15.4 Empty States and Feedback

### Test Cases

#### TC11: Empty State - No Transactions
1. Delete all transactions (or use fresh install)
2. Navigate to Activity tab
3. Verify EmptyStateView appears with:
   - Appropriate icon
   - "No Transactions Yet" title
   - Helpful message
   - "Add Transaction" button (if applicable)

**Expected**: Empty state is clear and helpful

#### TC12: Empty State - No Budget
1. Ensure no budget is set
2. Navigate to Planning tab (as premium user)
3. Verify empty state appears for budget section
4. Verify action button to create budget is present

**Expected**: Empty state guides user to create budget

#### TC13: Loading States
1. Create a new transaction
2. Observe loading indicator during save
3. Verify UI is disabled during loading
4. Verify loading indicator disappears after save completes
5. Repeat for other async operations (budget creation, etc.)

**Expected**: Loading states are visible and prevent duplicate actions

#### TC14: Success Feedback
1. Create a new transaction
2. Verify success toast appears at top of screen
3. Verify toast shows checkmark icon and success message
4. Verify toast auto-dismisses after 2-3 seconds
5. Edit a transaction
6. Verify success toast appears
7. Create a budget
8. Verify success toast appears

**Expected**: Success feedback is consistent and non-intrusive

---

## 15.5 Accessibility

### Test Cases

#### TC15: VoiceOver Support
1. Enable VoiceOver (Settings → Accessibility → VoiceOver)
2. Navigate through app using VoiceOver gestures
3. Verify all buttons have descriptive labels
4. Verify form fields announce their purpose
5. Verify validation errors are announced
6. Verify success/error messages are announced
7. Test transaction editing flow with VoiceOver
8. Verify category picker is navigable

**Expected**: All UI elements are accessible via VoiceOver

#### TC16: Dynamic Type
1. Go to Settings → Display & Brightness → Text Size
2. Increase text size to maximum
3. Open app and navigate through all screens
4. Verify text scales appropriately
5. Verify layouts don't break
6. Verify no text is truncated inappropriately
7. Reduce text size to minimum
8. Verify app still looks good

**Expected**: App adapts to all text sizes without breaking

#### TC17: High Contrast Mode
1. Enable Increase Contrast (Settings → Accessibility → Display & Text Size)
2. Navigate through app
3. Verify all text is readable
4. Verify buttons are clearly visible
5. Verify form fields have clear borders
6. Verify validation errors are visible

**Expected**: App is usable in high contrast mode

#### TC18: Touch Targets
1. Navigate through app
2. Verify all buttons are easy to tap
3. Verify no accidental taps on nearby elements
4. Test with larger finger/thumb
5. Verify minimum 44x44 point touch targets

**Expected**: All interactive elements are easily tappable

---

## 15.6 Performance Testing

### Test Cases

#### TC19: Large Dataset Performance
1. Create 100+ transactions (use script or manual entry)
2. Navigate to Activity tab
3. Verify list scrolls smoothly
4. Verify no lag when opening transaction details
5. Verify search/filter works quickly
6. Monitor memory usage in Xcode Instruments

**Expected**: App performs well with large datasets

#### TC20: Smooth Animations
1. Navigate through app
2. Observe all transitions and animations
3. Verify sheet presentations are smooth
4. Verify toast animations are smooth
5. Verify tab switching is instant
6. Verify no dropped frames

**Expected**: All animations are smooth (60fps)

#### TC21: Memory Usage
1. Open Xcode Instruments
2. Run Memory profiler
3. Navigate through all screens
4. Create/edit/delete transactions
5. Switch tabs multiple times
6. Verify no memory leaks
7. Verify memory usage is reasonable

**Expected**: No memory leaks, stable memory usage

#### TC22: Older Device Testing
1. Test on iPhone SE (2nd gen) or similar older device
2. Run through all test cases above
3. Verify performance is acceptable
4. Verify UI renders correctly on smaller screen

**Expected**: App works well on older/smaller devices

---

## Test Results Summary

### Completion Checklist

- [ ] TC1: Edit Transaction - Happy Path
- [ ] TC2: Edit Transaction - Validation
- [ ] TC3: Edit Transaction - Cancel
- [ ] TC4: Edit Transaction - Error Handling
- [ ] TC5: "See All" Navigation from Home
- [ ] TC6: Tab Switching
- [ ] TC7: Deep Navigation State
- [ ] TC8: Free User Experience
- [ ] TC9: Premium User Experience
- [ ] TC10: Upgrade Flow
- [ ] TC11: Empty State - No Transactions
- [ ] TC12: Empty State - No Budget
- [ ] TC13: Loading States
- [ ] TC14: Success Feedback
- [ ] TC15: VoiceOver Support
- [ ] TC16: Dynamic Type
- [ ] TC17: High Contrast Mode
- [ ] TC18: Touch Targets
- [ ] TC19: Large Dataset Performance
- [ ] TC20: Smooth Animations
- [ ] TC21: Memory Usage
- [ ] TC22: Older Device Testing

### Issues Found

Document any issues found during testing:

1. **Issue**: [Description]
   - **Severity**: Critical / High / Medium / Low
   - **Steps to Reproduce**: [Steps]
   - **Expected**: [Expected behavior]
   - **Actual**: [Actual behavior]

---

## Sign-off

- **Tester**: _______________
- **Date**: _______________
- **Build Version**: _______________
- **Test Environment**: _______________
- **Overall Status**: Pass / Fail / Pass with Issues

