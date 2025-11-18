//
//  ClariFiWidget.swift
//  ClariFi iOS
//
//  Modern WidgetKit implementation for iOS 19+
//
//  NOTE: This widget currently displays placeholder data only.
//  Full implementation with real data is coming soon.
//

import WidgetKit
import SwiftUI
import CoreData

// MARK: - Widget Entry
struct ClariFiWidgetEntry: TimelineEntry {
    let date: Date
    let balance: Decimal
    let recentTransactions: [TransactionSummary]
    let budgetStatus: ClariFi_iOS.BudgetStatus?
}

struct TransactionSummary {
    let merchant: String
    let amount: Decimal
    let category: String?
}

// BudgetStatus is defined in BudgetMonitoringService.swift

// MARK: - Widget Provider
struct ClariFiWidgetProvider: TimelineProvider {
    // NOTE: Currently returns placeholder data
    // TODO: Integrate with DI container and repositories for real data
    
    func placeholder(in context: Context) -> ClariFiWidgetEntry {
        ClariFiWidgetEntry(
            date: Date(),
            balance: 2847.32, // PLACEHOLDER DATA
            recentTransactions: [
                TransactionSummary(merchant: "Sample Transaction", amount: -5.99, category: "Food"),
                TransactionSummary(merchant: "Sample Transaction", amount: -45.00, category: "Transportation"),
                TransactionSummary(merchant: "Sample Transaction", amount: -89.50, category: "Food")
            ],
            budgetStatus: nil as ClariFi_iOS.BudgetStatus?
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ClariFiWidgetEntry) -> ()) {
        // PLACEHOLDER: In production, this should fetch real data
        let entry = ClariFiWidgetEntry(
            date: Date(),
            balance: 2847.32, // PLACEHOLDER DATA
            recentTransactions: [
                TransactionSummary(merchant: "Sample Transaction", amount: -5.99, category: "Food"),
                TransactionSummary(merchant: "Sample Transaction", amount: -45.00, category: "Transportation")
            ],
            budgetStatus: nil as ClariFi_iOS.BudgetStatus?
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ClariFiWidgetEntry>) -> ()) {
        // PLACEHOLDER: In production, this should:
        // 1. Access DI container
        // 2. Resolve TransactionRepository and BudgetRepository
        // 3. Fetch real user data
        // 4. Use user's currency preference (not hardcoded USD)
        
        let currentDate = Date()
        let entry = ClariFiWidgetEntry(
            date: currentDate,
            balance: 2847.32, // PLACEHOLDER DATA
            recentTransactions: [
                TransactionSummary(merchant: "Sample Transaction", amount: -5.99, category: "Food"),
                TransactionSummary(merchant: "Sample Transaction", amount: -45.00, category: "Transportation"),
                TransactionSummary(merchant: "Sample Transaction", amount: -89.50, category: "Food")
            ],
            budgetStatus: nil as ClariFi_iOS.BudgetStatus?
        )
        
        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View
struct ClariFiWidgetView: View {
    var entry: ClariFiWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: ClariFiWidgetEntry
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Balance")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // NOTE: Hardcoded USD - should use user's currency preference
                Text(entry.balance, format: .currency(code: "USD"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.green)
                    Text("+2.4%") // PLACEHOLDER DATA
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            
            // Coming Soon badge
            Text("Preview")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.8))
                )
                .padding(8)
        }
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: ClariFiWidgetEntry
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Balance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // NOTE: Hardcoded USD - should use user's currency preference
                    Text(entry.balance, format: .currency(code: "USD"))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.green)
                        Text("+2.4%") // PLACEHOLDER DATA
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let budgetStatus = entry.budgetStatus {
                        // NOTE: Hardcoded USD - should use user's currency preference
                        Text(budgetStatus.totalBudgeted - budgetStatus.totalSpent, format: .currency(code: "USD"))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No Budget")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text("Set up a budget")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            
            // Coming Soon badge
            Text("Preview")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.8))
                )
                .padding(8)
        }
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    let entry: ClariFiWidgetEntry
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Financial Overview")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // NOTE: Hardcoded USD - should use user's currency preference
                    Text(entry.balance, format: .currency(code: "USD"))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Budget")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let budgetStatus = entry.budgetStatus {
                            // NOTE: Hardcoded USD - should use user's currency preference
                            Text(budgetStatus.totalBudgeted - budgetStatus.totalSpent, format: .currency(code: "USD"))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No Budget")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            Text("Set up a budget")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Spent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let budgetStatus = entry.budgetStatus {
                            // NOTE: Hardcoded USD - should use user's currency preference
                            Text(budgetStatus.totalSpent, format: .currency(code: "USD"))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                            
                            Text("this month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("$0.00") // PLACEHOLDER DATA
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            Text("this month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Transactions")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    ForEach(Array(entry.recentTransactions.prefix(3).enumerated()), id: \.offset) { index, transaction in
                        HStack {
                            Text(transaction.merchant)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // NOTE: Hardcoded USD - should use user's currency preference
                            Text(transaction.amount, format: .currency(code: "USD"))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(transaction.amount < 0 ? .red : .green)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            
            // Coming Soon badge
            Text("Preview")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.8))
                )
                .padding(8)
        }
    }
}

// MARK: - Widget Configuration
struct ClariFiWidget: Widget {
    let kind: String = "ClariFiWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClariFiWidgetProvider()) { entry in
            ClariFiWidgetView(entry: entry)
        }
        .configurationDisplayName("ClariFi Financial")
        .description("Preview of financial widget. Full functionality coming soon with real-time data.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Preview
#Preview("Small Widget", as: .systemSmall) {
    ClariFiWidget()
} timelineProvider: {
    ClariFiWidgetProvider()
}

#Preview("Medium Widget", as: .systemMedium) {
    ClariFiWidget()
} timelineProvider: {
    ClariFiWidgetProvider()
}

#Preview("Large Widget", as: .systemLarge) {
    ClariFiWidget()
} timelineProvider: {
    ClariFiWidgetProvider()
}

// MARK: - Individual View Previews
#Preview("Small View") {
    SmallWidgetView(entry: ClariFiWidgetEntry(
        date: Date(),
        balance: 2500.00,
        recentTransactions: [
            TransactionSummary(merchant: "Coffee Shop", amount: -4.50, category: "Food"),
            TransactionSummary(merchant: "Gas Station", amount: -45.00, category: "Transportation")
        ],
        budgetStatus: nil
    ))
}

#Preview("Medium View") {
    MediumWidgetView(entry: ClariFiWidgetEntry(
        date: Date(),
        balance: 2500.00,
        recentTransactions: [
            TransactionSummary(merchant: "Coffee Shop", amount: -4.50, category: "Food"),
            TransactionSummary(merchant: "Gas Station", amount: -45.00, category: "Transportation"),
            TransactionSummary(merchant: "Grocery Store", amount: -85.30, category: "Food")
        ],
        budgetStatus: nil
    ))
}

#Preview("Large View") {
    LargeWidgetView(entry: ClariFiWidgetEntry(
        date: Date(),
        balance: 2500.00,
        recentTransactions: [
            TransactionSummary(merchant: "Coffee Shop", amount: -4.50, category: "Food"),
            TransactionSummary(merchant: "Gas Station", amount: -45.00, category: "Transportation"),
            TransactionSummary(merchant: "Grocery Store", amount: -85.30, category: "Food"),
            TransactionSummary(merchant: "Restaurant", amount: -32.75, category: "Food")
        ],
        budgetStatus: nil
    ))
}
