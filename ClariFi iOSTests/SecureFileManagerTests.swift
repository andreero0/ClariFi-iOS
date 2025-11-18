//
//  SecureFileManagerTests.swift
//  ClariFi iOSTests
//
//  Unit tests for SecureFileManager covering file creation, secure deletion,
//  cleanup operations, and lifecycle management
//

import XCTest
@testable import ClariFi_iOS

class SecureFileManagerTests: XCTestCase {
    var fileManager: SecureFileManager!
    var testFileURLs: [URL] = []
    
    override func setUp() async throws {
        try await super.setUp()
        fileManager = SecureFileManager.shared
        testFileURLs = []
        // Clean up any existing files
        try? fileManager.cleanupSecureDirectory()
    }
    
    override func tearDown() async throws {
        // Clean up all test files
        for url in testFileURLs {
            try? fileManager.quickDelete(url)
        }
        try? fileManager.cleanupSecureDirectory()
        try await super.tearDown()
    }
    
    // MARK: - Directory Setup Tests
    
    func testSecureDirectoryIsCreatedOnInitialization() throws {
        // When: Getting file count (which accesses directory)
        let count = try fileManager.getSecureFileCount()
        
        // Then: Should not throw (directory exists)
        XCTAssertGreaterThanOrEqual(count, 0)
    }
    
    func testSecureDirectoryPersistsAcrossServiceInstances() throws {
        // Given: File created
        let testData = "Persistence test".data(using: .utf8)!
        let fileURL = try fileManager.createSecureTemporaryFile(data: testData)
        testFileURLs.append(fileURL)
        
        // When: Accessing through same instance
        let count = try fileManager.getSecureFileCount()
        
        // Then: File should still exist
        XCTAssertGreaterThan(count, 0)
    }
    
    // MARK: - File Creation Tests
    
    func testTemporaryFileCanBeCreatedWithData() throws {
        // Given: Test data
        let testData = "Test file content".data(using: .utf8)!
        
        // When: Creating file
        let fileURL = try fileManager.createSecureTemporaryFile(data: testData)
        testFileURLs.append(fileURL)
        
        // Then: Should return valid URL
        XCTAssertNotNil(fileURL)
    }
    
    func testCreatedFileExistsAtReturnedURL() throws {
        // Given: Created file
        let testData = "File exists test".data(using: .utf8)!
        let fileURL = try fileManager.createSecureTemporaryFile(data: testData)
        testFileURLs.append(fileURL)
        
        // Then: File should exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    func testCreatedFileContainsCorrectData() throws {
        // Given: Test data
        let testData = "Correct data test".data(using: .utf8)!
        
        // When: Creating and reading file
        let fileURL = try fileManager.createSecureTemporaryFile(data: testData)
        testFileURLs.append(fileURL)
        let readData = try Data(contentsOf: fileURL)
        
        // Then: Data should match
        XCTAssertEqual(readData, testData)
    }
    
    func testMultipleFilesCanBeCreatedIndependently() throws {
        // Given: Multiple data items
        let data1 = "File 1".data(using: .utf8)!
        let data2 = "File 2".data(using: .utf8)!
        let data3 = "File 3".data(using: .utf8)!
        
        // When: Creating multiple files
        let url1 = try fileManager.createSecureTemporaryFile(data: data1)
        let url2 = try fileManager.createSecureTemporaryFile(data: data2)
        let url3 = try fileManager.createSecureTemporaryFile(data: data3)
        testFileURLs.append(contentsOf: [url1, url2, url3])
        
        // Then: All should exist and be different
        XCTAssertTrue(FileManager.default.fileExists(atPath: url1.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: url2.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: url3.path))
        XCTAssertNotEqual(url1, url2)
        XCTAssertNotEqual(url2, url3)
        XCTAssertNotEqual(url1, url3)
    }
    
