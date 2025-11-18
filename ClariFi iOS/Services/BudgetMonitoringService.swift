//
//  BudgetMonitoringService.swift
//  ClariFi iOS
//
//  Created by Kiro on 2025-10-10.
//

import Foundation
import CoreData
import Combine

// MARK: - Budget Alert Model
struct BudgetAlert: Identifiable {
    let id: UUID
    let categoryId: UUID
    let categoryName: String
    let type: AlertType
    let message: String
    let severity: AlertSeverity
    let currentAmount: Decimal
    let budgetedAmount: Decimal
    let percentageUsed: Double
    let timestamp: Date
    
    enum AlertType {
        case approaching // Near threshold
        case exceeded // Over budget
        case rollover // Rollover occurred
    }
    
    enum AlertSeverity {
        case info
        case warning
        case critical
    }
}

// MARK: - Budget Status Model
struct BudgetStatus {
    let budget: Budget
    let categoryStatuses: [CategoryStatus]
    let totalBudgeted: Decimal
    let totalSpent: Decimal
    let percentageUsed: Double
    let alerts: [BudgetAlert]
    let periodStart: Date
    let periodEnd: Date
    let daysRemaining: Int
}

struct CategoryStatus {
    let category: BudgetCategory
    let spent: Decimal
    let budgeted: Decimal
    let remaining: Decimal
    let percentageUsed: Double
    let isOverBudget: Bool
    let isNearThreshold: Bool
}

// MARK: - Budget Monitoring Service Protocol
protocol BudgetMonitoringServiceProtocol {
    var alertsPublisher: AnyPublisher<[BudgetAlert], Never> { get }
    func getBudgetStatus() async throws -> BudgetStatus?
    func processTransaction(_ transaction: Transaction) async throws
    func checkAndPerformRollover() async throws
}

// MARK: - Budget Monitoring Service
class BudgetMonitoringService: BudgetMonitoringServiceProtocol {
    
    // MARK: - Dependencies
    private let budgetRepository: any BudgetRepository
    private let budgetCategoryRepository: any BudgetCategoryRepository
    private let transactionRepository: any TransactionRepository
    private let context: NSManagedObjectContext
    
