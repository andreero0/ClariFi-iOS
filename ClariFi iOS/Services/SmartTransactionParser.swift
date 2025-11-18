import Foundation

// MARK: - Array Extension for Chunking

extension Array {
    /// Split array into chunks of specified size
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Smart Transaction Parser Implementation

class SmartTransactionParser: TransactionParserService {
    
    private let dateFormatter: DateFormatter
    private let alternativeDateFormatter: DateFormatter
    private let monthNameFormatter: DateFormatter
    private let isoDateFormatter: DateFormatter
    private let shortDateFormatter: DateFormatter
    private let correctionStore = CorrectionStore()
    private let minimumConfidence: Float = 0.6
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        alternativeDateFormatter = DateFormatter()
        alternativeDateFormatter.dateFormat = "MM/dd/yy"
        
        monthNameFormatter = DateFormatter()
        monthNameFormatter.dateFormat = "MMM dd, yyyy"
        
        isoDateFormatter = DateFormatter()
        isoDateFormatter.dateFormat = "yyyy-MM-dd"
        
        shortDateFormatter = DateFormatter()
        shortDateFormatter.dateFormat = "MM/dd"
    }
    
    // MARK: - Public Methods
    
    func parseTransactions(from text: String, format: StatementFormat) async throws -> [ParsedTransaction] {
        let lines = preprocessText(text)
        let patterns = format.patterns
        
        // For small files, use sequential parsing to avoid overhead
        if lines.count < 50 {
            return try await parseSequentially(lines: lines, patterns: patterns)
        }
        
        // For larger files, use parallel parsing
        return try await parseInParallel(lines: lines, patterns: patterns)
    }
    
    // MARK: - Sequential Parsing (for small files)
    
    private func parseSequentially(lines: [String], patterns: StatementPatterns) async throws -> [ParsedTransaction] {
        var parsedTransactions: [ParsedTransaction] = []
        
        for (lineNumber, line) in lines.enumerated() {
            // Skip lines that match exclude patterns
            if shouldExcludeLine(line, patterns: patterns) {
                continue
            }
            
            // Try to parse the line as a transaction
            if let transaction = parseTransactionLine(line, lineNumber: lineNumber, patterns: patterns) {
                // Only include transactions with sufficient confidence
                if transaction.confidence.overall >= minimumConfidence {
                    parsedTransactions.append(transaction)
                }
            }
        }
        
        if parsedTransactions.isEmpty {
            throw ParserError.noTransactionsFound
        }
        
        // Apply user corrections and learning
        let correctedTransactions = await applyCorrectionLearning(to: parsedTransactions)
        
        return correctedTransactions
    }
    
    // MARK: - Parallel Parsing (for large files)
    
    private func parseInParallel(lines: [String], patterns: StatementPatterns) async throws -> [ParsedTransaction] {
        // Chunk lines into batches for parallel processing
        let chunkSize = 100
        let chunks = lines.chunked(into: chunkSize)
        
        // Parse chunks in parallel
        return try await withThrowingTaskGroup(of: [ParsedTransaction].self) { group in
            for (chunkIndex, chunk) in chunks.enumerated() {
                group.addTask {
                    await self.parseChunk(chunk, startLineNumber: chunkIndex * chunkSize, patterns: patterns)
                }
            }
            
            var allTransactions: [ParsedTransaction] = []
            for try await chunkTransactions in group {
                allTransactions.append(contentsOf: chunkTransactions)
            }
            
            if allTransactions.isEmpty {
                throw ParserError.noTransactionsFound
            }
            
            // Apply user corrections and learning
            let correctedTransactions = await self.applyCorrectionLearning(to: allTransactions)
            
            return correctedTransactions
        }
    }
    
    private func parseChunk(_ lines: [String], startLineNumber: Int, patterns: StatementPatterns) async -> [ParsedTransaction] {
        var chunkTransactions: [ParsedTransaction] = []
        
        for (index, line) in lines.enumerated() {
            let lineNumber = startLineNumber + index
            
            // Skip lines that match exclude patterns
            if shouldExcludeLine(line, patterns: patterns) {
                continue
            }
            
            // Try to parse the line as a transaction
            if let transaction = parseTransactionLine(line, lineNumber: lineNumber, patterns: patterns) {
                // Only include transactions with sufficient confidence
                if transaction.confidence.overall >= minimumConfidence {
                    chunkTransactions.append(transaction)
                }
            }
        }
        
        return chunkTransactions
    }
    
