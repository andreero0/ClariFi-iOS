//
//  HelpView.swift
//  ClariFi iOS
//
//  Help documentation and onboarding tutorials
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTopic: HelpTopic?
    
    var body: some View {
        NavigationView {
            List {
                Section("Getting Started") {
                    ForEach(HelpTopic.gettingStartedTopics) { topic in
                        Button {
                            selectedTopic = topic
                        } label: {
                            HelpTopicRow(topic: topic)
                        }
                    }
                }
                
                Section("Features") {
                    ForEach(HelpTopic.featureTopics) { topic in
                        Button {
                            selectedTopic = topic
                        } label: {
                            HelpTopicRow(topic: topic)
                        }
                    }
                }
                
                Section("Privacy & Security") {
                    ForEach(HelpTopic.privacyTopics) { topic in
                        Button {
                            selectedTopic = topic
                        } label: {
                            HelpTopicRow(topic: topic)
                        }
                    }
                }
                
                Section("Troubleshooting") {
                    ForEach(HelpTopic.troubleshootingTopics) { topic in
                        Button {
                            selectedTopic = topic
                        } label: {
                            HelpTopicRow(topic: topic)
                        }
                    }
                }
            }
            .navigationTitle("Help & Tutorials")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedTopic) { topic in
                HelpDetailView(topic: topic)
            }
        }
    }
}

