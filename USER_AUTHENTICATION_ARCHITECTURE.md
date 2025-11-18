# User Authentication System - Complete Architecture

## Executive Summary

**Goal:** Transform ClariFi from a single-device, anonymous app to a multi-user, multi-device financial platform with proper user accounts.

**Scope:**
- ✅ User registration (email + password)
- ✅ User login/logout
- ✅ User profiles (name, email, settings)
- ✅ Core Data User entity
- ✅ Multi-device support (via Supabase)
- ✅ Password reset functionality
- ✅ Email verification
- ✅ Secure session management

## 1. Architecture Overview

### Current State → Target State

**Before (Anonymous):**
```
App Launch
    ↓
Onboarding (one-time)
    ↓
Main App (local data only)
```

**After (User-Based):**
```
App Launch
    ↓
Check Authentication State
    ├─ Not Logged In → Welcome Screen
    │       ↓
    │   Registration / Login
    │       ↓
    │   Onboarding (for new users)
    │       ↓
    │   Main App
    │
    └─ Logged In → Main App (with cloud sync)
```

### Component Architecture

```
┌─────────────────────────────────────────────┐
│            Presentation Layer                │
│  - WelcomeView                               │
│  - RegistrationView                          │
│  - LoginView                                 │
│  - ProfileView                               │
│  - ForgotPasswordView                        │
└─────────────────┬───────────────────────────┘
                  ↓
┌─────────────────────────────────────────────┐
│           ViewModel Layer                    │
│  - AuthenticationViewModel                   │
│  - RegistrationViewModel                     │
│  - ProfileViewModel                          │
└─────────────────┬───────────────────────────┘
                  ↓
┌─────────────────────────────────────────────┐
│            Service Layer                     │
│  - AuthenticationService                     │
│  - UserService                               │
│  - SessionManager                            │
└─────────────────┬───────────────────────────┘
                  ↓
┌─────────────────────────────────────────────┐
│            Data Layer                        │
│  - Core Data (User entity)                   │
│  - Supabase Auth                             │
│  - Keychain (tokens)                         │
└─────────────────────────────────────────────┘
```

## 2. Core Data Schema - User Entity

### User Entity

```swift
@objc(User)
public class User: NSManagedObject {
    @NSManaged public var id: UUID?              // Primary key
    @NSManaged public var email: String?          // Email (unique)
    @NSManaged public var displayName: String?    // Full name
    @NSManaged public var firstName: String?      // First name
    @NSManaged public var lastName: String?       // Last name
    @NSManaged public var phoneNumber: String?    // Optional phone
    @NSManaged public var profileImageURL: String? // Profile photo URL

    // Authentication
    @NSManaged public var supabaseUserId: String? // Supabase auth.users.id
    @NSManaged public var isEmailVerified: Bool   // Email verification status
    @NSManaged public var lastLoginAt: Date?      // Last login timestamp

    // Preferences
    @NSManaged public var preferredCurrency: String? // Default: USD
    @NSManaged public var timezone: String?       // User's timezone
    @NSManaged public var locale: String?         // Language/region

    // Privacy Settings
    @NSManaged public var biometricEnabled: Bool  // Face ID/Touch ID
    @NSManaged public var processingMode: String? // on-device / hybrid

    // Subscription
    @NSManaged public var subscriptionTier: String? // free / premium / pro
    @NSManaged public var subscriptionExpiresAt: Date?

    // Timestamps
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

    // Relationships
    @NSManaged public var accounts: NSSet?         // User's financial accounts
    @NSManaged public var transactions: NSSet?     // User's transactions
    @NSManaged public var budgets: NSSet?          // User's budgets
    @NSManaged public var statements: NSSet?       // User's uploaded statements
}
```

### Updated Entity Relationships

**All existing entities need user relationship:**

```swift
// Transaction entity (updated)
extension Transaction {
    @NSManaged public var user: User?  // ✅ NEW: Link to user
    @NSManaged public var account: Account?
    @NSManaged public var statement: Statement?
}

// Account entity (updated)
extension Account {
    @NSManaged public var user: User?  // ✅ NEW: Link to user
    @NSManaged public var transactions: NSSet?
}

// Budget entity (updated)
extension Budget {
    @NSManaged public var user: User?  // ✅ NEW: Link to user
    @NSManaged public var categories: NSSet?
}

// Statement entity (updated)
extension Statement {
    @NSManaged public var user: User?  // ✅ NEW: Link to user
    @NSManaged public var transactions: NSSet?
}
```

