//
//  BudgetView.swift
//  ClariFi iOS
//
//  Created by Kiro on 2025-10-10.
//

import SwiftUI

struct BudgetView: View {
    @Environment(\.diContainer) private var container
    // State Management: @StateObject is used because this View owns the ViewModel lifecycle.
    // The ViewModel is injected via the initializer from the DI container, ensuring proper
    // dependency injection and testability. SwiftUI manages the lifecycle automatically.
    @StateObject private var viewModel: BudgetViewModel
    @State private var showingCreateBudget = false
    
    init(viewModel: BudgetViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading budget...")
                } else if let status = viewModel.budgetStatus {
                    budgetStatusView(status)
                } else {
                    noBudgetView
                }
            }
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateBudget = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateBudget) {
                BudgetCreationView(viewModel: container.resolve(BudgetCreationViewModel.self))
            }
            .task {
                await viewModel.loadBudgetStatus()
            }
            .refreshable {
                await viewModel.loadBudgetStatus()
            }
            .errorAlert(error: $viewModel.error)
        }
    }
    
    // MARK: - Budget Status View
    private func budgetStatusView(_ status: BudgetStatus) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overall Budget Summary
                budgetSummaryCard(status)
                
                // Alerts Section
                if !status.alerts.isEmpty {
                    alertsSection(status.alerts)
                }
                
                // Category Breakdown
                categoriesSection(status.categoryStatuses)
            }
            .padding()
        }
    }
    
    // MARK: - Budget Summary Card
    private func budgetSummaryCard(_ status: BudgetStatus) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(status.budget.name ?? "Budget")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(status.daysRemaining) days remaining")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: min(status.percentageUsed, 1.0))
                    .stroke(
                        progressColor(for: status.percentageUsed),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: status.percentageUsed)
                
                VStack {
                    Text("\(Int(status.percentageUsed * 100))%")
                        .font(.system(size: 36, weight: .bold))
                    Text("used")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Amount Details
            HStack {
                VStack(alignment: .leading) {
                    Text("Spent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(status.totalSpent))
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(status.totalBudgeted))
                        .font(.headline)
                }
            }
            
            // Period Info
            HStack {
                Text(formatDateRange(status.periodStart, status.periodEnd))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Alerts Section
    private func alertsSection(_ alerts: [BudgetAlert]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alerts")
                .font(.headline)
            
            ForEach(alerts) { alert in
                AlertCard(alert: alert)
            }
        }
    }
    
    // MARK: - Categories Section
    private func categoriesSection(_ categories: [CategoryStatus]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
            
            ForEach(categories, id: \.category.id) { status in
                CategoryCard(status: status)
            }
        }
    }
    
    // MARK: - No Budget View
    private var noBudgetView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Active Budget")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create a budget to start tracking your spending")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingCreateBudget = true }) {
                Text("Create Budget")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    private func progressColor(for percentage: Double) -> Color {
        if percentage >= 1.0 {
            return .red
        } else if percentage >= 0.8 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        return CurrencyPreferenceManager.shared.formatWithSymbol(amount)
    }
    
    private func formatDateRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// MARK: - Alert Card
struct AlertCard: View {
    let alert: BudgetAlert
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(iconColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.categoryName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(alert.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
    }
    
    private var iconName: String {
        switch alert.type {
        case .approaching:
            return "exclamationmark.triangle.fill"
        case .exceeded:
            return "xmark.circle.fill"
        case .rollover:
            return "arrow.clockwise.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch alert.severity {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
    
    private var backgroundColor: Color {
        switch alert.severity {
        case .info:
            return Color.blue.opacity(0.1)
        case .warning:
            return Color.orange.opacity(0.1)
        case .critical:
            return Color.red.opacity(0.1)
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let status: CategoryStatus
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(status.category.name ?? "")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(formatCurrency(status.spent))
                    .font(.subheadline)
                    .foregroundColor(status.isOverBudget ? .red : .primary)
                Text("/ \(formatCurrency(status.budgeted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(progressColor)
                        .frame(width: geometry.size.width * min(status.percentageUsed, 1.0), height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut, value: status.percentageUsed)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(Int(status.percentageUsed * 100))% used")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if status.isOverBudget {
                    Text("Over budget")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text("\(formatCurrency(status.remaining)) left")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    private var progressColor: Color {
        if status.isOverBudget {
            return .red
        } else if status.isNearThreshold {
            return .orange
        } else {
            return .green
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        return CurrencyPreferenceManager.shared.formatWithSymbol(amount)
    }
}

// MARK: - Preview
struct BudgetView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let viewModel = BudgetViewModel(
            budgetRepository: CoreDataBudgetRepository(context: context),
            budgetCategoryRepository: CoreDataBudgetCategoryRepository(context: context),
            transactionRepository: CoreDataTransactionRepository(context: context),
            categoryMappingService: CategoryMappingService(),
            monitoringService: BudgetMonitoringService(
                budgetRepository: CoreDataBudgetRepository(context: context),
                budgetCategoryRepository: CoreDataBudgetCategoryRepository(context: context),
                transactionRepository: CoreDataTransactionRepository(context: context),
                context: context
            ),
            context: context
        )
        
        return BudgetView(viewModel: viewModel)
    }
}
