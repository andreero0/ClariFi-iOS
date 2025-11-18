//
//  LoginView.swift
//  ClariFi iOS
//
//  Created by Claude on 2025-11-05.
//  User login screen
//

import SwiftUI

/// Login form for existing users
struct LoginView: View {

    @StateObject private var viewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.diContainer) private var container
    @State private var sessionManager: SessionManager?

    init(authService: AuthenticationServiceProtocol) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(authService: authService))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding(.top, 20)

                        Text("Welcome Back")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)

                    // Form fields
                    VStack(spacing: 16) {
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

                            SecureField("Enter your password", text: $viewModel.password)
                                .textContentType(.password)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }

                    // Remember me and forgot password
                    HStack {
                        Button(action: viewModel.toggleRememberMe) {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.rememberMe ? "checkmark.square.fill" : "square")
                                    .foregroundColor(viewModel.rememberMe ? .blue : .gray)
                                Text("Remember me")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }

                        Spacer()

                        Button(action: viewModel.showForgotPasswordSheet) {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 4)

                    // Sign in button
                    Button(action: {
                        Task {
                            await viewModel.signIn()
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        } else {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                    }
                    .background(viewModel.isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(16)
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        Text("OR")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }

                    // Magic link button
                    Button(action: {
                        Task {
                            await viewModel.signInWithMagicLink()
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope")
                            Text("Sign in with Email Link")
                                .font(.subheadline)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.email.isEmpty || !viewModel.isEmailValid || viewModel.isLoading)

                    // Create account link
                    HStack {
                        Text("Don't have an account?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button("Create Account") {
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
            .alert("", isPresented: $viewModel.showError) {
                Button("OK", action: viewModel.dismissError)
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $viewModel.showForgotPassword) {
                ForgotPasswordSheet(viewModel: viewModel)
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

// MARK: - Forgot Password Sheet

struct ForgotPasswordSheet: View {

    @ObservedObject var viewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding(.top, 20)

                    Text("Reset Password")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Enter your email to receive password reset instructions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Enter your email", text: $viewModel.forgotPasswordEmail)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)

                // Send button
                Button(action: {
                    Task {
                        await viewModel.sendPasswordReset()
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    } else {
                        Text("Send Reset Link")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                }
                .background(viewModel.isForgotPasswordValid ? Color.blue : Color.gray)
                .cornerRadius(16)
                .disabled(!viewModel.isForgotPasswordValid || viewModel.isLoading)
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.closeForgotPassword()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let container = AppDIContainer.createPreviewContainer()
        let authService = container.resolve(AuthenticationServiceProtocol.self)
        LoginView(authService: authService)
    }
}
