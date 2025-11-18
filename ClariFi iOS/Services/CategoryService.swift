//
//  CategoryService.swift
//  ClariFi_iOS
//
//  Automatic transaction categorization service with pattern matching and learning
//

import Foundation
import CoreData

// MARK: - Categorization Result

struct CategorizationResult {
    let category: String
    let confidence: Float
    let matchedPattern: String?
    let matchType: MatchType
    let categorizationMethod: CategorizationMethod
    
    enum MatchType {
        case exactRule
        case patternMatch
        case learned
        case llm
        case default_
    }
    
    init(category: String, confidence: Float, matchedPattern: String?, matchType: MatchType, categorizationMethod: CategorizationMethod? = nil) {
        self.category = category
        self.confidence = confidence
        self.matchedPattern = matchedPattern
        self.matchType = matchType
        
        // Auto-convert matchType to categorizationMethod if not provided
        if let method = categorizationMethod {
            self.categorizationMethod = method
        } else {
            switch matchType {
            case .exactRule:
                self.categorizationMethod = .rule
            case .patternMatch:
                self.categorizationMethod = .pattern
            case .learned:
                self.categorizationMethod = .learned
            case .llm:
                self.categorizationMethod = .llm
            case .default_:
                self.categorizationMethod = .pattern
            }
        }
    }
}

// MARK: - Category Service Protocol

protocol CategoryServiceProtocol {
    func categorize(merchant: String, amount: Decimal) async throws -> CategorizationResult
    func learnFromCorrection(merchant: String, category: String) async throws
    func getSuggestedCategories(for merchant: String) async throws -> [CategorizationResult]
    func getMerchantHistory(for merchant: String) async throws -> [String: Int]
}

// MARK: - Category Service Implementation

class CategoryService: CategoryServiceProtocol {
    private let context: NSManagedObjectContext
    private let backgroundContextProvider: BackgroundContextProvider
    private let transactionRepository: (any TransactionRepository)?
    private let llmService: LLMCategorizationServiceProtocol?
    
    // Built-in merchant patterns for common merchants - now using canonical category names
    private let builtInPatterns: [String: (pattern: String, canonicalCategory: String)] = [
        // Groceries
        "walmart": ("walmart", "food_groceries"),
        "target": ("target", "food_groceries"),
        "kroger": ("kroger", "food_groceries"),
        "safeway": ("safeway", "food_groceries"),
        "whole foods": ("whole foods", "food_groceries"),
        "trader joe": ("trader joe", "food_groceries"),
        "costco": ("costco", "food_groceries"),
        "aldi": ("aldi", "food_groceries"),
        
        // Dining
        "starbucks": ("starbucks", "dining"),
        "mcdonald": ("mcdonald", "dining"),
        "chipotle": ("chipotle", "dining"),
        "subway": ("subway", "dining"),
        "panera": ("panera", "dining"),
        "dunkin": ("dunkin", "dining"),
        "restaurant": ("restaurant", "dining"),
        "cafe": ("cafe", "dining"),
        "pizza": ("pizza", "dining"),
        "burger": ("burger", "dining"),
        
        // Transportation
        "uber": ("uber", "transportation"),
        "lyft": ("lyft", "transportation"),
        "shell": ("shell", "transportation"),
        "chevron": ("chevron", "transportation"),
        "exxon": ("exxon", "transportation"),
        "bp gas": ("bp", "transportation"),
        "parking": ("parking", "transportation"),
        
        // Utilities
        "electric": ("electric", "utilities"),
        "gas company": ("gas", "utilities"),
        "water": ("water", "utilities"),
        "internet": ("internet", "utilities"),
        "phone": ("phone", "utilities"),
        
        // Entertainment
        "netflix": ("netflix", "entertainment"),
        "spotify": ("spotify", "entertainment"),
        "hulu": ("hulu", "entertainment"),
        "disney": ("disney", "entertainment"),
        "hbo": ("hbo", "entertainment"),
        "amazon prime": ("prime", "entertainment"),
        "movie": ("movie", "entertainment"),
        "theater": ("theater", "entertainment"),
        
        // Shopping
        "amazon": ("amazon", "shopping"),
        "ebay": ("ebay", "shopping"),
        "etsy": ("etsy", "shopping"),
        "best buy": ("best buy", "shopping"),
        
        // Healthcare
        "pharmacy": ("pharmacy", "healthcare"),
        "cvs": ("cvs", "healthcare"),
        "walgreens": ("walgreens", "healthcare"),
        "hospital": ("hospital", "healthcare"),
        "clinic": ("clinic", "healthcare"),
        "doctor": ("doctor", "healthcare"),
        
        // Housing
        "rent": ("rent", "housing"),
        "mortgage": ("mortgage", "housing"),
        "property": ("property", "housing"),
        
        // Subscriptions
        "subscription": ("subscriptions", "subscriptions"),
        "membership": ("membership", "subscriptions"),
    ]
    
