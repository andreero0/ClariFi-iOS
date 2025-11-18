//
//  OnboardingStateManager.swift
//  ClariFi iOS
//
//  Created to fix race condition in first action execution after onboarding
//  Provides deterministic state management for post-onboarding actions
//

import Foundation
import SwiftUI

/// Manages the state of pending actions after onboarding completes
/// This ensures first actions execute reliably without race conditions
@MainActor
class OnboardingStateManager: ObservableObject {
    @Published var pendingFirstAction: FirstActionType?
    @Published var shouldExecuteFirstAction: Bool = false

    /// Set the pending first action to be executed after onboarding
    /// - Parameter action: The first action selected by the user during onboarding
    func setPendingFirstAction(_ action: FirstActionType?) {
        self.pendingFirstAction = action
        self.shouldExecuteFirstAction = action != nil
    }

    /// Clear the pending first action after it has been executed
    func clearFirstAction() {
        self.pendingFirstAction = nil
        self.shouldExecuteFirstAction = false
    }

    /// Check if there is a pending first action
    var hasPendingAction: Bool {
        return pendingFirstAction != nil && shouldExecuteFirstAction
    }
}
