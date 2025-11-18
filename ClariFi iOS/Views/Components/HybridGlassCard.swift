//
//  HybridGlassCard.swift
//  ClariFi iOS
//
//  Hybrid glass card system following Apple's 2024-2025 HIG principles
//  with selective glass effects for premium elements only
//

import SwiftUI

struct HybridGlassCard<Content: View>: View {
    enum Style {
        case premium  // Subtle white gradient for balance card
        case standard // Solid for regular cards
    }
    
    let style: Style
    let content: Content
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let gradientColors: [Color]
    
    init(
        style: Style = .standard,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 8,
            gradientColors: [Color] = [ColorSystem.glassOverlayLight, .clear],
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.gradientColors = gradientColors
        self.content = content()
    }
    
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        content
            .background(cardBackground)
    }
    
    private var cardBackground: some View {
        Group {
            if reduceTransparency {
                // Accessibility fallback - solid background
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    )
                    .shadow(
                        color: .black.opacity(0.1),
                        radius: shadowRadius,
                        x: 0,
                        y: shadowRadius / 2
                    )
            } else {
                // Style-specific background
                switch style {
                case .premium:
                    premiumGlassBackground
                case .standard:
                    standardBackground
                }
            }
        }
    }
    
    private var premiumGlassBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                // Subtle liquid glass effect - mostly white with very light gradient
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.95),
                        Color.white.opacity(0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                // Very subtle edge highlight
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.clear,
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: .black.opacity(0.08),
                radius: shadowRadius,
                x: 0,
                y: shadowRadius / 2
            )
            .shadow(
                color: .black.opacity(0.04),
                radius: 2,
                x: 0,
                y: 1
            )
    }
    
    private var standardBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(ColorSystem.background)
            .shadow(
                color: .black.opacity(0.08),
                radius: shadowRadius,
                x: 0,
                y: shadowRadius / 2
            )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Premium card (for balance) - subtle white gradient
        HybridGlassCard(style: .premium) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Account Balance")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("$2,847.32")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                    Text("+2.4% from last month")
                        .font(.caption)
                }
                .foregroundColor(.green)
            }
            .padding(24)
        }
        
        // Standard card (for regular content)
        HybridGlassCard(style: .standard) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    Spacer()
                }
                
                Text("$1,234.56")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Total Spending")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
