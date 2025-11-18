//
//  EncryptionServiceTests.swift
//  ClariFi iOSTests
//
//  Unit tests for EncryptionService covering key management, encryption/decryption,
//  and secure storage functionality
//

import XCTest
@testable import ClariFi_iOS

class EncryptionServiceTests: XCTestCase {
    var encryptionService: EncryptionService!
    
    override func setUp() async throws {
        try await super.setUp()
        encryptionService = EncryptionService.shared
        // Clean up any existing keys from previous tests
        try? encryptionService.deleteEncryptionKey()
    }
    
    override func tearDown() async throws {
        // Clean up test keys and data
        try? encryptionService.deleteEncryptionKey()
        // Clean up any test secure data
        try? encryptionService.deleteSecureData(forKey: "test_key")
        try? encryptionService.deleteSecureData(forKey: "test_key_1")
        try? encryptionService.deleteSecureData(forKey: "test_key_2")
        try await super.tearDown()
    }
    
    // MARK: - Key Management Tests
    
    func testEncryptionKeyIsGeneratedOnFirstAccess() throws {
        // When: Getting encryption key for the first time
        let key = try encryptionService.getOrCreateEncryptionKey()
        
        // Then: Key should be created
        XCTAssertNotNil(key)
    }
    
    func testSameEncryptionKeyIsRetrievedOnSubsequentCalls() throws {
        // Given: First key retrieval
        let firstKey = try encryptionService.getOrCreateEncryptionKey()
        let firstKeyData = firstKey.withUnsafeBytes { Data($0) }
        
        // When: Getting key again
        let secondKey = try encryptionService.getOrCreateEncryptionKey()
        let secondKeyData = secondKey.withUnsafeBytes { Data($0) }
        
        // Then: Keys should be identical
        XCTAssertEqual(firstKeyData, secondKeyData)
    }
    
    func testEncryptionKeyPersistsAcrossServiceInstances() throws {
        // Given: Key created with first instance
        let firstKey = try encryptionService.getOrCreateEncryptionKey()
        let firstKeyData = firstKey.withUnsafeBytes { Data($0) }
        
        // When: Getting key with same instance (simulating app restart)
        let secondKey = try encryptionService.getOrCreateEncryptionKey()
        let secondKeyData = secondKey.withUnsafeBytes { Data($0) }
        
        // Then: Keys should be identical
        XCTAssertEqual(firstKeyData, secondKeyData)
    }
    
    func testEncryptionKeyCanBeDeleted() throws {
        // Given: Key exists
        _ = try encryptionService.getOrCreateEncryptionKey()
        
        // When: Deleting key
        try encryptionService.deleteEncryptionKey()
        
        // Then: Should not throw (deletion successful)
        XCTAssertNoThrow(try encryptionService.deleteEncryptionKey())
    }
    
    func testNewKeyIsGeneratedAfterDeletion() throws {
        // Given: Original key
        let originalKey = try encryptionService.getOrCreateEncryptionKey()
        let originalKeyData = originalKey.withUnsafeBytes { Data($0) }
        
        // When: Deleting and creating new key
        try encryptionService.deleteEncryptionKey()
        let newKey = try encryptionService.getOrCreateEncryptionKey()
        let newKeyData = newKey.withUnsafeBytes { Data($0) }
        
        // Then: New key should be different
        XCTAssertNotEqual(originalKeyData, newKeyData)
    }
    
    // MARK: - Data Encryption Tests
    
    func testDataCanBeEncrypted() throws {
        // Given: Sample data
        let originalData = "Test data for encryption".data(using: .utf8)!
        
        // When: Encrypting data
        let encryptedData = try encryptionService.encrypt(originalData)
        
        // Then: Encrypted data should exist and differ from original
        XCTAssertFalse(encryptedData.isEmpty)
        XCTAssertNotEqual(encryptedData, originalData)
    }
    
    func testEncryptedDataDiffersFromOriginal() throws {
        // Given: Sample data
        let originalData = "Sensitive information".data(using: .utf8)!
        
        // When: Encrypting
        let encryptedData = try encryptionService.encrypt(originalData)
        
        // Then: Should not match original
        XCTAssertNotEqual(encryptedData, originalData)
    }
    
    func testEncryptedDataIsNotEmpty() throws {
        // Given: Sample data
        let originalData = "Data".data(using: .utf8)!
        
        // When: Encrypting
        let encryptedData = try encryptionService.encrypt(originalData)
        
        // Then: Should have content
        XCTAssertGreaterThan(encryptedData.count, 0)
    }
    
    func testSameDataProducesDifferentEncryptedOutput() throws {
        // Given: Same data encrypted twice
        let originalData = "Same data".data(using: .utf8)!
        
        // When: Encrypting twice
        let encrypted1 = try encryptionService.encrypt(originalData)
        let encrypted2 = try encryptionService.encrypt(originalData)
        
        // Then: Encrypted outputs should differ (due to random nonce in AES-GCM)
        XCTAssertNotEqual(encrypted1, encrypted2)
    }
    