    func improveAccuracy(with userCorrections: [TransactionCorrection]) async {
        await correctionStore.add(userCorrections)
        
        // In a real implementation, this would update ML models or pattern weights
        // For now, we store corrections to apply pattern learning
    }
    
    // MARK: - Private Methods
    
    private func preprocessText(_ text: String) -> [String] {
        // Split into lines and clean up
        let lines = text.components(separatedBy: .newlines)
        
        return lines.map { line in
            // Remove extra whitespace
            let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
            // Normalize multiple spaces to single spaces
            return cleaned.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        }.filter { !$0.isEmpty }
    }
    
    private func shouldExcludeLine(_ line: String, patterns: StatementPatterns) -> Bool {
        for excludePattern in patterns.excludePatterns {
            if excludePattern.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil {
                return true
            }
        }
        return false
    }
    
    private func parseTransactionLine(_ line: String, lineNumber: Int, patterns: StatementPatterns) -> ParsedTransaction? {
        // Try to parse using the pattern's main transaction line pattern
        if let parsed = patterns.parseTransactionLine(line) {
            let date = parseDate(from: parsed.date)
            let merchant = cleanMerchant(parsed.merchant)
            let amount = parseAmount(from: parsed.amount)
            
            let confidence = calculateConfidence(
                dateString: parsed.date,
                merchantString: parsed.merchant,
                amountString: parsed.amount,
                parsedDate: date,
                parsedMerchant: merchant,
                parsedAmount: amount
            )
            
            let transactionType = patterns.detectTransactionType(line)
            
            return ParsedTransaction(
                date: date,
                merchant: merchant,
                amount: amount,
                confidence: confidence,
                rawText: line,
                lineNumber: lineNumber,
                category: predictCategory(for: merchant, amount: amount, type: transactionType),
                transactionType: transactionType
            )
        }
        
        // Fallback: try individual pattern matching
        return parseWithFallbackPatterns(line, lineNumber: lineNumber, patterns: patterns)
    }
    
    private func parseWithFallbackPatterns(_ line: String, lineNumber: Int, patterns: StatementPatterns) -> ParsedTransaction? {
        var dateString: String?
        var merchantString: String?
        var amountString: String?
        
        // Try to find date
        for datePattern in patterns.datePatterns {
            if let match = datePattern.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                dateString = String(line[Range(match.range, in: line)!])
                break
            }
        }
        
        // Try to find amount
        for amountPattern in patterns.amountPatterns {
            if let match = amountPattern.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                let fullMatch = String(line[Range(match.range, in: line)!])
                // Extract just the numeric part
                let numericPattern = try! NSRegularExpression(pattern: #"(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)"#)
                if let numericMatch = numericPattern.firstMatch(in: fullMatch, range: NSRange(fullMatch.startIndex..., in: fullMatch)) {
                    amountString = String(fullMatch[Range(numericMatch.range(at: 1), in: fullMatch)!])
                }
                break
            }
        }
        
        // Try to find merchant (everything else that looks like a merchant name)
        if dateString != nil && amountString != nil {
            var workingLine = line
            
            // Remove date and amount from line to isolate merchant
            if let dateStr = dateString {
                workingLine = workingLine.replacingOccurrences(of: dateStr, with: "")
            }
            if let amountStr = amountString {
                workingLine = workingLine.replacingOccurrences(of: "$" + amountStr, with: "")
                workingLine = workingLine.replacingOccurrences(of: amountStr, with: "")
            }
            
            merchantString = workingLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if merchantString?.isEmpty == true {
                merchantString = nil
            }
        }
        
        // Only create transaction if we have at least date and amount
        guard dateString != nil && amountString != nil else {
            return nil
        }
        
        let date = parseDate(from: dateString)
        let merchant = cleanMerchant(merchantString)
        let amount = parseAmount(from: amountString)
        
        let confidence = calculateConfidence(
            dateString: dateString,
            merchantString: merchantString,
            amountString: amountString,
            parsedDate: date,
            parsedMerchant: merchant,
            parsedAmount: amount
        )
        
        let transactionType = patterns.detectTransactionType(line)
        
