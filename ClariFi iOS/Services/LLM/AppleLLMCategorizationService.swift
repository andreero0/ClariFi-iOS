//
//  AppleLLMCategorizationService.swift
//  ClariFi
//
//  Privacy-first LLM categorization service with fallback to pattern matching
//

import Foundation

/// Privacy-first LLM categorization service that uses Apple Foundation Model
/// with automatic fallback to pattern matching when LLM is unavailable
class AppleLLMCategorizationService: LLMCategorizationServiceProtocol {
    
    // MARK: - Properties
    
    private let modelManager: AppleFoundationModelManager
    private let fallbackService: CategoryServiceProtocol
    private let categoryMappingService: CategoryMappingServiceProtocol
    private let performanceMonitor: LLMPerformanceMonitor
    
    // Thread-safe cache using Swift actor
    private let cache = LLMCache()

    // Additional synchronous caches for non-async contexts
    private var responseCache: [String: LLMCategorizationResult] = [:]
    private var merchantNormalizationCache: [String: String] = [:]
    private let cacheQueue = DispatchQueue(label: "com.clarifi.llmCache", attributes: .concurrent)

    // Debouncing for rapid queries
    private var pendingQueries: [String: Task<LLMCategorizationResult, Error>] = [:]
    private let debounceQueue = DispatchQueue(label: "com.clarifi.llmDebounce", attributes: .concurrent)
    
    // MARK: - Initialization
    
    init(
        modelManager: AppleFoundationModelManager,
        fallbackService: CategoryServiceProtocol,
        categoryMappingService: CategoryMappingServiceProtocol
    ) {
        self.modelManager = modelManager
        self.fallbackService = fallbackService
        self.categoryMappingService = categoryMappingService
        self.performanceMonitor = LLMPerformanceMonitor.shared
    }
    
    // MARK: - LLMCategorizationServiceProtocol
    
    @MainActor
    func categorizeWithLLM(
        merchant: String,
        amount: Decimal,
        context: String?
    ) async throws -> LLMCategorizationResult {
        // Create cache key
        let cacheKey = "\(merchant.lowercased())_\(amount)"
        
        // Check cache first
        if let cached = await cache.getResponse(for: cacheKey) {
            print("Using cached LLM result for: \(merchant)")
            return cached
        }
        
        // Check for pending query (debouncing)
        if let pendingTask = debounceQueue.sync(execute: { pendingQueries[cacheKey] }) {
            print("⏳ Waiting for pending LLM query: \(merchant)")
            return try await pendingTask.value
        }
        
        // Start performance tracking
        let queryId = performanceMonitor.startQuery()
        
        // Check if LLM is available
        guard modelManager.isAvailable else {
            print("ℹ️ LLM not available, using fallback categorization")
            let result = try await fallbackToCategoryService(merchant: merchant, amount: amount)
            performanceMonitor.endQuery(queryId: queryId, method: result.method, category: result.category)
            await cache.setResponse(result, for: cacheKey)
            return result
        }
        
        // Create task for this query
        let task = Task<LLMCategorizationResult, Error> {
            do {
                // Construct prompt for categorization (optimized length)
                let prompt = buildOptimizedCategorizationPrompt(
                    merchant: merchant,
                    amount: amount,
                    context: context
                )
                
                // Query LLM
                let response = try await modelManager.query(prompt: prompt)
                
                // Parse response
                let result = parseCategorizationResponse(response)
                
                print("LLM categorization successful: \(result.category)")
                performanceMonitor.endQuery(queryId: queryId, method: result.method, category: result.category)
                
                // Cache the result
                await cache.setResponse(result, for: cacheKey)
                
                // Remove from pending
                debounceQueue.async(flags: .barrier) { [weak self] in
                    self?.pendingQueries.removeValue(forKey: cacheKey)
                }
                
                return result
            
            } catch let error as LLMError {
                // Log specific LLM error with user-friendly message
                print("LLM categorization failed: \(error.errorDescription ?? "Unknown error")")
                if let reason = error.failureReason {
                    print("   Reason: \(reason)")
                }
                if let suggestion = error.recoverySuggestion {
                    print("   Recovery: \(suggestion)")
                }
                
                performanceMonitor.endQueryWithError(queryId: queryId, error: error)
                let result = try await fallbackToCategoryService(merchant: merchant, amount: amount)
                
                // Cache fallback result
                await cache.setResponse(result, for: cacheKey)
                
                // Remove from pending
                debounceQueue.async(flags: .barrier) { [weak self] in
                    self?.pendingQueries.removeValue(forKey: cacheKey)
                }
                
                // Add note about fallback in result
                var fallbackResult = result
                fallbackResult.reasoning = "Fallback used: \(error.errorDescription ?? "LLM unavailable")"
                return fallbackResult
                
            } catch {
                // Log unexpected error
                print("Unexpected error during LLM categorization: \(error.localizedDescription)")
                performanceMonitor.endQueryWithError(queryId: queryId, error: error)
                let result = try await fallbackToCategoryService(merchant: merchant, amount: amount)
                
                // Cache fallback result
                await cache.setResponse(result, for: cacheKey)
                
                // Remove from pending
                debounceQueue.async(flags: .barrier) { [weak self] in
                    self?.pendingQueries.removeValue(forKey: cacheKey)
                }
                
                return result
            }
        }
        
        // Store pending task
        debounceQueue.async(flags: .barrier) { [weak self] in
            self?.pendingQueries[cacheKey] = task
        }
        
        return try await task.value
    }
    
