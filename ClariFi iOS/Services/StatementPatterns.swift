import Foundation
import RegexBuilder

// MARK: - Statement Patterns Protocol

protocol StatementPatterns {
    var datePatterns: [NSRegularExpression] { get }
    var amountPatterns: [NSRegularExpression] { get }
    var merchantPatterns: [NSRegularExpression] { get }
    var transactionLinePattern: NSRegularExpression { get }
    var excludePatterns: [NSRegularExpression] { get }
    
    func parseTransactionLine(_ line: String) -> (date: String?, merchant: String?, amount: String?)?
    func detectTransactionType(_ line: String) -> TransactionType
}

// MARK: - Base Pattern Implementation

class BaseStatementPatterns: StatementPatterns {
    
    var datePatterns: [NSRegularExpression] {
        return [
            try! NSRegularExpression(pattern: #"\b(\d{1,2})/(\d{1,2})/(\d{2,4})\b"#),
            try! NSRegularExpression(pattern: #"\b(\d{1,2})-(\d{1,2})-(\d{2,4})\b"#),
            try! NSRegularExpression(pattern: #"\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{1,2}),?\s+(\d{2,4})\b"#, options: .caseInsensitive),
            try! NSRegularExpression(pattern: #"\b(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{2,4})\b"#, options: .caseInsensitive)
        ]
    }
    
    var amountPatterns: [NSRegularExpression] {
        return [
            try! NSRegularExpression(pattern: #"\$\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)"#),
            try! NSRegularExpression(pattern: #"(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*\$"#),
            try! NSRegularExpression(pattern: #"\b(\d{1,3}(?:,\d{3})*\.\d{2})\b"#),
            try! NSRegularExpression(pattern: #"(\d+\.\d{2})\s*(CR|DR)?"#, options: .caseInsensitive)
        ]
    }
    
    lazy var merchantPatterns: [NSRegularExpression] = {
        return [
            try! NSRegularExpression(pattern: #"[A-Z][A-Z0-9\s&\-\.]{2,30}"#),
            try! NSRegularExpression(pattern: #"\b[A-Z]{2,}(?:\s+[A-Z0-9\-\.&]+)*\b"#)
        ]
    }()
    
    var transactionLinePattern: NSRegularExpression {
        // Generic pattern that looks for date + text + amount
        return try! NSRegularExpression(pattern: #"(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})\s+(.+?)\s+\$?(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)"#)
    }
    
    var excludePatterns: [NSRegularExpression] {
        return [
            try! NSRegularExpression(pattern: #"^(BALANCE|TOTAL|SUBTOTAL|PREVIOUS|PAYMENT|STATEMENT)"#, options: .caseInsensitive),
            try! NSRegularExpression(pattern: #"^(Page \d+|Account Number|Statement Period)"#, options: .caseInsensitive),
            try! NSRegularExpression(pattern: #"^\s*$"#), // Empty lines
            try! NSRegularExpression(pattern: #"^[\-\=\*]{3,}"#) // Separator lines
        ]
    }
    
    func parseTransactionLine(_ line: String) -> (date: String?, merchant: String?, amount: String?)? {
        let matches = transactionLinePattern.matches(in: line, range: NSRange(line.startIndex..., in: line))
        
        guard let match = matches.first, match.numberOfRanges >= 4 else {
            return nil
        }
        
        let dateRange = match.range(at: 1)
        let merchantRange = match.range(at: 2)
        let amountRange = match.range(at: 3)
        
        let date = dateRange.location != NSNotFound ? String(line[Range(dateRange, in: line)!]) : nil
        let merchant = merchantRange.location != NSNotFound ? String(line[Range(merchantRange, in: line)!]) : nil
        let amount = amountRange.location != NSNotFound ? String(line[Range(amountRange, in: line)!]) : nil
        
        return (date: date, merchant: merchant?.trimmingCharacters(in: .whitespaces), amount: amount)
    }
    
    func detectTransactionType(_ line: String) -> TransactionType {
        let lowercaseLine = line.lowercased()
        
        if lowercaseLine.contains("fee") || lowercaseLine.contains("charge") {
            return .fee
        } else if lowercaseLine.contains("interest") {
            return .interest
        } else if lowercaseLine.contains("transfer") {
            return .transfer
        } else if lowercaseLine.contains("payment") {
            return .payment
        } else if lowercaseLine.contains("refund") || lowercaseLine.contains("credit") {
            return .refund
        } else if lowercaseLine.contains("debit") || lowercaseLine.contains("-") {
            return .debit
        } else {
            return .unknown
        }
    }
}

// MARK: - Specific Bank Patterns

class GenericStatementPatterns: BaseStatementPatterns {
    // Uses base implementation
}

class BankOfAmericaPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // Bank of America specific format: MM/DD/YYYY MERCHANT NAME AMOUNT
        return try! NSRegularExpression(pattern: #"(\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
}

class ChasePatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // Chase specific format often includes reference numbers
        return try! NSRegularExpression(pattern: #"(\d{2}\/\d{2})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
}

class WellsFargoPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // Wells Fargo format
        return try! NSRegularExpression(pattern: #"(\d{1,2}\/\d{1,2})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
}

class DiscoverPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // Discover card format
        return try! NSRegularExpression(pattern: #"(\d{2}\/\d{2}\/\d{2})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
}

class AmericanExpressPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // AmEx format often has different date format
        return try! NSRegularExpression(pattern: #"([A-Z]{3}\s+\d{1,2})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
}

class CreditCardPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // Generic credit card format
        return try! NSRegularExpression(pattern: #"(\d{2}\/\d{2}\/\d{2,4})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
}

class DebitCardPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // Generic debit card format
        return try! NSRegularExpression(pattern: #"(\d{2}\/\d{2}\/\d{2,4})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
}

// MARK: - Additional Bank Patterns

class CapitalOnePatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // Capital One format: MM/DD/YYYY MERCHANT AMOUNT
        // Often includes transaction date and posting date
        return try! NSRegularExpression(pattern: #"(\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Trans Date|Post Date|Reference Number)"#, options: .caseInsensitive))
        return patterns
    }
}

class CitiPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // Citi format: MM/DD MERCHANT AMOUNT
        // Often uses two-digit dates with implied year
        return try! NSRegularExpression(pattern: #"(\d{2}\/\d{2})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Date|Description|Amount|New Balance)"#, options: .caseInsensitive))
        return patterns
    }
}

class USBankPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // US Bank format: MM/DD/YYYY DESCRIPTION AMOUNT
        return try! NSRegularExpression(pattern: #"(\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Beginning Balance|Ending Balance|Deposits|Withdrawals)"#, options: .caseInsensitive))
        return patterns
    }
}

class PNCBankPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // PNC format: MM/DD/YY DESCRIPTION AMOUNT
        return try! NSRegularExpression(pattern: #"(\d{2}\/\d{2}\/\d{2})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Date|Transaction|Deposits|Withdrawals|Balance)"#, options: .caseInsensitive))
        return patterns
    }
}

class TDBankPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // TD Bank format: MM/DD/YYYY DESCRIPTION AMOUNT
        return try! NSRegularExpression(pattern: #"(\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Transaction Date|Description|Debits|Credits)"#, options: .caseInsensitive))
        return patterns
    }
}

class USAAPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // USAA format: MM/DD/YYYY DESCRIPTION AMOUNT
        // Often includes check numbers and reference IDs
        return try! NSRegularExpression(pattern: #"(\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Date|Description|Debits|Credits|Balance|Check #)"#, options: .caseInsensitive))
        return patterns
    }
}

class NavyFederalPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // Navy Federal format: MM/DD/YY DESCRIPTION AMOUNT
        return try! NSRegularExpression(pattern: #"(\d{2}\/\d{2}\/\d{2})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Date|Transaction|Withdrawals|Deposits|Balance)"#, options: .caseInsensitive))
        return patterns
    }
}

class SchwabPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // Schwab format: MM/DD/YYYY DESCRIPTION AMOUNT
        // Investment accounts may have different formats
        return try! NSRegularExpression(pattern: #"(\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Date|Action|Description|Amount|Symbol|Quantity)"#, options: .caseInsensitive))
        return patterns
    }
}

class FidelityPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // Fidelity format: MM/DD/YYYY DESCRIPTION AMOUNT
        // Investment accounts with various transaction types
        return try! NSRegularExpression(pattern: #"(\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Run Date|Activity|Symbol|Quantity|Price|Amount)"#, options: .caseInsensitive))
        return patterns
    }
}

// MARK: - Digital Payment Platform Patterns

class VenmoPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // Venmo format: YYYY-MM-DD HH:MM:SS DESCRIPTION AMOUNT
        // Digital payments often include timestamps
        return try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2})\s+\d{2}:\d{2}:\d{2}\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var datePatterns: [NSRegularExpression] {
        var patterns = super.datePatterns
        patterns.insert(try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2})"#), at: 0)
        return patterns
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Datetime|Type|Status|From|To|Amount|Note)"#, options: .caseInsensitive))
        return patterns
    }
    
    override func detectTransactionType(_ line: String) -> TransactionType {
        let lowercaseLine = line.lowercased()
        
        if lowercaseLine.contains("payment") || lowercaseLine.contains("charge") {
            return .payment
        } else if lowercaseLine.contains("standard transfer") {
            return .transfer
        } else {
            return super.detectTransactionType(line)
        }
    }
}

class PayPalPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // PayPal format: MM/DD/YYYY DESCRIPTION AMOUNT STATUS
        return try! NSRegularExpression(pattern: #"(\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Date|Name|Type|Status|Currency|Gross|Fee|Net)"#, options: .caseInsensitive))
        return patterns
    }
    
