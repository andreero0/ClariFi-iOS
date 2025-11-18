//
//  RuleEngine.swift
//  ClariFi_iOS
//
//  Rule engine for user-defined categorization rules
//

import Foundation
import CoreData

// MARK: - Rule Match Type

enum RuleMatchType: String, CaseIterable {
    case exact = "exact"
    case contains = "contains"
    case startsWith = "startsWith"
    case regex = "regex"
    
    var displayName: String {
        switch self {
        case .exact: return "Exact Match"
        case .contains: return "Contains"
        case .startsWith: return "Starts With"
        case .regex: return "Regular Expression"
        }
    }
    
    var description: String {
        switch self {
        case .exact: return "Merchant name must match exactly"
        case .contains: return "Merchant name contains the pattern"
        case .startsWith: return "Merchant name starts with the pattern"
        case .regex: return "Advanced pattern matching"
        }
    }
}

// MARK: - Rule Conflict

struct RuleConflict {
    let transaction: Transaction
    let conflictingRules: [CategorizationRule]
    let suggestedResolution: CategorizationRule?
}

// MARK: - Rule Application Result

struct RuleApplicationResult {
    let appliedCount: Int
    let skippedCount: Int
    let conflicts: [RuleConflict]
    let errors: [Error]
}

// MARK: - Rule Engine Protocol

protocol RuleEngineProtocol {
    func createRule(name: String, merchantPattern: String, category: String, matchType: RuleMatchType, priority: Int16, minAmount: Decimal?, maxAmount: Decimal?) async throws -> CategorizationRule
    func updateRule(_ rule: CategorizationRule, name: String?, merchantPattern: String?, category: String?, matchType: RuleMatchType?, priority: Int16?, minAmount: Decimal?, maxAmount: Decimal?, isActive: Bool?) async throws
    func deleteRule(_ rule: CategorizationRule) async throws
    func fetchAllRules() async throws -> [CategorizationRule]
    func fetchActiveRules() async throws -> [CategorizationRule]
    func applyRulesToTransaction(_ transaction: Transaction) async throws -> String?
    func applyRulesToTransactions(_ transactions: [Transaction]) async throws -> RuleApplicationResult
    func detectConflicts(for transaction: Transaction) async throws -> [CategorizationRule]
    func reorderRules(_ rules: [CategorizationRule]) async throws
}

// MARK: - Rule Engine Implementation

