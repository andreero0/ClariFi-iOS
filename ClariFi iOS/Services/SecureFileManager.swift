//
//  SecureFileManager.swift
//  ClariFi_iOS
//
//  Handles secure temporary file creation and automatic cleanup
//

import Foundation
import UIKit

/// Service for managing secure temporary files with automatic cleanup
class SecureFileManager {
    static let shared = SecureFileManager()
    
    private let fileManager = FileManager.default
    private let secureDirectoryName = "SecureTemp"
    private var trackedFiles: Set<URL> = []
    private let queue = DispatchQueue(label: "com.clarifi.securefiles", attributes: .concurrent)
    
    private init() {
        setupSecureDirectory()
        setupCleanupObservers()
    }
    
    // MARK: - Directory Setup
    
    private var secureDirectory: URL {
        let tempDir = fileManager.temporaryDirectory
        return tempDir.appendingPathComponent(secureDirectoryName, isDirectory: true)
    }
    
    private func setupSecureDirectory() {
        do {
            if !fileManager.fileExists(atPath: secureDirectory.path) {
                try fileManager.createDirectory(
                    at: secureDirectory,
                    withIntermediateDirectories: true,
                    attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
                )
            }
        } catch {
            print("Failed to create secure directory: \(error)")
        }
    }
    
    // MARK: - File Operations
    
    /// Creates a secure temporary file with data protection
    func createSecureTemporaryFile(data: Data, fileExtension: String = "tmp") throws -> URL {
        let fileName = UUID().uuidString + "." + fileExtension
        let fileURL = secureDirectory.appendingPathComponent(fileName)
        
        // Write data with file protection
        try data.write(
            to: fileURL,
            options: [.atomic, .completeFileProtection]
        )
        
        // Track file for cleanup
        queue.async(flags: .barrier) {
            self.trackedFiles.insert(fileURL)
        }
        
        return fileURL
    }
    
    /// Creates a secure temporary file from a source file
    func createSecureTemporaryFile(from sourceURL: URL) throws -> URL {
        let data = try Data(contentsOf: sourceURL)
        let fileExtension = sourceURL.pathExtension
        return try createSecureTemporaryFile(data: data, fileExtension: fileExtension)
    }
    
    /// Securely deletes a file by overwriting before deletion
    func secureDelete(_ fileURL: URL) throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }
        
        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        guard let fileSize = attributes[.size] as? Int64 else {
            throw SecureFileError.deletionFailed
        }
        
        // Overwrite with random data
        let randomData = Data((0..<fileSize).map { _ in UInt8.random(in: 0...255) })
        try randomData.write(to: fileURL, options: .atomic)
        
        // Delete the file
        try fileManager.removeItem(at: fileURL)
        
        // Remove from tracked files
        queue.async(flags: .barrier) {
            self.trackedFiles.remove(fileURL)
        }
    }
    
    /// Deletes a file without overwriting (faster, less secure)
    func quickDelete(_ fileURL: URL) throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }
        
        try fileManager.removeItem(at: fileURL)
        
        queue.async(flags: .barrier) {
            self.trackedFiles.remove(fileURL)
        }
    }
    
    // MARK: - Cleanup
    
    /// Cleans up all tracked temporary files
    func cleanupAllTrackedFiles() {
        queue.sync {
            for fileURL in trackedFiles {
                try? quickDelete(fileURL)
            }
            trackedFiles.removeAll()
        }
    }
    
    /// Cleans up old temporary files (older than specified age)
    func cleanupOldFiles(olderThan age: TimeInterval = 3600) throws {
        let contents = try fileManager.contentsOfDirectory(
            at: secureDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )
        
        let cutoffDate = Date().addingTimeInterval(-age)
        
        for fileURL in contents {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let creationDate = attributes[.creationDate] as? Date,
               creationDate < cutoffDate {
                try quickDelete(fileURL)
            }
        }
    }
    
    /// Cleans up entire secure directory
    func cleanupSecureDirectory() throws {
        if fileManager.fileExists(atPath: secureDirectory.path) {
            try fileManager.removeItem(at: secureDirectory)
        }
        
        queue.async(flags: .barrier) {
            self.trackedFiles.removeAll()
        }
        
        setupSecureDirectory()
    }
    
    // MARK: - Observers
    
    private func setupCleanupObservers() {
        // Cleanup when app enters background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Cleanup when app terminates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppTermination),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        
        // Cleanup old files when app becomes active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleAppBackground() {
        // Clean up old files when app goes to background
        try? cleanupOldFiles(olderThan: 300) // 5 minutes
    }
    
    @objc private func handleAppTermination() {
        // Clean up all tracked files on termination
        cleanupAllTrackedFiles()
    }
    
    @objc private func handleAppActive() {
        // Clean up old files when app becomes active
        try? cleanupOldFiles(olderThan: 3600) // 1 hour
    }
    
    // MARK: - File Info
    
    /// Gets the size of all temporary files
    func getTotalSecureFileSize() throws -> Int64 {
        let contents = try fileManager.contentsOfDirectory(
            at: secureDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        )
        
        var totalSize: Int64 = 0
        for fileURL in contents {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? Int64 {
                totalSize += fileSize
            }
        }
        
        return totalSize
    }
    
    /// Gets count of temporary files
    func getSecureFileCount() throws -> Int {
        let contents = try fileManager.contentsOfDirectory(
            at: secureDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )
        return contents.count
    }
}

// MARK: - Errors

enum SecureFileError: LocalizedError {
    case creationFailed
    case deletionFailed
    case directorySetupFailed
    
    var errorDescription: String? {
        switch self {
        case .creationFailed:
            return "Failed to create secure temporary file"
        case .deletionFailed:
            return "Failed to securely delete file"
        case .directorySetupFailed:
            return "Failed to set up secure directory"
        }
    }
}
