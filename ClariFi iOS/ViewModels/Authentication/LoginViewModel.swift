//
//  LoginViewModel.swift
//  ClariFi iOS
//
//  Created by Claude on 2025-11-05.
//  ViewModel for user login flow
//

import Foundation
import SwiftUI
import Combine

/// ViewModel managing user login state and authentication
@MainActor
class LoginViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = false

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    @Published var showForgotPassword: Bool = false
    @Published var forgotPasswordEmail: String = ""
    @Published var resetPasswordSent: Bool = false

    // Validation states
    @Published var isEmailValid: Bool = true

    // MARK: - Private Properties

    private let authService: AuthenticationServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        isEmailValid
    }

    var isForgotPasswordValid: Bool {
        !forgotPasswordEmail.isEmpty &&
        isValidEmailFormat(forgotPasswordEmail)
    }

    // MARK: - Initialization

    init(authService: AuthenticationServiceProtocol) {
        self.authService = authService
        setupValidation()
        loadRememberedEmail()
    }

    // MARK: - Setup

    private func setupValidation() {
        // Validate email on change
        $email
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] email in
                self?.validateEmail(email)
            }
            .store(in: &cancellables)
    }

    private func loadRememberedEmail() {
        if let savedEmail = UserDefaults.standard.string(forKey: "rememberedEmail") {
            email = savedEmail
            rememberMe = true
        }
    }

    // MARK: - Validation Methods

    private func validateEmail(_ email: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            isEmailValid = true
            return
        }

        isEmailValid = isValidEmailFormat(trimmedEmail)
    }

    private func isValidEmailFormat(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    // MARK: - Actions

    /// Sign in with email and password
    func signIn() async {
        guard isFormValid else {
            errorMessage = "Please enter a valid email and password"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await authService.signIn(
                email: email,
                password: password
            )

            // Save email if remember me is enabled
            if rememberMe {
                UserDefaults.standard.set(email, forKey: "rememberedEmail")
            } else {
                UserDefaults.standard.removeObject(forKey: "rememberedEmail")
            }

            // Success - navigation handled by parent view observing session state
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    /// Sign in with magic link (passwordless)
    func signInWithMagicLink() async {
        guard !email.isEmpty && isEmailValid else {
            errorMessage = "Please enter a valid email address"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.signInWithMagicLink(email: email)

            errorMessage = "Check your email for a sign-in link"
            showError = true // Using alert to show success message
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    /// Send password reset email
    func sendPasswordReset() async {
        guard isForgotPasswordValid else {
            errorMessage = "Please enter a valid email address"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.resetPassword(email: forgotPasswordEmail)

            resetPasswordSent = true
            errorMessage = "Password reset instructions sent to your email"
            showError = true

            // Clear and close after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.closeForgotPassword()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    /// Show forgot password sheet
    func showForgotPasswordSheet() {
        forgotPasswordEmail = email
        showForgotPassword = true
    }

    /// Close forgot password sheet
    func closeForgotPassword() {
        showForgotPassword = false
        forgotPasswordEmail = ""
        resetPasswordSent = false
    }

    /// Clear form fields
    func clearForm() {
        email = ""
        password = ""
        errorMessage = nil
        showError = false
    }

    /// Dismiss error alert
    func dismissError() {
        showError = false
        errorMessage = nil
    }

    /// Toggle remember me
    func toggleRememberMe() {
        rememberMe.toggle()
        if !rememberMe {
            UserDefaults.standard.removeObject(forKey: "rememberedEmail")
        }
    }
}
