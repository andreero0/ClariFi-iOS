//
//  PremiumUpsellView.swift
//  ClariFi iOS
//
//  Reusable premium feature upsell component
//

import SwiftUI

/// A view that promotes premium features to free users.
///
/// This component displays a feature name, list of benefits, and an upgrade button
/// with a gradient background. It's designed to be visually appealing while clearly
/// communicating the value of premium features.
///
/// ## Usage
/// ```swift
/// if !subscriptionViewModel.isPremium {
///     PremiumUpsellView(
///         feature: "Advanced Insights",
///         benefits: [
///             "Detailed spending analytics",
///             "Custom budget categories",
///             "Export reports to PDF"
///         ],
///         onUpgrade: {
///             subscriptionViewModel.showPaywall = true
///         }
///     )
/// }
/// ```
///
/// ## Accessibility
/// - Upgrade button has clear label and hint
/// - All text supports Dynamic Type
struct PremiumUpsellView: View {
    let feature: String
    let benefits: [String]
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Premium icon
            Image(systemName: "star.fill")
                .font(.system(size: 48))
                .foregroundColor(.yellow)
                .accessibilityHidden(true)
            
            // Feature title
            Text("Premium Feature")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(1)
            
            Text(feature)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Benefits list
            VStack(alignment: .leading, spacing: 12) {
                ForEach(benefits, id: \.self) { benefit in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.body)
                        
                        Text(benefit)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.vertical, 8)
            
            // Upgrade button
            Button(action: onUpgrade) {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Upgrade to Premium")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .accessibilityLabel("Upgrade to Premium")
            .accessibilityHint("Opens premium subscription options")
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        PremiumUpsellView(
            feature: "Advanced Insights",
            benefits: [
                "Detailed spending analytics",
                "Custom budget categories",
                "Export reports to PDF",
                "Priority support"
            ],
            onUpgrade: {
                print("Upgrade tapped")
            }
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
