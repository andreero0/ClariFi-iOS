# Supported Statement Formats

ClariFi supports automatic parsing of bank statements, credit card statements, and digital payment platform exports from 21 different financial institutions and services.

## US Banks (15 formats)

### Major National Banks

1. **Bank of America**
   - Format: `MM/DD/YYYY MERCHANT AMOUNT`
   - Statement types: Checking, Savings, Credit Cards
   - Status: ✅ Fully Supported

2. **Chase (JPMorgan Chase)**
   - Format: `MM/DD MERCHANT AMOUNT`
   - Statement types: Checking, Savings, Credit Cards
   - Status: ✅ Fully Supported

3. **Wells Fargo**
   - Format: `MM/DD MERCHANT AMOUNT`
   - Statement types: Checking, Savings, Credit Cards
   - Status: ✅ Fully Supported

4. **Capital One**
   - Format: `MM/DD/YYYY MERCHANT AMOUNT`
   - Statement types: Checking, Savings, Credit Cards
   - Special features: Transaction and posting date support
   - Status: ✅ Fully Supported

5. **Citibank (Citi)**
   - Format: `MM/DD MERCHANT AMOUNT`
   - Statement types: Checking, Savings, Credit Cards
   - Special features: Two-digit dates with implied year
   - Status: ✅ Fully Supported

6. **US Bank**
   - Format: `MM/DD/YYYY DESCRIPTION AMOUNT`
   - Statement types: Checking, Savings
   - Status: ✅ Fully Supported

7. **PNC Bank**
   - Format: `MM/DD/YY DESCRIPTION AMOUNT`
   - Statement types: Checking, Savings
   - Status: ✅ Fully Supported

8. **TD Bank**
   - Format: `MM/DD/YYYY DESCRIPTION AMOUNT`
   - Statement types: Checking, Savings
   - Status: ✅ Fully Supported

### Credit Unions & Military Banks

9. **USAA**
   - Format: `MM/DD/YYYY DESCRIPTION AMOUNT`
   - Statement types: Checking, Savings, Credit Cards
   - Special features: Check number and reference ID support
   - Status: ✅ Fully Supported

10. **Navy Federal Credit Union**
    - Format: `MM/DD/YY DESCRIPTION AMOUNT`
    - Statement types: Checking, Savings, Credit Cards
    - Status: ✅ Fully Supported

### Credit Card Companies

11. **Discover Card**
    - Format: `MM/DD/YY MERCHANT AMOUNT`
    - Statement types: Credit Cards
    - Status: ✅ Fully Supported

12. **American Express**
    - Format: `MMM DD MERCHANT AMOUNT`
    - Statement types: Credit Cards, Charge Cards
    - Special features: Month name date format
    - Status: ✅ Fully Supported

### Generic Formats

13. **Generic Credit Card**
    - Format: `MM/DD/YYYY MERCHANT AMOUNT`
    - Use for: Any credit card not specifically listed
    - Status: ✅ Fully Supported

14. **Generic Debit Card**
    - Format: `MM/DD/YYYY MERCHANT AMOUNT`
    - Use for: Any debit card not specifically listed
    - Status: ✅ Fully Supported

15. **Generic Bank Statement**
    - Format: Flexible pattern matching
    - Use for: Any bank not specifically listed
    - Status: ✅ Fully Supported

## Investment & Brokerage Accounts (2 formats)

16. **Charles Schwab**
    - Format: `MM/DD/YYYY DESCRIPTION AMOUNT`
    - Account types: Banking, Brokerage, Investment
    - Special features: Handles both banking and investment transactions
    - Status: ✅ Fully Supported

17. **Fidelity**
    - Format: `MM/DD/YYYY DESCRIPTION AMOUNT`
    - Account types: Brokerage, Investment, 401(k)
    - Special features: Various investment transaction types
    - Status: ✅ Fully Supported

## Canadian Banks (7 formats)

22. **RBC (Royal Bank of Canada)**
    - Format: `YYYY-MM-DD DESCRIPTION AMOUNT` or `MM/DD/YYYY DESCRIPTION AMOUNT`
    - Account types: Checking, Savings, Credit Cards
    - Special features: ISO date format support
    - Status: ✅ Fully Supported

23. **TD Canada Trust**
    - Format: `YYYY-MM-DD DESCRIPTION AMOUNT` or `MM/DD/YYYY DESCRIPTION AMOUNT`
    - Account types: Checking, Savings, Credit Cards
    - Special features: ISO date format support
    - Status: ✅ Fully Supported

24. **Scotiabank**
    - Format: `YYYY-MM-DD DESCRIPTION AMOUNT` or `DD/MM/YYYY DESCRIPTION AMOUNT`
    - Account types: Checking, Savings, Credit Cards
    - Special features: Supports both date formats
    - Status: ✅ Fully Supported

25. **BMO (Bank of Montreal)**
    - Format: `YYYY-MM-DD DESCRIPTION AMOUNT` or `MM/DD/YYYY DESCRIPTION AMOUNT`
    - Account types: Checking, Savings, Credit Cards
    - Special features: ISO date format support
    - Status: ✅ Fully Supported

