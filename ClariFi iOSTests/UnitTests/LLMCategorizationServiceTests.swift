//
//  LLMCategorizationServiceTests.swift
//  ClariFi_iOS Tests
//
//  Unit tests for LLM categorization service with fallback behavior
//

import XCTest
@testable import ClariFi_iOS

@MainActor
final class LLMCategorizationServiceTests: XCTestCase {
    
    var sut: AppleLLMCategorizationService!
    var mockModelManager: MockAppleFoundationModelManager!
    var mockCategoryService: MockCategoryService!
    var mockCategoryMappingService: MockCategoryMappingService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockModelManager = MockAppleFoundationModelManager()
        mockCategoryService = MockCategoryService()
        mockCategoryMappingService = MockCategoryMappingService()
        
        sut = AppleLLMCategorizationService(
            modelManager: mockModelManager,
            fallbackService: mockCategoryService,
            categoryMappingService: mockCategoryMappingService
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        mockModelManager = nil
        mockCategoryService = nil
        mockCategoryMappingService = nil
        try await super.tearDown()
    }
    
    // MARK: - Fallback Behavior Tests
    
    func testCategorizeWithLLM_WhenModelUnavailable_UsesFallback() async throws {
        // Given
        mockModelManager.isAvailable = false
        mockCategoryService.mockCategorizationResult = CategorizationResult(
            category: "food_groceries",
            confidence: 0.8,
            matchedPattern: "walmart",
            matchType: .patternMatch
        )
        
        // When
        let result = try await sut.categorizeWithLLM(
            merchant: "Walmart",
            amount: 50.00,
            context: nil
        )
        
        // Then
        XCTAssertTrue(mockCategoryService.categorizeCalled)
        XCTAssertEqual(result.category, "food_groceries")
        XCTAssertEqual(result.method, .pattern)
    }
    
    func testNormalizeMerchantName_WhenModelUnavailable_UsesFallback() async throws {
        // Given
        mockModelManager.isAvailable = false
        let merchant = "WALMART #1234 ANYTOWN"
        
        // When
        let normalized = try await sut.normalizeMerchantName(merchant)
        
        // Then
        XCTAssertNotEqual(normalized, merchant)
        XCTAssertFalse(normalized.contains("#1234"))
    }
    
    func testExtractTransactionData_WhenModelUnavailable_UsesFallback() async throws {
        // Given
        mockModelManager.isAvailable = false
        let text = "01/15/2024 Starbucks $5.50\n01/16/2024 Walmart $45.00"
        
        // When
        let transactions = try await sut.extractTransactionData(from: text)
        
        // Then
        XCTAssertGreaterThan(transactions.count, 0)
    }
    
    func testCategorizeWithLLM_WhenLLMFails_UsesFallback() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.shouldThrowError = true
        mockCategoryService.mockCategorizationResult = CategorizationResult(
            category: "dining",
            confidence: 0.7,
            matchedPattern: "starbucks",
            matchType: .patternMatch
        )
        
        // When
        let result = try await sut.categorizeWithLLM(
            merchant: "Starbucks",
            amount: 5.50,
            context: nil
        )
        