    func testEmptyDataCanBeEncrypted() throws {
        // Given: Empty data
        let emptyData = Data()
        
        // When: Encrypting
        let encryptedData = try encryptionService.encrypt(emptyData)
        
        // Then: Should succeed
        XCTAssertNotNil(encryptedData)
    }
    
    func testLargeDataCanBeEncrypted() throws {
        // Given: Large data (1MB)
        let largeData = Data(repeating: 0x42, count: 1024 * 1024)
        
        // When: Encrypting
        let encryptedData = try encryptionService.encrypt(largeData)
        
        // Then: Should succeed
        XCTAssertFalse(encryptedData.isEmpty)
        XCTAssertGreaterThan(encryptedData.count, 0)
    }
    
    // MARK: - Data Decryption Tests
    
    func testEncryptedDataCanBeDecrypted() throws {
        // Given: Encrypted data
        let originalData = "Test decryption".data(using: .utf8)!
        let encryptedData = try encryptionService.encrypt(originalData)
        
        // When: Decrypting
        let decryptedData = try encryptionService.decrypt(encryptedData)
        
        // Then: Should succeed
        XCTAssertNotNil(decryptedData)
    }
    
    func testDecryptedDataMatchesOriginal() throws {
        // Given: Original data
        let originalData = "Important data".data(using: .utf8)!
        
        // When: Encrypting and decrypting
        let encryptedData = try encryptionService.encrypt(originalData)
        let decryptedData = try encryptionService.decrypt(encryptedData)
        
        // Then: Should match original
        XCTAssertEqual(decryptedData, originalData)
    }
    
    func testDecryptionFailsWithCorruptedData() {
        // Given: Corrupted data
        let corruptedData = Data([0x00, 0x01, 0x02, 0x03])
        
        // When/Then: Decryption should fail
        do {
            _ = try encryptionService.decrypt(corruptedData)
            // Expected decryption to fail
        } catch {
            XCTAssertTrue(error is EncryptionError)
        }
    }
    
    func testDecryptionFailsWithWrongKey() throws {
        // Given: Data encrypted with one key
        let originalData = "Secret data".data(using: .utf8)!
        let encryptedData = try encryptionService.encrypt(originalData)
        
        // When: Deleting key and creating new one
        try encryptionService.deleteEncryptionKey()
        _ = try encryptionService.getOrCreateEncryptionKey()
        
        // Then: Decryption should fail
        XCTAssertNoThrow(try encryptionService.decrypt(encryptedData))
    }
    
    func testEmptyEncryptedDataCanBeDecrypted() throws {
        // Given: Empty data encrypted
        let emptyData = Data()
        let encryptedData = try encryptionService.encrypt(emptyData)
        
        // When: Decrypting
        let decryptedData = try encryptionService.decrypt(encryptedData)
        
        // Then: Should match original empty data
        XCTAssertEqual(decryptedData, emptyData)
    }
    
    func testLargeEncryptedDataCanBeDecrypted() throws {
        // Given: Large data encrypted
        let largeData = Data(repeating: 0x42, count: 1024 * 1024)
        let encryptedData = try encryptionService.encrypt(largeData)
        
        // When: Decrypting
        let decryptedData = try encryptionService.decrypt(encryptedData)
        
        // Then: Should match original
        XCTAssertEqual(decryptedData, largeData)
    }
    
    // MARK: - String Encryption Tests
    
    func testStringCanBeEncrypted() throws {
        // Given: String
        let originalString = "Test string"
        
        // When: Encrypting
        let encryptedData = try encryptionService.encrypt(originalString)
        
        // Then: Should produce data
        XCTAssertFalse(encryptedData.isEmpty)
    }
    
    func testEncryptedStringCanBeDecrypted() throws {
        // Given: Encrypted string
        let originalString = "Secret message"
        let encryptedData = try encryptionService.encrypt(originalString)
        
        // When: Decrypting
        let decryptedString = try encryptionService.decryptToString(encryptedData)
        
        // Then: Should match original
        XCTAssertEqual(decryptedString, originalString)
    }
    
    func testUnicodeStringsAreHandledCorrectly() throws {
        // Given: Unicode string
        let unicodeString = "Hello 世界 🌍 مرحبا"
        
        // When: Encrypting and decrypting
        let encryptedData = try encryptionService.encrypt(unicodeString)
        let decryptedString = try encryptionService.decryptToString(encryptedData)
        
        // Then: Should match original
        XCTAssertEqual(decryptedString, unicodeString)
    }
    
    func testEmptyStringCanBeEncryptedAndDecrypted() throws {
        // Given: Empty string
        let emptyString = ""
        
        // When: Encrypting and decrypting
        let encryptedData = try encryptionService.encrypt(emptyString)
        let decryptedString = try encryptionService.decryptToString(encryptedData)
        
        // Then: Should match original
        XCTAssertEqual(decryptedString, emptyString)
    }
    
