//
//  CategorizationRulesViewModel.swift
//  ClariFi_iOS
//
//  ViewModel for categorization rules management
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class CategorizationRulesViewModel: BaseViewModel {
    @Published var rules: [CategorizationRule] = []
    
    private let context: NSManagedObjectContext
    private let categoryService: CategoryService
    private let ruleEngine: RuleEngine
    
    init(context: NSManagedObjectContext, categoryService: CategoryService, ruleEngine: RuleEngine) {
        self.context = context
        self.categoryService = categoryService
        self.ruleEngine = ruleEngine
        super.init()
    }
    
    func loadRules() async {
        isLoading = true
        error = nil
        
        do {
            rules = try await ruleEngine.fetchAllRules()
            isLoading = false
        } catch {
            isLoading = false
            handleError(error, context: ["operation": "load_rules"])
        }
    }
    
    func createRule(
        name: String,
        merchantPattern: String,
        category: String,
        matchType: RuleMatchType,
        priority: Int16,
        minAmount: Decimal?,
        maxAmount: Decimal?
    ) async {
        do {
            _ = try await ruleEngine.createRule(
                name: name,
                merchantPattern: merchantPattern,
                category: category,
                matchType: matchType,
                priority: priority,
                minAmount: minAmount,
                maxAmount: maxAmount
            )
            await loadRules()
        } catch {
            handleError(error, context: ["operation": "create_rule", "rule_name": name])
        }
    }
    
    func updateRule(
        _ rule: CategorizationRule,
        name: String,
        merchantPattern: String,
        category: String,
        matchType: RuleMatchType,
        priority: Int16,
        minAmount: Decimal?,
        maxAmount: Decimal?
    ) async {
        do {
            try await ruleEngine.updateRule(
                rule,
                name: name,
                merchantPattern: merchantPattern,
                category: category,
                matchType: matchType,
                priority: priority,
                minAmount: minAmount,
                maxAmount: maxAmount
            )
            await loadRules()
        } catch {
            handleError(error, context: ["operation": "update_rule", "rule_name": name])
        }
    }
    
    func deleteRule(_ rule: CategorizationRule) async {
        do {
            try await ruleEngine.deleteRule(rule)
            await loadRules()
        } catch {
            handleError(error, context: ["operation": "delete_rule", "rule_id": rule.id?.uuidString ?? "unknown"])
        }
    }
    
    func toggleRuleActive(_ rule: CategorizationRule) async {
        do {
            try await ruleEngine.updateRule(rule, isActive: !rule.isActive)
            await loadRules()
        } catch {
            handleError(error, context: ["operation": "toggle_rule_active", "rule_id": rule.id?.uuidString ?? "unknown"])
        }
    }
    
    func reorderRules(from: IndexSet, to: Int) async {
        var reorderedRules = rules
        reorderedRules.move(fromOffsets: from, toOffset: to)
        
        do {
            try await ruleEngine.reorderRules(reorderedRules)
            await loadRules()
        } catch {
            handleError(error, context: ["operation": "reorder_rules"])
        }
    }
}
