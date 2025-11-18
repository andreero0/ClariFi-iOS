//
//  SecurityAuditService.swift
//  ClariFi_iOS
//
//  Handles security event logging and audit reporting
//

import Foundation
import CoreData

/// Service for logging security events and generating audit reports
class SecurityAuditService {
    private let queue = DispatchQueue(label: "com.clarifi.security.audit", qos: .utility)
    private let maxLogEntries = 1000
    private let logRetentionDays = 90
    private let encryptionService: EncryptionService
    private let secureFileManager: SecureFileManager
    
    init(encryptionService: EncryptionService, secureFileManager: SecureFileManager) {
        self.encryptionService = encryptionService
        self.secureFileManager = secureFileManager
        setupCleanupTimer()
    }
    
    // MARK: - Event Logging
    
    /// Logs a security event
    func logEvent(_ event: SecurityEvent) {
        queue.async {
            self.persistEvent(event)
        }
    }
    
    private func persistEvent(_ event: SecurityEvent) {
        let entry = SecurityLogEntry(
            id: UUID(),
            timestamp: Date(),
            eventType: event.type,
            severity: event.severity,
            description: event.description,
            metadata: event.metadata
        )
        
        // Store in UserDefaults for simplicity (in production, consider Core Data)
        var logs = retrieveAllLogs()
        logs.append(entry)
        
        // Trim old entries if exceeding max
        if logs.count > maxLogEntries {
            logs = Array(logs.suffix(maxLogEntries))
        }
        
        saveLogs(logs)
    }
    
    // MARK: - Log Retrieval
    
    /// Retrieves all security log entries
    func getAllLogs() -> [SecurityLogEntry] {
        return queue.sync {
            retrieveAllLogs()
        }
    }
    
    /// Retrieves logs filtered by event type
    func getLogs(ofType type: SecurityEventType) -> [SecurityLogEntry] {
        return getAllLogs().filter { $0.eventType == type }
    }
    
    /// Retrieves logs within a date range
    func getLogs(from startDate: Date, to endDate: Date) -> [SecurityLogEntry] {
        return getAllLogs().filter { entry in
            entry.timestamp >= startDate && entry.timestamp <= endDate
        }
    }
    
    /// Retrieves logs by severity
    func getLogs(withSeverity severity: SecuritySeverity) -> [SecurityLogEntry] {
        return getAllLogs().filter { $0.severity == severity }
    }
    
    private func retrieveAllLogs() -> [SecurityLogEntry] {
        guard let data = UserDefaults.standard.data(forKey: "security_audit_logs"),
              let logs = try? JSONDecoder().decode([SecurityLogEntry].self, from: data) else {
            return []
        }
        return logs
    }
    
