//
//  QuickStartView.swift
//  ClariFi iOS
//
//  Quick start selection view for onboarding flow
//

import SwiftUI

struct QuickStartView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue.gradient)
                    .accessibilityHidden(true)
                
                Text("How would you like to start?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Choose your first action to get started with ClariFi")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Action Cards
            VStack(spacing: 16) {
                ForEach(FirstActionType.allCases, id: \.self) { actionType in
                    ActionCard(
                        actionType: actionType,
                        isSelected: coordinator.selectedFirstAction == actionType,
                        onSelect: {
                            coordinator.selectFirstAction(actionType)
                        }
                    )
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Navigation Buttons
            VStack(spacing: 12) {
                if coordinator.selectedFirstAction != nil {
                    Button(action: {
                        coordinator.advance()
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .accessibilityLabel("Continue to next step")
                }
                
                Button(action: {
                    coordinator.selectedFirstAction = nil
                    coordinator.advance()
                }) {
                    Text("Skip - I'll choose later")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Skip quick start selection")
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Action Card
struct ActionCard: View {
    let actionType: FirstActionType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: actionType.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(actionType.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(actionType.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(actionType.title). \(actionType.description)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Supporting Views
struct ActionBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }
}

// MARK: - Preview
#Preview("Quick Start - No Selection") {
    QuickStartView(coordinator: OnboardingCoordinator())
}

#Preview("Quick Start - With Selection") {
    let coordinator = OnboardingCoordinator()
    coordinator.selectedFirstAction = .uploadStatement
    return QuickStartView(coordinator: coordinator)
}

#Preview("Action Card - Unselected") {
    ActionCard(
        actionType: .uploadStatement,
        isSelected: false,
        onSelect: {}
    )
    .padding()
}

#Preview("Action Card - Selected") {
    ActionCard(
        actionType: .manualEntry,
        isSelected: true,
        onSelect: {}
    )
    .padding()
}
