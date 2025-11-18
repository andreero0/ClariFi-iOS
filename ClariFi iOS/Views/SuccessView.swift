//
//  SuccessView.swift
//  ClariFi iOS
//
//  Success feedback views and animations
//

import SwiftUI

struct SuccessView: View {
    let message: String
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .accessibilityHidden(true)
            
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .opacity(opacity)
                .accessibleHeading()
            
            Button("Done") {
                HapticFeedback.selection.trigger()
                onDismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .cornerRadius(10)
            .opacity(opacity)
            .accessibilityLabel("Done")
            .accessibilityHint("Close this success message")
        }
        .padding(30)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding()
        .onAppear {
            HapticFeedback.success.trigger()
            AccessibilityAnnouncement.announce(message)
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

struct InlineSuccessView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SuccessBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    @State private var offset: CGFloat = -100
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
        .offset(y: offset)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                offset = 0
            }
            
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    offset = -100
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            }
        }
    }
}

struct CheckmarkAnimation: View {
    @State private var trimEnd: CGFloat = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.green.opacity(0.2), lineWidth: 4)
                .frame(width: 60, height: 60)
            
            Circle()
                .trim(from: 0, to: trimEnd)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
            
            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.green)
                .scaleEffect(trimEnd)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                trimEnd = 1.0
            }
        }
    }
}

#Preview("Success View") {
    SuccessView(message: "Transaction saved successfully!") {
        print("Dismissed")
    }
}

#Preview("Inline Success") {
    InlineSuccessView(message: "Budget updated")
        .padding()
}

#Preview("Success Banner") {
    VStack {
        Spacer()
        SuccessBanner(message: "Statement uploaded successfully") {
            print("Dismissed")
        }
        Spacer()
    }
}

#Preview("Checkmark Animation") {
    CheckmarkAnimation()
}