    private func saveLogs(_ logs: [SecurityLogEntry]) {
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: "security_audit_logs")
        }
    }
    
    // MARK: - Audit Reports
    
    /// Generates a security audit report
    func generateAuditReport(for period: DateInterval) -> SecurityAuditReport {
        let logs = getLogs(from: period.start, to: period.end)
        
        let authenticationAttempts = logs.filter { $0.eventType == .authenticationAttempt }.count
        let authenticationSuccesses = logs.filter { $0.eventType == .authenticationSuccess }.count
        let authenticationFailures = logs.filter { $0.eventType == .authenticationFailure }.count
        
        let dataAccessEvents = logs.filter { $0.eventType == .dataAccess }.count
        let dataModificationEvents = logs.filter { $0.eventType == .dataModification }.count
        let dataExportEvents = logs.filter { $0.eventType == .dataExport }.count
        let dataDeletionEvents = logs.filter { $0.eventType == .dataDeletion }.count
        
        let encryptionEvents = logs.filter { $0.eventType == .encryptionOperation }.count
        let decryptionEvents = logs.filter { $0.eventType == .decryptionOperation }.count
        
        let securityViolations = logs.filter { $0.severity == .critical || $0.severity == .high }.count
        
        return SecurityAuditReport(
            period: period,
            totalEvents: logs.count,
            authenticationAttempts: authenticationAttempts,
            authenticationSuccesses: authenticationSuccesses,
            authenticationFailures: authenticationFailures,
            dataAccessEvents: dataAccessEvents,
            dataModificationEvents: dataModificationEvents,
            dataExportEvents: dataExportEvents,
            dataDeletionEvents: dataDeletionEvents,
            encryptionEvents: encryptionEvents,
            decryptionEvents: decryptionEvents,
            securityViolations: securityViolations,
            recentCriticalEvents: logs.filter { $0.severity == .critical }.suffix(10).reversed()
        )
    }
    
    /// Gets a summary of recent security activity
    func getRecentActivitySummary(days: Int = 7) -> SecurityActivitySummary {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let logs = getLogs(from: startDate, to: Date())
        
        let authEvents = logs.filter { 
            $0.eventType == .authenticationAttempt || 
            $0.eventType == .authenticationSuccess || 
            $0.eventType == .authenticationFailure 
        }.count
        
        let dataEvents = logs.filter {
            $0.eventType == .dataAccess ||
            $0.eventType == .dataModification ||
            $0.eventType == .dataExport ||
            $0.eventType == .dataDeletion
        }.count
        
        let securityEvents = logs.filter {
            $0.severity == .high || $0.severity == .critical
        }.count
        
        return SecurityActivitySummary(
            days: days,
            totalEvents: logs.count,
            authenticationEvents: authEvents,
            dataEvents: dataEvents,
            securityEvents: securityEvents,
            lastActivity: logs.last?.timestamp
        )
    }
    
    // MARK: - Data Integrity
    
    /// Performs integrity check on stored data
    func performIntegrityCheck() async -> IntegrityCheckResult {
        var issues: [String] = []
        var checksPerformed = 0
        
        // Check 1: Verify encryption key exists
        checksPerformed += 1
        do {
            _ = try encryptionService.getOrCreateEncryptionKey()
        } catch {
            issues.append("Encryption key verification failed")
        }
        
        // Check 2: Verify secure directory exists
        checksPerformed += 1
        do {
            _ = try secureFileManager.getSecureFileCount()
        } catch {
            issues.append("Secure directory verification failed")
        }
        
        // Check 3: Check for orphaned temporary files
        checksPerformed += 1
        do {
            let fileCount = try secureFileManager.getSecureFileCount()
            if fileCount > 100 {
                issues.append("Excessive temporary files detected (\(fileCount))")
            }
        } catch {
            issues.append("Temporary file check failed")
        }
        
        // Check 4: Verify audit log integrity
        checksPerformed += 1
        let logs = getAllLogs()
        if logs.isEmpty {
            // No logs is acceptable for new installations
        } else if logs.count > maxLogEntries {
            issues.append("Audit log exceeds maximum entries")
        }
        
        logEvent(SecurityEvent(
            type: .integrityCheck,
            severity: issues.isEmpty ? .info : .medium,
            description: "Integrity check completed: \(checksPerformed) checks, \(issues.count) issues",
            metadata: ["issues": issues.joined(separator: ", ")]
        ))
        
        return IntegrityCheckResult(
            timestamp: Date(),
            checksPerformed: checksPerformed,
            issuesFound: issues.count,
            issues: issues,
            passed: issues.isEmpty
        )
    }
    
    // MARK: - Cleanup
    
    /// Clears old log entries
    func cleanupOldLogs() {
        queue.async {
            let cutoffDate = Calendar.current.date(
                byAdding: .day,
                value: -self.logRetentionDays,
                to: Date()
            ) ?? Date()
            
            let logs = self.retrieveAllLogs()
            let filteredLogs = logs.filter { $0.timestamp >= cutoffDate }
            
            self.saveLogs(filteredLogs)
            
            self.logEvent(SecurityEvent(
                type: .maintenanceOperation,
                severity: .info,
                description: "Cleaned up \(logs.count - filteredLogs.count) old log entries"
            ))
        }
    }
    
    /// Clears all audit logs
    func clearAllLogs() {
        queue.async {
            self.saveLogs([])
            
            self.logEvent(SecurityEvent(
                type: .maintenanceOperation,
                severity: .medium,
                description: "All audit logs cleared by user"
            ))
        }
    }
    
    private func setupCleanupTimer() {
        // Clean up old logs daily
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            self?.cleanupOldLogs()
        }
    }
}

// MARK: - Models

struct SecurityEvent {
    let type: SecurityEventType
    let severity: SecuritySeverity
    let description: String
    let metadata: [String: String]
    
    init(type: SecurityEventType, severity: SecuritySeverity, description: String, metadata: [String: String] = [:]) {
        self.type = type
        self.severity = severity
        self.description = description
        self.metadata = metadata
    }
}

enum SecurityEventType: String, Codable {
    case authenticationAttempt
    case authenticationSuccess
    case authenticationFailure
    case dataAccess
    case dataModification
    case dataExport
    case dataDeletion
    case encryptionOperation
    case decryptionOperation
    case integrityCheck
    case maintenanceOperation
    case securityViolation
}

enum SecuritySeverity: String, Codable, Comparable {
    case info
    case low
    case medium
    case high
    case critical
    
    static func < (lhs: SecuritySeverity, rhs: SecuritySeverity) -> Bool {
        let order: [SecuritySeverity] = [.info, .low, .medium, .high, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

struct SecurityLogEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let eventType: SecurityEventType
    let severity: SecuritySeverity
    let description: String
    let metadata: [String: String]
}

struct SecurityAuditReport {
    let period: DateInterval
    let totalEvents: Int
    let authenticationAttempts: Int
    let authenticationSuccesses: Int
    let authenticationFailures: Int
    let dataAccessEvents: Int
    let dataModificationEvents: Int
    let dataExportEvents: Int
    let dataDeletionEvents: Int
    let encryptionEvents: Int
    let decryptionEvents: Int
    let securityViolations: Int
    let recentCriticalEvents: [SecurityLogEntry]
    
    var authenticationSuccessRate: Double {
        guard authenticationAttempts > 0 else { return 0 }
        return Double(authenticationSuccesses) / Double(authenticationAttempts)
    }
}

struct SecurityActivitySummary {
    let days: Int
    let totalEvents: Int
    let authenticationEvents: Int
    let dataEvents: Int
    let securityEvents: Int
    let lastActivity: Date?
}

struct IntegrityCheckResult {
    let timestamp: Date
    let checksPerformed: Int
    let issuesFound: Int
    let issues: [String]
    let passed: Bool
}
