//
//  OnboardingNavigationBar.swift
//  ClariFi iOS
//
//  Custom navigation bar for onboarding to prevent validation bypass via swipe
//

import SwiftUI

struct OnboardingNavigationBar: View {
    @ObservedObject var coordinator: OnboardingCoordinator

    var body: some View {
        VStack(spacing: 0) {
            // Navigation buttons
            HStack {
                // Back button
                if coordinator.currentStep.rawValue > 0 {
                    Button(action: {
                        coordinator.goBack()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.body)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .accessibilityLabel("Go back to previous step")
                } else {
                    Spacer()
                        .frame(width: 80)
                }

                Spacer()

                // Progress indicator
                Text("Step \(coordinator.currentStepIndex + 1) of \(coordinator.totalSteps)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                // Next/Finish button
                if coordinator.currentStep.rawValue < coordinator.totalSteps - 1 {
                    Button(action: {
                        coordinator.advance()
                    }) {
                        HStack(spacing: 4) {
                            Text("Next")
                                .font(.body)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .accessibilityLabel("Go to next step")
                } else {
                    Button(action: {
                        coordinator.advance()
                    }) {
                        Text("Finish")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .accessibilityLabel("Complete onboarding")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 3)

                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * coordinator.progress, height: 3)
                        .animation(.easeInOut(duration: 0.3), value: coordinator.progress)
                }
            }
            .frame(height: 3)
        }
        .background(Color(.systemBackground).opacity(0.95))
    }
}

#Preview("Navigation Bar - First Step") {
    OnboardingNavigationBar(coordinator: OnboardingCoordinator())
        .previewLayout(.sizeThatFits)
}

#Preview("Navigation Bar - Middle Step") {
    let coordinator = OnboardingCoordinator()
    coordinator.currentStep = .accountSetup
    return OnboardingNavigationBar(coordinator: coordinator)
        .previewLayout(.sizeThatFits)
}

#Preview("Navigation Bar - Last Step") {
    let coordinator = OnboardingCoordinator()
    coordinator.currentStep = .firstAction
    return OnboardingNavigationBar(coordinator: coordinator)
        .previewLayout(.sizeThatFits)
}
