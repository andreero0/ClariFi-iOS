//
//  ErrorView.swift
//  ClariFi iOS
//
//  Reusable error display and recovery views
//

import SwiftUI

struct ErrorView: View {
    let error: AppError
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            SafeImage(systemName: errorIcon, fallback: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(errorColor)
                .accessibilityHidden(true)
            
            Text(errorTitle)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .accessibleHeading()
            
            Text(error.errorDescription ?? "An unknown error occurred")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            HStack(spacing: 12) {
                if let onRetry = onRetry {
                    Button(action: {
                        HapticFeedback.impact(.medium).trigger()
                        onRetry()
                    }) {
                        Text("Try Again")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .accessibilityLabel("Try again")
                    .accessibilityHint("Retry the failed operation")
                }
                
                Button(action: {
                    HapticFeedback.selection.trigger()
                    onDismiss()
                }) {
                    Text(onRetry == nil ? "OK" : "Dismiss")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                }
                .accessibilityLabel(onRetry == nil ? "OK" : "Dismiss")
                .accessibilityHint("Close this error message")
            }
        }
        .padding(30)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding()
        .onAppear {
            HapticFeedback.error.trigger()
            let message = "\(errorTitle). \(error.errorDescription ?? "")"
            AccessibilityAnnouncement.announce(message)
        }
    }
    
    private var errorIcon: String {
        switch error {
        case .authenticationFailed:
            return "lock.shield.fill"
        case .storageError:
            return "externaldrive.fill.badge.xmark"
        case .networkError:
            return "wifi.slash"
        case .privacyViolation:
            return "hand.raised.fill"
        case .subscriptionRequired:
            return "crown.fill"
        case .ocrFailed, .parsingFailed:
            return "doc.text.magnifyingglass"
        default:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var errorColor: Color {
        switch error {
        case .authenticationFailed:
            return .orange
        case .storageError:
            return .red
        case .networkError:
            return .blue
        case .privacyViolation:
            return .purple
        case .subscriptionRequired:
            return .yellow
        default:
            return .red
        }
    }
    
    private var errorTitle: String {
        switch error {
        case .authenticationFailed:
            return "Authentication Required"
        case .storageError:
            return "Storage Error"
        case .networkError:
            return "Connection Error"
        case .privacyViolation:
            return "Privacy Settings"
        case .subscriptionRequired:
            return "Premium Feature"
        case .ocrFailed:
            return "Document Reading Failed"
        case .parsingFailed:
            return "Parsing Error"
        case .parsingError:
            return "Parsing Error"
        case .validationError:
            return "Validation Error"
        case .workflowFailed:
            return "Operation Failed"
        case .initializationFailed:
            return "Initialization Error"
        case .unknownError:
            return "Unknown Error"
        }
    }
}

struct InlineErrorView: View {
    let message: String
    let onDismiss: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ErrorBanner: View {
    let message: String
    let type: BannerType
    let onDismiss: () -> Void
    
    enum BannerType {
        case error
        case warning
        case info
        
        var color: Color {
            switch self {
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            SafeImage(systemName: type.icon, fallback: "info.circle.fill")
                .foregroundColor(type.color)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: onDismiss) {
                SafeImage(systemName: "xmark", fallback: "xmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(type.color.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

#Preview("Error View") {
    ErrorView(
        error: .ocrFailed(reason: "Unable to detect text in the image"),
        onRetry: { print("Retry") },
        onDismiss: { print("Dismiss") }
    )
}

#Preview("Inline Error") {
    InlineErrorView(
        message: "Failed to save transaction",
        onDismiss: { print("Dismiss") }
    )
    .padding()
}

#Preview("Error Banner") {
    VStack(spacing: 12) {
        ErrorBanner(
            message: "Failed to connect to server",
            type: .error,
            onDismiss: { print("Dismiss") }
        )
        
        ErrorBanner(
            message: "Low storage space available",
            type: .warning,
            onDismiss: { print("Dismiss") }
        )
        
        ErrorBanner(
            message: "New insights available",
            type: .info,
            onDismiss: { print("Dismiss") }
        )
    }
}
