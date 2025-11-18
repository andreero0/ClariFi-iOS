//
//  ErrorHandler.swift
//  ClariFi iOS
//
//  Comprehensive error handling system to prevent app crashes
//

import Foundation
import SwiftUI
import OSLog

// MARK: - Global C-Compatible Signal Handler

/// Global C-compatible function to bridge signal handling to Swift
@_cdecl("swift_signal_handler_bridge")
func swift_signal_handler_bridge(signal: Int32) {
    ErrorHandler.shared.handleSignal(signal: signal)
}

/// Global error handler for the app
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var hasError: Bool = false
    @Published var currentError: AppError?
    @Published var errorCount: Int = 0
    
    private let logger = Logger(subsystem: "com.clarifi.ios", category: "ErrorHandler")
    private let maxErrorCount = 10
    private var errorHistory: [AppError] = []
    
    private init() {
        setupGlobalErrorHandling()
    }
    
    // MARK: - Global Error Handling
    
    private func setupGlobalErrorHandling() {
        // Set up global exception handler
        NSSetUncaughtExceptionHandler { exception in
            ErrorHandler.shared.handleUncaughtException(exception)
        }
        
        // Set up signal handlers for common crashes
        signal(SIGABRT, swift_signal_handler_bridge)
        signal(SIGILL, swift_signal_handler_bridge)
        signal(SIGSEGV, swift_signal_handler_bridge)
        signal(SIGFPE, swift_signal_handler_bridge)
        signal(SIGBUS, swift_signal_handler_bridge)
        signal(SIGPIPE, swift_signal_handler_bridge)
    }
    
    func handleSignal(signal: Int32) {
        let error = AppError.initializationFailed(underlying: NSError(domain: "SignalError", code: Int(signal), userInfo: [NSLocalizedDescriptionKey: "Signal \(signal) received"]))
        ErrorHandler.shared.handleError(error)
        
        // Log the signal
        let logger = Logger(subsystem: "com.clarifi.ios", category: "SignalHandler")
        logger.error("Signal \(signal) received")
        
        // Exit gracefully
        exit(1)
    }
    
    // MARK: - Error Handling Methods
    
    func handleError(_ error: AppError) {
        logger.error("Error handled: \(error.localizedDescription)")
        
        // Add to error history
        errorHistory.append(error)
        if errorHistory.count > maxErrorCount {
            errorHistory.removeFirst()
        }
        
        // Update state
        currentError = error
        hasError = true
        errorCount += 1
        
        // Track analytics if available
        if let analyticsService = try? AppDIContainer().resolve(AnalyticsServiceProtocol.self) {
            analyticsService.captureException(error, context: [
                "error_count": errorCount,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ])
        }
        
        // Show error to user if it's critical
        if error.isCritical {
            showErrorToUser(error)
        }
    }
    
    func handleUncaughtException(_ exception: NSException) {
        let underlyingError = NSError(domain: "ExceptionError", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "Uncaught exception: \(exception.name.rawValue)",
            "reason": exception.reason ?? "Unknown",
            "callStack": exception.callStackSymbols
        ])
        let error = AppError.initializationFailed(underlying: underlyingError)
        handleError(error)
        
        logger.critical("Uncaught exception: \(exception.name.rawValue)")
        logger.critical("Reason: \(exception.reason ?? "Unknown")")
        logger.critical("Call stack: \(exception.callStackSymbols)")
    }
    
    func handleSwiftError(_ error: Error) {
        let appError = AppError.from(error)
        handleError(appError)
    }
    
    // MARK: - Error Recovery
    
    func clearError() {
        hasError = false
        currentError = nil
    }
    
    func resetErrorCount() {
        errorCount = 0
        errorHistory.removeAll()
    }
    
    func canRecover() -> Bool {
        return errorCount < maxErrorCount
    }
    
    // MARK: - User Interface
    
    private func showErrorToUser(_ error: AppError) {
        // This would typically show an alert or error view
        // For now, we'll just log it
        logger.error("Showing error to user: \(error.localizedDescription)")
    }
    
    // MARK: - Error Analysis
    
    func getErrorFrequency() -> [String: Int] {
        var frequency: [String: Int] = [:]
        
        for error in errorHistory {
            let key = String(describing: type(of: error))
            frequency[key, default: 0] += 1
        }
        
        return frequency
    }
    
    func getMostCommonError() -> AppError? {
        let frequency = getErrorFrequency()
        let mostCommon = frequency.max { $0.value < $1.value }
        
        return errorHistory.first { error in
            String(describing: type(of: error)) == mostCommon?.key
        }
    }
}

// MARK: - AppError Extensions

extension AppError {
    var isCritical: Bool {
        switch self {
        case .initializationFailed, .authenticationFailed, .storageError:
            return true
        default:
            return false
        }
    }
    
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        // Convert common system errors
        if let nsError = error as NSError? {
            switch nsError.domain {
            case NSCocoaErrorDomain:
                return .storageError(underlying: nsError)
            case NSURLErrorDomain:
                return .networkError(underlying: nsError)
            default:
                return .initializationFailed(underlying: nsError)
            }
        }
        
        return .unknownError
    }
}

// MARK: - Global Error Handling Functions

func handleError(_ error: Error) {
    ErrorHandler.shared.handleSwiftError(error)
}

func handleError(_ error: AppError) {
    ErrorHandler.shared.handleError(error)
}

// MARK: - SwiftUI Error Handling

struct ErrorHandlingViewModifier: ViewModifier {
    @StateObject private var errorHandler = ErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorHandler.hasError) {
                Button("OK") {
                    errorHandler.clearError()
                }
            } message: {
                if let error = errorHandler.currentError {
                    Text(error.localizedDescription)
                }
            }
    }
}

extension View {
    func handleErrors() -> some View {
        self.modifier(ErrorHandlingViewModifier())
    }
}
