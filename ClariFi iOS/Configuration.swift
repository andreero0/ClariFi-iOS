//
//  Configuration.swift
//  ClariFi iOS
//
//  Configuration management for environment variables and app settings
//

import Foundation

/// Configuration manager for handling environment variables and app settings
struct Configuration {
    
    // MARK: - Analytics Configuration
    static var postHogAPIKey: String {
        return ProcessInfo.processInfo.environment["POSTHOG_API_KEY"] ?? ""
    }
    
    static var postHogHost: String {
        return ProcessInfo.processInfo.environment["POSTHOG_HOST"] ?? "https://app.posthog.com"
    }
    
    static var isAnalyticsEnabled: Bool {
        return !postHogAPIKey.isEmpty
    }
    
    // MARK: - StoreKit Configuration
    static var isStoreKitEnabled: Bool {
        #if DEBUG
        return false // Disable StoreKit in debug mode
        #else
        return true
        #endif
    }
    
    // MARK: - Development Configuration
    static var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Feature Flags
    static var enableHapticFeedback: Bool {
        if isSimulator {
            return false // Disable haptics in simulator
        }
        return UserDefaults.standard.bool(forKey: "HapticFeedbackEnabled")
    }
    
    static var enableBiometricAuth: Bool {
        return UserDefaults.standard.bool(forKey: "BiometricAuthEnabled")
    }
    
    // MARK: - Error Handling Configuration
    static var enableDetailedLogging: Bool {
        return isDebugMode
    }
    
    static var enableCrashReporting: Bool {
        return !isDebugMode && isAnalyticsEnabled
    }
}
