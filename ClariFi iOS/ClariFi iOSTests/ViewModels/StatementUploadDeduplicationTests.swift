import XCTest
import CoreData
@testable import ClariFi_iOS

@MainActor
final class StatementUploadDeduplicationTests: XCTestCase {
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory persistence controller for testing
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
    }
    
    override func tearDown() async throws {
        context = nil
        persistenceController = nil
        try await super.tearDown()
    }
    
    // MARK: - Core Data Deduplication Tests
    
    func testCheckDuplicate_WithNoExistingStatement_ReturnsFalse() async throws {
        // Given
        let viewModel = createViewModel()
        let testHash = "test_hash_123"
        
        // When
        let isDuplicate = await viewModel.checkDuplicate(fileHash: testHash)
        
        // Then
        XCTAssertFalse(isDuplicate, "Should return false when no statement exists with the hash")
    }
    
    func testCheckDuplicate_WithExistingStatement_ReturnsTrue() async throws {
        // Given
        let viewModel = createViewModel()
        let testHash = "test_hash_456"
        
        // Create a statement with the test hash
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "test.pdf"
        statement.uploadDate = Date()
        statement.fileHash = "original_hash"
        statement.uploadHash = testHash
        statement.uploadedAt = Date()
        statement.uploadSource = "test"
        statement.processingStatus = "completed"
        statement.fileSize = 1000
        statement.documentType = "pdf"
        statement.createdAt = Date()
        statement.updatedAt = Date()
        
        try context.save()
        
        // When
        let isDuplicate = await viewModel.checkDuplicate(fileHash: testHash)
        
        // Then
        XCTAssertTrue(isDuplicate, "Should return true when statement exists with the hash")
    }
    
    func testMarkUploaded_PersistsHashAndMetadata() async throws {
        // Given
        let viewModel = createViewModel()
        let testHash = "test_hash_789"
        let testSource = "camera"
        
        // Create a statement
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "test.jpg"
        statement.uploadDate = Date()
        statement.fileHash = "original_hash"
        statement.processingStatus = "processing"
        statement.fileSize = 2000
        statement.documentType = "image"
        statement.createdAt = Date()
        statement.updatedAt = Date()
        
        try context.save()
        
        // When
        await viewModel.markUploaded(statement: statement, fileHash: testHash, source: testSource)
        
        // Refresh the context to get updated data
        context.refresh(statement, mergeChanges: true)
        
        // Then
        XCTAssertEqual(statement.uploadHash, testHash, "Upload hash should be persisted")
        XCTAssertNotNil(statement.uploadedAt, "Upload date should be set")
        XCTAssertEqual(statement.uploadSource, testSource, "Upload source should be persisted")
    }
    
    func testDeduplication_PersistsAcrossContextRefresh() async throws {
        // Given
        let viewModel = createViewModel()
        let testHash = "persistent_hash_123"
        
        // Create and save a statement
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "persistent.pdf"
        statement.uploadDate = Date()
        statement.fileHash = "original_hash"
        statement.uploadHash = testHash
        statement.uploadedAt = Date()
        statement.uploadSource = "document"
        statement.processingStatus = "completed"
        statement.fileSize = 3000
        statement.documentType = "pdf"
        statement.createdAt = Date()
        statement.updatedAt = Date()
        
        try context.save()
        
        // Reset the context to simulate app restart
        context.reset()
        
        // When
        let isDuplicate = await viewModel.checkDuplicate(fileHash: testHash)
        
        // Then
        XCTAssertTrue(isDuplicate, "Deduplication should persist across context refresh")
    }
    
    // MARK: - Helper Methods
    
    private func createViewModel() -> StatementUploadViewModel {
        // Create mock services
        let mockOCRService = MockOCRService()
        let mockParserService = MockTransactionParserService()
        let mockTransactionRepo = MockTransactionRepository()
        let mockAccountRepo = MockAccountRepository()
        let mockStatementRepo = MockStatementRepository()
        
        return StatementUploadViewModel(
            ocrService: mockOCRService,
            parserService: mockParserService,
            transactionRepository: mockTransactionRepo,
            accountRepository: mockAccountRepo,
            statementRepository: mockStatementRepo,
            llmService: nil,
            context: context
        )
    }
}

// MARK: - Mock Services

class MockOCRService: OCRService {
    func processDocument(_ data: Data, type: DocumentType) async throws -> OCRResult {
        return OCRResult(rawText: "", confidence: 1.0, processingTime: 0.1)
    }
}

class MockTransactionParserService: TransactionParserService {
    func parseTransactions(from text: String, format: StatementFormat) async throws -> [ParsedTransaction] {
        return []
    }
}

class MockTransactionRepository: TransactionRepository {
    func save(_ transaction: Transaction) async throws {}
    func fetch(_ request: NSFetchRequest<Transaction>) async throws -> [Transaction] { return [] }
    func delete(_ transaction: Transaction) async throws {}
    func fetchAll() async throws -> [Transaction] { return [] }
    func fetchRecent(limit: Int) async throws -> [Transaction] { return [] }
}

class MockAccountRepository: AccountRepository {
    func save(_ account: Account) async throws {}
    func fetch(_ request: NSFetchRequest<Account>) async throws -> [Account] { return [] }
    func delete(_ account: Account) async throws {}
    func fetchAll() async throws -> [Account] { return [] }
    func getOrCreateDefaultAccount() async throws -> Account {
        let context = PersistenceController(inMemory: true).container.viewContext
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Default"
        account.type = "checking"
        account.isActive = true
        account.isDefault = true
        account.createdAt = Date()
        account.updatedAt = Date()
        return account
    }
}

class MockStatementRepository: StatementRepository {
    func save(_ statement: Statement) async throws {}
    func fetch(_ request: NSFetchRequest<Statement>) async throws -> [Statement] { return [] }
    func delete(_ statement: Statement) async throws {}
    func fetchAll() async throws -> [Statement] { return [] }
}
