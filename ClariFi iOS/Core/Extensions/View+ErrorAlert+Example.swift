//
//  View+ErrorAlert+Example.swift
//  ClariFi iOS
//
//  Created by AI Assistant on 2025-10-11.
//
//  This file contains usage examples for the errorAlert modifier.
//  It is not compiled in production builds.
//

#if DEBUG
import SwiftUI

// MARK: - Basic Usage Example
struct ErrorAlertBasicExample: View {
    @StateObject private var viewModel = ExampleViewModel()
    
    var body: some View {
        VStack {
            Button("Trigger Error") {
                viewModel.triggerError()
            }
        }
        .errorAlert(error: $viewModel.error)
    }
}

// MARK: - Advanced Usage Example with Custom Actions
struct ErrorAlertAdvancedExample: View {
    @StateObject private var viewModel = ExampleViewModel()
    
    var body: some View {
        VStack {
            Button("Trigger Error") {
                viewModel.triggerError()
            }
        }
        .errorAlert(
            error: $viewModel.error,
            primaryAction: { error in
                // Retry action
                viewModel.retryLastAction()
            },
            secondaryAction: { error in
                // Show more info
                viewModel.showErrorDetails(error)
            }
        )
    }
}

// MARK: - Example ViewModel
@MainActor
class ExampleViewModel: ObservableObject {
    @Published var error: AppError?
    
    func triggerError() {
        error = .validationError(message: "Invalid input provided")
    }
    
    func retryLastAction() {
        // Retry logic
    }
    
    func showErrorDetails(_ error: AppError) {
        // Show details
    }
}

// MARK: - Preview
struct ErrorAlertExample_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ErrorAlertBasicExample()
                .previewDisplayName("Basic Error Alert")
            
            ErrorAlertAdvancedExample()
                .previewDisplayName("Advanced Error Alert")
        }
    }
}
#endif
