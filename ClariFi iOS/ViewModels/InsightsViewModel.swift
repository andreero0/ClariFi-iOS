//
//  InsightsViewModel.swift
//  ClariFi_iOS
//
//  ViewModel for insights display and interaction
//

import Foundation
import CoreData
import Combine

@MainActor
class InsightsViewModel: BaseViewModel {
    
    @Published var insights: [Insight] = []
    @Published var dismissedInsightIds: Set<UUID> = []
    @Published var selectedInsight: Insight?
    
    private let insightsEngine: InsightsEngineProtocol
    private let transactionRepository: any TransactionRepository
    private let budgetRepository: any BudgetRepository
    private let context: NSManagedObjectContext
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        insightsEngine: InsightsEngineProtocol,
        transactionRepository: any TransactionRepository,
        budgetRepository: any BudgetRepository,
        context: NSManagedObjectContext
    ) {
        self.insightsEngine = insightsEngine
        self.transactionRepository = transactionRepository
        self.budgetRepository = budgetRepository
        self.context = context
        
        super.init()
        loadDismissedInsights()
    }
    
    // MARK: - Public Methods
    
    func loadInsights() async {
        isLoading = true
        error = nil
        
        do {
            // Fetch transactions and budget on main actor
            let transactions = try await transactionRepository.fetchAll()
            let budget = try await budgetRepository.fetchActiveBudget()
            
            // Capture the insights engine reference for the detached task
            let engine = insightsEngine
            
            // Generate insights on a detached task to avoid blocking the main actor
            // This moves heavy computation off the main thread
            let generatedInsights = await Task.detached { [transactions, budget] in
                await engine.generateInsights(
                    for: transactions,
                    budget: budget
                )
            }.value
            
            // Filter out dismissed insights and publish results on main actor
            insights = generatedInsights.filter { !dismissedInsightIds.contains($0.id) }
            
        } catch {
            handleError(error, context: ["operation": "load_insights"])
        }
        
        isLoading = false
    }
    
    func dismissInsight(_ insight: Insight) {
        dismissedInsightIds.insert(insight.id)
        insights.removeAll { $0.id == insight.id }
        saveDismissedInsights()
    }
    
    func selectInsight(_ insight: Insight) {
        selectedInsight = insight
    }
    
    func clearSelectedInsight() {
        selectedInsight = nil
    }
    
    func refreshInsights() async {
        await loadInsights()
    }
    
    func getInsightsByPriority(_ priority: InsightPriority) -> [Insight] {
        return insights.filter { $0.priority == priority }
    }
    
    func getInsightsByType(_ type: InsightType) -> [Insight] {
        return insights.filter { $0.type == type }
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleNotificationForInsight(_ insight: Insight) {
        // Only schedule for high priority insights
        guard insight.priority >= .high else { return }
        
        // Request notification permission and schedule
        // This would integrate with UNUserNotificationCenter
        // For now, we'll just mark it as a placeholder
        print("Scheduling notification for insight: \(insight.title)")
    }
    
    func shouldShowProactiveAlert(for insight: Insight) -> Bool {
        // Show proactive alerts for critical budget alerts
        return insight.type == .budgetAlert && insight.priority == .critical
    }
    
    // MARK: - Private Methods
    
    private func loadDismissedInsights() {
        if let data = UserDefaults.standard.data(forKey: "dismissedInsights"),
           let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            dismissedInsightIds = ids
        }
    }
    
    private func saveDismissedInsights() {
        if let data = try? JSONEncoder().encode(dismissedInsightIds) {
            UserDefaults.standard.set(data, forKey: "dismissedInsights")
        }
    }
}