## 3. Supabase Authentication Integration

### Supabase Setup

**Authentication Methods:**
- ✅ Email + Password (primary)
- ✅ Magic Link (passwordless)
- 🔜 Social OAuth (Google, Apple Sign-In)
- 🔜 Two-Factor Authentication (2FA)

**Database Schema:**

```sql
-- Supabase auth.users table (built-in)
-- id, email, encrypted_password, email_confirmed_at, etc.

-- User profiles table (extends auth.users)
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    first_name TEXT,
    last_name TEXT,
    phone_number TEXT,
    profile_image_url TEXT,

    -- Preferences
    preferred_currency TEXT DEFAULT 'USD',
    timezone TEXT,
    locale TEXT,

    -- Privacy
    biometric_enabled BOOLEAN DEFAULT false,
    processing_mode TEXT DEFAULT 'on-device',

    -- Subscription
    subscription_tier TEXT DEFAULT 'free',
    subscription_expires_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Users can only access their own profile
CREATE POLICY "Users can access own profile"
    ON user_profiles FOR ALL
    USING (auth.uid() = id);

-- Function to create profile on signup
CREATE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, display_name, created_at)
    VALUES (NEW.id, NEW.raw_user_meta_data->>'display_name', NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create profile
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### Authentication Service

```swift
// Services/Authentication/AuthenticationService.swift

import Foundation
import Supabase

protocol AuthenticationServiceProtocol {
    func signUp(email: String, password: String, displayName: String) async throws -> User
    func signIn(email: String, password: String) async throws -> User
    func signOut() async throws
    func resetPassword(email: String) async throws
    func updatePassword(newPassword: String) async throws
    func verifyEmail(token: String) async throws
    func getCurrentUser() async throws -> User?
    func refreshSession() async throws
}

@MainActor
class AuthenticationService: AuthenticationServiceProtocol {

    private let supabase: SupabaseClient
    private let context: NSManagedObjectContext
    private let sessionManager: SessionManager

    init(supabase: SupabaseClient, context: NSManagedObjectContext) {
        self.supabase = supabase
        self.context = context
        self.sessionManager = SessionManager.shared
    }

    // MARK: - Registration

    func signUp(email: String, password: String, displayName: String) async throws -> User {
        // Validate inputs
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        guard isValidPassword(password) else {
            throw AuthError.weakPassword
        }

        // Create Supabase user
        let authResponse = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: ["display_name": displayName]
        )

        guard let session = authResponse.session else {
            throw AuthError.signUpFailed
        }

        // Create local user in Core Data
        let user = User(context: context)
        user.id = UUID()
        user.email = email
        user.displayName = displayName
        user.supabaseUserId = session.user.id.uuidString
        user.isEmailVerified = false
        user.createdAt = Date()
        user.updatedAt = Date()
        user.preferredCurrency = "USD"
        user.biometricEnabled = false
        user.processingMode = "on-device"
        user.subscriptionTier = "free"

        // Save to Core Data
        try context.save()

        // Store session
        try await sessionManager.storeSession(session)

        // Track analytics
        Analytics.track(.userRegistered, properties: [
            "email": email,
            "has_display_name": !displayName.isEmpty
        ])

