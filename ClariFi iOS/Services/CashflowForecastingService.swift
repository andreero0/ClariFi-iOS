import Foundation
import CoreData

// MARK: - Cashflow Forecast
struct CashflowForecast {
    let startDate: Date
    let endDate: Date
    let predictions: [CashflowPrediction]
    let confidenceLevel: Float
    let methodology: String
}

struct CashflowPrediction {
    let date: Date
    let predictedIncome: Decimal
    let predictedExpenses: Decimal
    let predictedBalance: Decimal
    let confidenceInterval: ConfidenceInterval
    let breakdown: [CategoryPrediction]
}

struct ConfidenceInterval {
    let lower: Decimal
    let upper: Decimal
    let confidence: Float // e.g., 0.95 for 95% confidence
}

struct CategoryPrediction {
    let category: String
    let predictedAmount: Decimal
    let confidence: Float
    let trend: Trend
}

enum Trend {
    case increasing
    case decreasing
    case stable
    
    var description: String {
        switch self {
        case .increasing: return "Increasing"
        case .decreasing: return "Decreasing"
        case .stable: return "Stable"
        }
    }
}

// MARK: - Cashflow Forecasting Service
class CashflowForecastingService {
    private let context: NSManagedObjectContext
    private let backgroundContextProvider: BackgroundContextProvider
    
    init(context: NSManagedObjectContext, backgroundContextProvider: BackgroundContextProvider) {
        self.context = context
        self.backgroundContextProvider = backgroundContextProvider
    }
    
    convenience init(context: NSManagedObjectContext) {
        let container = PersistenceController.shared.container
        let provider = BackgroundContextProvider(persistentContainer: container)
        self.init(context: context, backgroundContextProvider: provider)
    }
    
    // MARK: - Generate Forecast
    func generateForecast(months: Int = 3) async throws -> CashflowForecast {
        let historicalData = try await fetchHistoricalData()
        
        guard !historicalData.isEmpty else {
            throw ForecastError.insufficientData
        }
        
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .month, value: months, to: startDate)!
        
        var predictions: [CashflowPrediction] = []
        var currentBalance = try await calculateCurrentBalance()
        
        // Generate monthly predictions
        for monthOffset in 0..<months {
            guard let predictionDate = Calendar.current.date(byAdding: .month, value: monthOffset, to: startDate) else {
                continue
            }
            
            let categoryPredictions = try await predictCategorySpending(
                for: predictionDate,
                historicalData: historicalData
            )
            
            let totalExpenses = categoryPredictions.reduce(Decimal.zero) { $0 + $1.predictedAmount }
            let predictedIncome = try await predictIncome(for: predictionDate, historicalData: historicalData)
            
            currentBalance = currentBalance + predictedIncome - totalExpenses
            
            let confidenceInterval = calculateConfidenceInterval(
                predicted: currentBalance,
                historicalVariance: calculateVariance(historicalData)
            )
            
            let prediction = CashflowPrediction(
                date: predictionDate,
                predictedIncome: predictedIncome,
                predictedExpenses: totalExpenses,
                predictedBalance: currentBalance,
                confidenceInterval: confidenceInterval,
                breakdown: categoryPredictions
            )
            
            predictions.append(prediction)
        }
        
        let overallConfidence = calculateOverallConfidence(predictions: predictions)
        