    @MainActor
    func normalizeMerchantName(_ merchant: String) async throws -> String {
        let cacheKey = merchant.lowercased()
        
        // Check cache first
        if let cached = await cache.getMerchantNormalization(for: cacheKey) {
            print("Using cached merchant normalization for: \(merchant)")
            return cached
        }
        
        // Check if LLM is available
        guard modelManager.isAvailable else {
            let normalized = normalizeWithFallback(merchant)
            await cache.setMerchantNormalization(normalized, for: cacheKey)
            return normalized
        }
        
        do {
            let prompt = buildOptimizedNormalizationPrompt(merchant: merchant)
            let response = try await modelManager.query(prompt: prompt)
            let normalized = response.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Validate response is reasonable
            guard !normalized.isEmpty && normalized.count < 100 else {
                let fallback = normalizeWithFallback(merchant)
                await cache.setMerchantNormalization(fallback, for: cacheKey)
                return fallback
            }
            
            print("LLM merchant normalization: \(merchant) → \(normalized)")
            await cache.setMerchantNormalization(normalized, for: cacheKey)
            return normalized
            
        } catch {
            print("LLM normalization failed, using fallback")
            let fallback = normalizeWithFallback(merchant)
            cacheMerchantNormalization(cacheKey, normalized: fallback)
            return fallback
        }
    }
    
    @MainActor
    func extractTransactionData(from text: String) async throws -> [TransactionData] {
        // Check if LLM is available
        guard modelManager.isAvailable else {
            print("ℹ️ LLM not available, using fallback extraction")
            return try await extractWithFallback(text: text)
        }
        
        do {
            let prompt = buildExtractionPrompt(text: text)
            let response = try await modelManager.query(prompt: prompt)
            let transactions = parseTransactionData(response)
            
            print("LLM extracted \(transactions.count) transactions")
            return transactions
            
        } catch {
            print("LLM extraction failed: \(error.localizedDescription), using fallback")
            return try await extractWithFallback(text: text)
        }
    }
    
    // MARK: - Prompt Construction
    
    /// Optimized categorization prompt with reduced length
    private func buildOptimizedCategorizationPrompt(
        merchant: String,
        amount: Decimal,
        context: String?
    ) -> String {
        // Get only essential categories (top 10 most common)
        let essentialCategories = [
            "Food & Groceries", "Dining", "Transportation", "Housing",
            "Utilities", "Shopping", "Entertainment", "Healthcare",
            "Income", "Other"
        ]
        
        var prompt = "Categorize: \(merchant) $\(amount)"
        if let context = context {
            prompt += " (\(context))"
        }
        prompt += "\nCategories: \(essentialCategories.joined(separator: ", "))\nReturn category only:"
        
        return prompt
    }
    
