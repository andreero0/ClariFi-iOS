//
//  StatementUploadFlowTests.swift
//  ClariFi iOS Tests
//
//  Created by aEro on 2025-10-10.
//

import Testing
import UIKit
import UniformTypeIdentifiers
@testable import ClariFi_iOS

/// Tests for the complete statement upload flow including document selection,
/// processing, transaction review, and error handling
struct StatementUploadFlowTests {
    
    var viewModel: StatementUploadViewModel!
    var mockOCRService: MockOCRService!
    var mockParserService: MockTransactionParserService!
    var mockRepository: MockTransactionRepository!
    
    init() throws {
        
        
        mockOCRService = MockOCRService()
        mockParserService = MockTransactionParserService()
        mockRepository = MockTransactionRepository()
        
        viewModel = StatementUploadViewModel(
            ocrService: mockOCRService,
            parserService: mockParserService,
            transactionRepository: mockRepository
        )
    }
    
    
    // MARK: - Document Selection Tests
    
    func testShowDocumentPicker_UpdatesState() {
        // When
        viewModel.showDocumentPicker()
        
        // Then
        #expect(viewModel.showingDocumentPicker == true)
        #expect(viewModel.showingCamera == false)
        #expect(viewModel.showingPhotoLibrary == false)
    }
    
    func testShowCamera_UpdatesState() {
        // When
        viewModel.showCamera()
        
        // Then
        #expect(viewModel.showingCamera == true)
        #expect(viewModel.showingDocumentPicker == false)
        #expect(viewModel.showingPhotoLibrary == false)
    }
    
    func testShowPhotoLibrary_UpdatesState() {
        // When
        viewModel.showPhotoLibrary()
        
        // Then
        #expect(viewModel.showingPhotoLibrary == true)
        #expect(viewModel.showingDocumentPicker == false)
        #expect(viewModel.showingCamera == false)
    }
    
    // MARK: - Document Processing Flow Tests
    
    func testProcessDocument_ValidPDF_Success() async {
        // Given
        let pdfData = createTestPDFData()
        mockOCRService.mockResult = createMockOCRResult()
        mockParserService.mockTransactions = createMockParsedTransactions()
        
        // When
        await viewModel.processDocument(pdfData, filename: "test.pdf", contentType: .pdf)
        
        // Wait for processing to complete
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Then
        #expect(viewModel.isProcessing == false)
        #expect(viewModel.parsedTransactions.count == 3)
        #expect(viewModel.error == nil)
        #expect(mockOCRService.processDocumentCalled == true)
        #expect(mockParserService.parseTransactionsCalled == true)
    }
    
    func testProcessDocument_ValidImage_Success() async {
        // Given
        let imageData = createTestImageData()
        mockOCRService.mockResult = createMockOCRResult()
        mockParserService.mockTransactions = createMockParsedTransactions()
        
        // When
        await viewModel.processDocument(imageData, filename: "test.jpg", contentType: .jpeg)
        
        // Wait for processing to complete
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Then
        #expect(viewModel.isProcessing == false)
        #expect(viewModel.parsedTransactions.count == 3)
        #expect(viewModel.error == nil)
    }
    
    func testProcessDocument_DuplicateStatement_ShowsError() async {
        // Given
        let pdfData = createTestPDFData()
        mockOCRService.mockResult = createMockOCRResult()
        mockParserService.mockTransactions = createMockParsedTransactions()
        
        // Process once
        await viewModel.processDocument(pdfData, filename: "test.pdf", contentType: .pdf)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Reset state
        await MainActor.run {
            viewModel.resetUpload()
        }
        
        // When - Process same document again
        await viewModel.processDocument(pdfData, filename: "test.pdf", contentType: .pdf)
        
        // Then
        #expect(viewModel.error != nil)
        if let error = viewModel.error as? UploadError {
            #expect(error == .duplicateStatement)
        } else {
            Issue.record("Expected UploadError.duplicateStatement")
        }
    }
    
    func testProcessDocument_InvalidFile_ShowsError() async {
        // Given
        let invalidData = "Not a valid file".data(using: .utf8)!
        
        // When
        await viewModel.processDocument(invalidData, filename: "invalid.txt", contentType: .plainText)
        
        // Then
        #expect(viewModel.error != nil)
        if let error = viewModel.error as? UploadError {
            #expect(error == .invalidFile)
        }
    }
    
    func testProcessDocument_FileTooLarge_ShowsError() async {
        // Given - Create data larger than 50MB
        let largeData = Data(count: 51 * 1024 * 1024)
        
        // When
        await viewModel.processDocument(largeData, filename: "large.pdf", contentType: .pdf)
        
        // Then
        #expect(viewModel.error != nil)
        if let error = viewModel.error as? UploadError {
            #expect(error == .invalidFile)
        }
    }
    
    func testProcessDocument_OCRFailure_ShowsError() async {
        // Given
        let pdfData = createTestPDFData()
        mockOCRService.shouldFail = true
        mockOCRService.mockError = OCRError.processingFailed("Test failure")
        
        // When
        await viewModel.processDocument(pdfData, filename: "test.pdf", contentType: .pdf)
        
        // Wait for processing
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Then
        #expect(viewModel.error != nil)
        #expect(viewModel.isProcessing == false)
        #expect(viewModel.parsedTransactions.isEmpty == true)
    }
    
