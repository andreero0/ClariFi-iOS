//
//  BudgetTemplateService.swift
//  ClariFi iOS
//
//  Created by Kiro on 2025-10-10.
//

import Foundation

// MARK: - Budget Template Models
struct BudgetTemplate {
    let id: String
    let name: String
    let description: String
    let targetAudience: String
    let categories: [BudgetCategoryTemplate]
    let defaultPeriod: BudgetPeriod
    let rolloverEnabled: Bool
}

struct BudgetCategoryTemplate {
    let name: String  // Display name for the template
    let canonicalName: String  // Canonical category name for consistency
    let suggestedAmount: Decimal
    let suggestedPercentage: Double
    let alertThreshold: Float
    let color: String?
    
    // Convenience initializer that auto-maps to canonical name
    init(name: String, suggestedAmount: Decimal, suggestedPercentage: Double, alertThreshold: Float, color: String?) {
        self.name = name
        self.canonicalName = BudgetTemplateService.mapToCanonicalCategory(name)
        self.suggestedAmount = suggestedAmount
        self.suggestedPercentage = suggestedPercentage
        self.alertThreshold = alertThreshold
        self.color = color
    }
}

enum BudgetPeriod: String, CaseIterable {
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
    
    func nextPeriodStart(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        }
    }
    
    func periodEnd(from startDate: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .weekly:
            return calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
        case .monthly:
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startDate),
                  let endDate = calendar.date(byAdding: .day, value: -1, to: nextMonth) else {
                return startDate
            }
            return endDate
        }
    }
}

// MARK: - Budget Template Service
class BudgetTemplateService {
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Category Mapping
    
