# Currency Support Guide

## Overview

ClariFi now supports multiple currencies, allowing users to track their finances in their preferred currency. The app supports 15 major world currencies with proper formatting and localization.

## Supported Currencies

| Currency | Code | Symbol | Example |
|----------|------|--------|---------|
| US Dollar | USD | $ | $1,234.56 |
| Canadian Dollar | CAD | CA$ | CA$1,234.56 |
| Euro | EUR | € | €1,234.56 |
| British Pound | GBP | £ | £1,234.56 |
| Japanese Yen | JPY | ¥ | ¥1,235 |
| Australian Dollar | AUD | A$ | A$1,234.56 |
| Swiss Franc | CHF | CHF | CHF1,234.56 |
| Chinese Yuan | CNY | ¥ | ¥1,234.56 |
| Indian Rupee | INR | ₹ | ₹1,234.56 |
| Mexican Peso | MXN | MX$ | MX$1,234.56 |
| Brazilian Real | BRL | R$ | R$1,234.56 |
| South Korean Won | KRW | ₩ | ₩1,235 |
| Singapore Dollar | SGD | S$ | S$1,234.56 |
| New Zealand Dollar | NZD | NZ$ | NZ$1,234.56 |
| Hong Kong Dollar | HKD | HK$ | HK$1,234.56 |

## User Experience

### Changing Currency

1. Open the app
2. Navigate to **Planning** tab
3. Tap **Currency** in the App Settings section
4. Search or browse available currencies
5. Tap your preferred currency
6. Confirmation message appears

### Auto-Detection

On first launch, the app automatically detects your currency based on:
1. Device locale currency code
2. Device region code
3. Falls back to USD if detection fails

### Currency Display

All amounts throughout the app are displayed in your selected currency:
- Transaction amounts
- Budget amounts
- Account balances
- Insights and reports
- Charts and graphs

## Implementation Details

### Core Components

#### 1. Currency Model (`Models/Currency.swift`)

```swift
enum Currency: String, CaseIterable {
    case usd = "USD"
    case cad = "CAD"
    // ... more currencies
    
    var symbol: String { }
    var name: String { }
    var flag: String { }
    var decimalPlaces: Int { }
}
```

#### 2. FormatterCache Actor (`Models/FormatterCache.swift`)

Thread-safe actor-based caching for NumberFormatter instances:

```swift
actor FormatterCache {
    private var formatters: [Currency: NumberFormatter] = [:]
    
    /// Synchronous formatter access (safe for sync contexts)
    func formatterSync(for currency: Currency) -> NumberFormatter
    
    /// Async formatter access (for async contexts)
    func formatter(for currency: Currency) async -> NumberFormatter
    
    /// Clear cached formatters
    func clearCache()
}
```

**Benefits:**
- Thread-safe access through actor isolation
- Performance optimization through caching
- No data races or synchronization issues
- Supports both sync and async contexts

#### 3. Currency Formatter (`CurrencyFormatter`)

```swift
class CurrencyFormatter {
    static let shared = CurrencyFormatter()
    private let formatterCache = FormatterCache()
    
    // Synchronous methods (most common)
    func format(_ amount: Decimal, currency: Currency) -> String
    func formatWithSymbol(_ amount: Decimal, currency: Currency) -> String
    
    // Async methods (for async contexts)
    func formatAsync(_ amount: Decimal, currency: Currency) async -> String
    func formatWithSymbolAsync(_ amount: Decimal, currency: Currency) async -> String
    
    func parse(_ string: String, currency: Currency) -> Decimal?
}
```

**Usage Pattern:**
- Use synchronous methods (`format`, `formatWithSymbol`) in Views and computed properties
- Use async methods (`formatAsync`, `formatWithSymbolAsync`) in async functions
- Formatters are cached in the actor for performance

#### 4. Currency Preference Manager (`CurrencyPreferenceManager`)

```swift
class CurrencyPreferenceManager: ObservableObject {
    static let shared = CurrencyPreferenceManager()
    
    @Published var preferredCurrency: Currency
    
    // Synchronous formatting with preferred currency
    func format(_ amount: Decimal) -> String
    func formatWithSymbol(_ amount: Decimal) -> String
    
    // Async formatting with preferred currency
    func formatAsync(_ amount: Decimal) async -> String
    func formatWithSymbolAsync(_ amount: Decimal) async -> String
}
```

