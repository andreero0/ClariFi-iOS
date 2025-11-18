//
//  OnboardingViewModel.swift
//  ClariFi iOS
//
//  ViewModel for managing onboarding flow state and completion
//

import Foundation
import SwiftUI
import CoreData

@MainActor
class OnboardingViewModel: BaseViewModel {
    private let userDefaults = UserDefaults.standard
    private let onboardingCompletedKey = "com.clarifi.onboarding.completed"
    private let onboardingVersionKey = "com.clarifi.onboarding.version"
    private let onboardingAccountsKey = "com.clarifi.onboarding.accounts"
    private let onboardingFirstActionKey = "com.clarifi.onboarding.firstAction"
    static let currentOnboardingVersion = 2  // Incremented for new onboarding flow
    private let securityAudit: SecurityAuditService
    
    @Published var isCreatingAccounts = false
    @Published var accountCreationProgress: String = ""
    
    init(securityAudit: SecurityAuditService) {
        self.securityAudit = securityAudit
        super.init()
    }
    
    // Check if user has completed onboarding
    static func hasCompletedOnboarding() -> Bool {
        return UserDefaults.standard.bool(forKey: "com.clarifi.onboarding.completed")
    }
    
    // Complete onboarding and save user preferences
    func completeOnboarding(context: NSManagedObjectContext, coordinator: OnboardingCoordinator) async {
        await MainActor.run {
            isCreatingAccounts = true
            accountCreationProgress = "Saving preferences..."
        }
        
        // Save processing mode preference
        let privacyManager = PrivacyManager(viewContext: context)
        privacyManager.processingMode = coordinator.selectedProcessingMode
        
        // Small delay for smooth UX
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Save biometric preference
        if coordinator.enableBiometric {
            await MainActor.run {
                accountCreationProgress = "Setting up security..."
            }
            let biometricService = BiometricAuthService.shared
            biometricService.isBiometricEnabled = true
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
        
        // Create accounts in Core Data
        if !coordinator.createdAccounts.isEmpty {
            await MainActor.run {
                accountCreationProgress = "Creating accounts..."
            }
            await createAccounts(coordinator.createdAccounts, context: context)
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
        
        // Save first action preference
        if let firstAction = coordinator.selectedFirstAction {
            await MainActor.run {
                accountCreationProgress = "Finalizing setup..."
            }
            userDefaults.set(firstAction.rawValue, forKey: onboardingFirstActionKey)
        } else {
            userDefaults.removeObject(forKey: onboardingFirstActionKey)
        }
        
        // Mark onboarding as completed
        userDefaults.set(true, forKey: onboardingCompletedKey)
        userDefaults.set(Self.currentOnboardingVersion, forKey: onboardingVersionKey)
        userDefaults.synchronize()
        
        // Complete analytics tracking
        OnboardingAnalytics.shared.completeOnboarding(
            accountsCreated: coordinator.createdAccounts.count,
            firstAction: coordinator.selectedFirstAction,
            biometricEnabled: coordinator.enableBiometric,
            processingMode: coordinator.selectedProcessingMode.rawValue
        )
        
        // Log onboarding completion for security audit
        securityAudit.logEvent(SecurityEvent(
            type: .dataAccess,
            severity: .info,
            description: "User completed onboarding",
            metadata: [
                "processingMode": coordinator.selectedProcessingMode.rawValue,
                "biometricEnabled": String(coordinator.enableBiometric),
                "accountsCreated": String(coordinator.createdAccounts.count),
                "firstAction": coordinator.selectedFirstAction?.rawValue ?? "none",
                "version": String(Self.currentOnboardingVersion)
            ]
        ))
        
        var notificationInfo: [String: Any] = [
            "processingMode": coordinator.selectedProcessingMode.rawValue,
            "biometricEnabled": coordinator.enableBiometric,
            "accountsCreated": coordinator.createdAccounts.count
        ]
        if let firstAction = coordinator.selectedFirstAction?.rawValue {
            notificationInfo["firstAction"] = firstAction
        }
        
        NotificationCenter.default.post(
            name: .onboardingCompleted,
            object: nil,
            userInfo: notificationInfo
        )
        
        await MainActor.run {
            isCreatingAccounts = false
        }
    }
    
    // Create accounts from onboarding data
    private func createAccounts(_ accountsData: [AccountSetupData], context: NSManagedObjectContext) async {
        guard !accountsData.isEmpty else { return }
        
        await context.perform {
            for accountData in accountsData {
                let account = Account(context: context)
                account.id = accountData.id
                account.name = accountData.displayName
                account.type = accountData.type.rawValue
                // Note: balance, createdDate, lastModifiedDate properties not available in Account entity
                // account.balance = accountData.initialBalance as NSDecimalNumber
                account.isDefault = accountData.isDefault
                // account.createdDate = Date()
                // account.lastModifiedDate = Date()
            }
            
            do {
                try context.save()
            } catch {
                print("Error saving accounts: \(error)")
            }
        }
    }
    
    // Get the user's selected first action
    static func getFirstAction() -> FirstActionType? {
        guard let rawValue = UserDefaults.standard.string(forKey: "com.clarifi.onboarding.firstAction") else {
            return nil
        }
        return FirstActionType(rawValue: rawValue)
    }
    
    // Reset onboarding (for testing or re-onboarding)
    static func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "com.clarifi.onboarding.completed")
        UserDefaults.standard.removeObject(forKey: "com.clarifi.onboarding.version")
        UserDefaults.standard.removeObject(forKey: "com.clarifi.onboarding.firstAction")
        UserDefaults.standard.synchronize()
    }
    
    // Check if onboarding needs to be shown again (version upgrade)
    static func shouldShowOnboarding() -> Bool {
        let completed = UserDefaults.standard.bool(forKey: "com.clarifi.onboarding.completed")
        let version = UserDefaults.standard.integer(forKey: "com.clarifi.onboarding.version")
        
        // Show onboarding if never completed or if version is outdated
        return !completed || version < Self.currentOnboardingVersion
    }
}

extension Notification.Name {
    static let onboardingCompleted = Notification.Name("com.clarifi.onboarding.completedNotification")
}
