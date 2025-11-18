//
//  InsightsEngine.swift
//  ClariFi_iOS
//
//  Insights generation engine for spending analysis and recommendations
//

import Foundation
import CoreData

// MARK: - Insight Models

enum InsightType: String, Codable {
    case spendingTrend
    case budgetAlert
    case savingsOpportunity
    case recurringCharge
    case unusualSpending
    case categoryIncrease
}

enum InsightPriority: Int, Comparable, Codable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    static func < (lhs: InsightPriority, rhs: InsightPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

struct ActionItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let actionType: ActionType
    
    enum ActionType: String, Codable {
        case adjustBudget
        case reviewTransactions
        case createRule
        case cancelSubscription
        case setAlert
    }
    
    init(title: String, description: String, actionType: ActionType) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.actionType = actionType
    }
}

struct Insight: Identifiable, Codable {
    let id: UUID
    let type: InsightType
    let priority: InsightPriority
    let title: String
    let description: String
    let explanation: String
    let actionItems: [ActionItem]
    let confidence: Float
    let dataSourceCount: Int
    let generatedAt: Date
    let relevanceScore: Float
    
    var impactScore: Float {
        return (Float(priority.rawValue) * 0.4) + (confidence * 0.3) + (relevanceScore * 0.3)
    }
}

struct SpendingTrends: Codable {
    let period: DateInterval
    let totalSpending: Decimal
    let averageDaily: Decimal
    let categoryBreakdown: [String: Decimal]
    let topMerchants: [TopMerchant]
    let comparisonToPrevious: Decimal? // Percentage change
    let projectedMonthly: Decimal
}

struct TopMerchant: Codable {
    let merchant: String
    let amount: Decimal
}

// MARK: - Insights Engine Protocol

protocol InsightsEngineProtocol {
    func generateInsights(for transactions: [Transaction], budget: Budget?) async -> [Insight]
    func generateSpendingTrends(for period: DateInterval, transactions: [Transaction]) async -> SpendingTrends
    func prioritizeInsights(_ insights: [Insight]) -> [Insight]
}

// MARK: - Insights Engine Implementation

