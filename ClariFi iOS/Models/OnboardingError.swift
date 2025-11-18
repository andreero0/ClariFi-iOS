import Foundation

/// Errors that can occur during the onboarding process
enum OnboardingError: Error, LocalizedError {
    case accountCreationFailed(reason: String?)
    case biometricSetupFailed(reason: String?)
    case invalidConfiguration
    case invalidAccountData(field: String)
    case duplicateAccountName(name: String)
    case stepValidationFailed(step: String)
    case persistenceFailed
    
    var errorDescription: String? {
        switch self {
        case .accountCreationFailed:
            return "Failed to create account"
        case .biometricSetupFailed:
            return "Failed to enable biometric authentication"
        case .invalidConfiguration:
            return "Invalid onboarding configuration"
        case .invalidAccountData(let field):
            return "Invalid \(field)"
        case .duplicateAccountName(let name):
            return "Account '\(name)' already exists"
        case .stepValidationFailed(let step):
            return "Cannot proceed from \(step)"
        case .persistenceFailed:
            return "Failed to save onboarding data"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .accountCreationFailed(let reason):
            return reason ?? "The account could not be created."
        case .biometricSetupFailed(let reason):
            return reason ?? "Biometric authentication could not be enabled."
        case .invalidConfiguration:
            return "The onboarding flow is not properly configured."
        case .invalidAccountData:
            return "The account information provided is not valid."
        case .duplicateAccountName:
            return "An account with this name already exists."
        case .stepValidationFailed:
            return "Required information is missing or invalid."
        case .persistenceFailed:
            return "The data could not be saved to storage."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .accountCreationFailed:
            return "Please try again. If the problem persists, restart the app."
        case .biometricSetupFailed:
            return "You can enable biometric authentication later in Settings."
        case .invalidConfiguration:
            return "Please restart the app. If the problem persists, reinstall the app."
        case .invalidAccountData(let field):
            return "Please provide a valid \(field) and try again."
        case .duplicateAccountName:
            return "Please choose a different account name."
        case .stepValidationFailed:
            return "Please complete all required fields before continuing."
        case .persistenceFailed:
            return "Please try again. Make sure you have enough storage space."
        }
    }
}
