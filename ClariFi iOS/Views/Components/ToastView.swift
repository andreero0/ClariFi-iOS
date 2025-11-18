//
//  ToastView.swift
//  ClariFi iOS
//
//  Toast notification component for success feedback
//

import SwiftUI

/// A temporary notification view that appears at the bottom of the screen.
///
/// Toast notifications provide non-intrusive feedback for user actions. They automatically
/// dismiss after 2.5 seconds and support different types (success, error, warning, info).
///
/// ## Usage
/// ```swift
/// @State private var showToast = false
///
/// var body: some View {
///     VStack {
///         Button("Save") {
///             // Perform save
///             showToast = true
///         }
///     }
///     .successToast(isShowing: $showToast, message: "Saved successfully")
/// }
/// ```
///
/// ## Accessibility
/// - Automatically announces message to VoiceOver users
/// - Combines icon and text into single accessibility element
/// - Marked as static text for appropriate VoiceOver behavior
struct ToastView: View {
    let message: String
    let icon: String
    let iconColor: Color
    @Binding var isShowing: Bool
    
    init(
        message: String,
        icon: String = "checkmark.circle.fill",
        iconColor: Color = .green,
        isShowing: Binding<Bool>
    ) {
        self.message = message
        self.icon = icon
        self.iconColor = iconColor
        self._isShowing = isShowing
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            // Auto-dismiss after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowing = false
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Convenience Initializers

extension ToastView {
    /// Creates a success toast with green checkmark icon.
    ///
    /// - Parameters:
    ///   - message: The success message to display
    ///   - isShowing: Binding to control toast visibility
    /// - Returns: A configured success toast view
    static func success(message: String, isShowing: Binding<Bool>) -> ToastView {
        ToastView(
            message: message,
            icon: "checkmark.circle.fill",
            iconColor: .green,
            isShowing: isShowing
        )
    }
    
    /// Creates an error toast with red X icon.
    ///
    /// - Parameters:
    ///   - message: The error message to display
    ///   - isShowing: Binding to control toast visibility
    /// - Returns: A configured error toast view
    static func error(message: String, isShowing: Binding<Bool>) -> ToastView {
        ToastView(
            message: message,
            icon: "xmark.circle.fill",
            iconColor: .red,
            isShowing: isShowing
        )
    }
    
    /// Warning toast
    static func warning(message: String, isShowing: Binding<Bool>) -> ToastView {
        ToastView(
            message: message,
            icon: "exclamationmark.triangle.fill",
            iconColor: .orange,
            isShowing: isShowing
        )
    }
    
    /// Info toast
    static func info(message: String, isShowing: Binding<Bool>) -> ToastView {
        ToastView(
            message: message,
            icon: "info.circle.fill",
            iconColor: .blue,
            isShowing: isShowing
        )
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let icon: String
    let iconColor: Color
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isShowing {
                ToastView(
                    message: message,
                    icon: icon,
                    iconColor: iconColor,
                    isShowing: $isShowing
                )
                .zIndex(1000)
            }
        }
    }
}

extension View {
    /// Adds a toast notification overlay to this view.
    ///
    /// - Parameters:
    ///   - isShowing: Binding that controls toast visibility
    ///   - message: The message to display in the toast
    ///   - icon: SF Symbol name for the toast icon
    ///   - iconColor: Color for the icon
    /// - Returns: A view with toast notification capability
    func toast(
        isShowing: Binding<Bool>,
        message: String,
        icon: String = "checkmark.circle.fill",
        iconColor: Color = .green
    ) -> some View {
        modifier(ToastModifier(
            isShowing: isShowing,
            message: message,
            icon: icon,
            iconColor: iconColor
        ))
    }
    
    /// Adds a success toast notification overlay to this view.
    ///
    /// Convenience method for showing success feedback with a green checkmark.
    ///
    /// - Parameters:
    ///   - isShowing: Binding that controls toast visibility
    ///   - message: The success message to display
    /// - Returns: A view with success toast capability
    func successToast(isShowing: Binding<Bool>, message: String) -> some View {
        toast(isShowing: isShowing, message: message, icon: "checkmark.circle.fill", iconColor: .green)
    }
    
    /// Show an error toast
    func errorToast(isShowing: Binding<Bool>, message: String) -> some View {
        toast(isShowing: isShowing, message: message, icon: "xmark.circle.fill", iconColor: .red)
    }
    
    /// Show a warning toast
    func warningToast(isShowing: Binding<Bool>, message: String) -> some View {
        toast(isShowing: isShowing, message: message, icon: "exclamationmark.triangle.fill", iconColor: .orange)
    }
    
    /// Show an info toast
    func infoToast(isShowing: Binding<Bool>, message: String) -> some View {
        toast(isShowing: isShowing, message: message, icon: "info.circle.fill", iconColor: .blue)
    }
}

// MARK: - Preview

#Preview("Success Toast") {
    struct PreviewWrapper: View {
        @State private var showToast = true
        
        var body: some View {
            VStack {
                Button("Show Toast") {
                    withAnimation {
                        showToast = true
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .successToast(isShowing: $showToast, message: "Transaction saved successfully")
        }
    }
    
    return PreviewWrapper()
}

#Preview("Error Toast") {
    struct PreviewWrapper: View {
        @State private var showToast = true
        
        var body: some View {
            VStack {
                Button("Show Toast") {
                    withAnimation {
                        showToast = true
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .errorToast(isShowing: $showToast, message: "Failed to save transaction")
        }
    }
    
    return PreviewWrapper()
}

#Preview("All Toast Types") {
    struct PreviewWrapper: View {
        @State private var showSuccess = false
        @State private var showError = false
        @State private var showWarning = false
        @State private var showInfo = false
        
        var body: some View {
            VStack(spacing: 20) {
                Button("Success") {
                    withAnimation { showSuccess = true }
                }
                Button("Error") {
                    withAnimation { showError = true }
                }
                Button("Warning") {
                    withAnimation { showWarning = true }
                }
                Button("Info") {
                    withAnimation { showInfo = true }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .successToast(isShowing: $showSuccess, message: "Success message")
            .errorToast(isShowing: $showError, message: "Error message")
            .warningToast(isShowing: $showWarning, message: "Warning message")
            .infoToast(isShowing: $showInfo, message: "Info message")
        }
    }
    
    return PreviewWrapper()
}
