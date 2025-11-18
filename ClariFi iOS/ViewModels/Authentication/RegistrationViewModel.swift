//
//  RegistrationViewModel.swift
//  ClariFi iOS
//
//  Created by Claude on 2025-11-05.
//  ViewModel for user registration flow
//

import Foundation
import SwiftUI
import Combine

/// ViewModel managing user registration state and validation
@MainActor
class RegistrationViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var agreedToTerms: Bool = false

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // Password strength indicator
    @Published var passwordStrength: PasswordStrength = .veryWeak
    @Published var passwordFeedback: String = ""
    @Published var showPasswordStrength: Bool = false

    // Validation states
    @Published var isDisplayNameValid: Bool = true
    @Published var isEmailValid: Bool = true
    @Published var isPasswordValid: Bool = true
    @Published var doPasswordsMatch: Bool = true

    // MARK: - Private Properties

    private let authService: AuthenticationServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var isFormValid: Bool {
        !displayName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        agreedToTerms &&
        isEmailValid &&
        isPasswordValid &&
        doPasswordsMatch
    }

    // MARK: - Initialization

    init(authService: AuthenticationServiceProtocol) {
        self.authService = authService
        setupValidation()
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

        // Validate password strength on change
        $password
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] password in
                self?.validatePasswordStrength(password)
            }
            .store(in: &cancellables)

        // Check if passwords match
        Publishers.CombineLatest($password, $confirmPassword)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] password, confirmPassword in
                self?.validatePasswordsMatch(password: password, confirmPassword: confirmPassword)
            }
            .store(in: &cancellables)

        // Validate display name
        $displayName
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] name in
                self?.validateDisplayName(name)
            }
            .store(in: &cancellables)
    }

    // MARK: - Validation Methods

    private func validateEmail(_ email: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            isEmailValid = true
            return
        }

        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        isEmailValid = emailPredicate.evaluate(with: trimmedEmail)
    }

    private func validatePasswordStrength(_ password: String) {
        guard !password.isEmpty else {
            showPasswordStrength = false
            isPasswordValid = true
            return
        }

        showPasswordStrength = true
        let validation = authService.validatePassword(password)
        passwordStrength = validation.strength
        passwordFeedback = validation.feedback
        isPasswordValid = validation.isValid
    }

    private func validatePasswordsMatch(password: String, confirmPassword: String) {
        guard !confirmPassword.isEmpty else {
            doPasswordsMatch = true
            return
        }

        doPasswordsMatch = password == confirmPassword
    }

    private func validateDisplayName(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            isDisplayNameValid = true
            return
        }

        isDisplayNameValid = trimmedName.count >= 2
    }

    // MARK: - Actions

    /// Register a new user
    func register() async {
        guard isFormValid else {
            errorMessage = "Please fill in all fields correctly"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await authService.signUp(
                email: email,
                password: password,
                displayName: displayName
            )

            // Success - navigation handled by parent view observing session state
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    /// Clear all form fields
    func clearForm() {
        displayName = ""
        email = ""
        password = ""
        confirmPassword = ""
        agreedToTerms = false
        errorMessage = nil
        showError = false
        showPasswordStrength = false
    }

    /// Dismiss error alert
    func dismissError() {
        showError = false
        errorMessage = nil
    }
}
