//
//  SecurityAuditView.swift
//  ClariFi_iOS
//
//  Displays security audit logs and reports
//

import SwiftUI

struct SecurityAuditView: View {
    @StateObject private var viewModel: SecurityAuditViewModel
    @State private var selectedPeriod: AuditPeriod = .week
    @State private var showingIntegrityCheck = false
    
    init(container: AppDIContainer) {
        let auditService = container.resolve(SecurityAuditService.self)
        _viewModel = StateObject(wrappedValue: SecurityAuditViewModel(auditService: auditService))
    }
    
    var body: some View {
        List {
            // Activity Summary Section
            Section {
                if let summary = viewModel.activitySummary {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "shield.checkered")
                                .foregroundColor(.blue)
                            Text("Security Activity")
                                .font(.headline)
                        }
                        
                        HStack {
                            HybridGlassCard(style: .standard) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "list.number")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                        Spacer()
                                    }
                                    
                                    Text("\(summary.totalEvents)")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Text("Total Events")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(16)
                            }
                            
                            HybridGlassCard(style: .standard) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "person.badge.key")
                                            .foregroundColor(.green)
                                            .font(.title2)
                                        Spacer()
                                    }
                                    
                                    Text("\(summary.authenticationEvents)")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Text("Auth Events")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(16)
                            }
                        }
                        
                        HStack {
                            HybridGlassCard(style: .standard) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "doc.text")
                                            .foregroundColor(.orange)
                                            .font(.title2)
                                        Spacer()
                                    }
                                    
                                    Text("\(summary.dataEvents)")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Text("Data Events")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(16)
                            }
                            
                            HybridGlassCard(style: .standard) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "shield")
                                            .foregroundColor(.red)
                                            .font(.title2)
                                        Spacer()
                                    }
                                    
                                    Text("\(summary.securityEvents)")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Text("Security Events")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(16)
                            }
                        }
                        
                        if let lastActivity = summary.lastActivity {
                            Text("Last activity: \(lastActivity, style: .relative) ago")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Last 7 Days")
            }
            
            // Audit Report Section
            Section {
                Picker("Period", selection: $selectedPeriod) {
                    Text("Last Week").tag(AuditPeriod.week)
                    Text("Last Month").tag(AuditPeriod.month)
                    Text("Last 3 Months").tag(AuditPeriod.threeMonths)
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedPeriod) { _, _ in
                    viewModel.loadAuditReport(for: selectedPeriod)
                }
                
                if let report = viewModel.auditReport {
                    VStack(alignment: .leading, spacing: 8) {
                        AuditMetricRow(
                            icon: "person.badge.key",
                            title: "Authentication",
                            value: "\(report.authenticationSuccesses)/\(report.authenticationAttempts)",
                            detail: String(format: "%.1f%% success rate", report.authenticationSuccessRate * 100)
                        )
                        
                        AuditMetricRow(
                            icon: "doc.text",
                            title: "Data Access",
                            value: "\(report.dataAccessEvents)",
                            detail: nil
                        )
                        
                        AuditMetricRow(
                            icon: "pencil",
                            title: "Data Modifications",
                            value: "\(report.dataModificationEvents)",
                            detail: nil
                        )
                        
                        AuditMetricRow(
                            icon: "lock",
                            title: "Encryption Operations",
                            value: "\(report.encryptionEvents)",
                            detail: nil
                        )
                        
                        if report.securityViolations > 0 {
                            AuditMetricRow(
                                icon: "exclamationmark.triangle",
                                title: "Security Violations",
                                value: "\(report.securityViolations)",
                                detail: nil
                            )
                            .foregroundColor(.red)
                        }
                    }
                }
            } header: {
                Text("Audit Report")
            }
            
            // Recent Critical Events
            if let report = viewModel.auditReport,
               !report.recentCriticalEvents.isEmpty {
                Section {
                    ForEach(Array(report.recentCriticalEvents), id: \.id) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: severityIcon(event.severity))
                                    .foregroundColor(severityColor(event.severity))
                                Text(event.eventType.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(event.timestamp, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(event.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Recent Critical Events")
                }
            }
            
            // Integrity Check Section
            Section {
                Button(action: {
                    Task {
                        await viewModel.performIntegrityCheck()
                        showingIntegrityCheck = true
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.shield")
                        Text("Run Integrity Check")
                        Spacer()
                        if viewModel.isCheckingIntegrity {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isCheckingIntegrity)
                
                if let result = viewModel.integrityCheckResult {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.passed ? .green : .red)
                            Text(result.passed ? "All checks passed" : "Issues detected")
                                .fontWeight(.medium)
                        }
                        
                        Text("\(result.checksPerformed) checks performed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !result.issues.isEmpty {
                            ForEach(result.issues, id: \.self) { issue in
                                Text("• \(issue)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Data Integrity")
            }
            
            // Actions Section
            Section {
                Button(role: .destructive, action: {
                    viewModel.clearAllLogs()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear All Logs")
                    }
                }
            } header: {
                Text("Actions")
            } footer: {
                Text("Audit logs are automatically cleaned up after 90 days. Clearing logs will remove all security event history.")
            }
        }
        .navigationTitle("Security Audit")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
        .alert("Integrity Check Complete", isPresented: $showingIntegrityCheck) {
            Button("OK", role: .cancel) { }
        } message: {
            if let result = viewModel.integrityCheckResult {
                Text(result.passed ? "All integrity checks passed successfully." : "Found \(result.issuesFound) issue(s). Please review the details.")
            }
        }
    }
    
    private func severityIcon(_ severity: SecuritySeverity) -> String {
        switch severity {
        case .info: return "info.circle"
        case .low: return "exclamationmark.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
    
    private func severityColor(_ severity: SecuritySeverity) -> Color {
        switch severity {
        case .info: return .blue
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Supporting Views

// StatCard is defined in DashboardView.swift

struct AuditMetricRow: View {
    let icon: String
    let title: String
    let value: String
    let detail: String?
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                if let detail = detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ViewModel

@MainActor
class SecurityAuditViewModel: ObservableObject {
    @Published var activitySummary: SecurityActivitySummary?
    @Published var auditReport: SecurityAuditReport?
    @Published var integrityCheckResult: IntegrityCheckResult?
    @Published var isCheckingIntegrity = false
    
    private let auditService: SecurityAuditService
    
    init(auditService: SecurityAuditService) {
        self.auditService = auditService
    }
    
    func loadData() async {
        loadActivitySummary()
        loadAuditReport(for: .week)
    }
    
    func loadActivitySummary() {
        activitySummary = auditService.getRecentActivitySummary(days: 7)
    }
    
    func loadAuditReport(for period: AuditPeriod) {
        let interval = period.dateInterval
        auditReport = auditService.generateAuditReport(for: interval)
    }
    
    func performIntegrityCheck() async {
        isCheckingIntegrity = true
        integrityCheckResult = await auditService.performIntegrityCheck()
        isCheckingIntegrity = false
    }
    
    func clearAllLogs() {
        auditService.clearAllLogs()
        Task {
            await loadData()
        }
    }
}

enum AuditPeriod {
    case week
    case month
    case threeMonths
    
    var dateInterval: DateInterval {
        let end = Date()
        let start: Date
        
        switch self {
        case .week:
            start = Calendar.current.date(byAdding: .day, value: -7, to: end) ?? end
        case .month:
            start = Calendar.current.date(byAdding: .month, value: -1, to: end) ?? end
        case .threeMonths:
            start = Calendar.current.date(byAdding: .month, value: -3, to: end) ?? end
        }
        
        return DateInterval(start: start, end: end)
    }
}

#Preview {
    NavigationView {
        SecurityAuditView(container: AppDIContainer.createPreviewContainer() as! AppDIContainer)
    }
}