    init(
        context: NSManagedObjectContext,
        backgroundContextProvider: BackgroundContextProvider,
        transactionRepository: (any TransactionRepository)? = nil,
        llmService: LLMCategorizationServiceProtocol? = nil
    ) {
        self.context = context
        self.backgroundContextProvider = backgroundContextProvider
        self.transactionRepository = transactionRepository
        self.llmService = llmService
    }
    
    // Convenience initializer for backward compatibility
    convenience init(context: NSManagedObjectContext) {
        // Create a temporary background context provider for backward compatibility
        let container = PersistenceController.shared.container
        let backgroundContextProvider = BackgroundContextProvider(persistentContainer: container)
        self.init(context: context, backgroundContextProvider: backgroundContextProvider, transactionRepository: nil, llmService: nil)
    }
    
    // MARK: - Public Methods
    
    func categorize(merchant: String, amount: Decimal) async throws -> CategorizationResult {
        let normalizedMerchant = normalizeMerchant(merchant)
        
        // 1. Check for exact user-defined rules (highest priority)
        if let ruleResult = try await checkUserRules(merchant: normalizedMerchant, amount: amount) {
            return ruleResult
        }
        
        // 2. Check learned patterns from user corrections
        if let learnedResult = try await checkLearnedPatterns(merchant: normalizedMerchant) {
            return learnedResult
        }
        
        // 3. Try LLM categorization if available
        if let llmService = llmService {
            do {
                let llmResult = try await llmService.categorizeWithLLM(
                    merchant: merchant,
                    amount: amount,
                    context: nil
                )
                
                // Only use LLM result if confidence is reasonable
                if llmResult.confidence > 0.5 {
                    return CategorizationResult(
                        category: llmResult.category,
                        confidence: llmResult.confidence,
                        matchedPattern: llmResult.normalizedMerchant,
                        matchType: .llm,
                        categorizationMethod: .llm
                    )
                }
            } catch {
                // LLM failed, continue to fallback methods
                print("LLM categorization failed: \(error.localizedDescription)")
            }
        }
        
        // 4. Check built-in patterns
        if let builtInResult = checkBuiltInPatterns(merchant: normalizedMerchant) {
            return builtInResult
        }
        
        // 5. Default to "Other" with low confidence (using canonical name)
        return CategorizationResult(
            category: "other",
            confidence: 0.3,
            matchedPattern: nil,
            matchType: .default_
        )
    }
    
    func learnFromCorrection(merchant: String, category: String) async throws {
        let normalizedMerchant = normalizeMerchant(merchant)
        
        // Fetch or create merchant pattern
        let fetchRequest: NSFetchRequest<MerchantPattern> = MerchantPattern.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "normalizedName == %@", normalizedMerchant)
        
        let existingPatterns = try context.fetch(fetchRequest)
        
        if let existingPattern = existingPatterns.first {
            // Update existing pattern
            existingPattern.category = category
            existingPattern.occurrenceCount += 1
            existingPattern.lastUsed = Date()
            existingPattern.updatedAt = Date()
            
            // Increase confidence with each occurrence (max 0.95)
            let newConfidence = min(0.95, existingPattern.confidence + 0.1)
            existingPattern.confidence = newConfidence
        } else {
            // Create new pattern
            let newPattern = MerchantPattern(context: context)
            newPattern.id = UUID()
            newPattern.merchantName = merchant
            newPattern.normalizedName = normalizedMerchant
            newPattern.category = category
            newPattern.confidence = 0.7 // Start with moderate confidence
            newPattern.occurrenceCount = 1
            newPattern.lastUsed = Date()
            newPattern.createdAt = Date()
            newPattern.updatedAt = Date()
        }
        
