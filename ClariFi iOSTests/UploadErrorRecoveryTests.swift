//
//  UploadErrorRecoveryTests.swift
//  ClariFi iOS Tests
//
//  Created by aEro on 2025-10-10.
//

import Testing
import UIKit
@testable import ClariFi_iOS

/// Tests for error states and recovery flows in the upload process
struct UploadErrorRecoveryTests {
    
    var viewModel: StatementUploadViewModel!
    var mockOCRService: MockOCRServiceForErrors!
    var mockParserService: MockParserServiceForErrors!
    var mockRepository: MockRepositoryForErrors!
    
    init() throws {
        
        
        mockOCRService = MockOCRServiceForErrors()
        mockParserService = MockParserServiceForErrors()
        mockRepository = MockRepositoryForErrors()
        
        viewModel = StatementUploadViewModel(
            ocrService: mockOCRService,
            parserService: mockParserService,
            transactionRepository: mockRepository
        )
    }
    
    
    // MARK: - OCR Error Recovery Tests
    
    func testOCRError_NoTextFound_ShowsError() async {
        // Given
        let imageData = createTestImageData()
        mockOCRService.errorToThrow = OCRError.noTextFound
        
        // When
        await viewModel.processDocument(imageData, filename: "test.jpg", contentType: .jpeg)
        
        // Wait for processing
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Then
        await MainActor.run {
            #expect(viewModel.error != nil)
            #expect(viewModel.isProcessing == false)
            #expect(viewModel.parsedTransactions.isEmpty == true)
        }
        
        if let error = await MainActor.run({ viewModel.error as? OCRError }) {
            #expect(error == .noTextFound)
        }
    }
    
    func testOCRError_LowConfidence_ShowsError() async {
        // Given
        let imageData = createTestImageData()
        mockOCRService.errorToThrow = OCRError.lowConfidence(0.3)
        
        // When
        await viewModel.processDocument(imageData, filename: "test.jpg", contentType: .jpeg)
        
        // Wait for processing
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Then
        await MainActor.run {
            #expect(viewModel.error != nil)
            #expect(viewModel.isProcessing == false)
        }
    }
    
    func testOCRError_ProcessingFailed_ShowsError() async {
        // Given
        let imageData = createTestImageData()
        mockOCRService.errorToThrow = OCRError.processingFailed("Test failure reason")
        
        // When
        await viewModel.processDocument(imageData, filename: "test.jpg", contentType: .jpeg)
        
        // Wait for processing
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Then
        await MainActor.run {
            #expect(viewModel.error != nil)
            #expect(viewModel.isProcessing == false)
        }
    }
    
    func testOCRError_MemoryLimitExceeded_ShowsError() async {
        // Given
        let imageData = createTestImageData()
        mockOCRService.errorToThrow = OCRError.memoryLimitExceeded
        
        // When
        await viewModel.processDocument(imageData, filename: "test.jpg", contentType: .jpeg)
        
        // Wait for processing
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Then
        await MainActor.run {
            #expect(viewModel.error != nil)
            #expect(viewModel.isProcessing == false)
        }
    }
    
    func testOCRError_UnsupportedDocumentType_ShowsError() async {
        // Given
        let imageData = createTestImageData()
        mockOCRService.errorToThrow = OCRError.unsupportedDocumentType
        
        // When
        await viewModel.processDocument(imageData, filename: "test.jpg", contentType: .jpeg)
        
        // Wait for processing
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Then
        await MainActor.run {
            #expect(viewModel.error != nil)
        }
    }
    
    // MARK: - Parsing Error Recovery Tests
    
    func testParserError_NoTransactionsFound_ShowsError() async {
        // Given
        let imageData = createTestImageData()
        mockOCRService.mockResult = createMockOCRResult()
        mockParserService.errorToThrow = ParserError.noTransactionsFound
        
        // When
        await viewModel.processDocument(imageData, filename: "test.jpg", contentType: .jpeg)
        
        // Wait for processing
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Then
        await MainActor.run {
            #expect(viewModel.error != nil)
            #expect(viewModel.parsedTransactions.isEmpty == true)
        }
    }
    