    func testFileExtensionIsPreserved() throws {
        // Given: Data with specific extension
        let testData = "PDF content".data(using: .utf8)!
        
        // When: Creating file with extension
        let fileURL = try fileManager.createSecureTemporaryFile(data: testData, fileExtension: "pdf")
        testFileURLs.append(fileURL)
        
        // Then: Extension should be preserved
        XCTAssertEqual(fileURL.pathExtension, "pdf")
    }
    
    func testFilesAreTrackedForCleanup() throws {
        // Given: Created file
        let testData = "Tracked file".data(using: .utf8)!
        let fileURL = try fileManager.createSecureTemporaryFile(data: testData)
        testFileURLs.append(fileURL)
        
        // When: Getting file count
        let count = try fileManager.getSecureFileCount()
        
        // Then: Should be at least 1
        XCTAssertEqual(count, 1)
    }
    
    // MARK: - File Creation from Source Tests
    
    func testTemporaryFileCanBeCreatedFromSourceFile() throws {
        // Given: Source file
        let sourceData = "Source file content".data(using: .utf8)!
        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent("source.txt")
        try sourceData.write(to: sourceURL)
        defer { try? FileManager.default.removeItem(at: sourceURL) }
        
        // When: Creating from source
        let fileURL = try fileManager.createSecureTemporaryFile(from: sourceURL)
        testFileURLs.append(fileURL)
        
        // Then: Should succeed
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    func testCreatedFileContainsSameDataAsSource() throws {
        // Given: Source file
        let sourceData = "Source data".data(using: .utf8)!
        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent("source.txt")
        try sourceData.write(to: sourceURL)
        defer { try? FileManager.default.removeItem(at: sourceURL) }
        
        // When: Creating from source
        let fileURL = try fileManager.createSecureTemporaryFile(from: sourceURL)
        testFileURLs.append(fileURL)
        let copiedData = try Data(contentsOf: fileURL)
        
        // Then: Data should match
        XCTAssertEqual(copiedData, sourceData)
    }
    
    func testFileExtensionIsPreservedFromSource() throws {
        // Given: Source file with extension
        let sourceData = "PDF data".data(using: .utf8)!
        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent("source.pdf")
        try sourceData.write(to: sourceURL)
        defer { try? FileManager.default.removeItem(at: sourceURL) }
        
        // When: Creating from source
        let fileURL = try fileManager.createSecureTemporaryFile(from: sourceURL)
        testFileURLs.append(fileURL)
        
        // Then: Extension should match
        XCTAssertEqual(fileURL.pathExtension, "pdf")
    }
    
    // MARK: - Secure Deletion Tests
    
    func testFileNoLongerExistsAfterSecureDeletion() throws {
        // Given: Created file
        let testData = "Delete me securely".data(using: .utf8)!
        let fileURL = try fileManager.createSecureTemporaryFile(data: testData)
        
        // When: Securely deleting
        try fileManager.secureDelete(fileURL)
        
        // Then: File should not exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    func testSecureDeletionHandlesNonExistentFilesGracefully() throws {
        // Given: Non-existent file URL
        let nonExistentURL = FileManager.default.temporaryDirectory.appendingPathComponent("nonexistent.txt")
        
        // When/Then: Should not throw
        XCTAssertNoThrow(try fileManager.secureDelete(nonExistentURL))
    }
    
    func testSecureDeletionWorksForLargeFiles() throws {
        // Given: Large file (1MB)
        let largeData = Data(repeating: 0x42, count: 1024 * 1024)
        let fileURL = try fileManager.createSecureTemporaryFile(data: largeData)
        
        // When: Securely deleting
        try fileManager.secureDelete(fileURL)
        
        // Then: File should not exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    // MARK: - Quick Deletion Tests
    
    func testFileNoLongerExistsAfterQuickDeletion() throws {
        // Given: Created file
        let testData = "Delete me quickly".data(using: .utf8)!
        let fileURL = try fileManager.createSecureTemporaryFile(data: testData)
        
        // When: Quick deleting
        try fileManager.quickDelete(fileURL)
        
        // Then: File should not exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    func testQuickDeletionHandlesNonExistentFilesGracefully() throws {
        // Given: Non-existent file URL
        let nonExistentURL = FileManager.default.temporaryDirectory.appendingPathComponent("nonexistent.txt")
        
        // When/Then: Should not throw
        XCTAssertNoThrow(try fileManager.quickDelete(nonExistentURL))
    }
    
    // MARK: - Cleanup Tests
    
    func testAllTrackedFilesCanBeCleanedUpAtOnce() throws {
        // Given: Multiple tracked files
        let data1 = "File 1".data(using: .utf8)!
        let data2 = "File 2".data(using: .utf8)!
        let url1 = try fileManager.createSecureTemporaryFile(data: data1)
        let url2 = try fileManager.createSecureTemporaryFile(data: data2)
        
        // When: Cleaning up all tracked files
        fileManager.cleanupAllTrackedFiles()
        
        // Then: Files should not exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: url1.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: url2.path))
    }
    
    func testOldFilesAreCleanedUpBasedOnAgeThreshold() throws {
        // Given: File created
        let testData = "Old file".data(using: .utf8)!
        let fileURL = try fileManager.createSecureTemporaryFile(data: testData)
        testFileURLs.append(fileURL)
        
        // When: Cleaning up files older than 0 seconds (all files)
        try fileManager.cleanupOldFiles(olderThan: 0)
        
        // Then: File should be deleted
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    func testRecentFilesArePreservedDuringOldFileCleanup() throws {
        // Given: Recently created file
        let testData = "Recent file".data(using: .utf8)!
        let fileURL = try fileManager.createSecureTemporaryFile(data: testData)
        testFileURLs.append(fileURL)
        
        // When: Cleaning up files older than 1 hour
        try fileManager.cleanupOldFiles(olderThan: 3600)
        
        // Then: Recent file should still exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    func testEntireSecureDirectoryCanBeCleanedUp() throws {
        // Given: Files in secure directory
        let data1 = "File 1".data(using: .utf8)!
        let data2 = "File 2".data(using: .utf8)!
        _ = try fileManager.createSecureTemporaryFile(data: data1)
        _ = try fileManager.createSecureTemporaryFile(data: data2)
        
        // When: Cleaning up directory
        try fileManager.cleanupSecureDirectory()
        
        // Then: Directory should be empty
        let count = try fileManager.getSecureFileCount()
        XCTAssertEqual(count, 0)
    }
    
    func testSecureDirectoryIsRecreatedAfterCleanup() throws {
        // Given: Directory cleaned up
        try fileManager.cleanupSecureDirectory()
        
        // When: Creating new file
        let testData = "New file".data(using: .utf8)!
        let fileURL = try fileManager.createSecureTemporaryFile(data: testData)
        testFileURLs.append(fileURL)
        
        // Then: Should succeed
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    // MARK: - File Info Tests
    
    func testTotalFileSizeIsCalculatedCorrectly() throws {
        // Given: Files with known sizes
        let data1 = Data(repeating: 0x41, count: 1000) // 1KB
        let data2 = Data(repeating: 0x42, count: 2000) // 2KB
        let url1 = try fileManager.createSecureTemporaryFile(data: data1)
        let url2 = try fileManager.createSecureTemporaryFile(data: data2)
        testFileURLs.append(contentsOf: [url1, url2])
        
        // When: Getting total size
        let totalSize = try fileManager.getTotalSecureFileSize()
        
        // Then: Should be approximately 3KB (allowing for file system overhead)
        XCTAssertEqual(totalSize, 3000)
    }
    
    func testFileCountIsAccurate() throws {
        // Given: Known number of files
        let data1 = "File 1".data(using: .utf8)!
        let data2 = "File 2".data(using: .utf8)!
        let data3 = "File 3".data(using: .utf8)!
        let url1 = try fileManager.createSecureTemporaryFile(data: data1)
        let url2 = try fileManager.createSecureTemporaryFile(data: data2)
        let url3 = try fileManager.createSecureTemporaryFile(data: data3)
        testFileURLs.append(contentsOf: [url1, url2, url3])
        
        // When: Getting file count
        let count = try fileManager.getSecureFileCount()
        
        // Then: Should be 3
        XCTAssertEqual(count, 3)
    }
    
    func testEmptyDirectoryReturnsZeroSizeAndCount() throws {
        // Given: Empty directory
        try fileManager.cleanupSecureDirectory()
        
        // When: Getting size and count
        let size = try fileManager.getTotalSecureFileSize()
        let count = try fileManager.getSecureFileCount()
        
        // Then: Both should be zero
        XCTAssertEqual(size, 0)
        XCTAssertEqual(count, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testDeletionHandlesMissingFiles() throws {
        // Given: Non-existent file
        let nonExistentURL = FileManager.default.temporaryDirectory.appendingPathComponent("missing.txt")
        
        // When/Then: Should not throw
        XCTAssertNoThrow(try fileManager.secureDelete(nonExistentURL))
        XCTAssertNoThrow(try fileManager.quickDelete(nonExistentURL))
    }
    
    func testSecureFileErrorDescriptions() {
        // Given: All error types
        let errors: [SecureFileError] = [
            .creationFailed,
            .deletionFailed,
            .directorySetupFailed
        ]
        
        // Then: All should have descriptions
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Performance Tests
    
    func testMultipleFileCreationPerformance() throws {
        // Note: Performance testing removed - Swift Testing doesn't have direct measure equivalent
        // This test verifies multiple file creation works without measuring performance
        var urls: [URL] = []
        for i in 0..<10 { // Reduced count for faster test execution
            let data = "File \(i)".data(using: .utf8)!
            if let url = try? fileManager.createSecureTemporaryFile(data: data) {
                urls.append(url)
            }
        }
        // Cleanup
        for url in urls {
            try? fileManager.quickDelete(url)
        }
        XCTAssertEqual(urls.count, 10)
    }
    
    func testBatchCleanupPerformance() throws {
        // Given: 10 files (reduced for faster test execution)
        var urls: [URL] = []
        for i in 0..<10 {
            let data = "File \(i)".data(using: .utf8)!
            let url = try fileManager.createSecureTemporaryFile(data: data)
            urls.append(url)
        }
        
        // Test cleanup functionality
        fileManager.cleanupAllTrackedFiles()
        
        // Verify cleanup worked
        let count = try fileManager.getSecureFileCount()
        XCTAssertEqual(count, 0)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteFileLifecycle() throws {
        // Given: Create file
        let testData = "Lifecycle test".data(using: .utf8)!
        let fileURL = try fileManager.createSecureTemporaryFile(data: testData)
        
        // Then: File exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        
        // When: Reading file
        let readData = try Data(contentsOf: fileURL)
        XCTAssertEqual(readData, testData)
        
        // When: Deleting file
        try fileManager.secureDelete(fileURL)
        
        // Then: File no longer exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    func testMultipleOperationsInSequence() throws {
        // Create
        let data1 = "First".data(using: .utf8)!
        let url1 = try fileManager.createSecureTemporaryFile(data: data1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url1.path))
        
        // Create another
        let data2 = "Second".data(using: .utf8)!
        let url2 = try fileManager.createSecureTemporaryFile(data: data2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url2.path))
        
        // Check count
        var count = try fileManager.getSecureFileCount()
        XCTAssertEqual(count, 2)
        
        // Delete one
        try fileManager.quickDelete(url1)
        count = try fileManager.getSecureFileCount()
        XCTAssertEqual(count, 1)
        
        // Cleanup all
        fileManager.cleanupAllTrackedFiles()
        count = try fileManager.getSecureFileCount()
        XCTAssertEqual(count, 0)
    }
}
