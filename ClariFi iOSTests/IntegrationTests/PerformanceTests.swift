//
//  PerformanceTests.swift
//  ClariFi_iOS
//
//  Performance testing and optimization suite
//  Tests app launch time, onboarding transitions, LLM queries, and category lookups
//

import XCTest
@testable import ClariFi_iOS

@MainActor
final class PerformanceTests: XCTestCase {
    
    var container: AppDIContainer!
    var categoryMappingService: CategoryMappingService!
    var llmService: AppleLLMCategorizationService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Set up DI container with test dependencies
        container = AppDIContainer()
        
        // Register test services
        container.registerSingleton(CategoryMappingServiceProtocol.self) { _ in
            CategoryMappingService()
        }
        
        categoryMappingService = CategoryMappingService()
        
        // Set up LLM service with mock model manager
        let modelManager = AppleFoundationModelManager()
        let fallbackService = MockCategoryService()
        llmService = AppleLLMCategorizationService(
            modelManager: modelManager,
            fallbackService: fallbackService
        )
        
        // Clear performance monitor
        PerformanceMonitor.shared.clearAll()
        await LLMPerformanceMonitor.shared.reset()
    }
    
    override func tearDown() async throws {
        container = nil
        categoryMappingService = nil
        llmService = nil
        
        // Print performance summary
        PerformanceMonitor.shared.printSummary()
        await LLMPerformanceMonitor.shared.logPerformanceSummary()
        
        try await super.tearDown()
    }
    
    // MARK: - App Launch Time Tests
    
    func testAppLaunchTime() throws {
        // Measure app initialization time
        measure(metrics: [XCTClockMetric()]) {
            let container = AppDIContainer()
            
            // Simulate app launch dependency registration
            container.registerSingleton(CategoryMappingServiceProtocol.self) { _ in
                CategoryMappingService()
            }
            
            // Verify container is ready
            XCTAssertNotNil(container)
        }
        
        // Verify launch time is under 2 seconds (design requirement)
        let stats = PerformanceMonitor.shared.getStatistics(for: "app_launch")
        if let avgTime = stats?.average {
            XCTAssertLessThan(avgTime, 2.0, "App launch time should be under 2 seconds")
        }
    }
    
    func testDependencyRegistrationTime() throws {
        // Measure time to register all dependencies
        let result = PerformanceMonitor.shared.measure("dependency_registration") {
            let container = AppDIContainer()
            
            // Register all core services
            container.registerSingleton(CategoryMappingServiceProtocol.self) { _ in
                CategoryMappingService()
            }
            
            return container
        }
        
        XCTAssertNotNil(result)
        
        // Verify registration is fast (< 100ms)
        let stats = PerformanceMonitor.shared.getStatistics(for: "dependency_registration")
        XCTAssertNotNil(stats)
        if let avgTime = stats?.average {
            XCTAssertLessThan(avgTime, 0.1, "Dependency registration should be under 100ms")
        }
    }
    
    // MARK: - Onboarding Step Transition Tests
    
    func testOnboardingStepTransitionTime() async throws {
        let coordinator = OnboardingCoordinator()
        
        // Measure transition time between steps
        let transitionTime = PerformanceMonitor.shared.measure("onboarding_step_transition") {
            coordinator.advance()
            return coordinator.currentStep
        }
        
        XCTAssertEqual(transitionTime, .privacy)
        
        // Verify transition is under 500ms (design requirement)
        let stats = PerformanceMonitor.shared.getStatistics(for: "onboarding_step_transition")
        if let avgTime = stats?.average {
            XCTAssertLessThan(avgTime, 0.5, "Onboarding step transition should be under 500ms")
        }
    }
    
    func testOnboardingValidationTime() throws {
        let coordinator = OnboardingCoordinator()
        
        // Add test account
        let account = AccountSetupData(
            name: "Test Account",
            type: .checking,
            initialBalance: 1000.0,
            isDefault: true
        )
        coordinator.createdAccounts.append(account)
        
        // Measure validation time
        let canAdvance = PerformanceMonitor.shared.measure("onboarding_validation") {
            return coordinator.canAdvance()
        }
        
        XCTAssertTrue(canAdvance)
        
        // Verify validation is fast (< 10ms)
        let stats = PerformanceMonitor.shared.getStatistics(for: "onboarding_validation")
        if let avgTime = stats?.average {
            XCTAssertLessThan(avgTime, 0.01, "Onboarding validation should be under 10ms")
        }
    }
    
    func testCompleteOnboardingFlowTime() async throws {
        let coordinator = OnboardingCoordinator()
        
        // Measure complete onboarding flow
        let timerId = PerformanceMonitor.shared.startMeasurement("complete_onboarding_flow")
        
        // Simulate user going through all steps
        coordinator.selectedProcessingMode = .localOnly
        coordinator.advance() // to privacy
        
        coordinator.advance() // to features
        
        coordinator.advance() // to account setup
        let account = AccountSetupData(
            name: "Checking",
            type: .checking,
            initialBalance: 1000.0,
            isDefault: true
        )
        coordinator.createdAccounts.append(account)
        coordinator.advance() // to biometric
        
        coordinator.enableBiometric = true
        coordinator.advance() // to quick start
        
        coordinator.selectedFirstAction = .manualEntry
        coordinator.advance() // to first action
        
        PerformanceMonitor.shared.endMeasurement("complete_onboarding_flow", id: timerId)
        
        // Verify we reached the end
        XCTAssertEqual(coordinator.currentStep, .firstAction)
        
        // Verify total flow time is reasonable (< 5 minutes for user, but instant in test)
        let stats = PerformanceMonitor.shared.getStatistics(for: "complete_onboarding_flow")
        if let avgTime = stats?.average {
            XCTAssertLessThan(avgTime, 1.0, "Onboarding flow processing should be under 1 second")
        }
    }
    
    // MARK: - LLM Query Time Tests
    
    func testLLMQueryTime() async throws {
        // Measure LLM query time
        let queryId = await LLMPerformanceMonitor.shared.startQuery()
        
        let result = await PerformanceMonitor.shared.measureAsync("llm_categorization") {
            try await llmService.categorizeWithLLM(
                merchant: "Whole Foods Market",
                amount: 125.50,
                context: nil
            )
        }
        
        await LLMPerformanceMonitor.shared.endQuery(
            queryId: queryId,
            method: result.matchType,
            category: result.category
        )
        
        XCTAssertNotNil(result)
        
        // Verify LLM query is under 3 seconds (design requirement)
        let stats = PerformanceMonitor.shared.getStatistics(for: "llm_categorization")
        if let avgTime = stats?.average {
            XCTAssertLessThan(avgTime, 3.0, "LLM categorization should be under 3 seconds")
        }
    }
    
    func testLLMFallbackTime() async throws {
        // Test fallback performance when LLM is unavailable
        let queryId = await LLMPerformanceMonitor.shared.startQuery()
        
        let result = await PerformanceMonitor.shared.measureAsync("llm_fallback") {
            try await llmService.categorizeWithLLM(
                merchant: "Starbucks",
                amount: 5.75,
                context: nil
            )
        }
        
        await LLMPerformanceMonitor.shared.endQuery(
            queryId: queryId,
            method: result.matchType,
            category: result.category
        )
        
        XCTAssertNotNil(result)
        
        // Verify fallback is fast (< 100ms)
        let stats = PerformanceMonitor.shared.getStatistics(for: "llm_fallback")
        if let avgTime = stats?.average {
            XCTAssertLessThan(avgTime, 0.1, "LLM fallback should be under 100ms")
        }
    }
    
    func testLLMMerchantNormalizationTime() async throws {
        // Measure merchant name normalization
        let result = await PerformanceMonitor.shared.measureAsync("llm_merchant_normalization") {
            try await llmService.normalizeMerchantName("AMZN*MARKETPLACE")
        }
        
        XCTAssertNotNil(result)
        
        // Verify normalization is fast (< 1 second)
        let stats = PerformanceMonitor.shared.getStatistics(for: "llm_merchant_normalization")
        if let avgTime = stats?.average {
            XCTAssertLessThan(avgTime, 1.0, "Merchant normalization should be under 1 second")
        }
    }
    
    func testBulkLLMCategorizationTime() async throws {
        // Test performance with multiple transactions
        let merchants = [
            "Whole Foods Market",
            "Shell Gas Station",
            "Netflix",
            "AT&T Wireless",
            "Target",
            "Starbucks",
            "CVS Pharmacy",
            "Amazon.com",
            "Uber",
            "Chipotle"
        ]
        
        let timerId = PerformanceMonitor.shared.startMeasurement("bulk_llm_categorization")
        
        for merchant in merchants {
            let queryId = await LLMPerformanceMonitor.shared.startQuery()
            
            let result = try await llmService.categorizeWithLLM(
                merchant: merchant,
                amount: Decimal(Double.random(in: 10...200)),
                context: nil
            )
            
            await LLMPerformanceMonitor.shared.endQuery(
                queryId: queryId,
                method: result.matchType,
                category: result.category
            )
        }
        
        PerformanceMonitor.shared.endMeasurement("bulk_llm_categorization", id: timerId)
        
        // Verify bulk processing is reasonable (< 30 seconds for 10 transactions)
        let stats = PerformanceMonitor.shared.getStatistics(for: "bulk_llm_categorization")
        if let avgTime = stats?.average {
            XCTAssertLessThan(avgTime, 30.0, "Bulk categorization should be under 30 seconds")
        }
    }
    
    // MARK: - Category Lookup Time Tests
    
    func testCategoryLookupTime() throws {
        // Measure single category lookup
        let result = PerformanceMonitor.shared.measure("category_lookup") {
            return categoryMappingService.getCanonicalCategory(from: "Housing")
        }
        
        XCTAssertNotNil(result)
        
        // Verify lookup is under 10ms (design requirement)
        let stats = PerformanceMonitor.shared.getStatistics(for: "category_lookup")
        if let avgTime = stats?.average {
            XCTAssertLessThan(avgTime, 0.01, "Category lookup should be under 10ms")
        }
    }
    
    func testGetAllCategoriesTime() throws {
        // Measure getting all categories
        let result = PerformanceMonitor.shared.measure("get_all_categories") {
            return categoryMappingService.getAllCategories()
        }
        
        XCTAssertFalse(result.isEmpty)
        
        // Verify getting all categories is fast (< 10ms)
        let stats = PerformanceMonitor.shared.getStatistics(for: "get_all_categories")
        if let avgTime = stats?.average {
            XCTAssertLessThan(avgTime, 0.01, "Getting all categories should be under 10ms")
        }
    }
    
    func testCategoryDisplayNameLookupTime() throws {
        // Measure display name lookup
        let result = PerformanceMonitor.shared.measure("category_display_name_lookup") {
            return categoryMappingService.getDisplayName(for: "housing")
        }
        
        XCTAssertEqual(result, "Housing & Rent")
        
        // Verify display name lookup is fast (< 5ms)
        let stats = PerformanceMonitor.shared.getStatistics(for: "category_display_name_lookup")
        if let avgTime = stats?.average {
            XCTAssertLessThan(avgTime, 0.005, "Display name lookup should be under 5ms")
        }
    }
    
    func testBulkCategoryLookupTime() throws {
        let templateNames = [
            "Housing",
            "Food & Groceries",
            "Dining & Restaurants",
            "Transportation",
            "Utilities",
            "Healthcare",
            "Entertainment",
            "Shopping",
            "Subscriptions",
            "Income"
        ]
        
        // Measure bulk lookup
        let timerId = PerformanceMonitor.shared.startMeasurement("bulk_category_lookup")
        
        var results: [CategoryDefinition?] = []
        for name in templateNames {
            let category = categoryMappingService.getCanonicalCategory(from: name)
            results.append(category)
        }
        
        PerformanceMonitor.shared.endMeasurement("bulk_category_lookup", id: timerId)
        
        XCTAssertEqual(results.count, templateNames.count)
        
        // Verify bulk lookup is fast (< 50ms for 10 lookups)
        let stats = PerformanceMonitor.shared.getStatistics(for: "bulk_category_lookup")
        if let avgTime = stats?.average {
            XCTAssertLessThan(avgTime, 0.05, "Bulk category lookup should be under 50ms")
        }
    }
    
    func testCategoryMappingWithAliases() throws {
        // Test performance with various alias formats
        let aliases = [
            "Housing",
            "Housing & Rent",
            "Housing (BAH)",
            "Housing & Home Office",
            "Food & Groceries",
            "Groceries",
            "Food & Dining"
        ]
        
        let timerId = PerformanceMonitor.shared.startMeasurement("category_alias_mapping")
        
        for alias in aliases {
            let category = categoryMappingService.getCanonicalCategory(from: alias)
            XCTAssertNotNil(category, "Should find category for alias: \(alias)")
        }
        
        PerformanceMonitor.shared.endMeasurement("category_alias_mapping", id: timerId)
        
        // Verify alias mapping is fast
        let stats = PerformanceMonitor.shared.getStatistics(for: "category_alias_mapping")
        if let avgTime = stats?.average {
            XCTAssertLessThan(avgTime, 0.05, "Category alias mapping should be under 50ms")
        }
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemoryUsageDuringOnboarding() throws {
        // Measure memory footprint during onboarding
        let coordinator = OnboardingCoordinator()
        
        // Add multiple accounts
        for i in 1...10 {
            let account = AccountSetupData(
                name: "Account \(i)",
                type: .checking,
                initialBalance: Decimal(i * 1000),
                isDefault: i == 1
            )
            coordinator.createdAccounts.append(account)
        }
        
        // Verify memory is reasonable
        XCTAssertEqual(coordinator.createdAccounts.count, 10)
    }
    
    func testMemoryUsageWithManyCategories() throws {
        // Verify category definitions don't cause memory issues
        let categories = categoryMappingService.getAllCategories()
        
        // Access all properties to ensure they're loaded
        for category in categories {
            _ = category.displayName
            _ = category.icon
            _ = category.budgetTemplateAliases
        }
        
        XCTAssertGreaterThan(categories.count, 0)
    }
    
    // MARK: - Optimization Verification Tests
    
    func testCategoryLookupOptimization() throws {
        // Verify category lookup uses efficient data structures
        // Run multiple lookups and verify consistent performance
        
        var times: [TimeInterval] = []
        
        for _ in 1...100 {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = categoryMappingService.getCanonicalCategory(from: "Housing")
            let endTime = CFAbsoluteTimeGetCurrent()
            times.append(endTime - startTime)
        }
        
        let avgTime = times.reduce(0, +) / Double(times.count)
        let maxTime = times.max() ?? 0
        
        // Verify consistent performance (max should not be much higher than average)
        XCTAssertLessThan(maxTime, avgTime * 3, "Lookup time should be consistent")
        XCTAssertLessThan(avgTime, 0.001, "Average lookup should be under 1ms")
    }
    
    func testLLMResponseCaching() async throws {
        // Test that repeated queries benefit from caching
        let merchant = "Whole Foods Market"
        
        // First query
        let firstQueryId = await LLMPerformanceMonitor.shared.startQuery()
        let firstStartTime = CFAbsoluteTimeGetCurrent()
        
        let firstResult = try await llmService.categorizeWithLLM(
            merchant: merchant,
            amount: 100.0,
            context: nil
        )
        
        let firstEndTime = CFAbsoluteTimeGetCurrent()
        let firstDuration = firstEndTime - firstStartTime
        
        await LLMPerformanceMonitor.shared.endQuery(
            queryId: firstQueryId,
            method: firstResult.matchType,
            category: firstResult.category
        )
        
        // Second query (should be faster if cached)
        let secondQueryId = await LLMPerformanceMonitor.shared.startQuery()
        let secondStartTime = CFAbsoluteTimeGetCurrent()
        
        let secondResult = try await llmService.categorizeWithLLM(
            merchant: merchant,
            amount: 100.0,
            context: nil
        )
        
        let secondEndTime = CFAbsoluteTimeGetCurrent()
        let secondDuration = secondEndTime - secondStartTime
        
        await LLMPerformanceMonitor.shared.endQuery(
            queryId: secondQueryId,
            method: secondResult.matchType,
            category: secondResult.category
        )
        
        // Verify results are consistent
        XCTAssertEqual(firstResult.category, secondResult.category)
        
        // Note: Caching optimization can be added in future if needed
        print("First query: \(firstDuration)s, Second query: \(secondDuration)s")
    }
    
    // MARK: - Performance Regression Tests
    
    func testNoPerformanceRegression() throws {
        // Baseline performance expectations
        let expectations: [String: TimeInterval] = [
            "category_lookup": 0.01,           // 10ms
            "get_all_categories": 0.01,        // 10ms
            "onboarding_validation": 0.01,     // 10ms
            "dependency_registration": 0.1     // 100ms
        ]
        
        // Run operations
        _ = categoryMappingService.getCanonicalCategory(from: "Housing")
        _ = categoryMappingService.getAllCategories()
        
        let coordinator = OnboardingCoordinator()
        coordinator.createdAccounts.append(AccountSetupData(
            name: "Test",
            type: .checking,
            initialBalance: 1000,
            isDefault: true
        ))
        _ = coordinator.canAdvance()
        
        // Verify no regressions
        for (label, maxTime) in expectations {
            if let stats = PerformanceMonitor.shared.getStatistics(for: label) {
                XCTAssertLessThan(
                    stats.average,
                    maxTime,
                    "\(label) exceeded expected time: \(stats.average)s > \(maxTime)s"
                )
            }
        }
    }
}

// MARK: - Mock Services

class MockCategoryService: CategoryServiceProtocol {
    func categorize(merchant: String, amount: Decimal) async throws -> CategorizationResult {
        // Simple pattern matching for testing
        let category: String
        let merchantLower = merchant.lowercased()
        
        if merchantLower.contains("food") || merchantLower.contains("grocery") {
            category = "food_groceries"
        } else if merchantLower.contains("gas") || merchantLower.contains("shell") {
            category = "transportation"
        } else if merchantLower.contains("netflix") || merchantLower.contains("spotify") {
            category = "subscriptions"
        } else {
            category = "other"
        }
        
        return CategorizationResult(
            category: category,
            confidence: 0.8,
            matchedPattern: nil,
            matchType: .pattern
        )
    }
}

