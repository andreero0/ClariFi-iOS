//
//  BatchCategorizationViewModel.swift
//  ClariFi_iOS
//
//  ViewModel for batch categorization
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class BatchCategorizationViewModel: BaseViewModel {
    @Published var uncategorizedTransactions: [Transaction] = []
    @Published var activeRulesCount: Int = 0
    @Published var isProcessing = false
    @Published var result: RuleApplicationResult?
    @Published var uncategorizedOnly = true
    @Published var showConflicts = true
    
    private let context: NSManagedObjectContext
    private let transactionRepository: any TransactionRepository
    private let categoryService: CategoryService
    private let ruleEngine: RuleEngine
    
    init(
        context: NSManagedObjectContext,
        transactionRepository: any TransactionRepository,
        categoryService: CategoryService,
        ruleEngine: RuleEngine
    ) {
        self.context = context
        self.transactionRepository = transactionRepository
        self.categoryService = categoryService
        self.ruleEngine = ruleEngine
        
        super.init()
    }
    
    func loadUncategorizedTransactions() async {
        do {
            let allTransactions = try await transactionRepository.fetchAll()
            
            if uncategorizedOnly {
                uncategorizedTransactions = allTransactions.filter { transaction in
                    transaction.category == nil ||
                    transaction.category == "" ||
                    transaction.category == "other"
                }
            } else {
                uncategorizedTransactions = allTransactions
            }
            
            let activeRules = try await ruleEngine.fetchActiveRules()
            activeRulesCount = activeRules.count
        } catch {
            handleError(error, context: ["operation": "load_uncategorized_transactions"])
        }
    }
    
    func applyRules() async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let transactionsToProcess = uncategorizedOnly ? uncategorizedTransactions : try await transactionRepository.fetchAll()
            
            let applicationResult = try await ruleEngine.applyRulesToTransactions(transactionsToProcess)
            
            result = applicationResult
            
            // Reload uncategorized transactions
            await loadUncategorizedTransactions()
        } catch {
            handleError(error, context: ["operation": "apply_rules"])
        }
    }
}