        return CashflowForecast(
            startDate: startDate,
            endDate: endDate,
            predictions: predictions,
            confidenceLevel: overallConfidence,
            methodology: "Historical average with trend analysis"
        )
    }
    
    // MARK: - Predict Category Spending
    private func predictCategorySpending(
        for date: Date,
        historicalData: [ForecastTransactionData]
    ) async throws -> [CategoryPrediction] {
        let calendar = Calendar.current
        let targetMonth = calendar.component(.month, from: date)
        
        // Group transactions by category
        var categoryData: [String: [Decimal]] = [:]
        
        for transaction in historicalData {
            let month = calendar.component(.month, from: transaction.date)
            
            // Only consider same month from previous years for seasonality
            if month == targetMonth {
                if categoryData[transaction.category] == nil {
                    categoryData[transaction.category] = []
                }
                categoryData[transaction.category]?.append(transaction.amount)
            }
        }
        
        // Generate predictions for each category
        var predictions: [CategoryPrediction] = []
        
        for (category, amounts) in categoryData {
            guard !amounts.isEmpty else { continue }
            
            let average = amounts.reduce(Decimal.zero, +) / Decimal(amounts.count)
            let trend = detectTrend(amounts: amounts)
            let confidence = calculatePredictionConfidence(amounts: amounts)
            
            // Apply trend adjustment
            let trendAdjustment: Decimal
            switch trend {
            case .increasing:
                trendAdjustment = average * 0.1 // 10% increase
            case .decreasing:
                trendAdjustment = average * -0.1 // 10% decrease
            case .stable:
                trendAdjustment = 0
            }
            
            let prediction = CategoryPrediction(
                category: category,
                predictedAmount: average + trendAdjustment,
                confidence: confidence,
                trend: trend
            )
            
            predictions.append(prediction)
        }
        
        return predictions
    }
    
    // MARK: - Predict Income
    private func predictIncome(
        for date: Date,
        historicalData: [ForecastTransactionData]
    ) async throws -> Decimal {
        // Filter for income transactions (negative amounts in our system)
        let incomeTransactions = historicalData.filter { $0.amount < 0 }
        
        guard !incomeTransactions.isEmpty else {
            return 0
        }
        
        let calendar = Calendar.current
        let targetMonth = calendar.component(.month, from: date)
        
        // Get income for same month in previous periods
        let relevantIncome = incomeTransactions.filter {
            calendar.component(.month, from: $0.date) == targetMonth
        }
        
        if relevantIncome.isEmpty {
            // Fallback to overall average
            let total = incomeTransactions.reduce(Decimal.zero) { $0 + abs($1.amount) }
            return total / Decimal(incomeTransactions.count)
        }
        
        let total = relevantIncome.reduce(Decimal.zero) { $0 + abs($1.amount) }
        return total / Decimal(relevantIncome.count)
    }
    
    // MARK: - Helper Methods
    private func fetchHistoricalData() async throws -> [ForecastTransactionData] {
        return try await backgroundContextProvider.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            
            // Fetch last 12 months of data
            let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
            fetchRequest.predicate = NSPredicate(format: "date >= %@", oneYearAgo as NSDate)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
            
            let transactions = try context.fetch(fetchRequest)
            
            return transactions.compactMap { transaction in
                guard let date = transaction.date,
                      let amount = transaction.amount?.decimalValue,
                      let category = transaction.category else {
                    return nil
                }
                return ForecastTransactionData(
                    date: date,
                    amount: amount,
                    category: category
                )
            }
        }
    }
    
    private func calculateCurrentBalance() async throws -> Decimal {
        return try await backgroundContextProvider.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            let transactions = try context.fetch(fetchRequest)
            
            return transactions.reduce(Decimal.zero) { balance, transaction in
                let amount = transaction.amount?.decimalValue ?? Decimal.zero
                // Income is negative, expenses are positive
                return balance - amount
            }
        }
    }
    
    private func detectTrend(amounts: [Decimal]) -> Trend {
        guard amounts.count >= 3 else { return .stable }
        
        let recentCount = min(3, amounts.count)
        let recent = Array(amounts.suffix(recentCount))
        let older = Array(amounts.prefix(amounts.count - recentCount))
        
        let recentAvg = recent.reduce(Decimal.zero, +) / Decimal(recent.count)
        let olderAvg = older.reduce(Decimal.zero, +) / Decimal(older.count)
        
        let difference = recentAvg - olderAvg
        let threshold = olderAvg * 0.1 // 10% threshold
        
        if difference > threshold {
            return .increasing
        } else if difference < -threshold {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    private func calculateVariance(_ data: [ForecastTransactionData]) -> Decimal {
        guard !data.isEmpty else { return 0 }
        
        let amounts = data.map { $0.amount }
        let mean = amounts.reduce(Decimal.zero, +) / Decimal(amounts.count)
        
        let squaredDifferences = amounts.map { amount -> Decimal in
            let diff = amount - mean
            return diff * diff
        }
        
        let variance = squaredDifferences.reduce(Decimal.zero, +) / Decimal(amounts.count)
        return variance
    }
    
    private func calculateConfidenceInterval(predicted: Decimal, historicalVariance: Decimal) -> ConfidenceInterval {
        // Using 95% confidence interval (approximately 2 standard deviations)
        let standardDeviation = sqrt(Double(truncating: historicalVariance as NSNumber))
        let margin = Decimal(standardDeviation * 1.96) // 1.96 for 95% confidence
        
        return ConfidenceInterval(
            lower: predicted - margin,
            upper: predicted + margin,
            confidence: 0.95
        )
    }
    
    private func calculatePredictionConfidence(amounts: [Decimal]) -> Float {
        guard amounts.count > 1 else { return 0.5 }
        
        let mean = amounts.reduce(Decimal.zero, +) / Decimal(amounts.count)
        let variance = calculateVariance(amounts.map { ForecastTransactionData(date: Date(), amount: $0, category: "") })
        
        // Lower variance = higher confidence
        let coefficientOfVariation = sqrt(Double(truncating: variance as NSNumber)) / Double(truncating: mean as NSNumber)
        
        // Convert to confidence score (0-1)
        let confidence = max(0, min(1, 1 - Float(coefficientOfVariation)))
        
        return confidence
    }
    
    private func calculateOverallConfidence(predictions: [CashflowPrediction]) -> Float {
        guard !predictions.isEmpty else { return 0 }
        
        let confidences = predictions.flatMap { $0.breakdown.map { $0.confidence } }
        let average = confidences.reduce(0, +) / Float(confidences.count)
        
        return average
    }
}

// MARK: - Supporting Types
private struct ForecastTransactionData {
    let date: Date
    let amount: Decimal
    let category: String
}

// MARK: - Forecast Error
enum ForecastError: LocalizedError {
    case insufficientData
    case calculationFailed
    
    var errorDescription: String? {
        switch self {
        case .insufficientData:
            return "Not enough historical data to generate forecast"
        case .calculationFailed:
            return "Failed to calculate forecast"
        }
    }
}
