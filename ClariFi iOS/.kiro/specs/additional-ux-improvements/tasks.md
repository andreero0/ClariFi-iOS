# Implementation Plan

- [x] 1. Set up transaction editing data model and validation
  - Create TransactionEditData.swift with initialization, validation, and change detection
  - Implement validation rules for merchant, amount, and category fields
  - _Requirements: 1.3, 1.4, 1.5, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 2. Implement repository update method
  - [x] 2.1 Add updateTransaction method to TransactionRepositoryProtocol
    - Define method signature with optional parameters for partial updates
    - _Requirements: 1.6, 1.7_
  
  - [x] 2.2 Implement updateTransaction in CoreDataTransactionRepository
    - Fetch transaction by ID with error handling
    - Update only non-nil fields
    - Update updatedAt timestamp automatically
    - Save context and return updated transaction
    - _Requirements: 1.6, 1.7_

- [x] 3. Create category picker component
  - [x] 3.1 Implement CategoryPickerView
    - Create list view with all CategoryDefinition categories
    - Display category display name and description
    - Show checkmark for selected category
    - Handle tap to select and dismiss
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [x] 4. Build transaction edit view
  - [x] 4.1 Create TransactionEditView with form layout
    - Implement date picker for transaction date
    - Add text field for merchant name
    - Add decimal text field for amount
    - Add category picker button
    - Add multiline text field for notes
    - Add preview section with formatted amount
    - _Requirements: 1.2, 1.3_
  
  - [x] 4.2 Implement real-time validation in TransactionEditView
    - Show inline validation errors
    - Disable save button when invalid
    - Clear errors when fields become valid
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_
  
  - [x] 4.3 Add save and cancel functionality
    - Implement save button with loading state
    - Call repository updateTransaction method
    - Handle success and error cases
    - Implement cancel button to dismiss without saving
    - _Requirements: 1.4, 1.5, 1.6, 1.8, 7.1, 7.2, 7.3_

- [x] 5. Integrate edit functionality into transaction detail view
  - [x] 5.1 Add Edit button to TransactionDetailView toolbar
    - Create button that opens edit sheet
    - Initialize TransactionEditData from current transaction
    - _Requirements: 1.1_
  
  - [x] 5.2 Implement edit sheet presentation
    - Present TransactionEditView as sheet
    - Handle save callback to update transaction
    - Handle cancel callback to dismiss sheet
    - Show success feedback after save
    - _Requirements: 1.2, 1.8, 8.2_

- [x] 6. Fix navigation consistency
  - [x] 6.1 Update MainTabView to support programmatic tab selection
    - Add selection binding to TabView
    - Bind to AppState.selectedTab
    - Assign tags to each tab (0, 1, 2)
    - _Requirements: 3.2, 3.3_
  
  - [x] 6.2 Fix HomeView "See All" button in Insights section
    - Replace NavigationLink with Button
    - Set AppState.selectedTab to Activity tab (1)
    - _Requirements: 3.1, 3.3_
  
  - [x] 6.3 Verify all "See All" navigation patterns
    - Check other "See All" buttons in HomeView
    - Ensure consistent navigation behavior
    - Test state preservation on navigation
    - _Requirements: 3.3, 3.4_

- [x] 7. Implement premium feature UX improvements
  - [x] 7.1 Create PremiumUpsellView component
    - Design reusable upsell component with icon, title, benefits list
    - Add "Upgrade to Premium" button
    - Style consistently with app design
    - _Requirements: 4.2_
  
  - [x] 7.2 Add premium status checks to PlanningView
    - Check subscriptionViewModel.isPremium before showing premium features
    - Show PremiumUpsellView for non-premium users
    - Show full features for premium users
    - _Requirements: 4.1, 4.2, 4.3_
  
  - [x] 7.3 Add subscription management for premium users
    - Add "Manage Subscription" button in settings section
    - Open App Store subscription management URL
    - Only show for premium users
    - _Requirements: 4.5, 4.6_
  
  - [x] 7.4 Implement upgrade flow
    - Connect "Upgrade" button to paywall presentation
    - Use existing SubscriptionViewModel.showPaywall
    - _Requirements: 4.4_

