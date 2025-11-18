//
//  AppError.swift
//  ClariFi iOS
//
//  Created by AI Assistant on 2025-10-10.
//

import Foundation

enum AppError: LocalizedError {
    case initializationFailed(underlying: Error)
    case authenticationFailed(reason: String)
    case storageError(underlying: Error)
    case networkError(underlying: Error)
    case privacyViolation(action: String)
    case subscriptionRequired(feature: String)
    case workflowFailed(step: String, underlying: Error)
    case ocrFailed(reason: String)
    case parsingFailed(confidence: Float)
    case parsingError(message: String)
    case validationError(message: String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let error):
            return "Failed to initialize app: \(error.localizedDescription)"
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .storageError(let error):
            return "Storage error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .privacyViolation(let action):
            return "Privacy violation: \(action) requires consent"
        case .subscriptionRequired(let feature):
            return "\(feature) requires a premium subscription"
        case .workflowFailed(let step, let error):
            return "Failed at \(step): \(error.localizedDescription)"
        case .ocrFailed(let reason):
            return "Failed to read document: \(reason)"
        case .parsingFailed(let confidence):
            return "Could not parse transactions (confidence: \(Int(confidence * 100))%)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .initializationFailed:
            return "Try restarting the app. If the problem persists, contact support."
        case .authenticationFailed:
            return "Please try authenticating again or use your device passcode."
        case .storageError:
            return "Check available storage space and try again."
        case .networkError:
            return "Check your internet connection and try again."
        case .privacyViolation:
            return "Update your privacy settings to enable this feature."
        case .subscriptionRequired:
            return "Upgrade to premium to access this feature."
        case .workflowFailed:
            return "Please try again. If the problem persists, contact support."
        case .ocrFailed:
            return "Try taking a clearer photo or entering transactions manually."
        case .parsingFailed:
            return "Review and correct the parsed transactions before saving."
        case .parsingError:
            return "Please check the data format and try again."
        case .validationError:
            return "Please check your input and try again."
        case .unknownError:
            return "Please try again. If the problem persists, contact support."
        }
    }
}

