//
//  View+ErrorAlert.swift
//  ClariFi iOS
//
//  Created by AI Assistant on 2025-10-11.
//

import SwiftUI

extension View {
    /// Presents a consistent error alert when an AppError is present
    /// - Parameter error: A binding to an optional AppError
    /// - Returns: A view with an error alert modifier
    func errorAlert(error: Binding<AppError?>) -> some View {
        alert(
            "Error",
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            ),
            presenting: error.wrappedValue
        ) { appError in
            Button("OK", role: .cancel) {
                error.wrappedValue = nil
            }
        } message: { appError in
            VStack(alignment: .leading, spacing: 8) {
                if let description = appError.errorDescription {
                    Text(description)
                }
                
                if let recovery = appError.recoverySuggestion {
                    Text(recovery)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    /// Presents a consistent error alert with custom actions
    /// - Parameters:
    ///   - error: A binding to an optional AppError
    ///   - primaryAction: Optional primary action button
    ///   - secondaryAction: Optional secondary action button
    /// - Returns: A view with an error alert modifier
    func errorAlert(
        error: Binding<AppError?>,
        primaryAction: ((AppError) -> Void)? = nil,
        secondaryAction: ((AppError) -> Void)? = nil
    ) -> some View {
        alert(
            "Error",
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            ),
            presenting: error.wrappedValue
        ) { appError in
            if let primaryAction = primaryAction {
                Button("Retry") {
                    primaryAction(appError)
                    error.wrappedValue = nil
                }
            }
            
            if let secondaryAction = secondaryAction {
                Button("More Info") {
                    secondaryAction(appError)
                    error.wrappedValue = nil
                }
            }
            
            Button("OK", role: .cancel) {
                error.wrappedValue = nil
            }
        } message: { appError in
            VStack(alignment: .leading, spacing: 8) {
                if let description = appError.errorDescription {
                    Text(description)
                }
                
                if let recovery = appError.recoverySuggestion {
                    Text(recovery)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
