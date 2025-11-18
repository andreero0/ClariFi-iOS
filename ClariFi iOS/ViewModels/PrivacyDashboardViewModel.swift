//
//  PrivacyDashboardViewModel.swift
//  ClariFi iOS
//
//  ViewModel for privacy dashboard and controls
//

import Foundation
import SwiftUI
import CoreData

@MainActor
class PrivacyDashboardViewModel: BaseViewModel {
    @Published var dataSummary: DataSummary?
    @Published var showExportSheet = false
    @Published var showDeleteConfirmation = false
    @Published var exportURL: URL?
    @Published var showProcessingModeInfo = false
    
    private let privacyManager: PrivacyManager
    
    var processingMode: ProcessingMode {
        get { privacyManager.processingMode }
        set { privacyManager.processingMode = newValue }
    }
    
    var featureConsent: FeatureConsent {
        get { privacyManager.featureConsent }
        set { privacyManager.featureConsent = newValue }
    }
    
    init(privacyManager: PrivacyManager) {
        self.privacyManager = privacyManager
        super.init()
        
        // Clean up old temporary files on init
        privacyManager.cleanupTemporaryFiles()
    }
    
    func loadDataSummary() async {
        isLoading = true
        error = nil
        
        do {
            dataSummary = try await privacyManager.getDataSummary()
            isLoading = false
        } catch {
            isLoading = false
            handleError(error, context: ["operation": "load_data_summary"])
        }
    }
    
    func exportData() async {
        isLoading = true
        error = nil
        
        do {
            let url = try await privacyManager.exportUserData()
            exportURL = url
            showExportSheet = true
            Analytics.track(.dataExported, properties: [
                "processing_mode": processingMode == .localOnly ? "local" : "cloud"
            ])
            isLoading = false
        } catch {
            isLoading = false
            handleError(error, context: ["operation": "export_data", "processing_mode": processingMode == .localOnly ? "local" : "cloud"])
        }
    }
    
    func deleteAllData() async {
        isLoading = true
        error = nil
        
        do {
            try await privacyManager.deleteAllUserData()
            Analytics.track(.dataDeleted, properties: [
                "data_type": "all_user_data"
            ])
            // Reload summary after deletion
            await loadDataSummary()
        } catch {
            isLoading = false
            handleError(error, context: ["operation": "delete_all_data"])
        }
    }
    
    func toggleProcessingMode() {
        let newMode = processingMode == .localOnly ? ProcessingMode.cloudOptIn : ProcessingMode.localOnly
        processingMode = newMode
        Analytics.track(.processingModeChanged, properties: [
            "new_mode": newMode == .localOnly ? "local" : "cloud"
        ])
    }
    
    func updateFeatureConsent(insights: Bool? = nil, notifications: Bool? = nil, budgetAlerts: Bool? = nil, categoryLearning: Bool? = nil) {
        var consent = featureConsent
        
        if let insights = insights {
            consent.insightsEnabled = insights
        }
        if let notifications = notifications {
            consent.notificationsEnabled = notifications
        }
        if let budgetAlerts = budgetAlerts {
            consent.budgetAlertsEnabled = budgetAlerts
        }
        if let categoryLearning = categoryLearning {
            consent.categoryLearningEnabled = categoryLearning
        }
        
        featureConsent = consent
    }
}
