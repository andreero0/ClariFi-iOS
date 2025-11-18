//
//  KeychainHelper.swift
//  ClariFi iOS
//
//  Created by Claude on 2025-11-05.
//  Secure storage helper for authentication tokens and sensitive data
//

import Foundation
import Security

/// Helper class for secure storage of sensitive data in iOS Keychain
class KeychainHelper {

    // MARK: - Error Types

    enum KeychainError: Error, LocalizedError {
        case duplicateItem
        case itemNotFound
        case unexpectedStatus(OSStatus)
        case invalidData
        case unableToEncode
        case unableToFetch

        var errorDescription: String? {
            switch self {
            case .duplicateItem:
                return "Item already exists in keychain"
            case .itemNotFound:
                return "Item not found in keychain"
            case .unexpectedStatus(let status):
                return "Unexpected keychain status: \(status)"
            case .invalidData:
                return "Invalid data format"
            case .unableToEncode:
                return "Unable to encode data"
            case .unableToFetch:
                return "Unable to fetch data from keychain"
            }
        }
    }

    // MARK: - Store Methods

    /// Store a string value in the keychain
    /// - Parameters:
    ///   - key: Unique identifier for the item
    ///   - value: String value to store
    ///   - accessible: When the item should be accessible (default: when unlocked)
    /// - Throws: KeychainError if operation fails
    static func store(key: String, value: String, accessible: CFString = kSecAttrAccessibleWhenUnlocked) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.unableToEncode
        }
        try store(key: key, data: data, accessible: accessible)
    }

    /// Store data in the keychain
    /// - Parameters:
    ///   - key: Unique identifier for the item
    ///   - data: Data to store
    ///   - accessible: When the item should be accessible
    /// - Throws: KeychainError if operation fails
    static func store(key: String, data: Data, accessible: CFString = kSecAttrAccessibleWhenUnlocked) throws {
        // First, try to delete any existing item
        try? delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.clarifi.ios",
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessible
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                throw KeychainError.duplicateItem
            }
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Retrieve Methods

    /// Retrieve a string value from the keychain
    /// - Parameter key: Unique identifier for the item
    /// - Returns: String value if found, nil otherwise
    /// - Throws: KeychainError if operation fails
    static func retrieve(key: String) throws -> String? {
        guard let data = try retrieveData(key: key) else {
            return nil
        }

        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return string
    }

    /// Retrieve data from the keychain
    /// - Parameter key: Unique identifier for the item
    /// - Returns: Data if found, nil otherwise
    /// - Throws: KeychainError if operation fails
    static func retrieveData(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.clarifi.ios",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }

        return data
    }

    // MARK: - Update Methods

    /// Update an existing keychain item
    /// - Parameters:
    ///   - key: Unique identifier for the item
    ///   - value: New string value
    /// - Throws: KeychainError if operation fails
    static func update(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.unableToEncode
        }
        try update(key: key, data: data)
    }

    /// Update an existing keychain item
    /// - Parameters:
    ///   - key: Unique identifier for the item
    ///   - data: New data value
    /// - Throws: KeychainError if operation fails
    static func update(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.clarifi.ios"
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Delete Methods

    /// Delete an item from the keychain
    /// - Parameter key: Unique identifier for the item
    /// - Throws: KeychainError if operation fails
    static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.clarifi.ios"
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Delete all keychain items for this app
    /// - Throws: KeychainError if operation fails
    static func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.clarifi.ios"
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Convenience Methods

    /// Check if a keychain item exists
    /// - Parameter key: Unique identifier for the item
    /// - Returns: true if item exists, false otherwise
    static func exists(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.clarifi.ios",
            kSecReturnData as String: false
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}

// MARK: - Authentication Token Keys

extension KeychainHelper {

    /// Keychain keys for authentication
    enum AuthKeys {
        static let accessToken = "com.clarifi.auth.accessToken"
        static let refreshToken = "com.clarifi.auth.refreshToken"
        static let userId = "com.clarifi.auth.userId"
        static let userEmail = "com.clarifi.auth.userEmail"
        static let deviceIdentifier = "com.clarifi.deviceIdentifier"
    }
}
