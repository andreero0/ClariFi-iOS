import Foundation
import CoreData

// MARK: - Spending Scenario
struct SpendingScenario {
    let id: UUID
    let name: String
    let description: String
    let changes: [CategoryChange]
    let startDate: Date
    let duration: Int // months
}

struct CategoryChange {
    let category: String
    let changeType: ChangeType
    let amount: Decimal
}

enum ChangeType {
    case increase
    case decrease
    case setAmount
    
    var description: String {
        switch self {
        case .increase: return "Increase"
        case .decrease: return "Decrease"
        case .setAmount: return "Set to"
        }
    }
}

// MARK: - Scenario Result
struct ScenarioResult {
    let scenario: SpendingScenario
    let baseline: CashflowForecast
    let projected: CashflowForecast
    let impact: ScenarioImpact
}

struct ScenarioImpact {
    let totalSavings: Decimal
    let monthlySavings: Decimal
    let categoryImpacts: [CategoryImpact]
    let recommendations: [String]
}

struct CategoryImpact {
    let category: String
    let baselineAmount: Decimal
    let projectedAmount: Decimal
    let difference: Decimal
    let percentageChange: Float
}

// MARK: - Scenario Planning Service
class ScenarioPlanningService {
    private let context: NSManagedObjectContext
    private let backgroundContextProvider: BackgroundContextProvider
    private let forecastingService: CashflowForecastingService
    
    init(context: NSManagedObjectContext, backgroundContextProvider: BackgroundContextProvider) {
        self.context = context
        self.backgroundContextProvider = backgroundContextProvider
        self.forecastingService = CashflowForecastingService(context: context, backgroundContextProvider: backgroundContextProvider)
    }
    
    convenience init(context: NSManagedObjectContext) {
        let container = PersistenceController.shared.container
        let provider = BackgroundContextProvider(persistentContainer: container)
        self.init(context: context, backgroundContextProvider: provider)
    }
    
    // MARK: - Run Scenario
    func runScenario(_ scenario: SpendingScenario) async throws -> ScenarioResult {
        // Generate baseline forecast
        let baseline = try await forecastingService.generateForecast(months: scenario.duration)
        
        // Generate projected forecast with scenario changes
        let projected = try await generateProjectedForecast(
            baseline: baseline,
            scenario: scenario
        )
        
        // Calculate impact
        let impact = calculateImpact(baseline: baseline, projected: projected, scenario: scenario)
        
        return ScenarioResult(
            scenario: scenario,
            baseline: baseline,
            projected: projected,
            impact: impact
        )
    }
    
    // MARK: - Compare Scenarios
    func compareScenarios(_ scenarios: [SpendingScenario]) async throws -> [ScenarioResult] {
        var results: [ScenarioResult] = []
        
        for scenario in scenarios {
            let result = try await runScenario(scenario)
            results.append(result)
        }
        
        return results.sorted { $0.impact.totalSavings > $1.impact.totalSavings }
    }
    
    // MARK: - Generate Common Scenarios
    func generateCommonScenarios() async throws -> [SpendingScenario] {
        let categories = try await fetchTopCategories()
        var scenarios: [SpendingScenario] = []
        
        // Scenario 1: Reduce dining out by 30%
        if categories.contains(where: { $0.lowercased().contains("dining") || $0.lowercased().contains("restaurant") }) {
            let diningCategory = categories.first { $0.lowercased().contains("dining") || $0.lowercased().contains("restaurant") }!
            scenarios.append(SpendingScenario(
                id: UUID(),
                name: "Reduce Dining Out",
                description: "Cut dining expenses by 30%",
                changes: [CategoryChange(category: diningCategory, changeType: .decrease, amount: 0.30)],
                startDate: Date(),
                duration: 3
            ))
        }
        
        // Scenario 2: Reduce entertainment by 50%
        if categories.contains(where: { $0.lowercased().contains("entertainment") }) {
            let entertainmentCategory = categories.first { $0.lowercased().contains("entertainment") }!
            scenarios.append(SpendingScenario(
                id: UUID(),
                name: "Cut Entertainment",
                description: "Reduce entertainment spending by 50%",
                changes: [CategoryChange(category: entertainmentCategory, changeType: .decrease, amount: 0.50)],
                startDate: Date(),
                duration: 3
            ))
        }
        
        // Scenario 3: Reduce all discretionary spending by 20%
        let discretionaryCategories = categories.filter {
            let lower = $0.lowercased()
            return lower.contains("dining") || lower.contains("entertainment") ||
                   lower.contains("shopping") || lower.contains("hobby")
        }
        
        if !discretionaryCategories.isEmpty {
            scenarios.append(SpendingScenario(
                id: UUID(),
                name: "Reduce Discretionary Spending",
                description: "Cut all discretionary spending by 20%",
                changes: discretionaryCategories.map {
                    CategoryChange(category: $0, changeType: .decrease, amount: 0.20)
                },
                startDate: Date(),
                duration: 3
            ))
        }
        
        // Scenario 4: Aggressive savings (reduce all non-essential by 40%)
        if !discretionaryCategories.isEmpty {
            scenarios.append(SpendingScenario(
                id: UUID(),
                name: "Aggressive Savings",
                description: "Maximize savings by cutting non-essentials by 40%",
                changes: discretionaryCategories.map {
                    CategoryChange(category: $0, changeType: .decrease, amount: 0.40)
                },
                startDate: Date(),
                duration: 6
            ))
        }
        
        return scenarios
    }
    
