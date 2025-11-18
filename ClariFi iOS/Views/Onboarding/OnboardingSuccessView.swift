//
//  OnboardingSuccessView.swift
//  ClariFi iOS
//
//  Success celebration view shown after completing onboarding
//

import SwiftUI

struct OnboardingSuccessView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    let onGetStarted: () -> Void
    
    @State private var showCheckmark = false
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated Checkmark
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showCheckmark ? 1.0 : 0.5)
                    .opacity(showCheckmark ? 1.0 : 0.0)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green.gradient)
                    .scaleEffect(showCheckmark ? 1.0 : 0.5)
                    .opacity(showCheckmark ? 1.0 : 0.0)
            }
            .accessibilityHidden(true)
            
            // Success Message
            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0.0)
                
                Text("Your ClariFi account is ready to use")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(showContent ? 1.0 : 0.0)
            }
            
            Spacer()
            
            // Setup Summary
            if showContent {
                VStack(spacing: 16) {
                    Text("What's Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        if let firstAction = coordinator.selectedFirstAction {
                            NextStepCard(
                                icon: firstAction.icon,
                                title: firstAction.title,
                                description: "We'll help you get started with this",
                                isPrimary: true
                            )
                        }
                        
                        NextStepCard(
                            icon: "chart.bar.fill",
                            title: "Track Your Spending",
                            description: "See where your money goes in real-time",
                            isPrimary: false
                        )
                        
                        NextStepCard(
                            icon: "lightbulb.fill",
                            title: "Get Smart Insights",
                            description: "Receive personalized financial recommendations",
                            isPrimary: false
                        )
                    }
                    .padding(.horizontal)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            Spacer()
            
            // Get Started Button
            if showContent {
                Button(action: onGetStarted) {
                    HStack {
                        Text("Get Started")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
                .accessibilityLabel("Get started with ClariFi")
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            // Animate checkmark
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showCheckmark = true
            }
            
            // Show content after checkmark
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showContent = true
                }
            }
        }
    }
}

// MARK: - Next Step Card
struct NextStepCard: View {
    let icon: String
    let title: String
    let description: String
    let isPrimary: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(isPrimary ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isPrimary ? .blue : .secondary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            if isPrimary {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPrimary ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Celebration Confetti (Optional Enhancement)
struct ConfettiView: View {
    @State private var animate = false
    let colors: [Color] = [.blue, .green, .yellow, .orange, .red, .purple]
    
    var body: some View {
        ZStack {
            ForEach(0..<20) { index in
                Circle()
                    .fill(colors[index % colors.count])
                    .frame(width: 10, height: 10)
                    .offset(
                        x: animate ? CGFloat.random(in: -200...200) : 0,
                        y: animate ? CGFloat.random(in: -400...400) : 0
                    )
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animate = true
            }
        }
    }
}

// MARK: - Preview
#Preview("Success View - With First Action") {
    let coordinator = OnboardingCoordinator()
    coordinator.selectedFirstAction = .uploadStatement
    coordinator.createdAccounts = [AccountSetupData.sampleChecking]
    coordinator.enableBiometric = true
    
    return OnboardingSuccessView(
        coordinator: coordinator,
        onGetStarted: {}
    )
}

#Preview("Success View - No First Action") {
    let coordinator = OnboardingCoordinator()
    coordinator.createdAccounts = [AccountSetupData.sampleChecking]
    
    return OnboardingSuccessView(
        coordinator: coordinator,
        onGetStarted: {}
    )
}

#Preview("Next Step Card - Primary") {
    NextStepCard(
        icon: "doc.text.viewfinder",
        title: "Upload a Statement",
        description: "We'll help you get started with this",
        isPrimary: true
    )
    .padding()
}

#Preview("Next Step Card - Secondary") {
    NextStepCard(
        icon: "chart.bar.fill",
        title: "Track Your Spending",
        description: "See where your money goes in real-time",
        isPrimary: false
    )
    .padding()
}
