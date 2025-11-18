//
//  AuthenticationService.swift
//  ClariFi iOS
//
//  Created by Claude on 2025-11-05.
//  Implementation of authentication service with Supabase integration
//

import Foundation
import CoreData
import Supabase

// MARK: - UserProfile Codable Model

/// Codable model for Supabase user_profiles table
struct UserProfile: Codable {
    let id: String
    let displayName: String?
    let firstName: String?
    let lastName: String?
    let preferredCurrency: String?
    let biometricEnabled: Bool?
    let subscriptionTier: String?
    let isEmailVerified: Bool?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case firstName = "first_name"
        case lastName = "last_name"
        case preferredCurrency = "preferred_currency"
        case biometricEnabled = "biometric_enabled"
        case subscriptionTier = "subscription_tier"
        case isEmailVerified = "is_email_verified"
        case updatedAt = "updated_at"
    }
}

/// Service handling user authentication, registration, and session management
@MainActor
class AuthenticationService: AuthenticationServiceProtocol {

    // MARK: - Properties

    private let supabase: SupabaseClient
    private let context: NSManagedObjectContext
    private let sessionManager: SessionManager

    // MARK: - Password Validation Regex

    private let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
    private let uppercaseRegex = ".*[A-Z]+.*"
    private let lowercaseRegex = ".*[a-z]+.*"
    private let digitRegex = ".*[0-9]+.*"
    private let specialCharRegex = ".*[!@#$%^&*(),.?\":{}|<>]+.*"

    // MARK: - Initialization

    init(supabase: SupabaseClient, context: NSManagedObjectContext, sessionManager: SessionManager) {
        self.supabase = supabase
        self.context = context
        self.sessionManager = sessionManager
    }

    // MARK: - Registration & Login

