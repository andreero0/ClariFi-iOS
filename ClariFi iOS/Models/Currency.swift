//
//  Currency.swift
//  ClariFi_iOS
//
//  Multi-currency support model
//

import Foundation

/// Supported currencies in ClariFi
enum Currency: String, CaseIterable, Codable {
    case usd = "USD"
    case cad = "CAD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case aud = "AUD"
    case chf = "CHF"
    case cny = "CNY"
    case inr = "INR"
    case mxn = "MXN"
    case brl = "BRL"
    case krw = "KRW"
    case sgd = "SGD"
    case nzd = "NZD"
    case hkd = "HKD"
    
    /// Currency symbol
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .cad: return "CA$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .aud: return "A$"
        case .chf: return "CHF"
        case .cny: return "¥"
        case .inr: return "₹"
        case .mxn: return "MX$"
        case .brl: return "R$"
        case .krw: return "₩"
        case .sgd: return "S$"
        case .nzd: return "NZ$"
        case .hkd: return "HK$"
        }
    }
    
    /// Full currency name
    var name: String {
        switch self {
        case .usd: return "US Dollar"
        case .cad: return "Canadian Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .jpy: return "Japanese Yen"
        case .aud: return "Australian Dollar"
        case .chf: return "Swiss Franc"
        case .cny: return "Chinese Yuan"
        case .inr: return "Indian Rupee"
        case .mxn: return "Mexican Peso"
        case .brl: return "Brazilian Real"
        case .krw: return "South Korean Won"
        case .sgd: return "Singapore Dollar"
        case .nzd: return "New Zealand Dollar"
        case .hkd: return "Hong Kong Dollar"
        }
    }
    
    /// Locale identifier for proper formatting
    var localeIdentifier: String {
        switch self {
        case .usd: return "en_US"
        case .cad: return "en_CA"
        case .eur: return "en_EU"
        case .gbp: return "en_GB"
        case .jpy: return "ja_JP"
        case .aud: return "en_AU"
        case .chf: return "de_CH"
        case .cny: return "zh_CN"
        case .inr: return "en_IN"
        case .mxn: return "es_MX"
        case .brl: return "pt_BR"
        case .krw: return "ko_KR"
        case .sgd: return "en_SG"
        case .nzd: return "en_NZ"
        case .hkd: return "zh_HK"
        }
    }
    
    /// Number of decimal places (most currencies use 2, some like JPY use 0)
    var decimalPlaces: Int {
        switch self {
        case .jpy, .krw: return 0
        default: return 2
        }
    }
    
    /// Display text combining code and name
    var displayText: String {
        "\(rawValue) - \(name)"
    }
}

/// Currency formatting service with thread-safe formatter caching
class CurrencyFormatter {
    
    static let shared = CurrencyFormatter()
    
    private let formatterCache = FormatterCache()
    
    private init() {}
    
