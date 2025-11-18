//
//  InsightDetailView.swift
//  ClariFi_iOS
//
//  Detailed view for individual insights with explanations and actions
//

import SwiftUI

struct InsightDetailView: View {
    let insight: Insight
    let onDismiss: () -> Void
    let onClose: () -> Void
    
    @State private var showingActionConfirmation = false
    @State private var selectedAction: ActionItem?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection
                    
                    Divider()
                    
                    // Description
                    descriptionSection
                    
                    Divider()
                    
                    // Explanation
                    explanationSection
                    
                    Divider()
                    
                    // Action Items
                    if !insight.actionItems.isEmpty {
                        actionItemsSection
                        Divider()
                    }
                    
                    // Metadata
                    metadataSection
                }
                .padding()
            }
            .navigationTitle("Insight Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        onClose()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onDismiss) {
                        Label("Dismiss", systemImage: "xmark.circle")
                    }
                }
            }
            .alert("Take Action", isPresented: $showingActionConfirmation) {
                Button("OK") {
                    selectedAction = nil
                }
            } message: {
                if let action = selectedAction {
                    Text("Action: \(action.description)")
                }
            }
        }
    }
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            priorityIcon
                .font(.system(size: 40))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(insight.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                priorityBadge
            }
            
            Spacer()
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(insight.description)
                .font(.body)
        }
    }
    
    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("How We Calculated This")
                    .font(.headline)
            }
            
            Text(insight.explanation)
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                metricBadge(
                    icon: "doc.text.fill",
                    label: "\(insight.dataSourceCount) transactions",
                    color: .blue
                )
                
                metricBadge(
                    icon: "checkmark.seal.fill",
                    label: String(format: "%.0f%% confidence", insight.confidence * 100),
                    color: confidenceColor
                )
            }
            .padding(.top, 8)
        }
    }
    
    private var actionItemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "hand.tap.fill")
                    .foregroundColor(.green)
                Text("Recommended Actions")
                    .font(.headline)
            }
            
            ForEach(insight.actionItems) { action in
                ActionItemCard(action: action) {
                    selectedAction = action
                    showingActionConfirmation = true
                }
            }
        }
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Additional Information")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Generated:")
                Spacer()
                Text(insight.generatedAt, style: .relative)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            
            HStack {
                Text("Type:")
                Spacer()
                Text(insight.type.rawValue.capitalized)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            
            HStack {
                Text("Relevance Score:")
                Spacer()
                Text(String(format: "%.0f%%", insight.relevanceScore * 100))
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
        }
    }
    
    private var priorityIcon: some View {
        Group {
            switch insight.priority {
            case .critical:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            case .high:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
            case .medium:
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.blue)
            case .low:
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var priorityBadge: some View {
        Text(priorityText)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(priorityColor.opacity(0.2))
            .foregroundColor(priorityColor)
            .cornerRadius(8)
    }
    
    private var priorityText: String {
        switch insight.priority {
        case .critical: return "CRITICAL"
        case .high: return "HIGH PRIORITY"
        case .medium: return "MEDIUM PRIORITY"
        case .low: return "LOW PRIORITY"
        }
    }
    
    private var priorityColor: Color {
        switch insight.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .gray
        }
    }
    
    private var confidenceColor: Color {
        if insight.confidence >= 0.8 {
            return .green
        } else if insight.confidence >= 0.6 {
            return .orange
        } else {
            return .gray
        }
    }
    
    private func metricBadge(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(label)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(8)
    }
}

// MARK: - Action Item Card

struct ActionItemCard: View {
    let action: ActionItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: actionIcon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(actionColor)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(action.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(action.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var actionIcon: String {
        switch action.actionType {
        case .adjustBudget:
            return "slider.horizontal.3"
        case .reviewTransactions:
            return "list.bullet.rectangle"
        case .createRule:
            return "wand.and.stars"
        case .cancelSubscription:
            return "xmark.circle"
        case .setAlert:
            return "bell.badge"
        }
    }
    
    private var actionColor: Color {
        switch action.actionType {
        case .adjustBudget:
            return .blue
        case .reviewTransactions:
            return .purple
        case .createRule:
            return .green
        case .cancelSubscription:
            return .red
        case .setAlert:
            return .orange
        }
    }
}

// MARK: - Preview

struct InsightDetailView_Previews: PreviewProvider {
    static var previews: some View {
        InsightDetailView(
            insight: Insight(
                id: UUID(),
                type: .budgetAlert,
                priority: .high,
                title: "Approaching Budget Limit",
                description: "You've used 85% of your dining budget",
                explanation: "Based on 15 transactions totaling $425 in the Dining category this month",
                actionItems: [
                    ActionItem(
                        title: "Review Transactions",
                        description: "Check your recent dining expenses",
                        actionType: .reviewTransactions
                    ),
                    ActionItem(
                        title: "Adjust Budget",
                        description: "Consider increasing your dining budget",
                        actionType: .adjustBudget
                    )
                ],
                confidence: 0.9,
                dataSourceCount: 15,
                generatedAt: Date(),
                relevanceScore: 0.85
            ),
            onDismiss: {},
            onClose: {}
        )
    }
}
