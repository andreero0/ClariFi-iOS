//
//  CategoryMappingServiceTests.swift
//  ClariFi iOS Tests
//
//  Created by Kiro on 2025-10-13.
//

import XCTest
@testable import ClariFi_iOS

final class CategoryMappingServiceTests: XCTestCase {
    
    var sut: CategoryMappingService!
    
    override func setUp() {
        super.setUp()
        sut = CategoryMappingService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - getCanonicalCategory Tests
    
    func testGetCanonicalCategory_WithExactCanonicalName() {
        // Given
        let templateName = "housing"
        
        // When
        let result = sut.getCanonicalCategory(from: templateName)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.canonicalName, "housing")
        XCTAssertEqual(result?.displayName, "Housing & Rent")
    }
    
    func testGetCanonicalCategory_WithDisplayName() {
        // Given
        let templateName = "Housing & Rent"
        
        // When
        let result = sut.getCanonicalCategory(from: templateName)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.canonicalName, "housing")
    }
    
    func testGetCanonicalCategory_WithTemplateAlias() {
        // Given
        let templateName = "Housing (BAH)"
        
        // When
        let result = sut.getCanonicalCategory(from: templateName)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.canonicalName, "housing")
    }
    
    func testGetCanonicalCategory_WithWhitespace() {
        // Given
        let templateName = "  Housing  "
        
        // When
        let result = sut.getCanonicalCategory(from: templateName)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.canonicalName, "housing")
    }
    
    func testGetCanonicalCategory_CaseInsensitive() {
        // Given
        let templateName = "HOUSING"
        
        // When
        let result = sut.getCanonicalCategory(from: templateName)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.canonicalName, "housing")
    }
    
    func testGetCanonicalCategory_WithNonExistentCategory() {
        // Given
        let templateName = "NonExistentCategory"
        
        // When
        let result = sut.getCanonicalCategory(from: templateName)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testGetCanonicalCategory_WithMultipleAliases() {
        // Given
        let aliases = ["Food & Groceries", "Groceries", "Food"]
        
        // When & Then
        for alias in aliases {
            let result = sut.getCanonicalCategory(from: alias)
            XCTAssertNotNil(result, "Failed to find category for alias: \(alias)")
            XCTAssertEqual(result?.canonicalName, "food_groceries")
        }
    }
    
    // MARK: - getDisplayName Tests
    
    func testGetDisplayName_WithValidCanonicalName() {
        // Given
        let canonicalName = "housing"
        
        // When
        let displayName = sut.getDisplayName(for: canonicalName)
        
        // Then
        XCTAssertEqual(displayName, "Housing & Rent")
    }
    
    func testGetDisplayName_WithInvalidCanonicalName() {
        // Given
        let canonicalName = "invalid_category"
        
        // When
        let displayName = sut.getDisplayName(for: canonicalName)
        
        // Then
        XCTAssertEqual(displayName, "invalid_category")
    }
    
    func testGetDisplayName_ForAllCategories() {
        // Given
        let allCategories = CategoryDefinition.allCategories
        
        // When & Then
        for category in allCategories {
            let displayName = sut.getDisplayName(for: category.canonicalName)
            XCTAssertEqual(displayName, category.displayName)
        }
    }
    
    // MARK: - getAllCategories Tests
    
    func testGetAllCategories_ReturnsAllDefinedCategories() {
        // When
        let categories = sut.getAllCategories()
        
        // Then
        XCTAssertEqual(categories.count, CategoryDefinition.allCategories.count)
        XCTAssertTrue(categories.contains { $0.canonicalName == "housing" })
        XCTAssertTrue(categories.contains { $0.canonicalName == "food_groceries" })
        XCTAssertTrue(categories.contains { $0.canonicalName == "other" })
    }
    
    func testGetAllCategories_ContainsEssentialCategories() {
        // When
        let categories = sut.getAllCategories()
        let essentialCategories = categories.filter { $0.isEssential }
        
        // Then
        XCTAssertGreaterThan(essentialCategories.count, 0)
        XCTAssertTrue(essentialCategories.contains { $0.canonicalName == "housing" })
        XCTAssertTrue(essentialCategories.contains { $0.canonicalName == "utilities" })
    }
    
    // MARK: - getCategoriesForBudgetTemplate Tests
    
    func testGetCategoriesForBudgetTemplate_ExcludesIncomeAndTransfer() {
        // Given
        let templateId = "test_template"
        
        // When
        let categories = sut.getCategoriesForBudgetTemplate(templateId)
        
        // Then
        XCTAssertFalse(categories.contains { $0.canonicalName == "income" })
        XCTAssertFalse(categories.contains { $0.canonicalName == "transfer" })
    }
    
    func testGetCategoriesForBudgetTemplate_IncludesExpenseCategories() {
        // Given
        let templateId = "test_template"
        
        // When
        let categories = sut.getCategoriesForBudgetTemplate(templateId)
        
        // Then
        XCTAssertTrue(categories.contains { $0.canonicalName == "housing" })
        XCTAssertTrue(categories.contains { $0.canonicalName == "food_groceries" })
        XCTAssertTrue(categories.contains { $0.canonicalName == "utilities" })
    }
    
    // MARK: - Integration Tests
    
    func testCategoryMapping_RoundTrip() {
        // Given
        let templateName = "Housing (BAH)"
        
        // When
        let category = sut.getCanonicalCategory(from: templateName)
        let displayName = sut.getDisplayName(for: category?.canonicalName ?? "")
        
        // Then
        XCTAssertNotNil(category)
        XCTAssertEqual(displayName, "Housing & Rent")
    }
    
    func testCategoryMapping_AllCategoriesHaveUniqueCanonicalNames() {
        // Given
        let categories = sut.getAllCategories()
        
        // When
        let canonicalNames = categories.map { $0.canonicalName }
        let uniqueNames = Set(canonicalNames)
        
        // Then
        XCTAssertEqual(canonicalNames.count, uniqueNames.count, "Duplicate canonical names found")
    }
}