    /// Format a decimal amount with the specified currency (synchronous)
    func format(_ amount: Decimal, currency: Currency) -> String {
        let formatter = formatterCache.formatterSync(for: currency)
        
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency.symbol)\(amount)"
    }
    
    /// Format a decimal amount with the specified currency (async version)
    func formatAsync(_ amount: Decimal, currency: Currency) async -> String {
        let formatter = await formatterCache.formatter(for: currency)
        
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency.symbol)\(amount)"
    }
    
    /// Format with custom symbol (for display consistency)
    func formatWithSymbol(_ amount: Decimal, currency: Currency) -> String {
        // Create a decimal formatter for symbol formatting
        let decimalFormatter = NumberFormatter()
        decimalFormatter.numberStyle = .decimal
        decimalFormatter.maximumFractionDigits = currency.decimalPlaces
        decimalFormatter.minimumFractionDigits = currency.decimalPlaces
        decimalFormatter.groupingSeparator = ","
        decimalFormatter.decimalSeparator = "."
        
        let formattedNumber = decimalFormatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
        return "\(currency.symbol)\(formattedNumber)"
    }
    
    /// Format with custom symbol (async version for future async contexts)
    func formatWithSymbolAsync(_ amount: Decimal, currency: Currency) async -> String {
        // Create a decimal formatter for symbol formatting
        let decimalFormatter = NumberFormatter()
        decimalFormatter.numberStyle = .decimal
        decimalFormatter.maximumFractionDigits = currency.decimalPlaces
        decimalFormatter.minimumFractionDigits = currency.decimalPlaces
        decimalFormatter.groupingSeparator = ","
        decimalFormatter.decimalSeparator = "."
        
        let formattedNumber = decimalFormatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
        return "\(currency.symbol)\(formattedNumber)"
    }
    
    /// Parse a string to decimal (removing currency symbols)
    func parse(_ string: String, currency: Currency) -> Decimal? {
        let cleanString = string
            .replacingOccurrences(of: currency.symbol, with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        return Decimal(string: cleanString)
    }
    
    // MARK: - Synchronous Convenience Methods (for backward compatibility)
    
    /// Synchronous format method (creates formatter each time - use async version for performance)
    func formatSync(_ amount: Decimal, currency: Currency) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: currency.localeIdentifier)
        formatter.currencyCode = currency.rawValue
        formatter.maximumFractionDigits = currency.decimalPlaces
        formatter.minimumFractionDigits = currency.decimalPlaces
        
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency.symbol)\(amount)"
    }
    
    // MARK: - Cache Management
    
    /// Clear the formatter cache (useful for memory management)
    func clearCache() {
        Task {
            await formatterCache.clearCache()
        }
    }
    
    /// Get cache statistics
    func getCacheStats() async -> Int {
        return await formatterCache.cacheSize
    }
}

/// User currency preference manager
class CurrencyPreferenceManager: ObservableObject {
    
    static let shared = CurrencyPreferenceManager()
    
    private let userDefaultsKey = "preferredCurrency"
    
    @Published var preferredCurrency: Currency {
        didSet {
            UserDefaults.standard.set(preferredCurrency.rawValue, forKey: userDefaultsKey)
        }
    }
    
    private init() {
        // Try to load from UserDefaults
        if let savedCurrency = UserDefaults.standard.string(forKey: userDefaultsKey),
           let currency = Currency(rawValue: savedCurrency) {
            self.preferredCurrency = currency
        } else {
            // Default to USD or detect from locale
            self.preferredCurrency = Self.detectCurrencyFromLocale()
        }
    }
    
    /// Detect currency from user's locale
    private static func detectCurrencyFromLocale() -> Currency {
        let locale = Locale.current
        
        // Try to get currency code from locale
        if let currencyCode = locale.currency?.identifier,
           let currency = Currency(rawValue: currencyCode) {
            return currency
        }
        
        // Fallback based on region code
        if let regionCode = locale.region?.identifier {
            switch regionCode {
            case "US": return .usd
            case "CA": return .cad
            case "GB": return .gbp
            case "JP": return .jpy
            case "AU": return .aud
            case "CH": return .chf
            case "CN": return .cny
            case "IN": return .inr
            case "MX": return .mxn
            case "BR": return .brl
            case "KR": return .krw
            case "SG": return .sgd
            case "NZ": return .nzd
            case "HK": return .hkd
            default:
                // Check if in EU
                let euCountries = ["AT", "BE", "CY", "EE", "FI", "FR", "DE", "GR", "IE", 
                                   "IT", "LV", "LT", "LU", "MT", "NL", "PT", "SK", "SI", "ES"]
                if euCountries.contains(regionCode) {
                    return .eur
                }
            }
        }
        
        // Ultimate fallback
        return .usd
    }
    
    /// Format amount with preferred currency (synchronous)
    func format(_ amount: Decimal) -> String {
        CurrencyFormatter.shared.format(amount, currency: preferredCurrency)
    }
    
    /// Format amount with preferred currency (async version)
    func formatAsync(_ amount: Decimal) async -> String {
        await CurrencyFormatter.shared.formatAsync(amount, currency: preferredCurrency)
    }
    
    /// Format amount with symbol (synchronous)
    func formatWithSymbol(_ amount: Decimal) -> String {
        CurrencyFormatter.shared.formatWithSymbol(amount, currency: preferredCurrency)
    }
    
    /// Format amount with symbol (async version)
    func formatWithSymbolAsync(_ amount: Decimal) async -> String {
        await CurrencyFormatter.shared.formatWithSymbolAsync(amount, currency: preferredCurrency)
    }
}