    func signUp(email: String, password: String, displayName: String) async throws -> User {
        // 1. Validate inputs
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidEmail(trimmedEmail) else {
            throw AuthenticationError.invalidEmail
        }

        let passwordValidation = validatePassword(password)
        guard passwordValidation.isValid else {
            throw AuthenticationError.weakPassword
        }

        guard !trimmedDisplayName.isEmpty else {
            throw AuthenticationError.unknown(NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Display name is required"]))
        }

        // 2. Create Supabase user
        do {
            let authResponse = try await supabase.auth.signUp(
                email: trimmedEmail,
                password: password,
                data: ["display_name": .string(trimmedDisplayName)]
            )

            guard let session = authResponse.session else {
                throw AuthenticationError.unknown(NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No session returned after signup"]))
            }

            // 3. Store session
            try sessionManager.storeSession(session)

            // 4. Create local Core Data User entity
            let user = User(context: context)
            user.id = UUID()
            user.email = trimmedEmail
            user.displayName = trimmedDisplayName
            user.supabaseUserId = session.user.id.uuidString
            user.isEmailVerified = false
            user.preferredCurrency = "USD"
            user.biometricEnabled = false
            user.processingMode = "on-device"
            user.subscriptionTier = "free"
            user.createdAt = Date()
            user.updatedAt = Date()

            try context.save()

            // 5. Create user profile in Supabase
            try await createSupabaseProfile(user: user)

            return user

        } catch let error as AuthenticationError {
            throw error
        } catch {
            if error.localizedDescription.contains("already registered") {
                throw AuthenticationError.emailAlreadyInUse
            }
            throw AuthenticationError.unknown(error)
        }
    }

    func signIn(email: String, password: String) async throws -> User {
        // 1. Validate inputs
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard isValidEmail(trimmedEmail) else {
            throw AuthenticationError.invalidEmail
        }

        // 2. Authenticate with Supabase
        do {
            let session = try await supabase.auth.signIn(
                email: trimmedEmail,
                password: password
            )

            // 3. Store session
            try sessionManager.storeSession(session)

            // 4. Fetch or create local user
            let user = try await fetchOrCreateLocalUser(supabaseUserId: session.user.id.uuidString, email: trimmedEmail)

            // 5. Update lastLoginAt
            user.lastLoginAt = Date()
            user.updatedAt = Date()
            try context.save()

            return user

        } catch let error as AuthenticationError {
            throw error
        } catch {
            if error.localizedDescription.contains("Invalid login credentials") {
                throw AuthenticationError.invalidCredentials
            }
            throw AuthenticationError.unknown(error)
        }
    }

    func signInWithMagicLink(email: String) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard isValidEmail(trimmedEmail) else {
            throw AuthenticationError.invalidEmail
        }

        do {
            try await supabase.auth.signInWithOTP(
                email: trimmedEmail,
                redirectTo: URL(string: "clarifi://auth/callback")
            )
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }

    // MARK: - Session Management

    func signOut() async throws {
        do {
            try await supabase.auth.signOut()
            try sessionManager.clearSession()

            // Clear current user from context but keep data
            // (data remains for when user signs back in)
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }

    func refreshSession() async throws {
        try await sessionManager.refreshSession()
    }

    func getCurrentUser() async throws -> User? {
        guard let userId = sessionManager.currentUserId else {
            return nil
        }

        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "supabaseUserId == %@", userId)
        fetchRequest.fetchLimit = 1

        do {
            let users = try context.fetch(fetchRequest)
            return users.first
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }

    // MARK: - Password Management

    func resetPassword(email: String) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard isValidEmail(trimmedEmail) else {
            throw AuthenticationError.invalidEmail
        }

        do {
            try await supabase.auth.resetPasswordForEmail(
                trimmedEmail,
                redirectTo: URL(string: "clarifi://auth/reset-password")
            )
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }

    func updatePassword(newPassword: String) async throws {
        let passwordValidation = validatePassword(newPassword)
        guard passwordValidation.isValid else {
            throw AuthenticationError.weakPassword
        }

        do {
            try await supabase.auth.update(user: UserAttributes(password: newPassword))
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }

    nonisolated func validatePassword(_ password: String) -> (isValid: Bool, strength: PasswordStrength, feedback: String) {
        var score = 0
        var feedback: [String] = []

        // Check length
        if password.count < 8 {
            feedback.append("At least 8 characters")
        } else {
            score += 1
        }

        // Check uppercase
        if password.range(of: uppercaseRegex, options: .regularExpression) != nil {
            score += 1
        } else {
            feedback.append("One uppercase letter")
        }

        // Check lowercase
        if password.range(of: lowercaseRegex, options: .regularExpression) != nil {
            score += 1
        } else {
            feedback.append("One lowercase letter")
        }

        // Check digit
        if password.range(of: digitRegex, options: .regularExpression) != nil {
            score += 1
        } else {
            feedback.append("One number")
        }

        // Check special character
        if password.range(of: specialCharRegex, options: .regularExpression) != nil {
            score += 1
        } else {
            feedback.append("One special character")
        }

        // Bonus for length
        if password.count >= 12 {
            score += 1
        }

        let strength: PasswordStrength
        switch score {
        case 0...1:
            strength = .veryWeak
        case 2:
            strength = .weak
        case 3:
            strength = .fair
        case 4:
            strength = .strong
        default:
            strength = .veryStrong
        }

        let isValid = score >= 4 // Require at least "strong"
        let feedbackString = feedback.isEmpty ? "Password meets requirements" : "Required: " + feedback.joined(separator: ", ")

        return (isValid, strength, feedbackString)
    }

    // MARK: - Email Verification

    func verifyEmail(token: String) async throws {
        guard let email = sessionManager.currentUserEmail else {
            throw AuthenticationError.userNotFound
        }

        do {
            try await supabase.auth.verifyOTP(
                email: email,
                token: token,
                type: .email
            )

            // Update local user
            if let user = try await getCurrentUser() {
                user.isEmailVerified = true
                user.updatedAt = Date()
                try context.save()
            }
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }

    func resendVerificationEmail() async throws {
        guard let email = sessionManager.currentUserEmail else {
            throw AuthenticationError.userNotFound
        }

        do {
            try await supabase.auth.resend(
                email: email,
                type: .signup
            )
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }

    // MARK: - User Management

    func updateProfile(displayName: String?, firstName: String?, lastName: String?) async throws {
        guard let user = try await getCurrentUser() else {
            throw AuthenticationError.userNotFound
        }

        if let displayName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines), !displayName.isEmpty {
            user.displayName = displayName
        }

        if let firstName = firstName?.trimmingCharacters(in: .whitespacesAndNewlines) {
            user.firstName = firstName.isEmpty ? nil : firstName
        }

        if let lastName = lastName?.trimmingCharacters(in: .whitespacesAndNewlines) {
            user.lastName = lastName.isEmpty ? nil : lastName
        }

        user.updatedAt = Date()

        do {
            try context.save()

            // Update Supabase profile
            try await updateSupabaseProfile(user: user)
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }

    func deleteAccount() async throws {
        guard let user = try await getCurrentUser() else {
            throw AuthenticationError.userNotFound
        }

        do {
            // Delete from Supabase (will cascade to all user data via RLS)
            try await supabase.auth.admin.deleteUser(id: user.supabaseUserId ?? "")

            // Delete local data
            context.delete(user)
            try context.save()

            // Clear session
            try sessionManager.clearSession()
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }

    // MARK: - Private Helper Methods

    private func isValidEmail(_ email: String) -> Bool {
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func fetchOrCreateLocalUser(supabaseUserId: String, email: String) async throws -> User {
        // Try to fetch existing user
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "supabaseUserId == %@", supabaseUserId)
        fetchRequest.fetchLimit = 1

        if let existingUser = try context.fetch(fetchRequest).first {
            return existingUser
        }

        // Fetch user profile from Supabase
        guard let supabaseProfile = try await fetchSupabaseProfile(userId: supabaseUserId) else {
            throw AuthenticationError.userNotFound
        }

        // Create local user
        let user = User(context: context)
        user.id = UUID()
        user.email = email
        user.supabaseUserId = supabaseUserId
        user.displayName = supabaseProfile["display_name"] as? String
        user.firstName = supabaseProfile["first_name"] as? String
        user.lastName = supabaseProfile["last_name"] as? String
        user.preferredCurrency = supabaseProfile["preferred_currency"] as? String ?? "USD"
        user.biometricEnabled = supabaseProfile["biometric_enabled"] as? Bool ?? false
        user.subscriptionTier = supabaseProfile["subscription_tier"] as? String ?? "free"
        user.isEmailVerified = supabaseProfile["is_email_verified"] as? Bool ?? false
        user.createdAt = Date()
        user.updatedAt = Date()

        try context.save()
        return user
    }

    private func createSupabaseProfile(user: User) async throws {
        let profile = UserProfile(
            id: user.supabaseUserId ?? "",
            displayName: user.displayName,
            firstName: user.firstName,
            lastName: user.lastName,
            preferredCurrency: user.preferredCurrency ?? "USD",
            biometricEnabled: user.biometricEnabled,
            subscriptionTier: user.subscriptionTier ?? "free",
            isEmailVerified: user.isEmailVerified,
            updatedAt: nil
        )

        do {
            try await supabase
                .from("user_profiles")
                .insert(profile)
                .execute()
        } catch {
            print("Failed to create Supabase profile: \(error)")
            // Don't throw - local user is created, profile sync can retry later
        }
    }

    private func updateSupabaseProfile(user: User) async throws {
        let profile = UserProfile(
            id: user.supabaseUserId ?? "",
            displayName: user.displayName,
            firstName: user.firstName,
            lastName: user.lastName,
            preferredCurrency: user.preferredCurrency ?? "USD",
            biometricEnabled: user.biometricEnabled,
            subscriptionTier: nil,
            isEmailVerified: nil,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        do {
            try await supabase
                .from("user_profiles")
                .update(profile)
                .eq("id", value: user.supabaseUserId ?? "")
                .execute()
        } catch {
            print("Failed to update Supabase profile: \(error)")
            // Don't throw - local user is updated, profile sync can retry later
        }
    }

    private func fetchSupabaseProfile(userId: String) async throws -> [String: Any]? {
        do {
            let profile: UserProfile = try await supabase
                .from("user_profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            // Convert to dictionary format for compatibility
            let response: [String: Any] = [
                "display_name": profile.displayName as Any,
                "first_name": profile.firstName as Any,
                "last_name": profile.lastName as Any,
                "preferred_currency": profile.preferredCurrency as Any,
                "biometric_enabled": profile.biometricEnabled as Any,
                "subscription_tier": profile.subscriptionTier as Any,
                "is_email_verified": profile.isEmailVerified as Any
            ]

            return response
        } catch {
            print("Failed to fetch Supabase profile: \(error)")
            return nil
        }
    }
}
