//
//  OnboardingView.swift
//  ClariFi iOS
//
//  Onboarding flow for first-time users
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: OnboardingViewModel
    @StateObject private var coordinator = OnboardingCoordinator()
    @Binding var isPresented: Bool
    
    private var stepBinding: Binding<OnboardingStep> {
        Binding(
            get: { coordinator.currentStep },
            set: { newValue in coordinator.requestStepChange(to: newValue) }
        )
    }
    
    init(isPresented: Binding<Bool>, container: AppDIContainer) {
        self._isPresented = isPresented
        let securityAudit = container.resolve(SecurityAuditService.self)
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(securityAudit: securityAudit))
    }
    
    var body: some View {
        TabView(selection: stepBinding) {
            WelcomePageView()
                .tag(OnboardingStep.welcome)
            
            PrivacyPageView(selectedMode: $coordinator.selectedProcessingMode)
                .tag(OnboardingStep.privacy)
            
            FeaturesPageView()
                .tag(OnboardingStep.features)
            
            AccountSetupStepView(coordinator: coordinator)
                .tag(OnboardingStep.accountSetup)
            
            BiometricSetupPageView(enableBiometric: $coordinator.enableBiometric)
                .tag(OnboardingStep.biometric)
            
            QuickStartView(coordinator: coordinator)
                .tag(OnboardingStep.quickStart)
            
            FirstActionGuidanceView(coordinator: coordinator)
                .tag(OnboardingStep.firstAction)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .ignoresSafeArea()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AccessibilityLabels.onboardingProgress)
        .accessibilityValue("Step \(coordinator.currentStepIndex + 1) of \(coordinator.totalSteps)")
        .accessibilityHint(AccessibilityHints.onboardingNextStep)
        .onAppear {
            Analytics.track(.onboardingStarted)
            
            // Announce onboarding start for VoiceOver users
            if AccessibilityTesting.isVoiceOverRunning {
                AccessibilityAnnouncement.announce(
                    "Welcome to ClariFi onboarding. \(coordinator.totalSteps) steps to complete.",
                    delay: 0.5
                )
            }
        }
        .onChange(of: coordinator.currentStep) { newStep in
            Analytics.track(.screenViewed, properties: [
                "screen_name": "onboarding_\(newStep.title.lowercased().replacingOccurrences(of: " ", with: "_"))",
                "step_number": newStep.rawValue
            ])
            
            // Announce step change for VoiceOver users
            if AccessibilityTesting.isVoiceOverRunning {
                AccessibilityAnnouncement.announceScreenChange()
                AccessibilityAnnouncement.announce(
                    "\(newStep.title). Step \(newStep.rawValue + 1) of \(coordinator.totalSteps)",
                    delay: 0.3
                )
            }
        }
        .onChange(of: coordinator.isComplete) { isComplete in
            if isComplete {
                Task {
                    await viewModel.completeOnboarding(
                        context: viewContext,
                        coordinator: coordinator
                    )
                    Analytics.track(.onboardingCompleted, properties: [
                        "processing_mode": coordinator.selectedProcessingMode == .localOnly ? "local" : "cloud",
                        "biometric_enabled": coordinator.enableBiometric,
                        "accounts_created": coordinator.createdAccounts.count,
                        "first_action": coordinator.selectedFirstAction?.rawValue ?? "none"
                    ])
                    isPresented = false
                }
            }
        }
        .overlay {
            if viewModel.isCreatingAccounts {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text(viewModel.accountCreationProgress)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(40)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(radius: 20)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isCreatingAccounts)
            }
        }
    }
}

// MARK: - Welcome Page
struct WelcomePageView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.blue.gradient)
                .accessibilityHidden(true)
            
            VStack(spacing: 16) {
                Text("Welcome to ClariFi")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Take control of your finances with privacy-first budgeting")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                FeatureBadge(icon: "lock.shield.fill", text: "Privacy First")
                FeatureBadge(icon: "wifi.slash", text: "Works Offline")
                FeatureBadge(icon: "chart.bar.fill", text: "Smart Insights")
            }
            .padding(.horizontal)
            
            Spacer()
            
            Text("Swipe to continue")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 40)
                .accessibilityHidden(true)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(AccessibilityLabels.onboardingWelcome)
        .accessibilityValue("Take control of your finances with privacy-first budgeting. Features include: Privacy First, Works Offline, and Smart Insights.")
        .accessibilityHint(AccessibilityHints.onboardingWelcome)
    }
}

// MARK: - Privacy Page
struct PrivacyPageView: View {
    @Binding var selectedMode: ProcessingMode
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "shield.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green.gradient)
                .accessibilityHidden(true)
            