### Usage in Code

#### Formatting Amounts

**Synchronous Formatting (Most Common):**

```swift
// Using CurrencyFormatter directly
let amount: Decimal = 1234.56
let formatted = CurrencyFormatter.shared.format(amount, currency: .usd)
// Result: "$1,234.56"

// Using CurrencyPreferenceManager (uses user's preferred currency)
let formatted = CurrencyPreferenceManager.shared.format(amount)
// Result: "$1,234.56" or "CA$1,234.56" depending on preference

// Using Decimal extension
let formatted = amount.formattedAsCurrency
// Result: "$1,234.56" (or user's preferred currency)

// Using Transaction extension
let transaction: Transaction = ...
let formatted = transaction.formattedAmount
// Result: "CA$1,234.56" (if transaction currency is CAD)
```

**Async Formatting (In Async Contexts):**

```swift
// In async functions or ViewModels
func processAmount(_ amount: Decimal) async -> String {
    // Use async formatter in async context
    let formatted = await CurrencyFormatter.shared.formatAsync(amount, currency: .usd)
    return formatted
}

// Using CurrencyPreferenceManager async
let formatted = await CurrencyPreferenceManager.shared.formatAsync(amount)
```

**When to Use Each:**
- **Synchronous methods**: Views, computed properties, non-async functions
- **Async methods**: Async functions, background processing, when already in async context
- **Actor-based caching**: Automatically used by both sync and async methods for performance

#### Creating Transactions

```swift
// Transactions automatically use preferred currency
let transaction = Transaction.create(
    in: context,
    date: Date(),
    merchant: "Whole Foods",
    amount: 85.50,
    category: "food_groceries",
    account: account
)
// transaction.currency is set to user's preferred currency
```

#### Accessing Currency in Views

```swift
struct MyView: View {
    @StateObject private var currencyManager = CurrencyPreferenceManager.shared
    
    var body: some View {
        Text(currencyManager.format(amount))
        Text("Currency: \(currencyManager.preferredCurrency.rawValue)")
    }
}
```

### Data Model

The Core Data model already includes currency fields:

```xml
<!-- Transaction Entity -->
<attribute name="currency" attributeType="String" defaultValueString="USD"/>

<!-- RecurringTransaction Entity -->
<attribute name="currency" attributeType="String" defaultValueString="USD"/>
```

### Migration

No data migration is required because:
1. Currency field already exists in the data model
2. Default value is "USD"
3. Existing transactions will continue to work
4. New transactions use the preferred currency

## Testing

### Manual Testing

1. **Currency Selection**
   - [ ] Open Currency settings
   - [ ] Search for currencies
   - [ ] Select different currencies
   - [ ] Verify confirmation message
   - [ ] Check currency persists after app restart

2. **Transaction Display**
   - [ ] Create transaction in USD
   - [ ] Change currency to CAD
   - [ ] Verify existing transactions still show correctly
   - [ ] Create new transaction
   - [ ] Verify new transaction uses CAD

3. **Budget Display**
   - [ ] Create budget in USD
   - [ ] Change currency to EUR
   - [ ] Verify budget amounts display correctly
   - [ ] Create new budget
   - [ ] Verify new budget uses EUR

4. **Edge Cases**
   - [ ] Test with JPY (0 decimal places)
   - [ ] Test with very large amounts
   - [ ] Test with very small amounts
   - [ ] Test currency symbols display correctly

### Automated Testing

```swift
func testCurrencyFormatting() {
    let amount: Decimal = 1234.56
    
    // Test USD
    let usdFormatted = amount.formatted(as: .usd)
    XCTAssertEqual(usdFormatted, "$1,234.56")
    
    // Test CAD
    let cadFormatted = amount.formatted(as: .cad)
    XCTAssertEqual(cadFormatted, "CA$1,234.56")
    
    // Test JPY (no decimals)
    let jpyFormatted = amount.formatted(as: .jpy)
    XCTAssertEqual(jpyFormatted, "¥1,235")
}

func testCurrencyPreference() {
    let manager = CurrencyPreferenceManager.shared
    
    // Change currency
    manager.preferredCurrency = .cad
    
    // Verify persistence
    XCTAssertEqual(manager.preferredCurrency, .cad)
    
    // Verify formatting uses new currency
    let formatted = manager.format(100)
    XCTAssertTrue(formatted.contains("CA$"))
}
```

## Accessibility

