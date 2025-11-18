//
//  HelpSupportView.swift
//  ClariFi iOS
//
//  Help and Support view
//

import SwiftUI

struct HelpSupportView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                NavigationLink(destination: Text("Upload Statement Guide")) {
                    Label("How to Upload Statements", systemImage: "doc.text.magnifyingglass")
                }
                
                NavigationLink(destination: Text("Transaction Entry Guide")) {
                    Label("Adding Transactions", systemImage: "plus.circle")
                }
                
                NavigationLink(destination: Text("Budget Setup Guide")) {
                    Label("Setting Up Budgets", systemImage: "target")
                }
            }
            
            Section("Troubleshooting") {
                NavigationLink(destination: Text("Common Issues")) {
                    Label("Common Issues", systemImage: "exclamationmark.triangle")
                }
                
                NavigationLink(destination: Text("Data Sync Issues")) {
                    Label("Data Sync Problems", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            
            Section("Contact Support") {
                Button(action: {
                    // Open email client
                }) {
                    Label("Email Support", systemImage: "envelope")
                }
                
                Button(action: {
                    // Open feedback form
                }) {
                    Label("Send Feedback", systemImage: "bubble.left")
                }
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationView {
        HelpSupportView()
    }
}