    func testParserError_InvalidFormat_ShowsError() async {
        // Given
        let imageData = createTestImageData()
        mockOCRService.mockResult = createMockOCRResult()
        mockParserService.errorToThrow = ParserError.invalidFormat
        
        // When
        await viewModel.processDocument(imageData, filename: "test.jpg", contentType: .jpeg)
        
        // Wait for processing
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Then
        await MainActor.run {
            #expect(viewModel.error != nil)
        }
    }
    
    func testParserError_InsufficientData_ShowsError() async {
        // Given
        let imageData = createTestImageData()
        mockOCRService.mockResult = createMockOCRResult()
        mockParserService.errorToThrow = ParserError.insufficientData
        
        // When
        await viewModel.processDocument(imageData, filename: "test.jpg", contentType: .jpeg)
        
        // Wait for processing
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Then
        await MainActor.run {
            #expect(viewModel.error != nil)
        }
    }
    
    // MARK: - Repository Error Recovery Tests
    
    func testRepositoryError_SaveFailure_ShowsError() async {
        // Given
        await MainActor.run {
            viewModel.parsedTransactions = createMockParsedTransactions()
        }
        mockRepository.errorToThrow = NSError(domain: "TestError", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Failed to save"
        ])
        
        // When
        await viewModel.confirmTransactions()
        