    // MARK: - Publishers
    private let alertsSubject = PassthroughSubject<[BudgetAlert], Never>()
    var alertsPublisher: AnyPublisher<[BudgetAlert], Never> {
        alertsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(
        budgetRepository: any BudgetRepository,
        budgetCategoryRepository: any BudgetCategoryRepository,
        transactionRepository: any TransactionRepository,
        context: NSManagedObjectContext
    ) {
        self.budgetRepository = budgetRepository
        self.budgetCategoryRepository = budgetCategoryRepository
        self.transactionRepository = transactionRepository
        self.context = context
    }
    
    // MARK: - Budget Status
    func getBudgetStatus() async throws -> BudgetStatus? {
        guard let budget = try await budgetRepository.fetchActiveBudget() else {
            return nil
        }
        
        let period = BudgetPeriod(rawValue: budget.period ?? "monthly") ?? .monthly
        let periodStart = budget.startDate ?? Date()
        let periodEnd = period.periodEnd(from: periodStart)
        
        // Fetch transactions for current period
        let transactions = try await transactionRepository.fetchByDateRange(periodStart, periodEnd)
        
        // Calculate spending by category
        let spendingByCategory = calculateSpendingByCategory(transactions)
        
        // Update category spent amounts
        let categories = try await budgetCategoryRepository.fetchByBudget(budget)
        var categoryStatuses: [CategoryStatus] = []
        var alerts: [BudgetAlert] = []
        
        for category in categories {
            let spent = spendingByCategory[category.name ?? ""] ?? 0
            let budgeted = category.budgetedAmount as Decimal? ?? 0
            let remaining = budgeted - spent
            let percentageUsed = budgeted > 0 ? Double(truncating: (spent as NSDecimalNumber).dividing(by: budgeted as NSDecimalNumber)) : 0
            let threshold = Double(category.alertThreshold)
            
            // Update spent amount in database
            try await budgetCategoryRepository.updateSpentAmount(category, amount: spent as NSDecimalNumber)
            
            let status = CategoryStatus(
                category: category,
                spent: spent,
                budgeted: budgeted,
                remaining: remaining,
                percentageUsed: percentageUsed,
                isOverBudget: spent > budgeted,
                isNearThreshold: percentageUsed >= threshold && percentageUsed < 1.0
            )
            categoryStatuses.append(status)
            
            // Generate alerts
            if let alert = generateAlert(for: status, threshold: threshold) {
                alerts.append(alert)
            }
        }
        
        let totalBudgeted = categoryStatuses.reduce(Decimal(0)) { $0 + $1.budgeted }
        let totalSpent = categoryStatuses.reduce(Decimal(0)) { $0 + $1.spent }
        let percentageUsed = totalBudgeted > 0 ? Double(truncating: (totalSpent as NSDecimalNumber).dividing(by: totalBudgeted as NSDecimalNumber)) : 0
        
        let calendar = Calendar.current
        let daysRemaining = calendar.dateComponents([.day], from: Date(), to: periodEnd).day ?? 0
        
        // Publish alerts
        if !alerts.isEmpty {
            alertsSubject.send(alerts)
        }
        
        return BudgetStatus(
            budget: budget,
            categoryStatuses: categoryStatuses,
            totalBudgeted: totalBudgeted,
            totalSpent: totalSpent,
            percentageUsed: percentageUsed,
            alerts: alerts,
            periodStart: periodStart,
            periodEnd: periodEnd,
            daysRemaining: max(0, daysRemaining)
        )
    }
    
    // MARK: - Transaction Processing
    func processTransaction(_ transaction: Transaction) async throws {
        guard let budget = try await budgetRepository.fetchActiveBudget() else {
            return
        }
        
        let period = BudgetPeriod(rawValue: budget.period ?? "monthly") ?? .monthly
        let periodStart = budget.startDate ?? Date()
        let periodEnd = period.periodEnd(from: periodStart)
        
        // Check if transaction is in current period
        guard let transactionDate = transaction.date,
              transactionDate >= periodStart && transactionDate <= periodEnd else {
            return
        }
        
        // Find matching category
        let categoryName = transaction.category ?? ""
        if let category = try await budgetCategoryRepository.fetchByName(categoryName, in: budget) {
            let currentSpent = category.spentAmount as Decimal? ?? 0
            let transactionAmount = transaction.amount as Decimal? ?? 0
            let newSpent = currentSpent + transactionAmount
            
            try await budgetCategoryRepository.updateSpentAmount(category, amount: newSpent as NSDecimalNumber)
            
            // Check for alerts
            let budgeted = category.budgetedAmount as Decimal? ?? 0
            let percentageUsed = budgeted > 0 ? Double(truncating: (newSpent as NSDecimalNumber).dividing(by: budgeted as NSDecimalNumber)) : 0
            let threshold = Double(category.alertThreshold)
            
            let status = CategoryStatus(
                category: category,
                spent: newSpent,
                budgeted: budgeted,
                remaining: budgeted - newSpent,
                percentageUsed: percentageUsed,
                isOverBudget: newSpent > budgeted,
                isNearThreshold: percentageUsed >= threshold && percentageUsed < 1.0
            )
            
            if let alert = generateAlert(for: status, threshold: threshold) {
                alertsSubject.send([alert])
            }
        }
    }
    
    // MARK: - Period Rollover
    func checkAndPerformRollover() async throws {
        guard let budget = try await budgetRepository.fetchActiveBudget() else {
            return
        }
        
        let period = BudgetPeriod(rawValue: budget.period ?? "monthly") ?? .monthly
        let periodStart = budget.startDate ?? Date()
        let periodEnd = period.periodEnd(from: periodStart)
        
        // Check if current period has ended
        guard Date() > periodEnd else {
            return
        }
        
        // Perform rollover
        let categories = try await budgetCategoryRepository.fetchByBudget(budget)
        var rolloverAlerts: [BudgetAlert] = []
        
        for category in categories {
            let spent = category.spentAmount as Decimal? ?? 0
            let budgeted = category.budgetedAmount as Decimal? ?? 0
            let remaining = budgeted - spent
            
            if category.rolloverEnabled && remaining > 0 {
                // Add remaining to next period's budget
                let newBudgeted = budgeted + remaining
                category.budgetedAmount = newBudgeted as NSDecimalNumber
                
                let alert = BudgetAlert(
                    id: UUID(),
                    categoryId: category.id ?? UUID(),
                    categoryName: category.name ?? "",
                    type: .rollover,
                    message: "Rolled over \(formatCurrency(remaining)) to next period",
                    severity: .info,
                    currentAmount: spent,
                    budgetedAmount: newBudgeted,
                    percentageUsed: 0,
                    timestamp: Date()
                )
                rolloverAlerts.append(alert)
            }
            
            // Reset spent amount for new period
            try await budgetCategoryRepository.updateSpentAmount(category, amount: NSDecimalNumber(value: 0))
        }
        
        // Update budget start date to next period
        budget.startDate = period.nextPeriodStart(from: periodStart)
        budget.updatedAt = Date()
        try await budgetRepository.save(budget)
        
        if !rolloverAlerts.isEmpty {
            alertsSubject.send(rolloverAlerts)
        }
    }
    
    // MARK: - Helper Methods
    private func calculateSpendingByCategory(_ transactions: [Transaction]) -> [String: Decimal] {
        var spending: [String: Decimal] = [:]
        
        for transaction in transactions {
            let category = transaction.category ?? "Uncategorized"
            let amount = transaction.amount as Decimal? ?? 0
            spending[category, default: 0] += amount
        }
        
        return spending
    }
    
    private func generateAlert(for status: CategoryStatus, threshold: Double) -> BudgetAlert? {
        let categoryId = status.category.id ?? UUID()
        let categoryName = status.category.name ?? ""
        
        if status.isOverBudget {
            let overage = status.spent - status.budgeted
            return BudgetAlert(
                id: UUID(),
                categoryId: categoryId,
                categoryName: categoryName,
                type: .exceeded,
                message: "You've exceeded your \(categoryName) budget by \(formatCurrency(overage))",
                severity: .critical,
                currentAmount: status.spent,
                budgetedAmount: status.budgeted,
                percentageUsed: status.percentageUsed,
                timestamp: Date()
            )
        } else if status.isNearThreshold {
            let remaining = status.remaining
            return BudgetAlert(
                id: UUID(),
                categoryId: categoryId,
                categoryName: categoryName,
                type: .approaching,
                message: "You have \(formatCurrency(remaining)) left in your \(categoryName) budget",
                severity: .warning,
                currentAmount: status.spent,
                budgetedAmount: status.budgeted,
                percentageUsed: status.percentageUsed,
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        return CurrencyFormatter.shared.formatSync(amount, currency: .usd)
    }
}
