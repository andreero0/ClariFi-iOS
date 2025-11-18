//
//  StatementUploadViewModelTests.swift
//  ClariFi_iOS Tests
//
//  Unit tests for StatementUploadViewModel using DI container and mocks
//

import XCTest
import CoreData
import UniformTypeIdentifiers
@testable import ClariFi_iOS

@MainActor
final class StatementUploadViewModelTests: XCTestCase {
    
    var container: DIContainer!
    var viewModel: StatementUploadViewModel!
    var mockOCRService: MockOCRService!
    var mockParserService: MockTransactionParserService!
    var mockTransactionRepository: MockTransactionRepository!
    var mockAccountRepository: MockAccountRepository!
    var mockStatementRepository: MockStatementRepository!
    var context: NSManagedObjectContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory Core Data context
        let persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
        
        // Create mock services and repositories
        mockOCRService = MockOCRService()
        mockParserService = MockTransactionParserService()
        mockTransactionRepository = MockTransactionRepository()
        mockAccountRepository = MockAccountRepository()
        mockStatementRepository = MockStatementRepository()
        
        // Create test container with mocks
        container = AppDIContainer()
        container.registerSingleton(OCRService.self) { _ in
            self.mockOCRService
        }
        container.registerSingleton(TransactionParserService.self) { _ in
            self.mockParserService
        }
        container.registerSingleton(TransactionRepository.self) { _ in
            self.mockTransactionRepository
        }
        container.registerSingleton(AccountRepository.self) { _ in
            self.mockAccountRepository
        }
        container.registerSingleton(StatementRepository.self) { _ in
            self.mockStatementRepository
        }
        
        // Create ViewModel with injected dependencies
        viewModel = StatementUploadViewModel(
            ocrService: mockOCRService,
            parserService: mockParserService,
            transactionRepository: mockTransactionRepository,
            accountRepository: mockAccountRepository,
            statementRepository: mockStatementRepository,
            context: context
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockOCRService = nil
        mockParserService = nil
        mockTransactionRepository = nil
        mockAccountRepository = nil
        mockStatementRepository = nil
        container = nil
        context = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertEqual(viewModel.progress, 0.0)
        XCTAssertTrue(viewModel.processingStatus.isEmpty)
        XCTAssertTrue(viewModel.parsedTransactions.isEmpty)
        XCTAssertFalse(viewModel.showingDocumentPicker)
        XCTAssertFalse(viewModel.showingCamera)
        XCTAssertFalse(viewModel.showingPhotoLibrary)
    }
    
    // MARK: - Show Picker Tests
    
    func testShowDocumentPicker() {
        // Act
        viewModel.showDocumentPicker()
        
        // Assert
        XCTAssertTrue(viewModel.showingDocumentPicker)
    }
    
    func testShowCamera() {
        // Act
        viewModel.showCamera()
        
        // Assert
        XCTAssertTrue(viewModel.showingCamera)
    }
    
    func testShowPhotoLibrary() {
        // Act
        viewModel.showPhotoLibrary()
        
        // Assert
        XCTAssertTrue(viewModel.showingPhotoLibrary)
    }
    
    // MARK: - Process Document Tests
    
    func testProcessDocumentSuccess() async {
        // Arrange
        let testData = "Test PDF Content".data(using: .utf8)!
        let filename = "test_statement.pdf"
        let contentType = UTType.pdf
        
        // Mock OCR result
        mockOCRService.mockResult = OCRResult(
            rawText: "Bank of America\nTransaction 1: $100\nTransaction 2: $50",
            confidence: 0.95,
            processingTime: 1.5,
            detectedFormat: .bankOfAmerica
        )
        
        // Mock parsed transactions
        let parsedTransaction = ParsedTransaction(
            date: Date(),
            merchant: "Test Merchant",
            amount: 100.0,
            category: "Food",
            confidence: ConfidenceScore(overall: 0.9, merchant: 0.95, amount: 0.95, date: 0.85)
        )
        mockParserService.mockTransactions = [parsedTransaction]
        
        // Act
        viewModel.processDocument(testData, filename: filename, contentType: contentType)
        
        // Wait for async processing
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Assert
        XCTAssertTrue(mockOCRService.processDocumentCalled)
        XCTAssertTrue(mockParserService.parseTransactionsCalled)
        XCTAssertEqual(viewModel.parsedTransactions.count, 1)
        XCTAssertEqual(viewModel.parsedTransactions.first?.merchant, "Test Merchant")
    }
    
