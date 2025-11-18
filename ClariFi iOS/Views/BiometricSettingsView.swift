//
//  BiometricSettingsView.swift
//  ClariFi_iOS
//
//  Settings for biometric authentication
//

import SwiftUI

struct BiometricSettingsView: View {
    @StateObject private var viewModel: BiometricSettingsViewModel
    @State private var showingEnableAlert = false
    @State private var showingDisableAlert = false
    
    init(container: AppDIContainer) {
        let auditService = container.resolve(SecurityAuditService.self)
        _viewModel = StateObject(wrappedValue: BiometricSettingsViewModel(auditService: auditService))
    }
    
    var body: some View {
        List {
            // Biometric Type Section
            Section {
                HStack {
                    Image(systemName: viewModel.biometricType.iconName)
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .frame(width: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.biometricType.displayName)
                            .font(.headline)
                        Text(viewModel.biometricAvailable ? "Available on this device" : "Not available")
                            .font(.caption)
                            .foregroundColor(viewModel.biometricAvailable ? .green : .secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Enable/Disable Section
            if viewModel.biometricAvailable {
                Section {
                    Toggle(isOn: $viewModel.isBiometricEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable \(viewModel.biometricType.displayName)")
                                .font(.subheadline)
                            Text("Require authentication to access the app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: viewModel.isBiometricEnabled) { _, newValue in
                        if newValue {
                            showingEnableAlert = true
                        } else {
                            showingDisableAlert = true
                        }
                    }
                } footer: {
                    Text("When enabled, you'll need to authenticate with \(viewModel.biometricType.displayName) or your device passcode to access your financial data.")
                }
                
                // Timeout Settings
                if viewModel.isBiometricEnabled {
                    Section {
                        Picker("Authentication Timeout", selection: $viewModel.selectedTimeout) {
                            Text("Immediately").tag(0)
                            Text("1 minute").tag(60)
                            Text("5 minutes").tag(300)
                            Text("15 minutes").tag(900)
                            Text("30 minutes").tag(1800)
                            Text("1 hour").tag(3600)
                        }
                        .onChange(of: viewModel.selectedTimeout) { _, newValue in
                            viewModel.updateTimeout(newValue)
                        }
                    } header: {
                        Text("Timeout")
                    } footer: {
                        Text("How long to wait before requiring authentication again after the app is backgrounded.")
                    }
                }
            } else {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Biometric authentication is not available on this device.")
                            .font(.subheadline)
                        Text("You can still secure your device with a passcode in Settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // Information Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(
                        icon: "lock.shield",
                        title: "Secure Access",
                        description: "Your biometric data never leaves your device and is managed by iOS."
                    )
                    
                    Divider()
                    
                    InfoRow(
                        icon: "key",
                        title: "Fallback Option",
                        description: "You can always use your device passcode if biometric authentication fails."
                    )
                    
                    Divider()
                    
                    InfoRow(
                        icon: "shield.checkered",
                        title: "Privacy First",
                        description: "Authentication happens entirely on your device. No data is sent to servers."
                    )
                }
            } header: {
                Text("About Biometric Security")
            }
        }
        .navigationTitle("Biometric Authentication")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.loadSettings()
        }
        .alert("Enable Biometric Authentication", isPresented: $showingEnableAlert) {
            Button("Enable") {
                Task {
                    await viewModel.enableBiometric()
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.isBiometricEnabled = false
            }
        } message: {
            Text("You'll be asked to authenticate with \(viewModel.biometricType.displayName) to confirm.")
        }
        .alert("Disable Biometric Authentication", isPresented: $showingDisableAlert) {
            Button("Disable", role: .destructive) {
                viewModel.disableBiometric()
            }
            Button("Cancel", role: .cancel) {
                viewModel.isBiometricEnabled = true
            }
        } message: {
            Text("You will no longer need to authenticate to access the app.")
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
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class BiometricSettingsViewModel: ObservableObject {
    @Published var biometricType: BiometricType = .none
    @Published var biometricAvailable = false
    @Published var isBiometricEnabled = false
    @Published var selectedTimeout: Int = 300
    @Published var error: Error?
    
    private let biometricService = BiometricAuthService.shared
    private let auditService: SecurityAuditService
    
    init(auditService: SecurityAuditService) {
        self.auditService = auditService
    }
    
    func loadSettings() {
        biometricType = biometricService.biometricType()
        biometricAvailable = biometricService.isBiometricAvailable()
        isBiometricEnabled = biometricService.isBiometricEnabled
        selectedTimeout = Int(biometricService.authenticationTimeout)
    }
    
    func enableBiometric() async {
        do {
            try await biometricService.enableBiometric()
            isBiometricEnabled = true
            
            auditService.logEvent(SecurityEvent(
                type: .authenticationSuccess,
                severity: .info,
                description: "Biometric authentication enabled"
            ))
        } catch {
            self.error = error
            isBiometricEnabled = false
            
            auditService.logEvent(SecurityEvent(
                type: .authenticationFailure,
                severity: .medium,
                description: "Failed to enable biometric authentication: \(error.localizedDescription)"
            ))
        }
    }
    
    func disableBiometric() {
        biometricService.disableBiometric()
        isBiometricEnabled = false
        
        auditService.logEvent(SecurityEvent(
            type: .maintenanceOperation,
            severity: .info,
            description: "Biometric authentication disabled"
        ))
    }
    
    func updateTimeout(_ timeout: Int) {
        biometricService.authenticationTimeout = TimeInterval(timeout)
        
        auditService.logEvent(SecurityEvent(
            type: .maintenanceOperation,
            severity: .info,
            description: "Authentication timeout updated to \(timeout) seconds"
        ))
    }
}

#Preview {
    NavigationView {
        BiometricSettingsView(container: AppDIContainer.createPreviewContainer() as! AppDIContainer)
    }
}