26. **CIBC (Canadian Imperial Bank of Commerce)**
    - Format: `YYYY-MM-DD DESCRIPTION AMOUNT` or `MM/DD/YYYY DESCRIPTION AMOUNT`
    - Account types: Checking, Savings, Credit Cards
    - Special features: ISO date format support
    - Status: ✅ Fully Supported

27. **Tangerine**
    - Format: `YYYY-MM-DD DESCRIPTION AMOUNT`
    - Account types: Checking, Savings
    - Special features: "Money In" / "Money Out" terminology
    - Status: ✅ Fully Supported

28. **Desjardins**
    - Format: `YYYY-MM-DD DESCRIPTION AMOUNT` or `DD/MM/YYYY DESCRIPTION AMOUNT`
    - Account types: Checking, Savings, Credit Cards
    - Special features: French language support, French amount format (1 234,56 $)
    - Bilingual: English and French headers supported
    - Status: ✅ Fully Supported

## Digital Payment Platforms (4 formats)

18. **Venmo**
    - Format: `YYYY-MM-DD HH:MM:SS DESCRIPTION AMOUNT`
    - Export format: CSV or statement view
    - Special features: Timestamp support, payment direction detection
    - Transaction types: Payments, Charges, Standard Transfers
    - Status: ✅ Fully Supported

19. **PayPal**
    - Format: `MM/DD/YYYY DESCRIPTION AMOUNT STATUS`
    - Export format: CSV or statement view
    - Special features: Status tracking, fee separation
    - Transaction types: Express Checkout, Website Payments, Withdrawals, Refunds
    - Status: ✅ Fully Supported

20. **Cash App**
    - Format: `YYYY-MM-DD DESCRIPTION AMOUNT`
    - Export format: CSV or statement view
    - Special features: Bitcoin and stock transaction support
    - Transaction types: Cash Out, Standard Deposit, Bitcoin, Stock purchases
    - Status: ✅ Fully Supported

21. **Zelle**
    - Format: `MM/DD/YYYY DESCRIPTION AMOUNT`
    - Export format: Usually within bank statements
    - Special features: Integrated bank transfer detection
    - Transaction types: Sent and Received transfers
    - Status: ✅ Fully Supported

**Note**: Numbers 22-28 are Canadian banks (see Canadian Banks section above)

## Supported File Formats

ClariFi can process statements in the following file formats:

- **PDF** (.pdf) - Most common format for bank statements
- **JPEG** (.jpg, .jpeg) - Photos of paper statements
- **PNG** (.png) - Screenshots or scanned statements
- **HEIC** (.heic) - iPhone photos of statements

## How to Upload Statements

1. **From Files**: Tap the upload button and select a PDF or image file
2. **From Camera**: Take a photo of your paper statement directly in the app
3. **From Photos**: Select an existing photo of a statement from your photo library

## Parsing Features

### Automatic Detection

ClariFi automatically detects:
- Transaction dates (multiple format support)
- Merchant names (with intelligent cleaning)
- Transaction amounts (with currency symbol handling)
- Transaction types (debit, credit, fee, interest, transfer, etc.)
- Categories (automatic categorization based on merchant patterns)

### Confidence Scoring

Each parsed transaction receives a confidence score:
- **High Confidence (90%+)**: Ready to import
- **Medium Confidence (70-89%)**: May need review
- **Low Confidence (<70%)**: Requires manual verification

### Smart Categorization

Transactions are automatically categorized into:
- Groceries
- Dining & Restaurants
- Transportation & Gas
- Shopping & Retail
- Entertainment & Subscriptions
- Utilities & Bills
- Healthcare
- Transfers & Payments
- Fees & Charges
- Interest
- Other

## Privacy & Security

All statement processing happens **locally on your device**:
- ✅ No data sent to external servers
- ✅ No cloud processing required
- ✅ Complete privacy and data ownership
- ✅ Encrypted local storage
- ✅ Secure file handling with automatic cleanup

## Troubleshooting

### Statement Not Parsing Correctly?

1. **Try a different format**: Select a specific bank format instead of "Generic"
2. **Improve image quality**: Ensure the statement is well-lit and in focus
3. **Use PDF when possible**: PDFs generally parse more accurately than photos
4. **Manual entry fallback**: You can always enter transactions manually

### Missing Transactions?

- Check that the statement includes transaction details (not just summaries)
- Verify the date range covers the transactions you expect
- Look for transactions flagged for manual review

### Wrong Categories?

- Correct the category for any transaction
- ClariFi learns from your corrections for future imports
- Create custom categorization rules for specific merchants

## Requesting New Format Support

Don't see your bank or payment platform? You can:
1. Use the "Generic" format (works for most statements)
2. Request support for your specific institution through the app feedback
3. Manually enter transactions as a fallback

## Future Format Support

We're continuously adding support for more institutions. Upcoming formats include:
- International banks
- Cryptocurrency exchanges (Coinbase, Binance, Kraken)
- Buy Now Pay Later services (Affirm, Klarna, Afterpay)
- Additional digital wallets (Apple Pay, Google Pay)

---

**Last Updated**: January 2024
**Total Formats Supported**: 28
**Success Rate**: 95%+ for supported formats
**Geographic Coverage**: United States and Canada