        return user
    }

    // MARK: - Login

    func signIn(email: String, password: String) async throws -> User {
        // Authenticate with Supabase
        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )

        // Store session
        try await sessionManager.storeSession(session)

        // Fetch or create local user
        let user = try await fetchOrCreateLocalUser(supabaseUserId: session.user.id.uuidString, email: email)

        // Update last login
        user.lastLoginAt = Date()
        user.updatedAt = Date()
        try context.save()

        // Track analytics
        Analytics.track(.userLoggedIn, properties: [
            "email": email
        ])

        return user
    }

    // MARK: - Logout

    func signOut() async throws {
        // Sign out from Supabase
        try await supabase.auth.signOut()

        // Clear session
        await sessionManager.clearSession()

        // Track analytics
        Analytics.track(.userLoggedOut)
    }

    // MARK: - Password Management

    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)

        Analytics.track(.passwordResetRequested, properties: [
            "email": email
        ])
    }

    func updatePassword(newPassword: String) async throws {
        guard isValidPassword(newPassword) else {
            throw AuthError.weakPassword
        }

        try await supabase.auth.update(user: UserAttributes(password: newPassword))

        Analytics.track(.passwordUpdated)
    }

    // MARK: - Email Verification

    func verifyEmail(token: String) async throws {
        try await supabase.auth.verifyOTP(
            token: token,
            type: .email
        )

        // Update local user
        if let user = try await getCurrentUser() {
            user.isEmailVerified = true
            user.updatedAt = Date()
            try context.save()
        }

        Analytics.track(.emailVerified)
    }

    // MARK: - Session Management

    func getCurrentUser() async throws -> User? {
        // Check if we have an active session
        guard let session = try? await supabase.auth.session else {
            return nil
        }

        // Fetch local user from Core Data
        let fetchRequest = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "supabaseUserId == %@", session.user.id.uuidString)
        fetchRequest.fetchLimit = 1

        let users = try context.fetch(fetchRequest)
        return users.first
    }

    func refreshSession() async throws {
        let session = try await supabase.auth.refreshSession()
        try await sessionManager.storeSession(session)
    }

    // MARK: - Private Helpers

    private func fetchOrCreateLocalUser(supabaseUserId: String, email: String) async throws -> User {
        // Try to fetch existing user
        let fetchRequest = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "supabaseUserId == %@", supabaseUserId)
        fetchRequest.fetchLimit = 1

        if let existingUser = try context.fetch(fetchRequest).first {
            return existingUser
        }

        // Create new local user
        let user = User(context: context)
        user.id = UUID()
        user.email = email
        user.supabaseUserId = supabaseUserId
        user.createdAt = Date()
        user.updatedAt = Date()

        try context.save()
        return user
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
        return password.count >= 8 &&
               password.rangeOfCharacter(from: .uppercaseLetters) != nil &&
               password.rangeOfCharacter(from: .lowercaseLetters) != nil &&
               password.rangeOfCharacter(from: .decimalDigits) != nil
    }
}

// MARK: - Authentication Errors

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyExists
    case signUpFailed
    case signInFailed
    case userNotFound
    case wrongPassword
    case sessionExpired
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 8 characters with uppercase, lowercase, and numbers"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .signUpFailed:
            return "Failed to create account. Please try again."
        case .signInFailed:
            return "Failed to sign in. Please check your credentials."
        case .userNotFound:
            return "No account found with this email"
        case .wrongPassword:
            return "Incorrect password"
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .networkError:
            return "Network error. Please check your connection."
        }
    }
}
```

## 4. Session Management

```swift
// Services/Authentication/SessionManager.swift

import Foundation
import Supabase

@MainActor
class SessionManager {
    static let shared = SessionManager()

    private let keychainService = "com.clarifi.session"
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let expiresAtKey = "expiresAt"
    private let userIdKey = "userId"

    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUserId: String?

    private init() {
        // Check for existing session on init
        Task {
            await checkSession()
        }
    }

    // MARK: - Session Storage

    func storeSession(_ session: Session) async throws {
        // Store in Keychain
        try KeychainHelper.store(
            key: accessTokenKey,
            value: session.accessToken,
            service: keychainService
        )

        try KeychainHelper.store(
            key: refreshTokenKey,
            value: session.refreshToken,
            service: keychainService
        )

        try KeychainHelper.store(
            key: expiresAtKey,
            value: String(session.expiresAt),
            service: keychainService
        )

        try KeychainHelper.store(
            key: userIdKey,
            value: session.user.id.uuidString,
            service: keychainService
        )

        // Update state
        isAuthenticated = true
        currentUserId = session.user.id.uuidString
    }

