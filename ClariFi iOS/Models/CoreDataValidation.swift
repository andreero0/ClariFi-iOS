//
//  CoreDataValidation.swift
//  ClariFi iOS
//
//  Created by aEro on 2025-10-10.
//

import Foundation
import CoreData

// MARK: - Validation Extensions

extension Transaction {
    
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateTransaction()
    }
    
    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateTransaction()
    }
    
    private func validateTransaction() throws {
        // Validate required fields
        guard let merchant = merchant, !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CoreDataValidationError.invalidMerchant
        }
        
        guard let category = category, !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CoreDataValidationError.invalidCategory
        }
        
        guard let currency = currency, !currency.isEmpty else {
            throw CoreDataValidationError.invalidCurrency
        }
        
        // Validate amount
        guard let amount = amount, amount.compare(NSDecimalNumber.zero) != .orderedSame else {
            throw CoreDataValidationError.invalidAmount
        }
        
        // Validate confidence score
        if confidence < 0.0 || confidence > 1.0 {
            throw CoreDataValidationError.invalidConfidence
        }
        
        // Validate date is not in the future (with some tolerance)
        if let date = date, date > Date().addingTimeInterval(86400) { // 1 day tolerance
            throw CoreDataValidationError.futureDate
        }
        
        // Validate merchant name length
        if merchant.count > 100 {
            throw CoreDataValidationError.merchantTooLong
        }
        
        // Validate category name length
        if category.count > 50 {
            throw CoreDataValidationError.categoryTooLong
        }
        
        // Validate notes length if present
        if let notes = notes, notes.count > 500 {
            throw CoreDataValidationError.notesTooLong
        }
    }
}

extension Account {
    
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateAccount()
    }
    
    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateAccount()
    }
    
    private func validateAccount() throws {
        // Validate required fields
        guard let name = name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CoreDataValidationError.invalidAccountName
        }
        
        guard let type = type, !type.isEmpty else {
            throw CoreDataValidationError.invalidAccountType
        }
        
        // Validate account type
        let validTypes = ["checking", "savings", "credit", "debit", "cash", "investment"]
        if !validTypes.contains(type.lowercased()) {
            throw CoreDataValidationError.invalidAccountType
        }
        
        // Validate name length
        if name.count > 100 {
            throw CoreDataValidationError.accountNameTooLong
        }
        
        // Validate last four digits if present
        if let lastFour = lastFourDigits {
            if lastFour.count != 4 || !lastFour.allSatisfy({ $0.isNumber }) {
                throw CoreDataValidationError.invalidLastFourDigits
            }
        }
    }
}

extension Budget {
    
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateBudget()
    }
    
    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateBudget()
    }
    
    private func validateBudget() throws {
        // Validate required fields
        guard let name = name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CoreDataValidationError.invalidBudgetName
        }
        
        guard let period = period, !period.isEmpty else {
            throw CoreDataValidationError.invalidBudgetPeriod
        }
        
        // Validate period
        let validPeriods = ["weekly", "monthly", "yearly"]
        if !validPeriods.contains(period.lowercased()) {
            throw CoreDataValidationError.invalidBudgetPeriod
        }
        
        // Validate name length
        if name.count > 100 {
            throw CoreDataValidationError.budgetNameTooLong
        }
        
        // Validate start date
        guard let startDate = startDate else {
            throw CoreDataValidationError.invalidStartDate
        }
        
        // Start date shouldn't be too far in the future
        if startDate > Date().addingTimeInterval(365 * 24 * 60 * 60) { // 1 year
            throw CoreDataValidationError.startDateTooFarInFuture
        }
    }
}

extension BudgetCategory {
    
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateBudgetCategory()
    }
    
    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateBudgetCategory()
    }
    
    private func validateBudgetCategory() throws {
        // Validate required fields
        guard let name = name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CoreDataValidationError.invalidCategoryName
        }
        
        // Validate amounts
        guard let budgetedAmount = budgetedAmount, budgetedAmount.compare(NSDecimalNumber.zero) == .orderedDescending else {
            throw CoreDataValidationError.invalidBudgetedAmount
        }
        
        guard let spentAmount = spentAmount, spentAmount.compare(NSDecimalNumber.zero) != .orderedAscending else {
            throw CoreDataValidationError.invalidSpentAmount
        }
        
        // Validate alert threshold
        if alertThreshold < 0.0 || alertThreshold > 1.0 {
            throw CoreDataValidationError.invalidAlertThreshold
        }
        
        // Validate name length
        if name.count > 50 {
            throw CoreDataValidationError.categoryNameTooLong
        }
        
        // Validate budget relationship
        guard budget != nil else {
            throw CoreDataValidationError.missingBudgetRelationship
        }
    }
}

