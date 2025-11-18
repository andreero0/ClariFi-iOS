//
//  AnalyticsSettingsView.swift
//  ClariFi_iOS
//
//  Settings view for analytics and crash reporting preferences
//

import SwiftUI

struct AnalyticsSettingsView: View {
    @AppStorage("analytics_enabled") private var analyticsEnabled = false
    @AppStorage("crash_reporting_enabled") private var crashReportingEnabled = false
    @AppStorage("analytics_consent_shown") private var consentShown = false
    
    @State private var showingConsentSheet = false
    @State private var showingDataInfo = false
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Analytics & Insights")
                                .font(.headline)
                            Text("Help us improve ClariFi")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("We respect your privacy. All analytics are optional and anonymous. Your financial data is never shared.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Toggle(isOn: $analyticsEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Usage Analytics")
                            .font(.body)
                        Text("Track app usage to improve features")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: analyticsEnabled) { newValue in
                    handleAnalyticsToggle(newValue)
                }
                
                Toggle(isOn: $crashReportingEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Crash Reporting")
                            .font(.body)
                        Text("Send crash reports to help fix bugs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(!analyticsEnabled)
                
            } header: {
                Text("Data Collection")
            } footer: {
                Text("Analytics help us understand how you use ClariFi so we can make it better. You can change these settings anytime.")
            }
            
            Section {
                Button(action: { showingDataInfo = true }) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("What Data is Collected?")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if analyticsEnabled {
                    Button(action: resetAnalyticsData) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Reset Analytics Data")
                                .foregroundColor(.red)
                        }
                    }
                }
            } header: {
                Text("Information")
            }
            
            if analyticsEnabled {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("Privacy Protected")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        privacyFeature(icon: "lock.fill", text: "No financial data is ever sent")
                        privacyFeature(icon: "eye.slash.fill", text: "Anonymous tracking only")
                        privacyFeature(icon: "server.rack", text: "Data stored securely")
                        privacyFeature(icon: "hand.raised.fill", text: "Opt-out anytime")
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Privacy Guarantees")
                }
            }
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDataInfo) {
            DataCollectionInfoView()
        }
        .sheet(isPresented: $showingConsentSheet) {
            AnalyticsConsentView(isPresented: $showingConsentSheet)
        }
        .onAppear {
            if !consentShown {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingConsentSheet = true
                    consentShown = true
                }
            }
        }
    }
    
    private func privacyFeature(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func handleAnalyticsToggle(_ enabled: Bool) {
        if enabled {
            Analytics.initialize()
            Analytics.track(.privacyModeSelected, properties: [
                "analytics_enabled": true,
                "source": "settings"
            ])
        } else {
            Analytics.track(.privacyModeSelected, properties: [
                "analytics_enabled": false,
                "source": "settings"
            ])
            Analytics.reset()
            crashReportingEnabled = false
        }
    }
    
    private func resetAnalyticsData() {
        Analytics.reset()
        Analytics.track(.dataDeleted, properties: [
            "data_type": "analytics",
            "source": "settings"
        ])
    }
}

struct DataCollectionInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("ClariFi collects anonymous usage data to improve the app experience. We take your privacy seriously.")
                        .font(.body)
                        .padding(.vertical, 8)
                }
                
                Section("What We Collect") {
                    dataItem(icon: "hand.tap.fill", title: "App Interactions", description: "Which features you use and how often")
                    dataItem(icon: "exclamationmark.triangle.fill", title: "Error Reports", description: "Technical errors and crashes to fix bugs")
                    dataItem(icon: "clock.fill", title: "Session Duration", description: "How long you use the app")
                    dataItem(icon: "iphone", title: "Device Info", description: "Device model and OS version for compatibility")
                }
                
                Section("What We DON'T Collect") {
                    dataItem(icon: "dollarsign.circle.fill", title: "Financial Data", description: "Transaction amounts, merchants, or categories", color: .green)
                    dataItem(icon: "person.fill", title: "Personal Info", description: "Names, emails, or identifying information", color: .green)
                    dataItem(icon: "location.fill", title: "Location Data", description: "Your physical location is never tracked", color: .green)
                    dataItem(icon: "doc.text.fill", title: "Document Content", description: "Statement files or OCR text", color: .green)
                }
                
                Section("How We Use It") {
                    Text("• Understand which features are most valuable")
                    Text("• Identify and fix bugs quickly")
                    Text("• Improve app performance")
                    Text("• Make data-driven product decisions")
                }
                .font(.subheadline)
                
                Section("Your Control") {
                    Text("You can disable analytics at any time from Settings. When disabled, no data is collected or sent.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Data Collection")
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
    
    private func dataItem(icon: String, title: String, description: String, color: Color = .blue) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
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
        .padding(.vertical, 4)
    }
}

struct AnalyticsConsentView: View {
    @Binding var isPresented: Bool
    @AppStorage("analytics_enabled") private var analyticsEnabled = false
    @AppStorage("crash_reporting_enabled") private var crashReportingEnabled = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(spacing: 12) {
                    Text("Help Improve ClariFi")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Share anonymous usage data to help us make ClariFi better for everyone")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    consentFeature(icon: "lock.shield.fill", text: "Your financial data stays private", color: .green)
                    consentFeature(icon: "eye.slash.fill", text: "Completely anonymous tracking", color: .blue)
                    consentFeature(icon: "hand.raised.fill", text: "Opt-out anytime in Settings", color: .orange)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: {
                        analyticsEnabled = true
                        crashReportingEnabled = true
                        Analytics.initialize()
                        Analytics.track(.onboardingCompleted, properties: [
                            "analytics_consent": true
                        ])
                        isPresented = false
                    }) {
                        Text("Enable Analytics")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        analyticsEnabled = false
                        crashReportingEnabled = false
                        isPresented = false
                    }) {
                        Text("No Thanks")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func consentFeature(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        AnalyticsSettingsView()
    }
}

#Preview("Data Info") {
    DataCollectionInfoView()
}

#Preview("Consent") {
    AnalyticsConsentView(isPresented: .constant(true))
}
