import SwiftUI
import Charts
import CoreData

struct ScenarioPlanningView: View {
    @StateObject private var viewModel: ScenarioPlanningViewModel
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: ScenarioPlanningViewModel(context: context))
    }
    
    var body: some View {
        Group {
            if subscriptionViewModel.isPremiumActive {
                scenarioContent
            } else {
                PremiumFeatureLock(feature: .scenarioPlanning)
            }
        }
        .navigationTitle("Scenario Planning")
        .task {
            await viewModel.loadScenarios()
        }
    }
    
    private var scenarioContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProgressView("Loading scenarios...")
                        .padding()
                } else {
                    // Scenario Selection
                    scenarioSelection
                    
                    // Selected Scenario Results
                    if let result = viewModel.selectedResult {
                        scenarioResults(result: result)
                    }
                }
            }
            .padding()
        }
    }
    
    private var scenarioSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What-If Scenarios")
                .font(.headline)
            
            Text("Explore how different spending changes could impact your finances")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ForEach(viewModel.scenarios, id: \.id) { scenario in
                Button(action: {
                    Task {
                        await viewModel.selectScenario(scenario)
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(scenario.name)
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            
                            Text(scenario.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if viewModel.selectedScenario?.id == scenario.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.selectedScenario?.id == scenario.id ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    )
                }
            }
            
            // Custom Scenario Button
            Button(action: {
                viewModel.showCustomScenario = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Custom Scenario")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    private func scenarioResults(result: ScenarioResult) -> some View {
        VStack(spacing: 24) {
            // Impact Summary
            impactSummary(impact: result.impact)
            
            // Comparison Chart
            comparisonChart(result: result)
            
            // Category Impacts
            categoryImpacts(impacts: result.impact.categoryImpacts)
            
            // Recommendations
            recommendations(recommendations: result.impact.recommendations)
        }
    }
    
    private func impactSummary(impact: ScenarioImpact) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Projected Impact")
                .font(.headline)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Savings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(impact.totalSavings))
                        .font(.title2.bold())
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Monthly Savings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(impact.monthlySavings))
                        .font(.title3.bold())
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func comparisonChart(result: ScenarioResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Baseline vs. Scenario")
                .font(.headline)
            
            Chart {
                ForEach(result.baseline.predictions, id: \.date) { prediction in
                    LineMark(
                        x: .value("Month", prediction.date),
                        y: .value("Balance", Double(truncating: prediction.predictedBalance as NSNumber))
                    )
                    .foregroundStyle(.gray)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
                
                ForEach(result.projected.predictions, id: \.date) { prediction in
                    LineMark(
                        x: .value("Month", prediction.date),
                        y: .value("Balance", Double(truncating: prediction.predictedBalance as NSNumber))
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            
            HStack(spacing: 16) {
                Label("Baseline", systemImage: "line.diagonal")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Label("With Changes", systemImage: "line.diagonal")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func categoryImpacts(impacts: [CategoryImpact]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Changes")
                .font(.headline)
            
            ForEach(impacts, id: \.category) { impact in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(impact.category)
                            .font(.subheadline)
                        
                        HStack(spacing: 8) {
                            Text(formatCurrency(impact.baselineAmount))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(formatCurrency(impact.projectedAmount))
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatCurrency(impact.difference))
                            .font(.subheadline.bold())
                            .foregroundColor(impact.difference > 0 ? .green : .red)
                        
                        Text("\(Int(impact.percentageChange))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
    
    private func recommendations(recommendations: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
            
            ForEach(recommendations, id: \.self) { recommendation in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.title3)
                    
                    Text(recommendation)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
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
    
    private func formatCurrency(_ amount: Decimal) -> String {
        return CurrencyPreferenceManager.shared.formatWithSymbol(amount)
    }
}

// MARK: - ViewModel
@MainActor
class ScenarioPlanningViewModel: ObservableObject {
    @Published var scenarios: [SpendingScenario] = []
    @Published var selectedScenario: SpendingScenario?
    @Published var selectedResult: ScenarioResult?
    @Published var isLoading = false
    @Published var showCustomScenario = false
    @Published var error: Error?
    
    private let scenarioService: ScenarioPlanningService
    
    init(context: NSManagedObjectContext) {
        self.scenarioService = ScenarioPlanningService(context: context)
    }
    
    func loadScenarios() async {
        isLoading = true
        error = nil
        
        do {
            let scenarios = try await scenarioService.generateCommonScenarios()
            self.scenarios = scenarios
            
            // Auto-select first scenario
            if let first = scenarios.first {
                await selectScenario(first)
            }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func selectScenario(_ scenario: SpendingScenario) async {
        selectedScenario = scenario
        isLoading = true
        
        do {
            let result = try await scenarioService.runScenario(scenario)
            self.selectedResult = result
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}
