//
//  FirstActionGuidanceView.swift
//  ClariFi iOS
//
//  Guidance view for first action after onboarding
//

import SwiftUI

struct FirstActionGuidanceView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green.gradient)
                    .accessibilityHidden(true)
                
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Let's get you started with ClariFi")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Setup Summary
            SetupSummaryCard(coordinator: coordinator)
                .padding(.horizontal)
            
            // Guidance Content
            if let action = coordinator.selectedFirstAction {
                GuidanceContent(actionType: action)
                    .padding(.horizontal)
            } else {
                NoActionSelectedContent()
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                if coordinator.selectedFirstAction != nil {
                    Button(action: {
                        coordinator.advance()
                    }) {
                        HStack {
                            Text("Let's Go!")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .accessibilityLabel("Complete onboarding and start first action")
                } else {
                    Button(action: {
                        coordinator.advance()
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .accessibilityLabel("Complete onboarding")
                }
                
                Button(action: {
                    coordinator.goBack()
                }) {
                    Text("Go Back")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Go back to previous step")
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Setup Summary Card
struct SetupSummaryCard: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Setup")
                .font(.headline)
                .foregroundColor(.primary)
            
            Divider()
            
            // Accounts
            HStack {
                Image(systemName: "building.columns.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Accounts")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(coordinator.createdAccounts.count) account\(coordinator.createdAccounts.count == 1 ? "" : "s") created")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Privacy Mode
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Privacy")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(coordinator.selectedProcessingMode == .localOnly ? "Local Only" : "Cloud Enhanced")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Biometric
            HStack {
                Image(systemName: coordinator.enableBiometric ? "faceid" : "lock.fill")
                    .foregroundColor(.purple)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Security")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(coordinator.enableBiometric ? "Biometric enabled" : "Device passcode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Guidance Content
struct GuidanceContent: View {
    let actionType: FirstActionType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: actionType.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Next: \(actionType.title)")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                switch actionType {
                case .uploadStatement:
                    GuidanceTip(
                        icon: "1.circle.fill",
                        text: "Take a photo of your bank statement or select from your photos"
                    )
                    GuidanceTip(
                        icon: "2.circle.fill",
                        text: "Our OCR will extract transactions automatically"
                    )
                    GuidanceTip(
                        icon: "3.circle.fill",
                        text: "Review and confirm the imported transactions"
                    )
                    
                case .manualEntry:
                    GuidanceTip(
                        icon: "1.circle.fill",
                        text: "Enter the transaction amount and merchant name"
                    )
                    GuidanceTip(
                        icon: "2.circle.fill",
                        text: "Select a category or let us suggest one"
                    )
                    GuidanceTip(
                        icon: "3.circle.fill",
                        text: "Add notes if needed and save"
                    )
                    
                case .createBudget:
                    GuidanceTip(
                        icon: "1.circle.fill",
                        text: "Choose a budget template that fits your lifestyle"
                    )
                    GuidanceTip(
                        icon: "2.circle.fill",
                        text: "Customize spending limits for each category"
                    )
                    GuidanceTip(
                        icon: "3.circle.fill",
                        text: "Start tracking your spending against your budget"
                    )
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - No Action Selected Content
struct NoActionSelectedContent: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Explore at Your Own Pace")
                .font(.headline)
            
            Text("You can start with any feature from the main screen. We recommend uploading a statement or adding a transaction to get started.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Guidance Tip
struct GuidanceTip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview("First Action Guidance - Upload Statement") {
    let coordinator = OnboardingCoordinator()
    coordinator.selectedFirstAction = .uploadStatement
    coordinator.createdAccounts = [AccountSetupData.sampleChecking]
    coordinator.enableBiometric = true

    return FirstActionGuidanceView(
        coordinator: coordinator
    )
}

#Preview("First Action Guidance - Manual Entry") {
    let coordinator = OnboardingCoordinator()
    coordinator.selectedFirstAction = .manualEntry
    coordinator.createdAccounts = AccountSetupData.samples

    return FirstActionGuidanceView(
        coordinator: coordinator
    )
}

#Preview("First Action Guidance - No Selection") {
    let coordinator = OnboardingCoordinator()
    coordinator.createdAccounts = [AccountSetupData.sampleChecking]

    return FirstActionGuidanceView(
        coordinator: coordinator
    )
}