    private func buildCategorizationPrompt(
        merchant: String,
        amount: Decimal,
        context: String?
    ) -> String {
        let categories = categoryMappingService.getAllCategories()
        let categoryList = categories.map { $0.displayName }.joined(separator: ", ")
        
        var prompt = """
        Categorize this financial transaction into one of the available categories.
        
        Transaction Details:
        - Merchant: \(merchant)
        - Amount: $\(amount)
        """
        
        if let context = context {
            prompt += "\n- Additional Context: \(context)"
        }
        
        prompt += """
        
        
        Available Categories:
        \(categoryList)
        
        Instructions:
        1. Analyze the merchant name and amount
        2. Select the most appropriate category from the list above
        3. Return ONLY the category name, nothing else
        4. If uncertain, choose the most likely category
        
        Category:
        """
        
        return prompt
    }
    
    /// Optimized normalization prompt with reduced length
    private func buildOptimizedNormalizationPrompt(merchant: String) -> String {
        return "Normalize merchant: \"\(merchant)\"\nRemove IDs, locations, codes. Return name only:"
    }
    
    private func buildNormalizationPrompt(merchant: String) -> String {
        return """
        Normalize this merchant name to a clean, standard format.
        
        Raw Merchant Name: "\(merchant)"
        
        Instructions:
        1. Remove transaction IDs, reference numbers, and codes
        2. Remove location identifiers (store numbers, addresses)
        3. Remove special characters and extra whitespace
        4. Keep the core business name
        5. Use proper capitalization
        6. Return ONLY the normalized name, nothing else
        
        Examples:
        - "WALMART #1234 ANYTOWN" → "Walmart"
        - "STARBUCKS STORE 5678" → "Starbucks"
        - "AMZ*AMAZON.COM" → "Amazon"
        
        Normalized Name:
        """
    }
    
    private func buildExtractionPrompt(text: String) -> String {
        return """
        Extract transaction data from the following text. This may be from a bank statement, receipt, or transaction list.
        
        Text:
        \(text)
        
        Instructions:
        1. Identify all transactions in the text
        2. For each transaction, extract: date, merchant name, and amount
        3. Format the output as JSON array with this structure:
        [
          {
            "date": "YYYY-MM-DD",
            "merchant": "Merchant Name",
            "amount": "123.45"
          }
        ]
        4. If a field cannot be determined, use null
        5. Return ONLY the JSON array, no additional text
        
        JSON:
        """
    }
    
    // MARK: - Response Parsing
    
    private func parseCategorizationResponse(_ response: String) -> LLMCategorizationResult {
        let normalized = response
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")
        
        // Try to find matching category
        let categories = categoryMappingService.getAllCategories()
        
        // First try exact match on display name
        if let match = categories.first(where: {
            $0.displayName.lowercased() == normalized.lowercased()
        }) {
            return LLMCategorizationResult(
                category: match.canonicalName,
                confidence: 0.9,
                normalizedMerchant: nil,
                method: .llm,
                reasoning: "LLM categorization"
            )
        }
        
        // Try exact match on canonical name
        if let match = categories.first(where: {
            $0.canonicalName.lowercased() == normalized.lowercased()
        }) {
            return LLMCategorizationResult(
                category: match.canonicalName,
                confidence: 0.9,
                normalizedMerchant: nil,
                method: .llm,
                reasoning: "LLM categorization"
            )
        }
        
        // Try partial match
        if let match = categories.first(where: {
            normalized.lowercased().contains($0.displayName.lowercased()) ||
            normalized.lowercased().contains($0.canonicalName.lowercased())
        }) {
            return LLMCategorizationResult(
                category: match.canonicalName,
                confidence: 0.7,
                normalizedMerchant: nil,
                method: .llm,
                reasoning: "LLM categorization (partial match)"
            )
        }
        
        // Default to "other"
        return LLMCategorizationResult(
            category: "other",
            confidence: 0.5,
            normalizedMerchant: nil,
            method: .llm,
            reasoning: "LLM categorization (default)"
        )
    }
    
