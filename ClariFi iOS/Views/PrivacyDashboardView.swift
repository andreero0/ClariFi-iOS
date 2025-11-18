//
//  PrivacyDashboardView.swift
//  ClariFi iOS
//
//  Privacy dashboard with processing mode controls and data management
//

import SwiftUI

struct PrivacyDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    // State Management: @StateObject is used because this View owns the ViewModel lifecycle.
    // The ViewModel is injected via the initializer from the DI container, ensuring proper
    // dependency injection and shared state across the application.
    @StateObject private var viewModel: PrivacyDashboardViewModel
    private let container: AppDIContainer
    
    init(viewModel: PrivacyDashboardViewModel, container: AppDIContainer) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.container = container
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Processing Mode Section
                    processingModeSection
                    
                    // Data Summary Section
                    dataSummarySection
                    
                    // Security Section
                    securitySection
                    
                    // Feature Consent Section
                    featureConsentSection
                    
                    // Data Management Section
                    dataManagementSection
                    
                    // Privacy Information
                    privacyInfoSection
                }
                .padding()
            }
            .navigationTitle("Privacy")
            .task {
                await viewModel.loadDataSummary()
            }
            .refreshable {
                await viewModel.loadDataSummary()
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
            .sheet(isPresented: $viewModel.showExportSheet) {
                if let url = viewModel.exportURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $viewModel.showProcessingModeInfo) {
                ProcessingModeInfoSheet(mode: viewModel.processingMode)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
    
    private var processingModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Processing Mode")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    viewModel.showProcessingModeInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
            }
            
            Button {
                viewModel.toggleProcessingMode()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.processingMode == .localOnly ? "lock.shield.fill" : "cloud.fill")
                        .font(.system(size: 40))
                        .foregroundColor(viewModel.processingMode == .localOnly ? .green : .blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.processingMode.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(viewModel.processingMode == .localOnly ? "All data stays on your device" : "Enhanced features with encryption")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    private var dataSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Summary")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                if let summary = viewModel.dataSummary {
                    DataSummaryRow(label: "Storage Used", value: summary.formattedStorageSize)
                    DataSummaryRow(label: "Transactions", value: "\(summary.totalTransactions)")
                    DataSummaryRow(label: "Statements", value: "\(summary.totalStatements)")
                    DataSummaryRow(label: "Budgets", value: "\(summary.totalBudgets)")
                    if summary.totalTransactions > 0 {
                        DataSummaryRow(label: "Date Range", value: summary.dateRange)
                    }
                } else {
                    DataSummaryRow(label: "Storage Used", value: "Loading...")
                    DataSummaryRow(label: "Transactions", value: "Loading...")
                    DataSummaryRow(label: "Statements", value: "Loading...")
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    private var featureConsentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Feature Permissions")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 0) {
                FeatureConsentToggle(
                    title: "Insights & Recommendations",
                    description: "Generate spending insights and recommendations",
                    isOn: Binding(
                        get: { viewModel.featureConsent.insightsEnabled },
                        set: { viewModel.updateFeatureConsent(insights: $0) }
                    )
                )
                
                Divider()
                
                FeatureConsentToggle(
                    title: "Budget Alerts",
                    description: "Receive notifications when approaching budget limits",
                    isOn: Binding(
                        get: { viewModel.featureConsent.budgetAlertsEnabled },
                        set: { viewModel.updateFeatureConsent(budgetAlerts: $0) }
                    )
                )
                
                Divider()
                
                FeatureConsentToggle(
                    title: "Category Learning",
                    description: "Learn from your corrections to improve categorization",
                    isOn: Binding(
                        get: { viewModel.featureConsent.categoryLearningEnabled },
                        set: { viewModel.updateFeatureConsent(categoryLearning: $0) }
                    )
                )
                
                Divider()
                
                FeatureConsentToggle(
                    title: "Notifications",
                    description: "Receive proactive financial notifications",
                    isOn: Binding(
                        get: { viewModel.featureConsent.notificationsEnabled },
                        set: { viewModel.updateFeatureConsent(notifications: $0) }
                    )
                )
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Management")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 0) {
                PrivacyControlRow(
                    title: "Export All Data",
                    icon: "square.and.arrow.up",
                    color: .blue
                ) {
                    Task {
                        await viewModel.exportData()
                    }
                }
                
                Divider()
                
                PrivacyControlRow(
                    title: "Delete All Data",
                    icon: "trash",
                    color: .red
                ) {
                    viewModel.showDeleteConfirmation = true
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .confirmationDialog(
                "Delete All Data",
                isPresented: $viewModel.showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All Data", role: .destructive) {
                    Task {
                        await viewModel.deleteAllData()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your transactions, budgets, and settings. This action cannot be undone.")
            }
        }
    }
    
    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 0) {
                NavigationLink(destination: BiometricSettingsView(container: container)) {
                    HStack {
                        Image(systemName: BiometricAuthService.shared.biometricType().iconName)
                            .frame(width: 24)
                            .foregroundColor(.blue)
                        Text("Biometric Authentication")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                Divider()
                
                NavigationLink(destination: SecurityAuditView(container: container)) {
                    HStack {
                        Image(systemName: "shield.checkered")
                            .frame(width: 24)
                            .foregroundColor(.blue)
                        Text("Security Audit")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    private var privacyInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Your Privacy Matters", systemImage: "hand.raised.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            Text("ClariFi is designed with privacy at its core. By default, all your financial data is processed and stored locally on your device. You have complete control over your data and can export or delete it at any time.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DataSummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

struct PrivacyControlRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ProcessingModeInfoSheet: View {
    let mode: ProcessingMode
    @Environment(\.dismiss) private var dismiss
    
    private var modeDescription: String {
        switch mode {
        case .localOnly:
            return "All data processing happens locally on your device. No data is sent to external servers."
        case .cloudOptIn:
            return "Data processing can happen in the cloud with your explicit consent for enhanced features."
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Processing Mode: \(mode.displayName)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(modeDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Processing Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureConsentToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let privacyManager = PrivacyManager(viewContext: context)
    let viewModel = PrivacyDashboardViewModel(privacyManager: privacyManager)
    let container = AppDIContainer.createPreviewContainer() as! AppDIContainer
    
    return PrivacyDashboardView(viewModel: viewModel, container: container)
        .environment(\.managedObjectContext, context)
}
