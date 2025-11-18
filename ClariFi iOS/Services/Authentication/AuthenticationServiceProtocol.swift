//
//  AuthenticationServiceProtocol.swift
//  ClariFi iOS
//
//  Created by Claude on 2025-11-05.
//  Protocol defining authentication service interface
//

import Foundation
import CoreData

/// Protocol defining authentication operations for user management
protocol AuthenticationServiceProtocol {

    // MARK: - Registration & Login

    /// Register a new user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password (must meet strength requirements)
    ///   - displayName: User's display name
    /// - Returns: Created User entity
    /// - Throws: AuthenticationError if registration fails
    func signUp(email: String, password: String, displayName: String) async throws -> User

    /// Sign in an existing user
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: User entity
    /// - Throws: AuthenticationError if authentication fails
    func signIn(email: String, password: String) async throws -> User

    /// Sign in with magic link (passwordless)
    /// - Parameter email: User's email address
    /// - Throws: AuthenticationError if operation fails
    func signInWithMagicLink(email: String) async throws

    // MARK: - Session Management

    /// Sign out the current user
    /// - Throws: AuthenticationError if sign out fails
    func signOut() async throws

    /// Refresh the current session
    /// - Throws: AuthenticationError if refresh fails
    func refreshSession() async throws

    /// Get the currently authenticated user
    /// - Returns: User entity if authenticated, nil otherwise
    func getCurrentUser() async throws -> User?

    // MARK: - Password Management

    /// Send password reset email
    /// - Parameter email: User's email address
    /// - Throws: AuthenticationError if operation fails
    func resetPassword(email: String) async throws

    /// Update password for authenticated user
    /// - Parameter newPassword: New password (must meet strength requirements)
    /// - Throws: AuthenticationError if update fails
    func updatePassword(newPassword: String) async throws

    /// Validate password strength
    /// - Parameter password: Password to validate
    /// - Returns: Tuple of (isValid, strength, feedback)
    func validatePassword(_ password: String) -> (isValid: Bool, strength: PasswordStrength, feedback: String)

    // MARK: - Email Verification

    /// Verify email with token from email link
    /// - Parameter token: Verification token
    /// - Throws: AuthenticationError if verification fails
    func verifyEmail(token: String) async throws

    /// Resend verification email
    /// - Throws: AuthenticationError if operation fails
    func resendVerificationEmail() async throws

    // MARK: - User Management

    /// Update user profile information
    /// - Parameters:
    ///   - displayName: New display name (optional)
    ///   - firstName: New first name (optional)
    ///   - lastName: New last name (optional)
    /// - Throws: AuthenticationError if update fails
    func updateProfile(displayName: String?, firstName: String?, lastName: String?) async throws

    /// Delete user account and all associated data
    /// - Throws: AuthenticationError if deletion fails
    func deleteAccount() async throws
}

// MARK: - Password Strength

enum PasswordStrength: Int {
    case veryWeak = 0
    case weak = 1
    case fair = 2
    case strong = 3
    case veryStrong = 4

    var color: String {
        switch self {
        case .veryWeak: return "red"
        case .weak: return "orange"
        case .fair: return "yellow"
        case .strong: return "lightGreen"
        case .veryStrong: return "green"
        }
    }

    var description: String {
        switch self {
        case .veryWeak: return "Very Weak"
        case .weak: return "Weak"
        case .fair: return "Fair"
        case .strong: return "Strong"
        case .veryStrong: return "Very Strong"
        }
    }
}