        // Then
        XCTAssertTrue(mockCategoryService.categorizeCalled)
        XCTAssertEqual(result.category, "dining")
        XCTAssertEqual(result.method, .pattern)
    }
    
    // MARK: - Prompt Construction Tests
    
    func testBuildCategorizationPrompt_IncludesMerchantAndAmount() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.mockResponse = "food_groceries"
        mockCategoryMappingService.mockCategories = [
            CategoryDefinition.foodGroceries,
            CategoryDefinition.dining
        ]
        
        // When
        _ = try await sut.categorizeWithLLM(
            merchant: "Whole Foods",
            amount: 75.00,
            context: nil
        )
        
        // Then
        XCTAssertTrue(mockModelManager.queryCalled)
        let prompt = mockModelManager.lastPrompt ?? ""
        XCTAssertTrue(prompt.contains("Whole Foods"))
        XCTAssertTrue(prompt.contains("75"))
    }
    
    func testBuildCategorizationPrompt_IncludesContext() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.mockResponse = "healthcare"
        
        // When
        _ = try await sut.categorizeWithLLM(
            merchant: "CVS Pharmacy",
            amount: 25.00,
            context: "prescription medication"
        )
        
        // Then
        let prompt = mockModelManager.lastPrompt ?? ""
        XCTAssertTrue(prompt.contains("prescription medication"))
    }
    
    func testBuildCategorizationPrompt_IncludesAvailableCategories() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.mockResponse = "housing"
        mockCategoryMappingService.mockCategories = [
            CategoryDefinition.housing,
            CategoryDefinition.utilities
        ]
        
        // When
        _ = try await sut.categorizeWithLLM(
            merchant: "Property Management",
            amount: 1500.00,
            context: nil
        )
        
        // Then
        let prompt = mockModelManager.lastPrompt ?? ""
        XCTAssertTrue(prompt.contains("Housing & Rent"))
        XCTAssertTrue(prompt.contains("Utilities"))
    }
    
    func testBuildNormalizationPrompt_IncludesExamples() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.mockResponse = "Walmart"
        
        // When
        _ = try await sut.normalizeMerchantName("WALMART #1234")
        
        // Then
        let prompt = mockModelManager.lastPrompt ?? ""
        XCTAssertTrue(prompt.contains("WALMART #1234"))
        XCTAssertTrue(prompt.contains("Examples") || prompt.contains("example"))
    }
    
    func testBuildExtractionPrompt_RequestsJSONFormat() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.mockResponse = "[]"
        
        // When
        _ = try await sut.extractTransactionData(from: "test text")
        
        // Then
        let prompt = mockModelManager.lastPrompt ?? ""
        XCTAssertTrue(prompt.contains("JSON") || prompt.contains("json"))
    }
    
    // MARK: - Response Parsing Tests
    
    func testParseCategorizationResponse_WithExactDisplayName() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.mockResponse = "Housing & Rent"
        mockCategoryMappingService.mockCategories = [CategoryDefinition.housing]
        
        // When
        let result = try await sut.categorizeWithLLM(
            merchant: "Landlord",
            amount: 1500.00,
            context: nil
        )
        
        // Then
        XCTAssertEqual(result.category, "housing")
        XCTAssertEqual(result.method, .llm)
        XCTAssertGreaterThan(result.confidence, 0.8)
    }
    
    func testParseCategorizationResponse_WithCanonicalName() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.mockResponse = "food_groceries"
        mockCategoryMappingService.mockCategories = [CategoryDefinition.foodGroceries]
        
        // When
        let result = try await sut.categorizeWithLLM(
            merchant: "Safeway",
            amount: 60.00,
            context: nil
        )
        
        // Then
        XCTAssertEqual(result.category, "food_groceries")
        XCTAssertEqual(result.method, .llm)
    }
    
    func testParseCategorizationResponse_WithPartialMatch() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.mockResponse = "The category is Housing"
        mockCategoryMappingService.mockCategories = [CategoryDefinition.housing]
        
        // When
        let result = try await sut.categorizeWithLLM(
            merchant: "Rent Payment",
            amount: 1200.00,
            context: nil
        )
        
        // Then
        XCTAssertEqual(result.category, "housing")
        XCTAssertLessThan(result.confidence, 0.9)
    }
    
    func testParseCategorizationResponse_WithUnknownCategory_DefaultsToOther() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.mockResponse = "UnknownCategory"
        mockCategoryMappingService.mockCategories = [CategoryDefinition.other]
        
        // When
        let result = try await sut.categorizeWithLLM(
            merchant: "Unknown Merchant",
            amount: 100.00,
            context: nil
        )
        
        // Then
        XCTAssertEqual(result.category, "other")
    }
    
    func testParseCategorizationResponse_CaseInsensitive() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.mockResponse = "HOUSING & RENT"
        mockCategoryMappingService.mockCategories = [CategoryDefinition.housing]
        
        // When
        let result = try await sut.categorizeWithLLM(
            merchant: "Apartment Complex",
            amount: 1800.00,
            context: nil
        )
        
        // Then
        XCTAssertEqual(result.category, "housing")
    }
    
    func testParseCategorizationResponse_TrimsWhitespace() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.mockResponse = "  Housing & Rent  \n"
        mockCategoryMappingService.mockCategories = [CategoryDefinition.housing]
        
        // When
        let result = try await sut.categorizeWithLLM(
            merchant: "Property Manager",
            amount: 1500.00,
            context: nil
        )
        
        // Then
        XCTAssertEqual(result.category, "housing")
    }
    
    func testParseTransactionData_WithValidJSON() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.mockResponse = """
        [
            {
                "date": "2024-01-15",
                "merchant": "Starbucks",
                "amount": "5.50"
            },
            {
                "date": "2024-01-16",
                "merchant": "Walmart",
                "amount": "45.00"
            }
        ]
        """
        
        // When
        let transactions = try await sut.extractTransactionData(from: "test text")
        
        // Then
        XCTAssertEqual(transactions.count, 2)
        XCTAssertEqual(transactions[0].merchant, "Starbucks")
        XCTAssertEqual(transactions[0].amount, 5.50)
        XCTAssertEqual(transactions[1].merchant, "Walmart")
        XCTAssertEqual(transactions[1].amount, 45.00)
    }
    
    func testParseTransactionData_WithInvalidJSON_ReturnsEmpty() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.mockResponse = "Invalid JSON"
        
        // When
        let transactions = try await sut.extractTransactionData(from: "test text")
        
        // Then
        XCTAssertEqual(transactions.count, 0)
    }
    
    func testParseTransactionData_WithMissingFields_SkipsInvalidEntries() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.mockResponse = """
        [
            {
                "date": "2024-01-15",
                "merchant": "Starbucks",
                "amount": "5.50"
            },
            {
                "date": "2024-01-16",
                "merchant": "Incomplete"
            }
        ]
        """
        
        // When
        let transactions = try await sut.extractTransactionData(from: "test text")
        
        // Then
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions[0].merchant, "Starbucks")
    }
    
    // MARK: - Error Handling Tests
    
    func testCategorizeWithLLM_WhenFallbackFails_ThrowsError() async throws {
        // Given
        mockModelManager.isAvailable = false
        mockCategoryService.shouldThrowError = true
        
        // When/Then
        do {
            _ = try await sut.categorizeWithLLM(
                merchant: "Test",
                amount: 10.00,
                context: nil
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected error
            XCTAssertNotNil(error)
        }
    }
    
    func testNormalizeMerchantName_WithEmptyResponse_UsesFallback() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.mockResponse = ""
        let merchant = "Test Merchant"
        
        // When
        let normalized = try await sut.normalizeMerchantName(merchant)
        
        // Then
        XCTAssertEqual(normalized, merchant)
    }
    
    func testNormalizeMerchantName_WithTooLongResponse_UsesFallback() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.mockResponse = String(repeating: "a", count: 150)
        let merchant = "Test Merchant"
        
        // When
        let normalized = try await sut.normalizeMerchantName(merchant)
        
        // Then
        XCTAssertEqual(normalized, merchant)
    }
    
    // MARK: - Timeout Behavior Tests
    
    func testCategorizeWithLLM_WithTimeout_UsesFallback() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.shouldTimeout = true
        mockCategoryService.mockCategorizationResult = CategorizationResult(
            category: "other",
            confidence: 0.5,
            matchedPattern: nil,
            matchType: .default_
        )
        
        // When
        let result = try await sut.categorizeWithLLM(
            merchant: "Test",
            amount: 10.00,
            context: nil
        )
        
        // Then
        XCTAssertTrue(mockCategoryService.categorizeCalled)
        XCTAssertEqual(result.method, .pattern)
    }
    
    // MARK: - Integration Tests
    
    func testFullFlow_LLMAvailable_UsesLLM() async throws {
        // Given
        mockModelManager.isAvailable = true
        mockModelManager.mockResponse = "Dining & Restaurants"
        mockCategoryMappingService.mockCategories = [CategoryDefinition.dining]
        
        // When
        let result = try await sut.categorizeWithLLM(
            merchant: "Chipotle",
            amount: 12.50,
            context: "lunch"
        )
        
        // Then
        XCTAssertTrue(mockModelManager.queryCalled)
        XCTAssertFalse(mockCategoryService.categorizeCalled)
        XCTAssertEqual(result.category, "dining")
        XCTAssertEqual(result.method, .llm)
    }
    
    func testFullFlow_LLMUnavailable_UsesFallback() async throws {
        // Given
        mockModelManager.isAvailable = false
        mockCategoryService.mockCategorizationResult = CategorizationResult(
            category: "dining",
            confidence: 0.8,
            matchedPattern: "chipotle",
            matchType: .patternMatch
        )
        
        // When
        let result = try await sut.categorizeWithLLM(
            merchant: "Chipotle",
            amount: 12.50,
            context: nil
        )
        
        // Then
        XCTAssertFalse(mockModelManager.queryCalled)
        XCTAssertTrue(mockCategoryService.categorizeCalled)
        XCTAssertEqual(result.category, "dining")
        XCTAssertEqual(result.method, .pattern)
    }
}

