//
//  LiquidGlassCard.swift
//  ClariFi iOS
//
//  Modern Liquid Glass design component for iOS 19+
//

import SwiftUI

struct StandardCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    
    init(
        cornerRadius: CGFloat = 12,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
            )
    }
}

// MARK: - Liquid Glass Button
struct LiquidGlassButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(LiquidGlassButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - Liquid Glass Button Style
struct LiquidGlassButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(isPressed ? 0.3 : 0.2),
                                        .clear,
                                        .white.opacity(isPressed ? 0.2 : 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: .black.opacity(isPressed ? 0.2 : 0.1),
                        radius: isPressed ? 4 : 8,
                        x: 0,
                        y: isPressed ? 2 : 4
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Standard Card Preview
#Preview {
    VStack(spacing: 20) {
        StandardCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Account Balance")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("$2,847.32")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("+2.4% from last month")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .padding(20)
        }
        
        StandardCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Total Spending")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("$1,234.56")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(20)
        }
        
        LiquidGlassButton("Add Transaction", systemImage: "plus.circle") {
            print("Add transaction tapped")
        }
        
        LiquidGlassButton("View Reports", systemImage: "chart.bar.fill") {
            print("View reports tapped")
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