    // MARK: - Private Methods
    private func generateProjectedForecast(
        baseline: CashflowForecast,
        scenario: SpendingScenario
    ) async throws -> CashflowForecast {
        var projectedPredictions: [CashflowPrediction] = []
        
        for prediction in baseline.predictions {
            var modifiedBreakdown = prediction.breakdown
            
            // Apply scenario changes
            for change in scenario.changes {
                if let index = modifiedBreakdown.firstIndex(where: { $0.category == change.category }) {
                    let original = modifiedBreakdown[index]
                    let newAmount: Decimal
                    
                    switch change.changeType {
                    case .increase:
                        newAmount = original.predictedAmount * (1 + change.amount)
                    case .decrease:
                        newAmount = original.predictedAmount * (1 - change.amount)
                    case .setAmount:
                        newAmount = change.amount
                    }
                    
                    modifiedBreakdown[index] = CategoryPrediction(
                        category: original.category,
                        predictedAmount: newAmount,
                        confidence: original.confidence,
                        trend: original.trend
                    )
                }
            }
            
            let newTotalExpenses = modifiedBreakdown.reduce(Decimal.zero) { $0 + $1.predictedAmount }
            let balanceChange = prediction.predictedExpenses - newTotalExpenses
            
            let modifiedPrediction = CashflowPrediction(
                date: prediction.date,
                predictedIncome: prediction.predictedIncome,
                predictedExpenses: newTotalExpenses,
                predictedBalance: prediction.predictedBalance + balanceChange,
                confidenceInterval: prediction.confidenceInterval,
                breakdown: modifiedBreakdown
            )
            
            projectedPredictions.append(modifiedPrediction)
        }
        
        return CashflowForecast(
            startDate: baseline.startDate,
            endDate: baseline.endDate,
            predictions: projectedPredictions,
            confidenceLevel: baseline.confidenceLevel,
            methodology: "Scenario-adjusted forecast"
        )
    }
    
    private func calculateImpact(
        baseline: CashflowForecast,
        projected: CashflowForecast,
        scenario: SpendingScenario
    ) -> ScenarioImpact {
        let baselineTotal = baseline.predictions.reduce(Decimal.zero) { $0 + $1.predictedExpenses }
        let projectedTotal = projected.predictions.reduce(Decimal.zero) { $0 + $1.predictedExpenses }
        let totalSavings = baselineTotal - projectedTotal
        let monthlySavings = totalSavings / Decimal(baseline.predictions.count)
        
        // Calculate category impacts
        var categoryImpacts: [CategoryImpact] = []
        let allCategories = Set(baseline.predictions.flatMap { $0.breakdown.map { $0.category } })
        
        for category in allCategories {
            let baselineAmount = baseline.predictions.reduce(Decimal.zero) { sum, prediction in
                sum + (prediction.breakdown.first { $0.category == category }?.predictedAmount ?? 0)
            }
            
            let projectedAmount = projected.predictions.reduce(Decimal.zero) { sum, prediction in
                sum + (prediction.breakdown.first { $0.category == category }?.predictedAmount ?? 0)
            }
            
            let difference = baselineAmount - projectedAmount
            let percentageChange = baselineAmount > 0 ? Float(truncating: (difference / baselineAmount * 100) as NSNumber) : 0
            
            if difference != 0 {
                categoryImpacts.append(CategoryImpact(
                    category: category,
                    baselineAmount: baselineAmount,
                    projectedAmount: projectedAmount,
                    difference: difference,
                    percentageChange: percentageChange
                ))
            }
        }
        
        // Generate recommendations
        let recommendations = generateRecommendations(
            scenario: scenario,
            totalSavings: totalSavings,
            categoryImpacts: categoryImpacts
        )
        
        return ScenarioImpact(
            totalSavings: totalSavings,
            monthlySavings: monthlySavings,
            categoryImpacts: categoryImpacts.sorted { $0.difference > $1.difference },
            recommendations: recommendations
        )
    }
    
    private func generateRecommendations(
        scenario: SpendingScenario,
        totalSavings: Decimal,
        categoryImpacts: [CategoryImpact]
    ) -> [String] {
        var recommendations: [String] = []
        
        if totalSavings > 0 {
            recommendations.append("This scenario could save you \(formatCurrency(totalSavings)) over \(scenario.duration) months")
        }
        
        for impact in categoryImpacts.prefix(3) {
            if impact.difference > 0 {
                recommendations.append("Reducing \(impact.category) spending could save \(formatCurrency(impact.difference))")
            }
        }
        
        if totalSavings > 1000 {
            recommendations.append("Consider setting up automatic transfers to savings to lock in these gains")
        }
        
        return recommendations
    }
    
    private func fetchTopCategories() async throws -> [String] {
        return try await backgroundContextProvider.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            let transactions = try context.fetch(fetchRequest)
            
            let categories = Set(transactions.compactMap { $0.category })
            return Array(categories)
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        // Use synchronous formatter to avoid async context issues
        return CurrencyFormatter.shared.format(amount, currency: CurrencyPreferenceManager.shared.preferredCurrency)
    }
}
