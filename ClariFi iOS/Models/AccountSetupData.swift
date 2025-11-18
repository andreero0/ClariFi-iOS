//
//  AccountSetupData.swift
//  ClariFi iOS
//
//  Model for account setup during onboarding
//

import Foundation

struct AccountSetupData: Identifiable, Equatable {
    let id: UUID
    var name: String
    var type: AccountType
    var initialBalance: Decimal
    var isDefault: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        type: AccountType,
        initialBalance: Decimal = 0,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.initialBalance = initialBalance
        self.isDefault = isDefault
    }
    
    // MARK: - Validation
    func validate() -> AccountSetupValidationError? {
        // Validate name
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            return .emptyName
        }
        
        if trimmedName.count < 2 {
            return .nameTooShort
        }
        
        if trimmedName.count > 50 {
            return .nameTooLong
        }
        
        // Validate initial balance
        if initialBalance < 0 && type != .credit {
            return .negativeBalance
        }
        
        return nil
    }
    
    var isValid: Bool {
        return validate() == nil
    }
    
    // MARK: - Computed Properties
    var displayName: String {
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var formattedBalance: String {
        return CurrencyFormatter.shared.formatSync(initialBalance, currency: .usd)
    }
}

// MARK: - Account Type
enum AccountType: String, CaseIterable, Codable {
    case checking = "Checking"
    case savings = "Savings"
    case credit = "Credit Card"
    case cash = "Cash"
    case investment = "Investment"
    
    var icon: String {
        switch self {
        case .checking:
            return "banknote"
        case .savings:
            return "dollarsign.circle"
        case .credit:
            return "creditcard"
        case .cash:
            return "dollarsign.square"
        case .investment:
            return "chart.line.uptrend.xyaxis"
        }
    }
    
    var description: String {
        switch self {
        case .checking:
            return "For everyday spending and bills"
        case .savings:
            return "For saving money and emergency funds"
        case .credit:
            return "For credit card transactions"
        case .cash:
            return "For cash transactions"
        case .investment:
            return "For investment accounts and portfolios"
        }
    }
    
    var allowsNegativeBalance: Bool {
        return self == .credit
    }
}

// MARK: - Validation Errors
enum AccountSetupValidationError: Error, LocalizedError {
    case emptyName
    case nameTooShort
    case nameTooLong
    case negativeBalance
    case invalidAccountType
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Account name cannot be empty"
        case .nameTooShort:
            return "Account name must be at least 2 characters"
        case .nameTooLong:
            return "Account name cannot exceed 50 characters"
        case .negativeBalance:
            return "Initial balance cannot be negative for this account type"
        case .invalidAccountType:
            return "Invalid account type selected"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .emptyName:
            return "Please enter a name for your account"
        case .nameTooShort:
            return "Please enter a longer account name"
        case .nameTooLong:
            return "Please shorten the account name"
        case .negativeBalance:
            return "Please enter a positive balance or use a Credit Card account type"
        case .invalidAccountType:
            return "Please select a valid account type"
        }
    }
}

// MARK: - Sample Data
extension AccountSetupData {
    static let sampleChecking = AccountSetupData(
        name: "Main Checking",
        type: .checking,
        initialBalance: 1500.00,
        isDefault: true
    )
    
    static let sampleSavings = AccountSetupData(
        name: "Emergency Fund",
        type: .savings,
        initialBalance: 5000.00,
        isDefault: false
    )
    
    static let sampleCredit = AccountSetupData(
        name: "Visa Card",
        type: .credit,
        initialBalance: -250.00,
        isDefault: false
    )
    
    static let sampleCash = AccountSetupData(
        name: "Cash",
        type: .cash,
        initialBalance: 100.00,
        isDefault: false
    )
    
    static let samples: [AccountSetupData] = [
        .sampleChecking,
        .sampleSavings,
        .sampleCredit,
        .sampleCash
    ]
}
