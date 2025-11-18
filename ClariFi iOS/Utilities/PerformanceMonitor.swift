//
//  PerformanceMonitor.swift
//  ClariFi iOS
//
//  Performance monitoring utilities for measuring and optimizing app performance
//

import Foundation

/// Performance monitoring utility for measuring operation times
class PerformanceMonitor {
    
    // MARK: - Singleton
    
    static let shared = PerformanceMonitor()
    
    private init() {}
    
    // MARK: - Properties
    
    private var measurements: [String: [TimeInterval]] = [:]
    private let queue = DispatchQueue(label: "com.clarifi.performanceMonitor", attributes: .concurrent)
    
    // MARK: - Measurement
    
    /// Measure the execution time of a synchronous operation
    /// - Parameters:
    ///   - label: A label to identify this measurement
    ///   - operation: The operation to measure
    /// - Returns: The result of the operation
    @discardableResult
    func measure<T>(_ label: String, operation: () -> T) -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        recordMeasurement(label: label, duration: duration)
        
        if duration > 0.1 { // Log if operation takes more than 100ms
            print("⏱️ Performance: \(label) took \(String(format: "%.3f", duration * 1000))ms")
        }
        
        return result
    }
    
    /// Measure the execution time of an async operation
    /// - Parameters:
    ///   - label: A label to identify this measurement
    ///   - operation: The async operation to measure
    /// - Returns: The result of the operation
    @discardableResult
    func measureAsync<T>(_ label: String, operation: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        recordMeasurement(label: label, duration: duration)
        
        if duration > 0.1 { // Log if operation takes more than 100ms
            print("⏱️ Performance: \(label) took \(String(format: "%.3f", duration * 1000))ms")
        }
        
        return result
    }
    
    /// Start a measurement timer
    /// - Parameter label: A label to identify this measurement
    /// - Returns: A timer ID to use with endMeasurement
    func startMeasurement(_ label: String) -> UUID {
        let id = UUID()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        queue.async(flags: .barrier) { [weak self] in
            self?.measurements["\(label)_\(id.uuidString)_start"] = [startTime]
        }
        
        return id
    }
    
    /// End a measurement timer
    /// - Parameters:
    ///   - label: The label used when starting the measurement
    ///   - id: The timer ID returned from startMeasurement
    func endMeasurement(_ label: String, id: UUID) {
        let endTime = CFAbsoluteTimeGetCurrent()
        let key = "\(label)_\(id.uuidString)_start"
        
        queue.sync {
            if let startTimes = measurements[key], let startTime = startTimes.first {
                let duration = endTime - startTime
                recordMeasurement(label: label, duration: duration)
                
                if duration > 0.1 {
                    print("⏱️ Performance: \(label) took \(String(format: "%.3f", duration * 1000))ms")
                }
            }
        }
        
        // Clean up start time
        queue.async(flags: .barrier) { [weak self] in
            self?.measurements.removeValue(forKey: key)
        }
    }
    
    // MARK: - Recording
    
    private func recordMeasurement(label: String, duration: TimeInterval) {
        queue.async(flags: .barrier) { [weak self] in
            if self?.measurements[label] == nil {
                self?.measurements[label] = []
            }
            self?.measurements[label]?.append(duration)
            
            // Keep only last 100 measurements per label
            if let count = self?.measurements[label]?.count, count > 100 {
                self?.measurements[label]?.removeFirst()
            }
        }
    }
    
    // MARK: - Statistics
    
    /// Get statistics for a specific measurement label
    /// - Parameter label: The measurement label
    /// - Returns: Statistics including average, min, max, and count
    func getStatistics(for label: String) -> MeasurementStatistics? {
        return queue.sync {
            guard let durations = measurements[label], !durations.isEmpty else {
                return nil
            }
            
            let average = durations.reduce(0, +) / Double(durations.count)
            let min = durations.min() ?? 0
            let max = durations.max() ?? 0
            let count = durations.count
            
            return MeasurementStatistics(
                label: label,
                average: average,
                min: min,
                max: max,
                count: count
            )
        }
    }
    
    /// Get all measurement statistics
    /// - Returns: Array of statistics for all measurements
    func getAllStatistics() -> [MeasurementStatistics] {
        return queue.sync {
            measurements.keys.compactMap { getStatistics(for: $0) }
        }
    }
    
    /// Print a summary of all measurements
    func printSummary() {
        let stats = getAllStatistics().sorted { $0.average > $1.average }
        
        print("\nPerformance Summary")
        print("=" * 60)
        
        for stat in stats {
            print(String(format: "%-30s Avg: %6.2fms  Min: %6.2fms  Max: %6.2fms  Count: %d",
                         stat.label,
                         stat.average * 1000,
                         stat.min * 1000,
                         stat.max * 1000,
                         stat.count))
        }
        
        print("=" * 60 + "\n")
    }
    
    /// Clear all measurements
    func clearAll() {
        queue.async(flags: .barrier) { [weak self] in
            self?.measurements.removeAll()
        }
    }
}

// MARK: - Measurement Statistics

struct MeasurementStatistics {
    let label: String
    let average: TimeInterval
    let min: TimeInterval
    let max: TimeInterval
    let count: Int
    
    var averageMs: Double { average * 1000 }
    var minMs: Double { min * 1000 }
    var maxMs: Double { max * 1000 }
}

// MARK: - String Extension

private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// MARK: - Usage Examples

/*
 // Synchronous measurement
 let result = PerformanceMonitor.shared.measure("category_lookup") {
     categoryService.getCategory(for: "housing")
 }
 
 // Async measurement
 let transactions = await PerformanceMonitor.shared.measureAsync("fetch_transactions") {
     try await repository.fetchAll()
 }
 
 // Manual timing
 let timerId = PerformanceMonitor.shared.startMeasurement("complex_operation")
 // ... do work ...
 PerformanceMonitor.shared.endMeasurement("complex_operation", id: timerId)
 
 // Get statistics
 if let stats = PerformanceMonitor.shared.getStatistics(for: "category_lookup") {
     print("Average: \(stats.averageMs)ms")
 }
 
 // Print summary
 PerformanceMonitor.shared.printSummary()
 */
