//
//  CategoryDefinition.swift
//  ClariFi iOS
//
//  Created by Kiro on 2025-10-13.
//

import Foundation

/// Canonical category definition - single source of truth for all categories
struct CategoryDefinition: Identifiable, Codable, Hashable {
    let id: String
    let canonicalName: String
    let displayName: String
    let icon: String
    let parentCategory: String?
    let isEssential: Bool
    let budgetTemplateAliases: [String]
    
    // MARK: - Predefined Categories
    
    static let housing = CategoryDefinition(
        id: "housing",
        canonicalName: "housing",
        displayName: "Housing & Rent",
        icon: "house.fill",
        parentCategory: "needs",
        isEssential: true,
        budgetTemplateAliases: ["Housing", "Housing & Rent", "Housing (BAH)", "Housing & Home Office", "Rent/Mortgage"]
    )
    
    static let foodGroceries = CategoryDefinition(
        id: "food_groceries",
        canonicalName: "food_groceries",
        displayName: "Food & Groceries",
        icon: "cart.fill",
        parentCategory: "needs",
        isEssential: true,
        budgetTemplateAliases: ["Food & Groceries", "Groceries", "Food", "Food & Dining"]
    )
    
    static let dining = CategoryDefinition(
        id: "dining",
        canonicalName: "dining",
        displayName: "Dining & Restaurants",
        icon: "fork.knife",
        parentCategory: "wants",
        isEssential: false,
        budgetTemplateAliases: ["Dining & Restaurants", "Dining Out", "Restaurants", "Eating Out"]
    )
    
    static let transportation = CategoryDefinition(
        id: "transportation",
        canonicalName: "transportation",
        displayName: "Transportation",
        icon: "car.fill",
        parentCategory: "needs",
        isEssential: true,
        budgetTemplateAliases: ["Transportation", "Car Payment", "Gas & Fuel", "Public Transit", "Vehicle Expenses"]
    )
    
    static let utilities = CategoryDefinition(
        id: "utilities",
        canonicalName: "utilities",
        displayName: "Utilities",
        icon: "bolt.fill",
        parentCategory: "needs",
        isEssential: true,
        budgetTemplateAliases: ["Utilities", "Electric", "Water", "Gas", "Internet", "Phone"]
    )
    
    static let healthcare = CategoryDefinition(
        id: "healthcare",
        canonicalName: "healthcare",
        displayName: "Healthcare & Medical",
        icon: "cross.case.fill",
        parentCategory: "needs",
        isEssential: true,
        budgetTemplateAliases: ["Healthcare", "Medical", "Health Insurance", "Prescriptions", "Doctor Visits"]
    )
    
    static let insurance = CategoryDefinition(
        id: "insurance",
        canonicalName: "insurance",
        displayName: "Insurance",
        icon: "shield.fill",
        parentCategory: "needs",
        isEssential: true,
        budgetTemplateAliases: ["Insurance", "Life Insurance", "Auto Insurance", "Home Insurance", "Health Insurance"]
    )
    
    static let education = CategoryDefinition(
        id: "education",
        canonicalName: "education",
        displayName: "Education",
        icon: "book.fill",
        parentCategory: "needs",
        isEssential: true,
        budgetTemplateAliases: ["Education", "Tuition", "Student Loans", "Books", "School Supplies"]
    )
    
    static let entertainment = CategoryDefinition(
        id: "entertainment",
        canonicalName: "entertainment",
        displayName: "Entertainment",
        icon: "tv.fill",
        parentCategory: "wants",
        isEssential: false,
        budgetTemplateAliases: ["Entertainment", "Movies", "Concerts", "Hobbies", "Recreation"]
    )
    
    static let shopping = CategoryDefinition(
        id: "shopping",
        canonicalName: "shopping",
        displayName: "Shopping",
        icon: "bag.fill",
        parentCategory: "wants",
        isEssential: false,
        budgetTemplateAliases: ["Shopping", "Clothing", "Personal Care", "Household Items"]
    )
    
