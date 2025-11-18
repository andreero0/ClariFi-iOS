//
//  PasswordStrengthView.swift
//  ClariFi iOS
//
//  Created by Claude on 2025-11-05.
//  Password strength indicator component
//

import SwiftUI

/// Visual indicator showing password strength
struct PasswordStrengthView: View {

    let strength: PasswordStrength
    let feedback: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Strength bars
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: index))
                        .frame(height: 4)
                }
            }

            // Strength label and feedback
            HStack {
                Text(strength.description)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(strengthColor)

                Spacer()
            }

            if !feedback.isEmpty {
                Text(feedback)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helper Properties

    private var strengthColor: Color {
        switch strength {
        case .veryWeak:
            return .red
        case .weak:
            return .orange
        case .fair:
            return .yellow
        case .strong:
            return Color(red: 0.5, green: 0.8, blue: 0.3) // Light green
        case .veryStrong:
            return .green
        }
    }

    private func barColor(for index: Int) -> Color {
        if index < strength.rawValue + 1 {
            return strengthColor
        } else {
            return Color.gray.opacity(0.2)
        }
    }
}

// MARK: - Preview

struct PasswordStrengthView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PasswordStrengthView(
                strength: .veryWeak,
                feedback: "Required: At least 8 characters, One uppercase letter"
            )

            PasswordStrengthView(
                strength: .weak,
                feedback: "Required: One number, One special character"
            )

            PasswordStrengthView(
                strength: .fair,
                feedback: "Add special character for better security"
            )

            PasswordStrengthView(
                strength: .strong,
                feedback: "Password meets requirements"
            )

            PasswordStrengthView(
                strength: .veryStrong,
                feedback: "Excellent password strength"
            )
        }
        .padding()
    }
}