    private func parseTransactionData(_ response: String) -> [TransactionData] {
        var transactions: [TransactionData] = []
        
        // Try to parse as JSON
        guard let jsonData = response.data(using: .utf8) else {
            return []
        }
        
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                for item in jsonArray {
                    if let transaction = parseTransactionItem(item) {
                        transactions.append(transaction)
                    }
                }
            }
        } catch {
            print("Failed to parse LLM transaction data: \(error)")
        }
        
        return transactions
    }
    
    private func parseTransactionItem(_ item: [String: Any]) -> TransactionData? {
        guard let merchant = item["merchant"] as? String,
              let amountString = item["amount"] as? String,
              let amount = Decimal(string: amountString) else {
            return nil
        }
        
        var date: Date?
        if let dateString = item["date"] as? String {
            let formatter = ISO8601DateFormatter()
            date = formatter.date(from: dateString)
        }
        
        return TransactionData(
            date: date,
            merchant: merchant,
            normalizedMerchant: nil,
            amount: amount,
            category: item["category"] as? String,
            confidence: 0.8,
            rawText: ""
        )
    }
    
    // MARK: - Fallback Methods
    
    private func fallbackToCategoryService(
        merchant: String,
        amount: Decimal
    ) async throws -> LLMCategorizationResult {
        let result = try await fallbackService.categorize(merchant: merchant, amount: amount)
        
        return LLMCategorizationResult(
            category: result.category,
            confidence: result.confidence,
            normalizedMerchant: nil,
            method: convertMatchType(result.matchType),
            reasoning: "Fallback: \(result.matchType)"
        )
    }
    
    private func normalizeWithFallback(_ merchant: String) -> String {
        // Basic normalization without LLM
        return merchant
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"#\d+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\d{4,}"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractWithFallback(text: String) async throws -> [TransactionData] {
        // Basic regex-based extraction
        var transactions: [TransactionData] = []
        
        // Pattern: date, merchant, amount
        let pattern = #"(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\s+([A-Za-z0-9\s&'-]+?)\s+\$?(\d+\.\d{2})"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            guard match.numberOfRanges == 4 else { continue }
            
            let dateString = nsString.substring(with: match.range(at: 1))
            let merchant = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
            let amountString = nsString.substring(with: match.range(at: 3))
            
            if let amount = Decimal(string: amountString) {
                let date = parseDate(dateString)
                
                transactions.append(TransactionData(
                    date: date,
                    merchant: merchant,
                    normalizedMerchant: normalizeWithFallback(merchant),
                    amount: amount,
                    category: nil,
                    confidence: 0.6,
                    rawText: nsString.substring(with: match.range)
                ))
            }
        }
        
        return transactions
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatters = [
            "MM/dd/yyyy",
            "MM-dd-yyyy",
            "M/d/yy",
            "M-d-yy"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    private func convertMatchType(_ matchType: CategorizationResult.MatchType) -> CategorizationMethod {
        switch matchType {
        case .exactRule:
            return .rule
        case .patternMatch:
            return .pattern
        case .learned:
            return .learned
        case .llm:
            return .llm
        case .default_:
            return .pattern
        }
    }
    
    // MARK: - Cache Management
    
    
    /// Clear all caches
    func clearCaches() {
        Task {
            await cache.clearAll()
        }

        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.responseCache.removeAll()
            self?.merchantNormalizationCache.removeAll()
        }

        debounceQueue.async(flags: .barrier) { [weak self] in
            self?.pendingQueries.removeAll()
        }

        print("LLM caches cleared")
    }

    /// Cache merchant normalization synchronously
    private func cacheMerchantNormalization(_ key: String, normalized: String) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.merchantNormalizationCache[key] = normalized
        }
    }

    /// Get cache statistics
    func getCacheStatistics() -> (responseCache: Int, merchantCache: Int, pending: Int) {
        return cacheQueue.sync {
            let responseCount = responseCache.count
            let merchantCount = merchantNormalizationCache.count
            let pendingCount = debounceQueue.sync { pendingQueries.count }
            return (responseCount, merchantCount, pendingCount)
        }
    }
}
