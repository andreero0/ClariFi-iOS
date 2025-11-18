import Foundation
import SwiftUI
import UniformTypeIdentifiers
import CryptoKit
import CoreData

@MainActor
class StatementUploadViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var progress: Float = 0.0
    @Published var processingStatus = ""
    @Published var parsedTransactions: [ParsedTransaction] = []
    
    // MARK: - Sheet States
    @Published var showingDocumentPicker = false
    @Published var showingCamera = false
    @Published var showingPhotoLibrary = false
    
    // MARK: - Private Properties
    private let ocrService: OCRService
    private let parserService: TransactionParserService
    private let transactionRepository: any TransactionRepository
    private let accountRepository: any AccountRepository
    private let statementRepository: any StatementRepository
    private let llmService: LLMCategorizationServiceProtocol?
    private let context: NSManagedObjectContext
    private var processingTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(
        ocrService: OCRService,
        parserService: TransactionParserService,
        transactionRepository: any TransactionRepository,
        accountRepository: any AccountRepository,
        statementRepository: any StatementRepository,
        llmService: LLMCategorizationServiceProtocol?,
        context: NSManagedObjectContext
    ) {
        self.ocrService = ocrService
        self.parserService = parserService
        self.transactionRepository = transactionRepository
        self.accountRepository = accountRepository
        self.statementRepository = statementRepository
        self.llmService = llmService
        self.context = context
        
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Checks if a statement with the given hash has already been uploaded
    func checkDuplicate(fileHash: String) async -> Bool {
        let fetchRequest = NSFetchRequest<Statement>(entityName: "Statement")
        fetchRequest.predicate = NSPredicate(format: "uploadHash == %@", fileHash)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try await context.perform {
                try self.context.fetch(fetchRequest)
            }
            return !results.isEmpty
        } catch {
            print("Error checking for duplicate statement: \(error)")
            return false
        }
    }
    
    /// Marks a statement as uploaded by persisting its hash
    func markUploaded(statement: Statement, fileHash: String, source: String) async {
        await context.perform {
            statement.uploadHash = fileHash
            statement.uploadedAt = Date()
            statement.uploadSource = source
            
            do {
                try self.context.save()
            } catch {
                print("Error marking statement as uploaded: \(error)")
            }
        }
    }
    
    func showDocumentPicker() {
        showingDocumentPicker = true
    }
    
    func showCamera() {
        showingCamera = true
    }
    
    func showPhotoLibrary() {
        showingPhotoLibrary = true
    }
    
    func processDocument(_ data: Data, filename: String, contentType: UTType) {
        // Check for duplicates using Core Data
        let fileHash = calculateFileHash(data)
        
        Task {
            let isDuplicate = await checkDuplicate(fileHash: fileHash)
            
            if isDuplicate {
                await MainActor.run {
                    handleError(AppError.validationError(message: "This statement has already been uploaded"), context: [
                        "reason": "duplicate",
                        "file_type": contentType.identifier
                    ])
                    Analytics.track(.statementUploadFailed, properties: [
                        "reason": "duplicate",
                        "file_type": contentType.identifier
                    ])
                }
                return
            }
            
            await continueProcessingDocument(data, filename: filename, fileHash: fileHash, contentType: contentType)
        }
    }
    
    private func continueProcessingDocument(_ data: Data, filename: String, fileHash: String, contentType: UTType) async {
        // Validate file
        guard validateFile(data: data, contentType: contentType) else {
            await MainActor.run {
                handleError(AppError.validationError(message: "The selected file is not valid or corrupted"), context: [
                    "reason": "invalid_file",
                    "file_type": contentType.identifier
                ])
                Analytics.track(.statementUploadFailed, properties: [
                    "reason": "invalid_file",
                    "file_type": contentType.identifier
                ])
            }
            return
        }
        
        let documentType: DocumentType
        if contentType.conforms(to: .pdf) {
            documentType = .pdf
        } else if contentType.conforms(to: .jpeg) {
            documentType = .image(.jpeg)
        } else if contentType.conforms(to: .png) {
            documentType = .image(.png)
        } else if contentType.conforms(to: .heic) {
            documentType = .image(.heic)
        } else {
            documentType = .image(.jpeg) // Default fallback
        }
        
        await MainActor.run {
            Analytics.track(.statementUploadStarted, properties: [
                "file_type": contentType.identifier,
                "document_type": String(describing: documentType),
                "file_size": data.count
            ])
        }
        
        await MainActor.run {
            startProcessing(data: data, filename: filename, fileHash: fileHash, documentType: documentType, uploadSource: "document")
        }
    }
    
    func processImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            handleError(AppError.validationError(message: "Failed to convert image"), context: [
                "reason": "image_conversion_failed",
                "source": "camera"
            ])
            Analytics.track(.statementUploadFailed, properties: [
                "reason": "image_conversion_failed",
                "source": "camera"
            ])
            return
        }
        
        let fileHash = calculateFileHash(data)
        
        Task {
            let isDuplicate = await checkDuplicate(fileHash: fileHash)
            
            if isDuplicate {
                await MainActor.run {
                    handleError(AppError.validationError(message: "This statement has already been uploaded"), context: [
                        "reason": "duplicate",
                        "source": "camera"
                    ])
                    Analytics.track(.statementUploadFailed, properties: [
                        "reason": "duplicate",
                        "source": "camera"
                    ])
                }
                return
            }
            
            await MainActor.run {
                Analytics.track(.statementUploadStarted, properties: [
                    "source": "camera",
                    "file_size": data.count
                ])
                
                startProcessing(data: data, filename: "camera_image.jpg", fileHash: fileHash, documentType: .image(.jpeg), uploadSource: "camera")
            }
        }
    }
    
    func cancelProcessing() {
        processingTask?.cancel()
        Analytics.track(.statementUploadCancelled, properties: [
            "progress": progress
        ])
        resetProcessingState()
    }
    
    func confirmTransactions() {
        Task {
            do {
                // Get or create default account
                let account = try await accountRepository.getOrCreateDefaultAccount()
                
                // Create transactions from parsed data
                var transactions: [Transaction] = []
                for parsedTransaction in parsedTransactions {
                    let transaction = Transaction(context: context)
                    transaction.id = UUID()
                    transaction.date = parsedTransaction.date
                    transaction.merchant = parsedTransaction.merchant
                    transaction.amount = NSDecimalNumber(decimal: parsedTransaction.amount ?? 0)
                    transaction.currency = "USD" // Default currency
                    transaction.category = parsedTransaction.category
                    transaction.confidence = parsedTransaction.confidence.overall
                    transaction.isManual = false
                    transaction.notes = nil // ParsedTransaction doesn't have notes
                    transaction.account = account
                    transaction.statement = nil
                    transaction.createdAt = Date()
                    transaction.updatedAt = Date()
                    transactions.append(transaction)
                }
                
                // Save all transactions
                for transaction in transactions {
                    try await transactionRepository.save(transaction)
                }
                
                // Mark statement as uploaded
                // In a real implementation, you'd save the statement record
                
                // Reset state
                resetUpload()
                
            } catch {
                handleError(error, context: ["operation": "confirm_transactions"])
            }
        }
    }
    
    func resetUpload() {
        parsedTransactions = []
        resetProcessingState()
    }
    
    // MARK: - Private Methods
    
    private func startProcessing(data: Data, filename: String, fileHash: String, documentType: DocumentType, uploadSource: String) {
        // Update UI state on main actor
        Task { @MainActor in
            isProcessing = true
            progress = 0.0
            processingStatus = "Preparing document..."
        }
        
        processingTask = Task {
            do {
                // Create statement record
                let statement = Statement(context: context)
                statement.id = UUID()
                statement.fileName = filename
                statement.uploadDate = Date()
                statement.fileHash = fileHash
                statement.processingStatus = "processing"
                statement.fileSize = Int64(data.count)
                statement.documentType = String(describing: documentType)
                statement.createdAt = Date()
                statement.updatedAt = Date()
                
                // Step 1: OCR Processing
                await updateProgress(0.1, status: "Reading document text...")
                
                let ocrResult = try await ocrService.processDocument(data, type: documentType)
                
                await updateProgress(0.5, status: "Extracting transactions...")
                
                // Step 2: Transaction Parsing
                let statementFormat = detectStatementFormat(from: ocrResult.rawText)
                var transactions = try await parserService.parseTransactions(from: ocrResult.rawText, format: statementFormat)
                
                // Step 3: LLM Enhancement (if available)
                if let llmService = llmService {
                    await updateProgress(0.7, status: "Enhancing with AI...")
                    transactions = await enhanceTransactionsWithLLM(transactions, llmService: llmService)
                }
                
                await updateProgress(0.9, status: "Finalizing results...")
                
                // Mark statement as uploaded with hash
                await markUploaded(statement: statement, fileHash: fileHash, source: uploadSource)
                
                // Update statement status
                await context.perform {
                    statement.processingStatus = "completed"
                    statement.updatedAt = Date()
                    try? self.context.save()
                }
                
                // Step 4: Finalize
                await MainActor.run {
                    self.parsedTransactions = transactions
                    self.progress = 1.0
                    self.processingStatus = "Complete!"
                    
                    Analytics.track(.statementUploadCompleted, properties: [
                        "transaction_count": transactions.count,
                        "low_confidence_count": transactions.filter { $0.confidence.overall < 0.7 }.count,
                        "processing_time": ocrResult.processingTime,
                        "upload_source": uploadSource
                    ])
                    
                    // Brief delay to show completion
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.isProcessing = false
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.handleError(error, context: ["component": "statement_upload"])
                    Analytics.track(.statementUploadFailed, properties: [
                        "error": error.localizedDescription
                    ])
                    self.resetProcessingState()
                }
            }
        }
    }
    
    private func updateProgress(_ newProgress: Float, status: String) async {
        await MainActor.run {
            self.progress = newProgress
            self.processingStatus = status
        }
    }
    
    private func resetProcessingState() {
        Task { @MainActor in
            isProcessing = false
            progress = 0.0
            processingStatus = ""
        }
        processingTask = nil
    }
    
    private func validateFile(data: Data, contentType: UTType) -> Bool {
        // Check file size (max 50MB)
        let maxSize = 50 * 1024 * 1024
        guard data.count <= maxSize else { return false }
        
        // Check content type
        let allowedTypes: [UTType] = [.pdf, .jpeg, .png, .heic]
        return allowedTypes.contains { contentType.conforms(to: $0) }
    }
    
    private func calculateFileHash(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func detectStatementFormat(from text: String) -> StatementFormat {
        let lowercaseText = text.lowercased()
        
        // Traditional Banks
        if lowercaseText.contains("bank of america") || lowercaseText.contains("bofa") {
            return .bankOfAmerica
        } else if lowercaseText.contains("jpmorgan chase") || lowercaseText.contains("chase bank") {
            return .chase
        } else if lowercaseText.contains("wells fargo") {
            return .wellsFargo
        } else if lowercaseText.contains("capital one") {
            return .capitalOne
        } else if lowercaseText.contains("citibank") || lowercaseText.contains("citi card") {
            return .citi
        } else if lowercaseText.contains("u.s. bank") || lowercaseText.contains("us bank") {
            return .usBank
        } else if lowercaseText.contains("pnc bank") || lowercaseText.contains("pnc financial") {
            return .pncBank
        } else if lowercaseText.contains("td bank") {
            return .tdBank
        } else if lowercaseText.contains("usaa") {
            return .usaa
        } else if lowercaseText.contains("navy federal") {
            return .navyFederal
        }
        
        // Credit Cards
        else if lowercaseText.contains("discover") {
            return .discover
        } else if lowercaseText.contains("american express") || lowercaseText.contains("amex") {
            return .americanExpress
        }
        
        // Investment & Brokerage
        else if lowercaseText.contains("charles schwab") || lowercaseText.contains("schwab") {
            return .schwab
        } else if lowercaseText.contains("fidelity") {
            return .fidelity
        }
        
        // Digital Payment Platforms
        else if lowercaseText.contains("venmo") {
            return .venmo
        } else if lowercaseText.contains("paypal") {
            return .paypal
        } else if lowercaseText.contains("cash app") || lowercaseText.contains("cashapp") {
            return .cashApp
        } else if lowercaseText.contains("zelle") {
            return .zelle
        }
        
        // Canadian Banks
        else if lowercaseText.contains("royal bank") || lowercaseText.contains("rbc") || lowercaseText.contains("banque royale") {
            return .rbc
        } else if lowercaseText.contains("td canada") || lowercaseText.contains("td trust") {
            return .tdCanada
        } else if lowercaseText.contains("scotiabank") || lowercaseText.contains("banque scotia") {
            return .scotiabank
        } else if lowercaseText.contains("bank of montreal") || lowercaseText.contains("bmo") || lowercaseText.contains("banque de montréal") {
            return .bmo
        } else if lowercaseText.contains("cibc") || lowercaseText.contains("canadian imperial") {
            return .cibc
        } else if lowercaseText.contains("tangerine") {
            return .tangerine
        } else if lowercaseText.contains("desjardins") {
            return .desjardins
        }
        
        // Generic fallback
        else {
            return .generic
        }
    }
    
    // MARK: - LLM Enhancement
    
    /// Enhances parsed transactions using LLM for better merchant normalization and categorization
    private func enhanceTransactionsWithLLM(
        _ transactions: [ParsedTransaction],
        llmService: LLMCategorizationServiceProtocol
    ) async -> [ParsedTransaction] {
        var enhancedTransactions: [ParsedTransaction] = []
        var llmFailureCount = 0
        var fallbackCount = 0
        
        for transaction in transactions {
            var enhanced = transaction  // Create mutable copy

            do {
                // Normalize merchant name using LLM
                if let merchant = transaction.merchant, !merchant.isEmpty {
                    let normalizedMerchant = try await llmService.normalizeMerchantName(merchant)
                    enhanced.merchant = normalizedMerchant
                }

                // Enhance categorization using LLM
                if let amount = transaction.amount, let merchant = enhanced.merchant {
                    let llmResult = try await llmService.categorizeWithLLM(
                        merchant: merchant,
                        amount: amount,
                        context: nil
                    )

                    // Update category with LLM result
                    enhanced.category = llmResult.category

                    // Update confidence if LLM was successful
                    if llmResult.method == .llm {
                        enhanced.confidence = TransactionConfidence(
                            date: transaction.confidence.date,
                            merchant: 0.95,  // High confidence for LLM-enhanced merchant
                            amount: transaction.confidence.amount
                        )
                    } else {
                        fallbackCount += 1
                    }
                }

                // Append enhanced transaction
                enhancedTransactions.append(enhanced)
                
            } catch let error as LLMError {
                // If LLM enhancement fails, use original transaction
                llmFailureCount += 1
                print("LLM enhancement failed: \(error.errorDescription ?? "Unknown error")")
                if let suggestion = error.recoverySuggestion {
                    print("   \(suggestion)")
                }
                enhancedTransactions.append(transaction)
                
            } catch {
                // Unexpected error
                llmFailureCount += 1
                print("Unexpected error during LLM enhancement: \(error.localizedDescription)")
                enhancedTransactions.append(transaction)
            }
        }
        
        // Log summary
        if llmFailureCount > 0 {
            print("ℹ️ LLM Enhancement Summary:")
            print("   - Total transactions: \(transactions.count)")
            print("   - LLM failures: \(llmFailureCount)")
            print("   - Fallback used: \(fallbackCount)")
            print("   - Successfully enhanced: \(transactions.count - llmFailureCount)")
        }
        
        return enhancedTransactions
    }
}