extension Statement {
    
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateStatement()
    }
    
    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateStatement()
    }
    
    private func validateStatement() throws {
        // Validate required fields
        guard let fileName = fileName, !fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CoreDataValidationError.invalidFileName
        }
        
        guard let fileHash = fileHash, !fileHash.isEmpty else {
            throw CoreDataValidationError.invalidFileHash
        }
        
        guard let processingStatus = processingStatus, !processingStatus.isEmpty else {
            throw CoreDataValidationError.invalidProcessingStatus
        }
        
        guard let documentType = documentType, !documentType.isEmpty else {
            throw CoreDataValidationError.invalidDocumentType
        }
        
        // Validate processing status
        let validStatuses = ["pending", "processing", "completed", "failed", "cancelled"]
        if !validStatuses.contains(processingStatus.lowercased()) {
            throw CoreDataValidationError.invalidProcessingStatus
        }
        
        // Validate document type
        let validTypes = ["pdf", "jpg", "jpeg", "png", "heic"]
        if !validTypes.contains(documentType.lowercased()) {
            throw CoreDataValidationError.invalidDocumentType
        }
        
        // Validate file name length
        if fileName.count > 255 {
            throw CoreDataValidationError.fileNameTooLong
        }
        
        // Validate file size
        if fileSize < 0 {
            throw CoreDataValidationError.invalidFileSize
        }
        
        // Validate upload date
        guard let uploadDate = uploadDate else {
            throw CoreDataValidationError.invalidUploadDate
        }
        
        // Upload date shouldn't be in the future
        if uploadDate > Date().addingTimeInterval(3600) { // 1 hour tolerance
            throw CoreDataValidationError.futureUploadDate
        }
    }
}

// MARK: - Validation Error Types
enum CoreDataValidationError: LocalizedError {
    // Transaction validation errors
    case invalidMerchant
    case invalidCategory
    case invalidCurrency
    case invalidAmount
    case invalidConfidence
    case futureDate
    case merchantTooLong
    case categoryTooLong
    case notesTooLong
    
    // Account validation errors
    case invalidAccountName
    case invalidAccountType
    case accountNameTooLong
    case invalidLastFourDigits
    
    // Budget validation errors
    case invalidBudgetName
    case invalidBudgetPeriod
    case budgetNameTooLong
    case invalidStartDate
    case startDateTooFarInFuture
    
    // Budget Category validation errors
    case invalidCategoryName
    case invalidBudgetedAmount
    case invalidSpentAmount
    case invalidAlertThreshold
    case categoryNameTooLong
    case missingBudgetRelationship
    
    // Statement validation errors
    case invalidFileName
    case invalidFileHash
    case invalidProcessingStatus
    case invalidDocumentType
    case fileNameTooLong
    case invalidFileSize
    case invalidUploadDate
    case futureUploadDate
    
    var errorDescription: String? {
        switch self {
        // Transaction errors
        case .invalidMerchant:
            return "Merchant name is required and cannot be empty"
        case .invalidCategory:
            return "Category is required and cannot be empty"
        case .invalidCurrency:
            return "Currency is required and cannot be empty"
        case .invalidAmount:
            return "Amount must be greater than zero"
        case .invalidConfidence:
            return "Confidence score must be between 0.0 and 1.0"
        case .futureDate:
            return "Transaction date cannot be in the future"
        case .merchantTooLong:
            return "Merchant name cannot exceed 100 characters"
        case .categoryTooLong:
            return "Category name cannot exceed 50 characters"
        case .notesTooLong:
            return "Notes cannot exceed 500 characters"
            
        // Account errors
        case .invalidAccountName:
            return "Account name is required and cannot be empty"
        case .invalidAccountType:
            return "Account type must be one of: checking, savings, credit, debit, cash, investment"
        case .accountNameTooLong:
            return "Account name cannot exceed 100 characters"
        case .invalidLastFourDigits:
            return "Last four digits must be exactly 4 numeric characters"
            
        // Budget errors
        case .invalidBudgetName:
            return "Budget name is required and cannot be empty"
        case .invalidBudgetPeriod:
            return "Budget period must be one of: weekly, monthly, yearly"
        case .budgetNameTooLong:
            return "Budget name cannot exceed 100 characters"
        case .invalidStartDate:
            return "Start date is required"
        case .startDateTooFarInFuture:
            return "Start date cannot be more than 1 year in the future"
            
        // Budget Category errors
        case .invalidCategoryName:
            return "Category name is required and cannot be empty"
        case .invalidBudgetedAmount:
            return "Budgeted amount must be greater than zero"
        case .invalidSpentAmount:
            return "Spent amount cannot be negative"
        case .invalidAlertThreshold:
            return "Alert threshold must be between 0.0 and 1.0"
        case .categoryNameTooLong:
            return "Category name cannot exceed 50 characters"
        case .missingBudgetRelationship:
            return "Budget category must be associated with a budget"
            
        // Statement errors
        case .invalidFileName:
            return "File name is required and cannot be empty"
        case .invalidFileHash:
            return "File hash is required and cannot be empty"
        case .invalidProcessingStatus:
            return "Processing status must be one of: pending, processing, completed, failed, cancelled"
        case .invalidDocumentType:
            return "Document type must be one of: pdf, jpg, jpeg, png, heic"
        case .fileNameTooLong:
            return "File name cannot exceed 255 characters"
        case .invalidFileSize:
            return "File size cannot be negative"
        case .invalidUploadDate:
            return "Upload date is required"
        case .futureUploadDate:
            return "Upload date cannot be in the future"
        }
    }
}