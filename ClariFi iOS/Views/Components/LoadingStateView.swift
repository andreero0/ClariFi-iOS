//
//  LoadingStateView.swift
//  ClariFi iOS
//
//  Reusable loading state component with skeleton screens
//

import SwiftUI

// MARK: - Loading State View

/// A simple loading indicator with an optional message.
///
/// Displays a circular progress indicator and customizable message text.
/// Use this for general loading states where you want to show progress feedback.
///
/// ## Usage
/// ```swift
/// if isLoading {
///     LoadingStateView(message: "Loading transactions...")
/// }
/// ```
///
/// ## Accessibility
/// - Message is announced to VoiceOver users
/// - Progress indicator is automatically accessible
struct LoadingStateView: View {
    let message: String
    let showProgress: Bool
    
    init(message: String = "Loading...", showProgress: Bool = true) {
        self.message = message
        self.showProgress = showProgress
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if showProgress {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

// MARK: - Skeleton View

/// An animated placeholder view that mimics content while loading.
///
/// Skeleton views provide visual feedback during loading by showing animated
/// placeholders that match the shape of the content being loaded.
///
/// ## Usage
/// ```swift
/// if isLoading {
///     VStack {
///         SkeletonView(height: 44)
///         SkeletonView(height: 44)
///         SkeletonView(height: 44)
///     }
/// } else {
///     // Actual content
/// }
/// ```
struct SkeletonView: View {
    @State private var isAnimating = false
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(height: CGFloat = 20, cornerRadius: CGFloat = 8) {
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.3))
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.5),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 400 : -400)
            )
            .clipped()
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Account Setup Skeleton
struct AccountSetupSkeleton: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonView(height: 24, cornerRadius: 8)
                        .frame(width: 150)
                    
                    SkeletonView(height: 44, cornerRadius: 12)
                    
                    HStack(spacing: 12) {
                        SkeletonView(height: 44, cornerRadius: 12)
                        SkeletonView(height: 44, cornerRadius: 12)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
        }
        .padding()
    }
}

// MARK: - LLM Query Loading View
struct LLMQueryLoadingView: View {
    let merchantName: String
    @State private var dots = ""
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            VStack(spacing: 8) {
                Text("Analyzing transaction\(dots)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(merchantName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onAppear {
            startDotAnimation()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Analyzing transaction for \(merchantName)")
    }
    
    private func startDotAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            withAnimation {
                if dots.count >= 3 {
                    dots = ""
                } else {
                    dots += "."
                }
            }
        }
    }
}

// MARK: - Inline Loading Indicator
struct InlineLoadingIndicator: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Smooth Transition Container
struct SmoothTransitionContainer<Content: View>: View {
    let isLoading: Bool
    let content: Content
    
    init(isLoading: Bool, @ViewBuilder content: () -> Content) {
        self.isLoading = isLoading
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
                .opacity(isLoading ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: isLoading)
            
            if isLoading {
                LoadingStateView()
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Processing Overlay
struct ProcessingOverlay: View {
    let message: String
    let progress: Float
    let onCancel: (() -> Void)?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ProgressView(value: Double(progress), total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 250)
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("\(Int(progress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                if let onCancel = onCancel {
                    Button("Cancel") {
                        onCancel()
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                }
            }
            .padding(40)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
    }
}

// MARK: - Preview
#Preview("Loading State") {
    VStack(spacing: 40) {
        LoadingStateView(message: "Creating your account...")
        
        LoadingStateView(message: "Processing statement...", showProgress: true)
        
        InlineLoadingIndicator(text: "Saving...")
    }
    .padding()
}

#Preview("Skeleton Views") {
    VStack(spacing: 40) {
        SkeletonView(height: 44)
            .padding()
        
        AccountSetupSkeleton()
    }
}

#Preview("LLM Loading") {
    LLMQueryLoadingView(merchantName: "STARBUCKS STORE #12345")
        .padding()
}

#Preview("Processing Overlay") {
    ProcessingOverlay(message: "Reading document text...", progress: 0.45) {
        print("Cancel tapped")
    }
}
