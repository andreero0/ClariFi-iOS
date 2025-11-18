//
//  SessionManager.swift
//  ClariFi iOS
//
//  Created by Claude on 2025-11-05.
//  Manages user authentication sessions and token lifecycle
//

import Foundation
import Supabase
import Combine

/// Manages authentication sessions, token storage, and automatic refresh
@MainActor
class SessionManager: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUserId: String?
    @Published private(set) var currentUserEmail: String?

    // MARK: - Private Properties

    private let supabase: SupabaseClient
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // Refresh token 5 minutes before expiry
    private let tokenRefreshBuffer: TimeInterval = 5 * 60

    // MARK: - Initialization

    init(supabase: SupabaseClient) {
        self.supabase = supabase
        restoreSession()
    }

    // MARK: - Session Management

    /// Store a new session after successful authentication
    /// - Parameters:
    ///   - session: The Supabase session to store
    /// - Throws: KeychainError if storage fails
    func storeSession(_ session: Session) throws {
        try KeychainHelper.store(key: KeychainHelper.AuthKeys.accessToken, value: session.accessToken)
        try KeychainHelper.store(key: KeychainHelper.AuthKeys.refreshToken, value: session.refreshToken)
        try KeychainHelper.store(key: KeychainHelper.AuthKeys.userId, value: session.user.id.uuidString)

        if let email = session.user.email {
            try KeychainHelper.store(key: KeychainHelper.AuthKeys.userEmail, value: email)
        }

        currentUserId = session.user.id.uuidString
        currentUserEmail = session.user.email
        isAuthenticated = true

        // Convert TimeInterval to Date
        let expiresAt = Date(timeIntervalSince1970: session.expiresAt)
        scheduleTokenRefresh(expiresAt: expiresAt)
    }

    /// Restore session from keychain on app launch
    func restoreSession() {
        do {
            guard let _ = try KeychainHelper.retrieve(key: KeychainHelper.AuthKeys.accessToken),
                  let _ = try KeychainHelper.retrieve(key: KeychainHelper.AuthKeys.refreshToken),
                  let userId = try KeychainHelper.retrieve(key: KeychainHelper.AuthKeys.userId) else {
                isAuthenticated = false
                return
            }

            currentUserId = userId
            currentUserEmail = try? KeychainHelper.retrieve(key: KeychainHelper.AuthKeys.userEmail)
            isAuthenticated = true

            // Attempt to refresh the session to ensure it's still valid
            Task {
                do {
                    try await refreshSession()
                } catch {
                    print("Failed to refresh session on restore: \(error)")
                    try? clearSession()
                }
            }
        } catch {
            print("Failed to restore session: \(error)")
            isAuthenticated = false
        }
    }

    /// Refresh the current session using the refresh token
    /// - Throws: Authentication error if refresh fails
    func refreshSession() async throws {
        guard let refreshToken = try KeychainHelper.retrieve(key: KeychainHelper.AuthKeys.refreshToken) else {
            throw AuthenticationError.noRefreshToken
        }

        do {
            let session = try await supabase.auth.refreshSession(refreshToken: refreshToken)
            try storeSession(session)
        } catch {
            print("Session refresh failed: \(error)")
            try clearSession()
            throw AuthenticationError.sessionExpired
        }
    }

    /// Clear the current session (logout)
    func clearSession() throws {
        try KeychainHelper.delete(key: KeychainHelper.AuthKeys.accessToken)
        try KeychainHelper.delete(key: KeychainHelper.AuthKeys.refreshToken)
        try KeychainHelper.delete(key: KeychainHelper.AuthKeys.userId)
        try KeychainHelper.delete(key: KeychainHelper.AuthKeys.userEmail)

        currentUserId = nil
        currentUserEmail = nil
        isAuthenticated = false

        cancelTokenRefresh()
    }

    /// Get the current access token
    /// - Returns: Access token string if available
    /// - Throws: KeychainError if retrieval fails
    func getAccessToken() throws -> String? {
        return try KeychainHelper.retrieve(key: KeychainHelper.AuthKeys.accessToken)
    }

    /// Check if the session is valid
    /// - Returns: true if session exists and is valid
    func isSessionValid() async -> Bool {
        guard isAuthenticated else { return false }

        do {
            _ = try await supabase.auth.session
            return true
        } catch {
            return false
        }
    }

    // MARK: - Token Refresh Scheduling

    /// Schedule automatic token refresh before expiration
    /// - Parameter expiresAt: Token expiration timestamp
    private func scheduleTokenRefresh(expiresAt: Date) {
        cancelTokenRefresh()

        let refreshAt = expiresAt.addingTimeInterval(-tokenRefreshBuffer)
        let timeUntilRefresh = refreshAt.timeIntervalSinceNow

        guard timeUntilRefresh > 0 else {
            // Token expires very soon, refresh immediately
            Task {
                try? await refreshSession()
            }
            return
        }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: timeUntilRefresh, repeats: false) { [weak self] _ in
            Task { @MainActor in
                try? await self?.refreshSession()
            }
        }
    }

    /// Cancel scheduled token refresh
    nonisolated private func cancelTokenRefresh() {
        MainActor.assumeIsolated {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }

    // MARK: - Cleanup

    deinit {
        cancelTokenRefresh()
    }
}

// MARK: - Authentication Errors

enum AuthenticationError: Error, LocalizedError {
    case noRefreshToken
    case sessionExpired
    case invalidCredentials
    case emailNotVerified
    case userNotFound
    case networkError
    case weakPassword
    case emailAlreadyInUse
    case invalidEmail
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noRefreshToken:
            return "No refresh token available"
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailNotVerified:
            return "Please verify your email address"
        case .userNotFound:
            return "User account not found"
        case .networkError:
            return "Network connection error. Please try again."
        case .weakPassword:
            return "Password must be at least 8 characters with uppercase, lowercase, number, and special character"
        case .emailAlreadyInUse:
            return "This email is already registered"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