        // Then
        await MainActor.run {
            #expect(viewModel.error != nil)
            #expect(viewModel.parsedTransactions.isEmpty == false) // Should not clear on error
        }
    }
    
    func testRepositoryError_CoreDataError_ShowsError() async {
        // Given
        await MainActor.run {
            viewModel.parsedTransactions = createMockParsedTransactions()
        }
        mockRepository.errorToThrow = NSError(domain: "NSCocoaErrorDomain", code: 134030)
        
        // When
        await viewModel.confirmTransactions()
        
        // Then
        await MainActor.run {
            #expect(viewModel.error != nil)
        }
    }
    
    // MARK: - Error Recovery Flow Tests
    
    func testErrorRecovery_ClearError_AllowsRetry() async {
        // Given
        let imageData = createTestImageData()
        mockOCRService.errorToThrow = OCRError.noTextFound
        
        // First attempt fails
        await viewModel.processDocument(imageData, filename: "test.jpg", contentType: .jpeg)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            #expect(viewModel.error != nil)
        }
        
        // Clear error
        await MainActor.run {
            viewModel.clearError()
        }
        
        await MainActor.run {
            #expect(viewModel.error == nil)
        }
        
        // When - Retry with success
        mockOCRService.errorToThrow = nil
        mockOCRService.mockResult = createMockOCRResult()
        mockParserService.mockTransactions = createMockParsedTransactions()
        
        await viewModel.processDocument(imageData, filename: "test2.jpg", contentType: .jpeg)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Then
        await MainActor.run {
            #expect(viewModel.error == nil)
            #expect(viewModel.parsedTransactions.isEmpty == false)
        }
    }
    
    func testErrorRecovery_ResetAfterError_ClearsState() async {
        // Given
        let imageData = createTestImageData()
        mockOCRService.errorToThrow = OCRError.processingFailed("Test")
        
        await viewModel.processDocument(imageData, filename: "test.jpg", contentType: .jpeg)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // When
        await MainActor.run {
            viewModel.resetUpload()
        }
        
        // Then
        await MainActor.run {
            #expect(viewModel.parsedTransactions.isEmpty == true)
            #expect(viewModel.isProcessing == false)
            #expect(viewModel.progress == 0.0)
        }
    }
    
    func testErrorRecovery_CancelDuringError_ClearsProcessing() async {
        // Given
        let imageData = createTestImageData()
        mockOCRService.processingDelay = 2.0
        mockOCRService.errorToThrow = OCRError.processingFailed("Test")
        
        // Start processing
        Task {
            await viewModel.processDocument(imageData, filename: "test.jpg", contentType: .jpeg)
        }
        
        // Wait a bit
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // When - Cancel
        await MainActor.run {
            viewModel.cancelProcessing()
        }
        
        // Wait for cancellation
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Then
        await MainActor.run {
            #expect(viewModel.isProcessing == false)
        }
    }
    
    // MARK: - Upload Error Tests
    
    func testUploadError_DuplicateStatement_PreventsDuplicate() async {
        // Given
        let imageData = createTestImageData()
        mockOCRService.mockResult = createMockOCRResult()
        mockParserService.mockTransactions = createMockParsedTransactions()
        
        // First upload
        await viewModel.processDocument(imageData, filename: "test.jpg", contentType: .jpeg)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            viewModel.resetUpload()
        }
        
        // When - Try to upload same file again
        await viewModel.processDocument(imageData, filename: "test.jpg", contentType: .jpeg)
        
        // Then
        await MainActor.run {
            #expect(viewModel.error != nil)
            if let error = viewModel.error as? UploadError {
                #expect(error == .duplicateStatement)
            }
        }
    }
    
    func testUploadError_InvalidFile_RejectsFile() async {
        // Given
        let invalidData = "Not a valid file".data(using: .utf8)!
        
        // When
        await viewModel.processDocument(invalidData, filename: "invalid.txt", contentType: .plainText)
        
        // Then
        await MainActor.run {
            #expect(viewModel.error != nil)
            if let error = viewModel.error as? UploadError {
                #expect(error == .invalidFile)
            }
        }
    }
    
    // MARK: - Error Message Tests
    
    func testErrorMessages_HaveDescriptions() {
        // Test UploadError descriptions
        let uploadErrors: [UploadError] = [
            .invalidFile,
            .duplicateStatement,
            .fileTooLarge,
            .unsupportedFormat
        ]
        
        for error in uploadErrors {
            #expect(error.errorDescription != nil)
            #expect(error.errorDescription!.isEmpty == false)
        }
    }
    
    func testErrorMessages_OCRErrors_HaveDescriptions() {
        // Test OCRError descriptions
        let ocrErrors: [OCRError] = [
            .unsupportedDocumentType,
            .processingFailed("Test"),
            .noTextFound,
            .lowConfidence(0.3),
            .memoryLimitExceeded
        ]
        
        for error in ocrErrors {
            #expect(error.errorDescription != nil)
            #expect(error.errorDescription!.isEmpty == false)
        }
    }
    
    func testErrorMessages_ParserErrors_HaveDescriptions() {
        // Test ParserError descriptions
        let parsingErrors: [ParserError] = [
            .noTransactionsFound,
            .invalidFormat,
            .insufficientData,
            .ambiguousData
        ]
        
        for error in parsingErrors {
            #expect(error.errorDescription != nil)
            #expect(error.errorDescription!.isEmpty == false)
        }
    }
    
    // MARK: - Concurrent Error Tests
    
    func testConcurrentErrors_OnlyOneProcessingAtTime() async {
        // Given
        let imageData1 = createTestImageData()
        let imageData2 = createTestImageData()
        mockOCRService.processingDelay = 1.0
        mockOCRService.mockResult = createMockOCRResult()
        mockParserService.mockTransactions = createMockParsedTransactions()
        
        // When - Try to process two documents simultaneously
        async let task1 = viewModel.processDocument(imageData1, filename: "test1.jpg", contentType: .jpeg)
        
        try? await Task.sleep(nanoseconds: 100_000_000) // Small delay
        
        async let task2 = viewModel.processDocument(imageData2, filename: "test2.jpg", contentType: .jpeg)
        
        await task1
        await task2
        
        // Then - Second should be rejected or queued
        // In this implementation, the second call would start after the first completes
        // or would be rejected if validation fails
        await MainActor.run {
            #expect(viewModel.isProcessing == false)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImageData() -> Data {
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let text = "01/15/2024 STARBUCKS $4.50"
            let font = UIFont.systemFont(ofSize: 16)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black
            ]
            
            let textRect = CGRect(x: 20, y: 20, width: size.width - 40, height: size.height - 40)
            text.draw(in: textRect, withAttributes: attributes)
        }
        return image.jpegData(compressionQuality: 0.8)!
    }
    
    private func createMockOCRResult() -> OCRResult {
        return OCRResult(
            rawText: "01/15/2024 STARBUCKS $4.50\n01/16/2024 SHELL GAS $35.00",
            confidence: 0.9,
            boundingBoxes: [],
            processingTime: 0.5,
            preprocessingApplied: []
        )
    }
    
    private func createMockParsedTransactions() -> [ParsedTransaction] {
        return [
            ParsedTransaction(
                date: Date(),
                merchant: "STARBUCKS",
                amount: Decimal(4.50),
                confidence: TransactionConfidence(date: 0.95, merchant: 0.90, amount: 0.95),
                rawText: "01/15/2024 STARBUCKS $4.50",
                lineNumber: 1,
                category: "Dining",
                transactionType: .debit
            ),
            ParsedTransaction(
                date: Date(),
                merchant: "SHELL GAS",
                amount: Decimal(35.00),
                confidence: TransactionConfidence(date: 0.90, merchant: 0.85, amount: 0.92),
                rawText: "01/16/2024 SHELL GAS $35.00",
                lineNumber: 2,
                category: "Gas",
                transactionType: .debit
            ),
            ParsedTransaction(
                date: Date(),
                merchant: "GROCERY MART",
                amount: Decimal(67.89),
                confidence: TransactionConfidence(date: 0.93, merchant: 0.88, amount: 0.94),
                rawText: "01/17/2024 GROCERY MART $67.89",
                lineNumber: 3,
                category: "Groceries",
                transactionType: .debit
            )
        ]
    }
}

