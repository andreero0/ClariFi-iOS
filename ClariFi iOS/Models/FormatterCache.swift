//
//  FormatterCache.swift
//  ClariFi iOS
//
//  Created by AI Assistant on 2025-10-10.
//
//  Thread-safe NumberFormatter cache for performance optimization
//

import Foundation

/// Thread-safe cache for NumberFormatter instances
class FormatterCache {

    // MARK: - Properties

    private var formatters: [Currency: NumberFormatter] = [:]
    private let maxCacheSize = 20 // Reasonable limit for different currencies
    private let queue = DispatchQueue(label: "com.clarifi.formatterCache", attributes: .concurrent)

    // MARK: - Public Methods

    /// Get a cached NumberFormatter for the specified currency (synchronous)
    /// This method is safe to call from synchronous contexts
    /// Thread safety is maintained through dispatch queue
    func formatterSync(for currency: Currency) -> NumberFormatter {
        // Try concurrent read first
        let existing = queue.sync {
            return formatters[currency]
        }

        if let cached = existing {
            return cached
        }

        // Need to create - use barrier write
        return queue.sync(flags: .barrier) { [self] in
            // Double-check after acquiring write lock
            if let cached = formatters[currency] {
                return cached
            }

            // Create new formatter
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale(identifier: currency.localeIdentifier)
            formatter.currencyCode = currency.rawValue
            formatter.maximumFractionDigits = currency.decimalPlaces
            formatter.minimumFractionDigits = currency.decimalPlaces

            // Cache the formatter
            formatters[currency] = formatter

            // Evict oldest entries if cache is full
            if formatters.count > maxCacheSize {
                evictOldestEntries()
            }

            return formatter
        }
    }

    /// Get a cached NumberFormatter for the specified currency (async version)
    /// For async contexts
    func formatter(for currency: Currency) async -> NumberFormatter {
        return formatterSync(for: currency)
    }

    /// Clear all cached formatters
    func clearCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.formatters.removeAll()
        }
    }

    /// Get cache statistics
    var cacheSize: Int {
        return queue.sync {
            return formatters.count
        }
    }

    // MARK: - Private Methods

    /// Evict oldest entries when cache is full
    private func evictOldestEntries() {
        // Simple eviction: remove half the cache
        let keysToRemove = Array(formatters.keys.prefix(maxCacheSize / 2))
        keysToRemove.forEach { formatters.removeValue(forKey: $0) }
    }
}

/// Thread-safe ISO8601DateFormatter cache
class DateFormatterCache {

    // MARK: - Properties

    private var cachedISO8601Formatter: ISO8601DateFormatter?
    private var dateFormatters: [String: DateFormatter] = [:]
    private let maxCacheSize = 10
    private let queue = DispatchQueue(label: "com.clarifi.dateFormatterCache", attributes: .concurrent)

    // MARK: - Public Methods

    /// Get a cached ISO8601DateFormatter
    func iso8601Formatter() -> ISO8601DateFormatter {
        // Try concurrent read first
        let existing = queue.sync {
            return cachedISO8601Formatter
        }

        if let cached = existing {
            return cached
        }

        // Need to create - use barrier write
        return queue.sync(flags: .barrier) { [self] in
            // Double-check after acquiring write lock
            if let cached = cachedISO8601Formatter {
                return cached
            }

            let formatter = ISO8601DateFormatter()
            cachedISO8601Formatter = formatter
            return formatter
        }
    }

    /// Get a cached DateFormatter for the specified format
    func dateFormatter(for format: String) -> DateFormatter {
        // Try concurrent read first
        let existing = queue.sync {
            return dateFormatters[format]
        }

        if let cached = existing {
            return cached
        }

        // Need to create - use barrier write
        return queue.sync(flags: .barrier) { [self] in
            // Double-check after acquiring write lock
            if let cached = dateFormatters[format] {
                return cached
            }

            // Create new formatter
            let formatter = DateFormatter()
            formatter.dateFormat = format
            dateFormatters[format] = formatter

            // Evict if cache is full
            if dateFormatters.count > maxCacheSize {
                evictOldestEntries()
            }

            return formatter
        }
    }

    /// Clear all cached formatters
    func clearCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cachedISO8601Formatter = nil
            self?.dateFormatters.removeAll()
        }
    }

    /// Get cache statistics
    var cacheSize: Int {
        return queue.sync {
            return dateFormatters.count + (cachedISO8601Formatter != nil ? 1 : 0)
        }
    }

    // MARK: - Private Methods

    private func evictOldestEntries() {
        let keysToRemove = Array(dateFormatters.keys.prefix(maxCacheSize / 2))
        keysToRemove.forEach { dateFormatters.removeValue(forKey: $0) }
    }
}
