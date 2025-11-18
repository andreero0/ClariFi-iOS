//
//  ContentView.swift
//  ClariFi iOS
//
//  Created by aEro on 2025-10-10.
//  Updated by Claude on 2025-11-05 - User authentication integration ready
//  ⚠️ Authentication flow is implemented but commented out until setup is complete
//  📄 See AUTHENTICATION_SETUP_GUIDE.md for instructions to enable
//

import SwiftUI
import CoreData
import Supabase

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.diContainer) private var container
    @Environment(\.scenePhase) private var scenePhase

    @State private var sessionManager: SessionManager?
    @State private var showOnboarding = !OnboardingViewModel.hasCompletedOnboarding()
    @State private var isAuthenticated = false
    @State private var showAuthenticationView = false
    @State private var showWelcome = false
    @State private var isLoading = true

    private let biometricService = BiometricAuthService.shared

    var body: some View {
        Group {
            if isLoading || sessionManager == nil {
                // Loading state while checking user authentication
                LoadingView()
                    .transition(.opacity)
            } else if sessionManager?.isAuthenticated == false {
                // User not signed in - show welcome screen
                WelcomeView()
                    .transition(.opacity)
            } else if showOnboarding {
                // User signed in but needs onboarding
                OnboardingView(isPresented: $showOnboarding, container: container as! AppDIContainer)
                    .environment(\.managedObjectContext, viewContext)
                    .transition(.opacity)
            } else if showAuthenticationView {
                // User signed in, onboarded, but needs biometric auth
                BiometricAuthenticationView(isAuthenticated: $isAuthenticated)
                    .transition(.opacity)
            } else if isAuthenticated {
                // Fully authenticated - show main app
                MainTabView()
                    .environment(\.managedObjectContext, viewContext)
                    .transition(.opacity)
            } else {
                // Loading state
                Color.clear
            }
        }
        .animation(.easeInOut, value: isLoading)
        .animation(.easeInOut, value: sessionManager?.isAuthenticated)
        .animation(.easeInOut, value: showOnboarding)
        .animation(.easeInOut, value: showAuthenticationView)
        .animation(.easeInOut, value: isAuthenticated)
        .onAppear {
            // Initialize session manager from DI container
            sessionManager = container.resolve(SessionManager.self)
            checkUserAuthentication()
        }
        .onChange(of: sessionManager?.isAuthenticated) { sessionIsAuthenticated in
            // When user signs in/out, update app state
            if sessionIsAuthenticated == true {
                checkUserAuthentication()
            } else if sessionIsAuthenticated == false {
                // User signed out
                showWelcome = true
                isAuthenticated = false
                showAuthenticationView = false
            }
        }
        .onChange(of: scenePhase) { newPhase in
            // Require authentication when app becomes active after being backgrounded
            if newPhase == .active {
                checkUserAuthentication()
            } else if newPhase == .background {
                // Invalidate biometric authentication when app goes to background
                biometricService.invalidateAuthentication()
                if biometricService.isBiometricEnabled {
                    isAuthenticated = false
                }
            }
        }
    }

    private func checkUserAuthentication() {
        Task {
            // Check if user has valid session
            guard let sessionManager = sessionManager, sessionManager.isAuthenticated else {
                await MainActor.run {
                    isLoading = false
                    showWelcome = true
                }
                return
            }

            // User is signed in, check onboarding status
            await MainActor.run {
                if showOnboarding {
                    // Still needs onboarding
                    isLoading = false
                    isAuthenticated = true
                    return
                }

                // Check if biometric authentication is required
                if biometricService.isAuthenticationRequired() {
                    showAuthenticationView = true
                    isAuthenticated = false
                    isLoading = false
                } else {
                    // Authentication not required or already authenticated
                    showAuthenticationView = false
                    isAuthenticated = true
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("ClariFi")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                ProgressView()
                    .scaleEffect(1.2)
            }
        }
    }
}

// MARK: - Biometric Authentication View

struct BiometricAuthenticationView: View {
    @Binding var isAuthenticated: Bool
    @State private var authenticationError: String?
    @State private var isAuthenticating = false

    private let biometricService = BiometricAuthService.shared

    var body: some View {
        ZStack {
            // Background blur for security
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // App icon and title
                VStack(spacing: 16) {
                    Image(systemName: biometricService.biometricType().iconName)
                        .font(.system(size: 80))
                        .foregroundStyle(.blue.gradient)

                    Text("ClariFi")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Authenticate to access your financial data")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Authentication button
                VStack(spacing: 16) {
                    if isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    } else {
                        Button(action: authenticate) {
                            Label(
                                "Authenticate with \(biometricService.biometricType().displayName)",
                                systemImage: biometricService.biometricType().iconName
                            )
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)

                        // Show error if authentication failed
                        if let error = authenticationError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Automatically trigger authentication when view appears
            authenticate()
        }
    }

    private func authenticate() {
        isAuthenticating = true
        authenticationError = nil

        Task {
            do {
                let success = try await biometricService.authenticate()
                await MainActor.run {
                    if success {
                        isAuthenticated = true
                    } else {
                        authenticationError = "Authentication failed. Please try again."
                    }
                    isAuthenticating = false
                }
            } catch BiometricAuthError.notEnabled {
                // If biometric is not enabled, allow access
                await MainActor.run {
                    isAuthenticated = true
                    isAuthenticating = false
                }
            } catch {
                await MainActor.run {
                    authenticationError = error.localizedDescription
                    isAuthenticating = false
                }
            }
        }
    }
}

#Preview("Main App") {
    let container = AppDIContainer.createPreviewContainer()
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .withDIContainer(container)
}

// Simple preview for faster loading
#Preview("Simple Home") {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppState())
}
