//
//  BiometricAuthService.swift
//  ClariFi_iOS
//
//  Handles biometric authentication (Face ID/Touch ID) for app access
//

import Foundation
import LocalAuthentication
import Combine

/// Service for managing biometric authentication
class BiometricAuthService: ObservableObject {
    static let shared = BiometricAuthService()
    
    private let context = LAContext()
    private let authenticationReason = "Authenticate to access your financial data"
    
    // UserDefaults keys
    private let biometricEnabledKey = "com.clarifi.biometric.enabled"
    private let lastAuthenticationKey = "com.clarifi.biometric.lastAuth"
    private let authenticationTimeoutKey = "com.clarifi.biometric.timeout"
    
    private init() {}
    
    // MARK: - Biometric Availability
    
    /// Checks if biometric authentication is available on the device
    func isBiometricAvailable() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Returns the type of biometric authentication available
    func biometricType() -> BiometricType {
        guard isBiometricAvailable() else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }
    
    // MARK: - Authentication Settings
    
    /// Checks if biometric authentication is enabled by user
    var isBiometricEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: biometricEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: biometricEnabledKey)
        }
    }
    
    /// Authentication timeout in seconds (default: 5 minutes)
    var authenticationTimeout: TimeInterval {
        get {
            let timeout = UserDefaults.standard.double(forKey: authenticationTimeoutKey)
            return timeout > 0 ? timeout : 300 // Default 5 minutes
        }
        set {
            UserDefaults.standard.set(newValue, forKey: authenticationTimeoutKey)
        }
    }
    
    private var lastAuthenticationDate: Date? {
        get {
            UserDefaults.standard.object(forKey: lastAuthenticationKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastAuthenticationKey)
        }
    }
    
    // MARK: - Authentication
    
    /// Authenticates user with biometrics
    func authenticate() async throws -> Bool {
        guard isBiometricAvailable() else {
            throw BiometricAuthError.notAvailable
        }
        
        guard isBiometricEnabled else {
            throw BiometricAuthError.notEnabled
        }
        
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Passcode"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: authenticationReason
            )
            
            if success {
                lastAuthenticationDate = Date()
            }
            
            return success
        } catch let error as LAError {
            throw BiometricAuthError.authenticationFailed(error)
        }
    }
    
    /// Authenticates with device passcode as fallback
    func authenticateWithPasscode() async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: authenticationReason
            )
            
            if success {
                lastAuthenticationDate = Date()
            }
            
            return success
        } catch let error as LAError {
            throw BiometricAuthError.authenticationFailed(error)
        }
    }
    
    /// Checks if authentication is required based on timeout
    func isAuthenticationRequired() -> Bool {
        guard isBiometricEnabled else {
            return false
        }
        
        guard let lastAuth = lastAuthenticationDate else {
            return true
        }
        
        let timeSinceAuth = Date().timeIntervalSince(lastAuth)
        return timeSinceAuth > authenticationTimeout
    }
    
    /// Invalidates current authentication session
    func invalidateAuthentication() {
        lastAuthenticationDate = nil
    }
    
    // MARK: - Setup
    
    /// Enables biometric authentication with initial setup
    func enableBiometric() async throws {
        guard isBiometricAvailable() else {
            throw BiometricAuthError.notAvailable
        }
        
        // Test authentication before enabling
        let success = try await authenticate()
        
        if success {
            isBiometricEnabled = true
        } else {
            throw BiometricAuthError.setupFailed
        }
    }
    
    /// Disables biometric authentication
    func disableBiometric() {
        isBiometricEnabled = false
        invalidateAuthentication()
    }
}

// MARK: - Types

enum BiometricType {
    case none
    case touchID
    case faceID
    case opticID
    
    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .opticID:
            return "Optic ID"
        }
    }
    
    var iconName: String {
        switch self {
        case .none:
            return "lock"
        case .touchID:
            return "touchid"
        case .faceID:
            return "faceid"
        case .opticID:
            return "opticid"
        }
    }
}

enum BiometricAuthError: LocalizedError {
    case notAvailable
    case notEnabled
    case authenticationFailed(LAError)
    case setupFailed
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnabled:
            return "Biometric authentication is not enabled"
        case .authenticationFailed(let error):
            return "Authentication failed: \(error.localizedDescription)"
        case .setupFailed:
            return "Failed to set up biometric authentication"
        }
    }
}