    /// Maps template-specific category names to canonical category names
    static func mapToCanonicalCategory(_ templateName: String) -> String {
        // Normalize the template name for matching
        let normalized = templateName.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Map template names to canonical names
        switch normalized {
        // Housing variations
        case "housing", "housing & rent", "housing (bah)", "housing & home office", "studio/workspace":
            return "housing"
            
        // Food & Groceries variations
        case "food & groceries", "groceries", "food & dining":
            return "food_groceries"
            
        // Dining variations
        case "dining", "dining & restaurants", "date nights & activities":
            return "dining"
            
        // Transportation variations
        case "transportation", "vehicle & transportation":
            return "transportation"
            
        // Utilities variations
        case "utilities", "utilities & bills", "utilities & phone", "internet & tech":
            return "utilities"
            
        // Healthcare variations
        case "healthcare", "healthcare & medications", "healthcare & fitness", "healthcare & wellness", "healthcare & insurance":
            return "healthcare"
            
        // Education variations
        case "education", "tuition & fees", "books & supplies", "childcare & education", "professional development":
            return "education"
            
        // Entertainment variations
        case "entertainment", "entertainment & social", "entertainment & hobbies", "entertainment & travel", "entertainment & recreation":
            return "entertainment"
            
        // Shopping variations
        case "shopping", "shopping & personal":
            return "shopping"
            
        // Personal Care variations
        case "personal care", "essential personal care":
            return "personal_care"
            
        // Savings variations
        case "savings & investments", "savings & emergency fund", "savings & tsp", "primary savings goal", "emergency savings", "emergency fund", "income buffer fund":
            return "savings"
            
        // Debt variations
        case "debt payments", "student loans & debt":
            return "debt"
            
        // Business variations
        case "business expenses", "business operations", "business taxes & savings", "marketing & growth":
            return "business"
            
        // Insurance variations
        case "insurance":
            return "insurance"
            
        // Subscriptions variations
        case "subscriptions":
            return "subscriptions"
            
        // Childcare variations
        case "childcare", "children's activities":
            return "childcare"
            
        // Family variations
        case "family support":
            return "family"
            
        // Gifts variations
        case "gifts & donations":
            return "gifts"
            
        // Professional Services variations
        case "professional services":
            return "professional_services"
            
        // Art/Creative variations
        case "art supplies & materials":
            return "art_supplies"
            
        // Taxes variations
        case "taxes & savings":
            return "taxes"
            
        // Travel variations
        case "travel":
            return "travel"
            
        // Income variations
        case "income":
            return "income"
            
        // Transfer variations
        case "transfer":
            return "transfer"
            
        // Other/default
        case "other":
            return "other"
            
        default:
            // If no match found, return a sanitized version of the template name
            return normalized.replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "&", with: "and")
                .replacingOccurrences(of: "/", with: "_")
        }
    }
    
    // MARK: - Template Definitions
    
    func getAllTemplates() -> [BudgetTemplate] {
        return [
            studentTemplate(),
            gigWorkerTemplate(),
            familyTemplate(),
            professionalTemplate(),
            retireeTemplate(),
            singleParentTemplate(),
            youngProfessionalTemplate(),
            minimalistTemplate(),
            entrepreneurTemplate(),
            coupleTemplate(),
            debtPayoffTemplate(),
            savingsGoalTemplate(),
            remoteWorkerTemplate(),
            militaryTemplate(),
            artistCreativeTemplate(),
            healthcareWorkerTemplate(),
            teacherTemplate(),
            newGraduateTemplate()
        ]
    }
    
    func getTemplate(byId id: String) -> BudgetTemplate? {
        return getAllTemplates().first { $0.id == id }
    }
    
    // MARK: - Student Template
    private func studentTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "student",
            name: "Student Budget",
            description: "Perfect for students managing tuition, books, and living expenses",
            targetAudience: "College and university students",
            categories: [
                BudgetCategoryTemplate(name: "Tuition & Fees", suggestedAmount: 500, suggestedPercentage: 0.30, alertThreshold: 0.9, color: "blue"),
                BudgetCategoryTemplate(name: "Books & Supplies", suggestedAmount: 150, suggestedPercentage: 0.09, alertThreshold: 0.8, color: "purple"),
                BudgetCategoryTemplate(name: "Housing", suggestedAmount: 400, suggestedPercentage: 0.24, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Food & Groceries", suggestedAmount: 250, suggestedPercentage: 0.15, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Transportation", suggestedAmount: 100, suggestedPercentage: 0.06, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Entertainment", suggestedAmount: 100, suggestedPercentage: 0.06, alertThreshold: 0.7, color: "pink"),
                BudgetCategoryTemplate(name: "Personal Care", suggestedAmount: 50, suggestedPercentage: 0.03, alertThreshold: 0.8, color: "indigo"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 120, suggestedPercentage: 0.07, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: true
        )
    }
    
    // MARK: - Gig Worker Template
    private func gigWorkerTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "gig-worker",
            name: "Gig Worker Budget",
            description: "Designed for freelancers and gig workers with variable income",
            targetAudience: "Freelancers, contractors, and gig economy workers",
            categories: [
                BudgetCategoryTemplate(name: "Business Expenses", suggestedAmount: 400, suggestedPercentage: 0.20, alertThreshold: 0.85, color: "blue"),
                BudgetCategoryTemplate(name: "Taxes & Savings", suggestedAmount: 600, suggestedPercentage: 0.30, alertThreshold: 0.9, color: "red"),
                BudgetCategoryTemplate(name: "Housing", suggestedAmount: 500, suggestedPercentage: 0.25, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Food & Groceries", suggestedAmount: 250, suggestedPercentage: 0.125, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Transportation", suggestedAmount: 100, suggestedPercentage: 0.05, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Healthcare", suggestedAmount: 100, suggestedPercentage: 0.05, alertThreshold: 0.9, color: "purple"),
                BudgetCategoryTemplate(name: "Entertainment", suggestedAmount: 50, suggestedPercentage: 0.025, alertThreshold: 0.7, color: "pink"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 0, suggestedPercentage: 0.0, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: true
        )
    }
    
    // MARK: - Family Template
    private func familyTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "family",
            name: "Family Budget",
            description: "Comprehensive budget for families with children",
            targetAudience: "Families with dependents",
            categories: [
                BudgetCategoryTemplate(name: "Housing", suggestedAmount: 1200, suggestedPercentage: 0.30, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Food & Groceries", suggestedAmount: 600, suggestedPercentage: 0.15, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Transportation", suggestedAmount: 400, suggestedPercentage: 0.10, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Childcare & Education", suggestedAmount: 500, suggestedPercentage: 0.125, alertThreshold: 0.9, color: "purple"),
                BudgetCategoryTemplate(name: "Healthcare", suggestedAmount: 300, suggestedPercentage: 0.075, alertThreshold: 0.9, color: "red"),
                BudgetCategoryTemplate(name: "Utilities", suggestedAmount: 200, suggestedPercentage: 0.05, alertThreshold: 0.85, color: "yellow"),
                BudgetCategoryTemplate(name: "Savings & Investments", suggestedAmount: 400, suggestedPercentage: 0.10, alertThreshold: 0.9, color: "blue"),
                BudgetCategoryTemplate(name: "Entertainment", suggestedAmount: 200, suggestedPercentage: 0.05, alertThreshold: 0.7, color: "pink"),
                BudgetCategoryTemplate(name: "Personal Care", suggestedAmount: 100, suggestedPercentage: 0.025, alertThreshold: 0.8, color: "indigo"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 100, suggestedPercentage: 0.025, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: false
        )
    }
    
    // MARK: - Professional Template
    private func professionalTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "professional",
            name: "Professional Budget",
            description: "For working professionals focused on career growth and savings",
            targetAudience: "Full-time professionals and career-focused individuals",
            categories: [
                BudgetCategoryTemplate(name: "Housing", suggestedAmount: 1000, suggestedPercentage: 0.30, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Savings & Investments", suggestedAmount: 500, suggestedPercentage: 0.15, alertThreshold: 0.9, color: "blue"),
                BudgetCategoryTemplate(name: "Food & Dining", suggestedAmount: 400, suggestedPercentage: 0.12, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Transportation", suggestedAmount: 300, suggestedPercentage: 0.09, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Professional Development", suggestedAmount: 200, suggestedPercentage: 0.06, alertThreshold: 0.85, color: "purple"),
                BudgetCategoryTemplate(name: "Healthcare & Fitness", suggestedAmount: 200, suggestedPercentage: 0.06, alertThreshold: 0.85, color: "red"),
                BudgetCategoryTemplate(name: "Utilities & Bills", suggestedAmount: 200, suggestedPercentage: 0.06, alertThreshold: 0.85, color: "yellow"),
                BudgetCategoryTemplate(name: "Entertainment", suggestedAmount: 200, suggestedPercentage: 0.06, alertThreshold: 0.7, color: "pink"),
                BudgetCategoryTemplate(name: "Shopping & Personal", suggestedAmount: 200, suggestedPercentage: 0.06, alertThreshold: 0.75, color: "indigo"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 133, suggestedPercentage: 0.04, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: true
        )
    }
    
    // MARK: - Retiree Template
    private func retireeTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "retiree",
            name: "Retiree Budget",
            description: "For retirees managing fixed income and healthcare costs",
            targetAudience: "Retirees and seniors on fixed income",
            categories: [
                BudgetCategoryTemplate(name: "Housing", suggestedAmount: 800, suggestedPercentage: 0.32, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Healthcare & Medications", suggestedAmount: 400, suggestedPercentage: 0.16, alertThreshold: 0.9, color: "red"),
                BudgetCategoryTemplate(name: "Food & Groceries", suggestedAmount: 350, suggestedPercentage: 0.14, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Utilities", suggestedAmount: 200, suggestedPercentage: 0.08, alertThreshold: 0.85, color: "yellow"),
                BudgetCategoryTemplate(name: "Transportation", suggestedAmount: 150, suggestedPercentage: 0.06, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Insurance", suggestedAmount: 200, suggestedPercentage: 0.08, alertThreshold: 0.9, color: "blue"),
                BudgetCategoryTemplate(name: "Entertainment & Hobbies", suggestedAmount: 150, suggestedPercentage: 0.06, alertThreshold: 0.7, color: "pink"),
                BudgetCategoryTemplate(name: "Personal Care", suggestedAmount: 100, suggestedPercentage: 0.04, alertThreshold: 0.8, color: "indigo"),
                BudgetCategoryTemplate(name: "Gifts & Donations", suggestedAmount: 100, suggestedPercentage: 0.04, alertThreshold: 0.75, color: "purple"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 50, suggestedPercentage: 0.02, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: false
        )
    }
    
    // MARK: - Single Parent Template
    private func singleParentTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "single-parent",
            name: "Single Parent Budget",
            description: "For single parents balancing work, childcare, and household expenses",
            targetAudience: "Single parents with dependent children",
            categories: [
                BudgetCategoryTemplate(name: "Housing", suggestedAmount: 900, suggestedPercentage: 0.30, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Childcare", suggestedAmount: 600, suggestedPercentage: 0.20, alertThreshold: 0.9, color: "purple"),
                BudgetCategoryTemplate(name: "Food & Groceries", suggestedAmount: 450, suggestedPercentage: 0.15, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Transportation", suggestedAmount: 300, suggestedPercentage: 0.10, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Children's Activities", suggestedAmount: 150, suggestedPercentage: 0.05, alertThreshold: 0.8, color: "pink"),
                BudgetCategoryTemplate(name: "Healthcare", suggestedAmount: 180, suggestedPercentage: 0.06, alertThreshold: 0.9, color: "red"),
                BudgetCategoryTemplate(name: "Utilities", suggestedAmount: 150, suggestedPercentage: 0.05, alertThreshold: 0.85, color: "yellow"),
                BudgetCategoryTemplate(name: "Emergency Savings", suggestedAmount: 150, suggestedPercentage: 0.05, alertThreshold: 0.9, color: "blue"),
                BudgetCategoryTemplate(name: "Personal Care", suggestedAmount: 60, suggestedPercentage: 0.02, alertThreshold: 0.8, color: "indigo"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 60, suggestedPercentage: 0.02, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: true
        )
    }
    
    // MARK: - Young Professional Template
    private func youngProfessionalTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "young-professional",
            name: "Young Professional Budget",
            description: "For early-career professionals building savings and paying off debt",
            targetAudience: "Recent graduates and early-career professionals",
            categories: [
                BudgetCategoryTemplate(name: "Housing", suggestedAmount: 800, suggestedPercentage: 0.32, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Student Loans & Debt", suggestedAmount: 400, suggestedPercentage: 0.16, alertThreshold: 0.9, color: "red"),
                BudgetCategoryTemplate(name: "Savings & Emergency Fund", suggestedAmount: 300, suggestedPercentage: 0.12, alertThreshold: 0.9, color: "blue"),
                BudgetCategoryTemplate(name: "Food & Dining", suggestedAmount: 300, suggestedPercentage: 0.12, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Transportation", suggestedAmount: 200, suggestedPercentage: 0.08, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Entertainment & Social", suggestedAmount: 150, suggestedPercentage: 0.06, alertThreshold: 0.7, color: "pink"),
                BudgetCategoryTemplate(name: "Professional Development", suggestedAmount: 100, suggestedPercentage: 0.04, alertThreshold: 0.85, color: "purple"),
                BudgetCategoryTemplate(name: "Utilities & Phone", suggestedAmount: 125, suggestedPercentage: 0.05, alertThreshold: 0.85, color: "yellow"),
                BudgetCategoryTemplate(name: "Shopping & Personal", suggestedAmount: 75, suggestedPercentage: 0.03, alertThreshold: 0.75, color: "indigo"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 50, suggestedPercentage: 0.02, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: true
        )
    }
    
    // MARK: - Minimalist Template
    private func minimalistTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "minimalist",
            name: "Minimalist Budget",
            description: "Focused on essential spending and maximizing savings",
            targetAudience: "Minimalists and those focused on financial independence",
            categories: [
                BudgetCategoryTemplate(name: "Housing", suggestedAmount: 600, suggestedPercentage: 0.30, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Savings & Investments", suggestedAmount: 600, suggestedPercentage: 0.30, alertThreshold: 0.9, color: "blue"),
                BudgetCategoryTemplate(name: "Food & Groceries", suggestedAmount: 300, suggestedPercentage: 0.15, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Transportation", suggestedAmount: 200, suggestedPercentage: 0.10, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Utilities", suggestedAmount: 150, suggestedPercentage: 0.075, alertThreshold: 0.85, color: "yellow"),
                BudgetCategoryTemplate(name: "Healthcare", suggestedAmount: 100, suggestedPercentage: 0.05, alertThreshold: 0.9, color: "red"),
                BudgetCategoryTemplate(name: "Essential Personal Care", suggestedAmount: 50, suggestedPercentage: 0.025, alertThreshold: 0.8, color: "indigo"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 0, suggestedPercentage: 0.0, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: true
        )
    }
    
    // MARK: - Entrepreneur Template
    private func entrepreneurTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "entrepreneur",
            name: "Entrepreneur Budget",
            description: "For small business owners managing business and personal expenses",
            targetAudience: "Entrepreneurs and small business owners",
            categories: [
                BudgetCategoryTemplate(name: "Business Operations", suggestedAmount: 800, suggestedPercentage: 0.25, alertThreshold: 0.85, color: "blue"),
                BudgetCategoryTemplate(name: "Business Taxes & Savings", suggestedAmount: 640, suggestedPercentage: 0.20, alertThreshold: 0.9, color: "red"),
                BudgetCategoryTemplate(name: "Marketing & Growth", suggestedAmount: 320, suggestedPercentage: 0.10, alertThreshold: 0.8, color: "purple"),
                BudgetCategoryTemplate(name: "Housing", suggestedAmount: 640, suggestedPercentage: 0.20, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Food & Groceries", suggestedAmount: 320, suggestedPercentage: 0.10, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Transportation", suggestedAmount: 160, suggestedPercentage: 0.05, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Healthcare & Insurance", suggestedAmount: 160, suggestedPercentage: 0.05, alertThreshold: 0.9, color: "pink"),
                BudgetCategoryTemplate(name: "Professional Services", suggestedAmount: 96, suggestedPercentage: 0.03, alertThreshold: 0.85, color: "indigo"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 64, suggestedPercentage: 0.02, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: true
        )
    }
    
    // MARK: - Couple Template
    private func coupleTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "couple",
            name: "Couple Budget",
            description: "For couples managing shared finances and joint goals",
            targetAudience: "Couples living together or married without children",
            categories: [
                BudgetCategoryTemplate(name: "Housing", suggestedAmount: 1400, suggestedPercentage: 0.28, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Savings & Investments", suggestedAmount: 750, suggestedPercentage: 0.15, alertThreshold: 0.9, color: "blue"),
                BudgetCategoryTemplate(name: "Food & Dining", suggestedAmount: 600, suggestedPercentage: 0.12, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Transportation", suggestedAmount: 500, suggestedPercentage: 0.10, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Utilities & Bills", suggestedAmount: 300, suggestedPercentage: 0.06, alertThreshold: 0.85, color: "yellow"),
                BudgetCategoryTemplate(name: "Healthcare & Fitness", suggestedAmount: 300, suggestedPercentage: 0.06, alertThreshold: 0.85, color: "red"),
                BudgetCategoryTemplate(name: "Entertainment & Travel", suggestedAmount: 500, suggestedPercentage: 0.10, alertThreshold: 0.7, color: "pink"),
                BudgetCategoryTemplate(name: "Shopping & Personal", suggestedAmount: 350, suggestedPercentage: 0.07, alertThreshold: 0.75, color: "indigo"),
                BudgetCategoryTemplate(name: "Date Nights & Activities", suggestedAmount: 200, suggestedPercentage: 0.04, alertThreshold: 0.7, color: "purple"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 100, suggestedPercentage: 0.02, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: true
        )
    }
    
    // MARK: - Debt Payoff Template
    private func debtPayoffTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "debt-payoff",
            name: "Debt Payoff Budget",
            description: "Aggressive debt reduction while maintaining essential expenses",
            targetAudience: "Anyone focused on eliminating debt quickly",
            categories: [
                BudgetCategoryTemplate(name: "Debt Payments", suggestedAmount: 1000, suggestedPercentage: 0.40, alertThreshold: 0.95, color: "red"),
                BudgetCategoryTemplate(name: "Housing", suggestedAmount: 600, suggestedPercentage: 0.24, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Food & Groceries", suggestedAmount: 300, suggestedPercentage: 0.12, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Transportation", suggestedAmount: 200, suggestedPercentage: 0.08, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Utilities", suggestedAmount: 150, suggestedPercentage: 0.06, alertThreshold: 0.85, color: "yellow"),
                BudgetCategoryTemplate(name: "Emergency Fund", suggestedAmount: 100, suggestedPercentage: 0.04, alertThreshold: 0.9, color: "blue"),
                BudgetCategoryTemplate(name: "Healthcare", suggestedAmount: 75, suggestedPercentage: 0.03, alertThreshold: 0.9, color: "purple"),
                BudgetCategoryTemplate(name: "Essential Personal Care", suggestedAmount: 50, suggestedPercentage: 0.02, alertThreshold: 0.8, color: "indigo"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 25, suggestedPercentage: 0.01, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: false
        )
    }
    
    // MARK: - Savings Goal Template
    private func savingsGoalTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "savings-goal",
            name: "Savings Goal Budget",
            description: "Maximize savings for a specific goal like house down payment or emergency fund",
            targetAudience: "Anyone saving for a major purchase or financial goal",
            categories: [
                BudgetCategoryTemplate(name: "Primary Savings Goal", suggestedAmount: 800, suggestedPercentage: 0.32, alertThreshold: 0.95, color: "blue"),
                BudgetCategoryTemplate(name: "Housing", suggestedAmount: 700, suggestedPercentage: 0.28, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Food & Groceries", suggestedAmount: 350, suggestedPercentage: 0.14, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Transportation", suggestedAmount: 250, suggestedPercentage: 0.10, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Utilities & Bills", suggestedAmount: 175, suggestedPercentage: 0.07, alertThreshold: 0.85, color: "yellow"),
                BudgetCategoryTemplate(name: "Healthcare", suggestedAmount: 100, suggestedPercentage: 0.04, alertThreshold: 0.9, color: "red"),
                BudgetCategoryTemplate(name: "Entertainment", suggestedAmount: 75, suggestedPercentage: 0.03, alertThreshold: 0.7, color: "pink"),
                BudgetCategoryTemplate(name: "Personal Care", suggestedAmount: 50, suggestedPercentage: 0.02, alertThreshold: 0.8, color: "indigo"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 0, suggestedPercentage: 0.0, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: true
        )
    }
    
    // MARK: - Remote Worker Template
    private func remoteWorkerTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "remote-worker",
            name: "Remote Worker Budget",
            description: "For remote workers with home office expenses and flexible lifestyle",
            targetAudience: "Remote employees and digital nomads",
            categories: [
                BudgetCategoryTemplate(name: "Housing & Home Office", suggestedAmount: 900, suggestedPercentage: 0.30, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Internet & Tech", suggestedAmount: 200, suggestedPercentage: 0.067, alertThreshold: 0.85, color: "blue"),
                BudgetCategoryTemplate(name: "Utilities", suggestedAmount: 200, suggestedPercentage: 0.067, alertThreshold: 0.85, color: "yellow"),
                BudgetCategoryTemplate(name: "Food & Groceries", suggestedAmount: 400, suggestedPercentage: 0.133, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Savings & Investments", suggestedAmount: 450, suggestedPercentage: 0.15, alertThreshold: 0.9, color: "purple"),
                BudgetCategoryTemplate(name: "Transportation", suggestedAmount: 150, suggestedPercentage: 0.05, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Healthcare & Wellness", suggestedAmount: 200, suggestedPercentage: 0.067, alertThreshold: 0.85, color: "red"),
                BudgetCategoryTemplate(name: "Professional Development", suggestedAmount: 150, suggestedPercentage: 0.05, alertThreshold: 0.8, color: "indigo"),
                BudgetCategoryTemplate(name: "Entertainment & Hobbies", suggestedAmount: 200, suggestedPercentage: 0.067, alertThreshold: 0.7, color: "pink"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 150, suggestedPercentage: 0.05, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: true
        )
    }
    
    // MARK: - Military Template
    private func militaryTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "military",
            name: "Military Budget",
            description: "For active duty military and veterans managing allowances and benefits",
            targetAudience: "Active duty military personnel and veterans",
            categories: [
                BudgetCategoryTemplate(name: "Housing (BAH)", suggestedAmount: 1000, suggestedPercentage: 0.30, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Savings & TSP", suggestedAmount: 500, suggestedPercentage: 0.15, alertThreshold: 0.9, color: "blue"),
                BudgetCategoryTemplate(name: "Food & Groceries", suggestedAmount: 400, suggestedPercentage: 0.12, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Vehicle & Transportation", suggestedAmount: 350, suggestedPercentage: 0.105, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Insurance", suggestedAmount: 200, suggestedPercentage: 0.06, alertThreshold: 0.9, color: "red"),
                BudgetCategoryTemplate(name: "Utilities & Phone", suggestedAmount: 200, suggestedPercentage: 0.06, alertThreshold: 0.85, color: "yellow"),
                BudgetCategoryTemplate(name: "Family Support", suggestedAmount: 300, suggestedPercentage: 0.09, alertThreshold: 0.85, color: "purple"),
                BudgetCategoryTemplate(name: "Entertainment & Recreation", suggestedAmount: 200, suggestedPercentage: 0.06, alertThreshold: 0.7, color: "pink"),
                BudgetCategoryTemplate(name: "Personal Care", suggestedAmount: 100, suggestedPercentage: 0.03, alertThreshold: 0.8, color: "indigo"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 83, suggestedPercentage: 0.025, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: true
        )
    }
    
    // MARK: - Artist/Creative Template
    private func artistCreativeTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "artist-creative",
            name: "Artist & Creative Budget",
            description: "For artists, musicians, and creatives with irregular income and project expenses",
            targetAudience: "Artists, musicians, writers, and creative professionals",
            categories: [
                BudgetCategoryTemplate(name: "Art Supplies & Materials", suggestedAmount: 300, suggestedPercentage: 0.15, alertThreshold: 0.85, color: "purple"),
                BudgetCategoryTemplate(name: "Studio/Workspace", suggestedAmount: 500, suggestedPercentage: 0.25, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Income Buffer Fund", suggestedAmount: 400, suggestedPercentage: 0.20, alertThreshold: 0.9, color: "blue"),
                BudgetCategoryTemplate(name: "Food & Groceries", suggestedAmount: 250, suggestedPercentage: 0.125, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Marketing & Promotion", suggestedAmount: 150, suggestedPercentage: 0.075, alertThreshold: 0.8, color: "pink"),
                BudgetCategoryTemplate(name: "Transportation", suggestedAmount: 100, suggestedPercentage: 0.05, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Utilities & Internet", suggestedAmount: 150, suggestedPercentage: 0.075, alertThreshold: 0.85, color: "yellow"),
                BudgetCategoryTemplate(name: "Professional Development", suggestedAmount: 100, suggestedPercentage: 0.05, alertThreshold: 0.8, color: "indigo"),
                BudgetCategoryTemplate(name: "Healthcare", suggestedAmount: 100, suggestedPercentage: 0.05, alertThreshold: 0.9, color: "red"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 50, suggestedPercentage: 0.025, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: true
        )
    }
    
    // MARK: - Healthcare Worker Template
    private func healthcareWorkerTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "healthcare-worker",
            name: "Healthcare Worker Budget",
            description: "For nurses, doctors, and healthcare professionals with shift work and continuing education",
            targetAudience: "Healthcare professionals and medical workers",
            categories: [
                BudgetCategoryTemplate(name: "Housing", suggestedAmount: 1000, suggestedPercentage: 0.28, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Student Loans", suggestedAmount: 500, suggestedPercentage: 0.14, alertThreshold: 0.9, color: "red"),
                BudgetCategoryTemplate(name: "Savings & Retirement", suggestedAmount: 500, suggestedPercentage: 0.14, alertThreshold: 0.9, color: "blue"),
                BudgetCategoryTemplate(name: "Food & Meal Prep", suggestedAmount: 400, suggestedPercentage: 0.11, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Transportation & Parking", suggestedAmount: 300, suggestedPercentage: 0.085, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Continuing Education", suggestedAmount: 200, suggestedPercentage: 0.055, alertThreshold: 0.85, color: "purple"),
                BudgetCategoryTemplate(name: "Professional Expenses", suggestedAmount: 150, suggestedPercentage: 0.04, alertThreshold: 0.85, color: "indigo"),
                BudgetCategoryTemplate(name: "Self-Care & Wellness", suggestedAmount: 200, suggestedPercentage: 0.055, alertThreshold: 0.8, color: "pink"),
                BudgetCategoryTemplate(name: "Utilities & Bills", suggestedAmount: 200, suggestedPercentage: 0.055, alertThreshold: 0.85, color: "yellow"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 150, suggestedPercentage: 0.04, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: true
        )
    }
    
    // MARK: - Teacher Template
    private func teacherTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "teacher",
            name: "Teacher Budget",
            description: "For educators managing classroom supplies and summer income gaps",
            targetAudience: "Teachers and education professionals",
            categories: [
                BudgetCategoryTemplate(name: "Housing", suggestedAmount: 900, suggestedPercentage: 0.30, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Summer Income Buffer", suggestedAmount: 450, suggestedPercentage: 0.15, alertThreshold: 0.9, color: "blue"),
                BudgetCategoryTemplate(name: "Classroom Supplies", suggestedAmount: 150, suggestedPercentage: 0.05, alertThreshold: 0.8, color: "purple"),
                BudgetCategoryTemplate(name: "Food & Groceries", suggestedAmount: 360, suggestedPercentage: 0.12, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Transportation", suggestedAmount: 240, suggestedPercentage: 0.08, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Professional Development", suggestedAmount: 150, suggestedPercentage: 0.05, alertThreshold: 0.85, color: "indigo"),
                BudgetCategoryTemplate(name: "Student Loans", suggestedAmount: 300, suggestedPercentage: 0.10, alertThreshold: 0.9, color: "red"),
                BudgetCategoryTemplate(name: "Healthcare", suggestedAmount: 180, suggestedPercentage: 0.06, alertThreshold: 0.9, color: "pink"),
                BudgetCategoryTemplate(name: "Utilities & Bills", suggestedAmount: 180, suggestedPercentage: 0.06, alertThreshold: 0.85, color: "yellow"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 90, suggestedPercentage: 0.03, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: true
        )
    }
    
    // MARK: - New Graduate Template
    private func newGraduateTemplate() -> BudgetTemplate {
        BudgetTemplate(
            id: "new-graduate",
            name: "New Graduate Budget",
            description: "For recent graduates starting their first job and building financial foundation",
            targetAudience: "Recent college graduates entering the workforce",
            categories: [
                BudgetCategoryTemplate(name: "Housing & Roommates", suggestedAmount: 700, suggestedPercentage: 0.28, alertThreshold: 0.9, color: "orange"),
                BudgetCategoryTemplate(name: "Student Loan Payments", suggestedAmount: 500, suggestedPercentage: 0.20, alertThreshold: 0.9, color: "red"),
                BudgetCategoryTemplate(name: "Emergency Fund Building", suggestedAmount: 300, suggestedPercentage: 0.12, alertThreshold: 0.9, color: "blue"),
                BudgetCategoryTemplate(name: "Food & Groceries", suggestedAmount: 250, suggestedPercentage: 0.10, alertThreshold: 0.8, color: "green"),
                BudgetCategoryTemplate(name: "Transportation", suggestedAmount: 200, suggestedPercentage: 0.08, alertThreshold: 0.8, color: "cyan"),
                BudgetCategoryTemplate(name: "Professional Wardrobe", suggestedAmount: 125, suggestedPercentage: 0.05, alertThreshold: 0.8, color: "indigo"),
                BudgetCategoryTemplate(name: "Utilities & Phone", suggestedAmount: 150, suggestedPercentage: 0.06, alertThreshold: 0.85, color: "yellow"),
                BudgetCategoryTemplate(name: "Social & Networking", suggestedAmount: 125, suggestedPercentage: 0.05, alertThreshold: 0.7, color: "pink"),
                BudgetCategoryTemplate(name: "Healthcare", suggestedAmount: 100, suggestedPercentage: 0.04, alertThreshold: 0.9, color: "purple"),
                BudgetCategoryTemplate(name: "Other", suggestedAmount: 50, suggestedPercentage: 0.02, alertThreshold: 0.8, color: "gray")
            ],
            defaultPeriod: .monthly,
            rolloverEnabled: true
        )
    }
    
    // MARK: - Helper Methods
    
    func calculateCategoryAmounts(template: BudgetTemplate, totalBudget: Decimal) -> [String: Decimal] {
        var amounts: [String: Decimal] = [:]
        
        for category in template.categories {
            let percentage = NSDecimalNumber(value: category.suggestedPercentage)
            let amount = totalBudget as NSDecimalNumber
            let calculatedAmount = amount.multiplying(by: percentage)
            amounts[category.name] = calculatedAmount as Decimal
        }
        
        return amounts
    }
}
