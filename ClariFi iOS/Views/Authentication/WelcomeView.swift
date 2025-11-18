//
//  WelcomeView.swift
//  ClariFi iOS
//
//  Created by Claude on 2025-11-05.
//  Initial authentication screen
//

import SwiftUI

/// Welcome screen for authentication flow
struct WelcomeView: View {

    @Environment(\.diContainer) private var container: DIContainer
    @State private var sessionManager: SessionManager?
    @State private var showRegistration = false
    @State private var showLogin = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.6),
                        Color.purple.opacity(0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // App logo and title
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 80))
                            .foregroundColor(.white)

                        Text("ClariFi")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Your Personal Finance Companion")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Spacer()

                    // Action buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            showRegistration = true
                        }) {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(16)
                        }

                        Button(action: {
                            showLogin = true
                        }) {
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

                        // Privacy note
                        Text("Your financial data stays private and secure")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
            .sheet(isPresented: $showRegistration) {
                let authService = container.resolve(AuthenticationServiceProtocol.self)
                RegistrationView(authService: authService)
            }
            .sheet(isPresented: $showLogin) {
                let authService = container.resolve(AuthenticationServiceProtocol.self)
                LoginView(authService: authService)
            }
            .onAppear {
                // Initialize session manager to observe authentication state
                sessionManager = container.resolve(SessionManager.self)
            }
            .onChange(of: sessionManager?.isAuthenticated) { isAuthenticated in
                // Dismiss login/registration sheets when user authenticates
                if isAuthenticated == true {
                    showLogin = false
                    showRegistration = false
                }
            }
        }
    }
}

// MARK: - Preview

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