- [x] 8. Create reusable empty state component
  - [x] 8.1 Implement EmptyStateView component
    - Create view with icon, title, message, and optional action button
    - Style consistently with app design
    - Add accessibility labels
    - _Requirements: 5.1, 5.2, 5.3_
  
  - [x] 8.2 Add empty states to key views
    - Add to transactions list when no transactions
    - Add to insights view when insufficient data
    - Add to budget view when no budget set
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 9. Implement loading states
  - [x] 9.1 Create LoadingOverlay component
    - Design full-screen loading overlay with progress indicator
    - Add semi-transparent background
    - Center loading indicator with message
    - _Requirements: 7.1, 7.2_
  
  - [x] 9.2 Add loading states to async operations
    - Add to transaction save operations
    - Add to budget creation
    - Disable action buttons during loading
    - _Requirements: 7.1, 7.2, 7.3_

- [x] 10. Implement success feedback system
  - [x] 10.1 Create ToastView component
    - Design toast notification with icon and message
    - Implement auto-dismiss after 2-3 seconds
    - Add slide-in/slide-out animation
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_
  
  - [x] 10.2 Add success feedback to key actions
    - Show toast after transaction created
    - Show toast after transaction updated
    - Show toast after budget created
    - _Requirements: 8.1, 8.2, 8.3_

- [x] 11. Enhance accessibility support
  - [x] 11.1 Add VoiceOver labels and hints
    - Add descriptive labels to all interactive elements
    - Add hints for complex actions
    - Test with VoiceOver enabled
    - _Requirements: 9.1, 9.2_
  
  - [x] 11.2 Verify Dynamic Type support
    - Ensure all text uses system fonts
    - Test with larger text sizes
    - Verify layouts adapt properly
    - _Requirements: 9.3_
  
  - [x] 11.3 Verify color contrast and touch targets
    - Check contrast ratios meet WCAG AA
    - Verify all touch targets are at least 44x44 points
    - Test in high contrast mode
    - _Requirements: 9.4, 9.5_

- [x] 12. Add error handling improvements
  - [x] 12.1 Implement inline validation errors
    - Show errors near problematic fields
    - Use red text with error icon
    - Clear errors when field becomes valid
    - _Requirements: 6.2_
  
  - [x] 12.2 Add error alerts for critical failures
    - Show alert for save failures
    - Show alert for not found errors
    - Provide actionable buttons (Retry, Cancel)
    - _Requirements: 1.5_

- [ ]* 13. Write unit tests for transaction editing
  - Test TransactionEditData initialization
  - Test validation logic with valid and invalid data
  - Test change detection
  - Test repository updateTransaction method
  - _Requirements: 1.3, 1.4, 1.5, 1.6_

- [ ]* 14. Write integration tests
  - Test complete transaction editing flow
  - Test navigation flow from Home to Activity
  - Test premium feature access flow
  - Test empty state to data flow
  - _Requirements: All_

- [ ] 15. Perform manual testing and polish
  - [ ] 15.1 Test transaction editing flow end-to-end
    - Create transaction, edit all fields, verify changes persist
    - Test validation with invalid data
    - Test cancel without saving
    - _Requirements: 1.1-1.8_
  
  - [ ] 15.2 Test navigation flows
    - Test all "See All" buttons
    - Verify tab switching works
    - Test state preservation
    - _Requirements: 3.1-3.4_
  
  - [ ] 15.3 Test premium features
    - Test as free user (should see upsell)
    - Test as premium user (should see full features)
    - Test upgrade flow
    - Test subscription management
    - _Requirements: 4.1-4.6_
  
  - [ ] 15.4 Test empty states and feedback
    - Verify empty states show when appropriate
    - Verify loading states during operations
    - Verify success toasts appear and dismiss
    - _Requirements: 5.1-5.4, 7.1-7.3, 8.1-8.5_
  
  - [ ] 15.5 Test accessibility
    - Test with VoiceOver
    - Test with larger text sizes
    - Test in high contrast mode
    - Verify touch target sizes
    - _Requirements: 9.1-9.5_
  
  - [ ] 15.6 Performance testing
    - Test with large datasets
    - Verify smooth scrolling
    - Check memory usage
    - Test on older devices
    - _Requirements: 10.1-10.5_

- [x] 16. Documentation and cleanup
  - [x] 16.1 Update code documentation
    - Add doc comments to new components
    - Update README if needed
    - Document any architectural decisions
  
  - [x] 16.2 Create user-facing documentation
    - Document how to edit transactions
    - Document premium features
    - Create troubleshooting guide
  
  - [x] 16.3 Final code review and cleanup
    - Remove debug code
    - Clean up commented code
    - Verify code style consistency
    - Run final diagnostics