    func getSession() async -> Session? {
        guard let accessToken = try? KeychainHelper.retrieve(key: accessTokenKey, service: keychainService),
              let refreshToken = try? KeychainHelper.retrieve(key: refreshTokenKey, service: keychainService),
              let expiresAtString = try? KeychainHelper.retrieve(key: expiresAtKey, service: keychainService),
              let expiresAt = TimeInterval(expiresAtString),
              let userId = try? KeychainHelper.retrieve(key: userIdKey, service: keychainService) else {
            return nil
        }

        // Check if session is expired
        if Date().timeIntervalSince1970 > expiresAt {
            // Session expired, need to refresh
            return nil
        }

        // Reconstruct session
        // Note: This is a simplified version, actual implementation would use Supabase Session type
        return nil // Return reconstructed session
    }

    func clearSession() async {
        // Remove from Keychain
        try? KeychainHelper.delete(key: accessTokenKey, service: keychainService)
        try? KeychainHelper.delete(key: refreshTokenKey, service: keychainService)
        try? KeychainHelper.delete(key: expiresAtKey, service: keychainService)
        try? KeychainHelper.delete(key: userIdKey, service: keychainService)

        // Update state
        isAuthenticated = false
        currentUserId = nil
    }

    func checkSession() async {
        if let session = await getSession() {
            isAuthenticated = true
            currentUserId = try? KeychainHelper.retrieve(key: userIdKey, service: keychainService)
        } else {
            isAuthenticated = false
            currentUserId = nil
        }
    }
}
```

## 5. User Interface Flow

### Welcome Screen

```swift
// Views/Authentication/WelcomeView.swift

struct WelcomeView: View {
    @StateObject private var viewModel: WelcomeViewModel
    @State private var showRegistration = false
    @State private var showLogin = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // App logo and title
                VStack(spacing: 20) {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.white)

                    Text("ClariFi")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)

                    Text("Privacy-First Financial Clarity")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Action buttons
                VStack(spacing: 16) {
                    Button(action: { showRegistration = true }) {
                        Text("Create Account")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(16)
                    }

                    Button(action: { showLogin = true }) {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                }
                .padding(.horizontal, 32)

                // Terms and privacy
                Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showRegistration) {
            RegistrationView()
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
        }
    }
}
```

### Registration Screen

```swift
// Views/Authentication/RegistrationView.swift

struct RegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: RegistrationViewModel

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Create Your Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Join thousands managing their finances securely")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 32)

                    // Form fields
                    VStack(spacing: 16) {
                        // Display name
                        TextField("Full Name", text: $displayName)
                            .textContentType(.name)
                            .autocapitalization(.words)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        // Email
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        // Password
                        SecureField("Password", text: $password)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        // Password requirements
                        if !password.isEmpty {
                            PasswordStrengthView(password: password)
                        }

                        // Confirm password
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("Passwords do not match")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)

                    // Terms agreement
                    Toggle(isOn: $agreedToTerms) {
                        Text("I agree to the Terms of Service and Privacy Policy")
                            .font(.subheadline)
                    }
                    .padding(.horizontal)

                    // Register button
                    Button(action: { register() }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Create Account")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(canRegister ? Color.blue : Color.gray)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(!canRegister || viewModel.isLoading)

                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    // Sign in link
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.secondary)
                        Button("Sign In") {
                            dismiss()
                        }
                        .foregroundColor(.blue)
                    }
                    .font(.subheadline)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var canRegister: Bool {
        !displayName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 8 &&
        agreedToTerms
    }

    private func register() {
        Task {
            await viewModel.register(
                email: email,
                password: password,
                displayName: displayName
            )

            if viewModel.registrationSuccess {
                dismiss()
            }
        }
    }
}

// Password strength indicator
struct PasswordStrengthView: View {
    let password: String

    private var strength: PasswordStrength {
        PasswordValidator.calculateStrength(password)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    Rectangle()
                        .fill(index < strength.bars ? strength.color : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }

            Text(strength.text)
                .font(.caption)
                .foregroundColor(strength.color)
        }
        .padding(.horizontal)
    }
}

struct PasswordStrength {
    let bars: Int
    let text: String
    let color: Color
}

class PasswordValidator {
    static func calculateStrength(_ password: String) -> PasswordStrength {
        var score = 0

        if password.count >= 8 { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { score += 1 }

        switch score {
        case 0...1:
            return PasswordStrength(bars: 1, text: "Weak", color: .red)
        case 2:
            return PasswordStrength(bars: 2, text: "Fair", color: .orange)
        case 3:
            return PasswordStrength(bars: 3, text: "Good", color: .yellow)
        case 4...5:
            return PasswordStrength(bars: 4, text: "Strong", color: .green)
        default:
            return PasswordStrength(bars: 1, text: "Weak", color: .red)
        }
    }
}
```

### Login Screen

```swift
// Views/Authentication/LoginView.swift

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: LoginViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Welcome Back")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 64)

