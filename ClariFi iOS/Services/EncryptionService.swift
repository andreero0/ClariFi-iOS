//
//  EncryptionService.swift
//  ClariFi_iOS
//
//  Handles data encryption using iOS Keychain and Data Protection API
//

import Foundation
import Security
import CryptoKit

/// Service for encrypting and decrypting sensitive data
class EncryptionService {
    static let shared = EncryptionService()
    
    private let keyIdentifier = "com.clarifi.encryption.key"
    private let keychainService = "com.clarifi.keychain"
    
    private init() {}
    
    // MARK: - Key Management
    
    /// Retrieves or generates encryption key from Keychain
    func getOrCreateEncryptionKey() throws -> SymmetricKey {
        // Try to retrieve existing key
        if let existingKey = try? retrieveKeyFromKeychain() {
            return existingKey
        }
        
        // Generate new key if none exists
        let newKey = SymmetricKey(size: .bits256)
        try storeKeyInKeychain(newKey)
        return newKey
    }
    
    private func retrieveKeyFromKeychain() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keyIdentifier,
            kSecReturnData as String: true,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw EncryptionError.keyRetrievalFailed
        }
        
        return SymmetricKey(data: keyData)
    }
    
    private func storeKeyInKeychain(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keyIdentifier,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw EncryptionError.keyStorageFailed
        }
    }
    
    /// Deletes encryption key from Keychain (used during data deletion)
    func deleteEncryptionKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keyIdentifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw EncryptionError.keyDeletionFailed
        }
    }
    
    // MARK: - Encryption/Decryption
    
    /// Encrypts data using AES-GCM
    func encrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        
        return combined
    }
    
    /// Decrypts data using AES-GCM
    func decrypt(_ encryptedData: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        return decryptedData
    }
    
    /// Encrypts a string
    func encrypt(_ string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidInput
        }
        return try encrypt(data)
    }
    
    /// Decrypts to a string
    func decryptToString(_ encryptedData: Data) throws -> String {
        let decryptedData = try decrypt(encryptedData)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        return string
    }
    
    // MARK: - Secure Storage
    
    /// Stores sensitive data in Keychain with encryption
    func storeSecureData(_ data: Data, forKey key: String) throws {
        let encryptedData = try encrypt(data)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: encryptedData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item if present
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw EncryptionError.storageError
        }
    }
    
    /// Retrieves and decrypts data from Keychain
    func retrieveSecureData(forKey key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let encryptedData = result as? Data else {
            throw EncryptionError.retrievalError
        }
        
        return try decrypt(encryptedData)
    }
    
    /// Deletes secure data from Keychain
    func deleteSecureData(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw EncryptionError.deletionError
        }
    }
}

// MARK: - Errors

enum EncryptionError: LocalizedError {
    case keyRetrievalFailed
    case keyStorageFailed
    case keyDeletionFailed
    case encryptionFailed
    case decryptionFailed
    case invalidInput
    case storageError
    case retrievalError
    case deletionError
    
    var errorDescription: String? {
        switch self {
        case .keyRetrievalFailed:
            return "Failed to retrieve encryption key from Keychain"
        case .keyStorageFailed:
            return "Failed to store encryption key in Keychain"
        case .keyDeletionFailed:
            return "Failed to delete encryption key from Keychain"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .invalidInput:
            return "Invalid input data for encryption"
        case .storageError:
            return "Failed to store encrypted data"
        case .retrievalError:
            return "Failed to retrieve encrypted data"
        case .deletionError:
            return "Failed to delete encrypted data"
        }
    }
}
