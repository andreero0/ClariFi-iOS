//
//  BaseViewModel.swift
//  ClariFi iOS
//
//  Base ViewModel with common patterns for error handling and loading states
//  All ViewModels should inherit from this class for consistency
//

import Foundation
import Combine

/// Base ViewModel providing common functionality for all ViewModels
/// Includes standardized error handling, loading states, and analytics integration
@MainActor
class BaseViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current error state, if any
    /// Views should bind to this property to display error alerts
    @Published var error: AppError?
    
    /// Loading state indicator
    /// Views should use this to show loading spinners or disable interactions
    @Published var isLoading: Bool = false
    
    // MARK: - Initialization
    
    init() {
        // Base initialization
        // Subclasses should call super.init() and then perform their own setup
    }
    
    // MARK: - Error Handling
    
    /// Centralized error handling method
    /// Converts any error to AppError, sets the error property, and logs to analytics
    ///
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - context: Additional context information for debugging and analytics
    ///
    /// Usage:
    /// ```swift
    /// do {
    ///     try await repository.save(item)
    /// } catch {
    ///     handleError(error, context: ["operation": "save_item", "item_id": item.id])
    /// }
    /// ```
    func handleError(_ error: Error, context: [String: Any] = [:]) {
        // Convert to AppError if needed
        if let appError = error as? AppError {
            self.error = appError
        } else {
            // Map other error types to AppError
            self.error = mapToAppError(error)
        }
        
        // Capture exception in analytics with context
        var enrichedContext = context
        enrichedContext["view_model"] = String(describing: type(of: self))
        enrichedContext["error_type"] = String(describing: type(of: error))
        
        // Safely capture analytics - don't let analytics errors crash the app
        do {
            Analytics.captureException(error, context: enrichedContext)
        } catch {
            print("Warning: Failed to capture analytics exception: \(error)")
        }
    }
    
    // MARK: - Private Helpers
    
    /// Maps generic errors to AppError cases
    private func mapToAppError(_ error: Error) -> AppError {
        // Check for common error types and map appropriately
        let nsError = error as NSError
        
        switch nsError.domain {
        case NSURLErrorDomain:
            return .networkError(underlying: error)
        case NSCocoaErrorDomain:
            return .storageError(underlying: error)
        default:
            return .unknownError
        }
    }
}
