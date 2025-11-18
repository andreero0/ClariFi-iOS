import Foundation
import RegexBuilder

// MARK: - Transaction Parser Service Protocol

protocol TransactionParserService {
    func parseTransactions(from text: String, format: StatementFormat) async throws -> [ParsedTransaction]
    func improveAccuracy(with userCorrections: [TransactionCorrection]) async
}

// MARK: - Supporting Types

enum StatementFormat {
    case generic
    case bankOfAmerica
    case chase
    case wellsFargo
    case discover
    case americanExpress
    case capitalOne
    case citi
    case usBank
    case pncBank
    case tdBank
    case usaa
    case navyFederal
    case schwab
    case fidelity
    case venmo
    case paypal
    case cashApp
    case zelle
    case creditCard
    case debitCard
    // Canadian Banks
    case rbc
    case tdCanada
    case scotiabank
    case bmo
    case cibc
    case tangerine
    case desjardins
    
    var patterns: StatementPatterns {
        switch self {
        case .generic:
            return GenericStatementPatterns()
        case .bankOfAmerica:
            return BankOfAmericaPatterns()
        case .chase:
            return ChasePatterns()
        case .wellsFargo:
            return WellsFargoPatterns()
        case .discover:
            return DiscoverPatterns()
        case .americanExpress:
            return AmericanExpressPatterns()
        case .capitalOne:
            return CapitalOnePatterns()
        case .citi:
            return CitiPatterns()
        case .usBank:
            return USBankPatterns()
        case .pncBank:
            return PNCBankPatterns()
        case .tdBank:
            return TDBankPatterns()
        case .usaa:
            return USAAPatterns()
        case .navyFederal:
            return NavyFederalPatterns()
        case .schwab:
            return SchwabPatterns()
        case .fidelity:
            return FidelityPatterns()
        case .venmo:
            return VenmoPatterns()
        case .paypal:
            return PayPalPatterns()
        case .cashApp:
            return CashAppPatterns()
        case .zelle:
            return ZellePatterns()
        case .creditCard:
            return CreditCardPatterns()
        case .debitCard:
            return DebitCardPatterns()
        case .rbc:
            return RBCPatterns()
        case .tdCanada:
            return TDCanadaPatterns()
        case .scotiabank:
            return ScotiabankPatterns()
        case .bmo:
            return BMOPatterns()
        case .cibc:
            return CIBCPatterns()
        case .tangerine:
            return TangerinePatterns()
        case .desjardins:
            return DesjardinsPatterns()
        }
    }
}

struct ParsedTransaction: Identifiable {
    let id = UUID()
    var date: Date?
    var merchant: String?
    var amount: Decimal?
    var confidence: TransactionConfidence
    let rawText: String  // Keep original text immutable
    let lineNumber: Int  // Keep line number immutable
    var category: String?
    var transactionType: TransactionType?
}

struct TransactionConfidence {
    let date: Float
    let merchant: Float
    let amount: Float
    let overall: Float
    
    init(date: Float, merchant: Float, amount: Float) {
        self.date = date
        self.merchant = merchant
        self.amount = amount
        self.overall = (date + merchant + amount) / 3.0
    }
}

enum TransactionType {
    case debit
    case credit
    case fee
    case interest
    case transfer
    case payment
    case refund
    case unknown
}

struct TransactionCorrection {
    let originalText: String
    let correctedDate: Date?
    let correctedMerchant: String?
    let correctedAmount: Decimal?
    let feedback: CorrectionFeedback
}

enum CorrectionFeedback {
    case dateWrong
    case merchantWrong
    case amountWrong
    case notATransaction
    case missingTransaction
}

// MARK: - Parser Errors

enum ParserError: LocalizedError {
    case noTransactionsFound
    case invalidFormat
    case ambiguousData(String)
    case insufficientConfidence(Float)
    
    var errorDescription: String? {
        switch self {
        case .noTransactionsFound:
            return "No valid transactions could be parsed from the text"
        case .invalidFormat:
            return "Statement format not recognized"
        case .ambiguousData(let details):
            return "Ambiguous transaction data: \(details)"
        case .insufficientConfidence(let confidence):
            return "Parsing confidence too low: \(confidence)"
        }
    }
}