        try context.save()
    }
    
    func getSuggestedCategories(for merchant: String) async throws -> [CategorizationResult] {
        let normalizedMerchant = normalizeMerchant(merchant)
        var suggestions: [CategorizationResult] = []
        
        // Get learned patterns
        if let learned = try await checkLearnedPatterns(merchant: normalizedMerchant) {
            suggestions.append(learned)
        }
        
        // Get built-in patterns
        if let builtIn = checkBuiltInPatterns(merchant: normalizedMerchant) {
            suggestions.append(builtIn)
        }
        
        // Get similar merchant patterns
        let similarPatterns = try await findSimilarMerchants(merchant: normalizedMerchant)
        suggestions.append(contentsOf: similarPatterns)
        
        // Sort by confidence and return top 3
        return Array(suggestions.sorted { $0.confidence > $1.confidence }.prefix(3))
    }
    
    func getMerchantHistory(for merchant: String) async throws -> [String: Int] {
        let normalizedMerchant = normalizeMerchant(merchant)
        
        // Fetch all transactions for this merchant
        guard let transactionRepository = transactionRepository else {
            return [:]
        }
        
        let transactions = try await transactionRepository.fetchAll()
        let matchingTransactions = transactions.filter {
            normalizeMerchant($0.merchant ?? "") == normalizedMerchant
        }
        
        // Count categories
        var categoryCounts: [String: Int] = [:]
        for transaction in matchingTransactions {
            if let category = transaction.category {
                categoryCounts[category, default: 0] += 1
            }
        }
        
        return categoryCounts
    }
    
    // MARK: - Private Methods
    
    private func checkUserRules(merchant: String, amount: Decimal) async throws -> CategorizationResult? {
        return try await backgroundContextProvider.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<CategorizationRule> = CategorizationRule.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isActive == YES")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: false)]
            
            let rules = try context.fetch(fetchRequest)
        
        for rule in rules {
            guard let pattern = rule.merchantPattern,
                  let category = rule.category,
                  let matchType = rule.matchType else { continue }
            
            // Check amount constraints
            if let minAmount = rule.minAmount as Decimal?, amount < minAmount {
                continue
            }
            if let maxAmount = rule.maxAmount as Decimal?, amount > maxAmount {
                continue
            }
            
            // Check merchant pattern
            if self.matchesMerchant(merchant, pattern: pattern, matchType: matchType) {
                // Update application count
                rule.applicationCount += 1
                rule.updatedAt = Date()
                try context.safeSave()
                
                return CategorizationResult(
                    category: category,
                    confidence: 0.95,
                    matchedPattern: pattern,
                    matchType: .exactRule
                )
            }
        }
        
        return nil
        }
    }
    
    private func checkLearnedPatterns(merchant: String) async throws -> CategorizationResult? {
        return try await backgroundContextProvider.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<MerchantPattern> = MerchantPattern.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "normalizedName == %@", merchant)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "confidence", ascending: false)]
            
            let patterns = try context.fetch(fetchRequest)
        
            if let pattern = patterns.first, let category = pattern.category {
                return CategorizationResult(
                    category: category,
                    confidence: pattern.confidence,
                    matchedPattern: pattern.merchantName,
                    matchType: .learned
                )
            }
            
            return nil
        }
    }
    
    private func checkBuiltInPatterns(merchant: String) -> CategorizationResult? {
        for (key, value) in builtInPatterns {
            if merchant.contains(key) {
                return CategorizationResult(
                    category: value.canonicalCategory,
                    confidence: 0.8,
                    matchedPattern: value.pattern,
                    matchType: .patternMatch
                )
            }
        }
        return nil
    }
    
    private func findSimilarMerchants(merchant: String) async throws -> [CategorizationResult] {
        return try await backgroundContextProvider.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<MerchantPattern> = MerchantPattern.fetchRequest()
            let patterns = try context.fetch(fetchRequest)
        
            var results: [CategorizationResult] = []
            
            for pattern in patterns {
                guard let normalizedName = pattern.normalizedName,
                      let category = pattern.category else { continue }
                
                let similarity = self.calculateSimilarity(merchant, normalizedName)
                if similarity > 0.6 {
                    results.append(CategorizationResult(
                        category: category,
                        confidence: pattern.confidence * similarity,
                        matchedPattern: pattern.merchantName,
                        matchType: .learned
                    ))
                }
            }
            
            return results
        }
    }
    
    private func matchesMerchant(_ merchant: String, pattern: String, matchType: String) -> Bool {
        switch matchType {
        case "exact":
            return merchant == pattern.lowercased()
        case "contains":
            return merchant.contains(pattern.lowercased())
        case "startsWith":
            return merchant.hasPrefix(pattern.lowercased())
        case "regex":
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(merchant.startIndex..., in: merchant)
                return regex.firstMatch(in: merchant, range: range) != nil
            }
            return false
        default:
            return merchant.contains(pattern.lowercased())
        }
    }
    
    private func normalizeMerchant(_ merchant: String) -> String {
        return merchant
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"[^a-z0-9\s]"#, with: "", options: .regularExpression)
    }
    
    private func calculateSimilarity(_ str1: String, _ str2: String) -> Float {
        let longer = str1.count > str2.count ? str1 : str2
        let shorter = str1.count > str2.count ? str2 : str1
        
        if longer.isEmpty {
            return 1.0
        }
        
        let editDistance = levenshteinDistance(shorter, longer)
        return Float(longer.count - editDistance) / Float(longer.count)
    }
    
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let str1Array = Array(str1)
        let str2Array = Array(str2)
        
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: str2Array.count + 1), count: str1Array.count + 1)
        
        for i in 0...str1Array.count {
            matrix[i][0] = i
        }
        
        for j in 0...str2Array.count {
            matrix[0][j] = j
        }
        
        for i in 1...str1Array.count {
            for j in 1...str2Array.count {
                let cost = str1Array[i - 1] == str2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            }
        }
        
        return matrix[str1Array.count][str2Array.count]
    }
    
    // MARK: - Test Methods
    func suggestCategory(for merchant: String, amount: Decimal) async -> String? {
        do {
            let result = try await categorize(merchant: merchant, amount: amount)
            return result.category
        } catch {
            return nil
        }
    }
}