struct HelpTopicRow: View {
    let topic: HelpTopic
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: topic.icon)
                .font(.title3)
                .foregroundColor(topic.color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(topic.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(topic.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct HelpDetailView: View {
    let topic: HelpTopic
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: topic.icon)
                            .font(.system(size: 40))
                            .foregroundColor(topic.color)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(topic.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(topic.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(topic.color.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(topic.content, id: \.self) { section in
                            Text(section)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // Steps (if available)
                    if !topic.steps.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Steps")
                                .font(.headline)
                                .padding(.top)
                            
                            ForEach(Array(topic.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 28, height: 28)
                                        .background(topic.color)
                                        .clipShape(Circle())
                                    
                                    Text(step)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
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
}

// MARK: - Help Topic Model

struct HelpTopic: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let content: [String]
    let steps: [String]
    
    static let gettingStartedTopics = [
        HelpTopic(
            title: "Welcome to ClariFi",
            subtitle: "Learn the basics",
            icon: "hand.wave.fill",
            color: .blue,
            content: [
                "ClariFi is a privacy-first personal finance app that helps you take control of your spending without connecting to your bank accounts.",
                "All your financial data stays on your device, giving you complete privacy and control.",
                "Get started by uploading a bank statement or adding transactions manually."
            ],
            steps: []
        ),
        HelpTopic(
            title: "Adding Your First Transaction",
            subtitle: "Start tracking your spending",
            icon: "plus.circle.fill",
            color: .green,
            content: [
                "There are two ways to add transactions to ClariFi: upload a bank statement or enter them manually.",
                "For the fastest setup, upload a PDF or image of your bank statement. ClariFi will automatically extract the transactions using on-device OCR."
            ],
            steps: [
                "Tap the 'Upload Statement' button on the dashboard",
                "Select a PDF or image file from your device",
                "Review the extracted transactions and make any corrections",
                "Tap 'Confirm' to save the transactions"
            ]
        ),
        HelpTopic(
            title: "Creating Your First Budget",
            subtitle: "Set spending goals",
            icon: "target",
            color: .orange,
            content: [
                "Budgets help you track your spending and stay on top of your financial goals.",
                "ClariFi offers starter templates for different lifestyles, or you can create a custom budget from scratch."
            ],
            steps: [
                "Go to the Budget tab",
                "Tap 'Create Budget'",
                "Choose a template or start from scratch",
                "Set amounts for each category",
                "Save your budget and start tracking"
            ]
        )
    ]
    
    static let featureTopics = [
        HelpTopic(
            title: "Statement Upload",
            subtitle: "Import transactions automatically",
            icon: "doc.text.magnifyingglass",
            color: .blue,
            content: [
                "Upload bank or credit card statements in PDF or image format.",
                "ClariFi uses on-device OCR to extract transaction data while keeping everything private.",
                "All processing happens locally on your device - no data is sent to the cloud."
            ],
            steps: [
                "Tap 'Upload Statement' from the dashboard or transactions tab",
                "Select a file or take a photo of your statement",
                "Wait for processing to complete",
                "Review and correct any extracted transactions",
                "Confirm to save"
            ]
        ),
        HelpTopic(
            title: "Manual Entry",
            subtitle: "Add transactions by hand",
            icon: "pencil.circle.fill",
            color: .green,
            content: [
                "Manually enter transactions for cash purchases or when you don't have a statement.",
                "ClariFi learns from your entries and provides smart suggestions for merchants and categories."
            ],
            steps: [
                "Tap 'Add Transaction' from the dashboard",
                "Enter the date, merchant, and amount",
                "Select or create a category",
                "Add optional notes",
                "Save the transaction"
            ]
        ),
        HelpTopic(
            title: "Budgets & Categories",
            subtitle: "Track spending by category",
            icon: "chart.pie.fill",
            color: .purple,
            content: [
                "Organize your spending into categories and set budget limits for each.",
                "ClariFi automatically categorizes transactions based on merchant patterns and your past behavior.",
                "Get alerts when you're approaching or exceeding budget limits."
            ],
            steps: []
        ),
        HelpTopic(
            title: "Insights & Recommendations",
            subtitle: "Understand your spending",
            icon: "lightbulb.fill",
            color: .yellow,
            content: [
                "ClariFi analyzes your spending patterns and provides actionable insights.",
                "Get personalized recommendations to help you save money and reach your financial goals.",
                "All analysis happens on your device - your data never leaves your phone."
            ],
            steps: []
        )
    ]
    
    static let privacyTopics = [
        HelpTopic(
            title: "Privacy-First Design",
            subtitle: "Your data stays on your device",
            icon: "lock.shield.fill",
            color: .green,
            content: [
                "ClariFi is built with privacy as the top priority. All your financial data stays on your device.",
                "We use on-device OCR and machine learning - no cloud processing required.",
                "You have complete control over your data with easy export and deletion options."
            ],
            steps: []
        ),
        HelpTopic(
            title: "Data Security",
            subtitle: "How we protect your information",
            icon: "key.fill",
            color: .blue,
            content: [
                "All sensitive data is encrypted using iOS security features.",
                "Optional biometric authentication adds an extra layer of protection.",
                "Your data is stored securely in the iOS sandbox, isolated from other apps."
            ],
            steps: []
        ),
        HelpTopic(
            title: "Export & Delete Data",
            subtitle: "You own your data",
            icon: "arrow.up.doc.fill",
            color: .orange,
            content: [
                "Export all your data at any time in a standard format.",
                "Delete all your data with a single tap - no questions asked.",
                "Your data is yours, and you have complete control over it."
            ],
            steps: [
                "Go to Settings > Privacy",
                "Tap 'Export Data' to download all your information",
                "Or tap 'Delete All Data' to permanently remove everything"
            ]
        )
    ]
    
    static let troubleshootingTopics = [
        HelpTopic(
            title: "OCR Not Working",
            subtitle: "Improve statement scanning",
            icon: "exclamationmark.triangle.fill",
            color: .red,
            content: [
                "If OCR isn't extracting transactions correctly, try these tips:",
                "• Ensure the statement is clear and well-lit",
                "• Use a high-resolution image or PDF",
                "• Make sure the text is not skewed or rotated",
                "• Try uploading a different page or section"
            ],
            steps: []
        ),
        HelpTopic(
            title: "Transactions Not Categorizing",
            subtitle: "Fix categorization issues",
            icon: "tag.slash.fill",
            color: .orange,
            content: [
                "ClariFi learns from your corrections to improve categorization over time.",
                "If transactions aren't being categorized correctly:",
                "• Manually correct a few transactions from the same merchant",
                "• Create a custom rule for specific merchants",
                "• Check that your categories are set up correctly"
            ],
            steps: []
        ),
        HelpTopic(
            title: "App Performance",
            subtitle: "Optimize ClariFi",
            icon: "speedometer",
            color: .blue,
            content: [
                "If the app is running slowly:",
                "• Clear the cache in Settings",
                "• Archive old transactions you don't need",
                "• Restart the app",
                "• Make sure you have the latest version installed"
            ],
            steps: []
        )
    ]
}

#Preview {
    HelpView()
}