        return ParsedTransaction(
            date: date,
            merchant: merchant,
            amount: amount,
            confidence: confidence,
            rawText: line,
            lineNumber: lineNumber,
            category: predictCategory(for: merchant, amount: amount, type: transactionType),
            transactionType: transactionType
        )
    }
    
    private func parseDate(from dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        // Try different date formats
        let formatters = [
            dateFormatter,           // MM/dd/yyyy
            alternativeDateFormatter, // MM/dd/yy
            monthNameFormatter,      // MMM dd, yyyy
            isoDateFormatter,        // yyyy-MM-dd (for digital platforms)
            shortDateFormatter       // MM/dd
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        // Try to handle partial dates (MM/DD without year)
        if dateString.contains("/") && dateString.components(separatedBy: "/").count == 2 {
            let currentYear = Calendar.current.component(.year, from: Date())
            let fullDateString = dateString + "/\(currentYear)"
            return dateFormatter.date(from: fullDateString)
        }
        
        return nil
    }
    
    private func cleanMerchant(_ merchantString: String?) -> String? {
        guard let merchant = merchantString else { return nil }
        
        var cleaned = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common prefixes/suffixes
        let cleanupPatterns = [
            #"^\d+\s+"#, // Remove leading numbers
            #"\s+\d+$"#, // Remove trailing numbers
            #"^(DEBIT|CREDIT|PURCHASE|PAYMENT)\s+"#, // Remove transaction type prefixes
            #"\s+(DEBIT|CREDIT|PURCHASE|PAYMENT)$"#  // Remove transaction type suffixes
        ]
        
        for pattern in cleanupPatterns {
            cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: .regularExpression, range: nil)
        }
        
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned.isEmpty ? nil : cleaned
    }
    
    private func parseAmount(from amountString: String?) -> Decimal? {
        guard let amountString = amountString else { return nil }
        
        // Remove currency symbols and clean up
        let cleaned = amountString
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Decimal(string: cleaned)
    }
    
    private func calculateConfidence(
        dateString: String?,
        merchantString: String?,
        amountString: String?,
        parsedDate: Date?,
        parsedMerchant: String?,
        parsedAmount: Decimal?
    ) -> TransactionConfidence {
        
        let dateConfidence: Float = {
            guard let dateString = dateString else { return 0.0 }
            if parsedDate != nil {
                // Higher confidence for full dates
                if dateString.contains("/") && dateString.components(separatedBy: "/").count == 3 {
                    return 0.95
                } else {
                    return 0.8
                }
            }
            return 0.1
        }()
        
        let merchantConfidence: Float = {
            guard merchantString != nil else { return 0.0 }
            if let merchant = parsedMerchant, !merchant.isEmpty {
                // Higher confidence for longer, more descriptive merchant names
                let length = merchant.count
                if length > 10 {
                    return 0.9
                } else if length > 5 {
                    return 0.7
                } else {
                    return 0.5
                }
            }
            return 0.1
        }()
        
        let amountConfidence: Float = {
            guard let amountString = amountString else { return 0.0 }
            if parsedAmount != nil {
                // Higher confidence for properly formatted amounts
                if amountString.contains("$") && amountString.contains(".") {
                    return 0.95
                } else if amountString.contains(".") {
                    return 0.85
                } else {
                    return 0.6
                }
            }
            return 0.1
        }()
        
        return TransactionConfidence(
            date: dateConfidence,
            merchant: merchantConfidence,
            amount: amountConfidence
        )
    }
    
    private func predictCategory(for merchant: String?, amount: Decimal?, type: TransactionType) -> String? {
        guard let merchant = merchant else { return nil }
        
        let lowercaseMerchant = merchant.lowercased()
        
        // Category prediction based on merchant name patterns
        
        // Groceries & Food
        if lowercaseMerchant.contains("grocery") || lowercaseMerchant.contains("market") || 
           lowercaseMerchant.contains("food") || lowercaseMerchant.contains("safeway") ||
           lowercaseMerchant.contains("kroger") || lowercaseMerchant.contains("whole foods") ||
           lowercaseMerchant.contains("trader joe") || lowercaseMerchant.contains("costco") {
            return "Groceries"
        }
        
        // Gas & Transportation
        else if lowercaseMerchant.contains("gas") || lowercaseMerchant.contains("fuel") || 
                lowercaseMerchant.contains("shell") || lowercaseMerchant.contains("exxon") ||
                lowercaseMerchant.contains("chevron") || lowercaseMerchant.contains("bp ") ||
                lowercaseMerchant.contains("mobil") || lowercaseMerchant.contains("uber") ||
                lowercaseMerchant.contains("lyft") || lowercaseMerchant.contains("taxi") {
            return "Transportation"
        }
        
        // Dining & Restaurants
        else if lowercaseMerchant.contains("restaurant") || lowercaseMerchant.contains("cafe") || 
                lowercaseMerchant.contains("pizza") || lowercaseMerchant.contains("coffee") ||
                lowercaseMerchant.contains("starbucks") || lowercaseMerchant.contains("mcdonald") ||
                lowercaseMerchant.contains("burger") || lowercaseMerchant.contains("dining") ||
                lowercaseMerchant.contains("bar ") || lowercaseMerchant.contains("grill") {
            return "Dining"
        }
        
        // Shopping & Retail
        else if lowercaseMerchant.contains("amazon") || lowercaseMerchant.contains("target") || 
                lowercaseMerchant.contains("walmart") || lowercaseMerchant.contains("ebay") ||
                lowercaseMerchant.contains("etsy") || lowercaseMerchant.contains("best buy") ||
                lowercaseMerchant.contains("home depot") || lowercaseMerchant.contains("lowes") ||
                lowercaseMerchant.contains("macy") || lowercaseMerchant.contains("nordstrom") {
            return "Shopping"
        }
        
        // Entertainment & Subscriptions
        else if lowercaseMerchant.contains("netflix") || lowercaseMerchant.contains("spotify") || 
                lowercaseMerchant.contains("subscription") || lowercaseMerchant.contains("hulu") ||
                lowercaseMerchant.contains("disney") || lowercaseMerchant.contains("apple.com") ||
                lowercaseMerchant.contains("youtube") || lowercaseMerchant.contains("hbo") ||
                lowercaseMerchant.contains("prime video") || lowercaseMerchant.contains("gaming") {
            return "Entertainment"
        }
        
        // Utilities & Bills
        else if lowercaseMerchant.contains("electric") || lowercaseMerchant.contains("utility") ||
                lowercaseMerchant.contains("water") || lowercaseMerchant.contains("internet") ||
                lowercaseMerchant.contains("phone") || lowercaseMerchant.contains("verizon") ||
                lowercaseMerchant.contains("at&t") || lowercaseMerchant.contains("t-mobile") ||
                lowercaseMerchant.contains("comcast") || lowercaseMerchant.contains("spectrum") {
            return "Utilities"
        }
        
        // Healthcare
        else if lowercaseMerchant.contains("pharmacy") || lowercaseMerchant.contains("medical") ||
                lowercaseMerchant.contains("doctor") || lowercaseMerchant.contains("hospital") ||
                lowercaseMerchant.contains("cvs") || lowercaseMerchant.contains("walgreens") ||
                lowercaseMerchant.contains("health") || lowercaseMerchant.contains("dental") {
            return "Healthcare"
        }
        
        // Digital Payments & Transfers
        else if lowercaseMerchant.contains("venmo") || lowercaseMerchant.contains("paypal") ||
                lowercaseMerchant.contains("cash app") || lowercaseMerchant.contains("zelle") ||
                lowercaseMerchant.contains("transfer") {
            return "Transfers"
        }
        
        // Fees & Charges
        else if type == .fee || lowercaseMerchant.contains("fee") || 
                lowercaseMerchant.contains("charge") || lowercaseMerchant.contains("atm") {
            return "Fees"
        }
        
        // Interest
        else if type == .interest || lowercaseMerchant.contains("interest") {
            return "Interest"
        }
        
        return "Other"
    }
    
    private func applyCorrectionLearning(to transactions: [ParsedTransaction]) async -> [ParsedTransaction] {
        // Apply learned patterns from user corrections
        // In a real implementation, this would use more sophisticated ML
        
        let userCorrections = await correctionStore.getAll()
        
        return transactions.map { transaction in
            // Check if we have corrections for similar transactions
            for correction in userCorrections {
                if transaction.rawText.lowercased().contains(correction.originalText.lowercased()) {
                    // Apply correction learning
                    var updatedTransaction = transaction
                    
                    if let correctedDate = correction.correctedDate {
                        updatedTransaction = ParsedTransaction(
                            date: correctedDate,
                            merchant: transaction.merchant,
                            amount: transaction.amount,
                            confidence: TransactionConfidence(
                                date: 0.95, // High confidence from user correction
                                merchant: transaction.confidence.merchant,
                                amount: transaction.confidence.amount
                            ),
                            rawText: transaction.rawText,
                            lineNumber: transaction.lineNumber,
                            category: transaction.category,
                            transactionType: transaction.transactionType
                        )
                    }
                    
                    return updatedTransaction
                }
            }
            
            return transaction
        }
    }
}