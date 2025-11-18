//
//  LLMCache.swift
//  ClariFi iOS
//
//  Created by AI Assistant on 2025-10-10.
//
//  Thread-safe cache for LLM categorization results using Swift actors
//

import Foundation

/// Thread-safe cache for LLM categorization results
actor LLMCache {
    
    // MARK: - Properties
    
    private var responseCache: [String: LLMCategorizationResult] = [:]
    private var merchantNormalizationCache: [String: String] = [:]
    
    private let maxResponseCacheSize = 1000
    private let maxMerchantCacheSize = 500
    
    // MARK: - Response Cache Methods
    
    func getResponse(for key: String) -> LLMCategorizationResult? {
        return responseCache[key]
    }
    
    func setResponse(_ result: LLMCategorizationResult, for key: String) {
        responseCache[key] = result
        
        // Limit cache size to prevent memory issues
        if responseCache.count > maxResponseCacheSize {
            // Remove oldest 100 entries (simple FIFO)
            let keysToRemove = Array(responseCache.keys.prefix(100))
            keysToRemove.forEach { responseCache.removeValue(forKey: $0) }
        }
    }
    
    // MARK: - Merchant Normalization Cache Methods
    
    func getMerchantNormalization(for key: String) -> String? {
        return merchantNormalizationCache[key]
    }
    
    func setMerchantNormalization(_ normalized: String, for key: String) {
        merchantNormalizationCache[key] = normalized
        
        // Limit cache size to prevent memory issues
        if merchantNormalizationCache.count > maxMerchantCacheSize {
            let keysToRemove = Array(merchantNormalizationCache.keys.prefix(50))
            keysToRemove.forEach { merchantNormalizationCache.removeValue(forKey: $0) }
        }
    }
    
    // MARK: - Cache Management
    
    func clearAll() {
        responseCache.removeAll()
        merchantNormalizationCache.removeAll()
    }
    
    func clearResponseCache() {
        responseCache.removeAll()
    }
    
    func clearMerchantCache() {
        merchantNormalizationCache.removeAll()
    }
    
    // MARK: - Cache Statistics
    
    var responseCacheSize: Int {
        return responseCache.count
    }
    
    var merchantCacheSize: Int {
        return merchantNormalizationCache.count
    }
    
    var totalCacheSize: Int {
        return responseCache.count + merchantNormalizationCache.count
    }
}
