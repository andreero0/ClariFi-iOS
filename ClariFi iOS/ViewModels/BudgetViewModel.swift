//
//  BudgetViewModel.swift
//  ClariFi iOS
//
//  Created by Kiro on 2025-10-10.
//

import Foundation
import CoreData
import Combine

@MainActor
class BudgetViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    @Published var budgetStatus: BudgetStatus?
    @Published var alerts: [BudgetAlert] = []
    
    // Computed properties for testing
    var activeBudget: Budget? {
        return budgetStatus?.budget
    }
    
    // MARK: - Dependencies
    private let budgetRepository: any BudgetRepository
    private let budgetCategoryRepository: any BudgetCategoryRepository
    private let transactionRepository: any TransactionRepository
    private let categoryMappingService: CategoryMappingServiceProtocol
    private let context: NSManagedObjectContext
    private let monitoringService: BudgetMonitoringServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        budgetRepository: any BudgetRepository,
        budgetCategoryRepository: any BudgetCategoryRepository,
        transactionRepository: any TransactionRepository,
        categoryMappingService: CategoryMappingServiceProtocol,
        monitoringService: BudgetMonitoringServiceProtocol,
        context: NSManagedObjectContext
    ) {
        self.budgetRepository = budgetRepository
        self.budgetCategoryRepository = budgetCategoryRepository
        self.transactionRepository = transactionRepository
        self.categoryMappingService = categoryMappingService
        self.monitoringService = monitoringService
        self.context = context
        
        super.init()
        setupMonitoringService()
    }
    
    // MARK: - Setup
    private func setupMonitoringService() {
        // Subscribe to alerts
        monitoringService.alertsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newAlerts in
                self?.alerts.append(contentsOf: newAlerts)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Budget Status
    func loadBudgetStatus() async {
        isLoading = true
        error = nil
        
        do {
            // Check for period rollover
            try await monitoringService.checkAndPerformRollover()
            
            // Load current status
            budgetStatus = try await monitoringService.getBudgetStatus()
            
            isLoading = false
        } catch {
            isLoading = false
            handleError(error, context: ["operation": "load_budget_status"])
        }
    }
    
    // MARK: - Transaction Processing
    func processNewTransaction(_ transaction: Transaction) async {
        do {
            try await monitoringService.processTransaction(transaction)
            await loadBudgetStatus()
        } catch {
            handleError(error, context: ["operation": "process_transaction", "transaction_id": transaction.id?.uuidString ?? "unknown"])
        }
    }
    
    // MARK: - Alert Management
    func dismissAlert(_ alert: BudgetAlert) {
        alerts.removeAll { $0.id == alert.id }
    }
    
    func clearAllAlerts() {
        alerts.removeAll()
    }
    
    // MARK: - Category Display
    func getDisplayName(for canonicalName: String) -> String {
        return categoryMappingService.getDisplayName(for: canonicalName)
    }
    
    func getCategoryIcon(for canonicalName: String) -> String {
        return categoryMappingService.getAllCategories()
            .first { $0.canonicalName == canonicalName }?
            .icon ?? "questionmark.circle.fill"
    }
    
    // MARK: - Test Methods
    func loadBudget() async {
        await loadBudgetStatus()
    }
    

}
