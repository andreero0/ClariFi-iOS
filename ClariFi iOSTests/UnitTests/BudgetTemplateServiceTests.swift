//
//  BudgetTemplateServiceTests.swift
//  ClariFi_iOS Tests
//
//  Tests for BudgetTemplateService
//

import XCTest
@testable import ClariFi_iOS

final class BudgetTemplateServiceTests: XCTestCase {
    
    var sut: BudgetTemplateService!
    
    override func setUp() {
        super.setUp()
        sut = BudgetTemplateService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Template Retrieval Tests
    
    func testGetAllTemplates_ReturnsMultipleTemplates() {
        // Act
        let templates = sut.getAllTemplates()
        
        // Assert
        XCTAssertGreaterThan(templates.count, 0)
        XCTAssertGreaterThanOrEqual(templates.count, 10, "Should have at least 10 templates")
    }
    
    func testGetAllTemplates_EachTemplateHasUniqueId() {
        // Act
        let templates = sut.getAllTemplates()
        let ids = templates.map { $0.id }
        let uniqueIds = Set(ids)
        
        // Assert
        XCTAssertEqual(ids.count, uniqueIds.count, "All template IDs should be unique")
    }
    
    func testGetAllTemplates_EachTemplateHasRequiredFields() {
        // Act
        let templates = sut.getAllTemplates()
        
        // Assert
        for template in templates {
            XCTAssertFalse(template.id.isEmpty, "Template ID should not be empty")
            XCTAssertFalse(template.name.isEmpty, "Template name should not be empty")
            XCTAssertFalse(template.description.isEmpty, "Template description should not be empty")
            XCTAssertFalse(template.targetAudience.isEmpty, "Template target audience should not be empty")
            XCTAssertFalse(template.categories.isEmpty, "Template should have categories")
        }
    }
    
    func testGetTemplateById_WithValidId_ReturnsTemplate() {
        // Arrange
        let expectedId = "student"
        
        // Act
        let template = sut.getTemplate(byId: expectedId)
        
        // Assert
        XCTAssertNotNil(template)
        XCTAssertEqual(template?.id, expectedId)
        XCTAssertEqual(template?.name, "Student Budget")
    }
    
    func testGetTemplateById_WithInvalidId_ReturnsNil() {
        // Arrange
        let invalidId = "non-existent-template"
        
        // Act
        let template = sut.getTemplate(byId: invalidId)
        
        // Assert
        XCTAssertNil(template)
    }
    
    // MARK: - Specific Template Tests
    
    func testStudentTemplate_HasCorrectStructure() {
        // Act
        let template = sut.getTemplate(byId: "student")
        
        // Assert
        XCTAssertNotNil(template)
        XCTAssertEqual(template?.name, "Student Budget")
        XCTAssertTrue(template?.categories.contains { $0.name == "Tuition & Fees" } ?? false)
        XCTAssertTrue(template?.categories.contains { $0.name == "Books & Supplies" } ?? false)
        XCTAssertEqual(template?.defaultPeriod, .monthly)
        XCTAssertTrue(template?.rolloverEnabled ?? false)
    }
    
    func testGigWorkerTemplate_HasCorrectStructure() {
        // Act
        let template = sut.getTemplate(byId: "gig-worker")
        
        // Assert
        XCTAssertNotNil(template)
        XCTAssertEqual(template?.name, "Gig Worker Budget")
        XCTAssertTrue(template?.categories.contains { $0.name == "Business Expenses" } ?? false)
        XCTAssertTrue(template?.categories.contains { $0.name == "Taxes & Savings" } ?? false)
    }
    
    func testFamilyTemplate_HasCorrectStructure() {
        // Act
        let template = sut.getTemplate(byId: "family")
        
        // Assert
        XCTAssertNotNil(template)
        XCTAssertEqual(template?.name, "Family Budget")
        XCTAssertTrue(template?.categories.contains { $0.name == "Childcare & Education" } ?? false)
        XCTAssertFalse(template?.rolloverEnabled ?? true)
    }
    
    func testProfessionalTemplate_HasCorrectStructure() {
        // Act
        let template = sut.getTemplate(byId: "professional")
        
        // Assert
        XCTAssertNotNil(template)
        XCTAssertEqual(template?.name, "Professional Budget")
        XCTAssertTrue(template?.categories.contains { $0.name == "Professional Development" } ?? false)
        XCTAssertTrue(template?.categories.contains { $0.name == "Savings & Investments" } ?? false)
    }
    
    func testRetireeTemplate_HasCorrectStructure() {
        // Act
        let template = sut.getTemplate(byId: "retiree")
        
        // Assert
        XCTAssertNotNil(template)
        XCTAssertEqual(template?.name, "Retiree Budget")
        XCTAssertTrue(template?.categories.contains { $0.name == "Healthcare & Medications" } ?? false)
    }
    
    // MARK: - Category Validation Tests
    
    func testAllTemplates_CategoriesHaveValidPercentages() {
        // Act
        let templates = sut.getAllTemplates()
        
        // Assert
        for template in templates {
            let totalPercentage = template.categories.reduce(0.0) { $0 + $1.suggestedPercentage }
            
            // Allow for small floating point errors
            XCTAssertLessThanOrEqual(abs(totalPercentage - 1.0), 0.01,
                                    "Template '\(template.name)' percentages should sum to ~1.0, got \(totalPercentage)")
        }
    }
    
    func testAllTemplates_CategoriesHaveValidAmounts() {
        // Act
        let templates = sut.getAllTemplates()
        
        // Assert
        for template in templates {
            for category in template.categories {
                XCTAssertGreaterThanOrEqual(category.suggestedAmount, 0,
                                          "Category '\(category.name)' in template '\(template.name)' should have non-negative amount")
            }
        }
    }
    
    func testAllTemplates_CategoriesHaveValidAlertThresholds() {
        // Act
        let templates = sut.getAllTemplates()
        
        // Assert
        for template in templates {
            for category in template.categories {
                XCTAssertGreaterThan(category.alertThreshold, 0,
                                   "Category '\(category.name)' alert threshold should be > 0")
                XCTAssertLessThanOrEqual(category.alertThreshold, 1.0,
                                       "Category '\(category.name)' alert threshold should be <= 1.0")
            }
        }
    }
    
    func testAllTemplates_CategoriesHaveNames() {
        // Act
        let templates = sut.getAllTemplates()
        
        // Assert
        for template in templates {
            for category in template.categories {
                XCTAssertFalse(category.name.isEmpty,
                             "All categories in template '\(template.name)' should have names")
            }
        }
    }
    
    // MARK: - Budget Period Tests
    
    func testBudgetPeriod_MonthlyDisplayName() {
        // Act
        let displayName = BudgetPeriod.monthly.displayName
        
        // Assert
        XCTAssertEqual(displayName, "Monthly")
    }
    
    func testBudgetPeriod_WeeklyDisplayName() {
        // Act
        let displayName = BudgetPeriod.weekly.displayName
        
        // Assert
        XCTAssertEqual(displayName, "Weekly")
    }
    
    func testBudgetPeriod_NextPeriodStart_Monthly() {
        // Arrange
        let startDate = Date()
        
        // Act
        let nextStart = BudgetPeriod.monthly.nextPeriodStart(from: startDate)
        
        // Assert
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: startDate, to: nextStart)
        XCTAssertEqual(components.month, 1)
    }
    
