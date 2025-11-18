//
//  InsightsView.swift
//  ClariFi_iOS
//
//  Main view for displaying insights and recommendations
//

import SwiftUI

struct InsightsView: View {
    // State Management: @StateObject is used because this View owns the ViewModel lifecycle.
    // The ViewModel is injected via the initializer from the DI container, following the
    // established dependency injection pattern for proper separation of concerns.
    @StateObject private var viewModel: InsightsViewModel
    @State private var showingDetailSheet = false
    
    init(viewModel: InsightsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Analyzing your spending...")
                } else if viewModel.insights.isEmpty {
                    emptyStateView
                } else {
                    insightsList
                }
            }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.refreshInsights()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingDetailSheet) {
                if let insight = viewModel.selectedInsight {
                    InsightDetailView(
                        insight: insight,
                        onDismiss: {
                            viewModel.dismissInsight(insight)
                            showingDetailSheet = false
                        },
                        onClose: {
                            showingDetailSheet = false
                        }
                    )
                }
            }
            .task {
                await viewModel.loadInsights()
            }
            .errorAlert(error: $viewModel.error)
        }
    }
    
    private var insightsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Critical insights first
                if !viewModel.getInsightsByPriority(.critical).isEmpty {
                    Section {
                        ForEach(viewModel.getInsightsByPriority(.critical)) { insight in
                            InsightCard(insight: insight) {
                                viewModel.selectInsight(insight)
                                showingDetailSheet = true
                            } onDismiss: {
                                viewModel.dismissInsight(insight)
                            }
                        }
                    } header: {
                        sectionHeader(title: "Urgent", icon: "exclamationmark.triangle.fill", color: .red)
                    }
                }
                
                // High priority insights
                if !viewModel.getInsightsByPriority(.high).isEmpty {
                    Section {
                        ForEach(viewModel.getInsightsByPriority(.high)) { insight in
                            InsightCard(insight: insight) {
                                viewModel.selectInsight(insight)
                                showingDetailSheet = true
                            } onDismiss: {
                                viewModel.dismissInsight(insight)
                            }
                        }
                    } header: {
                        sectionHeader(title: "Important", icon: "exclamationmark.circle.fill", color: .orange)
                    }
                }
                
                // Medium priority insights
                if !viewModel.getInsightsByPriority(.medium).isEmpty {
                    Section {
                        ForEach(viewModel.getInsightsByPriority(.medium)) { insight in
                            InsightCard(insight: insight) {
                                viewModel.selectInsight(insight)
                                showingDetailSheet = true
                            } onDismiss: {
                                viewModel.dismissInsight(insight)
                            }
                        }
                    } header: {
                        sectionHeader(title: "Recommendations", icon: "lightbulb.fill", color: .blue)
                    }
                }
                
                // Low priority insights
                if !viewModel.getInsightsByPriority(.low).isEmpty {
                    Section {
                        ForEach(viewModel.getInsightsByPriority(.low)) { insight in
                            InsightCard(insight: insight) {
                                viewModel.selectInsight(insight)
                                showingDetailSheet = true
                            } onDismiss: {
                                viewModel.dismissInsight(insight)
                            }
                        }
                    } header: {
                        sectionHeader(title: "Tips", icon: "info.circle.fill", color: .gray)
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Insights Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add more transactions to get personalized insights about your spending")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let insight: Insight
    let onTap: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                priorityIcon
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.headline)
                    
                    Text(insight.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            if !insight.actionItems.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Actions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(insight.actionItems.prefix(2)) { action in
                        HStack {
                            Image(systemName: actionIcon(for: action.actionType))
                                .foregroundColor(.accentColor)
                                .frame(width: 20)
                            Text(action.title)
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                }
            }
            
            HStack {
                confidenceBadge
                Spacer()
                Button("View Details") {
                    onTap()
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
        .font(.title2)
    }
    
    private var confidenceBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.caption)
            Text(String(format: "%.0f%% confident", insight.confidence * 100))
                .font(.caption)
        }
        .foregroundColor(confidenceColor)
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
    
    private func actionIcon(for actionType: ActionItem.ActionType) -> String {
        switch actionType {
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
}
