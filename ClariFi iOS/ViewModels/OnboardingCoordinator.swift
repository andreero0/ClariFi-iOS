//
//  OnboardingCoordinator.swift
//  ClariFi iOS
//
//  Coordinator for managing enhanced onboarding flow with account setup and quick start
//

import Foundation
import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case privacy = 1
    case features = 2
    case accountSetup = 3
    case biometric = 4
    case quickStart = 5
    case firstAction = 6
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome"
        case .privacy:
            return "Privacy"
        case .features:
            return "Features"
        case .accountSetup:
            return "Set Up Account"
        case .biometric:
            return "Security"
        case .quickStart:
            return "Quick Start"
        case .firstAction:
            return "Get Started"
        }
    }
    
    var isOptional: Bool {
        switch self {
        case .accountSetup, .quickStart:
            return true
        default:
            return false
        }
    }
}

@MainActor
class OnboardingCoordinator: ObservableObject {
    // MARK: - Published Properties
    @Published var currentStep: OnboardingStep = .welcome {
        didSet {
            guard currentStep != oldValue else { return }

            // Clear validation error when changing steps
            validationError = nil

            // Track step changes
            OnboardingAnalytics.shared.trackStepViewed(currentStep)

            // Track completion of previous step
            if oldValue.rawValue < currentStep.rawValue {
                OnboardingAnalytics.shared.trackStepCompleted(oldValue)
            }
        }
    }
    @Published var selectedProcessingMode: ProcessingMode = .localOnly
    @Published var enableBiometric: Bool = false
    @Published var createdAccounts: [AccountSetupData] = []
    @Published var selectedFirstAction: FirstActionType? {
        didSet {
            if let action = selectedFirstAction {
                OnboardingAnalytics.shared.trackFirstActionSelected(action)
            }
        }
    }
    @Published var isComplete: Bool = false
    @Published var validationError: String? = nil
    
    // MARK: - Initialization
    
    init() {
        // Start analytics tracking
        OnboardingAnalytics.shared.startOnboarding()
        OnboardingAnalytics.shared.trackStepViewed(.welcome)
    }
    
    // MARK: - Computed Properties
    var currentStepIndex: Int {
        currentStep.rawValue
    }
    
    var totalSteps: Int {
        OnboardingStep.allCases.count
    }
    
    var progress: Double {
        Double(currentStepIndex + 1) / Double(totalSteps)
    }
    
    // MARK: - Navigation Methods
    func advance() {
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            isComplete = true
            return
        }
        
        guard validate(currentStep).allowsAdvance(for: currentStep) else { return }
        setCurrentStep(nextStep)
    }
    
    func goBack() {
        if let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) {
            setCurrentStep(previousStep)
        }
    }
    
    func skipToStep(_ step: OnboardingStep) {
        requestStepChange(to: step)
    }
    
    func requestStepChange(to newStep: OnboardingStep) {
        guard newStep != currentStep else { return }

        if newStep.rawValue > currentStep.rawValue {
            let validation = validate(currentStep)
            guard validation.allowsAdvance(for: currentStep) else {
                // Set validation error message to show user feedback
                validationError = validation.message
                OnboardingAnalytics.shared.trackStepAbandoned(currentStep, reason: "validation_blocked")
                return
            }
        }

        setCurrentStep(newStep)
    }
    
    // MARK: - Validation Methods
    func canAdvance() -> Bool {
        validate(currentStep).allowsAdvance(for: currentStep)
    }
    
    func validateCurrentStep() -> ValidationResult {
        validate(currentStep)
    }
    
    private func validate(_ step: OnboardingStep) -> ValidationResult {
        switch step {
        case .welcome, .privacy, .features, .biometric:
            return .valid
        case .accountSetup:
            if createdAccounts.isEmpty {
                return .warning("No accounts added. A default 'General Account' will be created for you.")
            }
            return .valid
        case .quickStart:
            if selectedFirstAction == nil {
                return .warning("No action selected. You can choose an action later.")
            }
            return .valid
        case .firstAction:
            return .valid
        }
    }
    
    // MARK: - Account Management
    func addAccount(_ account: AccountSetupData) {
        var newAccount = account
        // First account is always default
        if createdAccounts.isEmpty {
            newAccount.isDefault = true
        }
        createdAccounts.append(newAccount)
        
        // Track account creation
        OnboardingAnalytics.shared.trackAccountCreated(
            type: account.type.rawValue,
            isDefault: newAccount.isDefault
        )
    }
    
    func removeAccount(_ account: AccountSetupData) {
        createdAccounts.removeAll { $0.id == account.id }
        
        // If we removed the default account, make the first remaining account default
        if !createdAccounts.isEmpty && !createdAccounts.contains(where: { $0.isDefault }) {
            createdAccounts[0].isDefault = true
        }
    }
    
    func setDefaultAccount(_ account: AccountSetupData) {
        for index in createdAccounts.indices {
            createdAccounts[index].isDefault = (createdAccounts[index].id == account.id)
        }
    }
    
    func createDefaultAccount() {
        let defaultAccount = AccountSetupData(
            name: "Cash",
            type: .cash,
            initialBalance: 0,
            isDefault: true
        )
        createdAccounts = [defaultAccount]
    }
    
    // MARK: - First Action Management
    func selectFirstAction(_ action: FirstActionType) {
        selectedFirstAction = action
    }
    
    // MARK: - Reset
    func reset() {
        setCurrentStep(.welcome)
        selectedProcessingMode = .localOnly
        enableBiometric = false
        createdAccounts = []
        selectedFirstAction = nil
        isComplete = false
    }
    
    // MARK: - Private Helpers
    private func setCurrentStep(_ step: OnboardingStep) {
        guard currentStep != step else { return }
        currentStep = step
    }
}

// MARK: - Supporting Types
enum ValidationResult {
    case valid
    case warning(String)
    case error(String)
    
    var message: String? {
        switch self {
        case .valid:
            return nil
        case .warning(let message), .error(let message):
            return message
        }
    }
    
    func allowsAdvance(for step: OnboardingStep) -> Bool {
        switch self {
        case .valid:
            return true
        case .warning:
            return step.isOptional
        case .error:
            return false
        }
    }
}

enum FirstActionType: String, CaseIterable {
    case uploadStatement
    case manualEntry
    case createBudget
    
    var title: String {
        switch self {
        case .uploadStatement:
            return "Upload a Statement"
        case .manualEntry:
            return "Add Transaction Manually"
        case .createBudget:
            return "Create Your First Budget"
        }
    }
    
    var description: String {
        switch self {
        case .uploadStatement:
            return "Scan your bank statement to import transactions automatically"
        case .manualEntry:
            return "Enter your first transaction to start tracking"
        case .createBudget:
            return "Set up your budget first, then add transactions"
        }
    }
    
    var icon: String {
        switch self {
        case .uploadStatement:
            return "doc.text.viewfinder"
        case .manualEntry:
            return "plus.circle.fill"
        case .createBudget:
            return "target"
        }
    }
}
