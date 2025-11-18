//
//  StatementRepositoryThreadSafetyTests.swift
//  ClariFi iOSTests
//
//  Thread safety tests for StatementRepository
//

import XCTest
import CoreData
@testable import ClariFi_iOS

@MainActor
class StatementRepositoryThreadSafetyTests: XCTestCase {
    
    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!
    var backgroundContextProvider: BackgroundContextProvider!
    var statementRepository: CoreDataStatementRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory Core Data stack
        container = NSPersistentContainer(name: "ClariFi_iOS")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        try await container.loadPersistentStores()
        context = container.viewContext
        backgroundContextProvider = BackgroundContextProvider(persistentContainer: container)
        statementRepository = CoreDataStatementRepository(context: context, backgroundContextProvider: backgroundContextProvider)
    }
    
    override func tearDown() async throws {
        container = nil
        context = nil
        backgroundContextProvider = nil
        statementRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Concurrent Read Tests
    
    func testConcurrentStatementReads() async throws {
        // Create test statements
        let statements = createTestStatements(count: 45)
        for statement in statements {
            try await statementRepository.save(statement)
        }
        
        // Test concurrent reads
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<30 {
                group.addTask {
                    do {
                        let fetched = try await self.statementRepository.fetchAll()
                        XCTAssertEqual(fetched.count, 45)
                    } catch {
                        XCTFail("Concurrent read failed: \(error)")
                    }
                }
            }
        }
    }
    
    func testConcurrentHashLookups() async throws {
        // Create statements with unique hashes
        let hashes = (0..<30).map { "hash_\($0)" }
        for (index, hash) in hashes.enumerated() {
            let statement = Statement(context: context)
            statement.id = UUID()
            statement.fileName = "Statement \(index)"
            statement.fileHash = hash
            statement.uploadDate = Date()
            statement.processingStatus = "pending"
            statement.createdAt = Date()
            statement.updatedAt = Date()
            try await statementRepository.save(statement)
        }
        
        // Test concurrent hash lookups
        await withTaskGroup(of: Void.self) { group in
            for hash in hashes {
                for _ in 0..<5 {
                    group.addTask {
                        do {
                            let statement = try await self.statementRepository.fetchByHash(hash)
                            XCTAssertNotNil(statement)
                            XCTAssertEqual(statement?.fileHash, hash)
                        } catch {
                            XCTFail("Concurrent hash lookup failed: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func testConcurrentProcessingStatusReads() async throws {
        // Create statements with different statuses
        let statuses = ["pending", "processing", "completed", "failed"]
        for (index, status) in statuses.enumerated() {
            for i in 0..<10 {
                let statement = Statement(context: context)
                statement.id = UUID()
                statement.fileName = "\(status) Statement \(i)"
                statement.fileHash = "hash_\(status)_\(i)"
                statement.uploadDate = Date()
                statement.processingStatus = status
                statement.createdAt = Date()
                statement.updatedAt = Date()
                try await statementRepository.save(statement)
            }
        }
        
        // Test concurrent status-specific reads
        await withTaskGroup(of: Void.self) { group in
            for status in statuses {
                for _ in 0..<10 {
                    group.addTask {
                        do {
                            let statements = try await self.statementRepository.fetchByProcessingStatus(status)
                            XCTAssertEqual(statements.count, 10)
                        } catch {
                            XCTFail("Concurrent status read failed: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func testConcurrentRecentStatementReads() async throws {
        // Create statements with different dates
        for i in 0..<50 {
            let statement = Statement(context: context)
            statement.id = UUID()
            statement.fileName = "Statement \(i)"
            statement.fileHash = "hash_\(i)"
            statement.uploadDate = Date().addingTimeInterval(Double(-i * 3600))
            statement.processingStatus = "completed"
            statement.createdAt = Date()
            statement.updatedAt = Date()
            try await statementRepository.save(statement)
        }
        
        // Test concurrent recent statement reads
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    do {
                        let statements = try await self.statementRepository.fetchRecentStatements(limit: 20)
                        XCTAssertEqual(statements.count, 20)
                    } catch {
                        XCTFail("Concurrent recent statement read failed: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Concurrent Write Tests (Upload Simulation)
    
    func testConcurrentStatementUploads() async throws {
        // Test concurrent statement uploads
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<40 {
                group.addTask {
                    do {
                        let statement = Statement(context: self.context)
                        statement.id = UUID()
                        statement.fileName = "Upload \(i).pdf"
                        statement.fileHash = "upload_hash_\(i)"
                        statement.uploadDate = Date()
                        statement.processingStatus = "pending"
                        statement.createdAt = Date()
                        statement.updatedAt = Date()
                        
                        try await self.statementRepository.save(statement)
                    } catch {
                        XCTFail("Concurrent statement upload failed: \(error)")
                    }
                }
            }
        }
        
        // Verify all statements were uploaded
        let allStatements = try await statementRepository.fetchAll()
        XCTAssertEqual(allStatements.count, 40)
    }
    
    func testConcurrentStatusUpdates() async throws {
        // Create initial statements
        let statements = createTestStatements(count: 25)
        for statement in statements {
            statement.processingStatus = "pending"
            try await statementRepository.save(statement)
        }
        
        // Test concurrent status updates
        await withTaskGroup(of: Void.self) { group in
            for (index, statement) in statements.enumerated() {
                group.addTask {
                    do {
                        let newStatus = index % 2 == 0 ? "completed" : "processing"
                        try await self.statementRepository.updateProcessingStatus(statement, status: newStatus)
                    } catch {
                        XCTFail("Concurrent status update failed: \(error)")
                    }
                }
            }
        }
        
        // Verify all updates completed
        let completedStatements = try await statementRepository.fetchByProcessingStatus("completed")
        let processingStatements = try await statementRepository.fetchByProcessingStatus("processing")
        XCTAssertEqual(completedStatements.count + processingStatements.count, 25)
    }
    
    // MARK: - Deduplication Tests
    
    func testConcurrentDeduplicationChecks() async throws {
        // Create a statement with a specific hash
        let duplicateHash = "duplicate_hash_123"
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "Original Statement"
        statement.fileHash = duplicateHash
        statement.uploadDate = Date()
        statement.processingStatus = "completed"
        statement.createdAt = Date()
        statement.updatedAt = Date()
        try await statementRepository.save(statement)
        
        // Test concurrent deduplication checks
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<30 {
                group.addTask {
                    do {
                        let existing = try await self.statementRepository.fetchByHash(duplicateHash)
                        XCTAssertNotNil(existing)
                        XCTAssertEqual(existing?.fileHash, duplicateHash)
                    } catch {
                        XCTFail("Concurrent deduplication check failed: \(error)")
                    }
                }
            }
        }
        
        // Verify only one statement with this hash exists
        let allStatements = try await statementRepository.fetchAll()
        let duplicates = allStatements.filter { $0.fileHash == duplicateHash }
        XCTAssertEqual(duplicates.count, 1)
    }
    
    func testConcurrentUploadWithDeduplication() async throws {
        // Create initial statements with unique hashes
        let existingHashes = Set((0..<20).map { "existing_hash_\($0)" })
        for hash in existingHashes {
            let statement = Statement(context: context)
            statement.id = UUID()
            statement.fileName = "Existing \(hash)"
            statement.fileHash = hash
            statement.uploadDate = Date()
            statement.processingStatus = "completed"
            statement.createdAt = Date()
            statement.updatedAt = Date()
            try await statementRepository.save(statement)
        }
        
        // Test concurrent uploads with some duplicates
        let uploadHashes = (0..<40).map { i in
            i < 20 ? "existing_hash_\(i)" : "new_hash_\(i)"
        }
        
        var uploadedCount = 0
        var duplicateCount = 0
        
        await withTaskGroup(of: Bool.self) { group in
            for hash in uploadHashes {
                group.addTask {
                    do {
                        // Check for duplicate
                        let existing = try await self.statementRepository.fetchByHash(hash)
                        if existing != nil {
                            return false // Duplicate
                        }
                        
                        // Upload new statement
                        let statement = Statement(context: self.context)
                        statement.id = UUID()
                        statement.fileName = "Upload \(hash)"
                        statement.fileHash = hash
                        statement.uploadDate = Date()
                        statement.processingStatus = "pending"
                        statement.createdAt = Date()
                        statement.updatedAt = Date()
                        try await self.statementRepository.save(statement)
                        return true // New upload
                    } catch {
                        XCTFail("Concurrent upload with deduplication failed: \(error)")
                        return false
                    }
                }
            }
            
            for await wasUploaded in group {
                if wasUploaded {
                    uploadedCount += 1
                } else {
                    duplicateCount += 1
                }
            }
        }
        
        // Verify deduplication worked
        XCTAssertEqual(duplicateCount, 20) // 20 duplicates detected
        XCTAssertEqual(uploadedCount, 20) // 20 new uploads
        
        let allStatements = try await statementRepository.fetchAll()
        XCTAssertEqual(allStatements.count, 40) // Total unique statements
    }
    
    // MARK: - Mixed Read/Write Tests
    
    func testConcurrentReadsAndWrites() async throws {
        // Create initial statements
        let initialStatements = createTestStatements(count: 15)
        for statement in initialStatements {
            try await statementRepository.save(statement)
        }
        
        // Test concurrent reads and writes
        await withTaskGroup(of: Void.self) { group in
            // Add write tasks
            for i in 0..<15 {
                group.addTask {
                    do {
                        let statement = Statement(context: self.context)
                        statement.id = UUID()
                        statement.fileName = "Mixed Statement \(i)"
                        statement.fileHash = "mixed_hash_\(i)"
                        statement.uploadDate = Date()
                        statement.processingStatus = "pending"
                        statement.createdAt = Date()
                        statement.updatedAt = Date()
                        
                        try await self.statementRepository.save(statement)
                    } catch {
                        XCTFail("Concurrent write failed: \(error)")
                    }
                }
            }
            
            // Add read tasks
            for _ in 0..<15 {
                group.addTask {
                    do {
                        let statements = try await self.statementRepository.fetchAll()
                        XCTAssertTrue(statements.count >= 15)
                    } catch {
                        XCTFail("Concurrent read failed: \(error)")
                    }
                }
            }
        }
        
        // Verify final state
        let finalStatements = try await statementRepository.fetchAll()
        XCTAssertEqual(finalStatements.count, 30)
    }
    
    func testConcurrentReadsWritesAndStatusUpdates() async throws {
        // Create initial statements
        let statements = createTestStatements(count: 10)
        for statement in statements {
            try await statementRepository.save(statement)
        }
        
        // Test concurrent reads, writes, and status updates
        await withTaskGroup(of: Void.self) { group in
            // Add read tasks
            for _ in 0..<10 {
                group.addTask {
                    do {
                        let _ = try await self.statementRepository.fetchRecentStatements(limit: 10)
                    } catch {
                        XCTFail("Concurrent read failed: \(error)")
                    }
                }
            }
            
            // Add write tasks
            for i in 0..<10 {
                group.addTask {
                    do {
                        let statement = Statement(context: self.context)
                        statement.id = UUID()
                        statement.fileName = "New Statement \(i)"
                        statement.fileHash = "new_hash_\(i)"
                        statement.uploadDate = Date()
                        statement.processingStatus = "pending"
                        statement.createdAt = Date()
                        statement.updatedAt = Date()
                        
                        try await self.statementRepository.save(statement)
                    } catch {
                        XCTFail("Concurrent write failed: \(error)")
                    }
                }
            }
            
            // Add status update tasks
            for statement in statements {
                group.addTask {
                    do {
                        try await self.statementRepository.updateProcessingStatus(statement, status: "completed")
                    } catch {
                        XCTFail("Concurrent status update failed: \(error)")
                    }
                }
            }
        }
        
        // Verify final state
        let finalStatements = try await statementRepository.fetchAll()
        XCTAssertEqual(finalStatements.count, 20)
        
        let completedStatements = try await statementRepository.fetchByProcessingStatus("completed")
        XCTAssertEqual(completedStatements.count, 10)
    }
    
    // MARK: - Statement with Transactions Tests
    
    func testConcurrentStatementWithTransactionsQueries() async throws {
        // Create statement with transactions
        let statement = Statement(context: context)
        statement.id = UUID()
        statement.fileName = "Test Statement"
        statement.fileHash = "test_hash"
        statement.uploadDate = Date()
        statement.processingStatus = "completed"
        statement.createdAt = Date()
        statement.updatedAt = Date()
        try await statementRepository.save(statement)
        
        // Create transactions for the statement
        for i in 0..<20 {
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.amount = NSDecimalNumber(value: Double(i * 10))
            transaction.merchant = "Merchant \(i)"
            transaction.date = Date()
            transaction.category = "Test"
            transaction.statement = statement
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
        }
        try context.save()
        
        // Test concurrent queries with transactions
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    do {
                        let fetchedStatement = try await self.statementRepository.fetchStatementWithTransactions(statement.id!)
                        XCTAssertNotNil(fetchedStatement)
                        XCTAssertEqual(fetchedStatement?.transactions?.count, 20)
                    } catch {
                        XCTFail("Concurrent statement with transactions query failed: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Data Integrity Tests
    
    func testNoDataCorruptionUnderConcurrency() async throws {
        // Create statements with specific data
        let statementIds = (0..<35).map { _ in UUID() }
        let hashes = (0..<35).map { "integrity_hash_\($0)" }
        
        await withTaskGroup(of: Void.self) { group in
            for (index, (id, hash)) in zip(statementIds, hashes).enumerated() {
                group.addTask {
                    do {
                        let statement = Statement(context: self.context)
                        statement.id = id
                        statement.fileName = "Statement \(index)"
                        statement.fileHash = hash
                        statement.uploadDate = Date()
                        statement.processingStatus = "completed"
                        statement.createdAt = Date()
                        statement.updatedAt = Date()
                        
                        try await self.statementRepository.save(statement)
                    } catch {
                        XCTFail("Statement creation failed: \(error)")
                    }
                }
            }
        }
        
        // Verify all statements exist with correct data
        let allStatements = try await statementRepository.fetchAll()
        XCTAssertEqual(allStatements.count, 35)
        
        for (index, (id, hash)) in zip(statementIds, hashes).enumerated() {
            let statement = allStatements.first { $0.id == id }
            XCTAssertNotNil(statement, "Statement with ID \(id) not found")
            XCTAssertEqual(statement?.fileName, "Statement \(index)")
            XCTAssertEqual(statement?.fileHash, hash)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestStatements(count: Int) -> [Statement] {
        var statements: [Statement] = []
        
        for i in 0..<count {
            let statement = Statement(context: context)
            statement.id = UUID()
            statement.fileName = "Test Statement \(i).pdf"
            statement.fileHash = "test_hash_\(i)"
            statement.uploadDate = Date()
            statement.processingStatus = i % 3 == 0 ? "completed" : (i % 3 == 1 ? "pending" : "processing")
            statement.createdAt = Date()
            statement.updatedAt = Date()
            statements.append(statement)
        }
        
        return statements
    }
}