    func testBudgetPeriod_NextPeriodStart_Weekly() {
        // Arrange
        let startDate = Date()
        
        // Act
        let nextStart = BudgetPeriod.weekly.nextPeriodStart(from: startDate)
        
        // Assert
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: nextStart)
        XCTAssertEqual(components.day, 7)
    }
    
    func testBudgetPeriod_PeriodEnd_Monthly() {
        // Arrange
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        
        // Act
        let endDate = BudgetPeriod.monthly.periodEnd(from: startDate)
        
        // Assert
        let endComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
        XCTAssertEqual(endComponents.year, 2024)
        XCTAssertEqual(endComponents.month, 1)
        XCTAssertEqual(endComponents.day, 31)
    }
    
    func testBudgetPeriod_PeriodEnd_Weekly() {
        // Arrange
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        
        // Act
        let endDate = BudgetPeriod.weekly.periodEnd(from: startDate)
        
        // Assert
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        XCTAssertEqual(components.day, 6)
    }
    
    // MARK: - Template Coverage Tests
    
    func testTemplates_CoverDiverseAudiences() {
        // Act
        let templates = sut.getAllTemplates()
        let templateIds = templates.map { $0.id }
        
        // Assert - Check for key templates
        XCTAssertTrue(templateIds.contains("student"))
        XCTAssertTrue(templateIds.contains("gig-worker"))
        XCTAssertTrue(templateIds.contains("family"))
        XCTAssertTrue(templateIds.contains("professional"))
        XCTAssertTrue(templateIds.contains("retiree"))
        XCTAssertTrue(templateIds.contains("single-parent"))
        XCTAssertTrue(templateIds.contains("young-professional"))
        XCTAssertTrue(templateIds.contains("minimalist"))
        XCTAssertTrue(templateIds.contains("entrepreneur"))
        XCTAssertTrue(templateIds.contains("couple"))
    }
    
    func testDebtPayoffTemplate_PrioritizesDebtPayment() {
        // Act
        let template = sut.getTemplate(byId: "debt-payoff")
        
        // Assert
        XCTAssertNotNil(template)
        
        // Find debt payment category
        let debtCategory = template?.categories.first { $0.name == "Debt Payments" }
        XCTAssertNotNil(debtCategory)
        
        // Should be the highest percentage
        let maxPercentage = template?.categories.map { $0.suggestedPercentage }.max()
        XCTAssertEqual(debtCategory?.suggestedPercentage, maxPercentage)
        XCTAssertGreaterThanOrEqual(debtCategory?.suggestedPercentage ?? 0, 0.35)
    }
    
    func testSavingsGoalTemplate_PrioritizesSavings() {
        // Act
        let template = sut.getTemplate(byId: "savings-goal")
        
        // Assert
        XCTAssertNotNil(template)
        
        // Find savings category
        let savingsCategory = template?.categories.first { $0.name == "Primary Savings Goal" }
        XCTAssertNotNil(savingsCategory)
        
        // Should be a high percentage
        XCTAssertGreaterThanOrEqual(savingsCategory?.suggestedPercentage ?? 0, 0.30)
    }
    
    func testMinimalistTemplate_HasFewerCategories() {
        // Act
        let minimalistTemplate = sut.getTemplate(byId: "minimalist")
        let familyTemplate = sut.getTemplate(byId: "family")
        
        // Assert
        XCTAssertNotNil(minimalistTemplate)
        XCTAssertNotNil(familyTemplate)
        
        // Minimalist should have fewer categories than family
        XCTAssertLessThan(minimalistTemplate?.categories.count ?? 0,
                         familyTemplate?.categories.count ?? 0)
    }
}
