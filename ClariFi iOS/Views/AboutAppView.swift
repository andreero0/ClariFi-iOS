//
//  AboutAppView.swift
//  ClariFi iOS
//
//  About the app view
//

import SwiftUI

struct AboutAppView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("ClariFi")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Your personal finance companion for clarity and control.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            
            Section("Features") {
                Label("Secure Transaction Import", systemImage: "lock.shield")
                Label("Smart Categorization", systemImage: "brain.head.profile")
                Label("Budget Management", systemImage: "target")
                Label("Financial Insights", systemImage: "lightbulb")
                Label("Privacy First", systemImage: "eye.slash")
            }
            
            Section("Legal") {
                NavigationLink(destination: Text("Privacy Policy")) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                
                NavigationLink(destination: Text("Terms of Service")) {
                    Label("Terms of Service", systemImage: "doc.text")
                }
                
                NavigationLink(destination: Text("Licenses")) {
                    Label("Open Source Licenses", systemImage: "doc.plaintext")
                }
            }
            
            Section("Connect") {
                Button(action: {
                    // Open website
                }) {
                    Label("Visit Website", systemImage: "globe")
                }
                
                Button(action: {
                    // Open social media
                }) {
                    Label("Follow on Social", systemImage: "person.2")
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationView {
        AboutAppView()
    }
}