                    // Form
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        Button("Forgot Password?") {
                            showForgotPassword = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal)

                    // Sign in button
                    Button(action: { signIn() }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(canSignIn ? Color.blue : Color.gray)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(!canSignIn || viewModel.isLoading)

                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }

    private var canSignIn: Bool {
        !email.isEmpty && !password.isEmpty
    }

    private func signIn() {
        Task {
            await viewModel.signIn(email: email, password: password)

            if viewModel.loginSuccess {
                dismiss()
            }
        }
    }
}
```

## 6. ViewModels

```swift
// ViewModels/RegistrationViewModel.swift

@MainActor
class RegistrationViewModel: BaseViewModel {
    @Published var isLoading = false
    @Published var registrationSuccess = false
    @Published var errorMessage: String?

    private let authService: AuthenticationServiceProtocol

    init(authService: AuthenticationServiceProtocol) {
        self.authService = authService
        super.init()
    }

    func register(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.signUp(
                email: email,
                password: password,
                displayName: displayName
            )

            registrationSuccess = true

            // Show success message
            NotificationCenter.default.post(
                name: .userRegistered,
                object: user
            )

        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }

        isLoading = false
    }
}

// ViewModels/LoginViewModel.swift

@MainActor
class LoginViewModel: BaseViewModel {
    @Published var isLoading = false
    @Published var loginSuccess = false
    @Published var errorMessage: String?

    private let authService: AuthenticationServiceProtocol

    init(authService: AuthenticationServiceProtocol) {
        self.authService = authService
        super.init()
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.signIn(email: email, password: password)

            loginSuccess = true

            // Show success message
            NotificationCenter.default.post(
                name: .userLoggedIn,
                object: user
            )

        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }

        isLoading = false
    }
}
```

## 7. Updated App Launch Flow

```swift
// ContentView.swift (updated)

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.diContainer) private var container
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var sessionManager = SessionManager.shared
    @State private var showOnboarding = false
    @State private var showAuthenticationView = false
    @State private var isAuthenticated = false

    private let biometricService = BiometricAuthService.shared

    var body: some View {
        Group {
            if !sessionManager.isAuthenticated {
                // User not logged in → Show welcome/login
                WelcomeView()
                    .transition(.opacity)
            } else if showOnboarding {
                // User logged in but hasn't completed onboarding
                OnboardingView(isPresented: $showOnboarding, container: container as! AppDIContainer)
                    .environment(\.managedObjectContext, viewContext)
                    .transition(.opacity)
            } else if showAuthenticationView {
                // User logged in, completed onboarding, but needs biometric auth
                AuthenticationView(isAuthenticated: $isAuthenticated)
                    .transition(.opacity)
            } else if isAuthenticated {
                // User authenticated → Show main app
                MainTabView()
                    .environment(\.managedObjectContext, viewContext)
                    .transition(.opacity)
            } else {
                // Loading state
                LoadingView()
            }
        }
        .animation(.easeInOut, value: sessionManager.isAuthenticated)
        .animation(.easeInOut, value: showOnboarding)
        .animation(.easeInOut, value: showAuthenticationView)
        .animation(.easeInOut, value: isAuthenticated)
        .onAppear {
            checkAuthenticationState()
        }
        .onChange(of: sessionManager.isAuthenticated) { isAuth in
            if isAuth {
                checkOnboardingStatus()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                checkAuthenticationState()
            } else if newPhase == .background {
                biometricService.invalidateAuthentication()
                if biometricService.isBiometricEnabled {
                    isAuthenticated = false
                }
            }
        }
    }

    private func checkAuthenticationState() {
        Task {
            await sessionManager.checkSession()

            if sessionManager.isAuthenticated {
                checkOnboardingStatus()
                checkBiometricAuth()
            }
        }
    }

    private func checkOnboardingStatus() {
        // Check if user has completed onboarding
        showOnboarding = !OnboardingViewModel.hasCompletedOnboarding()
    }

    private func checkBiometricAuth() {
        if biometricService.isAuthenticationRequired() {
            showAuthenticationView = true
            isAuthenticated = false
        } else {
            showAuthenticationView = false
            isAuthenticated = true
        }
    }
}
```

## 8. Implementation Timeline

### Week 1: Core Infrastructure
**Days 1-2: Core Data Schema**
- Create User entity
- Add relationships to existing entities
- Create migration script
- Test schema

**Days 3-4: Authentication Service**
- Implement AuthenticationService
- Implement SessionManager
- Implement KeychainHelper
- Unit tests

**Day 5: Supabase Setup**
- Create database schema
- Set up RLS policies
- Configure email templates
- Test authentication

### Week 2: User Interface
**Days 1-2: Auth Screens**
- WelcomeView
- RegistrationView
- LoginView
- ForgotPasswordView

**Days 3-4: ViewModels**
- RegistrationViewModel
- LoginViewModel
- ProfileViewModel
- Integration tests

**Day 5: App Flow Integration**
- Update ContentView
- Update OnboardingView
- Update DI container
- End-to-end testing

### Week 3: Profile & Settings
**Days 1-2: Profile Management**
- ProfileView
- EditProfileView
- ProfileViewModel
- Photo upload

**Days 3-4: Account Settings**
- Email change flow
- Password change flow
- Delete account flow
- Privacy settings

**Day 5: Polish & Testing**
- UI polish
- Error handling
- Loading states
- User testing

### Week 4: Multi-Device Sync
**Days 1-2: Data Sync**
- Update CloudBackupService for users
- Test cross-device sync
- Conflict resolution

**Days 3-4: Device Management**
- List user's devices
- Remove device
- Transfer data
- Security features

**Day 5: Launch Prep**
- Final testing
- Performance optimization
- Documentation
- Analytics

## 9. Migration Strategy

### Existing Users (Anonymous → Registered)

**Challenge:** Users currently have local data with no user association

**Solution:** Migration on first registration/login

```swift
class UserMigrationService {
    func migrateAnonymousDataToUser(user: User) async throws {
        let context = persistenceController.container.viewContext

        // Fetch all existing data
        let transactions = try await fetchAllTransactions()
        let accounts = try await fetchAllAccounts()
        let budgets = try await fetchAllBudgets()
        let statements = try await fetchAllStatements()

        // Associate with user
        await context.perform {
            for transaction in transactions {
                transaction.user = user
            }
            for account in accounts {
                account.user = user
            }
            for budget in budgets {
                budget.user = user
            }
            for statement in statements {
                statement.user = user
            }

            try? context.save()
        }

        // Upload to cloud
        try await cloudBackupService.backupAllData(strategy: .automatic)

        Analytics.track(.userDataMigrated, properties: [
            "transaction_count": transactions.count,
            "account_count": accounts.count
        ])
    }
}
```

## 10. Security Considerations

### Password Security
- ✅ Minimum 8 characters
- ✅ Requires uppercase, lowercase, numbers
- ✅ Bcrypt hashing (handled by Supabase)
- ✅ Rate limiting on login attempts

### Session Security
- ✅ JWT tokens with expiration
- ✅ Refresh token rotation
- ✅ Tokens stored in Keychain
- ✅ Automatic session refresh

### Email Security
- ✅ Email verification required
- ✅ Secure reset password flow
- ✅ Magic link support
- ✅ Rate limiting on email sends

### Privacy
- ✅ End-to-end encryption for sensitive data
- ✅ Row Level Security in Supabase
- ✅ GDPR compliance (right to be forgotten)
- ✅ Clear privacy policy

## 11. Testing Strategy

### Unit Tests
- AuthenticationService
- SessionManager
- Password validation
- Email validation

### Integration Tests
- Registration flow
- Login flow
- Password reset flow
- Session refresh

### UI Tests
- Complete registration
- Complete login
- Form validation
- Error handling

### E2E Tests
- New user journey
- Returning user journey
- Multi-device sync
- Data migration

---

**Architecture Document Date:** 2025-11-05
**Status:** Ready for Implementation
**Estimated Timeline:** 4 weeks
**Priority:** HIGH - Required for cloud backup and multi-device support