            VStack(spacing: 16) {
                Text("Your Privacy Matters")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("All your financial data stays on your device by default")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                ProcessingModeCard(
                    mode: .localOnly,
                    isSelected: selectedMode == .localOnly,
                    onSelect: { selectedMode = .localOnly }
                )
                
                ProcessingModeCard(
                    mode: .cloudOptIn,
                    isSelected: selectedMode == .cloudOptIn,
                    onSelect: { selectedMode = .cloudOptIn }
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            Text("You can change this anytime in Privacy settings")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 40)
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AccessibilityLabels.onboardingPrivacy)
        .accessibilityHint(AccessibilityHints.onboardingPrivacy)
    }
}

// MARK: - Features Page
struct FeaturesPageView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Powerful Features")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
            
            VStack(spacing: 24) {
                FeatureRow(
                    icon: "doc.text.viewfinder",
                    title: "Smart Statement Upload",
                    description: "Scan bank statements with OCR - no account linking required"
                )
                
                FeatureRow(
                    icon: "plus.circle.fill",
                    title: "Manual Entry",
                    description: "Track cash purchases with smart autocomplete"
                )
                
                FeatureRow(
                    icon: "target",
                    title: "Custom Budgets",
                    description: "Create budgets that fit your lifestyle with templates"
                )
                
                FeatureRow(
                    icon: "lightbulb.fill",
                    title: "Smart Insights",
                    description: "Get actionable recommendations to improve your finances"
                )
                
                FeatureRow(
                    icon: "tag.fill",
                    title: "Auto-Categorization",
                    description: "Transactions are automatically categorized and learn from you"
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            Text("Swipe to continue")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 40)
        }
        .padding()
    }
}

// MARK: - Biometric Setup Page
struct BiometricSetupPageView: View {
    @Binding var enableBiometric: Bool
    // State Management: Using direct property access for singleton service.
    // @StateObject should not be used for singletons as they manage their own lifecycle.
    private let biometricService = BiometricAuthService.shared
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: biometricIcon)
                .font(.system(size: 80))
                .foregroundStyle(.purple.gradient)
                .accessibilityHidden(true)
            
            VStack(spacing: 16) {
                Text("Secure Your Data")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Use \(biometricType) to protect your financial information")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            if biometricService.biometricType() != .none {
                VStack(spacing: 20) {
                    Toggle(isOn: $enableBiometric) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enable \(biometricType)")
                                .font(.headline)
                            
                            Text("Require authentication when opening the app")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    Text("Recommended for added security")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    
                    Text("Biometric authentication is not available on this device")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("You can still use ClariFi securely with device passcode protection")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            Text("You can change this anytime in Settings")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 40)
        }
        .padding()
    }
    
    private var biometricType: String {
        switch biometricService.biometricType() {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Biometric Authentication"
        @unknown default:
            return "Biometric Authentication"
        }
    }
    
    private var biometricIcon: String {
        switch biometricService.biometricType() {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.fill"
        @unknown default:
            return "lock.fill"
        }
    }
}

// MARK: - Get Started Page
struct GetStartedPageView: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.green.gradient)
                .accessibilityHidden(true)
            
            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Start tracking your finances with complete privacy and control")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                QuickActionCard(
                    icon: "doc.text.viewfinder",
                    title: "Upload a Statement",
                    description: "Scan your bank statement to get started quickly"
                )
                
                QuickActionCard(
                    icon: "plus.circle.fill",
                    title: "Add Transactions Manually",
                    description: "Enter transactions one by one for full control"
                )
                
                QuickActionCard(
                    icon: "target",
                    title: "Create Your First Budget",
                    description: "Set spending goals with our budget templates"
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: onComplete) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
            .accessibilityLabel("Get Started with ClariFi")
            .accessibilityHint("Completes onboarding and opens the main app")
        }
        .padding()
    }
}

// MARK: - Supporting Views
struct FeatureBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.headline)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ProcessingModeCard: View {
    let mode: ProcessingMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: mode == .localOnly ? "iphone" : "icloud")
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .secondary)
                    
                    Text(mode == .localOnly ? "Local Only" : "Cloud Enhanced")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                Text(mode == .localOnly
                     ? "All processing happens on your device. Maximum privacy, no internet required."
                     : "Optional cloud features with end-to-end encryption. Enhanced insights and sync.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview("Onboarding Flow") {
    OnboardingView(isPresented: .constant(true), container: AppDIContainer.createPreviewContainer() as! AppDIContainer)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("Welcome Page") {
    WelcomePageView()
}

#Preview("Privacy Page") {
    PrivacyPageView(selectedMode: .constant(.localOnly))
}

#Preview("Features Page") {
    FeaturesPageView()
}

#Preview("Biometric Setup") {
    BiometricSetupPageView(enableBiometric: .constant(true))
}

#Preview("Get Started") {
    GetStartedPageView(onComplete: {})
}