    func testProcessDocument_ParsingFailure_ShowsError() async {
        // Given
        let pdfData = createTestPDFData()
        mockOCRService.mockResult = createMockOCRResult()
        mockParserService.shouldFail = true
        mockParserService.mockError = ParsingError.noTransactionsFound
        
        // When
        await viewModel.processDocument(pdfData, filename: "test.pdf", contentType: .pdf)
        
        // Wait for processing
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Then
        #expect(viewModel.error != nil)
        #expect(viewModel.isProcessing == false)
    }
    
    // MARK: - Processing Progress Tests
    
    func testProcessDocument_UpdatesProgress() async {
        // Given
        let pdfData = createTestPDFData()
        mockOCRService.mockResult = createMockOCRResult()
        mockParserService.mockTransactions = createMockParsedTransactions()
        
        var progressValues: [Float] = []
        var statusValues: [String] = []
        
        // When
        let task = Task {
            await viewModel.processDocument(pdfData, filename: "test.pdf", contentType: .pdf)
        }
        
        // Monitor progress
        for _ in 0..<10 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await MainActor.run {
                progressValues.append(viewModel.progress)
                statusValues.append(viewModel.processingStatus)
            }
        }
        
        await task.value
        
        // Then
        #expect(progressValues.contains { $0 > 0 } == true)
        #expect(statusValues.filter { !$0.isEmpty }.isEmpty == false)
    }
    
    func testCancelProcessing_StopsProcessing() async {
        // Given
        let pdfData = createTestPDFData()
        mockOCRService.mockResult = createMockOCRResult()
        mockOCRService.processingDelay = 2.0 // Long delay
        mockParserService.mockTransactions = createMockParsedTransactions()
        
        // When
        Task {
            await viewModel.processDocument(pdfData, filename: "test.pdf", contentType: .pdf)
        }
        
        // Wait a bit then cancel
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        await MainActor.run {
            viewModel.cancelProcessing()
        }
        
        // Wait for cancellation to take effect
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Then
        await MainActor.run {
            #expect(viewModel.isProcessing == false)
            #expect(viewModel.progress == 0.0)
            #expect(viewModel.processingStatus.isEmpty == true)
        }
    }
    
    // MARK: - Image Processing Tests
    
    func testProcessImage_ValidImage_Success() async {
        // Given
        let testImage = createTestUIImage()
        mockOCRService.mockResult = createMockOCRResult()
        mockParserService.mockTransactions = createMockParsedTransactions()
        
        // When
        await viewModel.processImage(testImage)
        
        // Wait for processing
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Then
        #expect(viewModel.isProcessing == false)
        #expect(viewModel.parsedTransactions.count == 3)
        #expect(viewModel.error == nil)
    }
    
    func testProcessImage_InvalidImage_ShowsError() async {
        // Given - Create an image that can't be converted to JPEG
        let testImage = UIImage()
        
        // When
        await viewModel.processImage(testImage)
        
        // Then
        #expect(viewModel.error != nil)
    }
    
    // MARK: - Transaction Confirmation Tests
    
    func testConfirmTransactions_SavesSuccessfully() async {
        // Given
        await MainActor.run {
            viewModel.parsedTransactions = createMockParsedTransactions()
        }
        mockRepository.shouldSucceed = true
        
        // When
        await viewModel.confirmTransactions()
        
        // Then
        await MainActor.run {
            #expect(viewModel.parsedTransactions.isEmpty == true)
            #expect(viewModel.error == nil)
        }
        #expect(mockRepository.batchSaveCalled == true)
        #expect(mockRepository.savedTransactions.count == 3)
    }
    
    func testConfirmTransactions_SaveFailure_ShowsError() async {
        // Given
        await MainActor.run {
            viewModel.parsedTransactions = createMockParsedTransactions()
        }
        mockRepository.shouldSucceed = false
        mockRepository.mockError = NSError(domain: "TestError", code: 1)
        
        // When
        await viewModel.confirmTransactions()
        
        // Then
        await MainActor.run {
            #expect(viewModel.error != nil)
            #expect(viewModel.parsedTransactions.isEmpty == false)
        }
    }
    
    // MARK: - Reset and Clear Tests
    
    func testResetUpload_ClearsState() async {
        // Given
        await MainActor.run {
            viewModel.parsedTransactions = createMockParsedTransactions()
            viewModel.isProcessing = true
            viewModel.progress = 0.5
        }
        
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
    
    func testClearError_RemovesError() async {
        // Given
        await MainActor.run {
            viewModel.error = UploadError.invalidFile
        }
        
        // When
        await MainActor.run {
            viewModel.clearError()
        }
        
        // Then
        await MainActor.run {
            #expect(viewModel.error == nil)
        }
    }
    
    // MARK: - Statement Format Detection Tests
    
    func testProcessDocument_DetectsStatementFormat() async {
        // Given
        let pdfData = createTestPDFData()
        mockOCRService.mockResult = OCRResult(
            rawText: "BANK OF AMERICA Statement\n01/15/2024 STARBUCKS $4.50",
            confidence: 0.9,
            boundingBoxes: [],
            processingTime: 0.5,
            preprocessingApplied: []
        )
        mockParserService.mockTransactions = createMockParsedTransactions()
        
        // When
        await viewModel.processDocument(pdfData, filename: "test.pdf", contentType: .pdf)
        
        // Wait for processing
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Then
        #expect(mockParserService.parseTransactionsCalled == true)
        #expect(mockParserService.lastFormat == .bankOfAmerica)
    }
    
    // MARK: - Helper Methods
    
    private func createTestPDFData() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "ClariFi Test",
            kCGPDFContextAuthor: "Test Suite"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let text = """
            BANK STATEMENT
            01/15/2024 STARBUCKS $4.50
            01/16/2024 SHELL GAS $35.00
            01/17/2024 GROCERY MART $67.89
            """
            
            let font = UIFont.systemFont(ofSize: 12)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black
            ]
            
            let textRect = CGRect(x: 50, y: 50, width: pageRect.width - 100, height: pageRect.height - 100)
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    private func createTestImageData() -> Data {
        let image = createTestUIImage()
        return image.jpegData(compressionQuality: 0.8)!
    }
    
    private func createTestUIImage() -> UIImage {
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
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
    }
    
    private func createMockOCRResult() -> OCRResult {
        return OCRResult(
            rawText: """
            01/15/2024 STARBUCKS STORE #1234 $4.50
            01/16/2024 SHELL GAS STATION $35.00
            01/17/2024 GROCERY MART $67.89
            """,
            confidence: 0.9,
            boundingBoxes: [],
            processingTime: 0.5,
            preprocessingApplied: [.contrastAdjustment]
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

// MARK: - Mock Services

class MockOCRService: OCRService {
    var processDocumentCalled = false
    var processImageCalled = false
    var shouldFail = false
    var mockError: Error?
    var mockResult: OCRResult?
    var processingDelay: TimeInterval = 0.1
    
    func processDocument(_ data: Data, type: DocumentType) async throws -> OCRResult {
        processDocumentCalled = true
        
        try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
        
        if shouldFail {
            throw mockError ?? OCRError.processingFailed("Mock failure")
        }
        
        return mockResult ?? OCRResult(
            rawText: "Mock OCR text",
            confidence: 0.8,
            boundingBoxes: [],
            processingTime: processingDelay,
            preprocessingApplied: []
        )
    }
    
    func processImage(_ image: UIImage) async throws -> OCRResult {
        processImageCalled = true
        
        try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
        
        if shouldFail {
            throw mockError ?? OCRError.processingFailed("Mock failure")
        }
        
        return mockResult ?? OCRResult(
            rawText: "Mock OCR text",
            confidence: 0.8,
            boundingBoxes: [],
            processingTime: processingDelay,
            preprocessingApplied: []
        )
    }
}

class MockTransactionParserService: TransactionParserService {
    var parseTransactionsCalled = false
    var improveAccuracyCalled = false
    var shouldFail = false
    var mockError: Error?
    var mockTransactions: [ParsedTransaction]?
    var lastFormat: StatementFormat?
    
    func parseTransactions(from text: String, format: StatementFormat) async throws -> [ParsedTransaction] {
        parseTransactionsCalled = true
        lastFormat = format
        
        if shouldFail {
            throw mockError ?? ParsingError.noTransactionsFound
        }
        
        return mockTransactions ?? []
    }
    
    func improveAccuracy(with userCorrections: [TransactionCorrection]) async {
        improveAccuracyCalled = true
    }
}

class MockTransactionRepository: BaseCoreDataRepository<Transaction>, TransactionRepository {
    var batchSaveCalled = false
    var shouldSucceed = true
    var mockError: Error?
    var savedTransactions: [Transaction] = []
    
    init() {
        super.init(context: PersistenceController.shared.container.viewContext, entityName: "Transaction")
    }
    
    override func save(_ transaction: Transaction) async throws {
        if !shouldSucceed {
            throw mockError ?? NSError(domain: "MockError", code: 1)
        }
        savedTransactions.append(transaction)
    }
    
    override func fetchAll() async throws -> [Transaction] {
        return []
    }
    
    func fetchByDateRange(_ start: Date, _ end: Date) async throws -> [Transaction] {
        return []
    }
    
    override func delete(_ transaction: Transaction) async throws {
        if !shouldSucceed {
            throw mockError ?? NSError(domain: "MockError", code: 1)
        }
    }
    
    func batchUpdate(_ transactions: [Transaction]) async throws {
        if !shouldSucceed {
            throw mockError ?? NSError(domain: "MockError", code: 1)
        }
    }
    
    func batchSave(_ transactions: [Transaction]) async throws {
        batchSaveCalled = true
        if !shouldSucceed {
            throw mockError ?? NSError(domain: "MockError", code: 1)
        }
        savedTransactions.append(contentsOf: transactions)
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
