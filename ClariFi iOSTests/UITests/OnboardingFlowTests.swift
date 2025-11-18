//
//  OnboardingFlowTests.swift
//  ClariFi iOSTests
//
//  UI tests for the enhanced onboarding flow including account setup,
//  quick start selection, and first action guidance
//

import XCTest
import SwiftUI
import CoreData
@testable import ClariFi_iOS

@MainActor
class OnboardingFlowTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var coordinator: OnboardingCoordinator!
    
    override func setUp() async throws {
        try await super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
        coordinator = OnboardingCoordinator()
    }
    
    override func tearDown() async throws {
        coordinator = nil
        persistenceController = nil
        viewContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Complete Onboarding Flow Tests
    
    func testCompleteOnboardingFlowWithAllSteps() async throws {
        // Given: Fresh onboarding coordinator
        XCTAssertEqual(coordinator.currentStep, .welcome)
        XCTAssertFalse(coordinator.isComplete)
        
        // Step 1: Welcome
        XCTAssertTrue(coordinator.canAdvance())
        coordinator.advance()
        XCTAssertEqual(coordinator.currentStep, .privacy)
        
        // Step 2: Privacy
        coordinator.selectedProcessingMode = .localOnly
        XCTAssertTrue(coordinator.canAdvance())
        coordinator.advance()
        XCTAssertEqual(coordinator.currentStep, .features)
        
        // Step 3: Features
        XCTAssertTrue(coordinator.canAdvance())
        coordinator.advance()
        XCTAssertEqual(coordinator.currentStep, .accountSetup)
        
        // Step 4: Account Setup
        let account = AccountSetupData(
            name: "Test Checking",
            type: .checking,
            initialBalance: 1000.00
        )
        coordinator.addAccount(account)
        XCTAssertEqual(coordinator.createdAccounts.count, 1)
        XCTAssertTrue(coordinator.canAdvance())
        coordinator.advance()
        XCTAssertEqual(coordinator.currentStep, .biometric)
        
        // Step 5: Biometric
        coordinator.enableBiometric = true
        XCTAssertTrue(coordinator.canAdvance())
        coordinator.advance()
        XCTAssertEqual(coordinator.currentStep, .quickStart)
        
        // Step 6: Quick Start
        coordinator.selectFirstAction(.uploadStatement)
        XCTAssertEqual(coordinator.selectedFirstAction, .uploadStatement)
        XCTAssertTrue(coordinator.canAdvance())
        coordinator.advance()
        XCTAssertEqual(coordinator.currentStep, .firstAction)
        
        // Step 7: First Action (Final)
        XCTAssertTrue(coordinator.canAdvance())
        coordinator.advance()
        
        // Then: Onboarding should be complete
        XCTAssertTrue(coordinator.isComplete)
    }
    
    func testCompleteOnboardingFlowWithSkips() async throws {
        // Given: Fresh onboarding coordinator
        XCTAssertEqual(coordinator.currentStep, .welcome)
        
        // Navigate through required steps
        coordinator.advance() // Welcome -> Privacy
        coordinator.advance() // Privacy -> Features
        coordinator.advance() // Features -> Account Setup
        
        // Step 4: Skip Account Setup (creates default account)
        XCTAssertEqual(coordinator.currentStep, .accountSetup)
        coordinator.createDefaultAccount()
        XCTAssertEqual(coordinator.createdAccounts.count, 1)
        XCTAssertEqual(coordinator.createdAccounts.first?.name, "Cash")
        XCTAssertTrue(coordinator.createdAccounts.first?.isDefault ?? false)
        coordinator.advance()
        
        // Step 5: Biometric (skip by not enabling)
        XCTAssertEqual(coordinator.currentStep, .biometric)
        XCTAssertFalse(coordinator.enableBiometric)
        coordinator.advance()
        
        // Step 6: Skip Quick Start
        XCTAssertEqual(coordinator.currentStep, .quickStart)
        XCTAssertNil(coordinator.selectedFirstAction)
        coordinator.advance() // Can advance even without selection
        
        // Step 7: Complete
        XCTAssertEqual(coordinator.currentStep, .firstAction)
        coordinator.advance()
        
        // Then: Onboarding should be complete with defaults
        XCTAssertTrue(coordinator.isComplete)
        XCTAssertEqual(coordinator.createdAccounts.count, 1)
        XCTAssertNil(coordinator.selectedFirstAction)
    }
    
    func testOnboardingProgressTracking() {
        // Given: Fresh coordinator
        XCTAssertEqual(coordinator.currentStepIndex, 0)
        XCTAssertEqual(coordinator.totalSteps, 7)
        XCTAssertEqual(coordinator.progress, 1.0 / 7.0, accuracy: 0.01)
        
        // When: Advancing through steps
        coordinator.advance()
        XCTAssertEqual(coordinator.currentStepIndex, 1)
        XCTAssertEqual(coordinator.progress, 2.0 / 7.0, accuracy: 0.01)
        
        coordinator.advance()
        XCTAssertEqual(coordinator.currentStepIndex, 2)
        XCTAssertEqual(coordinator.progress, 3.0 / 7.0, accuracy: 0.01)
        
        // Then: Progress should increase linearly
        for _ in 0..<4 {
            coordinator.advance()
        }
        XCTAssertEqual(coordinator.currentStepIndex, 6)
        XCTAssertEqual(coordinator.progress, 1.0, accuracy: 0.01)
    }
    
    // MARK: - Account Creation Step Tests
    
    func testAccountCreationWithValidData() {
        // Given: Valid account data
        let account = AccountSetupData(
            name: "My Checking",
            type: .checking,
            initialBalance: 500.00
        )
        
        // When: Adding account
        coordinator.addAccount(account)
        
        // Then: Account should be added and marked as default (first account)
        XCTAssertEqual(coordinator.createdAccounts.count, 1)
        XCTAssertTrue(coordinator.createdAccounts.first?.isDefault ?? false)
        XCTAssertEqual(coordinator.createdAccounts.first?.name, "My Checking")
    }
    
    func testMultipleAccountCreation() {
        // Given: Multiple accounts
        let checking = AccountSetupData(name: "Checking", type: .checking, initialBalance: 1000)
        let savings = AccountSetupData(name: "Savings", type: .savings, initialBalance: 5000)
        let credit = AccountSetupData(name: "Credit Card", type: .credit, initialBalance: -200)
        
        // When: Adding accounts
        coordinator.addAccount(checking)
        coordinator.addAccount(savings)
        coordinator.addAccount(credit)
        
        // Then: All accounts should be added
        XCTAssertEqual(coordinator.createdAccounts.count, 3)
        
        // First account should be default
        XCTAssertTrue(coordinator.createdAccounts[0].isDefault)
        XCTAssertFalse(coordinator.createdAccounts[1].isDefault)
        XCTAssertFalse(coordinator.createdAccounts[2].isDefault)
    }
    
    func testAccountRemoval() {
        // Given: Multiple accounts
        let account1 = AccountSetupData(name: "Account 1", type: .checking, initialBalance: 100)
        let account2 = AccountSetupData(name: "Account 2", type: .savings, initialBalance: 200)
        coordinator.addAccount(account1)
        coordinator.addAccount(account2)
        XCTAssertEqual(coordinator.createdAccounts.count, 2)
        
        // When: Removing first account (default)
        coordinator.removeAccount(account1)
        
        // Then: Second account should become default
        XCTAssertEqual(coordinator.createdAccounts.count, 1)
        XCTAssertTrue(coordinator.createdAccounts.first?.isDefault ?? false)
        XCTAssertEqual(coordinator.createdAccounts.first?.name, "Account 2")
    }
    
    func testSetDefaultAccount() {
        // Given: Multiple accounts
        let account1 = AccountSetupData(name: "Account 1", type: .checking, initialBalance: 100)
        let account2 = AccountSetupData(name: "Account 2", type: .savings, initialBalance: 200)
        coordinator.addAccount(account1)
        coordinator.addAccount(account2)
        
        // When: Setting second account as default
        coordinator.setDefaultAccount(account2)
        
        // Then: Only second account should be default
        XCTAssertFalse(coordinator.createdAccounts[0].isDefault)
        XCTAssertTrue(coordinator.createdAccounts[1].isDefault)
    }
    
    func testDefaultAccountCreation() {
        // Given: No accounts
        XCTAssertTrue(coordinator.createdAccounts.isEmpty)
        
        // When: Creating default account
        coordinator.createDefaultAccount()
        
        // Then: Default cash account should be created
        XCTAssertEqual(coordinator.createdAccounts.count, 1)
        XCTAssertEqual(coordinator.createdAccounts.first?.name, "Cash")
        XCTAssertEqual(coordinator.createdAccounts.first?.type, .cash)
        XCTAssertEqual(coordinator.createdAccounts.first?.initialBalance, 0)
        XCTAssertTrue(coordinator.createdAccounts.first?.isDefault ?? false)
    }
    
    func testAccountSetupValidation() {
        // Given: Account setup step
        coordinator.skipToStep(.accountSetup)
        
        // When: No accounts created
        let validationResult = coordinator.validateCurrentStep()
        
        // Then: Should show warning
        switch validationResult {
        case .warning(let message):
            XCTAssertTrue(message.contains("default"))
        default:
            XCTFail("Expected warning for no accounts")
        }
        
        // When: Account is added
        coordinator.addAccount(AccountSetupData(name: "Test", type: .checking, initialBalance: 0))
        let validationResult2 = coordinator.validateCurrentStep()
        
        // Then: Should be valid
        XCTAssertTrue(validationResult2.isValid)
    }
    
    // MARK: - Quick Start Selection Tests
    
    func testQuickStartActionSelection() {
        // Given: Quick start step
        coordinator.skipToStep(.quickStart)
        XCTAssertNil(coordinator.selectedFirstAction)
        
        // When: Selecting upload statement
        coordinator.selectFirstAction(.uploadStatement)
        
        // Then: Action should be selected
        XCTAssertEqual(coordinator.selectedFirstAction, .uploadStatement)
        XCTAssertTrue(coordinator.canAdvance())
    }
    
    func testQuickStartActionChange() {
        // Given: Action already selected
        coordinator.skipToStep(.quickStart)
        coordinator.selectFirstAction(.uploadStatement)
        XCTAssertEqual(coordinator.selectedFirstAction, .uploadStatement)
        
        // When: Changing selection
        coordinator.selectFirstAction(.manualEntry)
        
        // Then: Selection should update
        XCTAssertEqual(coordinator.selectedFirstAction, .manualEntry)
    }
    
    func testQuickStartAllActionTypes() {
        // Test all action types can be selected
        let actions: [FirstActionType] = [.uploadStatement, .manualEntry, .createBudget]
        
        for action in actions {
            coordinator.selectFirstAction(action)
            XCTAssertEqual(coordinator.selectedFirstAction, action)
            
            // Verify action properties
            XCTAssertFalse(action.title.isEmpty)
            XCTAssertFalse(action.description.isEmpty)
            XCTAssertFalse(action.icon.isEmpty)
        }
    }
    
    func testQuickStartValidation() {
        // Given: Quick start step
        coordinator.skipToStep(.quickStart)
        
        // When: No action selected
        let validationResult = coordinator.validateCurrentStep()
        
        // Then: Should show warning
        switch validationResult {
        case .warning(let message):
            XCTAssertTrue(message.contains("later"))
        default:
            XCTFail("Expected warning for no action selected")
        }
        
        // When: Action is selected
        coordinator.selectFirstAction(.uploadStatement)
        let validationResult2 = coordinator.validateCurrentStep()
        
        // Then: Should be valid
        XCTAssertTrue(validationResult2.isValid)
    }
    
    func testQuickStartSkipFunctionality() {
        // Given: Quick start step with no selection
        coordinator.skipToStep(.quickStart)
        XCTAssertNil(coordinator.selectedFirstAction)
        
        // When: Advancing without selection (skip)
        XCTAssertTrue(coordinator.canAdvance()) // Can advance even without selection
        coordinator.advance()
        
        // Then: Should move to next step
        XCTAssertEqual(coordinator.currentStep, .firstAction)
        XCTAssertNil(coordinator.selectedFirstAction)
    }
    
    // MARK: - Skip Functionality Tests
    
    func testSkipAccountSetup() {
        // Given: Account setup step
        coordinator.skipToStep(.accountSetup)
        XCTAssertTrue(coordinator.createdAccounts.isEmpty)
        
        // When: Skipping (creating default account)
        coordinator.createDefaultAccount()
        
        // Then: Default account should be created
        XCTAssertEqual(coordinator.createdAccounts.count, 1)
        XCTAssertEqual(coordinator.createdAccounts.first?.name, "Cash")
        XCTAssertTrue(coordinator.canAdvance())
    }
    
    func testSkipBiometricSetup() {
        // Given: Biometric step
        coordinator.skipToStep(.biometric)
        XCTAssertFalse(coordinator.enableBiometric)
        
        // When: Advancing without enabling biometric
        XCTAssertTrue(coordinator.canAdvance())
        coordinator.advance()
        
        // Then: Should move to next step with biometric disabled
        XCTAssertEqual(coordinator.currentStep, .quickStart)
        XCTAssertFalse(coordinator.enableBiometric)
    }
    
    func testSkipQuickStart() {
        // Given: Quick start step
        coordinator.skipToStep(.quickStart)
        XCTAssertNil(coordinator.selectedFirstAction)
        
        // When: Advancing without selection
        XCTAssertTrue(coordinator.canAdvance())
        coordinator.advance()
        
        // Then: Should move to next step without action
        XCTAssertEqual(coordinator.currentStep, .firstAction)
        XCTAssertNil(coordinator.selectedFirstAction)
    }
    
    func testOptionalStepsIdentification() {
        // Verify which steps are optional
        XCTAssertFalse(OnboardingStep.welcome.isOptional)
        XCTAssertFalse(OnboardingStep.privacy.isOptional)
        XCTAssertFalse(OnboardingStep.features.isOptional)
        XCTAssertTrue(OnboardingStep.accountSetup.isOptional)
        XCTAssertFalse(OnboardingStep.biometric.isOptional)
        XCTAssertTrue(OnboardingStep.quickStart.isOptional)
        XCTAssertFalse(OnboardingStep.firstAction.isOptional)
    }
    
    // MARK: - Back Navigation Tests
    
    func testBackNavigationFromPrivacy() {
        // Given: On privacy step
        coordinator.advance() // Welcome -> Privacy
        XCTAssertEqual(coordinator.currentStep, .privacy)
        
        // When: Going back
        coordinator.goBack()
        
        // Then: Should return to welcome
        XCTAssertEqual(coordinator.currentStep, .welcome)
    }
    
    func testBackNavigationFromAccountSetup() {
        // Given: On account setup with data
        coordinator.skipToStep(.accountSetup)
        coordinator.addAccount(AccountSetupData(name: "Test", type: .checking, initialBalance: 100))
        XCTAssertEqual(coordinator.createdAccounts.count, 1)
        
        // When: Going back
        coordinator.goBack()
        
        // Then: Should return to features and preserve data
        XCTAssertEqual(coordinator.currentStep, .features)
        XCTAssertEqual(coordinator.createdAccounts.count, 1) // Data preserved
    }
    
    func testBackNavigationFromQuickStart() {
        // Given: On quick start with selection
        coordinator.skipToStep(.quickStart)
        coordinator.selectFirstAction(.uploadStatement)
        
        // When: Going back
        coordinator.goBack()
        
        // Then: Should return to biometric and preserve selection
        XCTAssertEqual(coordinator.currentStep, .biometric)
        XCTAssertEqual(coordinator.selectedFirstAction, .uploadStatement) // Selection preserved
    }
    
    func testBackNavigationFromFirstStep() {
        // Given: On welcome (first step)
        XCTAssertEqual(coordinator.currentStep, .welcome)
        
        // When: Attempting to go back
        coordinator.goBack()
        
        // Then: Should stay on welcome
        XCTAssertEqual(coordinator.currentStep, .welcome)
    }
    
    func testBackNavigationPreservesState() {
        // Given: Complete setup with data
        coordinator.selectedProcessingMode = .cloudOptIn
        coordinator.enableBiometric = true
        coordinator.addAccount(AccountSetupData(name: "Test", type: .checking, initialBalance: 500))
        coordinator.selectFirstAction(.manualEntry)
        coordinator.skipToStep(.firstAction)
        
        // When: Going back multiple steps
        coordinator.goBack() // firstAction -> quickStart
        coordinator.goBack() // quickStart -> biometric
        coordinator.goBack() // biometric -> accountSetup
        
        // Then: All state should be preserved
        XCTAssertEqual(coordinator.currentStep, .accountSetup)
        XCTAssertEqual(coordinator.selectedProcessingMode, .cloudOptIn)
        XCTAssertTrue(coordinator.enableBiometric)
        XCTAssertEqual(coordinator.createdAccounts.count, 1)
        XCTAssertEqual(coordinator.selectedFirstAction, .manualEntry)
    }
    
    // MARK: - View Integration Tests
    
    func testOnboardingViewCreation() {
        // Given: Onboarding view
        let isPresented = Binding.constant(true)
        let onboardingView = OnboardingView(isPresented: isPresented)
            .environment(\.managedObjectContext, viewContext)
        
        // Then: View should be created
        XCTAssertNotNil(onboardingView)
    }
    
    func testAccountSetupStepViewCreation() {
        // Given: Account setup step view
        let view = AccountSetupStepView(coordinator: coordinator)
        
        // Then: View should be created
        XCTAssertNotNil(view)
    }
    
    func testQuickStartViewCreation() {
        // Given: Quick start view
        let view = QuickStartView(coordinator: coordinator)
        
        // Then: View should be created
        XCTAssertNotNil(view)
    }
    
    func testFirstActionGuidanceViewCreation() {
        // Given: First action guidance view
        let isPresented = Binding.constant(true)
        let view = FirstActionGuidanceView(
            coordinator: coordinator,
            isOnboardingPresented: isPresented
        )
        
        // Then: View should be created
        XCTAssertNotNil(view)
    }
    
    func testOnboardingSuccessViewCreation() {
        // Given: Success view
        let view = OnboardingSuccessView(
            coordinator: coordinator,
            onGetStarted: {}
        )
        
        // Then: View should be created
        XCTAssertNotNil(view)
    }
    
    // MARK: - State Reset Tests
    
    func testCoordinatorReset() {
        // Given: Coordinator with data
        coordinator.skipToStep(.quickStart)
        coordinator.selectedProcessingMode = .cloudOptIn
        coordinator.enableBiometric = true
        coordinator.addAccount(AccountSetupData(name: "Test", type: .checking, initialBalance: 100))
        coordinator.selectFirstAction(.uploadStatement)
        coordinator.isComplete = true
        
        // When: Resetting
        coordinator.reset()
        
        // Then: All state should be reset
        XCTAssertEqual(coordinator.currentStep, .welcome)
        XCTAssertEqual(coordinator.selectedProcessingMode, .localOnly)
        XCTAssertFalse(coordinator.enableBiometric)
        XCTAssertTrue(coordinator.createdAccounts.isEmpty)
        XCTAssertNil(coordinator.selectedFirstAction)
        XCTAssertFalse(coordinator.isComplete)
    }
    
    // MARK: - Validation Tests
    
    func testValidationForAllSteps() {
        // Test validation for each step
        for step in OnboardingStep.allCases {
            coordinator.skipToStep(step)
            let result = coordinator.validateCurrentStep()
            
            // All steps should have some validation result
            XCTAssertNotNil(result)
            
            // Required steps should be valid by default
            if !step.isOptional {
                // Most required steps are valid by default
                switch step {
                case .welcome, .privacy, .features, .biometric, .firstAction:
                    XCTAssertTrue(result.isValid)
                default:
                    break
                }
            }
        }
    }
    
    func testCanAdvanceLogic() {
        // Test canAdvance for each step
        
        // Welcome - always can advance
        coordinator.skipToStep(.welcome)
        XCTAssertTrue(coordinator.canAdvance())
        
        // Privacy - always can advance (has default)
        coordinator.skipToStep(.privacy)
        XCTAssertTrue(coordinator.canAdvance())
        
        // Features - always can advance
        coordinator.skipToStep(.features)
        XCTAssertTrue(coordinator.canAdvance())
        
        // Account Setup - can advance if accounts exist OR is optional
        coordinator.skipToStep(.accountSetup)
        XCTAssertTrue(coordinator.canAdvance()) // Optional, so can advance
        
        // Biometric - always can advance
        coordinator.skipToStep(.biometric)
        XCTAssertTrue(coordinator.canAdvance())
        
        // Quick Start - can advance if action selected OR is optional
        coordinator.skipToStep(.quickStart)
        XCTAssertTrue(coordinator.canAdvance()) // Optional, so can advance
        
        // First Action - always can advance
        coordinator.skipToStep(.firstAction)
        XCTAssertTrue(coordinator.canAdvance())
    }
    
    // MARK: - Edge Cases
    
    func testEmptyAccountName() {
        // Given: Account with empty name
        let account = AccountSetupData(
            name: "",
            type: .checking,
            initialBalance: 100
        )
        
        // When: Validating
        let error = account.validate()
        
        // Then: Should have validation error
        XCTAssertNotNil(error)
        XCTAssertEqual(error, .emptyName)
    }
    
    func testNegativeBalanceForNonCreditAccount() {
        // Given: Checking account with negative balance
        let account = AccountSetupData(
            name: "Test",
            type: .checking,
            initialBalance: -100
        )
        
        // When: Validating
        let error = account.validate()
        
        // Then: Should have validation error
        XCTAssertNotNil(error)
        XCTAssertEqual(error, .negativeBalance)
    }
    
    func testNegativeBalanceForCreditAccount() {
        // Given: Credit account with negative balance
        let account = AccountSetupData(
            name: "Credit Card",
            type: .credit,
            initialBalance: -500
        )
        
        // When: Validating
        let error = account.validate()
        
        // Then: Should be valid (credit cards can have negative balance)
        XCTAssertNil(error)
        XCTAssertTrue(account.isValid)
    }
    
    func testAccountNameTooLong() {
        // Given: Account with very long name
        let longName = String(repeating: "a", count: 51)
        let account = AccountSetupData(
            name: longName,
            type: .checking,
            initialBalance: 100
        )
        
        // When: Validating
        let error = account.validate()
        
        // Then: Should have validation error
        XCTAssertNotNil(error)
        XCTAssertEqual(error, .nameTooLong)
    }
    
    func testAccountNameTooShort() {
        // Given: Account with single character name
        let account = AccountSetupData(
            name: "A",
            type: .checking,
            initialBalance: 100
        )
        
        // When: Validating
        let error = account.validate()
        
        // Then: Should have validation error
        XCTAssertNotNil(error)
        XCTAssertEqual(error, .nameTooShort)
    }
    
    func testMultipleDefaultAccounts() {
        // Given: Attempting to add multiple default accounts
        let account1 = AccountSetupData(name: "Account 1", type: .checking, initialBalance: 100, isDefault: true)
        let account2 = AccountSetupData(name: "Account 2", type: .savings, initialBalance: 200, isDefault: true)
        
        coordinator.addAccount(account1)
        coordinator.addAccount(account2)
        
        // Then: Only first account should remain default
        XCTAssertTrue(coordinator.createdAccounts[0].isDefault)
        XCTAssertFalse(coordinator.createdAccounts[1].isDefault)
    }
    
    func testSkipToInvalidStep() {
        // Given: Current step
        let currentStep = coordinator.currentStep
        
        // When: Attempting to skip to same step
        coordinator.skipToStep(currentStep)
        
        // Then: Should remain on same step
        XCTAssertEqual(coordinator.currentStep, currentStep)
    }
    
    // MARK: - Accessibility Tests
    
    func testOnboardingStepTitles() {
        // Verify all steps have titles
        for step in OnboardingStep.allCases {
            XCTAssertFalse(step.title.isEmpty, "Step \(step) should have a title")
        }
    }
    
    func testAccountTypeAccessibility() {
        // Verify all account types have icons and descriptions
        for type in AccountType.allCases {
            XCTAssertFalse(type.icon.isEmpty, "Account type \(type) should have an icon")
            XCTAssertFalse(type.description.isEmpty, "Account type \(type) should have a description")
        }
    }
    
    func testFirstActionTypeAccessibility() {
        // Verify all action types have required properties
        for action in FirstActionType.allCases {
            XCTAssertFalse(action.title.isEmpty, "Action \(action) should have a title")
            XCTAssertFalse(action.description.isEmpty, "Action \(action) should have a description")
            XCTAssertFalse(action.icon.isEmpty, "Action \(action) should have an icon")
        }
    }
}
