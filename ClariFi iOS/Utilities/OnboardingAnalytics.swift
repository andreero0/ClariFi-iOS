//
//  OnboardingAnalytics.swift
//  ClariFi iOS
//
//  Analytics tracking for onboarding flow
//

import Foundation

/// Helper class for tracking onboarding analytics
class OnboardingAnalytics {
    
    // MARK: - Singleton
    
    static let shared = OnboardingAnalytics()
    
    private init() {}
    
    // MARK: - Properties
    
    private var stepStartTimes: [String: Date] = [:]
    private var stepCompletionTimes: [String: TimeInterval] = [:]
    private var onboardingStartTime: Date?
    private var abandonmentPoints: [String] = []
    
    // MARK: - Onboarding Flow Tracking
    
    /// Start tracking onboarding flow
    func startOnboarding() {
        onboardingStartTime = Date()
        stepStartTimes.removeAll()
        stepCompletionTimes.removeAll()
        abandonmentPoints.removeAll()
        
        Analytics.track(.onboardingStarted, properties: [
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ])
    }
    
    /// Track when a step is viewed
    func trackStepViewed(_ step: OnboardingStep) {
        let stepName = step.analyticsName
        stepStartTimes[stepName] = Date()
        
        Analytics.track(.onboardingStepViewed, properties: [
            "step_name": stepName,
            "step_number": step.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ])
    }
    
    /// Track when a step is completed
    func trackStepCompleted(_ step: OnboardingStep) {
        let stepName = step.analyticsName
        
        // Calculate time spent on step
        if let startTime = stepStartTimes[stepName] {
            let duration = Date().timeIntervalSince(startTime)
            stepCompletionTimes[stepName] = duration
            
            Analytics.track(.onboardingStepCompleted, properties: [
                "step_name": stepName,
                "step_number": step.rawValue,
                "duration_seconds": duration,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ])
        }
    }
    
    /// Track when a step is abandoned (user goes back or exits)
    func trackStepAbandoned(_ step: OnboardingStep, reason: String? = nil) {
        let stepName = step.analyticsName
        abandonmentPoints.append(stepName)
        
        var properties: [String: Any] = [
            "step_name": stepName,
            "step_number": step.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        if let reason = reason {
            properties["reason"] = reason
        }
        
        if let startTime = stepStartTimes[stepName] {
            let duration = Date().timeIntervalSince(startTime)
            properties["time_before_abandonment"] = duration
        }
        
        Analytics.track(.onboardingStepAbandoned, properties: properties)
    }
    
    /// Track account creation during onboarding
    func trackAccountCreated(type: String, isDefault: Bool) {
        Analytics.track(.onboardingAccountCreated, properties: [
            "account_type": type,
            "is_default": isDefault,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ])
    }
    
    /// Track first action selection
    func trackFirstActionSelected(_ action: FirstActionType) {
        Analytics.track(.onboardingFirstActionSelected, properties: [
            "action": action.rawValue,
            "action_name": action.analyticsName,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ])
    }
    
    /// Complete onboarding tracking
    func completeOnboarding(
        accountsCreated: Int,
        firstAction: FirstActionType?,
        biometricEnabled: Bool,
        processingMode: String
    ) {
        guard let startTime = onboardingStartTime else { return }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        
        var properties: [String: Any] = [
            "total_duration_seconds": totalDuration,
            "accounts_created": accountsCreated,
            "biometric_enabled": biometricEnabled,
            "processing_mode": processingMode,
            "steps_completed": stepCompletionTimes.count,
            "abandonment_count": abandonmentPoints.count,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        if let firstAction = firstAction {
            properties["first_action"] = firstAction.rawValue
        }
        
        // Add step completion times
        for (step, duration) in stepCompletionTimes {
            properties["step_\(step)_duration"] = duration
        }
        
        // Add abandonment points if any
        if !abandonmentPoints.isEmpty {
            properties["abandonment_points"] = abandonmentPoints.joined(separator: ",")
        }
        
        Analytics.track(.onboardingCompleted, properties: properties)
        
        // Print summary for debugging
        printOnboardingSummary(totalDuration: totalDuration)
        
        // Reset tracking
        onboardingStartTime = nil
    }
    
    // MARK: - Statistics
    
    /// Get completion rate for a specific step
    func getStepCompletionRate(_ step: OnboardingStep) -> Double? {
        // This would typically query from a backend or local storage
        // For now, return nil as we don't have historical data
        return nil
    }
    
    /// Get average time spent on a step
    func getAverageStepDuration(_ step: OnboardingStep) -> TimeInterval? {
        // This would typically query from a backend or local storage
        return stepCompletionTimes[step.analyticsName]
    }
    
    /// Get first action distribution
    func getFirstActionDistribution() -> [FirstActionType: Int] {
        // This would typically query from a backend or local storage
        // For now, return empty as we don't have historical data
        return [:]
    }
    
    /// Get abandonment points
    func getAbandonmentPoints() -> [String] {
        return abandonmentPoints
    }
    
    // MARK: - Debugging
    
    private func printOnboardingSummary(totalDuration: TimeInterval) {
        print("\nOnboarding Analytics Summary")
        print("=" * 60)
        print("Total Duration: \(String(format: "%.1f", totalDuration))s")
        print("Steps Completed: \(stepCompletionTimes.count)")
        print("Abandonment Count: \(abandonmentPoints.count)")
        print("\nStep Durations:")
        for (step, duration) in stepCompletionTimes.sorted(by: { $0.key < $1.key }) {
            print("  \(step): \(String(format: "%.1f", duration))s")
        }
        if !abandonmentPoints.isEmpty {
            print("\nAbandonment Points:")
            for point in abandonmentPoints {
                print("  - \(point)")
            }
        }
        print("=" * 60 + "\n")
    }
}

// MARK: - Extensions

extension OnboardingStep {
    var analyticsName: String {
        switch self {
        case .welcome:
            return "welcome"
        case .privacy:
            return "privacy"
        case .features:
            return "features"
        case .accountSetup:
            return "account_setup"
        case .biometric:
            return "biometric"
        case .quickStart:
            return "quick_start"
        case .firstAction:
            return "first_action"
        }
    }
}

extension FirstActionType {
    var analyticsName: String {
        switch self {
        case .uploadStatement:
            return "upload_statement"
        case .manualEntry:
            return "manual_entry"
        case .createBudget:
            return "create_budget"
        }
    }
}

// MARK: - String Extension

private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}
