//
//  RegistrationView.swift
//  ClariFi iOS
//
//  Created by Claude on 2025-11-05.
//  User registration screen
//

import SwiftUI

/// Registration form for new user accounts
struct RegistrationView: View {

    @StateObject private var viewModel: RegistrationViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.diContainer) private var container
    @State private var sessionManager: SessionManager?

    init(authService: AuthenticationServiceProtocol) {
        _viewModel = StateObject(wrappedValue: RegistrationViewModel(authService: authService))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding(.top, 20)

                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Join ClariFi to manage your finances")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 8)

                    // Form fields
                    VStack(spacing: 16) {
                        // Display name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Display Name")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("Enter your name", text: $viewModel.displayName)
                                .textContentType(.name)
                                .autocapitalization(.words)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.isDisplayNameValid ? Color.clear : Color.red, lineWidth: 1)
                                )
                        }

                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("Enter your email", text: $viewModel.email)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.isEmailValid ? Color.clear : Color.red, lineWidth: 1)
                                )

                            if !viewModel.isEmailValid {
                                Text("Please enter a valid email address")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            SecureField("Create a password", text: $viewModel.password)
                                .textContentType(.newPassword)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.isPasswordValid ? Color.clear : Color.red, lineWidth: 1)
                                )

                            // Password strength indicator
                            if viewModel.showPasswordStrength {
                                PasswordStrengthView(
                                    strength: viewModel.passwordStrength,
                                    feedback: viewModel.passwordFeedback
                                )
                            }
                        }

                        // Confirm password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            SecureField("Confirm your password", text: $viewModel.confirmPassword)
                                .textContentType(.newPassword)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.doPasswordsMatch ? Color.clear : Color.red, lineWidth: 1)
                                )

                            if !viewModel.doPasswordsMatch && !viewModel.confirmPassword.isEmpty {
                                Text("Passwords do not match")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    // Terms and conditions
                    HStack(alignment: .top, spacing: 12) {
                        Button(action: {
                            viewModel.agreedToTerms.toggle()
                        }) {
                            Image(systemName: viewModel.agreedToTerms ? "checkmark.square.fill" : "square")
                                .font(.title3)
                                .foregroundColor(viewModel.agreedToTerms ? .blue : .gray)
                        }

                        Text("I agree to the Terms of Service and Privacy Policy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 4)

                    // Register button
                    Button(action: {
                        Task {
                            await viewModel.register()
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        } else {
                            Text("Create Account")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                    }
                    .background(viewModel.isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(16)
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)

                    // Sign in link
                    HStack {
                        Text("Already have an account?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button("Sign In") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Registration Error", isPresented: $viewModel.showError) {
                Button("OK", action: viewModel.dismissError)
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .onAppear {
                // Initialize session manager to observe authentication state
                sessionManager = container.resolve(SessionManager.self)
            }
            .onChange(of: sessionManager?.isAuthenticated) { isAuthenticated in
                // Dismiss sheet when user successfully authenticates
                if isAuthenticated == true {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        let container = AppDIContainer.createPreviewContainer()
        let authService = container.resolve(AuthenticationServiceProtocol.self)
        RegistrationView(authService: authService)
    }
}
