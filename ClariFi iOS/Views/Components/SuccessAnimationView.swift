//
//  SuccessAnimationView.swift
//  ClariFi iOS
//
//  Success animations using SF Symbols
//

import SwiftUI

// MARK: - Success Animation View
struct SuccessAnimationView: View {
    let title: String
    let message: String
    let icon: String
    let onDismiss: (() -> Void)?
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = -180
    @State private var showContent: Bool = false
    
    init(
        title: String,
        message: String,
        icon: String = "checkmark.circle.fill",
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated Icon
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(.green.gradient)
                .scaleEffect(scale)
                .opacity(opacity)
                .rotationEffect(.degrees(rotation))
                .accessibilityHidden(true)
            
            // Content
            if showContent {
                VStack(spacing: 12) {
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .onAppear {
            playAnimation()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
    
    private func playAnimation() {
        // Icon animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)) {
            scale = 1.0
            opacity = 1.0
            rotation = 0
        }
        
        // Content animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
        }
        
        // Auto dismiss if callback provided
        if let onDismiss = onDismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onDismiss()
            }
        }
    }
}

// MARK: - Celebration Animation
struct CelebrationAnimationView: View {
    let title: String
    let subtitle: String?
    let onComplete: () -> Void
    
    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    @State private var showText = false
    @State private var confettiPieces: [ConfettiPiece] = []
    
    init(
        title: String,
        subtitle: String? = nil,
        onComplete: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onComplete = onComplete
    }
    
    var body: some View {
        ZStack {
            // Confetti
            ForEach(confettiPieces) { piece in
                ConfettiShape(piece: piece)
            }
            
            // Main content
            VStack(spacing: 24) {
                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.green.gradient)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                if showText {
                    VStack(spacing: 12) {
                        Text(title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            playAnimation()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle ?? "")")
    }
    
    private func playAnimation() {
        // Generate confetti
        confettiPieces = (0..<30).map { _ in ConfettiPiece() }
        
        // Icon animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            scale = 1.0
            opacity = 1.0
        }
        
        // Confetti animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                showConfetti = true
            }
        }
        
        // Text animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                showText = true
            }
        }
        
        // Auto complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            onComplete()
        }
    }
}

// MARK: - Confetti Piece
struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
    
    init() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
        self.color = colors.randomElement() ?? .blue
        self.x = CGFloat.random(in: -200...200)
        self.y = CGFloat.random(in: -400...0)
        self.rotation = Double.random(in: 0...360)
        self.scale = CGFloat.random(in: 0.5...1.5)
    }
}

struct ConfettiShape: View {
    let piece: ConfettiPiece
    @State private var yOffset: CGFloat = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        Circle()
            .fill(piece.color)
            .frame(width: 8 * piece.scale, height: 8 * piece.scale)
            .offset(x: piece.x, y: piece.y + yOffset)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    Animation.easeOut(duration: 2.0)
                        .delay(Double.random(in: 0...0.3))
                ) {
                    yOffset = 600
                    rotation = piece.rotation + 360
                }
            }
    }
}

// MARK: - Pulse Animation
struct PulseAnimationView: View {
    let icon: String
    let color: Color
    
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Outer pulse
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 4)
                .scaleEffect(isPulsing ? 1.5 : 1.0)
                .opacity(isPulsing ? 0 : 1)
            
            // Inner circle
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 100, height: 100)
            
            // Icon
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(color)
        }
        .frame(width: 100, height: 100)
        .onAppear {
            withAnimation(
                Animation.easeOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Bounce Animation
struct BounceAnimationView: View {
    let icon: String
    let color: Color
    
    @State private var bounce = false
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 60))
            .foregroundStyle(color.gradient)
            .scaleEffect(bounce ? 1.2 : 1.0)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                ) {
                    bounce = true
                }
            }
    }
}

// MARK: - Success Toast
struct SuccessToast: View {
    let message: String
    let icon: String
    @Binding var isShowing: Bool
    
    @State private var offset: CGFloat = -100
    
    var body: some View {
        if isShowing {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.green)
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            .offset(y: offset)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    offset = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        offset = -100
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isShowing = false
                    }
                }
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Preview
#Preview("Success Animation") {
    SuccessAnimationView(
        title: "Success!",
        message: "Your transaction has been saved"
    )
}

#Preview("Celebration") {
    CelebrationAnimationView(
        title: "You're All Set!",
        subtitle: "Welcome to ClariFi",
        onComplete: {}
    )
}

#Preview("Pulse Animation") {
    PulseAnimationView(icon: "checkmark.circle.fill", color: .green)
}

#Preview("Bounce Animation") {
    BounceAnimationView(icon: "star.fill", color: .yellow)
}

#Preview("Success Toast") {
    SuccessToast(
        message: "Transaction saved successfully",
        icon: "checkmark.circle.fill",
        isShowing: .constant(true)
    )
}
