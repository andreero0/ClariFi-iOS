//
//  CategoryMappingService.swift
//  ClariFi iOS
//
//  Created by Kiro on 2025-10-13.
//

import Foundation

/// Protocol for category mapping operations
protocol CategoryMappingServiceProtocol {
    func getCanonicalCategory(from templateName: String) -> CategoryDefinition?
    func getCanonicalCategoryWithFallback(from templateName: String) -> CategoryDefinition
    func getDisplayName(for canonicalName: String) -> String
    func getAllCategories() -> [CategoryDefinition]
    func getCategoriesForBudgetTemplate(_ templateId: String) -> [CategoryDefinition]
}

/// Service for mapping between different category naming systems
class CategoryMappingService: CategoryMappingServiceProtocol {
    
    // MARK: - Properties
    
    private let definitions = CategoryDefinition.allCategories
    
    // O(1) lookup by canonical name
    private lazy var canonicalNameLookup: [String: CategoryDefinition] = {
        Dictionary(uniqueKeysWithValues: definitions.map { ($0.canonicalName, $0) })
    }()
    
    // O(1) lookup by display name (case-insensitive)
    private lazy var displayNameLookup: [String: CategoryDefinition] = {
        Dictionary(uniqueKeysWithValues: definitions.map { ($0.displayName.lowercased(), $0) })
    }()
    
    // O(1) lookup by template alias (case-insensitive)
    private lazy var aliasLookup: [String: CategoryDefinition] = {
        var lookup: [String: CategoryDefinition] = [:]
        for category in definitions {
            for alias in category.budgetTemplateAliases {
                lookup[alias.lowercased()] = category
            }
        }
        return lookup
    }()
    
    // Cache for template name lookups to avoid repeated searches
    private var templateNameCache: [String: CategoryDefinition] = [:]
    private let cacheQueue = DispatchQueue(label: "com.clarifi.categoryMappingCache", attributes: .concurrent)
    
    // MARK: - Public Methods
    
    /// Get canonical category from a template-specific name
    /// - Parameter templateName: The category name from a budget template
    /// - Returns: The canonical CategoryDefinition, or nil if not found
    func getCanonicalCategory(from templateName: String) -> CategoryDefinition? {
        return PerformanceMonitor.shared.measure("category_lookup") {
            let normalized = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedLower = normalized.lowercased()
            
            // Check cache first (O(1))
            if let cached = cacheQueue.sync(execute: { templateNameCache[normalizedLower] }) {
                return cached
            }
        
        // Try exact match on canonical name (O(1))
        if let category = canonicalNameLookup[normalizedLower] {
            cacheResult(normalizedLower, category: category)
            return category
        }
        
        // Try exact match on display name (O(1))
        if let category = displayNameLookup[normalizedLower] {
            cacheResult(normalizedLower, category: category)
            return category
        }
        
        // Try matching against template aliases (O(1))
        if let category = aliasLookup[normalizedLower] {
            cacheResult(normalizedLower, category: category)
            return category
        }
        
            // Try partial matching as last resort (O(n) - only when exact matches fail)
            if let category = definitions.first(where: { category in
                category.budgetTemplateAliases.contains { alias in
                    alias.lowercased().contains(normalizedLower) ||
                    normalizedLower.contains(alias.lowercased())
                }
            }) {
                cacheResult(normalizedLower, category: category)
                return category
            }
            
            return nil
        }
    }
    
    /// Cache a lookup result for faster future access
    private func cacheResult(_ key: String, category: CategoryDefinition) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.templateNameCache[key] = category
        }
    }
    
    /// Clear the lookup cache (useful for testing or memory management)
    func clearCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.templateNameCache.removeAll()
        }
    }
    
    /// Get canonical category with automatic fallback to "other"
    /// - Parameter templateName: The category name from a budget template
    /// - Returns: The canonical CategoryDefinition, or "other" category if not found
    func getCanonicalCategoryWithFallback(from templateName: String) -> CategoryDefinition {
        // Try to find the category
        if let category = getCanonicalCategory(from: templateName) {
            return category
        }
        
        // Log the mapping failure
        print("Category mapping failed for: '\(templateName)'")
        print("   Defaulting to 'Other' category")
        print("   This category name should be added to the mapping system")
        
        // Return "other" category as fallback
        if let otherCategory = canonicalNameLookup["other"] {
            return otherCategory
        }
        
        // Ultimate fallback if "other" doesn't exist (should never happen)
        return CategoryDefinition(
            id: "other",
            canonicalName: "other",
            displayName: "Other",
            icon: "questionmark.circle",
            parentCategory: nil,
            isEssential: false,
            budgetTemplateAliases: ["Other", "Miscellaneous", "Uncategorized"]
        )
    }
    
    /// Get display name for a canonical category name
    /// - Parameter canonicalName: The canonical category name
    /// - Returns: The user-facing display name, or the canonical name if not found
    func getDisplayName(for canonicalName: String) -> String {
        return canonicalNameLookup[canonicalName]?.displayName ?? canonicalName
    }
    
    /// Get all available categories
    /// - Returns: Array of all CategoryDefinitions
    func getAllCategories() -> [CategoryDefinition] {
        return definitions
    }
    
    /// Get categories relevant for a specific budget template
    /// - Parameter templateId: The budget template identifier
    /// - Returns: Array of CategoryDefinitions used in that template
    func getCategoriesForBudgetTemplate(_ templateId: String) -> [CategoryDefinition] {
        // For now, return all categories except income and transfer
        // This can be refined based on specific template requirements
        return definitions.filter { category in
            category.canonicalName != "income" &&
            category.canonicalName != "transfer"
        }
    }
}