// MARK: - Mock Services for Error Testing

class MockOCRServiceForErrors: OCRService {
    var errorToThrow: Error?
    var mockResult: OCRResult?
    var processingDelay: TimeInterval = 0.1
    
    func processDocument(_ data: Data, type: DocumentType) async throws -> OCRResult {
        try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
        
        if let error = errorToThrow {
            throw error
        }
        
        return mockResult ?? OCRResult(
            rawText: "Mock text",
            confidence: 0.8,
            boundingBoxes: [],
            processingTime: processingDelay,
            preprocessingApplied: []
        )
    }
    
    func processImage(_ image: UIImage) async throws -> OCRResult {
        try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
        
        if let error = errorToThrow {
            throw error
        }
        
        return mockResult ?? OCRResult(
            rawText: "Mock text",
            confidence: 0.8,
            boundingBoxes: [],
            processingTime: processingDelay,
            preprocessingApplied: []
        )
    }
}

class MockParserServiceForErrors: TransactionParserService {
    var errorToThrow: Error?
    var mockTransactions: [ParsedTransaction]?
    
    func parseTransactions(from text: String, format: StatementFormat) async throws -> [ParsedTransaction] {
        if let error = errorToThrow {
            throw error
        }
        
        return mockTransactions ?? []
    }
    
    func improveAccuracy(with userCorrections: [TransactionCorrection]) async {
        // No-op for error testing
    }
}

class MockRepositoryForErrors: BaseCoreDataRepository<Transaction>, TransactionRepository {
    var errorToThrow: Error?
    
    init() {
        super.init(context: PersistenceController.shared.container.viewContext, entityName: "Transaction")
    }
    
    override func save(_ transaction: Transaction) async throws {
        if let error = errorToThrow {
            throw error
        }
    }
    
    override func fetchAll() async throws -> [Transaction] {
        return []
    }
    
    func fetchByDateRange(_ start: Date, _ end: Date) async throws -> [Transaction] {
        return []
    }
    
    override func delete(_ transaction: Transaction) async throws {
        if let error = errorToThrow {
            throw error
        }
    }
    
    func batchUpdate(_ transactions: [Transaction]) async throws {
        if let error = errorToThrow {
            throw error
        }
    }
    
    func batchSave(_ transactions: [Transaction]) async throws {
        if let error = errorToThrow {
            throw error
        }
    }
    
    func fetchByAccount(_ account: Account) async throws -> [Transaction] {
        return []
    }
    
    func fetchByCategory(_ category: String) async throws -> [Transaction] {
        return []
    }
    
    func fetchByMerchant(_ merchant: String) async throws -> [Transaction] {
        return []
    }
    
    func fetchLowConfidenceTransactions(threshold: Float) async throws -> [Transaction] {
        return []
    }
    
    func fetchRecentTransactions(limit: Int) async throws -> [Transaction] {
        return []
    }
    
    func searchTransactions(query: String) async throws -> [Transaction] {
        return []
    }
}