class RuleEngine: RuleEngineProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Rule CRUD Operations
    
    func createRule(
        name: String,
        merchantPattern: String,
        category: String,
        matchType: RuleMatchType,
        priority: Int16 = 0,
        minAmount: Decimal? = nil,
        maxAmount: Decimal? = nil
    ) async throws -> CategorizationRule {
        // Validate pattern
        if matchType == .regex {
            _ = try NSRegularExpression(pattern: merchantPattern, options: .caseInsensitive)
        }
        
        let rule = CategorizationRule(context: context)
        rule.id = UUID()
        rule.name = name
        rule.merchantPattern = merchantPattern
        rule.category = category
        rule.matchType = matchType.rawValue
        rule.priority = priority
        rule.minAmount = minAmount as NSDecimalNumber?
        rule.maxAmount = maxAmount as NSDecimalNumber?
        rule.isActive = true
        rule.isUserCreated = true
        rule.applicationCount = 0
        rule.createdAt = Date()
        rule.updatedAt = Date()
        
        try context.save()
        return rule
    }
    
    func updateRule(
        _ rule: CategorizationRule,
        name: String? = nil,
        merchantPattern: String? = nil,
        category: String? = nil,
        matchType: RuleMatchType? = nil,
        priority: Int16? = nil,
        minAmount: Decimal? = nil,
        maxAmount: Decimal? = nil,
        isActive: Bool? = nil
    ) async throws {
        if let name = name {
            rule.name = name
        }
        
        if let merchantPattern = merchantPattern {
            // Validate pattern if match type is regex
            if let matchType = matchType, matchType == .regex {
                _ = try NSRegularExpression(pattern: merchantPattern, options: .caseInsensitive)
            } else if rule.matchType == "regex" {
                _ = try NSRegularExpression(pattern: merchantPattern, options: .caseInsensitive)
            }
            rule.merchantPattern = merchantPattern
        }
        
        if let category = category {
            rule.category = category
        }
        
        if let matchType = matchType {
            rule.matchType = matchType.rawValue
        }
        
        if let priority = priority {
            rule.priority = priority
        }
        
        if let minAmount = minAmount {
            rule.minAmount = minAmount as NSDecimalNumber
        }
        
        if let maxAmount = maxAmount {
            rule.maxAmount = maxAmount as NSDecimalNumber
        }
        
        if let isActive = isActive {
            rule.isActive = isActive
        }
        
        rule.updatedAt = Date()
        try context.save()
    }
    
    func deleteRule(_ rule: CategorizationRule) async throws {
        context.delete(rule)
        try context.save()
    }
    
    func fetchAllRules() async throws -> [CategorizationRule] {
        let fetchRequest: NSFetchRequest<CategorizationRule> = CategorizationRule.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "priority", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]
        return try context.fetch(fetchRequest)
    }
    
    func fetchActiveRules() async throws -> [CategorizationRule] {
        let fetchRequest: NSFetchRequest<CategorizationRule> = CategorizationRule.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "priority", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]
        return try context.fetch(fetchRequest)
    }
    
    // MARK: - Rule Application
    
    func applyRulesToTransaction(_ transaction: Transaction) async throws -> String? {
        guard let merchant = transaction.merchant else { return nil }
        
        let rules = try await fetchActiveRules()
        let amount = transaction.amount?.decimalValue ?? 0
        
        for rule in rules {
            if matchesRule(rule, merchant: merchant, amount: amount) {
                // Update rule application count
                rule.applicationCount += 1
                rule.updatedAt = Date()
                try context.save()
                
                return rule.category
            }
        }
        
        return nil
    }
    
    func applyRulesToTransactions(_ transactions: [Transaction]) async throws -> RuleApplicationResult {
        var appliedCount = 0
        var skippedCount = 0
        var conflicts: [RuleConflict] = []
        let errors: [Error] = []
        
        let rules = try await fetchActiveRules()
        
        for transaction in transactions {
            guard let merchant = transaction.merchant else {
                skippedCount += 1
                continue
            }
            
            let amount = transaction.amount?.decimalValue ?? 0
            let matchingRules = rules.filter { matchesRule($0, merchant: merchant, amount: amount) }
            
            if matchingRules.isEmpty {
                skippedCount += 1
            } else if matchingRules.count == 1 {
                // Single match - apply it
                let rule = matchingRules[0]
                transaction.category = rule.category
                transaction.updatedAt = Date()
                
                rule.applicationCount += 1
                rule.updatedAt = Date()
                
                appliedCount += 1
            } else {
                // Multiple matches - conflict
                let highestPriorityRule = matchingRules.first // Already sorted by priority
                conflicts.append(RuleConflict(
                    transaction: transaction,
                    conflictingRules: matchingRules,
                    suggestedResolution: highestPriorityRule
                ))
                
                // Apply highest priority rule
                if let rule = highestPriorityRule {
                    transaction.category = rule.category
                    transaction.updatedAt = Date()
                    
                    rule.applicationCount += 1
                    rule.updatedAt = Date()
                    
                    appliedCount += 1
                }
            }
        }
        
        try context.save()
        
        return RuleApplicationResult(
            appliedCount: appliedCount,
            skippedCount: skippedCount,
            conflicts: conflicts,
            errors: errors
        )
    }
    
    func detectConflicts(for transaction: Transaction) async throws -> [CategorizationRule] {
        guard let merchant = transaction.merchant else { return [] }
        
        let rules = try await fetchActiveRules()
        let amount = transaction.amount?.decimalValue ?? 0
        
        return rules.filter { matchesRule($0, merchant: merchant, amount: amount) }
    }
    
    func reorderRules(_ rules: [CategorizationRule]) async throws {
        for (index, rule) in rules.enumerated() {
            rule.priority = Int16(rules.count - index)
            rule.updatedAt = Date()
        }
        try context.save()
    }
    
    // MARK: - Private Methods
    
    private func matchesRule(_ rule: CategorizationRule, merchant: String, amount: Decimal) -> Bool {
        guard let pattern = rule.merchantPattern,
              let matchType = rule.matchType else { return false }
        
        // Check amount constraints
        if let minAmount = rule.minAmount?.decimalValue, amount < minAmount {
            return false
        }
        if let maxAmount = rule.maxAmount?.decimalValue, amount > maxAmount {
            return false
        }
        
        // Check merchant pattern
        let normalizedMerchant = merchant.lowercased()
        let normalizedPattern = pattern.lowercased()
        
        switch matchType {
        case "exact":
            return normalizedMerchant == normalizedPattern
        case "contains":
            return normalizedMerchant.contains(normalizedPattern)
        case "startsWith":
            return normalizedMerchant.hasPrefix(normalizedPattern)
        case "regex":
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(merchant.startIndex..., in: merchant)
                return regex.firstMatch(in: merchant, range: range) != nil
            }
            return false
        default:
            return normalizedMerchant.contains(normalizedPattern)
        }
    }
    
    // MARK: - Test Methods
    func applyRules(to transaction: Transaction) async -> String? {
        do {
            return try await applyRulesToTransaction(transaction)
        } catch {
            return nil
        }
    }
}