    static let subscriptions = CategoryDefinition(
        id: "subscriptions",
        canonicalName: "subscriptions",
        displayName: "Subscriptions",
        icon: "repeat.circle.fill",
        parentCategory: "wants",
        isEssential: false,
        budgetTemplateAliases: ["Subscriptions", "Streaming Services", "Memberships", "Software"]
    )
    
    static let savings = CategoryDefinition(
        id: "savings",
        canonicalName: "savings",
        displayName: "Savings",
        icon: "banknote.fill",
        parentCategory: "savings",
        isEssential: true,
        budgetTemplateAliases: ["Savings", "Emergency Fund", "Retirement", "Investments"]
    )
    
    static let debtPayment = CategoryDefinition(
        id: "debt_payment",
        canonicalName: "debt_payment",
        displayName: "Debt Payment",
        icon: "creditcard.fill",
        parentCategory: "needs",
        isEssential: true,
        budgetTemplateAliases: ["Debt Payment", "Credit Card Payment", "Loan Payment", "Student Loans"]
    )
    
    static let childcare = CategoryDefinition(
        id: "childcare",
        canonicalName: "childcare",
        displayName: "Childcare",
        icon: "figure.2.and.child.holdinghands",
        parentCategory: "needs",
        isEssential: true,
        budgetTemplateAliases: ["Childcare", "Daycare", "Babysitting", "Child Support"]
    )
    
    static let petCare = CategoryDefinition(
        id: "pet_care",
        canonicalName: "pet_care",
        displayName: "Pet Care",
        icon: "pawprint.fill",
        parentCategory: "wants",
        isEssential: false,
        budgetTemplateAliases: ["Pet Care", "Veterinary", "Pet Food", "Pet Supplies"]
    )
    
    static let gifts = CategoryDefinition(
        id: "gifts",
        canonicalName: "gifts",
        displayName: "Gifts & Donations",
        icon: "gift.fill",
        parentCategory: "wants",
        isEssential: false,
        budgetTemplateAliases: ["Gifts", "Donations", "Charity", "Presents"]
    )
    
    static let travel = CategoryDefinition(
        id: "travel",
        canonicalName: "travel",
        displayName: "Travel",
        icon: "airplane",
        parentCategory: "wants",
        isEssential: false,
        budgetTemplateAliases: ["Travel", "Vacation", "Hotels", "Flights"]
    )
    
    static let income = CategoryDefinition(
        id: "income",
        canonicalName: "income",
        displayName: "Income",
        icon: "dollarsign.circle.fill",
        parentCategory: nil,
        isEssential: false,
        budgetTemplateAliases: ["Income", "Salary", "Wages", "Bonus", "Side Income"]
    )
    
    static let transfer = CategoryDefinition(
        id: "transfer",
        canonicalName: "transfer",
        displayName: "Transfer",
        icon: "arrow.left.arrow.right",
        parentCategory: nil,
        isEssential: false,
        budgetTemplateAliases: ["Transfer", "Account Transfer", "Internal Transfer"]
    )
    
    static let other = CategoryDefinition(
        id: "other",
        canonicalName: "other",
        displayName: "Other",
        icon: "ellipsis.circle.fill",
        parentCategory: nil,
        isEssential: false,
        budgetTemplateAliases: ["Other", "Miscellaneous", "Uncategorized"]
    )
    
    // MARK: - All Categories
    
    static let allCategories: [CategoryDefinition] = [
        .housing,
        .foodGroceries,
        .dining,
        .transportation,
        .utilities,
        .healthcare,
        .insurance,
        .education,
        .entertainment,
        .shopping,
        .subscriptions,
        .savings,
        .debtPayment,
        .childcare,
        .petCare,
        .gifts,
        .travel,
        .income,
        .transfer,
        .other
    ]
}