### VoiceOver Support

- Currency names are read clearly
- Currency codes are announced
- Example amounts are provided
- Selection state is announced

### Dynamic Type

- Currency symbols scale with text
- Amount formatting remains readable
- Settings UI adapts to text size

## Localization

Each currency uses its appropriate locale for formatting:
- Number grouping (commas vs periods)
- Decimal separators
- Currency symbol placement
- Right-to-left support (future)

## Performance

### Optimization

- Currency preference cached in memory
- Formatters cached in thread-safe actor
- Actor-based caching prevents redundant formatter creation
- No network calls required
- Minimal storage overhead
- Synchronous API available for non-async contexts

### Memory Usage

- Currency enum: ~1 KB
- Preference manager: ~2 KB
- FormatterCache actor: ~3 KB
- Cached formatters: ~5 KB (up to 20 currencies)
- Total: < 15 KB

### Thread Safety

- FormatterCache is an actor, ensuring thread-safe access
- No data races when accessing formatters from multiple threads
- Synchronous methods safe to call from any context
- Async methods integrate seamlessly with Swift concurrency

## Future Enhancements

### Phase 1 (Current)
- ✅ 15 major currencies supported
- ✅ User preference selection
- ✅ Automatic formatting
- ✅ Locale-aware display

### Phase 2 (Future)
- [ ] Currency conversion
- [ ] Exchange rate API integration
- [ ] Multi-currency accounts
- [ ] Historical exchange rates
- [ ] Conversion tracking

### Phase 3 (Future)
- [ ] Cryptocurrency support
- [ ] Custom currency symbols
- [ ] Regional currency variants
- [ ] Offline exchange rates

## Troubleshooting

### Currency Not Changing

**Issue**: Selected currency doesn't apply to new transactions  
**Solution**: Ensure `CurrencyPreferenceManager.shared` is used when creating transactions

### Formatting Issues

**Issue**: Currency symbols not displaying correctly  
**Solution**: Check device locale settings and font support

### Persistence Issues

**Issue**: Currency preference resets on app restart  
**Solution**: Verify UserDefaults key is correct: `"preferredCurrency"`

## API Reference

### Currency Enum

```swift
enum Currency: String, CaseIterable {
    var symbol: String
    var name: String
    var flag: String
    var localeIdentifier: String
    var decimalPlaces: Int
    var displayText: String
}
```

### FormatterCache

```swift
actor FormatterCache {
    func formatterSync(for currency: Currency) -> NumberFormatter
    func formatter(for currency: Currency) async -> NumberFormatter
    func clearCache()
    var cacheSize: Int
}
```

### CurrencyFormatter

```swift
class CurrencyFormatter {
    static let shared: CurrencyFormatter
    
    // Synchronous methods
    func format(_ amount: Decimal, currency: Currency) -> String
    func formatWithSymbol(_ amount: Decimal, currency: Currency) -> String
    
    // Async methods
    func formatAsync(_ amount: Decimal, currency: Currency) async -> String
    func formatWithSymbolAsync(_ amount: Decimal, currency: Currency) async -> String
    
    func parse(_ string: String, currency: Currency) -> Decimal?
}
```

### CurrencyPreferenceManager

```swift
class CurrencyPreferenceManager: ObservableObject {
    static let shared: CurrencyPreferenceManager
    
    @Published var preferredCurrency: Currency
    
    // Synchronous methods
    func format(_ amount: Decimal) -> String
    func formatWithSymbol(_ amount: Decimal) -> String
    
    // Async methods
    func formatAsync(_ amount: Decimal) async -> String
    func formatWithSymbolAsync(_ amount: Decimal) async -> String
}
```

### Extensions

```swift
extension Decimal {
    var formattedAsCurrency: String
    var formattedWithCurrencySymbol: String
    func formatted(as currency: Currency) -> String
}

extension Transaction {
    var effectiveCurrency: Currency
    var formattedAmount: String
    func setPreferredCurrency()
}
```

## Related Documentation

- [Architecture Documentation](../ARCHITECTURE.md)
- [User Guide](README.md)
- [Testing Guide](../Tests/README.md)

## Support

For issues or questions about currency support:
1. Check this guide first
2. Review the implementation files
3. Test with different currencies
4. Check device locale settings

---

**Last Updated**: 2025-10-14  
**Version**: 1.0  
**Status**: ✅ Implemented and Ready