actor InsightsEngine: InsightsEngineProtocol {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Main Insight Generation
    
    func generateInsights(for transactions: [Transaction], budget: Budget?) async -> [Insight] {
        var insights: [Insight] = []
        
        // Generate different types of insights
        insights.append(contentsOf: await generateSpendingTrendInsights(transactions))
        
        if let budget = budget {
            insights.append(contentsOf: await generateBudgetAlerts(transactions, budget: budget))
        }
        
        insights.append(contentsOf: await generateSavingsOpportunities(transactions))
        insights.append(contentsOf: await generateRecurringChargeInsights(transactions))
        insights.append(contentsOf: await generateUnusualSpendingInsights(transactions))
        
        // Prioritize and return
        return prioritizeInsights(insights)
    }
    
    // MARK: - Spending Trends
    
    func generateSpendingTrends(for period: DateInterval, transactions: [Transaction]) async -> SpendingTrends {
        let periodTransactions = transactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return period.contains(date)
        }
        
        let totalSpending = periodTransactions.reduce(Decimal.zero) { $0 + ($1.amount?.decimalValue ?? 0) }
        let days = period.duration / 86400 // seconds to days
        let averageDaily = days > 0 ? totalSpending / Decimal(days) : Decimal.zero
        
        // Category breakdown
        var categoryBreakdown: [String: Decimal] = [:]
        for transaction in periodTransactions {
            let category = transaction.category ?? "Uncategorized"
            categoryBreakdown[category, default: Decimal.zero] += (transaction.amount?.decimalValue ?? 0)
        }
        
        // Top merchants
        var merchantTotals: [String: Decimal] = [:]
        for transaction in periodTransactions {
            merchantTotals[transaction.merchant ?? "Unknown", default: Decimal.zero] += (transaction.amount?.decimalValue ?? 0)
        }
        let topMerchants = merchantTotals.sorted { $0.value > $1.value }
            .prefix(5)
            .map { TopMerchant(merchant: $0.key, amount: $0.value) }
        
        // Comparison to previous period
        let previousPeriod = DateInterval(start: period.start.addingTimeInterval(-period.duration),
                                         end: period.start)
        let previousTransactions = transactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return previousPeriod.contains(date)
        }
        let previousTotal = previousTransactions.reduce(Decimal.zero) { $0 + ($1.amount?.decimalValue ?? 0) }
        
        let comparisonToPrevious: Decimal?
        if previousTotal > 0 {
            comparisonToPrevious = ((totalSpending - previousTotal) / previousTotal) * 100
        } else {
            comparisonToPrevious = nil
        }
        
        // Project monthly spending
        let projectedMonthly = averageDaily * 30
        
        return SpendingTrends(
            period: period,
            totalSpending: totalSpending,
            averageDaily: averageDaily,
            categoryBreakdown: categoryBreakdown,
            topMerchants: topMerchants,
            comparisonToPrevious: comparisonToPrevious,
            projectedMonthly: projectedMonthly
        )
    }
    
    // MARK: - Insight Prioritization
    
    nonisolated func prioritizeInsights(_ insights: [Insight]) -> [Insight] {
        return insights.sorted { insight1, insight2 in
            // Sort by impact score (combination of priority, confidence, and relevance)
            if insight1.impactScore != insight2.impactScore {
                return insight1.impactScore > insight2.impactScore
            }
            // If equal impact, sort by priority
            if insight1.priority != insight2.priority {
                return insight1.priority > insight2.priority
            }
            // If equal priority, sort by confidence
            return insight1.confidence > insight2.confidence
        }
    }
    
    // MARK: - Private Insight Generators
    
    private func generateSpendingTrendInsights(_ transactions: [Transaction]) async -> [Insight] {
        var insights: [Insight] = []
        
        guard transactions.count >= 7 else { return insights }
        
        // Analyze last 30 days vs previous 30 days
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: now)!
        
        let recentTransactions = transactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return date >= thirtyDaysAgo
        }
        let previousTransactions = transactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return date >= sixtyDaysAgo && date < thirtyDaysAgo
        }
        
        let recentTotal = recentTransactions.reduce(Decimal.zero) { $0 + ($1.amount?.decimalValue ?? 0) }
        let previousTotal = previousTransactions.reduce(Decimal.zero) { $0 + ($1.amount?.decimalValue ?? 0) }
        
        if previousTotal > 0 {
            let percentChange = ((recentTotal - previousTotal) / previousTotal) * 100
            
            if abs(percentChange) >= 15 {
                let isIncrease = percentChange > 0
                let priority: InsightPriority = abs(percentChange) >= 30 ? .high : .medium
                
                let insight = Insight(
                    id: UUID(),
                    type: .spendingTrend,
                    priority: priority,
                    title: isIncrease ? "Spending Increased" : "Spending Decreased",
                    description: String(format: "Your spending has %@ by %.1f%% compared to last month",
                                      isIncrease ? "increased" : "decreased",
                                      abs(Double(truncating: percentChange as NSNumber))),
                    explanation: String(format: "Based on %d transactions in the last 30 days ($%.2f) compared to the previous 30 days ($%.2f)",
                                      recentTransactions.count,
                                      Double(truncating: recentTotal as NSNumber),
                                      Double(truncating: previousTotal as NSNumber)),
                    actionItems: isIncrease ? [
                        ActionItem(title: "Review Recent Transactions",
                                 description: "Check your recent spending to identify the increase",
                                 actionType: .reviewTransactions),
                        ActionItem(title: "Adjust Budget",
                                 description: "Consider adjusting your budget categories",
                                 actionType: .adjustBudget)
                    ] : [
                        ActionItem(title: "Great Job!",
                                 description: "Keep up the good spending habits",
                                 actionType: .reviewTransactions)
                    ],
                    confidence: 0.9,
                    dataSourceCount: recentTransactions.count + previousTransactions.count,
                    generatedAt: Date(),
                    relevanceScore: 0.85
                )
                
                insights.append(insight)
            }
        }
        
        return insights
    }
    
    private func generateBudgetAlerts(_ transactions: [Transaction], budget: Budget) async -> [Insight] {
        var insights: [Insight] = []
        
        // Get current budget period
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate spending by category for current period
        var categorySpending: [String: Decimal] = [:]
        
        let periodStart: Date
        let periodEnd: Date
        
        if budget.period == "monthly" {
            let components = calendar.dateComponents([.year, .month], from: now)
            periodStart = calendar.date(from: components)!
            periodEnd = calendar.date(byAdding: .month, value: 1, to: periodStart)!
        } else {
            // Weekly
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            periodStart = calendar.date(from: components)!
            periodEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: periodStart)!
        }
        
        let periodTransactions = transactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return date >= periodStart && date < periodEnd
        }
        
        for transaction in periodTransactions {
            let category = transaction.category ?? "Uncategorized"
            categorySpending[category, default: Decimal.zero] += (transaction.amount?.decimalValue ?? 0)
        }
        
        // Check each budget category
        for budgetCategory in budget.categories?.allObjects as? [BudgetCategory] ?? [] {
            let spent = categorySpending[budgetCategory.name ?? ""] ?? Decimal.zero
            let budgeted = budgetCategory.budgetedAmount?.decimalValue ?? Decimal.zero
            
            guard budgeted > 0 else { continue }
            
            let percentUsed = (spent / budgeted) * 100
            
            // Generate alerts based on thresholds
            if percentUsed >= 100 {
                let insight = Insight(
                    id: UUID(),
                    type: .budgetAlert,
                    priority: .critical,
                    title: "Budget Exceeded: \(budgetCategory.name ?? "Unknown")",
                    description: String(format: "You've spent $%.2f of your $%.2f budget (%.0f%%)",
                                      Double(truncating: spent as NSNumber),
                                      Double(truncating: budgeted as NSNumber),
                                      Double(truncating: percentUsed as NSNumber)),
                    explanation: String(format: "Based on %d transactions in the %@ category this period",
                                      periodTransactions.filter { $0.category == budgetCategory.name }.count,
                                      budgetCategory.name ?? "Unknown"),
                    actionItems: [
                        ActionItem(title: "Review Spending",
                                 description: "Check transactions in this category",
                                 actionType: .reviewTransactions),
                        ActionItem(title: "Adjust Budget",
                                 description: "Consider increasing the budget for next period",
                                 actionType: .adjustBudget)
                    ],
                    confidence: 0.95,
                    dataSourceCount: periodTransactions.count,
                    generatedAt: Date(),
                    relevanceScore: 0.95
                )
                insights.append(insight)
            } else if percentUsed >= 80 {
                let insight = Insight(
                    id: UUID(),
                    type: .budgetAlert,
                    priority: .high,
                    title: "Approaching Budget Limit: \(budgetCategory.name ?? "Unknown")",
                    description: String(format: "You've used %.0f%% of your budget ($%.2f remaining)",
                                      Double(truncating: percentUsed as NSNumber),
                                      Double(truncating: (budgeted - spent) as NSNumber)),
                    explanation: String(format: "Based on %d transactions totaling $%.2f in the %@ category",
                                      periodTransactions.filter { $0.category == budgetCategory.name }.count,
                                      Double(truncating: spent as NSNumber),
                                      budgetCategory.name ?? "Unknown"),
                    actionItems: [
                        ActionItem(title: "Monitor Spending",
                                 description: "Be mindful of spending in this category",
                                 actionType: .setAlert),
                        ActionItem(title: "Review Transactions",
                                 description: "Check recent transactions",
                                 actionType: .reviewTransactions)
                    ],
                    confidence: 0.9,
                    dataSourceCount: periodTransactions.count,
                    generatedAt: Date(),
                    relevanceScore: 0.85
                )
                insights.append(insight)
            }
        }
        
        return insights
    }
    
    private func generateSavingsOpportunities(_ transactions: [Transaction]) async -> [Insight] {
        var insights: [Insight] = []
        
        // Look for recurring subscriptions that might be unused
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let recentTransactions = transactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return date >= thirtyDaysAgo
        }
        
        // Group by merchant to find recurring patterns
        var merchantFrequency: [String: [Transaction]] = [:]
        for transaction in recentTransactions {
            merchantFrequency[transaction.merchant ?? "Unknown", default: []].append(transaction)
        }
        
        // Look for merchants with consistent monthly charges
        for (merchant, merchantTransactions) in merchantFrequency {
            guard merchantTransactions.count >= 2 else { continue }
            
            let amounts = merchantTransactions.map { $0.amount }
            let avgAmount = amounts.reduce(Decimal.zero) { $0 + ($1?.decimalValue ?? 0) } / Decimal(amounts.count)
            
            // Check if amounts are consistent (likely subscription)
            let isConsistent = amounts.allSatisfy { amount in
                let decimalAmount = amount?.decimalValue ?? 0
                return abs(decimalAmount - avgAmount) < 1
            }
            
            if isConsistent && avgAmount > 5 {
                let totalSpent = amounts.reduce(Decimal.zero) { $0 + ($1?.decimalValue ?? 0) }
                
                let insight = Insight(
                    id: UUID(),
                    type: .savingsOpportunity,
                    priority: .medium,
                    title: "Review Subscription: \(merchant)",
                    description: String(format: "You've spent $%.2f on %d charges from %@",
                                      Double(truncating: totalSpent as NSNumber),
                                      merchantTransactions.count,
                                      merchant),
                    explanation: String(format: "This appears to be a recurring subscription of approximately $%.2f. Consider if you're still using this service.",
                                      Double(truncating: avgAmount as NSNumber)),
                    actionItems: [
                        ActionItem(title: "Review Usage",
                                 description: "Check if you're still using this service",
                                 actionType: .reviewTransactions),
                        ActionItem(title: "Consider Canceling",
                                 description: "Cancel if no longer needed",
                                 actionType: .cancelSubscription)
                    ],
                    confidence: 0.75,
                    dataSourceCount: merchantTransactions.count,
                    generatedAt: Date(),
                    relevanceScore: 0.7
                )
                insights.append(insight)
            }
        }
        
        return insights
    }
    
    private func generateRecurringChargeInsights(_ transactions: [Transaction]) async -> [Insight] {
        var insights: [Insight] = []
        
        // Analyze last 90 days for recurring patterns
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        let recentTransactions = transactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return date >= ninetyDaysAgo
        }
        
        // Group by merchant
        var merchantGroups: [String: [Transaction]] = [:]
        for transaction in recentTransactions {
            merchantGroups[transaction.merchant ?? "Unknown", default: []].append(transaction)
        }
        
        // Find merchants with 3+ transactions
        for (merchant, merchantTransactions) in merchantGroups {
            guard merchantTransactions.count >= 3 else { continue }
            
            let sortedTransactions = merchantTransactions.sorted { transaction1, transaction2 in
                guard let date1 = transaction1.date, let date2 = transaction2.date else { return false }
                return date1 < date2
            }
            let amounts = sortedTransactions.map { $0.amount }
            let avgAmount = amounts.reduce(Decimal.zero) { $0 + ($1?.decimalValue ?? 0) } / Decimal(amounts.count)
            
            // Check for consistent amounts (within 10%)
            let isConsistentAmount = amounts.allSatisfy { amount in
                let decimalAmount = amount?.decimalValue ?? 0
                return abs(decimalAmount - avgAmount) / avgAmount < 0.1
            }
            
            if isConsistentAmount {
                let totalSpent = amounts.reduce(Decimal.zero) { $0 + ($1?.decimalValue ?? 0) }
                
                let insight = Insight(
                    id: UUID(),
                    type: .recurringCharge,
                    priority: .low,
                    title: "Recurring Charge Detected: \(merchant)",
                    description: String(format: "Found %d similar charges averaging $%.2f",
                                      merchantTransactions.count,
                                      Double(truncating: avgAmount as NSNumber)),
                    explanation: String(format: "Total spent: $%.2f over %d transactions. Consider setting up automatic categorization.",
                                      Double(truncating: totalSpent as NSNumber),
                                      merchantTransactions.count),
                    actionItems: [
                        ActionItem(title: "Create Rule",
                                 description: "Set up automatic categorization for this merchant",
                                 actionType: .createRule)
                    ],
                    confidence: 0.8,
                    dataSourceCount: merchantTransactions.count,
                    generatedAt: Date(),
                    relevanceScore: 0.6
                )
                insights.append(insight)
            }
        }
        
        return insights
    }
    
    private func generateUnusualSpendingInsights(_ transactions: [Transaction]) async -> [Insight] {
        var insights: [Insight] = []
        
        guard transactions.count >= 30 else { return insights }
        
        // Calculate average transaction amount
        let amounts = transactions.map { $0.amount }
        let avgAmount = amounts.reduce(Decimal.zero) { $0 + ($1?.decimalValue ?? 0) } / Decimal(amounts.count)
        
        // Calculate standard deviation
        let variance = amounts.map { amount in
            let decimalAmount = amount?.decimalValue ?? 0
            return pow(Double(truncating: (decimalAmount - avgAmount) as NSNumber), 2)
        }
            .reduce(0.0, +) / Double(amounts.count)
        let stdDev = Decimal(sqrt(variance))
        
        // Find transactions that are 2+ standard deviations above average
        let threshold = avgAmount + (stdDev * 2)
        let unusualTransactions = transactions.filter { transaction in
            guard let amount = transaction.amount else { return false }
            return amount.decimalValue > threshold
        }
        
        // Only report if there are recent unusual transactions
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let recentUnusual = unusualTransactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return date >= sevenDaysAgo
        }
        
        if !recentUnusual.isEmpty {
            let totalUnusual = recentUnusual.reduce(Decimal.zero) { $0 + ($1.amount?.decimalValue ?? 0) }
            
            let insight = Insight(
                id: UUID(),
                type: .unusualSpending,
                priority: .medium,
                title: "Unusual Spending Detected",
                description: String(format: "Found %d transaction(s) significantly above your average",
                                  recentUnusual.count),
                explanation: String(format: "Your average transaction is $%.2f, but you had %d transaction(s) totaling $%.2f that were significantly higher",
                                  Double(truncating: avgAmount as NSNumber),
                                  recentUnusual.count,
                                  Double(truncating: totalUnusual as NSNumber)),
                actionItems: [
                    ActionItem(title: "Review Transactions",
                             description: "Check these large transactions",
                             actionType: .reviewTransactions)
                ],
                confidence: 0.7,
                dataSourceCount: recentUnusual.count,
                generatedAt: Date(),
                relevanceScore: 0.75
            )
            insights.append(insight)
        }
        
        return insights
    }
}