    override func detectTransactionType(_ line: String) -> TransactionType {
        let lowercaseLine = line.lowercased()
        
        if lowercaseLine.contains("express checkout") || lowercaseLine.contains("website payment") {
            return .payment
        } else if lowercaseLine.contains("withdrawal") || lowercaseLine.contains("bank transfer") {
            return .transfer
        } else if lowercaseLine.contains("refund") {
            return .refund
        } else {
            return super.detectTransactionType(line)
        }
    }
}

class CashAppPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // Cash App format: YYYY-MM-DD DESCRIPTION AMOUNT
        return try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var datePatterns: [NSRegularExpression] {
        var patterns = super.datePatterns
        patterns.insert(try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2})"#), at: 0)
        return patterns
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Date|Transaction|Amount|Status|Notes)"#, options: .caseInsensitive))
        return patterns
    }
    
    override func detectTransactionType(_ line: String) -> TransactionType {
        let lowercaseLine = line.lowercased()
        
        if lowercaseLine.contains("cash out") || lowercaseLine.contains("standard deposit") {
            return .transfer
        } else if lowercaseLine.contains("bitcoin") || lowercaseLine.contains("stock") {
            return .payment
        } else {
            return super.detectTransactionType(line)
        }
    }
}

class ZellePatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // Zelle format: MM/DD/YYYY DESCRIPTION AMOUNT
        // Usually appears within bank statements
        return try! NSRegularExpression(pattern: #"(\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Date|Recipient|Sender|Amount|Status)"#, options: .caseInsensitive))
        return patterns
    }
    
    override func detectTransactionType(_ line: String) -> TransactionType {
        let lowercaseLine = line.lowercased()
        
        if lowercaseLine.contains("zelle sent") || lowercaseLine.contains("sent to") {
            return .transfer
        } else if lowercaseLine.contains("zelle received") || lowercaseLine.contains("received from") {
            return .transfer
        } else {
            return super.detectTransactionType(line)
        }
    }
}

