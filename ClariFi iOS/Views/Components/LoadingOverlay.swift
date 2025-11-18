//
//  LoadingOverlay.swift
//  ClariFi iOS
//
//  Full-screen loading overlay component
//

import SwiftUI

struct LoadingOverlay: View {
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // Loading card
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(32)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Sample content behind overlay
        List {
            ForEach(0..<10) { i in
                Text("Item \(i)")
            }
        }
        
        LoadingOverlay(message: "Saving changes...")
    }
}