// MARK: - Mock Apple Foundation Model Manager

@MainActor
class MockAppleFoundationModelManager: AppleFoundationModelManager {
    var isAvailable: Bool = false
    var shouldThrowError: Bool = false
    var shouldTimeout: Bool = false
    var mockResponse: String = ""
    var queryCalled: Bool = false
    var lastPrompt: String?
    
    override init() {
        super.init()
    }
    
    override func query(prompt: String) async throws -> String {
        queryCalled = true
        lastPrompt = prompt
        
        if shouldTimeout {
            try await Task.sleep(nanoseconds: 6_000_000_000) // 6 seconds
            throw LLMError.timeout
        }
        
        if shouldThrowError {
            throw LLMError.queryFailed
        }
        
        return mockResponse
    }
}

// MARK: - Mock Category Mapping Service

class MockCategoryMappingService: CategoryMappingServiceProtocol {
    var mockCategories: [CategoryDefinition] = CategoryDefinition.allCategories
    
    func getCanonicalCategory(from templateName: String) -> CategoryDefinition? {
        return mockCategories.first { category in
            category.canonicalName.lowercased() == templateName.lowercased() ||
            category.displayName.lowercased() == templateName.lowercased()
        }
    }
    
    func getDisplayName(for canonicalName: String) -> String {
        return mockCategories.first { $0.canonicalName == canonicalName }?.displayName ?? canonicalName
    }
    
    func getAllCategories() -> [CategoryDefinition] {
        return mockCategories
    }
    
    func getCategoriesForBudgetTemplate(_ templateId: String) -> [CategoryDefinition] {
        return mockCategories.filter { $0.canonicalName != "income" && $0.canonicalName != "transfer" }
    }
}