    func testProcessDocumentDuplicate() {
        // Arrange
        let testData = "Test PDF Content".data(using: .utf8)!
        let filename = "test_statement.pdf"
        let contentType = UTType.pdf
        
        // Process once to add to uploaded statements
        viewModel.processDocument(testData, filename: filename, contentType: contentType)
        
        // Wait briefly
        try? Thread.sleep(forTimeInterval: 0.1)
        
        // Reset error
        viewModel.error = nil
        
        // Act - Process same document again
        viewModel.processDocument(testData, filename: filename, contentType: contentType)
        
        // Assert
        XCTAssertNotNil(viewModel.error)
        // The error should indicate duplicate
    }
    
    func testProcessDocumentInvalidFile() {
        // Arrange
        let testData = Data() // Empty data
        let filename = "test.pdf"
        let contentType = UTType.pdf
        
        // Act
        viewModel.processDocument(testData, filename: filename, contentType: contentType)
        
        // Assert
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(mockOCRService.processDocumentCalled)
    }
    
    // MARK: - Confirm Transactions Tests
    
    func testConfirmTransactionsSuccess() async {
        // Arrange
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Test Account"
        account.isActive = true
        mockAccountRepository.mockDefaultAccount = account
        
        let parsedTransaction = ParsedTransaction(
            date: Date(),
            merchant: "Test Merchant",
            amount: 100.0,
            category: "Food",
            confidence: ConfidenceScore(overall: 0.9, merchant: 0.95, amount: 0.95, date: 0.85)
        )
        viewModel.parsedTransactions = [parsedTransaction]
        
        // Act
        viewModel.confirmTransactions()
        
        // Wait for async processing
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Assert
        XCTAssertTrue(mockAccountRepository.getOrCreateDefaultAccountCalled)
        XCTAssertTrue(mockTransactionRepository.saveCalled)
        XCTAssertTrue(viewModel.parsedTransactions.isEmpty)
    }
    
    func testConfirmTransactionsError() async {
        // Arrange
        mockAccountRepository.shouldThrowError = true
        
        let parsedTransaction = ParsedTransaction(
            date: Date(),
            merchant: "Test Merchant",
            amount: 100.0,
            category: "Food",
            confidence: ConfidenceScore(overall: 0.9, merchant: 0.95, amount: 0.95, date: 0.85)
        )
        viewModel.parsedTransactions = [parsedTransaction]
        
        // Act
        viewModel.confirmTransactions()
        
        // Wait for async processing
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Assert
        XCTAssertTrue(mockAccountRepository.getOrCreateDefaultAccountCalled)
        XCTAssertNotNil(viewModel.error)
    }
    
    // MARK: - Reset Tests
    
    func testResetUpload() {
        // Arrange
        viewModel.parsedTransactions = [
            ParsedTransaction(
                date: Date(),
                merchant: "Test",
                amount: 100,
                category: "Food",
                confidence: ConfidenceScore(overall: 0.9, merchant: 0.9, amount: 0.9, date: 0.9)
            )
        ]
        viewModel.isProcessing = true
        viewModel.progress = 0.5
        viewModel.processingStatus = "Processing..."
        
        // Act
        viewModel.resetUpload()
        
        // Assert
        XCTAssertTrue(viewModel.parsedTransactions.isEmpty)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertEqual(viewModel.progress, 0.0)
        XCTAssertTrue(viewModel.processingStatus.isEmpty)
    }
}

// MARK: - Mock OCR Service

class MockOCRService: OCRService {
    var processDocumentCalled = false
    var mockResult: OCRResult?
    var shouldThrowError = false
    
    func processDocument(_ data: Data, type: DocumentType) async throws -> OCRResult {
        processDocumentCalled = true
        
        if shouldThrowError {
            throw NSError(domain: "MockOCRService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock OCR error"])
        }
        
        if let result = mockResult {
            return result
        }
        
        // Return default result
        return OCRResult(
            rawText: "Default OCR text",
            confidence: 0.8,
            processingTime: 1.0,
            detectedFormat: .generic
        )
    }
}

// MARK: - Mock Transaction Parser Service

class MockTransactionParserService: TransactionParserService {
    var parseTransactionsCalled = false
    var mockTransactions: [ParsedTransaction] = []
    var shouldThrowError = false
    
    func parseTransactions(from text: String, format: StatementFormat) async throws -> [ParsedTransaction] {
        parseTransactionsCalled = true
        
        if shouldThrowError {
            throw NSError(domain: "MockParserService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock parser error"])
        }
        
        return mockTransactions
    }
}