// MARK: - Canadian Bank Patterns

class RBCPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // RBC (Royal Bank of Canada) format: YYYY-MM-DD or MM/DD/YYYY DESCRIPTION AMOUNT
        return try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2}|\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var datePatterns: [NSRegularExpression] {
        var patterns = super.datePatterns
        patterns.insert(try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2})"#), at: 0)
        return patterns
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Transaction Date|Posting Date|Description|Debit|Credit|Balance)"#, options: .caseInsensitive))
        return patterns
    }
}

class TDCanadaPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // TD Canada Trust format: YYYY-MM-DD or MM/DD/YYYY DESCRIPTION AMOUNT
        return try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2}|\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var datePatterns: [NSRegularExpression] {
        var patterns = super.datePatterns
        patterns.insert(try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2})"#), at: 0)
        return patterns
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Date|Transaction|Withdrawals|Deposits|Balance|Account)"#, options: .caseInsensitive))
        return patterns
    }
}

class ScotiabankPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // Scotiabank format: YYYY-MM-DD or DD/MM/YYYY DESCRIPTION AMOUNT
        // Note: Scotiabank sometimes uses DD/MM/YYYY format
        return try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2}|\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var datePatterns: [NSRegularExpression] {
        var patterns = super.datePatterns
        patterns.insert(try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2})"#), at: 0)
        // Add DD/MM/YYYY pattern for Scotiabank
        patterns.append(try! NSRegularExpression(pattern: #"\b(\d{2})\/(\d{2})\/(\d{4})\b"#))
        return patterns
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Transaction Date|Description|Debits|Credits|Balance|Opening|Closing)"#, options: .caseInsensitive))
        return patterns
    }
}

class BMOPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // BMO (Bank of Montreal) format: YYYY-MM-DD or MM/DD/YYYY DESCRIPTION AMOUNT
        return try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2}|\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var datePatterns: [NSRegularExpression] {
        var patterns = super.datePatterns
        patterns.insert(try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2})"#), at: 0)
        return patterns
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Date|Description|Withdrawals|Deposits|Balance|Statement Period)"#, options: .caseInsensitive))
        return patterns
    }
}

class CIBCPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // CIBC (Canadian Imperial Bank of Commerce) format: YYYY-MM-DD or MM/DD/YYYY DESCRIPTION AMOUNT
        return try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2}|\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var datePatterns: [NSRegularExpression] {
        var patterns = super.datePatterns
        patterns.insert(try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2})"#), at: 0)
        return patterns
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Transaction Date|Posting Date|Description|Debits|Credits|Balance)"#, options: .caseInsensitive))
        return patterns
    }
}

class TangerinePatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // Tangerine (online bank) format: YYYY-MM-DD DESCRIPTION AMOUNT
        // Tangerine typically uses ISO date format
        return try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }
    
    override var datePatterns: [NSRegularExpression] {
        var patterns = super.datePatterns
        patterns.insert(try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2})"#), at: 0)
        return patterns
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        patterns.append(try! NSRegularExpression(pattern: #"^(Date|Transaction|Money Out|Money In|Balance)"#, options: .caseInsensitive))
        return patterns
    }
    
    override func detectTransactionType(_ line: String) -> TransactionType {
        let lowercaseLine = line.lowercased()
        
        // Tangerine uses "Money Out" and "Money In" terminology
        if lowercaseLine.contains("money out") {
            return .debit
        } else if lowercaseLine.contains("money in") {
            return .credit
        } else {
            return super.detectTransactionType(line)
        }
    }
}

class DesjardinsPatterns: BaseStatementPatterns {
    override var transactionLinePattern: NSRegularExpression {
        // Desjardins (Quebec credit union) format: YYYY-MM-DD or DD/MM/YYYY DESCRIPTION AMOUNT
        // May include French language descriptions
        return try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2}|\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+(\$?\d{1,3}(?:,\d{3})*\.\d{2}|\d{1,3}(?:\s\d{3})*,\d{2}\s?\$)"#)
    }
    
    override var datePatterns: [NSRegularExpression] {
        var patterns = super.datePatterns
        patterns.insert(try! NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2})"#), at: 0)
        // Add DD/MM/YYYY pattern
        patterns.append(try! NSRegularExpression(pattern: #"\b(\d{2})\/(\d{2})\/(\d{4})\b"#))
        return patterns
    }
    
    override var amountPatterns: [NSRegularExpression] {
        var patterns = super.amountPatterns
        // Add French-style amount format: 1 234,56 $
        patterns.append(try! NSRegularExpression(pattern: #"(\d{1,3}(?:\s\d{3})*,\d{2})\s?\$"#))
        return patterns
    }
    
    override var excludePatterns: [NSRegularExpression] {
        var patterns = super.excludePatterns
        // French and English headers
        patterns.append(try! NSRegularExpression(pattern: #"^(Date|Description|Débit|Crédit|Solde|Balance|Transaction)"#, options: .caseInsensitive))
        patterns.append(try! NSRegularExpression(pattern: #"^(Date de transaction|Description|Retraits|Dépôts)"#, options: .caseInsensitive))
        return patterns
    }
    
    override func detectTransactionType(_ line: String) -> TransactionType {
        let lowercaseLine = line.lowercased()
        
        // French terminology support
        if lowercaseLine.contains("débit") || lowercaseLine.contains("retrait") {
            return .debit
        } else if lowercaseLine.contains("crédit") || lowercaseLine.contains("dépôt") {
            return .credit
        } else if lowercaseLine.contains("frais") {
            return .fee
        } else if lowercaseLine.contains("intérêt") {
            return .interest
        } else if lowercaseLine.contains("virement") || lowercaseLine.contains("transfert") {
            return .transfer
        } else {
            return super.detectTransactionType(line)
        }
    }
}
