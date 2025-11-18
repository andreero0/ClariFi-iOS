import SwiftUI
import Charts
import CoreData

struct CashflowForecastView: View {
    @StateObject private var viewModel: CashflowForecastViewModel
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: CashflowForecastViewModel(context: context))
    }
    
    var body: some View {
        Group {
            if subscriptionViewModel.isPremiumActive {
                forecastContent
            } else {
                PremiumFeatureLock(feature: .cashflowForecasting)
            }
        }
        .navigationTitle("Cashflow Forecast")
        .task {
            await viewModel.loadForecast()
        }
    }
    
    private var forecastContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProgressView("Generating forecast...")
                        .padding()
                } else if let forecast = viewModel.forecast {
                    // Summary Card
                    forecastSummaryCard(forecast: forecast)
                    
                    // Chart
                    forecastChart(forecast: forecast)
                    
                    // Monthly Predictions
                    monthlyPredictions(forecast: forecast)
                    
                    // Category Breakdown
                    categoryBreakdown(forecast: forecast)
                } else if let error = viewModel.error {
                    errorView(error: error)
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.loadForecast()
        }
    }
    
    private func forecastSummaryCard(forecast: CashflowForecast) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("Forecast Summary")
                    .font(.headline)
                Spacer()
                Text("\(Int(forecast.confidenceLevel * 100))% confidence")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let lastPrediction = forecast.predictions.last {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Projected Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(lastPrediction.predictedBalance))
                        .font(.title.bold())
                        .foregroundColor(lastPrediction.predictedBalance >= 0 ? .green : .red)
                    
                    Text("by \(lastPrediction.date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Confidence interval
                    Text("Range: \(formatCurrency(lastPrediction.confidenceInterval.lower)) - \(formatCurrency(lastPrediction.confidenceInterval.upper))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func forecastChart(forecast: CashflowForecast) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Balance Projection")
                .font(.headline)
            
            Chart {
                ForEach(forecast.predictions, id: \.date) { prediction in
                    LineMark(
                        x: .value("Month", prediction.date),
                        y: .value("Balance", Double(truncating: prediction.predictedBalance as NSNumber))
                    )
                    .foregroundStyle(.blue)
                    
                    // Confidence interval area
                    AreaMark(
                        x: .value("Month", prediction.date),
                        yStart: .value("Lower", Double(truncating: prediction.confidenceInterval.lower as NSNumber)),
                        yEnd: .value("Upper", Double(truncating: prediction.confidenceInterval.upper as NSNumber))
                    )
                    .foregroundStyle(.blue.opacity(0.2))
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func monthlyPredictions(forecast: CashflowForecast) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Breakdown")
                .font(.headline)
            
            ForEach(forecast.predictions, id: \.date) { prediction in
                VStack(spacing: 8) {
                    HStack {
                        Text(prediction.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline.bold())
                        Spacer()
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Income")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatCurrency(prediction.predictedIncome))
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Expenses")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatCurrency(prediction.predictedExpenses))
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Balance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatCurrency(prediction.predictedBalance))
                                .font(.subheadline.bold())
                                .foregroundColor(prediction.predictedBalance >= 0 ? .green : .red)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func categoryBreakdown(forecast: CashflowForecast) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Trends")
                .font(.headline)
            
            if let firstPrediction = forecast.predictions.first {
                ForEach(firstPrediction.breakdown.sorted(by: { $0.predictedAmount > $1.predictedAmount }), id: \.category) { category in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.category)
                                .font(.subheadline)
                            
                            HStack(spacing: 4) {
                                Image(systemName: trendIcon(category.trend))
                                    .font(.caption)
                                Text(category.trend.description)
                                    .font(.caption)
                            }
                            .foregroundColor(trendColor(category.trend))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(formatCurrency(category.predictedAmount))
                                .font(.subheadline.bold())
                            
                            Text("\(Int(category.confidence * 100))% confidence")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func errorView(error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Unable to Generate Forecast")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                Task {
                    await viewModel.loadForecast()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        return CurrencyPreferenceManager.shared.formatWithSymbol(amount)
    }
    
    private func trendIcon(_ trend: Trend) -> String {
        switch trend {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
    
    private func trendColor(_ trend: Trend) -> Color {
        switch trend {
        case .increasing: return .red
        case .decreasing: return .green
        case .stable: return .gray
        }
    }
}

// MARK: - ViewModel
@MainActor
class CashflowForecastViewModel: ObservableObject {
    @Published var forecast: CashflowForecast?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let forecastingService: CashflowForecastingService
    
    init(context: NSManagedObjectContext) {
        self.forecastingService = CashflowForecastingService(context: context)
    }
    
    func loadForecast(months: Int = 3) async {
        isLoading = true
        error = nil
        
        do {
            let forecast = try await forecastingService.generateForecast(months: months)
            self.forecast = forecast
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}