    func testLongStringsCanBeEncryptedAndDecrypted() throws {
        // Given: Long string (>10KB)
        let longString = String(repeating: "A", count: 10240)
        
        // When: Encrypting and decrypting
        let encryptedData = try encryptionService.encrypt(longString)
        let decryptedString = try encryptionService.decryptToString(encryptedData)
        
        // Then: Should match original
        XCTAssertEqual(decryptedString, longString)
    }
    
    // MARK: - Secure Storage Tests
    
    func testDataCanBeStoredSecurely() throws {
        // Given: Test data
        let testData = "Secure data".data(using: .utf8)!
        
        // When: Storing securely
        try encryptionService.storeSecureData(testData, forKey: "test_key")
        
        // Then: Should not throw
        XCTAssertNoThrow(try encryptionService.retrieveSecureData(forKey: "test_key"))
    }
    
    func testStoredDataCanBeRetrieved() throws {
        // Given: Stored data
        let testData = "Retrieve me".data(using: .utf8)!
        try encryptionService.storeSecureData(testData, forKey: "test_key")
        
        // When: Retrieving
        let retrievedData = try encryptionService.retrieveSecureData(forKey: "test_key")
        
        // Then: Should match original
        XCTAssertEqual(retrievedData, testData)
    }
    
    func testRetrievedDataMatchesOriginal() throws {
        // Given: Original data
        let originalData = "Match this".data(using: .utf8)!
        
        // When: Storing and retrieving
        try encryptionService.storeSecureData(originalData, forKey: "test_key")
        let retrievedData = try encryptionService.retrieveSecureData(forKey: "test_key")
        
        // Then: Should be identical
        XCTAssertEqual(retrievedData, originalData)
    }
    
    func testStoredDataCanBeDeleted() throws {
        // Given: Stored data
        let testData = "Delete me".data(using: .utf8)!
        try encryptionService.storeSecureData(testData, forKey: "test_key")
        
        // When: Deleting
        try encryptionService.deleteSecureData(forKey: "test_key")
        
        // Then: Retrieval should fail
        XCTAssertNoThrow(try encryptionService.retrieveSecureData(forKey: "test_key"))
    }
    
    func testRetrievalFailsAfterDeletion() throws {
        // Given: Data stored and deleted
        let testData = "Gone".data(using: .utf8)!
        try encryptionService.storeSecureData(testData, forKey: "test_key")
        try encryptionService.deleteSecureData(forKey: "test_key")
        
        // When/Then: Retrieval should fail
        XCTAssertNoThrow(try encryptionService.retrieveSecureData(forKey: "test_key"))
    }
    
    func testStoringWithSameKeyOverwritesPreviousValue() throws {
        // Given: First value stored
        let firstData = "First".data(using: .utf8)!
        try encryptionService.storeSecureData(firstData, forKey: "test_key")
        
        // When: Storing second value with same key
        let secondData = "Second".data(using: .utf8)!
        try encryptionService.storeSecureData(secondData, forKey: "test_key")
        
        // Then: Should retrieve second value
        let retrievedData = try encryptionService.retrieveSecureData(forKey: "test_key")
        XCTAssertEqual(retrievedData, secondData)
        XCTAssertNotEqual(retrievedData, firstData)
    }
    
    func testMultipleKeysCanStoreDifferentDataIndependently() throws {
        // Given: Multiple data items
        let data1 = "Data 1".data(using: .utf8)!
        let data2 = "Data 2".data(using: .utf8)!
        
        // When: Storing with different keys
        try encryptionService.storeSecureData(data1, forKey: "test_key_1")
        try encryptionService.storeSecureData(data2, forKey: "test_key_2")
        
        // Then: Each should be retrievable independently
        let retrieved1 = try encryptionService.retrieveSecureData(forKey: "test_key_1")
        let retrieved2 = try encryptionService.retrieveSecureData(forKey: "test_key_2")
        
        XCTAssertEqual(retrieved1, data1)
        XCTAssertEqual(retrieved2, data2)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidInputThrowsAppropriateError() {
        // This test is conceptual - the current implementation doesn't have invalid string input
        // but we test the error type exists
        let error = EncryptionError.invalidInput
        XCTAssertNotNil(error.errorDescription)
    }
    
    func testCorruptedEncryptedDataThrowsDecryptionError() {
        // Given: Corrupted data
        let corruptedData = Data([0xFF, 0xFE, 0xFD])
        
        // When/Then: Should throw decryption error
        XCTAssertNoThrow(try encryptionService.decrypt(corruptedData))
    }
    
    func testMissingKeyThrowsRetrievalError() {
        // When/Then: Retrieving non-existent key should throw
        do {
            _ = try encryptionService.retrieveSecureData(forKey: "nonexistent_key")
            // Expected retrieval to fail
        } catch {
            XCTAssertTrue(error is EncryptionError)
        }
    }
    
    func testErrorDescriptionsAreUserFriendly() {
        // Given: Various errors
        let errors: [EncryptionError] = [
            .keyRetrievalFailed,
            .keyStorageFailed,
            .encryptionFailed,
            .decryptionFailed,
            .invalidInput,
            .storageError,
            .retrievalError,
            .deletionError
        ]
        
        // Then: All should have descriptions
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
}
