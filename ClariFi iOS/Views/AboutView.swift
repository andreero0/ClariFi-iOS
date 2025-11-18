//
//  AboutView.swift
//  ClariFi iOS
//
//  About view with app information
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Name
                    VStack(spacing: 12) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("ClariFi")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Privacy-First Personal Finance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Mission Statement
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Our Mission")
                            .font(.headline)
                        
                        Text("ClariFi helps you take control of your finances without compromising your privacy. All your data stays on your device, giving you complete ownership and peace of mind.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Key Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Features")
                            .font(.headline)
                        
                        FeatureRow(
                            icon: "lock.shield.fill",
                            title: "Privacy-First",
                            description: "All processing happens on your device"
                        )
                        
                        FeatureRow(
                            icon: "doc.text.magnifyingglass",
                            title: "Smart OCR",
                            description: "Automatically extract transactions from statements"
                        )
                        
                        FeatureRow(
                            icon: "chart.pie.fill",
                            title: "Budget Tracking",
                            description: "Set goals and track spending by category"
                        )
                        
                        FeatureRow(
                            icon: "lightbulb.fill",
                            title: "Actionable Insights",
                            description: "Get personalized recommendations"
                        )
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Links
                    VStack(spacing: 12) {
                        Link(destination: URL(string: "https://clarifi.app")!) {
                            HStack {
                                Image(systemName: "globe")
                                Text("Visit Our Website")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        Link(destination: URL(string: "https://github.com/clarifi/clarifi-ios")!) {
                            HStack {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                Text("View on GitHub")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                    
                    // Copyright
                    Text("© 2025 ClariFi. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    AboutView()
}
